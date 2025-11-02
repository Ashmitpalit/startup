import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../providers/camera_provider.dart';

class PoseOverlay extends StatelessWidget {
  final bool isScanning;

  const PoseOverlay({super.key, required this.isScanning});

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
              // Draw pose skeleton
              if (poseFrame != null && poseFrame.hasValidPose())
                CustomPaint(
                  size: Size.infinite,
                  painter: PosePainter(poseFrame.landmarks),
                ),

              // Scanning indicator
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(duration: 1000.ms),
                      const SizedBox(width: 8),
                      const Text(
                        'Analyzing your gait...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
            ],
          ),
        );
      },
    );
  }
}

class PosePainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;

  PosePainter(this.landmarks);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 8
      ..style = PaintingStyle.fill;

    // Draw connections between joints
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );

    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );

    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
    );
    _drawConnection(
      canvas,
      paint,
      size,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );

    // Draw joints
    landmarks.forEach((type, landmark) {
      final offset = _scalePoint(Offset(landmark.x, landmark.y), size);
      canvas.drawCircle(offset, 4, pointPaint);
    });
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
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  Offset _scalePoint(Offset point, Size size) {
    // Scale normalized coordinates (0-1) to screen size
    return Offset(point.dx * size.width, point.dy * size.height);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return true; // Repaint on every frame for smooth animation
  }
}
