import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseFrame {
  final DateTime timestamp;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;

  PoseFrame({
    required this.timestamp,
    required Map<PoseLandmarkType, PoseLandmark> landmarks,
  }) : landmarks = Map.unmodifiable(landmarks);

  // Get a specific landmark
  PoseLandmark? getLandmark(PoseLandmarkType type) {
    return landmarks[type];
  }

  // Check if all key landmarks are detected
  bool hasValidPose() {
    final keyLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (var landmarkType in keyLandmarks) {
      if (!landmarks.containsKey(landmarkType)) {
        return false;
      }
    }
    return true;
  }

  // Get confidence score for pose
  double getConfidenceScore() {
    if (landmarks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    for (var landmark in landmarks.values) {
      totalConfidence += landmark.likelihood;
    }

    return totalConfidence / landmarks.length;
  }
}

