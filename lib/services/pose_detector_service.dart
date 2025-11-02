import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/pose_frame.dart';
import 'dart:math' as math;

class PoseDetectorService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  bool _isProcessing = false;
  final List<PoseFrame> _poseHistory = [];
  final StreamController<PoseFrame> _poseStreamController =
      StreamController<PoseFrame>.broadcast();

  Stream<PoseFrame> get poseStream => _poseStreamController.stream;
  List<PoseFrame> get poseHistory => _poseHistory;

  // Process camera image for pose detection
  Future<void> processImage(CameraImage image, int rotation) async {
    // Use a less strict lock - only skip if we're already processing
    // This allows us to catch up if processing is slow
    if (_isProcessing) {
      // Skip this frame but don't wait - we'll process the next one
      return;
    }
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image, rotation);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Process asynchronously - don't await to avoid blocking
      processInputImage(inputImage).then((_) {
        _isProcessing = false;
      }).catchError((e) {
        debugPrint('Error in async pose processing: $e');
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error processing pose: $e');
      _isProcessing = false;
    }
  }

  // Process InputImage directly (for video frames)
  Future<void> processInputImage(InputImage inputImage) async {
    // Don't skip here - this is called from processImage which already checks
    // But for video processing, we want to process every frame
    try {
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final poseFrame = PoseFrame(
          timestamp: DateTime.now(),
          landmarks: pose.landmarks,
        );

        _poseHistory.add(poseFrame);
        _poseStreamController.add(poseFrame);
      } else {
        // Log occasionally when no pose detected (don't spam)
        if (_poseHistory.length % 30 == 0) {
          debugPrint('No pose detected in frame. History length: ${_poseHistory.length}');
        }
      }
    } catch (e) {
      debugPrint('Error processing InputImage: $e');
    }
  }

  // Convert camera image to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image, int rotation) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final InputImageRotation imageRotation =
          InputImageRotation.values[rotation ~/ 90];

      final InputImageFormat inputImageFormat = InputImageFormat.values
          .firstWhere(
            (format) => format.rawValue == image.format.raw,
            orElse: () => InputImageFormat.nv21,
          );

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  // Calculate gait metrics from pose history
  Map<String, dynamic> calculateGaitMetrics() {
    if (_poseHistory.length < 15) {
      debugPrint('Insufficient pose history: ${_poseHistory.length} frames (need at least 15)');
      return {}; // Need at least 0.5 seconds of data at 30fps
    }

    // Extract key metrics
    final stepData = _detectSteps();
    final jointAngles = _calculateJointAngles();
    final symmetry = _calculateSymmetry();
    final postureMetrics = _calculatePostureMetrics();

    return {
      'steps': stepData,
      'jointAngles': jointAngles,
      'symmetry': symmetry,
      'posture': postureMetrics,
    };
  }

  // Enhanced step detection with improved algorithms
  Map<String, dynamic> _detectSteps() {
    List<double> leftAnklePosY = [];
    List<double> rightAnklePosY = [];
    List<DateTime> timestamps = [];
    List<double> leftAnklePosX = [];
    List<double> rightAnklePosX = [];

    for (var frame in _poseHistory) {
      final leftAnkle = frame.getLandmark(PoseLandmarkType.leftAnkle);
      final rightAnkle = frame.getLandmark(PoseLandmarkType.rightAnkle);

      if (leftAnkle != null && rightAnkle != null) {
        leftAnklePosY.add(leftAnkle.y);
        rightAnklePosY.add(rightAnkle.y);
        leftAnklePosX.add(leftAnkle.x);
        rightAnklePosX.add(rightAnkle.x);
        timestamps.add(frame.timestamp);
      }
    }

    if (timestamps.length < 5) {
      debugPrint('Insufficient valid ankle data: ${timestamps.length} frames (need at least 5)');
      return {
        'totalSteps': 0,
        'leftSteps': 0,
        'rightSteps': 0,
        'cadence': 0.0,
        'strideLength': 0.0,
        'walkingSpeed': 0.0,
        'stepSymmetry': 0.5,
        'stepVariability': 0.0,
        'gaitStability': 0.0,
      };
    }

    // Enhanced step detection with smoothing
    int leftSteps = _countStepsEnhanced(leftAnklePosY, leftAnklePosX);
    int rightSteps = _countStepsEnhanced(rightAnklePosY, rightAnklePosX);
    int totalSteps = leftSteps + rightSteps;

    // Calculate cadence (steps per minute)
    final duration = timestamps.last.difference(timestamps.first).inSeconds;
    final cadence = duration > 0 ? (totalSteps / duration) * 60 : 0.0;

    // Enhanced stride length calculation
    double avgStrideLength = _calculateEnhancedStrideLength();

    // Calculate walking speed
    double walkingSpeed = (avgStrideLength * cadence) / 60;

    // Calculate step variability (consistency measure)
    double stepVariability = _calculateStepVariability(
      leftAnklePosY,
      rightAnklePosY,
    );

    // Calculate gait stability (overall smoothness)
    double gaitStability = _calculateGaitStability();

    // Enhanced symmetry calculation
    double stepSymmetry = _calculateEnhancedSymmetry(
      leftSteps,
      rightSteps,
      leftAnklePosY,
      rightAnklePosY,
    );

    return {
      'totalSteps': totalSteps,
      'leftSteps': leftSteps,
      'rightSteps': rightSteps,
      'cadence': cadence,
      'strideLength': avgStrideLength,
      'walkingSpeed': walkingSpeed,
      'stepSymmetry': stepSymmetry,
      'stepVariability': stepVariability,
      'gaitStability': gaitStability,
    };
  }

  // Enhanced step counting with forward/backward movement consideration
  int _countStepsEnhanced(List<double> anklePosY, List<double> anklePosX) {
    if (anklePosY.length < 5) return 0;

    // Smooth the signal to reduce noise
    List<double> smoothedY = _smoothSignal(anklePosY);
    List<double> smoothedX = _smoothSignal(anklePosX);

    int steps = 0;
    List<double> localMaxima = [];

    // Find local maxima with improved threshold
    for (int i = 2; i < smoothedY.length - 2; i++) {
      if (smoothedY[i] > smoothedY[i - 1] &&
          smoothedY[i] > smoothedY[i + 1] &&
          smoothedY[i] > smoothedY[i - 2] &&
          smoothedY[i] > smoothedY[i + 2]) {
        // Check if this is a significant peak (foot lift)
        double amplitude =
            smoothedY[i] - (smoothedY[i - 1] + smoothedY[i + 1]) / 2;
        if (amplitude > 0.015) {
          // Adjusted threshold
          localMaxima.add(smoothedY[i]);
          steps++;
        }
      }
    }

    return steps;
  }

  // Signal smoothing to reduce noise
  List<double> _smoothSignal(List<double> signal) {
    if (signal.length < 3) return signal;

    List<double> smoothed = [signal[0]];

    for (int i = 1; i < signal.length - 1; i++) {
      double avg = (signal[i - 1] + signal[i] + signal[i + 1]) / 3;
      smoothed.add(avg);
    }

    smoothed.add(signal[signal.length - 1]);
    return smoothed;
  }

  // Calculate step variability (how consistent are the steps)
  double _calculateStepVariability(
    List<double> leftAnkleY,
    List<double> rightAnkleY,
  ) {
    if (leftAnkleY.length < 10) return 0.0;

    // Calculate step time intervals
    List<double> stepTimes = [];
    List<double> combinedY = [];

    // Combine both ankles for overall step pattern
    for (int i = 0; i < math.min(leftAnkleY.length, rightAnkleY.length); i++) {
      combinedY.add((leftAnkleY[i] + rightAnkleY[i]) / 2);
    }

    // Find step intervals
    List<int> stepIndices = [];
    for (int i = 1; i < combinedY.length - 1; i++) {
      if (combinedY[i] > combinedY[i - 1] && combinedY[i] > combinedY[i + 1]) {
        if (combinedY[i] - (combinedY[i - 1] + combinedY[i + 1]) / 2 > 0.01) {
          stepIndices.add(i);
        }
      }
    }

    // Calculate variability in step intervals
    if (stepIndices.length < 3) return 0.0;

    List<double> intervals = [];
    for (int i = 1; i < stepIndices.length; i++) {
      intervals.add((stepIndices[i] - stepIndices[i - 1]).toDouble());
    }

    // Calculate coefficient of variation
    double mean = intervals.reduce((a, b) => a + b) / intervals.length;
    double variance =
        intervals.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        intervals.length;
    double stdDev = math.sqrt(variance);

    return mean > 0 ? stdDev / mean : 0.0;
  }

  // Calculate gait stability (overall smoothness of movement)
  double _calculateGaitStability() {
    if (_poseHistory.length < 20) return 0.0;

    double totalStability = 0.0;
    int validFrames = 0;

    for (int i = 1; i < _poseHistory.length - 1; i++) {
      final current = _poseHistory[i];
      final previous = _poseHistory[i - 1];

      // Calculate stability based on landmark movement smoothness
      double frameStability = 0.0;
      int landmarkCount = 0;

      for (var type in current.landmarks.keys) {
        final currentLandmark = current.getLandmark(type);
        final previousLandmark = previous.getLandmark(type);

        if (currentLandmark != null && previousLandmark != null) {
          double movement = math.sqrt(
            math.pow(currentLandmark.x - previousLandmark.x, 2) +
                math.pow(currentLandmark.y - previousLandmark.y, 2),
          );

          // Lower movement = higher stability
          frameStability += math.exp(-movement * 10); // Exponential decay
          landmarkCount++;
        }
      }

      if (landmarkCount > 0) {
        totalStability += frameStability / landmarkCount;
        validFrames++;
      }
    }

    return validFrames > 0 ? totalStability / validFrames : 0.0;
  }

  // Enhanced symmetry calculation considering timing and amplitude
  double _calculateEnhancedSymmetry(
    int leftSteps,
    int rightSteps,
    List<double> leftAnkleY,
    List<double> rightAnkleY,
  ) {
    // Step count symmetry
    double stepCountSymmetry = leftSteps + rightSteps > 0
        ? 1.0 - (leftSteps - rightSteps).abs() / (leftSteps + rightSteps)
        : 0.5;

    // Amplitude symmetry
    double amplitudeSymmetry = 1.0;
    if (leftAnkleY.length > 10 && rightAnkleY.length > 10) {
      double leftAmplitude = _calculateAmplitude(leftAnkleY);
      double rightAmplitude = _calculateAmplitude(rightAnkleY);

      if (leftAmplitude > 0 && rightAmplitude > 0) {
        amplitudeSymmetry =
            1.0 -
            (leftAmplitude - rightAmplitude).abs() /
                math.max(leftAmplitude, rightAmplitude);
      }
    }

    // Combined symmetry score
    return (stepCountSymmetry * 0.6 + amplitudeSymmetry * 0.4).clamp(0.0, 1.0);
  }

  // Calculate amplitude of ankle movement
  double _calculateAmplitude(List<double> signal) {
    if (signal.length < 5) return 0.0;

    double min = signal.reduce(math.min);
    double max = signal.reduce(math.max);

    return max - min;
  }

  // Count peaks in a signal (step detection)
  int _countPeaks(List<double> signal) {
    if (signal.length < 3) return 0;

    int peaks = 0;
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        // Check if peak is significant (above threshold)
        if ((signal[i] - signal[i - 1]).abs() > 0.02) {
          peaks++;
        }
      }
    }
    return peaks;
  }

  // Enhanced stride length calculation with better accuracy
  double _calculateEnhancedStrideLength() {
    List<double> strideLengths = [];
    List<double> leftStrideLengths = [];
    List<double> rightStrideLengths = [];

    for (var frame in _poseHistory) {
      final leftHip = frame.getLandmark(PoseLandmarkType.leftHip);
      final leftAnkle = frame.getLandmark(PoseLandmarkType.leftAnkle);
      final rightHip = frame.getLandmark(PoseLandmarkType.rightHip);
      final rightAnkle = frame.getLandmark(PoseLandmarkType.rightAnkle);

      if (leftHip != null &&
          leftAnkle != null &&
          rightHip != null &&
          rightAnkle != null) {
        // Calculate individual leg lengths
        final leftStride = _calculateDistance(leftHip, leftAnkle);
        final rightStride = _calculateDistance(rightHip, rightAnkle);

        leftStrideLengths.add(leftStride);
        rightStrideLengths.add(rightStride);
        strideLengths.add((leftStride + rightStride) / 2);
      }
    }

    if (strideLengths.isEmpty) return 0.0;

    // Remove outliers and calculate median for more robust estimate
    strideLengths.sort();
    double median = strideLengths[strideLengths.length ~/ 2];

    // Filter out values that are too far from median
    List<double> filteredStrides = strideLengths
        .where((stride) => (stride - median).abs() < median * 0.3)
        .toList();

    if (filteredStrides.isEmpty) return median;
    return filteredStrides.reduce((a, b) => a + b) / filteredStrides.length;
  }

  // Calculate joint angles
  Map<String, List<double>> _calculateJointAngles() {
    Map<String, List<double>> angles = {
      'left_knee': [],
      'right_knee': [],
      'left_hip': [],
      'right_hip': [],
      'left_ankle': [],
      'right_ankle': [],
    };

    for (var frame in _poseHistory) {
      // Left knee angle
      final leftHip = frame.getLandmark(PoseLandmarkType.leftHip);
      final leftKnee = frame.getLandmark(PoseLandmarkType.leftKnee);
      final leftAnkle = frame.getLandmark(PoseLandmarkType.leftAnkle);
      if (leftHip != null && leftKnee != null && leftAnkle != null) {
        angles['left_knee']!.add(_calculateAngle(leftHip, leftKnee, leftAnkle));
      }

      // Right knee angle
      final rightHip = frame.getLandmark(PoseLandmarkType.rightHip);
      final rightKnee = frame.getLandmark(PoseLandmarkType.rightKnee);
      final rightAnkle = frame.getLandmark(PoseLandmarkType.rightAnkle);
      if (rightHip != null && rightKnee != null && rightAnkle != null) {
        angles['right_knee']!.add(
          _calculateAngle(rightHip, rightKnee, rightAnkle),
        );
      }

      // Left hip angle
      final leftShoulder = frame.getLandmark(PoseLandmarkType.leftShoulder);
      if (leftShoulder != null && leftHip != null && leftKnee != null) {
        angles['left_hip']!.add(
          _calculateAngle(leftShoulder, leftHip, leftKnee),
        );
      }

      // Right hip angle
      final rightShoulder = frame.getLandmark(PoseLandmarkType.rightShoulder);
      if (rightShoulder != null && rightHip != null && rightKnee != null) {
        angles['right_hip']!.add(
          _calculateAngle(rightShoulder, rightHip, rightKnee),
        );
      }
    }

    return angles;
  }

  // Calculate angle between three points
  double _calculateAngle(
    PoseLandmark point1,
    PoseLandmark point2,
    PoseLandmark point3,
  ) {
    final vector1X = point1.x - point2.x;
    final vector1Y = point1.y - point2.y;
    final vector2X = point3.x - point2.x;
    final vector2Y = point3.y - point2.y;

    final angle =
        math.atan2(vector2Y, vector2X) - math.atan2(vector1Y, vector1X);
    return (angle * 180 / math.pi).abs();
  }

  // Calculate distance between two landmarks
  double _calculateDistance(PoseLandmark point1, PoseLandmark point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    final dz = point1.z - point2.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  // Calculate symmetry metrics
  Map<String, double> _calculateSymmetry() {
    List<double> leftRightDifferences = [];

    for (var frame in _poseHistory) {
      final leftHip = frame.getLandmark(PoseLandmarkType.leftHip);
      final rightHip = frame.getLandmark(PoseLandmarkType.rightHip);
      final leftKnee = frame.getLandmark(PoseLandmarkType.leftKnee);
      final rightKnee = frame.getLandmark(PoseLandmarkType.rightKnee);

      if (leftHip != null &&
          rightHip != null &&
          leftKnee != null &&
          rightKnee != null) {
        final leftSideLength = _calculateDistance(leftHip, leftKnee);
        final rightSideLength = _calculateDistance(rightHip, rightKnee);
        final difference = (leftSideLength - rightSideLength).abs();
        leftRightDifferences.add(difference);
      }
    }

    if (leftRightDifferences.isEmpty) {
      return {'symmetry': 1.0};
    }

    final avgDifference =
        leftRightDifferences.reduce((a, b) => a + b) /
        leftRightDifferences.length;
    final symmetryScore = 1.0 - avgDifference.clamp(0.0, 1.0);

    return {'symmetry': symmetryScore};
  }

  // Calculate posture metrics
  Map<String, double> _calculatePostureMetrics() {
    List<double> spineAlignments = [];
    List<double> shoulderLevels = [];

    for (var frame in _poseHistory) {
      // Spine alignment (shoulder to hip vertical alignment)
      final leftShoulder = frame.getLandmark(PoseLandmarkType.leftShoulder);
      final rightShoulder = frame.getLandmark(PoseLandmarkType.rightShoulder);
      final leftHip = frame.getLandmark(PoseLandmarkType.leftHip);
      final rightHip = frame.getLandmark(PoseLandmarkType.rightHip);

      if (leftShoulder != null &&
          rightShoulder != null &&
          leftHip != null &&
          rightHip != null) {
        final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
        final hipMidX = (leftHip.x + rightHip.x) / 2;
        final spineDeviation = (shoulderMidX - hipMidX).abs();
        spineAlignments.add(spineDeviation);

        // Shoulder level (should be horizontal)
        final shoulderLevelDiff = (leftShoulder.y - rightShoulder.y).abs();
        shoulderLevels.add(shoulderLevelDiff);
      }
    }

    double avgSpineAlignment = spineAlignments.isEmpty
        ? 0.0
        : spineAlignments.reduce((a, b) => a + b) / spineAlignments.length;

    double avgShoulderLevel = shoulderLevels.isEmpty
        ? 0.0
        : shoulderLevels.reduce((a, b) => a + b) / shoulderLevels.length;

    return {
      'spine_alignment': avgSpineAlignment,
      'shoulder_level': avgShoulderLevel,
    };
  }

  // Get injury risk assessment based on pose data
  Map<String, double> calculateInjuryRisk() {
    final metrics = calculateGaitMetrics();
    if (metrics.isEmpty) {
      return {
        'lower_back': 0.0,
        'left_knee': 0.0,
        'right_knee': 0.0,
        'left_ankle': 0.0,
        'right_ankle': 0.0,
        'left_hip': 0.0,
        'right_hip': 0.0,
      };
    }

    final jointAngles = metrics['jointAngles'] as Map<String, List<double>>;
    final symmetry = metrics['symmetry'] as Map<String, double>;
    final posture = metrics['posture'] as Map<String, double>;

    // Calculate risk based on deviations from normal ranges
    double symmetryScore = symmetry['symmetry'] ?? 1.0;
    double symmetryRisk = 1.0 - symmetryScore;

    // Knee risk based on angle ranges
    double leftKneeRisk = _calculateJointRisk(
      jointAngles['left_knee'] ?? [],
      0,
      170,
    );
    double rightKneeRisk = _calculateJointRisk(
      jointAngles['right_knee'] ?? [],
      0,
      170,
    );

    // Hip risk based on angle ranges
    double leftHipRisk = _calculateJointRisk(
      jointAngles['left_hip'] ?? [],
      0,
      180,
    );
    double rightHipRisk = _calculateJointRisk(
      jointAngles['right_hip'] ?? [],
      0,
      180,
    );

    // Lower back risk based on posture
    double spineAlignment = posture['spine_alignment'] ?? 0.0;
    double lowerBackRisk = (spineAlignment * 10).clamp(0.0, 1.0);

    // Ankle risk based on step asymmetry
    double ankleRisk = symmetryRisk * 0.7;

    return {
      'lower_back': lowerBackRisk,
      'left_knee': leftKneeRisk,
      'right_knee': rightKneeRisk,
      'left_ankle': ankleRisk,
      'right_ankle': ankleRisk,
      'left_hip': leftHipRisk,
      'right_hip': rightHipRisk,
    };
  }

  // Calculate joint risk based on angle deviations
  double _calculateJointRisk(
    List<double> angles,
    double minNormal,
    double maxNormal,
  ) {
    if (angles.isEmpty) return 0.0;

    int outOfRangeCount = 0;
    for (var angle in angles) {
      if (angle < minNormal || angle > maxNormal) {
        outOfRangeCount++;
      }
    }

    return (outOfRangeCount / angles.length).clamp(0.0, 1.0);
  }

  // Clear pose history
  void clearHistory() {
    _poseHistory.clear();
  }

  // Dispose resources
  void dispose() {
    _poseDetector.close();
    _poseStreamController.close();
  }
}
