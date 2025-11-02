import 'gait_data.dart';

class ScanResult {
  final String id;
  final DateTime timestamp;
  final GaitData gaitData;
  final double healthScore;
  final Map<String, double> injuryRisk;
  final List<String> recommendations;
  final List<String> corrections;
  final Duration scanDuration;

  ScanResult({
    required this.id,
    required this.timestamp,
    required this.gaitData,
    required this.healthScore,
    required this.injuryRisk,
    required this.recommendations,
    required this.corrections,
    required this.scanDuration,
  });

  // Get risk level for a specific body part
  String getRiskLevel(String bodyPart) {
    double risk = injuryRisk[bodyPart] ?? 0.0;
    if (risk < 0.3) return 'Low';
    if (risk < 0.6) return 'Medium';
    return 'High';
  }

  // Get overall risk level
  String getOverallRiskLevel() {
    if (injuryRisk.isEmpty) return 'Low';
    double avgRisk =
        injuryRisk.values.reduce((a, b) => a + b) / injuryRisk.length;
    if (avgRisk < 0.3) return 'Low';
    if (avgRisk < 0.6) return 'Medium';
    return 'High';
  }

  // Get health status based on score
  String getHealthStatus() {
    if (healthScore >= 90) return 'Excellent';
    if (healthScore >= 80) return 'Good';
    if (healthScore >= 70) return 'Fair';
    if (healthScore >= 60) return 'Poor';
    return 'Critical';
  }

  // Get color for health score
  String getHealthScoreColor() {
    if (healthScore >= 80) return 'green';
    if (healthScore >= 60) return 'yellow';
    return 'red';
  }

  // Get color for risk level
  String getRiskColor(String bodyPart) {
    String level = getRiskLevel(bodyPart);
    switch (level) {
      case 'Low':
        return 'green';
      case 'Medium':
        return 'yellow';
      case 'High':
        return 'red';
      default:
        return 'gray';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'gaitData': gaitData.toJson(),
      'healthScore': healthScore,
      'injuryRisk': injuryRisk,
      'recommendations': recommendations,
      'corrections': corrections,
      'scanDuration': scanDuration.inSeconds,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      gaitData: GaitData.fromJson(json['gaitData'] ?? {}),
      healthScore: json['healthScore']?.toDouble() ?? 0.0,
      injuryRisk: Map<String, double>.from(json['injuryRisk'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      corrections: List<String>.from(json['corrections'] ?? []),
      scanDuration: Duration(seconds: json['scanDuration'] ?? 0),
    );
  }

  // Create a sample scan result for testing
  factory ScanResult.createSample() {
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      gaitData: GaitData(
        averageStrideLength: 1.2,
        averageCadence: 110.0,
        averageStepWidth: 0.15,
        averageStepTime: 0.55,
        leftStepLength: 0.6,
        rightStepLength: 0.6,
        leftStepTime: 0.55,
        rightStepTime: 0.55,
        walkingSpeed: 1.1,
        stepSymmetry: 0.95,
        stancePhasePercentage: 60.0,
        swingPhasePercentage: 40.0,
        jointAngles: [
          JointAngle(
            jointName: 'left_knee',
            angle: 15.0,
            minNormal: 0.0,
            maxNormal: 20.0,
            timestamp: DateTime.now(),
          ),
          JointAngle(
            jointName: 'right_knee',
            angle: 18.0,
            minNormal: 0.0,
            maxNormal: 20.0,
            timestamp: DateTime.now(),
          ),
        ],
        postureData: [
          PostureData(
            postureType: 'spine_alignment',
            value: 2.5,
            threshold: 5.0,
            feedback: 'Good spine alignment',
            timestamp: DateTime.now(),
          ),
        ],
        timestamp: DateTime.now(),
      ),
      healthScore: 85.0,
      injuryRisk: {
        'lower_back': 0.2,
        'left_knee': 0.3,
        'right_knee': 0.25,
        'left_ankle': 0.15,
        'right_ankle': 0.18,
        'left_hip': 0.22,
        'right_hip': 0.28,
      },
      recommendations: [
        'Maintain current walking pace',
        'Focus on knee alignment during walking',
        'Consider strengthening exercises for hips',
      ],
      corrections: [
        'Slight left knee adjustment needed',
        'Maintain current posture',
      ],
      scanDuration: const Duration(seconds: 30),
    );
  }
}
