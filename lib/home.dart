import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/decorative_background.dart';
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

      _showSnackBar(
        'Error loading presentations: $e',
      );
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
        : int.tryParse(
              totalTargetTime?.toString() ?? '',
            ) ??
            0;

    return (seconds ~/ 60).toString();
  }

  void _openPresentation(
    Map<String, dynamic> item,
  ) {
    final id = item['_id']?.toString();

    if (id == null || id.isEmpty) {
      _showSnackBar(
        'Presentation ID not found',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlideManagementScreen(
          presentationId: id,
          targetTime: _targetMinutes(
            item['totalTargetTime'],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreatePresentation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PresentationScreen(),
      ),
    );

    if (!mounted) return;

    await _loadPresentations();
  }

  Future<void> _openEditPresentation(
    Map<String, dynamic> item,
  ) async {
    final id = item['_id']?.toString();

    if (id == null || id.isEmpty) {
      _showSnackBar(
        'Presentation ID not found',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresentationScreen(
          isEdit: true,
          id: id,
          title: item['title']?.toString() ?? '',
          description:
              item['description']?.toString() ??
                  '',
          time: _targetMinutes(
            item['totalTargetTime'],
          ),
        ),
      ),
    );

    if (!mounted) return;

    await _loadPresentations();
  }

  Future<void> _deletePresentation(
    Map<String, dynamic> item,
  ) async {
    final id = item['_id']?.toString();

    if (id == null || id.isEmpty) {
      _showSnackBar(
        'Presentation ID not found',
      );
      return;
    }

    try {
      final isSuccess =
          await ApiService.deletePresentation(id);

      if (!mounted) return;

      if (isSuccess) {
        _showSnackBar(
          'Presentation deleted',
        );

        await _loadPresentations();
      } else {
        _showSnackBar('Delete failed');
      }
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Delete error: $e',
      );
    }
  }

  Future<void> _confirmDelete(
    Map<String, dynamic> item,
  ) async {
    final rawTitle =
        item['title']?.toString().trim();

    final displayTitle =
        rawTitle == null || rawTitle.isEmpty
            ? 'this presentation'
            : '"$rawTitle"';

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final textColor = _isDarkMode
            ? Colors.white
            : const Color(0xFF29231D);

        final subtitleColor = _isDarkMode
            ? Colors.white70
            : const Color(0xFF74685A);

        return AlertDialog(
          backgroundColor: _isDarkMode
              ? const Color(0xFF152238)
              : const Color(0xFFFFFDF9),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.redAccent
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Presentation',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete '
            '$displayTitle?',
            style: TextStyle(
              color: subtitleColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: subtitleColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
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
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final textColor = _isDarkMode
            ? Colors.white
            : const Color(0xFF29231D);

        final subtitleColor = _isDarkMode
            ? Colors.white70
            : const Color(0xFF74685A);

        final primaryColor = _isDarkMode
            ? const Color(0xFF38BDF8)
            : const Color(0xFFF97316);

        return AlertDialog(
          backgroundColor: _isDarkMode
              ? const Color(0xFF152238)
              : const Color(0xFFFFFDF9),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: subtitleColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: subtitleColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
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
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (_) => false,
      );
    }
  }

  Widget _buildSummaryHeader({
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [
                  const Color(0xFF182A45),
                  const Color(0xFF132037),
                ]
              : [
                  const Color(0xFFFFFDF9),
                  const Color(0xFFFFF1DF),
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withValues(
                    alpha: 0.18,
                  )
                : const Color(0xFFB7773D)
                    .withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.09,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -40,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                border: Border.all(
                  color: primaryColor.withValues(
                    alpha: 0.16,
                  ),
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      _isDarkMode
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFF59E0B),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(19),
                ),
                child: Icon(
                  Icons.co_present_rounded,
                  color: _isDarkMode
                      ? const Color(0xFF07111F)
                      : Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to practice?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Choose a presentation and improve '
                      'your timing, pacing, and delivery.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: subtitleColor,
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

  Widget _buildSectionTitle({
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 42,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Your presentations',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_presentations.length} '
                'presentation'
                '${_presentations.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed:
                _isLoading ? null : _loadPresentations,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    return RefreshIndicator(
      onRefresh: _loadPresentations,
      color: primaryColor,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 34,
          bottom: 110,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 440),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 38,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(26),
                  border: Border.all(
                    color: borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black.withValues(
                              alpha: 0.17,
                            )
                          : const Color(0xFFB7773D)
                              .withValues(
                              alpha: 0.07,
                            ),
                      blurRadius: 22,
                      offset:
                          const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(
                              alpha: 0.18,
                            ),
                            primaryColor.withValues(
                              alpha: 0.06,
                            ),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(28),
                      ),
                      child: Icon(
                        Icons.slideshow_rounded,
                        size: 48,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'No presentations yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Create your first presentation, '
                      'add slides, and start practicing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed:
                          _openCreatePresentation,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor,
                        foregroundColor:
                            _isDarkMode
                                ? const Color(
                                    0xFF07111F,
                                  )
                                : Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 15,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                      ),
                      label: const Text(
                        'Create presentation',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
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
    required Color primaryColor,
  }) {
    return RefreshIndicator(
      onRefresh: _loadPresentations,
      color: primaryColor,
      child: ListView.builder(
        itemCount: _presentations.length,
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 4,
          bottom: 110,
        ),
        itemBuilder: (_, index) {
          final item = _presentations[index];

          return _PresentationCard(
            index: index,
            item: item,
            isDarkMode: _isDarkMode,
            targetMinutes: _targetMinutes(
              item['totalTargetTime'],
            ),
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
    required Color cardColor,
    required Color borderColor,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_presentations.isEmpty) {
      return _buildEmptyState(
        textColor: textColor,
        subtitleColor: subtitleColor,
        primaryColor: primaryColor,
        cardColor: cardColor,
        borderColor: borderColor,
      );
    }

    return _buildPresentationList(
      primaryColor: primaryColor,
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
        final backgroundColor = isDarkMode
            ? const Color(0xFF0B1220)
            : const Color(0xFFFFF9F1);

        final appBarColor = isDarkMode
            ? const Color(0xFF0B1220)
            : const Color(0xFFFFF9F1);

        final primaryColor = isDarkMode
            ? const Color(0xFF38BDF8)
            : const Color(0xFFF97316);

        final textColor = isDarkMode
            ? Colors.white
            : const Color(0xFF29231D);

        final subtitleColor = isDarkMode
            ? Colors.white60
            : const Color(0xFF74685A);

        final cardColor = isDarkMode
            ? const Color(0xFF152238)
            : Colors.white;

        final borderColor = isDarkMode
            ? const Color(0xFF2C405D)
            : const Color(0xFFF1E5D6);

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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.co_present_rounded,
                    color: primaryColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w900,
                      color: textColor,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Speak',
                      ),
                      TextSpan(
                        text: 'Flow',
                        style: TextStyle(
                          color: primaryColor,
                        ),
                      ),
                    ],
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
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(13),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: IconButton(
                  onPressed:
                      ThemeController.toggleTheme,
                  icon: Icon(
                    isDarkMode
                        ? Icons
                            .wb_sunny_outlined
                        : Icons
                            .dark_mode_outlined,
                    color: primaryColor,
                  ),
                  tooltip: isDarkMode
                      ? 'Switch to Warm Mode'
                      : 'Switch to Dark Mode',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin:
                    const EdgeInsets.symmetric(
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(13),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: IconButton(
                  onPressed: _confirmLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                  tooltip: 'Logout',
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: DecorativeBackground(
            isDarkMode: isDarkMode,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 980,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildSummaryHeader(
                          textColor: textColor,
                          subtitleColor:
                              subtitleColor,
                          primaryColor:
                              primaryColor,
                          cardColor: cardColor,
                          borderColor:
                              borderColor,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          textColor: textColor,
                          subtitleColor:
                              subtitleColor,
                          primaryColor:
                              primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildBody(
                            textColor:
                                textColor,
                            subtitleColor:
                                subtitleColor,
                            primaryColor:
                                primaryColor,
                            cardColor:
                                cardColor,
                            borderColor:
                                borderColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton:
              FloatingActionButton.extended(
            onPressed:
                _openCreatePresentation,
            backgroundColor: primaryColor,
            foregroundColor: isDarkMode
                ? const Color(0xFF07111F)
                : Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(17),
            ),
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'New presentation',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PresentationCard
    extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final String targetMinutes;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PresentationCard({
    required this.index,
    required this.item,
    required this.targetMinutes,
    required this.isDarkMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _accentColor {
    final lightColors = [
      const Color(0xFFF97316),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    final darkColors = [
      const Color(0xFF38BDF8),
      const Color(0xFF818CF8),
      const Color(0xFF2DD4BF),
      const Color(0xFFA78BFA),
    ];

    final colors =
        isDarkMode ? darkColors : lightColors;

    return colors[index % colors.length];
  }

  IconData get _presentationIcon {
    final icons = [
      Icons.track_changes_rounded,
      Icons.lightbulb_outline_rounded,
      Icons.bar_chart_rounded,
      Icons.auto_graph_rounded,
    ];

    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final rawTitle =
        item['title']?.toString().trim() ??
            '';

    final title = rawTitle.isEmpty
        ? 'Untitled presentation'
        : rawTitle;

    final description =
        item['description']?.toString().trim() ??
            '';

    final cardColor = isDarkMode
        ? const Color(0xFF152238)
        : Colors.white;

    final titleColor = isDarkMode
        ? Colors.white
        : const Color(0xFF29231D);

    final descriptionColor = isDarkMode
        ? Colors.white70
        : const Color(0xFF62584D);

    final secondaryColor = isDarkMode
        ? Colors.white60
        : const Color(0xFF817365);

    final borderColor = isDarkMode
        ? const Color(0xFF2C405D)
        : const Color(0xFFF1E5D6);

    final accent = _accentColor;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(
                    alpha: 0.16,
                  )
                : const Color(0xFFB7773D)
                    .withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor:
                accent.withValues(alpha: 0.10),
            highlightColor:
                accent.withValues(alpha: 0.05),
            child: Stack(
              children: [
                Positioned(
                  top: -42,
                  right: -34,
                  child: Container(
                    width: 115,
                    height: 115,
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: 0.07,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end:
                            Alignment.bottomCenter,
                        colors: [
                          accent,
                          accent.withValues(
                            alpha: 0.45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    18,
                    14,
                    18,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            17,
                          ),
                        ),
                        child: Icon(
                          _presentationIcon,
                          color: accent,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w900,
                                color: titleColor,
                              ),
                            ),
                            if (description
                                .isNotEmpty) ...[
                              const SizedBox(height: 7),
                              Text(
                                description,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color:
                                      descriptionColor,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 9,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons
                                      .schedule_rounded,
                                  label:
                                      '$targetMinutes min',
                                  color: accent,
                                  isDarkMode:
                                      isDarkMode,
                                ),
                                _InfoChip(
                                  icon: Icons
                                      .play_circle_outline_rounded,
                                  label:
                                      'Tap to practice',
                                  color: accent,
                                  isDarkMode:
                                      isDarkMode,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        tooltip: 'More options',
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: secondaryColor,
                        ),
                        elevation: 6,
                        color: isDarkMode
                            ? const Color(
                                0xFF1B2D49,
                              )
                            : Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value ==
                              'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .edit_outlined,
                                  size: 19,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : const Color(
                                          0xFF62584D,
                                        ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(
                                            0xFF29231D,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<
                              String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .delete_outline_rounded,
                                  size: 19,
                                  color:
                                      Colors.redAccent,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color:
                                        Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: isDarkMode ? 0.10 : 0.08,
        ),
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: color.withValues(
            alpha: isDarkMode ? 0.23 : 0.18,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? Colors.white70
                  : const Color(0xFF62584D),
            ),
          ),
        ],
      ),
    );
  }
}