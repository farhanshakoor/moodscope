import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isFirstTimeKey, false);

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _nextPage() {
    if (_currentPage < AppConstants.onboardingSteps.length - 1) {
      _pageController.nextPage(duration: AppConstants.mediumAnimationDuration, curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: AppConstants.onboardingSteps.length,
                  itemBuilder: (context, index) {
                    final step = AppConstants.onboardingSteps[index];
                    return _OnboardingPage(title: step['title']!, subtitle: step['subtitle']!, description: step['description']!, imagePath: step['image']!, index: index);
                  },
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(AppConstants.onboardingSteps.length, (index) => _PageIndicator(isActive: index == _currentPage)),
                    ),

                    const SizedBox(height: AppConstants.paddingLarge),

                    // Next/Get Started Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _currentPage == AppConstants.onboardingSteps.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final int index;

  const _OnboardingPage({required this.title, required this.subtitle, required this.description, required this.imagePath, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Container
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(140),
              boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)],
            ),
            child: _getIllustrationIcon(index),
          ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut).fadeIn(duration: 600.ms),

          const SizedBox(height: AppConstants.paddingExtraLarge),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ).animate().slideY(begin: 0.5, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 400.ms),

          const SizedBox(height: AppConstants.paddingSmall),

          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ).animate().slideY(begin: 0.5, delay: 500.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 500.ms),

          const SizedBox(height: AppConstants.paddingMedium),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ).animate().slideY(begin: 0.5, delay: 600.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _getIllustrationIcon(int index) {
    final icons = [Icons.psychology_alt_rounded, Icons.camera_alt_rounded, Icons.analytics_rounded, Icons.music_note_rounded];

    return Icon(icons[index], size: 120, color: Colors.white);
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(color: isActive ? AppTheme.primaryColor : AppTheme.textTertiary, borderRadius: BorderRadius.circular(4)),
    ).animate().scale(duration: AppConstants.shortAnimationDuration, curve: Curves.easeInOut).slideX(duration: AppConstants.shortAnimationDuration, curve: Curves.easeInOut);
  }
}
