import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/result_summary.dart';

class PracticeModeScreen extends StatefulWidget {
  final String presentationId;
  final String targetTime;

  const PracticeModeScreen({
    super.key,
    required this.presentationId,
    required this.targetTime,
  });

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  final PageController _pageController = PageController();

  final Map<String, String> _slideScripts = {};

  List<Map<String, dynamic>> _slides = [];

  int _currentSlideIndex = 0;
  int _seconds = 0;

  Timer? _timer;

  bool _isRunning = false;
  bool _canPauseResume = true;
  bool _isDarkMode = false;

  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final slideData = await ApiService.getSlides(
      widget.presentationId,
    );

    _slides = slideData
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    await Future.wait(
      _slides.map((slide) async {
        final slideId = slide['_id']?.toString();

        if (slideId == null || slideId.isEmpty) return;

        try {
          final scripts = await ApiService.getScripts(slideId);

          if (scripts.isNotEmpty) {
            final latestScript = scripts.last;

            _slideScripts[slideId] =
                latestScript['content']?.toString().trim().isNotEmpty == true
                    ? latestScript['content'].toString()
                    : 'No script found';
          } else {
            _slideScripts[slideId] = 'No script found';
          }
        } catch (_) {
          _slideScripts[slideId] = 'Error loading script';
        }
      }),
    );
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

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _seconds = 0;
      _isRunning = true;
      _canPauseResume = true;
    });

    _startTicking();
  }

  void _pauseTimer() {
    if (!_canPauseResume || !_isRunning) return;

    _timer?.cancel();

    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    if (!_canPauseResume || _isRunning || _seconds <= 0) return;

    setState(() {
      _isRunning = true;
    });

    _startTicking();
  }

  void _stopTimer() {
    _timer?.cancel();

    setState(() {
      _isRunning = false;
      _canPauseResume = false;
    });
  }

  void _startTicking() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _seconds++;
        });
      },
    );
  }

  Future<void> _finishPractice() async {
    _timer?.cancel();

    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final textColor = _isDarkMode
            ? Colors.white
            : const Color(0xFF2D261E);

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
                Icons.flag_outlined,
                color: _primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Finish Practice',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your practice time is ${_formatTime(_seconds)}. Do you want to finish and view the summary?',
            style: TextStyle(
              color: subtitleColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  color: subtitleColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _buttonTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Finish'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (shouldFinish == true) {
      setState(() {
        _isRunning = false;
        _canPauseResume = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultSummaryScreen(
            actualTimeInSeconds: _seconds,
            targetTime: widget.targetTime,
          ),
        ),
      );
    } else if (_isRunning) {
      _startTicking();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  String _formatTargetTime() {
    final targetMinutes = int.tryParse(widget.targetTime) ?? 0;

    if (targetMinutes <= 0) {
      return '${widget.targetTime} min';
    }

    return '$targetMinutes min';
  }

  String _imageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return '';

    final trimmedPath = imagePath.trim();

    final path = trimmedPath.startsWith('/')
        ? trimmedPath.substring(1)
        : trimmedPath;

    return '${ApiService.baseUrl}/$path';
  }

  String _currentScript() {
    if (_slides.isEmpty) {
      return 'No script for this slide';
    }

    if (_currentSlideIndex >= _slides.length) {
      return 'No script for this slide';
    }

    final currentSlide = _slides[_currentSlideIndex];
    final slideId = currentSlide['_id']?.toString() ?? '';

    final script = _slideScripts[slideId]?.trim();

    if (script == null || script.isEmpty) {
      return 'No script for this slide';
    }

    return script;
  }

  void _goToPreviousSlide() {
    if (_currentSlideIndex <= 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goToNextSlide() {
    if (_currentSlideIndex >= _slides.length - 1) return;

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Color get _backgroundColor {
    return _isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFFAF6EE);
  }

  Color get _cardColor {
    return _isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;
  }

  Color get _textColor {
    return _isDarkMode
        ? Colors.white
        : const Color(0xFF2D261E);
  }

  Color get _subtitleColor {
    return _isDarkMode
        ? Colors.white60
        : const Color(0xFF6B5E4E);
  }

  Color get _primaryColor {
    return _isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFFD97706);
  }

  Color get _borderColor {
    return _isDarkMode
        ? const Color(0xFF334155)
        : const Color(0xFFEFEBE3);
  }

  Color get _buttonTextColor {
    return _isDarkMode
        ? const Color(0xFF0F172A)
        : Colors.white;
  }

  BoxDecoration _cardDecoration({
    double radius = 22,
  }) {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: _borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withValues(alpha: 0.18)
              : const Color(0xFF7A7062).withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 850;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1180,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20,
              ),
              child: isWideScreen
                  ? _buildWideLayout()
                  : _buildCompactLayout(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Column(
      children: [
        _buildPracticeHeader(),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: _buildSlideViewer(),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildScriptBox(),
                    ),
                    const SizedBox(height: 18),
                    _buildTimerBox(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildFinishButton(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        _buildPracticeHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              SizedBox(
                height: 300,
                child: _buildSlideViewer(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: _buildScriptBox(),
              ),
              const SizedBox(height: 16),
              _buildTimerBox(),
              const SizedBox(height: 16),
              _buildFinishButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.record_voice_over_rounded,
              color: _primaryColor,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Follow your slides, read the script, and maintain your pacing.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildHeaderInfo(
            icon: Icons.schedule_rounded,
            label: 'Target',
            value: _formatTargetTime(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 19,
            color: _primaryColor,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: _subtitleColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideViewer() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.slideshow_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 9),
                Text(
                  'Slide ${_currentSlideIndex + 1} of ${_slides.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _currentSlideIndex > 0
                      ? _goToPreviousSlide
                      : null,
                  tooltip: 'Previous slide',
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                  ),
                  color: _primaryColor,
                ),
                IconButton(
                  onPressed: _currentSlideIndex < _slides.length - 1
                      ? _goToNextSlide
                      : null,
                  tooltip: 'Next slide',
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  color: _primaryColor,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: _borderColor,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8F7F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _borderColor,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSlideIndex = index;
                    });
                  },
                  itemBuilder: (_, index) {
                    final imageUrl = _imageUrl(
                      _slides[index]['imagePath']?.toString(),
                    );

                    if (imageUrl.isEmpty) {
                      return _buildMissingImage(
                        icon: Icons.image_not_supported_outlined,
                        message: 'No slide image',
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                        ) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return Center(
                            child: CircularProgressIndicator(
                              color: _primaryColor,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return _buildMissingImage(
                            icon: Icons.broken_image_outlined,
                            message: 'Unable to load slide image',
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 16,
            ),
            child: _buildPageIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingImage({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 52,
            color: _subtitleColor,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: _subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    const maxIndicators = 10;

    if (_slides.length > maxIndicators) {
      return Text(
        '${_currentSlideIndex + 1} / ${_slides.length}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _subtitleColor,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) {
          final isActive = _currentSlideIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isActive
                  ? _primaryColor
                  : _borderColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScriptBox() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 9),
                Text(
                  'Presentation Script',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: _borderColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: SelectableText(
                _currentScript(),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: _textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox() {
    String statusText;
    IconData statusIcon;

    if (_isRunning) {
      statusText = 'Timer running';
      statusIcon = Icons.fiber_manual_record_rounded;
    } else if (_seconds > 0 && _canPauseResume) {
      statusText = 'Timer paused';
      statusIcon = Icons.pause_circle_outline_rounded;
    } else if (_seconds > 0 && !_canPauseResume) {
      statusText = 'Timer stopped';
      statusIcon = Icons.stop_circle_outlined;
    } else {
      statusText = 'Ready to practice';
      statusIcon = Icons.timer_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                size: 16,
                color: _isRunning
                    ? Colors.redAccent
                    : _subtitleColor,
              ),
              const SizedBox(width: 7),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _subtitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatTime(_seconds),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target ${_formatTargetTime()}',
            style: TextStyle(
              fontSize: 13,
              color: _subtitleColor,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _TimerButton(
                label: _seconds > 0 ? 'Restart' : 'Start',
                icon: Icons.play_arrow_rounded,
                color: _primaryColor,
                foregroundColor: _buttonTextColor,
                onPressed: _startTimer,
              ),
              _TimerButton(
                label: 'Pause',
                icon: Icons.pause_rounded,
                color: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                onPressed: _isRunning && _canPauseResume
                    ? _pauseTimer
                    : null,
              ),
              _TimerButton(
                label: 'Resume',
                icon: Icons.play_circle_outline_rounded,
                color: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                onPressed: !_isRunning &&
                        _canPauseResume &&
                        _seconds > 0
                    ? _resumeTimer
                    : null,
              ),
              _TimerButton(
                label: 'Stop',
                icon: Icons.stop_rounded,
                color: Colors.redAccent,
                foregroundColor: Colors.white,
                onPressed: _isRunning ||
                        (_seconds > 0 && _canPauseResume)
                    ? _stopTimer
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _seconds > 0
            ? _finishPractice
            : () {
                _showSnackBar(
                  'Please start the timer before finishing practice',
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _buttonTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(
          Icons.flag_rounded,
        ),
        label: const Text(
          'Finish Practice',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading practice session...',
              style: TextStyle(
                color: _subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrError({
    required bool hasError,
  }) {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 34,
              ),
              decoration: _cardDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasError
                          ? Icons.error_outline_rounded
                          : Icons.slideshow_outlined,
                      size: 42,
                      color: hasError
                          ? Colors.redAccent
                          : _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    hasError
                        ? 'Unable to load practice'
                        : 'No slides found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasError
                        ? 'An error occurred while loading the slides. Please try again.'
                        : 'Add at least one slide before starting practice mode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: _subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadDataFuture = _loadData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _buttonTextColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Try again',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        titleSpacing: 8,
        title: Row(
          children: [
            Icon(
              Icons.mic_none_rounded,
              color: _primaryColor,
            ),
            const SizedBox(width: 9),
            const Text(
              'Practice Mode',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            tooltip: _isDarkMode
                ? 'Switch to Warm Mode'
                : 'Switch to Dark Mode',
            icon: Icon(
              _isDarkMode
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loadDataFuture,
          builder: (_, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return _buildLoading();
            }

            if (snapshot.hasError) {
              return _buildEmptyOrError(
                hasError: true,
              );
            }

            if (_slides.isEmpty) {
              return _buildEmptyOrError(
                hasError: false,
              );
            }

            return _buildMainContent();
          },
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  const _TimerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: color.withValues(alpha: 0.28),
        disabledForegroundColor:
            foregroundColor.withValues(alpha: 0.55),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      icon: Icon(
        icon,
        size: 19,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}