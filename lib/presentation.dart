import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/slide_management.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

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
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
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

        final presentationId = item['_id'] ?? item['presentation']?['_id'];

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presentation created successfully')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SlideManagementScreen(
              presentationId: presentationId,
              targetTime: _timeController.text.trim(),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create failed: $e')),
        );
      }
    }
  }

  void _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      try {
        final title = _titleController.text.trim();
        final description = _descriptionController.text.trim();
        final timeInMinutes = int.parse(_timeController.text.trim());
        final timeInSeconds = timeInMinutes * 60;

        final isSuccess = await ApiService.updatePresentation(
          id: widget.id!,
          title: title,
          description: description,
          totalTargetTime: timeInSeconds,
        );

        if (!mounted) return;

        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Presentation updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Update failed')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF7AA6E8)),
      filled: true,
      fillColor: const Color(0xFFFDFDFF),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD7E9FF),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFEC8FB4),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Presentation' : 'Add Presentation'),
        backgroundColor: const Color(0xFFEC8FB4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4EC), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.slideshow_outlined,
                      size: 60,
                      color: Color(0xFFEC8FB4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isEdit
                          ? 'Edit Presentation Details'
                          : 'Presentation Details',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Title', Icons.title),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration(
                        'Description',
                        Icons.description_outlined,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timeController,
                      decoration: _inputDecoration(
                        'Total Target Time (minutes)',
                        Icons.schedule,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter target time';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter numbers only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC8FB4),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: widget.isEdit ? _handleUpdate : _handleSave,
                        child: Text(
                          widget.isEdit ? 'Update' : 'Save',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}