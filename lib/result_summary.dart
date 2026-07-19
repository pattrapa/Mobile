import 'package:flutter/material.dart';
import 'package:flutter_project/decorative_background.dart';
import 'package:flutter_project/home.dart';
import 'package:flutter_project/theme_controller.dart';
import 'package:intl/intl.dart';

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
  bool get _isDarkMode => ThemeController.isDarkMode.value;

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

  Color get _surfaceColor {
    return _isDarkMode
        ? const Color(0xFF0F1A2C)
        : const Color(0xFFFFFCF8);
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds.abs();

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

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _borderColor),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withValues(alpha: 0.16)
              : const Color(0xFFB7773D).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  void _goBackHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (_) => false,
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.16)
                : const Color(0xFFB7773D).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor,
                  _secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _resultIcon,
              size: 30,
              color: _buttonTextColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Summary',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _resultTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _resultMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeComparisonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Time Comparison',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
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
                  surfaceColor: _surfaceColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeValue(
                  label: 'Target time',
                  value: _formattedTargetTime,
                  icon: Icons.flag_outlined,
                  primaryColor: _secondaryColor,
                  textColor: _textColor,
                  subtitleColor: _subtitleColor,
                  borderColor: _borderColor,
                  surfaceColor: _surfaceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: _progressValue,
                    backgroundColor: _surfaceColor,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _targetTimeInSeconds <= 0
                    ? 'No target'
                    : '${(_progressValue * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(17),
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
          Divider(height: 22, color: _borderColor),
          _SummaryRow(
            title: 'Target presentation time',
            value: _formattedTargetTime,
            icon: Icons.schedule_rounded,
            primaryColor: _primaryColor,
            textColor: _textColor,
            subtitleColor: _subtitleColor,
          ),
          Divider(height: 22, color: _borderColor),
          _SummaryRow(
            title: 'Time difference',
            value: _targetTimeInSeconds <= 0
                ? '-'
                : _formattedDifference,
            icon: Icons.difference_rounded,
            primaryColor: _primaryColor,
            textColor: _textColor,
            subtitleColor: _subtitleColor,
          ),
          Divider(height: 22, color: _borderColor),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              tip,
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

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _goBackHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _buttonTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.home_outlined),
        label: const Text(
          'Back to Home',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 12),
              _buildTimeComparisonCard(),
              const SizedBox(height: 12),
              _buildDetailsCard(),
              const SizedBox(height: 12),
              _buildTipCard(),
              const SizedBox(height: 16),
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
              titleSpacing: 18,
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assessment_outlined,
                      color: _primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Result Summary',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _borderColor),
                  ),
                  child: IconButton(
                    onPressed: ThemeController.toggleTheme,
                    icon: Icon(
                      isDarkMode
                          ? Icons.wb_sunny_outlined
                          : Icons.dark_mode_outlined,
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
  final Color surfaceColor;

  const _TimeValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.primaryColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: primaryColor,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: subtitleColor,
            ),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
