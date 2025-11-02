import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class Real3DSkeleton extends StatefulWidget {
  final Map<String, double> injuryRisk;
  final double? rotationX;
  final double? rotationY;
  final double? rotationZ;
  final Function(double x, double y, double z)? onRotationChanged;

  const Real3DSkeleton({
    super.key,
    required this.injuryRisk,
    this.rotationX,
    this.rotationY,
    this.rotationZ,
    this.onRotationChanged,
  });

  @override
  State<Real3DSkeleton> createState() => _Real3DSkeletonState();
}

class _Real3DSkeletonState extends State<Real3DSkeleton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _rotationZ = 0.0;

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
      height: 400,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 3D Skeleton with heatmap - properly centered and clipped
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
                      scale: _zoom.clamp(0.6, 1.5), // Limit zoom to prevent overflow
                      child: SizedBox(
                        width: double.infinity,
                        height: 350,
                        child: CustomPaint(
                          painter: Real3DSkeletonPainter(
                            injuryRisk: widget.injuryRisk,
                            rotationX: _rotationX,
                            rotationY: _rotationY,
                            rotationZ: _rotationZ,
                            pulseAnimation: _pulseController.value,
                          ),
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
                    CupertinoIcons.chevron_left,
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
                    CupertinoIcons.chevron_right,
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
                    CupertinoIcons.chevron_up,
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
                    CupertinoIcons.chevron_down,
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

    // Handle zoom (limited to prevent overflow)
    setState(() {
      _zoom = (_zoom * details.scale).clamp(0.6, 1.5);
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

class Real3DSkeletonPainter extends CustomPainter {
  final Map<String, double> injuryRisk;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double pulseAnimation;

  Real3DSkeletonPainter({
    required this.injuryRisk,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ensure skeleton is centered and fits within bounds
    final center = Offset(size.width / 2, size.height / 2);
    
    // Clip to canvas bounds to prevent overflow
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw 3D skeleton with heatmap
    _drawReal3DSkeleton(canvas, center, size);
  }

  void _drawReal3DSkeleton(Canvas canvas, Offset center, Size size) {
    // Define 3D skeleton structure with anatomical detail (centered at origin)
    final bones = _getAnatomicalBones3D(Offset.zero);

    // Transform bones based on rotation
    final transformedBones = _transformBones3D(bones);

    // Scale skeleton to fit within bounds (scale down if needed)
    final maxExtent = 200.0; // Maximum skeleton extent
    final scale = math.min(size.width, size.height) / (maxExtent * 2.2);
    
    // Apply scaling and centering
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    
    // Draw skeleton with heatmap colors
    _drawSkeletonWithHeatmap(canvas, transformedBones);
    
    canvas.restore();
  }

  List<Map<String, dynamic>> _getAnatomicalBones3D(Offset center) {
    return [
      // Head and neck - more anatomical
      {
        'name': 'head',
        'type': 'joint',
        'points': [
          {'x': 0.0, 'y': -95.0, 'z': 0.0, 'radius': 20.0},
          {'x': -8.0, 'y': -85.0, 'z': 0.0, 'radius': 15.0},
          {'x': 8.0, 'y': -85.0, 'z': 0.0, 'radius': 15.0},
          {'x': 0.0, 'y': -75.0, 'z': 0.0, 'radius': 18.0},
        ],
      },

      // Spine - curved and anatomical
      {
        'name': 'spine',
        'type': 'bone',
        'points': [
          {'x': 0.0, 'y': -70.0, 'z': 0.0, 'radius': 12.0},
          {'x': 0.0, 'y': -50.0, 'z': 2.0, 'radius': 10.0},
          {'x': 0.0, 'y': -30.0, 'z': 3.0, 'radius': 10.0},
          {'x': 0.0, 'y': -10.0, 'z': 2.0, 'radius': 12.0},
          {'x': 0.0, 'y': 10.0, 'z': 0.0, 'radius': 14.0},
          {'x': 0.0, 'y': 25.0, 'z': -2.0, 'radius': 12.0},
        ],
      },

      // Shoulders - more realistic
      {
        'name': 'left_shoulder',
        'type': 'joint',
        'points': [
          {'x': -25.0, 'y': -55.0, 'z': 0.0, 'radius': 10.0},
          {'x': -35.0, 'y': -45.0, 'z': 0.0, 'radius': 8.0},
          {'x': -30.0, 'y': -35.0, 'z': 0.0, 'radius': 8.0},
        ],
      },
      {
        'name': 'right_shoulder',
        'type': 'joint',
        'points': [
          {'x': 25.0, 'y': -55.0, 'z': 0.0, 'radius': 10.0},
          {'x': 35.0, 'y': -45.0, 'z': 0.0, 'radius': 8.0},
          {'x': 30.0, 'y': -35.0, 'z': 0.0, 'radius': 8.0},
        ],
      },

      // Arms - more detailed
      {
        'name': 'left_arm',
        'type': 'bone',
        'points': [
          {'x': -30.0, 'y': -35.0, 'z': 0.0, 'radius': 6.0},
          {'x': -45.0, 'y': -20.0, 'z': 0.0, 'radius': 7.0},
          {'x': -55.0, 'y': -5.0, 'z': 0.0, 'radius': 6.0},
          {'x': -60.0, 'y': 10.0, 'z': 0.0, 'radius': 5.0},
          {'x': -65.0, 'y': 25.0, 'z': 0.0, 'radius': 4.0},
        ],
      },
      {
        'name': 'right_arm',
        'type': 'bone',
        'points': [
          {'x': 30.0, 'y': -35.0, 'z': 0.0, 'radius': 6.0},
          {'x': 45.0, 'y': -20.0, 'z': 0.0, 'radius': 7.0},
          {'x': 55.0, 'y': -5.0, 'z': 0.0, 'radius': 6.0},
          {'x': 60.0, 'y': 10.0, 'z': 0.0, 'radius': 5.0},
          {'x': 65.0, 'y': 25.0, 'z': 0.0, 'radius': 4.0},
        ],
      },

      // Hips - more anatomical
      {
        'name': 'left_hip',
        'type': 'joint',
        'points': [
          {'x': -15.0, 'y': 25.0, 'z': -2.0, 'radius': 12.0},
          {'x': -20.0, 'y': 35.0, 'z': -1.0, 'radius': 10.0},
          {'x': -18.0, 'y': 45.0, 'z': 0.0, 'radius': 8.0},
        ],
      },
      {
        'name': 'right_hip',
        'type': 'joint',
        'points': [
          {'x': 15.0, 'y': 25.0, 'z': -2.0, 'radius': 12.0},
          {'x': 20.0, 'y': 35.0, 'z': -1.0, 'radius': 10.0},
          {'x': 18.0, 'y': 45.0, 'z': 0.0, 'radius': 8.0},
        ],
      },

      // Legs - more detailed
      {
        'name': 'left_leg',
        'type': 'bone',
        'points': [
          {'x': -18.0, 'y': 45.0, 'z': 0.0, 'radius': 8.0},
          {'x': -20.0, 'y': 60.0, 'z': 0.0, 'radius': 9.0},
          {'x': -18.0, 'y': 75.0, 'z': 0.0, 'radius': 8.0},
          {'x': -20.0, 'y': 90.0, 'z': 0.0, 'radius': 7.0},
          {'x': -22.0, 'y': 105.0, 'z': 0.0, 'radius': 6.0},
          {'x': -25.0, 'y': 120.0, 'z': 0.0, 'radius': 5.0},
        ],
      },
      {
        'name': 'right_leg',
        'type': 'bone',
        'points': [
          {'x': 18.0, 'y': 45.0, 'z': 0.0, 'radius': 8.0},
          {'x': 20.0, 'y': 60.0, 'z': 0.0, 'radius': 9.0},
          {'x': 18.0, 'y': 75.0, 'z': 0.0, 'radius': 8.0},
          {'x': 20.0, 'y': 90.0, 'z': 0.0, 'radius': 7.0},
          {'x': 22.0, 'y': 105.0, 'z': 0.0, 'radius': 6.0},
          {'x': 25.0, 'y': 120.0, 'z': 0.0, 'radius': 5.0},
        ],
      },
    ];
  }

  List<Map<String, dynamic>> _transformBones3D(
    List<Map<String, dynamic>> bones,
  ) {
    return bones.map((bone) {
      final transformedPoints = (bone['points'] as List).map((point) {
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
        double perspective = 300.0;
        double scale = perspective / (perspective + z2);

        return {
          'x': x3 * scale,
          'y': y3 * scale,
          'z': z2,
          'radius': (point['radius'] as double) * scale,
        };
      }).toList();

      return {
        'name': bone['name'],
        'type': bone['type'],
        'points': transformedPoints,
      };
    }).toList();
  }

  void _drawSkeletonWithHeatmap(
    Canvas canvas,
    List<Map<String, dynamic>> bones,
  ) {
    for (final bone in bones) {
      final points = bone['points'] as List;
      final risk = injuryRisk[bone['name']] ?? 0.0;
      final color = _getHeatmapColor(risk);

      if (bone['type'] == 'bone') {
        _drawBone(canvas, points, color, risk);
      } else {
        _drawJoint(canvas, points, color, risk);
      }
    }
  }

  void _drawBone(Canvas canvas, List points, Color color, double risk) {
    if (points.length < 2) return;

    // Draw bone segments with 3D effect
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      // Calculate bone thickness based on risk
      final thickness =
          (start['radius'] + end['radius']) / 2 * (1.0 + risk * 0.5);

      // Draw bone with gradient effect
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = color.withOpacity(0.8);

      // Add shadow for depth
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + 2
        ..color = Colors.black.withOpacity(0.3);

      // Only draw if within reasonable bounds
      final startOffset = Offset(start['x'], start['y']);
      final endOffset = Offset(end['x'], end['y']);
      
      // Check if line is within bounds (allowing some margin for rotation)
      if (startOffset.distanceSquared + endOffset.distanceSquared < 40000) {
        canvas.drawLine(startOffset, endOffset, shadowPaint);
        canvas.drawLine(startOffset, endOffset, paint);
      }
    }
  }

  void _drawJoint(Canvas canvas, List points, Color color, double risk) {
    for (final point in points) {
      final pointOffset = Offset(point['x'], point['y']);
      
      // Only draw if within reasonable bounds
      if (pointOffset.distanceSquared > 40000) {
        continue; // Skip points that are too far from center
      }
      
      final radius = point['radius'] * (1.0 + risk * 0.8);

      // Add pulse effect for high risk areas
      final pulseRadius = risk > 0.6
          ? radius * (1.0 + pulseAnimation * 0.3)
          : radius;

      // Draw outer glow for high risk (but smaller to prevent overflow)
      if (risk > 0.5) {
        final glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(0.3);

        canvas.drawCircle(
          pointOffset,
          (pulseRadius * 1.5).clamp(0.0, 50.0), // Limit glow size
          glowPaint,
        );
      }

      // Draw joint with 3D effect
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      canvas.drawCircle(pointOffset, pulseRadius.clamp(0, 30), paint);

      // Add inner highlight
      final highlightPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.9);

      canvas.drawCircle(
        pointOffset,
        (pulseRadius * 0.3).clamp(0, 10),
        highlightPaint,
      );

      // Add border for depth
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withOpacity(0.8);

      canvas.drawCircle(
        pointOffset,
        pulseRadius.clamp(0, 30),
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



