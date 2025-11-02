import 'dart:math';

class GaitData {
  final double averageStrideLength;
  final double averageCadence;
  final double averageStepWidth;
  final double averageStepTime;
  final double leftStepLength;
  final double rightStepLength;
  final double leftStepTime;
  final double rightStepTime;
  final double walkingSpeed;
  final double stepSymmetry;
  final double stancePhasePercentage;
  final double swingPhasePercentage;
  final List<JointAngle> jointAngles;
  final List<PostureData> postureData;
  final DateTime timestamp;

  GaitData({
    required this.averageStrideLength,
    required this.averageCadence,
    required this.averageStepWidth,
    required this.averageStepTime,
    required this.leftStepLength,
    required this.rightStepLength,
    required this.leftStepTime,
    required this.rightStepTime,
    required this.walkingSpeed,
    required this.stepSymmetry,
    required this.stancePhasePercentage,
    required this.swingPhasePercentage,
    required this.jointAngles,
    required this.postureData,
    required this.timestamp,
  });

  // Enhanced health score calculation with more comprehensive metrics
  double calculateHealthScore() {
    double score = 100.0;

    // Enhanced asymmetry penalty (more nuanced)
    double asymmetryPenalty = (1.0 - stepSymmetry) * 25;
    score -= asymmetryPenalty;

    // Speed optimization (optimal range gets bonus)
    if (walkingSpeed >= 1.0 && walkingSpeed <= 1.6) {
      // Optimal speed range gets a small bonus
      score += 2;
    } else if (walkingSpeed < 0.7 || walkingSpeed > 2.2) {
      // Very slow or very fast gets penalty
      score -= 20;
    } else if (walkingSpeed < 0.9 || walkingSpeed > 1.8) {
      // Moderately off gets smaller penalty
      score -= 10;
    }

    // Enhanced step time variation penalty
    double stepTimeVariation = _calculateStepTimeVariation();
    if (stepTimeVariation > 0.3) {
      score -= stepTimeVariation * 40; // Increased penalty for high variability
    } else if (stepTimeVariation > 0.15) {
      score -= stepTimeVariation * 20; // Moderate penalty
    }

    // Cadence bonus/penalty (optimal range: 100-120 steps/min)
    if (averageCadence >= 100 && averageCadence <= 120) {
      score += 3;
    } else if (averageCadence < 80 || averageCadence > 140) {
      score -= 12;
    } else if (averageCadence < 90 || averageCadence > 130) {
      score -= 6;
    }

    // Enhanced joint angle assessment
    int outOfRangeJoints = 0;
    double totalJointDeviation = 0.0;

    for (var joint in jointAngles) {
      if (joint.isOutOfRange()) {
        outOfRangeJoints++;
        // Calculate deviation severity
        double deviation = 0.0;
        if (joint.angle < joint.minNormal) {
          deviation = (joint.minNormal - joint.angle) / joint.minNormal;
        } else {
          deviation = (joint.angle - joint.maxNormal) / joint.maxNormal;
        }
        totalJointDeviation += deviation;
      }
    }

    // Joint penalties (progressive)
    if (outOfRangeJoints > 0) {
      score -= (outOfRangeJoints * 6) + (totalJointDeviation * 8);
    }

    // Enhanced posture assessment
    double postureScore = 100.0;
    for (var posture in postureData) {
      if (posture.hasIssues()) {
        // Calculate severity of posture issue
        double severity =
            (posture.value - posture.threshold) / posture.threshold;
        postureScore -= (severity * 15).clamp(0.0, 20.0);
      }
    }

    // Convert posture score to penalty
    score -= (100.0 - postureScore);

    // Stride length bonus/penalty
    if (averageStrideLength >= 0.8 && averageStrideLength <= 1.4) {
      score += 2;
    } else if (averageStrideLength < 0.6 || averageStrideLength > 1.8) {
      score -= 8;
    }

    // Step width assessment (normal range: 0.1-0.2m)
    if (averageStepWidth >= 0.1 && averageStepWidth <= 0.2) {
      score += 1;
    } else if (averageStepWidth < 0.05 || averageStepWidth > 0.3) {
      score -= 5;
    }

    // Gait phase assessment (normal: 60% stance, 40% swing)
    double stanceDeviation = (stancePhasePercentage - 60.0).abs();
    double swingDeviation = (swingPhasePercentage - 40.0).abs();

    if (stanceDeviation < 5 && swingDeviation < 5) {
      score += 2;
    } else if (stanceDeviation > 15 || swingDeviation > 15) {
      score -= 8;
    } else if (stanceDeviation > 10 || swingDeviation > 10) {
      score -= 4;
    }

    return score.clamp(0.0, 100.0);
  }

