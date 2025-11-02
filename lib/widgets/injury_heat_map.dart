import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InjuryHeatMap extends StatelessWidget {
  final Map<String, double> injuryRisks;

  const InjuryHeatMap({super.key, required this.injuryRisks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Injury Risk Heat Map',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Body visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBodyPartRisk(
                      'Left Hip',
                      injuryRisks['left_hip'] ?? 0.0,
                    ),
                    const SizedBox(height: 16),
                    _buildBodyPartRisk(
                      'Left Knee',
                      injuryRisks['left_knee'] ?? 0.0,
                    ),
                    const SizedBox(height: 16),
                    _buildBodyPartRisk(
                      'Left Ankle',
                      injuryRisks['left_ankle'] ?? 0.0,
                    ),
                  ],
                ),
              ),

              // Center body icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.person_fill,
                      size: 100,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    _buildBodyPartRisk(
                      'Lower Back',
                      injuryRisks['lower_back'] ?? 0.0,
                    ),
                  ],
                ),
              ),

              // Right side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBodyPartRisk(
                      'Right Hip',
                      injuryRisks['right_hip'] ?? 0.0,
                    ),
                    const SizedBox(height: 16),
                    _buildBodyPartRisk(
                      'Right Knee',
                      injuryRisks['right_knee'] ?? 0.0,
                    ),
                    const SizedBox(height: 16),
                    _buildBodyPartRisk(
                      'Right Ankle',
                      injuryRisks['right_ankle'] ?? 0.0,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildBodyPartRisk(String bodyPart, double risk) {
    final color = _getRiskColor(risk);
    final riskLevel = _getRiskLevel(risk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            bodyPart,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                riskLevel,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale();
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Low', Colors.green),
        const SizedBox(width: 16),
        _buildLegendItem('Medium', Colors.orange),
        const SizedBox(width: 16),
        _buildLegendItem('High', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.3) return Colors.green;
    if (risk < 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getRiskLevel(double risk) {
    if (risk < 0.3) return 'Low';
    if (risk < 0.6) return 'Medium';
    return 'High';
  }
}

