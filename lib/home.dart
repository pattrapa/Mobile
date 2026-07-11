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
  // เพิ่มตัวแปรสำหรับควบคุมโหมดสี (Warm Cream / Dark Mode)
  bool _isDarkMode = false;

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
      );
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
        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFDF9),
        title: Text(
          'Delete Presentation',
          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF2D261E)),
        ),
        content: Text(
          'Are you sure you want to delete "$title"?',
          style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFDF9),
        title: Text(
          'Logout',
          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF2D261E)),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a presentation to start practicing',
          style: TextStyle(
            fontSize: 14, 
            color: _isDarkMode ? Colors.white60 : const Color(0xFF6B5E4E),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706),
          ),
        ),
      );
    }

    if (_presentations.isEmpty) {
      return Center(
        child: Text(
          'No presentations yet',
          style: TextStyle(
            fontSize: 16,
            color: _isDarkMode ? Colors.white38 : Colors.black38,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPresentations,
      color: _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706),
      child: ListView.builder(
        itemCount: _presentations.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (_, index) {
          final item = _presentations[index];
          return _PresentationCard(
            item: item,
            isDarkMode: _isDarkMode,
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
    // กำหนดสีหลักตามโหมดปัจจุบัน
    final backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAF6EE);
    final appBarColor = _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3EFE6);
    final primaryColor = _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Presentations',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: appBarColor,
        foregroundColor: _isDarkMode ? Colors.white : const Color(0xFF2D261E),
        actions: [
          // ปุ่มสลับโหมดสีอยู่มุมบนขวาตามต้องการ
          IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: _isDarkMode ? 'Switch to Warm Mode' : 'Switch to Dark Mode',
          ),
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        backgroundColor: primaryColor,
        foregroundColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _PresentationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String targetMinutes;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PresentationCard({
    required this.item,
    required this.targetMinutes,
    required this.isDarkMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';

    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF2D261E);
    final descColor = isDarkMode ? Colors.white70 : const Color(0xFF574E43);
    final iconColor = isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.transparent : const Color(0xFFEFEBE3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withValues(alpha: 0.2) 
                : const Color(0xFF7A7062).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        // เปลี่ยนสีของ InkWell Splash เอฟเฟกต์ให้เข้ากับธีม
        data: Theme.of(context).copyWith(
          splashColor: iconColor.withValues(alpha: 0.1),
          highlightColor: iconColor.withValues(alpha: 0.05),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(title, titleColor),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: descColor, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: iconColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Target time: $targetMinutes min',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white60 : const Color(0xFF7A7062),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(String title, Color titleColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white54 : Colors.black45),
          elevation: 4,
          backgroundColor: isDarkMode ? const Color(0xFF334155) : Colors.white, // ห้ามใส่ const นำหน้าเงื่อนไขตัวแปร
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: isDarkMode ? Colors.white70 : Colors.black70),
                  const SizedBox(width: 10),
                  Text('Edit', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}