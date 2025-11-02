import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSProvider extends ChangeNotifier {
  FlutterTts? _flutterTts;
  bool _isEnabled = true;
  double _speechRate = 0.5;
  double _volume = 0.8;
  double _pitch = 1.0;
  String _languageCode = 'en-US';

  // Getters
  bool get isEnabled => _isEnabled;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;

  // Initialize TTS
  Future<void> initializeTTS() async {
    _flutterTts = FlutterTts();

    await _flutterTts!.setLanguage(_languageCode);
    await _flutterTts!.setSpeechRate(_speechRate);
    await _flutterTts!.setVolume(_volume);
    await _flutterTts!.setPitch(_pitch);

    // Set up completion handler
    _flutterTts!.setCompletionHandler(() {
      debugPrint("TTS completed");
    });

    // Set up error handler
    _flutterTts!.setErrorHandler((msg) {
      debugPrint("TTS error: $msg");
    });
  }

  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    if (_flutterTts != null) {
      try {
        await _flutterTts!.setLanguage(code);
      } catch (_) {}
    }
    notifyListeners();
  }

  // Speak text
  Future<void> speak(String text) async {
    if (!_isEnabled || _flutterTts == null) return;

    try {
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  // Stop speaking
  Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
  }

  // Toggle TTS on/off
  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    notifyListeners();
  }

  // Set speech rate
  void setSpeechRate(double rate) {
    _speechRate = rate;
    if (_flutterTts != null) {
      _flutterTts!.setSpeechRate(rate);
    }
    notifyListeners();
  }

  // Set volume
  void setVolume(double volume) {
    _volume = volume;
    if (_flutterTts != null) {
      _flutterTts!.setVolume(volume);
    }
    notifyListeners();
  }

  // Set pitch
  void setPitch(double pitch) {
    _pitch = pitch;
    if (_flutterTts != null) {
      _flutterTts!.setPitch(pitch);
    }
    notifyListeners();
  }

  // Predefined feedback messages
  void speakPostureFeedback(String feedback) {
    final prefix = _languageCode.startsWith('hi')
        ? 'पोश्चर सुधार'
        : 'Posture correction';
    speak("$prefix: $feedback");
  }

  void speakScanProgress(int remainingTime) {
    if (remainingTime == 10) {
      speak(
        _languageCode.startsWith('hi')
            ? '10 सेकंड शेष'
            : '10 seconds remaining',
      );
    } else if (remainingTime == 5) {
      speak(
        _languageCode.startsWith('hi') ? '5 सेकंड शेष' : '5 seconds remaining',
      );
    } else if (remainingTime == 1) {
      speak(_languageCode.startsWith('hi') ? 'स्कैन पूर्ण' : 'Scan complete');
    }
  }

  void speakScanStart() {
    final msg = _languageCode.startsWith('hi')
        ? 'गेट विश्लेषण स्कैन शुरू हो रहा है। कृपया कैमरे के सामने स्वाभाविक रूप से चलें।'
        : 'Starting gait analysis scan. Please walk naturally in front of the camera.';
    speak(msg);
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    super.dispose();
  }
}
