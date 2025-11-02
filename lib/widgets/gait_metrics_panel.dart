import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/gait_data.dart';

class GaitMetricsPanel extends StatelessWidget {
  final GaitData gaitData;

  const GaitMetricsPanel({super.key, required this.gaitData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gait Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detailed analysis of your walking pattern',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),

          // Metrics Grid
          _buildMetricsGrid(context),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Walking Speed',
                '${gaitData.walkingSpeed.toStringAsFixed(2)} m/s',
                Icons.speed,
                _getSpeedStatus(gaitData.walkingSpeed),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Cadence',
                '${gaitData.averageCadence.toStringAsFixed(0)} steps/min',
                Icons.timeline,
                _getCadenceStatus(gaitData.averageCadence),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Second row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Stride Length',
                '${gaitData.averageStrideLength.toStringAsFixed(2)} m',
                Icons.straighten,
                _getStrideStatus(gaitData.averageStrideLength),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Step Width',
                '${gaitData.averageStepWidth.toStringAsFixed(2)} m',
                Icons.open_in_full,
                _getStepWidthStatus(gaitData.averageStepWidth),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Third row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Symmetry',
                '${(gaitData.stepSymmetry * 100).toStringAsFixed(1)}%',
                Icons.balance,
                _getSymmetryStatus(gaitData.stepSymmetry),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Stance Phase',
                '${gaitData.stancePhasePercentage.toStringAsFixed(1)}%',
                Icons.pause_circle,
                _getStancePhaseStatus(gaitData.stancePhasePercentage),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(delay: 100.ms);
  }

  String _getSpeedStatus(double speed) {
    if (speed >= 1.2 && speed <= 1.6) return 'Optimal';
    if (speed >= 1.0 && speed <= 1.8) return 'Good';
    if (speed >= 0.8 && speed <= 2.0) return 'Fair';
    return 'Needs Attention';
  }

  String _getCadenceStatus(double cadence) {
    if (cadence >= 100 && cadence <= 120) return 'Optimal';
    if (cadence >= 90 && cadence <= 130) return 'Good';
    if (cadence >= 80 && cadence <= 140) return 'Fair';
    return 'Needs Attention';
  }

  String _getStrideStatus(double stride) {
    if (stride >= 1.1 && stride <= 1.4) return 'Optimal';
    if (stride >= 1.0 && stride <= 1.5) return 'Good';
    if (stride >= 0.9 && stride <= 1.6) return 'Fair';
    return 'Needs Attention';
  }

  String _getStepWidthStatus(double width) {
    if (width >= 0.12 && width <= 0.18) return 'Optimal';
    if (width >= 0.10 && width <= 0.20) return 'Good';
    if (width >= 0.08 && width <= 0.22) return 'Fair';
    return 'Needs Attention';
  }

  String _getSymmetryStatus(double symmetry) {
    if (symmetry >= 0.95) return 'Excellent';
    if (symmetry >= 0.90) return 'Good';
    if (symmetry >= 0.85) return 'Fair';
    return 'Needs Attention';
  }

  String _getStancePhaseStatus(double stance) {
    if (stance >= 58 && stance <= 62) return 'Optimal';
    if (stance >= 55 && stance <= 65) return 'Good';
    if (stance >= 52 && stance <= 68) return 'Fair';
    return 'Needs Attention';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Optimal':
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Fair':
        return Colors.orange;
      case 'Needs Attention':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}






