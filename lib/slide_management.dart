import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/practice_mode.dart';
import 'package:flutter_project/theme_controller.dart';

class SlideManagementScreen extends StatefulWidget {
  final String presentationId;
  final String targetTime;

  const SlideManagementScreen({
    super.key,
    required this.presentationId,
    required this.targetTime,
  });

  @override
  State<SlideManagementScreen> createState() =>
      _SlideManagementScreenState();
}

class _SlideManagementScreenState
    extends State<SlideManagementScreen> {
  final List<Map<String, dynamic>> _slides = [];

  bool _isLoading = true;
  bool _isUploading = false;
  bool _isDarkMode = false;
  int? _processingIndex;

  int get _targetTime =>
      int.tryParse(widget.targetTime) ?? 60;

  Color get primary => _isDarkMode
      ? const Color(0xFF38BDF8)
      : const Color(0xFFD97706);

  Color get background => _isDarkMode
      ? const Color(0xFF0F172A)
      : const Color(0xFFFAF6EE);

  Color get card =>
      _isDarkMode ? const Color(0xFF1E293B) : Colors.white;

  Color get text =>
      _isDarkMode ? Colors.white : const Color(0xFF2D261E);

  Color get subtitle =>
      _isDarkMode ? Colors.white60 : const Color(0xFF6B5E4E);

  Color get border => _isDarkMode
      ? const Color(0xFF334155)
      : const Color(0xFFEFEBE3);

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    setState(() => _isLoading = true);

    try {
      final data =
          await ApiService.getSlides(widget.presentationId);

      final loaded = <Map<String, dynamic>>[];

      for (final item in data) {
        final slide = Map<String, dynamic>.from(item);
        final id = slide['_id']?.toString();

        if (id != null) {
          try {
            final scripts = await ApiService.getScripts(id);
            slide['scriptData'] =
                scripts.isNotEmpty ? scripts.last : null;
          } catch (_) {
            slide['scriptData'] = null;
          }
        }

        slide['style'] ??= 'Standard';
        loaded.add(slide);
      }

      if (!mounted) return;

      setState(() {
        _slides
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Load slides failed: $e', error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.redAccent : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool> _confirm(
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: card,
            title: Text(title, style: TextStyle(color: text)),
            content: Text(
              content,
              style: TextStyle(color: subtitle),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _uploadPdf() async {
    if (_isUploading) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _isUploading = true);

    try {
      final success =
          await ApiService.uploadPdfAndCreateSlides(
        presentationId: widget.presentationId,
        pdfPath: path,
        targetTime: _targetTime,
      );

      if (!mounted) return;

      if (success) {
        _showMessage('PDF uploaded successfully');
        await _loadSlides();
      } else {
        _showMessage('Upload PDF failed', error: true);
      }
    } catch (e) {
      _showMessage('Upload PDF failed: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadImages() async {
    if (_isUploading) return;

    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null) return;

    final paths = result.files
        .where((file) => file.path != null)
        .map((file) => file.path!)
        .toList();

    if (paths.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final success = await ApiService.uploadImages(
        presentationId: widget.presentationId,
        imagePaths: paths,
        targetTime: _targetTime,
      );

      if (!mounted) return;

      if (success) {
        _showMessage('Images uploaded successfully');
        await _loadSlides();
      } else {
        _showMessage('Upload images failed', error: true);
      }
    } catch (e) {
      _showMessage('Upload images failed: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _runOcr(int index) async {
    if (_processingIndex != null) return;

    final slide = _slides[index];
    final id = slide['_id']?.toString();

    if (id == null) return;

    setState(() => _processingIndex = index);

    try {
      final result = await ApiService.runOcr(id);
      final data = result['data'] ?? result;

      if (!mounted) return;

      setState(() {
        slide['extractedTextClean'] =
            data['extractedTextClean']?.toString() ?? '';
      });

      _showMessage('OCR completed');
    } catch (e) {
      _showMessage('OCR failed: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _processingIndex = null);
      }
    }
  }

  Future<void> _generateScript(int index) async {
    if (_processingIndex != null) return;

    final slide = _slides[index];

    if (_hasScript(slide)) {
      _showMessage(
        'Please delete the existing script first',
        error: true,
      );
      return;
    }

    final id = slide['_id']?.toString();
    if (id == null) return;

    setState(() => _processingIndex = index);

    try {
      final result = await ApiService.generateScript(
        slideId: id,
        level: slide['style'].toString().toLowerCase(),
      );

      if (!mounted) return;

      setState(() {
        slide['scriptData'] = result['data'] ?? result;
      });

      _showMessage('Script generated');
    } catch (e) {
      _showMessage('Generate failed: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _processingIndex = null);
      }
    }
  }

  Future<String?> _showEditor({
    required String title,
    required String initialText,
  }) async {
    final controller =
        TextEditingController(text: initialText);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: card,
        title: Text(title, style: TextStyle(color: text)),
        content: SizedBox(
          width: 550,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              filled: true,
              fillColor: background,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor:
                  _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> _editContent(int index) async {
    final slide = _slides[index];

    final content = await _showEditor(
      title: 'Edit Slide Content',
      initialText:
          slide['extractedTextClean']?.toString() ?? '',
    );

    if (content == null) return;

    final id = slide['_id']?.toString();
    if (id == null) return;

    final success = await ApiService.updateSlide(
      slideId: id,
      extractedTextClean: content,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        slide['extractedTextClean'] = content;
      });
      _showMessage('Content saved');
    } else {
      _showMessage('Save content failed', error: true);
    }
  }

  Future<void> _editScript(int index) async {
    final slide = _slides[index];

    final content = await _showEditor(
      title: _hasScript(slide)
          ? 'Edit Script'
          : 'Write Script',
      initialText:
          slide['scriptData']?['content']?.toString() ?? '',
    );

    if (content == null || content.isEmpty) return;

    await _saveScript(index, content);
  }

  Future<void> _saveScript(
    int index,
    String content,
  ) async {
    final slide = _slides[index];
    final script = slide['scriptData'];
    final slideId = slide['_id']?.toString();

    if (slideId == null) return;

    try {
      if (script == null) {
        final newScript = await ApiService.createScript(
          slideId: slideId,
          content: content,
          level: slide['style'].toString().toLowerCase(),
          isAiGenerated: false,
        );

        if (!mounted) return;

        setState(() {
          slide['scriptData'] = newScript;
        });
      } else {
        final success = await ApiService.updateScript(
          scriptId: script['_id'].toString(),
          content: content,
          level: script['level']?.toString() ?? 'standard',
          isAiGenerated: false,
        );

        if (!success) {
          _showMessage('Update script failed', error: true);
          return;
        }

        setState(() {
          script['content'] = content;
        });
      }

      _showMessage('Script saved');
    } catch (e) {
      _showMessage('Save script failed: $e', error: true);
    }
  }

  Future<void> _deleteScript(int index) async {
    final slide = _slides[index];
    final script = slide['scriptData'];

    if (script == null) return;

    final confirmed = await _confirm(
      'Delete Script',
      'Are you sure you want to delete this script?',
    );

    if (!confirmed) return;

    final success =
        await ApiService.deleteScript(script['_id'].toString());

    if (!mounted) return;

    if (success) {
      setState(() {
        slide['scriptData'] = null;
      });
      _showMessage('Script deleted');
    } else {
      _showMessage('Delete script failed', error: true);
    }
  }

  Future<void> _deleteSlide(int index) async {
    final confirmed = await _confirm(
      'Delete Slide',
      'Delete this slide and all its data?',
    );

    if (!confirmed) return;

    final success = await ApiService.deleteSlide(
      _slides[index]['_id'].toString(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _slides.removeAt(index);
      });
      _showMessage('Slide deleted');
    } else {
      _showMessage('Delete slide failed', error: true);
    }
  }

  bool _hasScript(Map<String, dynamic> slide) {
    final content =
        slide['scriptData']?['content']?.toString().trim() ?? '';

    return content.isNotEmpty;
  }

  void _copyScript(Map<String, dynamic> slide) {
    final content =
        slide['scriptData']?['content']?.toString() ?? '';

    if (content.isEmpty) return;

    Clipboard.setData(ClipboardData(text: content));
    _showMessage('Script copied');
  }

  String _imageUrl(String path) {
    final cleanPath =
        path.startsWith('/') ? path.substring(1) : path;

    return '${ApiService.baseUrl}/$cleanPath';
  }

  void _goToPractice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeModeScreen(
          presentationId: widget.presentationId,
          targetTime: widget.targetTime,
        ),
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Upload PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadImages,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Upload Images'),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideCard(int index) {
    final slide = _slides[index];
    final hasScript = _hasScript(slide);
    final isProcessing = _processingIndex == index;

    final content =
        slide['extractedTextClean']?.toString().trim();

    final script =
        slide['scriptData']?['content']?.toString().trim();

    final imagePath = slide['imagePath']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Slide ${slide['slideNo'] ?? index + 1}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
              ),
              const Spacer(),
              if (isProcessing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
              IconButton(
                onPressed:
                    isProcessing ? null : () => _deleteSlide(index),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          if (imagePath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                _imageUrl(imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: const Text('Image Error'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Extracted Content',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content == null || content.isEmpty
                ? 'No extracted content'
                : content,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtitle),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed:
                    isProcessing ? null : () => _runOcr(index),
                child: const Text('Run OCR'),
              ),
              TextButton(
                onPressed:
                    isProcessing ? null : () => _editContent(index),
                child: const Text('Edit Content'),
              ),
            ],
          ),
          Divider(color: border),
          Row(
            children: [
              Text(
                'Script',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed:
                    hasScript ? () => _copyScript(slide) : null,
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          Text(
            script == null || script.isEmpty
                ? 'No script yet'
                : script,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasScript ? text : subtitle,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: slide['style']?.toString() ?? 'Standard',
                  dropdownColor: card,
                  style: TextStyle(color: text),
                  decoration: const InputDecoration(
                    labelText: 'Script style',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Standard',
                      child: Text('Standard'),
                    ),
                    DropdownMenuItem(
                      value: 'Formal',
                      child: Text('Formal'),
                    ),
                  ],
                  onChanged: hasScript || isProcessing
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              slide['style'] = value;
                            });
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: hasScript || isProcessing
                    ? null
                    : () => _generateScript(index),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Generate'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isProcessing ? null : () => _editScript(index),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    hasScript ? 'Edit Script' : 'Write Script',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasScript && !isProcessing
                      ? () => _deleteScript(index)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Script'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primary),
      );
    }

    if (_slides.isEmpty) {
      return Center(
        child: Text(
          'No slides yet',
          style: TextStyle(color: subtitle),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSlides,
      color: primary,
      child: ListView.builder(
        itemCount: _slides.length,
        itemBuilder: (_, index) => _buildSlideCard(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text(
          'Slide Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadSlides,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            icon: Icon(
              _isDarkMode
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildUploadButtons(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      _slides.isEmpty ? null : _goToPractice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: _isDarkMode
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                  ),
                  icon: const Icon(
                    Icons.record_voice_over_rounded,
                  ),
                  label: const Text(
                    'Go to Practice Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}