import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/login_screen.dart';
import 'package:flutter_project/presentation.dart';
import 'package:flutter_project/slide_management.dart';
import 'package:flutter_project/theme_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _presentations = [];

  bool _isLoading = true;
  bool get _isDarkMode => ThemeController.isDarkMode.value;

  @override
  void initState() {
    super.initState();
    _loadPresentations();
  }

  Future<void> _loadPresentations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

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

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Error loading presentations: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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

    if (id == null || id.isEmpty) {
      _showSnackBar('Presentation ID not found');
      return;
    }

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

    if (!mounted) return;
    await _loadPresentations();
  }

  Future<void> _openEditPresentation(Map<String, dynamic> item) async {
    final id = item['_id']?.toString();

    if (id == null || id.isEmpty) {
      _showSnackBar('Presentation ID not found');
      return;
    }

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

    if (!mounted) return;
    await _loadPresentations();
  }

  Future<void> _deletePresentation(Map<String, dynamic> item) async {
    final id = item['_id']?.toString();

    if (id == null || id.isEmpty) {
      _showSnackBar('Presentation ID not found');
      return;
    }

    try {
      final isSuccess = await ApiService.deletePresentation(id);

      if (!mounted) return;

      if (isSuccess) {
        _showSnackBar('Presentation deleted');
        await _loadPresentations();
      } else {
        _showSnackBar('Delete failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Delete error: $e');
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final title = item['title']?.toString().trim();

    final displayTitle = title == null || title.isEmpty
        ? 'this presentation'
        : '"$title"';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final textColor = _isDarkMode ? Colors.white : const Color(0xFF2D261E);

        final subtitleColor = _isDarkMode
            ? Colors.white70
            : const Color(0xFF6B5E4E);

        return AlertDialog(
          backgroundColor: _isDarkMode
              ? const Color(0xFF1E293B)
              : const Color(0xFFFFFDF9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete Presentation',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete $displayTitle?',
            style: TextStyle(color: subtitleColor, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white60 : const Color(0xFF6B5E4E),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deletePresentation(item);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final textColor = _isDarkMode ? Colors.white : const Color(0xFF2D261E);

        final subtitleColor = _isDarkMode
            ? Colors.white70
            : const Color(0xFF6B5E4E);

        return AlertDialog(
          backgroundColor: _isDarkMode
              ? const Color(0xFF1E293B)
              : const Color(0xFFFFFDF9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: _isDarkMode
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: subtitleColor, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white60 : const Color(0xFF6B5E4E),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
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

  Widget _buildHeader({
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isDarkMode
              ? const Color(0xFF334155)
              : const Color(0xFFEFEBE3),
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF7A7062).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your presentations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_presentations.length} presentation${_presentations.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isLoading ? null : _loadPresentations,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          color: subtitleColor,
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
  }) {
    return RefreshIndicator(
      onRefresh: _loadPresentations,
      color: primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 70),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFEFEBE3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.slideshow_rounded,
                        size: 44,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No presentations yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first presentation, add slides, and start practicing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: _openCreatePresentation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: _isDarkMode
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Create presentation',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _buildPresentationList({
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
  }) {
    return RefreshIndicator(
      onRefresh: _loadPresentations,
      color: primaryColor,
      child: ListView.builder(
        itemCount: _presentations.length,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemBuilder: (_, index) {
          final item = _presentations[index];

          return _PresentationCard(
            item: item,
            isDarkMode: _isDarkMode,
            targetMinutes: _targetMinutes(item['totalTargetTime']),
            onTap: () {
              _openPresentation(item);
            },
            onEdit: () {
              _openEditPresentation(item);
            },
            onDelete: () {
              _confirmDelete(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
  }) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_presentations.isEmpty) {
      return _buildEmptyState(
        textColor: textColor,
        subtitleColor: subtitleColor,
        primaryColor: primaryColor,
      );
    }

    return _buildPresentationList(
      textColor: textColor,
      subtitleColor: subtitleColor,
      primaryColor: primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, isDarkMode, _) {
        final backgroundColor = isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFFAF6EE);

        final appBarColor = isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFFAF6EE);

        final primaryColor = isDarkMode
            ? const Color(0xFF38BDF8)
            : const Color(0xFFD97706);

        final textColor = isDarkMode ? Colors.white : const Color(0xFF2D261E);

        final subtitleColor = isDarkMode
            ? Colors.white60
            : const Color(0xFF6B5E4E);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: appBarColor,
            foregroundColor: textColor,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 20,
            title: Row(
              children: [
                Icon(Icons.mic_none_rounded, color: primaryColor),
                const SizedBox(width: 10),
                const Text(
                  'SpeakFlow',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: ThemeController.toggleTheme,
                icon: Icon(
                  isDarkMode
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                ),
                tooltip: isDarkMode
                    ? 'Switch to Warm Mode'
                    : 'Switch to Dark Mode',
              ),
              IconButton(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildBody(
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          primaryColor: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreatePresentation,
            backgroundColor: primaryColor,
            foregroundColor: isDarkMode
                ? const Color(0xFF0F172A)
                : Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New presentation',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
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
    final rawTitle = item['title']?.toString().trim() ?? '';
    final title = rawTitle.isEmpty ? 'Untitled presentation' : rawTitle;

    final description = item['description']?.toString().trim() ?? '';

    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    final titleColor = isDarkMode ? Colors.white : const Color(0xFF2D261E);

    final descriptionColor = isDarkMode
        ? Colors.white70
        : const Color(0xFF574E43);

    final secondaryColor = isDarkMode
        ? Colors.white60
        : const Color(0xFF7A7062);

    final primaryColor = isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFFD97706);

    final borderColor = isDarkMode
        ? const Color(0xFF334155)
        : const Color(0xFFEFEBE3);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.17)
                : const Color(0xFF7A7062).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: primaryColor.withValues(alpha: 0.10),
          highlightColor: primaryColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.co_present_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: descriptionColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label: '$targetMinutes min',
                            color: primaryColor,
                            isDarkMode: isDarkMode,
                          ),
                          _InfoChip(
                            icon: Icons.play_circle_outline_rounded,
                            label: 'Tap to practice',
                            color: secondaryColor,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  icon: Icon(Icons.more_vert_rounded, color: secondaryColor),
                  elevation: 5,
                  color: isDarkMode ? const Color(0xFF334155) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 19,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(0xFF574E43),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF2D261E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDarkMode;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFEBE3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : const Color(0xFF6B5E4E),
            ),
          ),
        ],
      ),
    );
  }
}
