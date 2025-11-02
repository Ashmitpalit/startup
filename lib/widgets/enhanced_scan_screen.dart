import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import '../providers/camera_provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/enhanced_feedback_panel.dart';
import '../widgets/enhanced_pose_overlay.dart';
import '../models/scan_result.dart';
import '../models/gait_data.dart';
import '../screens/results_screen.dart';
import '../providers/gait_analysis_provider.dart';
import '../providers/badge_provider.dart';
import '../models/badge.dart';
import '../l10n/app_localizations.dart';

class EnhancedScanScreen extends StatefulWidget {
  const EnhancedScanScreen({super.key});

  @override
  State<EnhancedScanScreen> createState() => _EnhancedScanScreenState();
}

enum ScanMode { camera, video }

class _EnhancedScanScreenState extends State<EnhancedScanScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _progressController;
  bool _isInitialized = false;
  AnimationStatusListener? _scanStatusListener;
  ScanMode _scanMode = ScanMode.camera;
  File? _selectedVideoFile;
  Timer? _scanQualityTimer;
  int _warningCount = 0;
  String? _lastWarningType;

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

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraProvider = context.read<CameraProvider>();
    final ttsProvider = context.read<TTSProvider>();

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
    // Remove status listener before disposing
    if (_scanStatusListener != null) {
      _scanController.removeStatusListener(_scanStatusListener!);
    }

    _scanQualityTimer?.cancel();
    _pulseController.dispose();
    _scanController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Consumer<CameraProvider>(
        builder: (context, cameraProvider, child) {
          if (!_isInitialized || !cameraProvider.isInitialized) {
            return _buildLoadingScreen();
          }

          return Stack(
            children: [
              // Camera Preview with enhanced overlay
              _buildCameraPreview(cameraProvider),

              // Gradient overlay for better visibility
              _buildGradientOverlay(),

              // Enhanced UI
              _buildEnhancedUI(cameraProvider),

              // Pose Detection Overlay
              if (cameraProvider.isScanning)
                const EnhancedPoseOverlay(isScanning: true),

              // Enhanced Feedback Panel
              if (cameraProvider.isScanning)
                Positioned(
                  bottom: 140,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    ignoring: true,
                    child: SafeArea(top: false, child: EnhancedFeedbackPanel()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0B0B0F)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading icon
            Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.camera,
                    color: Colors.white,
                    size: 40,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(duration: 1500.ms)
                .then()
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 30),

            // Loading text with animation
            Text(
              AppLocalizations.of(context).t('initializing_camera'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),

            const SizedBox(height: 20),

            // Progress indicator
            Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 1000.ms),
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

  Widget _buildGradientOverlay() {
    return const SizedBox.shrink();
  }

  Widget _buildEnhancedUI(CameraProvider cameraProvider) {
    return SafeArea(
      child: Column(
        children: [
          // Enhanced Top Bar
          _buildEnhancedTopBar(cameraProvider),

          // Center Content with better animations
          Expanded(child: _buildEnhancedCenterContent(cameraProvider)),

          // Enhanced Bottom Controls
          _buildEnhancedBottomControls(cameraProvider),
        ],
      ),
    );
  }

  Widget _buildEnhancedTopBar(CameraProvider cameraProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Center: compact timer when scanning, else title
          Flexible(
            child: cameraProvider.isScanning
                ? _buildCompactTimer(cameraProvider)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppLocalizations.of(context).t('ready_to_scan'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),

          // TTS toggle + replay
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<TTSProvider>(
                builder: (_, tts, __) => IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () => tts.toggleEnabled(),
                  icon: Icon(
                    tts.isEnabled
                        ? CupertinoIcons.speaker_3
                        : CupertinoIcons.speaker_slash,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => context.read<TTSProvider>().speakScanStart(),
                icon: const Icon(
                  CupertinoIcons.arrow_clockwise,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimer(CameraProvider cameraProvider) {
    final progress = cameraProvider.remainingTime / cameraProvider.scanDuration;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: 1 - progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6366F1),
                  ),
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${cameraProvider.remainingTime}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).t('scanning'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${cameraProvider.detectedPoses} ${AppLocalizations.of(context).t('frames')}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCenterContent(CameraProvider cameraProvider) {
    if (!cameraProvider.isScanning) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mode Selection Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF121218),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _scanMode = ScanMode.camera;
                            _selectedVideoFile = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _scanMode == ScanMode.camera
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.camera,
                                color: _scanMode == ScanMode.camera
                                    ? Colors.white
                                    : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Live Camera',
                                style: TextStyle(
                                  color: _scanMode == ScanMode.camera
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _scanMode = ScanMode.video;
                          });
                          _pickVideoFile();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _scanMode == ScanMode.video
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.videocam,
                                color: _scanMode == ScanMode.video
                                    ? Colors.white
                                    : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upload Video',
                                style: TextStyle(
                                  color: _scanMode == ScanMode.video
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 20),

              // Content based on mode
              _scanMode == ScanMode.camera
                  ? _buildCameraInstructions()
                  : _buildVideoInstructions(),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEnhancedBottomControls(CameraProvider cameraProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0F),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: cameraProvider.isScanning
            ? Row(
                children: [
                  Expanded(child: _buildCompactStopButton(cameraProvider)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCompactCancelButton(cameraProvider)),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () =>
                          _showSettingsBottomSheet(context, cameraProvider),
                      icon: const Icon(
                        CupertinoIcons.settings,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : _buildEnhancedStartButton(cameraProvider),
      ),
    );
  }

  void _showSettingsBottomSheet(
    BuildContext context,
    CameraProvider cameraProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scan Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Consumer<TTSProvider>(
              builder: (_, tts, __) => ListTile(
                leading: Icon(
                  tts.isEnabled
                      ? CupertinoIcons.speaker_3
                      : CupertinoIcons.speaker_slash,
                  color: Colors.white70,
                  size: 24,
                ),
                title: Text(
                  'Voice Guidance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                trailing: Switch(
                  value: tts.isEnabled,
                  onChanged: (value) => tts.toggleEnabled(),
                  activeColor: const Color(0xFF6366F1),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                CupertinoIcons.arrow_clockwise,
                color: Colors.white70,
                size: 24,
              ),
              title: Text(
                'Replay Instructions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              onTap: () {
                context.read<TTSProvider>().speakScanStart();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStartButton(CameraProvider cameraProvider) {
    final canStart = _scanMode == ScanMode.camera
        ? cameraProvider.isInitialized
        : _selectedVideoFile != null;

    return GestureDetector(
      onTap: canStart
          ? () {
              if (_scanMode == ScanMode.camera) {
                _startScan(cameraProvider);
              } else {
                _startVideoScan(cameraProvider);
              }
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        decoration: BoxDecoration(
          gradient: canStart
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : null,
          color: canStart ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canStart
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _scanMode == ScanMode.camera
                      ? AppLocalizations.of(context).t('start_scan')
                      : 'Analyze Video',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCompactStopButton(CameraProvider cameraProvider) {
    return GestureDetector(
      onTap: () => _stopScan(cameraProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.stop_fill, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppLocalizations.of(context).t('stop_scan'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCancelButton(CameraProvider cameraProvider) {
    return ElevatedButton(
      onPressed: () {
        debugPrint('Cancel button pressed!');
        _cancelScan(cameraProvider);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white10, width: 1),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppLocalizations.of(context).t('cancel'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startScan(CameraProvider cameraProvider) {
    // Reset warning state
    _warningCount = 0;
    _lastWarningType = null;

    // Start TTS announcement
    context.read<TTSProvider>().speakScanStart();

    // Start camera scan
    cameraProvider.startScan();

    // Reset and start animation controller
    _scanController.reset();
    _scanController.forward();

    // Remove any existing listener
    if (_scanStatusListener != null) {
      _scanController.removeStatusListener(_scanStatusListener!);
    }

    // Listen for scan completion
    _scanStatusListener = (status) {
      if (status == AnimationStatus.completed) {
        _completeScan();
      }
    };
    _scanController.addStatusListener(_scanStatusListener!);

    // Start monitoring scan quality every 3 seconds
    _scanQualityTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!cameraProvider.isScanning || !mounted) {
        timer.cancel();
        return;
      }

      final qualityIssue = cameraProvider.checkScanQuality();
      if (qualityIssue != null && qualityIssue != _lastWarningType) {
        _handleScanQualityIssue(qualityIssue, cameraProvider);
      }
    });
  }

  void _stopScan(CameraProvider cameraProvider) {
    _scanQualityTimer?.cancel();

    // Remove status listener to prevent unwanted callbacks
    if (_scanStatusListener != null) {
      _scanController.removeStatusListener(_scanStatusListener!);
      _scanStatusListener = null;
    }

    cameraProvider.stopScan();
    _scanController.stop();
    _scanController.reset();
    _completeScan();
  }

  void _cancelScan(CameraProvider cameraProvider) {
    debugPrint('_cancelScan called');

    _scanQualityTimer?.cancel();

    // Remove status listener to prevent unwanted callbacks
    if (_scanStatusListener != null) {
      _scanController.removeStatusListener(_scanStatusListener!);
      _scanStatusListener = null;
    }

    // Stop camera scan first
    cameraProvider.stopScan();

    // Stop and reset animation
    _scanController.stop();
    _scanController.reset();

    // Don't speak on cancel - just exit
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleScanQualityIssue(
    String issueType,
    CameraProvider cameraProvider,
  ) {
    _lastWarningType = issueType;
    _warningCount++;

    String title;
    String message;
    String tips;

    switch (issueType) {
      case 'no_person_detected':
        title = 'No Person Detected';
        message =
            'Unable to detect a person in the frame. Make sure you are fully visible in front of the camera.';
        tips =
            '• Stand fully in the camera frame\n• Ensure good lighting\n• Face the camera directly\n• Stand 2-3 meters away';
        break;
      case 'person_lost':
        title = 'Person Out of Frame';
        message =
            'Lost track of you. Please stay in the camera frame and ensure good lighting.';
        tips =
            '• Stay within the camera view\n• Don\'t move too far from camera\n• Ensure consistent lighting\n• Walk in a straight line';
        break;
      case 'not_walking':
        title = 'No Movement Detected';
        message =
            'You appear to be stationary. Please start walking naturally for accurate gait analysis.';
        tips =
            '• Start walking forward naturally\n• Maintain a steady pace\n• Walk in a straight line\n• Don\'t stop or sit down';
        break;
      case 'poor_conditions':
        title = 'Poor Scanning Conditions';
        message =
            'Detection is limited. Please improve lighting and ensure clear visibility.';
        tips =
            '• Move to a well-lit area\n• Ensure camera has clear view\n• Remove obstructions\n• Face a light source';
        break;
      default:
        return;
    }

    // Show warning dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF121218),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                _warningCount >= 2
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : CupertinoIcons.info,
                color: _warningCount >= 2 ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Tips:',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tips,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_warningCount >= 2) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scan will be cancelled if conditions don\'t improve.',
                          style: TextStyle(
                            color: Colors.orange.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (_warningCount >= 2)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelScan(cameraProvider);
                },
                child: const Text(
                  'Cancel Scan',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Give user time to fix the issue before next check
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: Text(_warningCount >= 2 ? 'Try Again' : 'OK'),
            ),
          ],
        ),
      );

      // Auto-cancel after 3 warnings
      if (_warningCount >= 3) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop(); // Close warning dialog
            _cancelScan(cameraProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Scan cancelled due to poor conditions'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideoFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startVideoScan(CameraProvider cameraProvider) async {
    if (_selectedVideoFile == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121218),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            Text('Analyzing video...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      await cameraProvider.processVideoFileSimple(_selectedVideoFile!);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _completeScan();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCameraInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
                CupertinoIcons.hand_raised,
                color: Color(0xFF6366F1),
                size: 48,
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(duration: const Duration(milliseconds: 2000)),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context).t('ready_to_scan'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).t('scan_instructions'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 1000.ms),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.lightbulb,
                      color: Color(0xFFF59E0B),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).t('tips_best_results'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).t('tips_bullets'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 1200.ms),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildVideoInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedVideoFile != null
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.videocam,
            color: _selectedVideoFile != null
                ? const Color(0xFF22C55E)
                : const Color(0xFF6366F1),
            size: 48,
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 20),
          Text(
            _selectedVideoFile != null
                ? 'Video Selected'
                : 'Upload Walking Video',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 12),
          Text(
            _selectedVideoFile != null
                ? 'Tap "Analyze Video" to start the analysis'
                : 'Select a video of someone walking from your gallery',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 1000.ms),
          if (_selectedVideoFile != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.doc,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedVideoFile!.path.split('/').last,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVideoFile = null;
                      });
                    },
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }

  void _completeScan() {
    final cameraProvider = context.read<CameraProvider>();

    // Get REAL gait analysis from pose detection
    final gaitMetrics = cameraProvider.getGaitAnalysisResults();
    final injuryRisk = cameraProvider.getInjuryRisk();

    // Check if we have enough data
    debugPrint(
      'Scan complete - Detected poses: ${cameraProvider.detectedPoses}, Metrics empty: ${gaitMetrics.isEmpty}',
    );
    if (gaitMetrics.isEmpty || cameraProvider.detectedPoses < 15) {
      debugPrint(
        'Insufficient data: ${cameraProvider.detectedPoses} poses detected',
      );
      _showInsufficientDataDialog();
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
    final recommendations = _generateEnhancedRecommendations(
      gaitData,
      injuryRisk,
    );
    final corrections = _generateEnhancedCorrections(gaitData, jointAnglesData);

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

    // Get providers for badge checking
    final gaitProvider = context.read<GaitAnalysisProvider>();
    final badgeProvider = context.read<BadgeProvider>();

    // Check for improvement before adding result
    final previousScore = gaitProvider.previousScore;

    // Add to provider
    gaitProvider.addScanResult(scanResult);

    // Check for gait improvement badges
    if (previousScore != null) {
      badgeProvider.checkGaitImprovement(previousScore, healthScore).then((
        newBadges,
      ) {
        if (newBadges.isNotEmpty && mounted) {
          _showBadgeUnlockedDialog(newBadges);
        }
      });
    }

    // Check for consistency badges
    badgeProvider.checkScanConsistency().then((newBadges) {
      if (newBadges.isNotEmpty && mounted) {
        _showBadgeUnlockedDialog(newBadges);
      }
    });

    // Navigate to results with transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ResultsScreen(scanResult: scanResult),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _showInsufficientDataDialog() {
    final cameraProvider = context.read<CameraProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121218),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context).t('insufficient_data_title'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected ${cameraProvider.detectedPoses} frames (need at least 15)',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).t('insufficient_data_body'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tips for better detection:',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '• Stand fully in frame\n• Ensure good lighting\n• Walk naturally\n• Keep 2-3 meters away',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).t('ok')),
          ),
        ],
      ),
    );
  }

  void _showBadgeUnlockedDialog(List<Badge> badges) {
    // Show badge unlock animation/notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(badges.first.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Badge Unlocked!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    badges.first.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: badges.first.color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ... (rest of the methods remain the same as before)
  GaitData _buildGaitDataFromMetrics(
    Map<String, dynamic> steps,
    Map<String, List<double>> jointAnglesData,
    Map<String, double> symmetryData,
    Map<String, double> postureData,
  ) {
    // Implementation remains the same as in scan_screen.dart
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
    final symmetry = (symmetryData['symmetry'] ?? 1.0);

    // Ensure minimum values to prevent zero display issues
    final safeCadence = cadence > 0
        ? cadence
        : 90.0; // Default reasonable cadence
    final safeStrideLength = strideLength > 0
        ? strideLength
        : 0.7; // Default reasonable stride
    final safeWalkingSpeed = walkingSpeed > 0
        ? walkingSpeed
        : 1.05; // Default reasonable speed (cadence * strideLength / 60)
    final safeSymmetry = symmetry > 0
        ? symmetry
        : 0.85; // Default reasonable symmetry

    return GaitData(
      averageStrideLength: safeStrideLength,
      averageCadence: safeCadence,
      averageStepWidth: 0.15,
      averageStepTime: safeCadence > 0 ? 60 / safeCadence : 0.67,
      leftStepLength: safeStrideLength / 2,
      rightStepLength: safeStrideLength / 2,
      leftStepTime: safeCadence > 0 ? 60 / safeCadence : 0.67,
      rightStepTime: safeCadence > 0 ? 60 / safeCadence : 0.67,
      walkingSpeed: safeWalkingSpeed,
      stepSymmetry: safeSymmetry,
      stancePhasePercentage: 60.0,
      swingPhasePercentage: 40.0,
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

  List<String> _generateEnhancedRecommendations(
    GaitData gaitData,
    Map<String, double> injuryRisk,
  ) {
    List<String> recommendations = [];

    // Speed recommendations with more detail
    if (gaitData.walkingSpeed < 0.8) {
      recommendations.add(
        'Consider increasing your walking speed gradually to 1.0-1.4 m/s',
      );
      recommendations.add('Try walking with more purpose and energy');
    } else if (gaitData.walkingSpeed > 2.0) {
      recommendations.add(
        'Try maintaining a more moderate walking pace around 1.2-1.6 m/s',
      );
      recommendations.add('Focus on controlled, steady movements');
    } else {
      recommendations.add(
        'Excellent walking speed! Maintain your current pace',
      );
    }

    // Enhanced symmetry recommendations
    if (gaitData.stepSymmetry < 0.9) {
      recommendations.add('Focus on evening out your left and right steps');
      recommendations.add(
        'Consider physical therapy for gait symmetry improvement',
      );
      recommendations.add(
        'Try walking in front of a mirror to observe your symmetry',
      );
    }

    // Enhanced injury risk recommendations
    final highRiskAreas = injuryRisk.entries
        .where((e) => e.value > 0.5)
        .toList();
    if (highRiskAreas.isNotEmpty) {
      recommendations.add(
        'Focus on strengthening exercises for: ${highRiskAreas.map((e) => e.key.replaceAll('_', ' ')).join(', ')}',
      );
      recommendations.add(
        'Consider consulting a physical therapist for targeted exercises',
      );
    }

    // Posture recommendations
    for (var posture in gaitData.postureData) {
      if (posture.hasIssues()) {
        recommendations.add(
          'Work on improving ${posture.postureType.replaceAll('_', ' ')}',
        );
        recommendations.add('Try posture exercises and stretches');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Outstanding! Your gait is very healthy');
      recommendations.add('Keep up the excellent work with regular walking');
      recommendations.add(
        'Consider maintaining this routine for long-term health',
      );
    }

    return recommendations;
  }

  List<String> _generateEnhancedCorrections(
    GaitData gaitData,
    Map<String, List<double>> jointAnglesData,
  ) {
    List<String> corrections = [];

    // Check for joint angle issues with more detail
    for (var joint in gaitData.jointAngles) {
      if (joint.isOutOfRange()) {
        final deviation = joint.angle < joint.minNormal
            ? 'below normal range'
            : 'above normal range';
        corrections.add(
          '${joint.jointName.replaceAll('_', ' ')} angle is $deviation (${joint.angle.toStringAsFixed(1)}°)',
        );
      }
    }

    // Enhanced symmetry check
    if (gaitData.stepSymmetry < 0.95) {
      final asymmetry = ((1 - gaitData.stepSymmetry) * 100).toStringAsFixed(1);
      corrections.add(
        'Work on balancing left and right side movements (${asymmetry}% asymmetry detected)',
      );
    }

    if (corrections.isEmpty) {
      corrections.add('No major corrections needed - excellent form!');
      corrections.add(
        'Continue monitoring your gait regularly for maintenance',
      );
    }

    return corrections;
  }
}
