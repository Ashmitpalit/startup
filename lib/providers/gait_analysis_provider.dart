import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';

class GaitAnalysisProvider extends ChangeNotifier {
  List<ScanResult> _scanHistory = [];
  ScanResult? _currentScan;
  bool _isAnalyzing = false;
  double _overallHealthScore = 0.0;
  int _dailySteps = 0;

  // Getters
  List<ScanResult> get scanHistory => _scanHistory;
  ScanResult? get currentScan => _currentScan;
  bool get isAnalyzing => _isAnalyzing;
  double get overallHealthScore => _overallHealthScore;
  int get dailySteps => _dailySteps;

  // Add new scan result
  void addScanResult(ScanResult result) {
    _scanHistory.insert(0, result); // Add to beginning for recent first
    _currentScan = result;
    _updateOverallHealthScore();
    _simulateStepsFromScan(); // Simulate steps from scan activity
    notifyListeners();
  }

  // Update analyzing state
  void setAnalyzing(bool analyzing) {
    _isAnalyzing = analyzing;
    notifyListeners();
  }

  // Update daily steps (simulated - can be replaced with actual sensor data)
  void updateDailySteps(int steps) {
    _dailySteps = steps;
    notifyListeners();
  }

  // Simulate steps from scan activity
  void _simulateStepsFromScan() {
    // Add random steps between 500-2000 per scan
    _dailySteps += (500 + (DateTime.now().millisecond % 1500));
    notifyListeners();
  }

  // Calculate overall health score based on recent scans
  void _updateOverallHealthScore() {
    if (_scanHistory.isEmpty) {
      _overallHealthScore = 0.0;
      return;
    }

    // Calculate average of last 5 scans or all if less than 5
    int scansToConsider = _scanHistory.length > 5 ? 5 : _scanHistory.length;
    double totalScore = 0.0;

    for (int i = 0; i < scansToConsider; i++) {
      totalScore += _scanHistory[i].healthScore;
    }

    _overallHealthScore = totalScore / scansToConsider;
  }

  // Get injury risk areas for heat map
  Map<String, double> getInjuryRiskAreas() {
    if (_currentScan == null) return {};

    return {
      'Lower Back': _currentScan!.injuryRisk['lower_back'] ?? 0.0,
      'Left Knee': _currentScan!.injuryRisk['left_knee'] ?? 0.0,
      'Right Knee': _currentScan!.injuryRisk['right_knee'] ?? 0.0,
      'Left Ankle': _currentScan!.injuryRisk['left_ankle'] ?? 0.0,
      'Right Ankle': _currentScan!.injuryRisk['right_ankle'] ?? 0.0,
      'Left Hip': _currentScan!.injuryRisk['left_hip'] ?? 0.0,
      'Right Hip': _currentScan!.injuryRisk['right_hip'] ?? 0.0,
    };
  }

  // Get progress over time
  List<Map<String, dynamic>> getProgressData() {
    return _scanHistory
        .map(
          (scan) => {
            'date': scan.timestamp,
            'score': scan.healthScore,
            'strideLength': scan.gaitData.averageStrideLength,
            'cadence': scan.gaitData.averageCadence,
          },
        )
        .toList();
  }

  // Clear all data
  void clearAllData() {
    _scanHistory.clear();
    _currentScan = null;
    _overallHealthScore = 0.0;
    notifyListeners();
  }
}
