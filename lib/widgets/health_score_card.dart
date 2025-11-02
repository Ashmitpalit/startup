import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HealthScoreCard extends StatelessWidget {
  final double score;
  final bool hasData;
  final bool showDetails;

  const HealthScoreCard({
    super.key,
    required this.score,
    this.hasData = false,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Score Circle
          _buildScoreCircle(context),

          if (showDetails) ...[
            const SizedBox(height: 20),
            _buildScoreDetails(context),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCircle(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
        ),

        // Progress Circle
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: hasData ? score / 100 : 0.0,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
          ),
        ),

        // Score Text
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasData ? score.toStringAsFixed(0) : '--',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            Text(
              'Health Score',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut);
  }

  Widget _buildScoreDetails(BuildContext context) {
    return Column(
      children: [
        // Status Text
        Text(
          _getStatusText(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _getScoreColor(),
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Description
        Text(
          _getStatusDescription(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Risk Level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getRiskColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getRiskColor().withOpacity(0.5)),
          ),
          child: Text(
            'Injury Risk: ${_getRiskLevel()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getRiskColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor() {
    if (!hasData) return Colors.grey;
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.red;
    return Colors.red.shade800;
  }

  String _getStatusText() {
    if (!hasData) return 'No Data';
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 60) return 'Poor';
    return 'Critical';
  }

  String _getStatusDescription() {
    if (!hasData) return 'Run a scan to get your health score';
    if (score >= 90) return 'Your gait is excellent! Keep up the great work.';
    if (score >= 80)
      return 'Your gait is good with minor areas for improvement.';
    if (score >= 70) return 'Your gait is fair. Consider some adjustments.';
    if (score >= 60) return 'Your gait needs attention. Focus on improvements.';
    return 'Your gait requires immediate attention. Consult a professional.';
  }

  Color _getRiskColor() {
    if (!hasData) return Colors.grey;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getRiskLevel() {
    if (!hasData) return 'Unknown';
    if (score >= 80) return 'Low';
    if (score >= 60) return 'Medium';
    return 'High';
  }
}


