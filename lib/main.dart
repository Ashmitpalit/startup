import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'screens/landing_page.dart';
import 'providers/gait_analysis_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/tts_provider.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/badge_provider.dart';
import 'services/step_counter_service.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GaitAnalysisApp());
}

class GaitAnalysisApp extends StatelessWidget {
  const GaitAnalysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GaitAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => StepCounterService()),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..loadSavedLanguage(),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final ttsProvider = TTSProvider();
            ttsProvider.initializeTTS();
            return ttsProvider;
          },
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) => MaterialApp(
          title: 'Kadam',
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), // Indigo accent
              brightness: Brightness.dark, // Minimalist dark UI
            ),
            scaffoldBackgroundColor: const Color(0xFF0B0B0F),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B0B0F),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xFF121218),
            useMaterial3: true,
          ),
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.isAuthenticated) {
                return const LandingPage();
              }
              return const AuthScreen();
            },
          ),
        ),
      ),
    );
  }
}
