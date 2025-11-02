import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../providers/camera_provider.dart';

class EnhancedPoseOverlay extends StatelessWidget {
  final bool isScanning;

  const EnhancedPoseOverlay({super.key, required this.isScanning});

  @override
  Widget build(BuildContext context) {
    if (!isScanning) return const SizedBox.shrink();

    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        final poseFrame = cameraProvider.currentPoseFrame;

        return Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Draw enhanced pose skeleton
              if (poseFrame != null && poseFrame.hasValidPose())
                CustomPaint(
                  size: Size.infinite,
                  painter: EnhancedPosePainter(
                    poseFrame.landmarks,
                    poseFrame.getConfidenceScore(),
                  ),
                ),

              // Enhanced scanning indicator
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: _buildEnhancedScanningIndicator(cameraProvider),
              ),

              // Pose quality indicator
              if (poseFrame != null && poseFrame.hasValidPose())
                Positioned(
                  bottom: 200,
                  right: 20,
                  child: _buildPoseQualityIndicator(
                    poseFrame.getConfidenceScore(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedScanningIndicator(CameraProvider cameraProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(duration: 1000.ms),
          const SizedBox(width: 12),
          Text(
            'Analyzing your gait...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${cameraProvider.detectedPoses}',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2);
  }

  Widget _buildPoseQualityIndicator(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getConfidenceColor(confidence).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getConfidenceColor(confidence), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            color: _getConfidenceColor(confidence),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              color: _getConfidenceColor(confidence),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.5, 0.5));
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }
}

class EnhancedPosePainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final double confidence;

  EnhancedPosePainter(this.landmarks, this.confidence);

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamic colors based on confidence
    final baseColor = confidence > 0.7
        ? Colors.green
        : confidence > 0.4
        ? Colors.orange
        : Colors.red;

    final jointPaint = Paint()
      ..color = baseColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = baseColor
      ..strokeWidth = 8
      ..style = PaintingStyle.fill;

    final highConfidencePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw connections between joints with confidence-based styling
    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
    );
    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
    );
    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );

    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
    );
    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
    );
    _drawConnection(
      canvas,
      jointPaint,
      size,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );

    // Leg connections with thicker lines for better visibility
    final legPaint = Paint()
      ..color = baseColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    _drawConnection(
      canvas,
      legPaint,
      size,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
    );
    _drawConnection(
      canvas,
      legPaint,
      size,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    );
    _drawConnection(
      canvas,
      legPaint,
      size,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
    );
    _drawConnection(
      canvas,
      legPaint,
      size,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );

    // Draw joints with confidence-based styling
    landmarks.forEach((type, landmark) {
      final offset = _scalePoint(Offset(landmark.x, landmark.y), size);

      // Different colors for key joints
      Paint jointPaint = Paint()
        ..color = _getJointColor(type)
        ..strokeWidth = 6
        ..style = PaintingStyle.fill;

      // Draw joint with glow effect
      canvas.drawCircle(offset, 6, jointPaint);

      // Add inner highlight
      final highlightPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 2, highlightPaint);
    });

    // Draw center of mass if we have hip landmarks
    _drawCenterOfMass(canvas, size);
  }

  Color _getJointColor(PoseLandmarkType type) {
    switch (type) {
      case PoseLandmarkType.leftKnee:
      case PoseLandmarkType.rightKnee:
        return Colors.red; // Knees in red for visibility
      case PoseLandmarkType.leftAnkle:
      case PoseLandmarkType.rightAnkle:
        return Colors.blue; // Ankles in blue
      case PoseLandmarkType.leftHip:
      case PoseLandmarkType.rightHip:
        return Colors.purple; // Hips in purple
      case PoseLandmarkType.leftShoulder:
      case PoseLandmarkType.rightShoulder:
        return Colors.orange; // Shoulders in orange
      default:
        return confidence > 0.7 ? Colors.green : Colors.orange;
    }
  }

  void _drawCenterOfMass(Canvas canvas, Size size) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftHip != null && rightHip != null) {
      final centerX = (leftHip.x + rightHip.x) / 2;
      final centerY = (leftHip.y + rightHip.y) / 2;
      final center = _scalePoint(Offset(centerX, centerY), size);

      final centerPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.6)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, 15, centerPaint);
      canvas.drawCircle(center, 8, centerPaint);
    }
  }

  void _drawConnection(
    Canvas canvas,
    Paint paint,
    Size size,
    PoseLandmarkType start,
    PoseLandmarkType end,
  ) {
    final startLandmark = landmarks[start];
    final endLandmark = landmarks[end];

    if (startLandmark != null && endLandmark != null) {
      final startPoint = _scalePoint(
        Offset(startLandmark.x, startLandmark.y),
        size,
      );
      final endPoint = _scalePoint(Offset(endLandmark.x, endLandmark.y), size);

      // Draw line with slight glow effect
      canvas.drawLine(startPoint, endPoint, paint);

      // Add subtle shadow for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..strokeWidth = paint.strokeWidth + 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(startPoint, endPoint, shadowPaint);
    }
  }

  Offset _scalePoint(Offset point, Size size) {
    // Scale normalized coordinates (0-1) to screen size
    return Offset(point.dx * size.width, point.dy * size.height);
  }

  @override
  bool shouldRepaint(covariant EnhancedPosePainter oldDelegate) {
    return true; // Repaint on every frame for smooth animation
  }
}
