import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class SkeletonHeatmap3D extends StatefulWidget {
  final Map<String, double> injuryRisk;
  final double? rotationX;
  final double? rotationY;
  final double? rotationZ;
  final Function(double x, double y, double z)? onRotationChanged;

  const SkeletonHeatmap3D({
    super.key,
    required this.injuryRisk,
    this.rotationX,
    this.rotationY,
    this.rotationZ,
    this.onRotationChanged,
  });

  @override
  State<SkeletonHeatmap3D> createState() => _SkeletonHeatmap3DState();
}

class _SkeletonHeatmap3DState extends State<SkeletonHeatmap3D>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _rotationZ = 0.0;

  bool _isDragging = false;
  Offset? _lastPanPosition;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);

    // Initialize rotation values
    _rotationX = widget.rotationX ?? 0.0;
    _rotationY = widget.rotationY ?? 0.0;
    _rotationZ = widget.rotationZ ?? 0.0;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 450,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.grey[900]!.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 3D Skeleton with heatmap
          Center(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _rotationController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _zoom,
                    child: CustomPaint(
                      size: const Size(320, 380),
                      painter: Skeleton3DPainter(
                        injuryRisk: widget.injuryRisk,
                        rotationX: _rotationX,
                        rotationY: _rotationY,
                        rotationZ: _rotationZ,
                        pulseAnimation: _pulseController.value,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Rotation controls
          Positioned(top: 15, right: 15, child: _buildRotationControls()),

          // Heatmap legend
          Positioned(bottom: 15, left: 15, child: _buildHeatmapLegend()),

          // Reset button
          Positioned(top: 15, left: 15, child: _buildResetButton()),

          // Zoom indicator
          Positioned(top: 60, right: 15, child: _buildZoomIndicator()),
        ],
      ),
    );
  }

  Widget _buildRotationControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // X rotation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _rotateX(-15),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    CupertinoIcons.rotate_left,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'X',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _rotateX(15),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    CupertinoIcons.rotate_right,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Y rotation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _rotateY(-15),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    CupertinoIcons.rotate_left,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Y',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _rotateY(15),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    CupertinoIcons.rotate_right,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Injury Risk',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red,
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'High',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _resetView,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Icon(CupertinoIcons.arrow_clockwise, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        '${(_zoom * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Handle rotation (pan)
    if (_lastPanPosition != null) {
      final delta = details.localFocalPoint - _lastPanPosition!;
      _rotationY += delta.dx * 0.01;
      _rotationX += delta.dy * 0.01;
    }

    // Handle zoom
    setState(() {
      _zoom = (_zoom * details.scale).clamp(0.5, 2.0);
    });

    widget.onRotationChanged?.call(_rotationX, _rotationY, _rotationZ);
    _lastPanPosition = details.localFocalPoint;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastPanPosition = null;
  }

  void _rotateX(double angle) {
    setState(() {
      _rotationX += angle;
    });
    widget.onRotationChanged?.call(_rotationX, _rotationY, _rotationZ);
  }

  void _rotateY(double angle) {
    setState(() {
      _rotationY += angle;
    });
    widget.onRotationChanged?.call(_rotationX, _rotationY, _rotationZ);
  }

  void _resetView() {
    setState(() {
      _rotationX = 0.0;
      _rotationY = 0.0;
      _rotationZ = 0.0;
      _zoom = 1.0;
    });
    widget.onRotationChanged?.call(_rotationX, _rotationY, _rotationZ);
  }
}

class Skeleton3DPainter extends CustomPainter {
  final Map<String, double> injuryRisk;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double pulseAnimation;

