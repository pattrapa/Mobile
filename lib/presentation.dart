import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/slide_management.dart';
import 'package:flutter_project/theme_controller.dart';

class PresentationScreen extends StatefulWidget {
  final String? id;
  final String? title;
  final String? description;
  final String? time;
  final bool isEdit;

  const PresentationScreen({
    super.key,
    this.id,
    this.title,
    this.description,
    this.time,
    this.isEdit = false,
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _timeFocusNode = FocusNode();

  bool _isLoading = false;
  bool get _isDarkMode => ThemeController.isDarkMode.value;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _titleController.text = widget.title ?? '';
      _descriptionController.text = widget.description ?? '';
      _timeController.text = widget.time ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();

    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _timeFocusNode.dispose();

    super.dispose();
  }

  Color get _backgroundColor {
    return _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAF6EE);
  }

  Color get _cardColor {
    return _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  }

  Color get _textColor {
    return _isDarkMode ? Colors.white : const Color(0xFF2D261E);
  }

  Color get _subtitleColor {
    return _isDarkMode ? Colors.white60 : const Color(0xFF6B5E4E);
  }

  Color get _primaryColor {
    return _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706);
  }

  Color get _inputColor {
    return _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7);
  }

  Color get _borderColor {
    return _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFEBE3);
  }

  Color get _buttonTextColor {
    return _isDarkMode ? const Color(0xFF0F172A) : Colors.white;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Colors.redAccent : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final timeInMinutes = int.parse(_timeController.text.trim());
      final timeInSeconds = timeInMinutes * 60;

      final item = await ApiService.createPresentation(
        title: title,
        description: description,
        totalTargetTime: timeInSeconds,
      );

      if (!mounted) return;

      final rawPresentationId = item['_id'] ?? item['presentation']?['_id'];

      final presentationId = rawPresentationId?.toString();

      if (presentationId == null || presentationId.isEmpty) {
        setState(() {
          _isLoading = false;
        });

        _showSnackBar(
          'Presentation was created, but its ID was not found',
          isError: true,
        );
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Presentation created successfully');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SlideManagementScreen(
            presentationId: presentationId,
            targetTime: _timeController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Create failed: $e', isError: true);
    }
  }

  Future<void> _handleUpdate() async {
    if (_isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final presentationId = widget.id;

    if (presentationId == null || presentationId.isEmpty) {
      _showSnackBar('Presentation ID not found', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final timeInMinutes = int.parse(_timeController.text.trim());
      final timeInSeconds = timeInMinutes * 60;

      final isSuccess = await ApiService.updatePresentation(
        id: presentationId,
        title: title,
        description: description,
        totalTargetTime: timeInSeconds,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (isSuccess) {
        _showSnackBar('Presentation updated successfully');

        Navigator.pop(context, true);
      } else {
        _showSnackBar('Update failed', isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Update failed: $e', isError: true);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      labelStyle: TextStyle(color: _subtitleColor),
      hintStyle: TextStyle(
        color: _isDarkMode ? Colors.white30 : const Color(0xFFAAA093),
      ),
      suffixStyle: TextStyle(
        color: _subtitleColor,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: _inputColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _borderColor),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withValues(alpha: 0.20)
              : const Color(0xFF7A7062).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isEdit ? Icons.edit_note_rounded : Icons.add_chart_rounded,
            size: 44,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          widget.isEdit ? 'Edit Presentation' : 'Create Presentation',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isEdit
              ? 'Update your presentation information and target duration.'
              : 'Add the basic details before uploading slides and scripts.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: _subtitleColor),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 21, color: _primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Set a realistic target time so the practice result can compare your actual presentation duration.',
              style: TextStyle(fontSize: 13, height: 1.45, color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            enabled: !_isLoading,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            style: TextStyle(color: _textColor),
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_descriptionFocusNode);
            },
            decoration: _inputDecoration(
              label: 'Presentation title',
              hint: 'Example: Final Project Presentation',
              icon: Icons.title_rounded,
            ),
            validator: (value) {
              final title = value?.trim() ?? '';

              if (title.isEmpty) {
                return 'Please enter a title';
              }

              if (title.length < 3) {
                return 'Title must contain at least 3 characters';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            enabled: !_isLoading,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
            style: TextStyle(color: _textColor, height: 1.5),
            decoration: _inputDecoration(
              label: 'Description',
              hint: 'Describe the topic and purpose of this presentation',
              icon: Icons.description_outlined,
            ),
            validator: (value) {
              final description = value?.trim() ?? '';

              if (description.isEmpty) {
                return 'Please enter a description';
              }

              if (description.length < 5) {
                return 'Description must contain at least 5 characters';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _timeController,
            focusNode: _timeFocusNode,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: TextStyle(color: _textColor),
            onFieldSubmitted: (_) {
              if (widget.isEdit) {
                _handleUpdate();
              } else {
                _handleSave();
              }
            },
            decoration: _inputDecoration(
              label: 'Target duration',
              hint: 'Example: 10',
              icon: Icons.schedule_rounded,
              suffixText: 'minutes',
            ),
            validator: (value) {
              final text = value?.trim() ?? '';

              if (text.isEmpty) {
                return 'Please enter a target duration';
              }

              final minutes = int.tryParse(text);

              if (minutes == null) {
                return 'Please enter numbers only';
              }

              if (minutes <= 0) {
                return 'Target duration must be greater than 0';
              }

              if (minutes > 999) {
                return 'Target duration is too long';
              }

              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildInfoBanner(),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : widget.isEdit
                  ? _handleUpdate
                  : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                disabledBackgroundColor: _primaryColor.withValues(alpha: 0.50),
                foregroundColor: _buttonTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : Icon(
                      widget.isEdit
                          ? Icons.save_outlined
                          : Icons.arrow_forward_rounded,
                    ),
              label: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _buttonTextColor,
                      ),
                    )
                  : Text(
                      widget.isEdit ? 'Save Changes' : 'Continue to Slides',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: _cardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, isDarkMode, _) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            backgroundColor: _backgroundColor,
            foregroundColor: _textColor,
            elevation: 0,
            titleSpacing: 8,
            title: Row(
              children: [
                Icon(Icons.mic_none_rounded, color: _primaryColor),
                const SizedBox(width: 9),
                Text(
                  widget.isEdit ? 'Edit Presentation' : 'New Presentation',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _isLoading ? null : ThemeController.toggleTheme,
                icon: Icon(
                  isDarkMode
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                ),
                tooltip: isDarkMode
                    ? 'Switch to Warm Mode'
                    : 'Switch to Dark Mode',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(child: _buildContent()),
        );
      },
    );
  }
}
