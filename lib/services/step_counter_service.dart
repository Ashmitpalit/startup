import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepCounterService extends ChangeNotifier {
  Stream<StepCount>? _stepCountStream;
  Stream<PedestrianStatus>? _pedestrianStatusStream;
  bool _isListening = false;
  int _currentSteps = 0;
  int _todaySteps = 0;
  DateTime? _lastUpdateDate;
  bool _hasPermission = false;

  int get currentSteps => _currentSteps;
  int get todaySteps => _todaySteps;
  bool get isListening => _isListening;
  bool get hasPermission => _hasPermission;

  // Request step counter permission
  Future<bool> requestPermission() async {
    try {
      if (defaultTargetPlatform == defaultTargetPlatform) {
        // Android: Request ACTIVITY_RECOGNITION permission
        final status = await Permission.activityRecognition.request();
        _hasPermission = status.isGranted;
        
        if (!_hasPermission) {
          debugPrint('Activity recognition permission denied');
          return false;
        }
      }
      
      // Initialize pedometer
      await _initializePedometer();
      return true;
    } catch (e) {
      debugPrint('Error requesting step counter permission: $e');
      _hasPermission = false;
      return false;
    }
  }

  // Check if permission is already granted
  Future<bool> checkPermission() async {
    try {
      final status = await Permission.activityRecognition.status;
      _hasPermission = status.isGranted;
      
      if (_hasPermission) {
        await _initializePedometer();
      }
      
      return _hasPermission;
    } catch (e) {
      debugPrint('Error checking step counter permission: $e');
      _hasPermission = false;
      return false;
    }
  }

  // Initialize pedometer streams
  Future<void> _initializePedometer() async {
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      
      // Get initial step count
      await _updateInitialStepCount();
    } catch (e) {
      debugPrint('Error initializing pedometer: $e');
    }
  }

  // Get initial step count
  Future<void> _updateInitialStepCount() async {
    try {
      // Note: Pedometer doesn't have a direct getStepCount method
      // We'll initialize from the stream instead
      // Steps will be updated via the stream listener
      _currentSteps = 0;
      
      // Check if we need to reset for a new day
      final now = DateTime.now();
      if (_lastUpdateDate == null || 
          now.day != _lastUpdateDate!.day ||
          now.month != _lastUpdateDate!.month ||
          now.year != _lastUpdateDate!.year) {
        _todaySteps = _currentSteps;
      } else {
        // Calculate today's steps from current total
        _todaySteps = _currentSteps;
      }
      
      _lastUpdateDate = now;
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting initial step count: $e');
    }
  }

  // Start listening to step count updates
  void startListening() {
    if (_isListening || !_hasPermission || _stepCountStream == null) {
      return;
    }

    _isListening = true;
    
    _stepCountStream!.listen((StepCount event) {
      final now = DateTime.now();
      
      // Reset if it's a new day
      if (_lastUpdateDate == null || 
          now.day != _lastUpdateDate!.day ||
          now.month != _lastUpdateDate!.month ||
          now.year != _lastUpdateDate!.year) {
        _todaySteps = 0;
        _lastUpdateDate = now;
      }
      
      _currentSteps = event.steps;
      _todaySteps = _currentSteps;
      _lastUpdateDate = now;
      notifyListeners();
    }).onError((error) {
      debugPrint('Error in step count stream: $error');
    });

    _pedestrianStatusStream?.listen((PedestrianStatus event) {
      debugPrint('Pedestrian status: ${event.status}');
    }).onError((error) {
      debugPrint('Error in pedestrian status stream: $error');
    });
  }

  // Stop listening to step count updates
  void stopListening() {
    _isListening = false;
    // Note: Streams will continue, but we stop processing
  }

  // Manually update steps (fallback if sensor unavailable)
  void updateSteps(int steps) {
    _currentSteps = steps;
    _todaySteps = steps;
    _lastUpdateDate = DateTime.now();
    notifyListeners();
  }

  // Reset daily steps
  void resetDailySteps() {
    _todaySteps = 0;
    notifyListeners();
  }

  // Get total lifetime steps (estimated from scans if sensor unavailable)
  int getLifetimeSteps() {
    // This could be enhanced to store historical data
    return _currentSteps;
  }
}
