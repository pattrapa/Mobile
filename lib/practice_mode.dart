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

  List<Map<String, dynamic>> _slides = [];
  final Map<String, String> _slideScripts = {};

  int _currentSlideIndex = 0;
  int _seconds = 0;

  Timer? _timer;
  bool _isRunning = false;
  bool _canPauseResume = true;

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
    final slideData = await ApiService.getSlides(widget.presentationId);

    _slides = slideData
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    await Future.wait(
      _slides.map((slide) async {
        final slideId = slide['_id']?.toString();

        if (slideId == null) return;

        try {
          final scripts = await ApiService.getScripts(slideId);

          if (scripts.isNotEmpty) {
            final latestScript = scripts.last;
            _slideScripts[slideId] =
                latestScript['content']?.toString() ?? 'No script found';
          }
        } catch (_) {
          _slideScripts[slideId] = 'Error loading script';
        }
      }),
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
    if (!_canPauseResume) return;

    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    if (!_canPauseResume || _isRunning) return;

    setState(() => _isRunning = true);
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
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() => _seconds++);
      },
    );
  }

  void _finishPractice() {
    _timer?.cancel();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultSummaryScreen(
          actualTimeInSeconds: _seconds,
          targetTime: widget.targetTime,
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  String _imageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    final path = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;

    return '${ApiService.baseUrl}/$path';
  }

  String _currentScript() {
    if (_slides.isEmpty) return 'ไม่มีสคริปต์ในหน้านี้';

    final currentSlide = _slides[_currentSlideIndex];
    final slideId = currentSlide['_id']?.toString() ?? '';

    return _slideScripts[slideId] ?? 'ไม่มีสคริปต์ในหน้านี้';
  }

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _buildSlideViewer(),
          const SizedBox(height: 16),
          Expanded(child: _buildScriptBox()),
          const SizedBox(height: 16),
          _buildTimerBox(),
          const SizedBox(height: 16),
          _buildFinishButton(),
        ],
      ),
    );
  }

  Widget _buildSlideViewer() {
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Slide ${_currentSlideIndex + 1} / ${_slides.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C6BC0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() => _currentSlideIndex = index);
              },
              itemBuilder: (_, index) {
                final imageUrl = _imageUrl(
                  _slides[index]['imagePath']?.toString(),
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.image_not_supported, size: 50)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildPageIndicator(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) {
          final isActive = _currentSlideIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 10 : 8,
            height: isActive ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.pinkAccent : Colors.grey.shade300,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScriptBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Script',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C6BC0),
              ),
            ),
            const Divider(),
            Text(
              _currentScript(),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _formatTime(_seconds),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _TimerButton(
                label: 'Start',
                color: Colors.blue,
                onPressed: _startTimer,
              ),
              _TimerButton(
                label: 'Pause',
                color: Colors.orange,
                onPressed:
                    _isRunning && _canPauseResume ? _pauseTimer : null,
              ),
              _TimerButton(
                label: 'Resume',
                color: Colors.green,
                onPressed: !_isRunning && _canPauseResume && _seconds > 0
                    ? _resumeTimer
                    : null,
              ),
              _TimerButton(
                label: 'Stop',
                color: Colors.red,
                onPressed: _isRunning || (_seconds > 0 && _canPauseResume)
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
      height: 50,
      child: ElevatedButton(
        onPressed: _finishPractice,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC8FB4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Finish Practice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyOrError() {
    return const Center(
      child: Text('เกิดข้อผิดพลาด หรือไม่พบสไลด์'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Mode'),
        backgroundColor: const Color(0xFFEC8FB4),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError || _slides.isEmpty) {
            return _buildEmptyOrError();
          }

          return _buildMainContent();
        },
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _TimerButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}