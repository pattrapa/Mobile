import 'package:flutter/material.dart';
import 'package:flutter_project/home.dart';
import 'package:intl/intl.dart';

class ResultSummaryScreen extends StatelessWidget {
  final int actualTimeInSeconds;
  final String targetTime;

  const ResultSummaryScreen({
    super.key,
    required this.actualTimeInSeconds,
    required this.targetTime,
  });

  String get _formattedActualTime {
    final minutes = (actualTimeInSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (actualTimeInSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  String get _formattedTargetTime {
    final minutes = int.tryParse(targetTime) ?? 0;
    return '${minutes.toString().padLeft(2, '0')}:00';
  }

  String get _lastPracticedTime {
    final now = DateTime.now();
    return 'Today, ${DateFormat('HH:mm').format(now)}';
  }

  void _goBackHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Widget _buildHeader() {
    return _Panel(
      child: const Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 60,
            color: Color(0xFFEC8FB4),
          ),
          SizedBox(height: 12),
          Text(
            'Practice Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C6BC0),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Here is your latest practice result',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        _SummaryCard(
          title: 'Total Actual Time',
          value: _formattedActualTime,
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: 'Total Target Time',
          value: _formattedTargetTime,
          icon: Icons.schedule,
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: 'Last Practiced',
          value: _lastPracticedTime,
          icon: Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _goBackHome(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC8FB4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Back to Home',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Summary'),
        backgroundColor: const Color(0xFFEC8FB4),
        foregroundColor: Colors.white,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSummaryCards(),
                const Spacer(),
                _buildBackButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF7AA6E8),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C6BC0),
            ),
          ),
        ],
      ),
    );
  }
}