import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/auth/provider/auth_provider.dart';
import 'package:moodscope/features/auth/screens/login_screen.dart';
import 'package:moodscope/features/auth/screens/onboarding_screen.dart';
import 'package:moodscope/features/dashboard/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(AppConstants.isFirstTimeKey) ?? true;

    // Check authentication status
    if (authProvider.isAuthenticated) {
      // User is logged in, go to home
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (isFirstTime) {
      // First time user, show onboarding
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else {
      // Returning user, show login
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                ),
                child: const Icon(Icons.psychology_alt_rounded, size: 60, color: AppTheme.primaryColor),
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 400.ms),

              const SizedBox(height: 30),

              // App Name
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ).animate().slideY(begin: 1, delay: 400.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(delay: 400.ms, duration: 500.ms),

              const SizedBox(height: 10),

              // Tagline
              Text(
                'Your Emotional Journey Starts Here',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ).animate().slideY(begin: 1, delay: 600.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(delay: 600.ms, duration: 500.ms),

              const SizedBox(height: 60),

              // Loading Indicator
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms).scale(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
