import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumb;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import '../services/pose_detector_service.dart';
import '../models/pose_frame.dart';
import 'tts_provider.dart';

class CameraProvider extends ChangeNotifier {
  TTSProvider? _ttsProvider;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isScanning = false;
  int _scanDuration = 30; // seconds
  int _remainingTime = 0;

  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  PoseFrame? _currentPoseFrame;
  int _detectedPoses = 0;

  // Getters
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> get cameras => _cameras;
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  int get remainingTime => _remainingTime;
  int get scanDuration => _scanDuration;
  PoseDetectorService get poseDetectorService => _poseDetectorService;
  PoseFrame? get currentPoseFrame => _currentPoseFrame;
  int get detectedPoses => _detectedPoses;

  // Initialize camera
  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Use front camera for gait analysis
        final frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );

        await _cameraController!.initialize();
        _isInitialized = true;

        // Subscribe to pose detection stream
        _poseDetectorService.poseStream.listen((poseFrame) {
          _currentPoseFrame = poseFrame;
          _detectedPoses++;
          notifyListeners();
        });

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  // Start scanning
  void startScan() async {
    if (!_isInitialized || _isScanning) return;

    _isScanning = true;
    _remainingTime = _scanDuration;
    _detectedPoses = 0;
    _poseDetectorService.clearHistory();
    notifyListeners();

    // Start processing camera frames for pose detection
    await _cameraController!.startImageStream((CameraImage image) {
      if (_isScanning) {
        final rotation = _cameraController!.description.sensorOrientation;
        _poseDetectorService.processImage(image, rotation);
      }
    });

    // Start countdown timer
    _startCountdown();
  }

  // Stop scanning
  void stopScan() async {
    _isScanning = false;
    _remainingTime = 0;

    // Stop image stream
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    notifyListeners();
  }

  // Set TTS provider (called from UI)
  void setTTSProvider(TTSProvider provider) {
    _ttsProvider = provider;
  }

  // Start countdown timer
  void _startCountdown() {
    if (_remainingTime > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isScanning) {
          _remainingTime--;

          // TTS announcements at key intervals
          _ttsProvider?.speakScanProgress(_remainingTime);

          notifyListeners();
          _startCountdown();
        }
      });
    } else {
      stopScan();
    }
  }

  // Set scan duration
  void setScanDuration(int duration) {
    _scanDuration = duration;
    notifyListeners();
  }

  // Get gait analysis results
  Map<String, dynamic> getGaitAnalysisResults() {
    return _poseDetectorService.calculateGaitMetrics();
  }

  // Get injury risk assessment
  Map<String, double> getInjuryRisk() {
    return _poseDetectorService.calculateInjuryRisk();
  }

  // Process video file for pose detection using video_thumbnail
  Future<void> processVideoFileSimple(File videoFile) async {
    _isScanning = true;
    _detectedPoses = 0;
    _poseDetectorService.clearHistory();
    notifyListeners();

    try {
      // Get video duration first
      final videoPlayerController = VideoPlayerController.file(videoFile);
      await videoPlayerController.initialize();
      final duration = videoPlayerController.value.duration;
      await videoPlayerController.dispose();

      debugPrint('Processing video: ${videoFile.path}, duration: ${duration.inSeconds}s');
      
      // Extract frames at ~30fps (sample every 33ms = ~30fps)
      final totalFrames = (duration.inSeconds * 30).clamp(30, 900); // Min 1s (30 frames), max 30s (900 frames)
      final frameIntervalMs = (duration.inMilliseconds / totalFrames).round();
      
      int processedFrames = 0;
      
      for (int i = 0; i < totalFrames; i++) {
        final timeMs = i * frameIntervalMs;
        
        // Extract thumbnail frame from video
        final thumbnailPath = await video_thumb.VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          thumbnailPath: (await Directory.systemTemp).path,
          imageFormat: video_thumb.ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 75,
        );
        
        if (thumbnailPath != null) {
          final thumbnailFile = File(thumbnailPath);
          final inputImage = await _convertFileToInputImage(thumbnailFile);
          
          if (inputImage != null) {
            await _processVideoFrame(inputImage);
            processedFrames++;
            _detectedPoses = processedFrames;
            notifyListeners();
          }
          
          // Clean up thumbnail file
          try {
            await thumbnailFile.delete();
          } catch (e) {
            debugPrint('Error deleting thumbnail: $e');
          }
        }
      }
      
      _isScanning = false;
      notifyListeners();
      
      debugPrint('Processed $processedFrames frames from video');
    } catch (e) {
      debugPrint('Error processing video: $e');
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<InputImage?> _convertFileToInputImage(File imageFile) async {
    try {
      // ML Kit supports file path directly
      return InputImage.fromFilePath(imageFile.path);
    } catch (e) {
      debugPrint('Error converting file to InputImage: $e');
      return null;
    }
  }

  Future<void> _processVideoFrame(InputImage inputImage) async {
    try {
      // Process through pose detector service
      await _poseDetectorService.processInputImage(inputImage);
      
      // Update current pose frame from the latest in history
      if (_poseDetectorService.poseHistory.isNotEmpty) {
        _currentPoseFrame = _poseDetectorService.poseHistory.last;
      }
    } catch (e) {
      debugPrint('Error processing video frame: $e');
    }
  }

  // Dispose camera
  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetectorService.dispose();
    super.dispose();
  }
}
