import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('hi')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Kadam',
      'subtitle': 'Your step to better health',
      'quick_actions': 'Quick Actions',
      'run_scan': 'Run Scan',
      'view_results': 'View Results',
      'thirty_sec': '30-second analysis',
      'view_progress': 'View your progress',
      'recent_scans': 'Recent Scans',
      'score': 'Score',
      'no_scan_data': 'No scan data available. Please run a scan first.',
      'seconds_remaining_10': '10 seconds remaining',
      'seconds_remaining_5': '5 seconds remaining',
      'scan_complete': 'Scan complete',
      'scan_start':
          'Starting gait analysis scan. Please walk naturally in front of the camera.',
      'posture_correction': 'Posture correction',
      'language_english': 'English',
      'language_hindi': 'Hindi',
      'initializing_camera': 'Initializing Camera...',
      'ready_to_scan': 'Ready to Scan',
      'scan_instructions':
          'Position yourself in front of the camera and tap "Start Scan" to begin your 30-second gait analysis.',
      'tips_best_results': 'Tips for best results:',
      'tips_bullets':
          '• Ensure good lighting\n• Keep full body in frame\n• Walk naturally\n• Stand 2-3 meters away',
      'start_scan': 'Start Scan',
      'stop_scan': 'Stop Scan',
      'insufficient_data_title': 'Insufficient Data',
      'insufficient_data_body':
          'Not enough pose data was collected during the scan. Please ensure you are fully visible in the camera frame and try again.',
      'ok': 'OK',
      'sec': 'sec',
      'scanning': 'Scanning',
      'frames': 'frames',
      'data_quality': 'Data Quality',
      'cancel': 'Cancel',
      'replay_voice': 'Replay voice',
    },
    'hi': {
      'app_title': 'कदम',
      'subtitle': 'बेहतर स्वास्थ्य की ओर आपका कदम',
      'quick_actions': 'त्वरित क्रियाएँ',
      'run_scan': 'स्कैन चलाएँ',
      'view_results': 'परिणाम देखें',
      'thirty_sec': '30-सेकंड विश्लेषण',
      'view_progress': 'अपनी प्रगति देखें',
      'recent_scans': 'हाल के स्कैन',
      'score': 'स्कोर',
      'no_scan_data': 'कोई स्कैन डेटा उपलब्ध नहीं। कृपया पहले स्कैन चलाएँ।',
      'seconds_remaining_10': '10 सेकंड शेष',
      'seconds_remaining_5': '5 सेकंड शेष',
      'scan_complete': 'स्कैन पूर्ण',
      'scan_start':
          'गेट विश्लेषण स्कैन शुरू हो रहा है। कृपया कैमरे के सामने स्वाभाविक रूप से चलें।',
      'posture_correction': 'पोश्चर सुधार',
      'language_english': 'अंग्रेज़ी',
      'language_hindi': 'हिन्दी',
      'initializing_camera': 'कैमरा प्रारंभ हो रहा है...',
      'ready_to_scan': 'स्कैन के लिए तैयार',
      'scan_instructions':
          'कैमरे के सामने खड़े हों और 30-सेकंड के गेट विश्लेषण के लिए "स्कैन शुरू करें" पर टैप करें।',
      'tips_best_results': 'सर्वोत्तम परिणामों के लिए सुझाव:',
      'tips_bullets':
          '• अच्छी रोशनी सुनिश्चित करें\n• पूरा शरीर फ्रेम में रखें\n• स्वाभाविक रूप से चलें\n• 2-3 मीटर दूर खड़े हों',
      'start_scan': 'स्कैन शुरू करें',
      'stop_scan': 'स्कैन रोकें',
      'insufficient_data_title': 'पर्याप्त डेटा नहीं',
      'insufficient_data_body':
          'स्कैन के दौरान पर्याप्त पोज़ डेटा एकत्र नहीं हुआ। कृपया सुनिश्चित करें कि आप कैमरा फ्रेम में पूरी तरह दिखाई दे रहे हैं और पुनः प्रयास करें।',
      'ok': 'ठीक है',
      'sec': 'सेक',
      'scanning': 'स्कैनिंग',
      'frames': 'फ्रेम',
      'data_quality': 'डेटा गुणवत्ता',
      'cancel': 'रद्द करें',
      'replay_voice': 'आवाज़ दोहराएँ',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
