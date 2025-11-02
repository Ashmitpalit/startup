import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/camera_provider.dart';
import '../providers/tts_provider.dart';

class EnhancedFeedbackPanel extends StatefulWidget {
  const EnhancedFeedbackPanel({super.key});

  @override
  State<EnhancedFeedbackPanel> createState() => _EnhancedFeedbackPanelState();
}

class _EnhancedFeedbackPanelState extends State<EnhancedFeedbackPanel> {
  int _currentInstructionIndex = 0;
  late List<String> _instructions;
  late List<String> _detailedInstructions;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _instructions = [
      'Walk straight ahead',
      'Keep your arms relaxed',
      'Maintain natural posture',
      'Look forward',
      'Keep steady pace',
      'Stay in frame',
    ];

    _detailedInstructions = [
      'Walk naturally with your normal stride',
      'Let your arms swing naturally at your sides',
      'Keep your back straight and shoulders level',
      'Look straight ahead, not at the camera',
      'Maintain a consistent, comfortable pace',
      'Make sure your full body stays visible',
    ];

    _startInstructionCycle();
  }

  void _startInstructionCycle() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentInstructionIndex =
              (_currentInstructionIndex + 1) % _instructions.length;
        });

        // Speak the instruction with enhanced feedback
        if (!_isSpeaking) {
          _speakEnhancedInstruction();
        }

        _startInstructionCycle();
      }
    });
  }

  Future<void> _speakEnhancedInstruction() async {
    _isSpeaking = true;
    final ttsProvider = context.read<TTSProvider>();

    // Speak main instruction
    await ttsProvider.speak(_instructions[_currentInstructionIndex]);

    // Wait a bit then speak detailed instruction
    await Future.delayed(const Duration(milliseconds: 500));
    await ttsProvider.speak(_detailedInstructions[_currentInstructionIndex]);

    _isSpeaking = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        final detectedPoses = cameraProvider.detectedPoses;
        final hasPose = cameraProvider.currentPoseFrame != null;
        final confidence =
            cameraProvider.currentPoseFrame?.getConfidenceScore() ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121218).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact status header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: hasPose ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(duration: 1000.ms),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          hasPose ? 'Detected' : 'Scanning...',
                          style: TextStyle(
                            color: hasPose ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Compact confidence
                  if (hasPose)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(confidence * 100).toInt()}%',
                        style: TextStyle(
                          color: _getConfidenceColor(confidence),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Compact instruction
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.speaker_2,
                      color: Color(0xFF6366F1),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _instructions[_currentInstructionIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _detailedInstructions[_currentInstructionIndex],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 12),

              // Compact stats
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatCard(
                      '$detectedPoses',
                      'Frames',
                      CupertinoIcons.camera,
                      const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      hasPose ? 'Good' : 'Low',
                      'Quality',
                      CupertinoIcons.chart_bar,
                      hasPose ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }
}



