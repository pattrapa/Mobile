import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/decorative_background.dart';
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
  State<SlideManagementScreen> createState() => _SlideManagementScreenState();
}

class _SlideManagementScreenState extends State<SlideManagementScreen> {
  final List<Map<String, dynamic>> _slides = [];

  bool _isLoading = true;
  bool _isUploading = false;
  bool get _isDarkMode => ThemeController.isDarkMode.value;
  int? _processingIndex;

  int get _targetTime => int.tryParse(widget.targetTime) ?? 60;

  Color get primary =>
      _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFF97316);

  Color get secondary =>
      _isDarkMode ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);

  Color get background =>
      _isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFFFF9F1);

  Color get card => _isDarkMode ? const Color(0xFF152238) : Colors.white;

  Color get inputColor =>
      _isDarkMode ? const Color(0xFF0F1A2C) : const Color(0xFFFFFCF8);

  Color get text => _isDarkMode ? Colors.white : const Color(0xFF29231D);

  Color get subtitle => _isDarkMode ? Colors.white60 : const Color(0xFF74685A);

  Color get border =>
      _isDarkMode ? const Color(0xFF2C405D) : const Color(0xFFF1E5D6);

  Color get buttonText => _isDarkMode ? const Color(0xFF07111F) : Colors.white;
  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getSlides(widget.presentationId);

      final loaded = <Map<String, dynamic>>[];

      for (final item in data) {
        final slide = Map<String, dynamic>.from(item);
        final id = slide['_id']?.toString();

        if (id != null) {
          try {
            final scripts = await ApiService.getScripts(id);
            slide['scriptData'] = scripts.isNotEmpty ? scripts.last : null;
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
          backgroundColor: error ? Colors.redAccent : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: card,
            title: Text(title, style: TextStyle(color: text)),
            content: Text(content, style: TextStyle(color: subtitle)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
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
      final success = await ApiService.uploadPdfAndCreateSlides(
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
      _showMessage('Please delete the existing script first', error: true);
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
    final controller = TextEditingController(text: initialText);

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
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: _isDarkMode
                  ? const Color(0xFF0F172A)
                  : Colors.white,
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
      initialText: slide['extractedTextClean']?.toString() ?? '',
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
      title: _hasScript(slide) ? 'Edit Script' : 'Write Script',
      initialText: slide['scriptData']?['content']?.toString() ?? '',
    );

    if (content == null || content.isEmpty) return;

    await _saveScript(index, content);
  }

  Future<void> _saveScript(int index, String content) async {
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

    final success = await ApiService.deleteScript(script['_id'].toString());

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
    final content = slide['scriptData']?['content']?.toString().trim() ?? '';

    return content.isNotEmpty;
  }

  void _copyScript(Map<String, dynamic> slide) {
    final content = slide['scriptData']?['content']?.toString() ?? '';

    if (content.isEmpty) return;

    Clipboard.setData(ClipboardData(text: content));
    _showMessage('Script copied');
  }

  String _imageUrl(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [const Color(0xFF1A2D49), const Color(0xFF152238)]
              : [const Color(0xFFFFF5E8), const Color(0xFFFFE8CD)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFFB7773D).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -25,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, secondary]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.24),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.slideshow_rounded,
                  color: buttonText,
                  size: 34,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prepare your slides',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Upload slides, review extracted content, and prepare your speaking script.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: const Text(
                'Upload PDF',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary.withValues(alpha: 0.12),
                foregroundColor: primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: BorderSide(color: primary.withValues(alpha: 0.25)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadImages,
              icon: const Icon(Icons.image_outlined, size: 20),
              label: const Text(
                'Upload Images',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary.withValues(alpha: 0.12),
                foregroundColor: secondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: BorderSide(color: secondary.withValues(alpha: 0.25)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 5,
          height: 42,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Presentation slides',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_slides.length} slide${_slides.length == 1 ? '' : 's'} added',
                style: TextStyle(fontSize: 13, color: subtitle),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: IconButton(
            onPressed: _isLoading ? null : _loadSlides,
            icon: const Icon(Icons.refresh_rounded),
            color: primary,
            tooltip: 'Refresh slides',
          ),
        ),
      ],
    );
  }

  Widget _buildSlideCard(int index) {
    final slide = _slides[index];
    final hasScript = _hasScript(slide);
    final isProcessing = _processingIndex == index;

    final content = slide['extractedTextClean']?.toString().trim();

    final script = slide['scriptData']?['content']?.toString().trim();

    final imagePath = slide['imagePath']?.toString();

    final accentColors = _isDarkMode
        ? const [
            Color(0xFF38BDF8),
            Color(0xFF818CF8),
            Color(0xFF2DD4BF),
            Color(0xFFA78BFA),
          ]
        : const [
            Color(0xFFF97316),
            Color(0xFFF59E0B),
            Color(0xFFEC4899),
            Color(0xFF8B5CF6),
          ];

    final accent = accentColors[index % accentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.16)
                : const Color(0xFFB7773D).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, accent.withValues(alpha: 0.40)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 125,
                height: 125,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 18, 17, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.slideshow_rounded, color: accent),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Slide ${slide['slideNo'] ?? index + 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hasScript
                                  ? 'Content and script ready'
                                  : 'Review content and prepare a script',
                              style: TextStyle(fontSize: 12, color: subtitle),
                            ),
                          ],
                        ),
                      ),
                      if (isProcessing)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: accent,
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: isProcessing
                              ? null
                              : () => _deleteSlide(index),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Delete slide',
                        ),
                      ),
                    ],
                  ),
                  if (imagePath != null) ...[
                    const SizedBox(height: 17),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrl(imagePath),
                          height: 230,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return SizedBox(
                              height: 155,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 38,
                                    color: subtitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unable to load slide image',
                                    style: TextStyle(color: subtitle),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _buildContentSection(
                    index: index,
                    accent: accent,
                    content: content,
                    isProcessing: isProcessing,
                  ),
                  const SizedBox(height: 15),
                  Divider(color: border),
                  const SizedBox(height: 5),
                  _buildScriptSection(
                    index: index,
                    slide: slide,
                    accent: accent,
                    script: script,
                    hasScript: hasScript,
                    isProcessing: isProcessing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection({
    required int index,
    required Color accent,
    required String? content,
    required bool isProcessing,
  }) {
    final hasContent = content != null && content.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.text_snippet_outlined,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Extracted content',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
              ),
              if (hasContent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Ready',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasContent
                ? content
                : 'No extracted content. Run OCR to read text from this slide.',
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: hasContent ? text : subtitle,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              OutlinedButton.icon(
                onPressed: isProcessing ? null : () => _runOcr(index),
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: const Text('Run OCR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: isProcessing ? null : () => _editContent(index),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Content'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: text,
                  side: BorderSide(color: border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScriptSection({
    required int index,
    required Map<String, dynamic> slide,
    required Color accent,
    required String? script,
    required bool hasScript,
    required bool isProcessing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.notes_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Speaking script',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: IconButton(
                onPressed: hasScript ? () => _copyScript(slide) : null,
                icon: const Icon(Icons.copy_rounded),
                color: accent,
                tooltip: 'Copy script',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: inputColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Text(
            script == null || script.isEmpty
                ? 'No script yet. Generate one with AI or write your own script.'
                : script,
            maxLines: 7,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: hasScript ? text : subtitle,
            ),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;

            final styleDropdown = DropdownButtonFormField<String>(
              initialValue: slide['style']?.toString() ?? 'Standard',
              dropdownColor: card,
              style: TextStyle(color: text),
              iconEnabledColor: accent,
              decoration: InputDecoration(
                labelText: 'Script style',
                labelStyle: TextStyle(color: subtitle),
                filled: true,
                fillColor: inputColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                DropdownMenuItem(value: 'Formal', child: Text('Formal')),
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
            );

            final generateButton = ElevatedButton.icon(
              onPressed: hasScript || isProcessing
                  ? null
                  : () => _generateScript(index),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Generate Script',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: _isDarkMode
                    ? const Color(0xFF07111F)
                    : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  styleDropdown,
                  const SizedBox(height: 10),
                  generateButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: styleDropdown),
                const SizedBox(width: 10),
                generateButton,
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : () => _editScript(index),
                icon: const Icon(Icons.edit_outlined),
                label: Text(hasScript ? 'Edit Script' : 'Write Script'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasScript && !isProcessing
                    ? () => _deleteScript(index)
                    : null,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete Script'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadSlides,
      color: primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 25, bottom: 110),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 38,
                ),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black.withValues(alpha: 0.16)
                          : const Color(0xFFB7773D).withValues(alpha: 0.07),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary.withValues(alpha: 0.18),
                            secondary.withValues(alpha: 0.09),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        Icons.upload_file_rounded,
                        size: 46,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 21),
                    Text(
                      'No slides yet',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a PDF or images to start preparing your presentation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (_slides.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadSlides,
      color: primary,
      child: ListView.builder(
        itemCount: _slides.length,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 110),
        itemBuilder: (_, index) {
          return _buildSlideCard(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, isDarkMode, _) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            foregroundColor: text,
            elevation: 0,
            titleSpacing: 8,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.slideshow_rounded,
                    color: primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Slide Management',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: border),
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _loadSlides,
                  icon: const Icon(Icons.refresh_rounded),
                  color: primary,
                  tooltip: 'Refresh slides',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: border),
                ),
                child: IconButton(
                  onPressed: ThemeController.toggleTheme,
                  icon: Icon(
                    isDarkMode
                        ? Icons.wb_sunny_outlined
                        : Icons.dark_mode_outlined,
                    color: primary,
                  ),
                  tooltip: isDarkMode
                      ? 'Switch to Warm Mode'
                      : 'Switch to Dark Mode',
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: DecorativeBackground(
            isDarkMode: isDarkMode,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SizedBox(
                      width: constraints.maxWidth > 980
                          ? 980
                          : constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                        child: Column(
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 10),
                            _buildUploadButtons(),
                            const SizedBox(height: 14),
                            _buildSectionTitle(),
                            const SizedBox(height: 8),

                            // พื้นที่รายการสไลด์
                            Expanded(child: _buildBody()),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _slides.isEmpty || _isUploading
                                    ? null
                                    : _goToPractice,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  disabledBackgroundColor: primary.withValues(
                                    alpha: 0.45,
                                  ),
                                  foregroundColor: buttonText,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.record_voice_over_rounded,
                                ),
                                label: const Text(
                                  'Continue to Practice Mode',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UploadOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDarkMode;
  final bool isLoading;
  final VoidCallback onTap;

  const _UploadOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDarkMode,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF152238) : Colors.white;

    final textColor = isDarkMode ? Colors.white : const Color(0xFF29231D);

    final subtitleColor = isDarkMode ? Colors.white60 : const Color(0xFF74685A);

    final borderColor = isDarkMode
        ? const Color(0xFF2C405D)
        : const Color(0xFFF1E5D6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}