  double _calculateStepTimeVariation() {
    // Calculate coefficient of variation for step times
    List<double> stepTimes = [leftStepTime, rightStepTime];
    double mean = stepTimes.reduce((a, b) => a + b) / stepTimes.length;
    double variance =
        stepTimes.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        stepTimes.length;
    double stdDev = sqrt(variance);
    return stdDev / mean;
  }

  Map<String, dynamic> toJson() {
    return {
      'averageStrideLength': averageStrideLength,
      'averageCadence': averageCadence,
      'averageStepWidth': averageStepWidth,
      'averageStepTime': averageStepTime,
      'leftStepLength': leftStepLength,
      'rightStepLength': rightStepLength,
      'leftStepTime': leftStepTime,
      'rightStepTime': rightStepTime,
      'walkingSpeed': walkingSpeed,
      'stepSymmetry': stepSymmetry,
      'stancePhasePercentage': stancePhasePercentage,
      'swingPhasePercentage': swingPhasePercentage,
      'jointAngles': jointAngles.map((j) => j.toJson()).toList(),
      'postureData': postureData.map((p) => p.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GaitData.fromJson(Map<String, dynamic> json) {
    return GaitData(
      averageStrideLength: json['averageStrideLength']?.toDouble() ?? 0.0,
      averageCadence: json['averageCadence']?.toDouble() ?? 0.0,
      averageStepWidth: json['averageStepWidth']?.toDouble() ?? 0.0,
      averageStepTime: json['averageStepTime']?.toDouble() ?? 0.0,
      leftStepLength: json['leftStepLength']?.toDouble() ?? 0.0,
      rightStepLength: json['rightStepLength']?.toDouble() ?? 0.0,
      leftStepTime: json['leftStepTime']?.toDouble() ?? 0.0,
      rightStepTime: json['rightStepTime']?.toDouble() ?? 0.0,
      walkingSpeed: json['walkingSpeed']?.toDouble() ?? 0.0,
      stepSymmetry: json['stepSymmetry']?.toDouble() ?? 0.0,
      stancePhasePercentage: json['stancePhasePercentage']?.toDouble() ?? 0.0,
      swingPhasePercentage: json['swingPhasePercentage']?.toDouble() ?? 0.0,
      jointAngles:
          (json['jointAngles'] as List?)
              ?.map((j) => JointAngle.fromJson(j))
              .toList() ??
          [],
      postureData:
          (json['postureData'] as List?)
              ?.map((p) => PostureData.fromJson(p))
              .toList() ??
          [],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class JointAngle {
  final String jointName;
  final double angle;
  final double minNormal;
  final double maxNormal;
  final DateTime timestamp;

  JointAngle({
    required this.jointName,
    required this.angle,
    required this.minNormal,
    required this.maxNormal,
    required this.timestamp,
  });

  bool isOutOfRange() {
    return angle < minNormal || angle > maxNormal;
  }

  double getNormalizedAngle() {
    return (angle - minNormal) / (maxNormal - minNormal);
  }

  Map<String, dynamic> toJson() {
    return {
      'jointName': jointName,
      'angle': angle,
      'minNormal': minNormal,
      'maxNormal': maxNormal,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory JointAngle.fromJson(Map<String, dynamic> json) {
    return JointAngle(
      jointName: json['jointName'] ?? '',
      angle: json['angle']?.toDouble() ?? 0.0,
      minNormal: json['minNormal']?.toDouble() ?? 0.0,
      maxNormal: json['maxNormal']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class PostureData {
  final String postureType;
  final double value;
  final double threshold;
  final String feedback;
  final DateTime timestamp;

  PostureData({
    required this.postureType,
    required this.value,
    required this.threshold,
    required this.feedback,
    required this.timestamp,
  });

  bool hasIssues() {
    return value > threshold;
  }

  Map<String, dynamic> toJson() {
    return {
      'postureType': postureType,
      'value': value,
      'threshold': threshold,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PostureData.fromJson(Map<String, dynamic> json) {
    return PostureData(
      postureType: json['postureType'] ?? '',
      value: json['value']?.toDouble() ?? 0.0,
      threshold: json['threshold']?.toDouble() ?? 0.0,
      feedback: json['feedback'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
