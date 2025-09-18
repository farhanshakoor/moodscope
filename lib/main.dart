// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:moodscope/features/auth/provider/auth_provider.dart';
import 'package:moodscope/features/dashboard/providers/dashboard_provider.dart';
import 'package:moodscope/features/diary/providers/diary_provider.dart';
import 'package:moodscope/features/music/providers/music_provider.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:toastification/toastification.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/emotion_detection/providers/emotion_provider.dart';

import 'features/auth/screens/splash_screen.dart';

// Global cameras list
List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize cameras
  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Error initializing cameras: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const EmotionWellbeingApp());
}

class EmotionWellbeingApp extends StatelessWidget {
  const EmotionWellbeingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => EmotionProvider(),
          ), // Uncommented this
          ChangeNotifierProvider(create: (_) => DiaryProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => MusicProvider()),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
