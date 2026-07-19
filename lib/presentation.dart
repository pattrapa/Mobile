import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/decorative_background.dart';
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
  State<PresentationScreen> createState() =>
      _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _timeController =
      TextEditingController();

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _timeFocusNode = FocusNode();

  bool _isLoading = false;

  bool get _isDarkMode => ThemeController.isDarkMode.value;

  Color get _backgroundColor {
    return _isDarkMode
        ? const Color(0xFF0B1220)
        : const Color(0xFFFFF9F1);
  }

  Color get _cardColor {
    return _isDarkMode
        ? const Color(0xFF152238)
        : Colors.white;
  }

  Color get _textColor {
    return _isDarkMode
        ? Colors.white
        : const Color(0xFF29231D);
  }

  Color get _subtitleColor {
    return _isDarkMode
        ? Colors.white60
        : const Color(0xFF74685A);
  }

  Color get _primaryColor {
    return _isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFFF97316);
  }

  Color get _secondaryColor {
    return _isDarkMode
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);
  }

  Color get _inputColor {
    return _isDarkMode
        ? const Color(0xFF0F1A2C)
        : const Color(0xFFFFFCF8);
  }

  Color get _borderColor {
    return _isDarkMode
        ? const Color(0xFF2C405D)
        : const Color(0xFFF1E5D6);
  }

  Color get _buttonTextColor {
    return _isDarkMode
        ? const Color(0xFF07111F)
        : Colors.white;
  }

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

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
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
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: isError
              ? Colors.redAccent
              : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final description =
          _descriptionController.text.trim();

      final timeInMinutes =
          int.parse(_timeController.text.trim());

      final timeInSeconds =
          timeInMinutes * 60;

      final item =
          await ApiService.createPresentation(
        title: title,
        description: description,
        totalTargetTime: timeInSeconds,
      );

      if (!mounted) return;

      final rawPresentationId =
          item['_id'] ??
          item['presentation']?['_id'];

      final presentationId =
          rawPresentationId?.toString();

      if (presentationId == null ||
          presentationId.isEmpty) {
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

      _showSnackBar(
        'Presentation created successfully',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SlideManagementScreen(
            presentationId:
                presentationId,
            targetTime:
                _timeController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Create failed: $e',
        isError: true,
      );
    }
  }

  Future<void> _handleUpdate() async {
    if (_isLoading) return;

    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final presentationId = widget.id;

    if (presentationId == null ||
        presentationId.isEmpty) {
      _showSnackBar(
        'Presentation ID not found',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();

      final description =
          _descriptionController.text.trim();

      final timeInMinutes =
          int.parse(_timeController.text.trim());

      final timeInSeconds =
          timeInMinutes * 60;

      final isSuccess =
          await ApiService.updatePresentation(
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
        _showSnackBar(
          'Presentation updated successfully',
        );

        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          'Update failed',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Update failed: $e',
        isError: true,
      );
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
      labelStyle: TextStyle(
        color: _subtitleColor,
      ),
      hintStyle: TextStyle(
        color: _isDarkMode
            ? Colors.white30
            : const Color(0xFFAAA093),
      ),
      suffixStyle: TextStyle(
        color: _subtitleColor,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(
            alpha: 0.10,
          ),
          borderRadius:
              BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 21,
          color: _primaryColor,
        ),
      ),
      filled: true,
      fillColor: _inputColor,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 2,
        ),
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [
                      const Color(0xFF1A2D49),
                      const Color(0xFF152238),
                    ]
                  : [
                      const Color(0xFFFFF5E8),
                      const Color(0xFFFFE8CD),
                    ],
            ),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor,
                      _secondaryColor,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor
                          .withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset:
                          const Offset(0, 9),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isEdit
                      ? Icons.edit_note_rounded
                      : Icons.add_chart_rounded,
                  size: 36,
                  color: _buttonTextColor,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEdit
                          ? 'Edit Presentation'
                          : 'Create Presentation',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w900,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isEdit
                          ? 'Update the information and target duration.'
                          : 'Add the details before uploading slides and scripts.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: _subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -26,
          right: -22,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _primaryColor
                  .withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 21,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Set a realistic target time so the app can compare your actual presentation duration.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: _textColor,
              ),
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
            textInputAction:
                TextInputAction.next,
            maxLength: 100,
            style: TextStyle(
              color: _textColor,
            ),
            onFieldSubmitted: (_) {
              FocusScope.of(context)
                  .requestFocus(
                _descriptionFocusNode,
              );
            },
            decoration: _inputDecoration(
              label: 'Presentation title',
              hint:
                  'Example: Final Project Presentation',
              icon: Icons.title_rounded,
            ),
            validator: (value) {
              final title =
                  value?.trim() ?? '';

              if (title.isEmpty) {
                return 'Please enter a title';
              }

              if (title.length < 3) {
                return 'Title must contain at least 3 characters';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller:
                _descriptionController,
            focusNode:
                _descriptionFocusNode,
            enabled: !_isLoading,
            keyboardType:
                TextInputType.multiline,
            textInputAction:
                TextInputAction.newline,
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
            style: TextStyle(
              color: _textColor,
              height: 1.5,
            ),
            decoration: _inputDecoration(
              label: 'Description',
              hint:
                  'Describe the topic and purpose of this presentation',
              icon:
                  Icons.description_outlined,
            ),
            validator: (value) {
              final description =
                  value?.trim() ?? '';

              if (description.isEmpty) {
                return 'Please enter a description';
              }

              if (description.length < 5) {
                return 'Description must contain at least 5 characters';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _timeController,
            focusNode: _timeFocusNode,
            enabled: !_isLoading,
            keyboardType:
                TextInputType.number,
            textInputAction:
                TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
              LengthLimitingTextInputFormatter(
                3,
              ),
            ],
            style: TextStyle(
              color: _textColor,
            ),
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
              final text =
                  value?.trim() ?? '';

              if (text.isEmpty) {
                return 'Please enter a target duration';
              }

              final minutes =
                  int.tryParse(text);

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
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : widget.isEdit
                      ? _handleUpdate
                      : _handleSave,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _primaryColor,
                disabledBackgroundColor:
                    _primaryColor.withValues(
                  alpha: 0.50,
                ),
                foregroundColor:
                    _buttonTextColor,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : Icon(
                      widget.isEdit
                          ? Icons
                              .save_outlined
                          : Icons
                              .arrow_forward_rounded,
                    ),
              label: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                            _buttonTextColor,
                      ),
                    )
                  : Text(
                      widget.isEdit
                          ? 'Save Changes'
                          : 'Continue to Slides',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
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
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          34,
        ),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 680,
          ),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius:
                      BorderRadius.circular(26),
                  border: Border.all(
                    color: _borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black
                              .withValues(
                              alpha: 0.20,
                            )
                          : const Color(
                              0xFFB7773D,
                            ).withValues(
                              alpha: 0.08,
                            ),
                      blurRadius: 24,
                      offset:
                          const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable:
          ThemeController.isDarkMode,
      builder: (
        context,
        isDarkMode,
        _,
      ) {
        return Scaffold(
          backgroundColor:
              _backgroundColor,
          appBar: AppBar(
            backgroundColor:
                _backgroundColor,
            foregroundColor: _textColor,
            elevation: 0,
            titleSpacing: 8,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _primaryColor
                        .withValues(
                      alpha: 0.11,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    Icons.co_present_rounded,
                    color: _primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isEdit
                      ? 'Edit Presentation'
                      : 'New Presentation',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin:
                    const EdgeInsets.symmetric(
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                  border: Border.all(
                    color: _borderColor,
                  ),
                ),
                child: IconButton(
                  onPressed: _isLoading
                      ? null
                      : ThemeController
                          .toggleTheme,
                  icon: Icon(
                    isDarkMode
                        ? Icons
                            .wb_sunny_outlined
                        : Icons
                            .dark_mode_outlined,
                    color: _primaryColor,
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
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }
}