  Skeleton3DPainter({
    required this.injuryRisk,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw 3D skeleton with heatmap
    _drawSkeleton3D(canvas, center, size);
  }

  void _drawSkeleton3D(Canvas canvas, Offset center, Size size) {
    // Define 3D skeleton structure with more anatomical detail
    final points = _getDetailedSkeletonPoints3D(center);

    // Transform points based on rotation
    final transformedPoints = _transformPoints3D(points);

    // Draw skeleton with heatmap colors
    _drawSkeletonWithHeatmap(canvas, transformedPoints);
  }

  List<Map<String, dynamic>> _getDetailedSkeletonPoints3D(Offset center) {
    return [
      // Head and neck
      {
        'name': 'head',
        'x': 0.0,
        'y': -90.0,
        'z': 0.0,
        'radius': 18.0,
        'type': 'joint',
      },

      // Spine - more detailed
      {
        'name': 'neck',
        'x': 0.0,
        'y': -70.0,
        'z': 0.0,
        'radius': 10.0,
        'type': 'joint',
      },
      {
        'name': 'upper_spine',
        'x': 0.0,
        'y': -50.0,
        'z': 0.0,
        'radius': 8.0,
        'type': 'joint',
      },
      {
        'name': 'mid_spine',
        'x': 0.0,
        'y': -30.0,
        'z': 0.0,
        'radius': 8.0,
        'type': 'joint',
      },
      {
        'name': 'lower_spine',
        'x': 0.0,
        'y': -10.0,
        'z': 0.0,
        'radius': 10.0,
        'type': 'joint',
      },
      {
        'name': 'sacrum',
        'x': 0.0,
        'y': 10.0,
        'z': 0.0,
        'radius': 8.0,
        'type': 'joint',
      },

      // Shoulders and arms - more detailed
      {
        'name': 'left_shoulder',
        'x': -30.0,
        'y': -55.0,
        'z': 0.0,
        'radius': 8.0,
        'type': 'joint',
      },
      {
        'name': 'right_shoulder',
        'x': 30.0,
        'y': -55.0,
        'z': 0.0,
        'radius': 8.0,
        'type': 'joint',
      },
      {
        'name': 'left_elbow',
        'x': -55.0,
        'y': -30.0,
        'z': 0.0,
        'radius': 6.0,
        'type': 'joint',
      },
      {
        'name': 'right_elbow',
        'x': 55.0,
        'y': -30.0,
        'z': 0.0,
        'radius': 6.0,
        'type': 'joint',
      },
      {
        'name': 'left_wrist',
        'x': -70.0,
        'y': -10.0,
        'z': 0.0,
        'radius': 5.0,
        'type': 'joint',
      },
      {
        'name': 'right_wrist',
        'x': 70.0,
        'y': -10.0,
        'z': 0.0,
        'radius': 5.0,
        'type': 'joint',
      },
      {
        'name': 'left_hand',
        'x': -75.0,
        'y': 0.0,
        'z': 0.0,
        'radius': 4.0,
        'type': 'joint',
      },
      {
        'name': 'right_hand',
        'x': 75.0,
        'y': 0.0,
        'z': 0.0,
        'radius': 4.0,
        'type': 'joint',
      },

      // Hips and legs - more detailed
      {
        'name': 'left_hip',
        'x': -18.0,
        'y': 20.0,
        'z': 0.0,
        'radius': 10.0,
        'type': 'joint',
      },
      {
        'name': 'right_hip',
        'x': 18.0,
        'y': 20.0,
        'z': 0.0,
        'radius': 10.0,
        'type': 'joint',
      },
      {
        'name': 'left_knee',
        'x': -18.0,
        'y': 55.0,
        'z': 0.0,
        'radius': 8.0,
        'type': 'joint',
      },
      {
        'name': 'right_knee',
        'x': 18.0,
        'y': 55.0,
        'z': 0.0,
        'radius': 8.0,
        'type': 'joint',
      },
      {
        'name': 'left_ankle',
        'x': -18.0,
        'y': 90.0,
        'z': 0.0,
        'radius': 6.0,
        'type': 'joint',
      },
      {
        'name': 'right_ankle',
        'x': 18.0,
        'y': 90.0,
        'z': 0.0,
        'radius': 6.0,
        'type': 'joint',
      },
      {
        'name': 'left_foot',
        'x': -18.0,
        'y': 105.0,
        'z': 0.0,
        'radius': 4.0,
        'type': 'joint',
      },
      {
        'name': 'right_foot',
        'x': 18.0,
        'y': 105.0,
        'z': 0.0,
        'radius': 4.0,
        'type': 'joint',
      },
    ];
  }

  List<Map<String, dynamic>> _transformPoints3D(
    List<Map<String, dynamic>> points,
  ) {
    return points.map((point) {
      double x = point['x'];
      double y = point['y'];
      double z = point['z'] ?? 0.0;

      // Apply 3D rotations with perspective
      // Rotation around X axis
      double y1 = y * math.cos(rotationX) - z * math.sin(rotationX);
      double z1 = y * math.sin(rotationX) + z * math.cos(rotationX);

      // Rotation around Y axis
      double x2 = x * math.cos(rotationY) + z1 * math.sin(rotationY);
      double z2 = -x * math.sin(rotationY) + z1 * math.cos(rotationY);

      // Rotation around Z axis
      double x3 = x2 * math.cos(rotationZ) - y1 * math.sin(rotationZ);
      double y3 = x2 * math.sin(rotationZ) + y1 * math.cos(rotationZ);

      // Apply perspective projection
      double perspective = 200.0;
      double scale = perspective / (perspective + z2);

      return {
        'name': point['name'],
        'x': x3 * scale,
        'y': y3 * scale,
        'z': z2,
        'radius': (point['radius'] as double) * scale,
        'type': point['type'],
        'original': point,
      };
    }).toList();
  }

  void _drawSkeletonWithHeatmap(
    Canvas canvas,
    List<Map<String, dynamic>> points,
  ) {
    // Draw bones first
    _drawBones(canvas, points);

    // Draw joints with heatmap colors
    _drawJointsWithHeatmap(canvas, points);
  }

  void _drawBones(Canvas canvas, List<Map<String, dynamic>> points) {
    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white.withOpacity(0.7);

    // Define bone connections
    final connections = [
      // Head and spine
      ['head', 'neck'],
      ['neck', 'upper_spine'],
      ['upper_spine', 'mid_spine'],
      ['mid_spine', 'lower_spine'],
      ['lower_spine', 'sacrum'],

      // Arms
      ['upper_spine', 'left_shoulder'],
      ['upper_spine', 'right_shoulder'],
      ['left_shoulder', 'left_elbow'],
      ['right_shoulder', 'right_elbow'],
      ['left_elbow', 'left_wrist'],
      ['right_elbow', 'right_wrist'],
      ['left_wrist', 'left_hand'],
      ['right_wrist', 'right_hand'],

      // Legs
      ['sacrum', 'left_hip'],
      ['sacrum', 'right_hip'],
      ['left_hip', 'left_knee'],
      ['right_hip', 'right_knee'],
      ['left_knee', 'left_ankle'],
      ['right_knee', 'right_ankle'],
      ['left_ankle', 'left_foot'],
      ['right_ankle', 'right_foot'],
    ];

    for (final connection in connections) {
      try {
        final point1 = points.firstWhere((p) => p['name'] == connection[0]);
        final point2 = points.firstWhere((p) => p['name'] == connection[1]);

        canvas.drawLine(
          Offset(point1['x'], point1['y']),
          Offset(point2['x'], point2['y']),
          bonePaint,
        );
      } catch (e) {
        // Skip if point not found
        continue;
      }
    }
  }

  void _drawJointsWithHeatmap(
    Canvas canvas,
    List<Map<String, dynamic>> points,
  ) {
    for (final point in points) {
      final risk = injuryRisk[point['name']] ?? 0.0;
      final color = _getHeatmapColor(risk);
      final baseRadius = point['radius'] as double;
      final radius = baseRadius * (1.0 + risk * 0.8);

      // Add pulse effect for high risk areas
      final pulseRadius = risk > 0.6
          ? radius * (1.0 + pulseAnimation * 0.3)
          : radius;

      // Draw outer glow for high risk
      if (risk > 0.5) {
        final glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(0.3);

        canvas.drawCircle(
          Offset(point['x'], point['y']),
          pulseRadius * 1.8,
          glowPaint,
        );
      }

      // Draw joint
      final jointPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      canvas.drawCircle(
        Offset(point['x'], point['y']),
        pulseRadius,
        jointPaint,
      );

      // Add inner highlight
      final highlightPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.9);

      canvas.drawCircle(
        Offset(point['x'], point['y']),
        pulseRadius * 0.3,
        highlightPaint,
      );

      // Add border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.8);

      canvas.drawCircle(
        Offset(point['x'], point['y']),
        pulseRadius,
        borderPaint,
      );
    }
  }

  Color _getHeatmapColor(double risk) {
    final normalizedRisk = risk.clamp(0.0, 1.0);

    if (normalizedRisk < 0.2) {
      return Colors.blue.withOpacity(0.9);
    } else if (normalizedRisk < 0.4) {
      return Colors.green.withOpacity(0.9);
    } else if (normalizedRisk < 0.6) {
      return Colors.yellow.withOpacity(0.9);
    } else if (normalizedRisk < 0.8) {
      return Colors.orange.withOpacity(0.9);
    } else {
      return Colors.red.withOpacity(0.9);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
