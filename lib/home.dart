import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/login_screen.dart';
import 'package:flutter_project/presentation.dart';
import 'package:flutter_project/slide_management.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _presentations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresentations();
  }

  Future<void> _loadPresentations() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getPresentations();

      if (!mounted) return;

      setState(() {
        _presentations = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showSnackBar('Error loading presentations: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _targetMinutes(dynamic totalTargetTime) {
    final seconds = totalTargetTime is int
        ? totalTargetTime
        : int.tryParse(totalTargetTime?.toString() ?? '') ?? 0;

    return (seconds ~/ 60).toString();
  }
  
  void _openPresentation(Map<String, dynamic> item) {
    final id = item['_id']?.toString();
    if (id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlideManagementScreen(
          presentationId: id,
          targetTime: _targetMinutes(item['totalTargetTime']),
        ),
      ),
    );
  }

  Future<void> _openCreatePresentation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PresentationScreen()),
    );

    _loadPresentations();
  }
  // แก้ไข
  Future<void> _openEditPresentation(Map<String, dynamic> item) async {
    final id = item['_id']?.toString();
    if (id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresentationScreen(
          isEdit: true,
          id: id,
          title: item['title']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          time: _targetMinutes(item['totalTargetTime']),
        ),
      ),
    );

    _loadPresentations();
  }
  // ลบ
  Future<void> _deletePresentation(Map<String, dynamic> item) async {
    final id = item['_id']?.toString();
    if (id == null) return;

    final isSuccess = await ApiService.deletePresentation(id);

    if (!mounted) return;

    if (isSuccess) {
      _showSnackBar('Presentation deleted');
      await _loadPresentations();
    } else {
      _showSnackBar('Delete failed');
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final title = item['title']?.toString() ?? '';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Presentation'),
        content: Text('Are you sure you want to delete "$title"?'),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deletePresentation(item);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      ApiService.token = null;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C6BC0),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Choose a presentation to continue',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_presentations.isEmpty) {
      return const Center(child: Text('No presentations yet'));
    }

    return RefreshIndicator(
      onRefresh: _loadPresentations,
      child: ListView.builder(
        itemCount: _presentations.length,
        itemBuilder: (_, index) {
          final item = _presentations[index];
          return _PresentationCard(
            item: item,
            targetMinutes: _targetMinutes(item['totalTargetTime']),
            onTap: () => _openPresentation(item),
            onEdit: () => _openEditPresentation(item),
            onDelete: () => _confirmDelete(item),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Presentations'),
        backgroundColor: const Color(0xFFEC8FB4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePresentation,
        backgroundColor: const Color(0xFFEC8FB4),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PresentationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String targetMinutes;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PresentationCard({
    required this.item,
    required this.targetMinutes,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(title),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 18,
                  color: Color(0xFF7AA6E8),
                ),
                const SizedBox(width: 6),
                Text('Target time: $targetMinutes min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C6BC0),
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ],
    );
  }
}