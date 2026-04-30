import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/practice_mode.dart';

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

  int get _targetTime {
    return int.tryParse(widget.targetTime) ?? 60;
  }

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getSlides(widget.presentationId);
      final loadedSlides = <Map<String, dynamic>>[];

      for (final item in data) {
        final slide = Map<String, dynamic>.from(item);
        final scripts = await ApiService.getScripts(slide['_id']);

        slide['scriptData'] = scripts.isNotEmpty ? scripts.first : null;
        slide['style'] = slide['style'] ?? 'Standard';

        loadedSlides.add(slide);
      }

      if (!mounted) return;

      setState(() {
        _slides
          ..clear()
          ..addAll(loadedSlides);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showSnackBar('Load slides failed: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.black87,
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    final filePath = result?.files.single.path;
    if (filePath == null) return;

    final isSuccess = await ApiService.uploadPdfAndCreateSlides(
      presentationId: widget.presentationId,
      pdfPath: filePath,
      targetTime: _targetTime,
    );

    if (!mounted) return;

    if (isSuccess) {
      _showSnackBar('PDF uploaded successfully');
      _loadSlides();
    } else {
      _showSnackBar('Upload PDF failed', isError: true);
    }
  }

  Future<void> _uploadImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null) return;

    final imagePaths = result.files
        .where((file) => file.path != null)
        .map((file) => file.path!)
        .toList();

    if (imagePaths.isEmpty) return;

    final isSuccess = await ApiService.uploadImages(
      presentationId: widget.presentationId,
      imagePaths: imagePaths,
      targetTime: _targetTime,
    );

    if (!mounted) return;

    if (isSuccess) {
      _showSnackBar('Images uploaded successfully');
      _loadSlides();
    } else {
      _showSnackBar('Upload images failed', isError: true);
    }
  }

  Future<void> _runOcr(int index) async {
    try {
      final result = await ApiService.runOcr(_slides[index]['_id']);
      final data = result['data'] ?? result;

      setState(() {
        _slides[index]['extractedTextClean'] =
            data['extractedTextClean'] ?? '';
      });

      _showSnackBar('OCR completed');
    } catch (e) {
      _showSnackBar('OCR failed: $e', isError: true);
    }
  }

  Future<void> _generateScript(int index) async {
    final slide = _slides[index];

    if (_hasScript(slide)) {
      _showSnackBar(
        'Please delete the existing script first',
        isError: true,
      );
      return;
    }

    try {
      final result = await ApiService.generateScript(
        slideId: slide['_id'],
        level: slide['style'].toString().toLowerCase(),
      );

      setState(() {
        slide['scriptData'] = result['data'];
      });

      _showSnackBar('${slide['style']} script generated');
    } catch (e) {
      _showSnackBar('Generate failed: $e', isError: true);
    }
  }

  void _editContent(int index) {
    final slide = _slides[index];
    final controller = TextEditingController(
      text: slide['extractedTextClean'] ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Content'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final isSuccess = await ApiService.updateSlide(
                slideId: slide['_id'],
                extractedTextClean: controller.text,
              );

              if (!mounted) return;

              if (isSuccess) {
                setState(() {
                  slide['extractedTextClean'] = controller.text;
                });

                controller.dispose();
                Navigator.pop(context);
                _showSnackBar('Content saved');
              } else {
                _showSnackBar('Save content failed', isError: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editScript(int index) {
    final slide = _slides[index];
    final scriptData = slide['scriptData'];
    final controller = TextEditingController(
      text: scriptData?['content'] ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Script'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveScript(
                index: index,
                content: controller.text,
              );

              if (!mounted) return;

              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScript({
    required int index,
    required String content,
  }) async {
    final slide = _slides[index];
    final scriptData = slide['scriptData'];

    try {
      if (scriptData != null) {
        final isSuccess = await ApiService.updateScript(
          scriptId: scriptData['_id'],
          content: content,
          level: scriptData['level'] ?? 'standard',
          isAiGenerated: false,
        );

        if (!isSuccess) {
          _showSnackBar('Update script failed', isError: true);
          return;
        }

        setState(() {
          scriptData['content'] = content;
        });
      } else {
        final newScript = await ApiService.createScript(
          slideId: slide['_id'],
          content: content,
          level: slide['style'].toString().toLowerCase(),
          isAiGenerated: false,
        );

        setState(() {
          slide['scriptData'] = newScript;
        });
      }

      _showSnackBar('Script saved');
    } catch (e) {
      _showSnackBar('Save script failed: $e', isError: true);
    }
  }

  Future<void> _deleteScript(int index) async {
    final slide = _slides[index];
    final scriptData = slide['scriptData'];

    if (scriptData == null) return;

    final confirmed = await _confirmAction(
      title: 'Delete Script',
      content: 'Are you sure you want to delete this script?',
    );

    if (!confirmed) return;

    final isSuccess = await ApiService.deleteScript(scriptData['_id']);

    if (!mounted) return;

    if (isSuccess) {
      setState(() {
        slide['scriptData'] = null;
      });

      _showSnackBar('Script deleted');
    } else {
      _showSnackBar('Delete script failed', isError: true);
    }
  }

  Future<void> _deleteSlide(int index) async {
    final confirmed = await _confirmAction(
      title: 'Delete Slide',
      content: 'Delete this slide and all its data? This cannot be undone.',
    );

    if (!confirmed) return;

    final isSuccess = await ApiService.deleteSlide(_slides[index]['_id']);

    if (!mounted) return;

    if (isSuccess) {
      _showSnackBar('Slide deleted');
      _loadSlides();
    } else {
      _showSnackBar('Delete slide failed', isError: true);
    }
  }

  void _copyScript(Map<String, dynamic> slide) {
    final content = slide['scriptData']?['content'] ?? '';

    Clipboard.setData(ClipboardData(text: content));
    _showSnackBar('Copied');
  }

  bool _hasScript(Map<String, dynamic> slide) {
    final content = slide['scriptData']?['content']?.toString() ?? '';
    return content.isNotEmpty;
  }

  String _imageUrl(String imagePath) {
    final path = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;

    return '${ApiService.baseUrl}/$path';
  }

  Widget _buildTopButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _uploadPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Upload PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _uploadImages,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Upload Images'),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_slides.isEmpty) {
      return const Center(child: Text('No slides yet'));
    }

    return RefreshIndicator(
      onRefresh: _loadSlides,
      child: ListView.builder(
        itemCount: _slides.length,
        itemBuilder: (_, index) {
          return _SlideCard(
            slide: _slides[index],
            index: index,
            hasScript: _hasScript(_slides[index]),
            imageUrl: _slides[index]['imagePath'] == null
                ? null
                : _imageUrl(_slides[index]['imagePath']),
            onRunOcr: () => _runOcr(index),
            onEditContent: () => _editContent(index),
            onGenerateScript: () => _generateScript(index),
            onEditScript: () => _editScript(index),
            onDeleteScript: () => _deleteScript(index),
            onDeleteSlide: () => _deleteSlide(index),
            onCopyScript: () => _copyScript(_slides[index]),
            onStyleChanged: (value) {
              setState(() {
                _slides[index]['style'] = value;
              });
            },
          );
        },
      ),
    );
  }

  void _goToPracticeMode() {
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

  Widget _buildPracticeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _goToPracticeMode,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC8FB4),
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Go to Practice Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slide Management'),
        backgroundColor: const Color(0xFFEC8FB4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE4EC),
              Color(0xFFE3F2FD),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTopButtons(),
              const SizedBox(height: 16),
              Expanded(child: _buildSlideList()),
              const SizedBox(height: 12),
              _buildPracticeButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final Map<String, dynamic> slide;
  final int index;
  final bool hasScript;
  final String? imageUrl;
  final VoidCallback onRunOcr;
  final VoidCallback onEditContent;
  final VoidCallback onGenerateScript;
  final VoidCallback onEditScript;
  final VoidCallback onDeleteScript;
  final VoidCallback onDeleteSlide;
  final VoidCallback onCopyScript;
  final ValueChanged<String> onStyleChanged;

  const _SlideCard({
    required this.slide,
    required this.index,
    required this.hasScript,
    required this.imageUrl,
    required this.onRunOcr,
    required this.onEditContent,
    required this.onGenerateScript,
    required this.onEditScript,
    required this.onDeleteScript,
    required this.onDeleteSlide,
    required this.onCopyScript,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final slideNo = slide['slideNo'] ?? index + 1;
    final content = slide['extractedTextClean'] ?? 'No content';
    final script = slide['scriptData']?['content'] ?? 'No script yet';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(slideNo),
          if (imageUrl != null) ...[
            const SizedBox(height: 12),
            _buildImage(),
          ],
          const SizedBox(height: 16),
          _buildContent(content),
          const Divider(),
          _buildScript(script),
          const SizedBox(height: 16),
          _buildGenerateRow(),
          const SizedBox(height: 10),
          _buildScriptActions(),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic slideNo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Slide $slideNo',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C6BC0),
          ),
        ),
        IconButton(
          onPressed: onDeleteSlide,
          icon: const Icon(
            Icons.close,
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 180,
            width: double.infinity,
            alignment: Alignment.center,
            color: Colors.grey.shade100,
            child: const Text('Image Error'),
          );
        },
      ),
    );
  }

  Widget _buildContent(dynamic content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(content.toString()),
        Row(
          children: [
            TextButton(
              onPressed: onRunOcr,
              child: const Text('Run OCR'),
            ),
            TextButton(
              onPressed: onEditContent,
              child: const Text('Edit Content'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScript(dynamic script) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Script',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              onPressed: onCopyScript,
              icon: const Icon(
                Icons.copy_rounded,
                size: 20,
              ),
            ),
          ],
        ),
        Text(
          script.toString(),
          style: TextStyle(
            color: hasScript ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: slide['style'] ?? 'Standard',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
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
            onChanged: hasScript
                ? null
                : (value) {
                    if (value != null) {
                      onStyleChanged(value);
                    }
                  },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: hasScript ? null : onGenerateScript,
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildScriptActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEditScript,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Script'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasScript ? onDeleteScript : null,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Script'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}