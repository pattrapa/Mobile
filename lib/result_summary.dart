import 'package:flutter/material.dart';
import 'package:flutter_project/home.dart';
import 'package:intl/intl.dart';
import 'package:flutter_project/theme_controller.dart';

class ResultSummaryScreen extends StatefulWidget {
  final int actualTimeInSeconds;
  final String targetTime;

  const ResultSummaryScreen({
    super.key,
    required this.actualTimeInSeconds,
    required this.targetTime,
  });

  @override
  State<ResultSummaryScreen> createState() => _ResultSummaryScreenState();
}

class _ResultSummaryScreenState extends State<ResultSummaryScreen> {
  bool _isDarkMode = false;

  int get _targetTimeInSeconds {
    final minutes = int.tryParse(widget.targetTime) ?? 0;
    return minutes * 60;
  }

  int get _timeDifference {
    return widget.actualTimeInSeconds - _targetTimeInSeconds;
  }

  double get _progressValue {
    if (_targetTimeInSeconds <= 0) return 0;

    final progress = widget.actualTimeInSeconds / _targetTimeInSeconds;

    return progress.clamp(0.0, 1.0);
  }

  String get _formattedActualTime {
    return _formatDuration(widget.actualTimeInSeconds);
  }

  String get _formattedTargetTime {
    return _formatDuration(_targetTimeInSeconds);
  }

  String get _formattedDifference {
    return _formatDuration(_timeDifference.abs());
  }

  String get _lastPracticedTime {
    final now = DateTime.now();
    return 'Today, ${DateFormat('HH:mm').format(now)}';
  }

  String get _resultTitle {
    if (_targetTimeInSeconds <= 0) {
      return 'Practice completed';
    }

    if (_timeDifference == 0) {
      return 'Perfect timing';
    }

    if (_timeDifference < 0) {
      return 'Finished ahead of time';
    }

    return 'Finished over target';
  }

  String get _resultMessage {
    if (_targetTimeInSeconds <= 0) {
      return 'Your practice session has been recorded successfully.';
    }

    if (_timeDifference == 0) {
      return 'You matched your target duration exactly. Great pacing!';
    }

    if (_timeDifference < 0) {
      return 'You finished $_formattedDifference earlier than your target time.';
    }

    return 'You finished $_formattedDifference later than your target time.';
  }

  IconData get _resultIcon {
    if (_targetTimeInSeconds <= 0) {
      return Icons.check_circle_outline_rounded;
    }

    if (_timeDifference == 0) {
      return Icons.verified_rounded;
    }

    if (_timeDifference < 0) {
      return Icons.speed_rounded;
    }

    return Icons.schedule_rounded;
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

  Color get _borderColor {
    return _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFEBE3);
  }

  Color get _buttonTextColor {
    return _isDarkMode ? const Color(0xFF0F172A) : Colors.white;
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? totalSeconds.abs() : totalSeconds;

    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final seconds = safeSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  BoxDecoration _cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _borderColor),
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

  void _goBackHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_resultIcon, size: 48, color: _primaryColor),
          ),
          const SizedBox(height: 18),
          Text(
            'Practice Summary',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _resultTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _resultMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: _subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeComparisonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: _primaryColor),
              const SizedBox(width: 9),
              Text(
                'Time Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _TimeValue(
                  label: 'Actual time',
                  value: _formattedActualTime,
                  icon: Icons.timer_outlined,
                  primaryColor: _primaryColor,
                  textColor: _textColor,
                  subtitleColor: _subtitleColor,
                  borderColor: _borderColor,
                  isDarkMode: _isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeValue(
                  label: 'Target time',
                  value: _formattedTargetTime,
                  icon: Icons.flag_outlined,
                  primaryColor: _primaryColor,
                  textColor: _textColor,
                  subtitleColor: _subtitleColor,
                  borderColor: _borderColor,
                  isDarkMode: _isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: _progressValue,
                    backgroundColor: _isDarkMode
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF3EFE6),
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _targetTimeInSeconds <= 0
                    ? 'No target'
                    : '${((_progressValue) * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _SummaryRow(
            title: 'Actual presentation time',
            value: _formattedActualTime,
            icon: Icons.timer_outlined,
            primaryColor: _primaryColor,
            textColor: _textColor,
            subtitleColor: _subtitleColor,
          ),
          Divider(height: 28, color: _borderColor),
          _SummaryRow(
            title: 'Target presentation time',
            value: _formattedTargetTime,
            icon: Icons.schedule_rounded,
            primaryColor: _primaryColor,
            textColor: _textColor,
            subtitleColor: _subtitleColor,
          ),
          Divider(height: 28, color: _borderColor),
          _SummaryRow(
            title: 'Time difference',
            value: _targetTimeInSeconds <= 0 ? '-' : _formattedDifference,
            icon: Icons.difference_rounded,
            primaryColor: _primaryColor,
            textColor: _textColor,
            subtitleColor: _subtitleColor,
          ),
          Divider(height: 28, color: _borderColor),
          _SummaryRow(
            title: 'Last practiced',
            value: _lastPracticedTime,
            icon: Icons.history_rounded,
            primaryColor: _primaryColor,
            textColor: _textColor,
            subtitleColor: _subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    String tip;

    if (_targetTimeInSeconds <= 0) {
      tip =
          'Set a target time before practicing to compare your pacing more clearly.';
    } else if (_timeDifference == 0) {
      tip =
          'Keep practicing with the same pace so your delivery remains consistent.';
    } else if (_timeDifference < 0) {
      tip =
          'Try adding clearer transitions or brief pauses between important points.';
    } else {
      tip =
          'Try shortening repeated explanations and focus on the main message of each slide.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 14, height: 1.5, color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _goBackHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _buttonTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.home_outlined),
        label: const Text(
          'Back to Home',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildTimeComparisonCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              const SizedBox(height: 16),
              _buildTipCard(),
              const SizedBox(height: 22),
              _buildBackButton(),
            ],
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
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: _backgroundColor,
              foregroundColor: _textColor,
              elevation: 0,
              titleSpacing: 20,
              title: Row(
                children: [
                  Icon(Icons.mic_none_rounded, color: _primaryColor),
                  const SizedBox(width: 9),
                  const Text(
                    'Result Summary',
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
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(child: _buildContent()),
          ),
        );
      },
    );
  }
}

class _TimeValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  final Color primaryColor;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final bool isDarkMode;

  const _TimeValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.primaryColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 25, color: primaryColor),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  final Color primaryColor;
  final Color textColor;
  final Color subtitleColor;

  const _SummaryRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.primaryColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 22, color: primaryColor),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, color: subtitleColor)),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
