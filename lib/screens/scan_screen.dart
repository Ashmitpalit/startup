import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/camera_provider.dart';
import '../providers/gait_analysis_provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/pose_overlay.dart';
import '../widgets/scan_timer.dart';
import '../widgets/feedback_panel.dart';
import '../models/scan_result.dart';
import '../models/gait_data.dart';
import 'results_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraProvider = context.read<CameraProvider>();
    final ttsProvider = context.read<TTSProvider>();

    // Pass TTS provider to camera provider
    cameraProvider.setTTSProvider(ttsProvider);

    await cameraProvider.initializeCamera();

    if (mounted) {
      setState(() {
        _isInitialized = cameraProvider.isInitialized;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraProvider>(
        builder: (context, cameraProvider, child) {
          if (!_isInitialized || !cameraProvider.isInitialized) {
            return _buildLoadingScreen();
          }

          return Stack(
            children: [
              // Camera Preview
              _buildCameraPreview(cameraProvider),

              // Overlay UI
              _buildOverlayUI(cameraProvider),

              // Pose Detection Overlay
              if (cameraProvider.isScanning)
                PoseOverlay(isScanning: cameraProvider.isScanning),

              // Feedback Panel
              if (cameraProvider.isScanning)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: FeedbackPanel(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Initializing Camera...',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraProvider cameraProvider) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(cameraProvider.cameraController!),
    );
  }

  Widget _buildOverlayUI(CameraProvider cameraProvider) {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar
          _buildTopBar(cameraProvider),

          // Center Content
          Expanded(child: Center(child: _buildCenterContent(cameraProvider))),

          // Bottom Controls
          _buildBottomControls(cameraProvider),
        ],
      ),
    );
  }

  Widget _buildTopBar(CameraProvider cameraProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.arrow_left,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          if (cameraProvider.isScanning)
            ScanTimer(
              remainingTime: cameraProvider.remainingTime,
              totalTime: cameraProvider.scanDuration,
            ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildCenterContent(CameraProvider cameraProvider) {
    if (!cameraProvider.isScanning) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.person_fill,
                  color: Colors.white,
                  size: 48,
                ).animate().scale(duration: 1.seconds),
                const SizedBox(height: 16),
                Text(
                  'Ready to Scan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Position yourself in front of the camera and tap "Start Scan" to begin your 30-second gait analysis.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Make sure you have enough space to walk naturally.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomControls(CameraProvider cameraProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!cameraProvider.isScanning) ...[
            _buildStartButton(cameraProvider),
          ] else ...[
            _buildStopButton(cameraProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildStartButton(CameraProvider cameraProvider) {
    return GestureDetector(
      onTap: () => _startScan(cameraProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              'Start Scan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 600.ms);
  }

  Widget _buildStopButton(CameraProvider cameraProvider) {
    return GestureDetector(
      onTap: () => _stopScan(cameraProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.stop_fill, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              'Stop Scan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startScan(CameraProvider cameraProvider) {
    // Start TTS announcement
    context.read<TTSProvider>().speakScanStart();

    // Start camera scan
    cameraProvider.startScan();

    // Start animation controller
    _scanController.forward();

    // Listen for scan completion
    _scanController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeScan();
      }
    });
  }

  void _stopScan(CameraProvider cameraProvider) {
    cameraProvider.stopScan();
    _scanController.stop();
    _completeScan();
  }

  void _completeScan() {
    final cameraProvider = context.read<CameraProvider>();

    // Get REAL gait analysis from pose detection
    final gaitMetrics = cameraProvider.getGaitAnalysisResults();
    final injuryRisk = cameraProvider.getInjuryRisk();

    // Check if we have enough data
    if (gaitMetrics.isEmpty || cameraProvider.detectedPoses < 30) {
      // Fallback to sample if not enough data collected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough pose data collected. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
      return;
    }

    final steps = gaitMetrics['steps'] as Map<String, dynamic>;
    final jointAnglesData =
        gaitMetrics['jointAngles'] as Map<String, List<double>>;
    final symmetryData = gaitMetrics['symmetry'] as Map<String, double>;
    final postureData = gaitMetrics['posture'] as Map<String, double>;

    // Convert to GaitData model
    final gaitData = _buildGaitDataFromMetrics(
      steps,
      jointAnglesData,
      symmetryData,
      postureData,
    );

    // Calculate health score
    final healthScore = gaitData.calculateHealthScore();

    // Generate recommendations based on analysis
    final recommendations = _generateRecommendations(gaitData, injuryRisk);
    final corrections = _generateCorrections(gaitData, jointAnglesData);

    // Create scan result with REAL data
    final scanResult = ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      gaitData: gaitData,
      healthScore: healthScore,
      injuryRisk: injuryRisk,
      recommendations: recommendations,
      corrections: corrections,
      scanDuration: Duration(
        seconds: _scanController.duration?.inSeconds ?? 30,
      ),
    );

    // Add to provider
    context.read<GaitAnalysisProvider>().addScanResult(scanResult);

    // Navigate to results
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(scanResult: scanResult),
      ),
    );
  }

  GaitData _buildGaitDataFromMetrics(
    Map<String, dynamic> steps,
    Map<String, List<double>> jointAnglesData,
    Map<String, double> symmetryData,
    Map<String, double> postureData,
  ) {
    // Calculate average joint angles
    List<JointAngle> jointAngles = [];
    jointAnglesData.forEach((jointName, angles) {
      if (angles.isNotEmpty) {
        final avgAngle = angles.reduce((a, b) => a + b) / angles.length;
        jointAngles.add(
          JointAngle(
            jointName: jointName,
            angle: avgAngle,
            minNormal: _getMinNormalAngle(jointName),
            maxNormal: _getMaxNormalAngle(jointName),
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    // Build posture data
    List<PostureData> postures = [];
    postureData.forEach((postureType, value) {
      postures.add(
        PostureData(
          postureType: postureType,
          value: value,
          threshold: _getPostureThreshold(postureType),
          feedback: _getPostureFeedback(postureType, value),
          timestamp: DateTime.now(),
        ),
      );
    });

    final cadence = (steps['cadence'] ?? 0.0) as double;
    final strideLength = (steps['strideLength'] ?? 0.0) as double;
    final walkingSpeed = (steps['walkingSpeed'] ?? 0.0) as double;
    final symmetry = symmetryData['symmetry'] ?? 1.0;

    return GaitData(
      averageStrideLength: strideLength,
      averageCadence: cadence,
      averageStepWidth: 0.15, // Default value, can be enhanced
      averageStepTime: cadence > 0 ? 60 / cadence : 0.0,
      leftStepLength: strideLength / 2,
      rightStepLength: strideLength / 2,
      leftStepTime: cadence > 0 ? 60 / cadence : 0.0,
      rightStepTime: cadence > 0 ? 60 / cadence : 0.0,
      walkingSpeed: walkingSpeed,
      stepSymmetry: symmetry,
      stancePhasePercentage: 60.0, // Typical value
      swingPhasePercentage: 40.0, // Typical value
      jointAngles: jointAngles,
      postureData: postures,
      timestamp: DateTime.now(),
    );
  }

  double _getMinNormalAngle(String jointName) {
    switch (jointName) {
      case 'left_knee':
      case 'right_knee':
        return 0.0;
      case 'left_hip':
      case 'right_hip':
        return 0.0;
      default:
        return 0.0;
    }
  }

  double _getMaxNormalAngle(String jointName) {
    switch (jointName) {
      case 'left_knee':
      case 'right_knee':
        return 170.0;
      case 'left_hip':
      case 'right_hip':
        return 180.0;
      default:
        return 180.0;
    }
  }

  double _getPostureThreshold(String postureType) {
    switch (postureType) {
      case 'spine_alignment':
        return 0.1;
      case 'shoulder_level':
        return 0.05;
      default:
        return 0.1;
    }
  }

  String _getPostureFeedback(String postureType, double value) {
    final threshold = _getPostureThreshold(postureType);
    if (value < threshold) {
      return 'Good ${postureType.replaceAll('_', ' ')}';
    } else {
      return '${postureType.replaceAll('_', ' ')} needs attention';
    }
  }

  List<String> _generateRecommendations(
    GaitData gaitData,
    Map<String, double> injuryRisk,
  ) {
    List<String> recommendations = [];

    // Speed recommendations
    if (gaitData.walkingSpeed < 0.8) {
      recommendations.add('Consider increasing your walking speed gradually');
    } else if (gaitData.walkingSpeed > 2.0) {
      recommendations.add('Try maintaining a more moderate walking pace');
    } else {
      recommendations.add(
        'Maintain your current walking pace - it\'s in the healthy range',
      );
    }

    // Symmetry recommendations
    if (gaitData.stepSymmetry < 0.9) {
      recommendations.add('Focus on evening out your left and right steps');
      recommendations.add(
        'Consider physical therapy for gait symmetry improvement',
      );
    }

    // Injury risk recommendations
    final highRiskAreas = injuryRisk.entries
        .where((e) => e.value > 0.5)
        .toList();
    if (highRiskAreas.isNotEmpty) {
      recommendations.add(
        'Focus on strengthening exercises for: ${highRiskAreas.map((e) => e.key.replaceAll('_', ' ')).join(', ')}',
      );
    }

    // Posture recommendations
    for (var posture in gaitData.postureData) {
      if (posture.hasIssues()) {
        recommendations.add(
          'Work on improving ${posture.postureType.replaceAll('_', ' ')}',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Great job! Your gait looks healthy');
      recommendations.add('Keep up the good work with regular walking');
    }

    return recommendations;
  }

  List<String> _generateCorrections(
    GaitData gaitData,
    Map<String, List<double>> jointAnglesData,
  ) {
    List<String> corrections = [];

    // Check for joint angle issues
    for (var joint in gaitData.jointAngles) {
      if (joint.isOutOfRange()) {
        corrections.add(
          '${joint.jointName.replaceAll('_', ' ')} angle needs adjustment',
        );
      }
    }

    // Check symmetry
    if (gaitData.stepSymmetry < 0.95) {
      corrections.add('Work on balancing left and right side movements');
    }

    if (corrections.isEmpty) {
      corrections.add('No major corrections needed');
      corrections.add('Continue monitoring your gait regularly');
    }

    return corrections;
  }
}
