import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../providers/tts_provider.dart';

class FeedbackPanel extends StatefulWidget {
  const FeedbackPanel({super.key});

  @override
  State<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel> {
  int _currentInstructionIndex = 0;
  late List<String> _instructions;

  @override
  void initState() {
    super.initState();
    _instructions = [
      'Walk straight ahead',
      'Keep your arms relaxed',
      'Maintain natural posture',
      'Look forward',
      'Keep steady pace',
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

        // Speak the instruction
        context.read<TTSProvider>().speak(
          _instructions[_currentInstructionIndex],
        );

        _startInstructionCycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        final detectedPoses = cameraProvider.detectedPoses;
        final hasPose = cameraProvider.currentPoseFrame != null;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pose detection status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: hasPose ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasPose ? 'Pose Detected' : 'Looking for pose...',
                    style: TextStyle(
                      color: hasPose ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Current instruction
              Text(
                _instructions[_currentInstructionIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Frames captured
              Text(
                '$detectedPoses frames captured',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

