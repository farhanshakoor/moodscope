import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/auth/provider/auth_provider.dart';
import 'package:moodscope/features/dashboard/screens/dashboard_screen.dart';
import 'package:moodscope/features/diary/screens/diary_screen.dart';
import 'package:moodscope/features/emotion_detection/screens/image_capture_emotion_screen.dart';
import 'package:moodscope/features/music/screens/music_screen.dart';
import 'package:moodscope/features/profile/screens/profile_screen.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart'; // Import to access global cameras list

import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Updated to pass cameras to EmotionDetectionScreen
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize screens with cameras parameter
    _screens = [
      const HomeTabScreen(),
      // EmotionDetectionScreen(cameras: cameras), // Pass global cameras list
      ImageCaptureEmotionScreen(cameras: cameras),
      const DiaryScreen(),
      const DashboardScreen(),
      const EnhancedMusicScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: AppConstants.shortAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.user;
                          final userName = user?.displayName ?? 'User';
                          final greeting = _getGreeting();

                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      greeting,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withAlpha(
                                        (0.3 * 255).toInt(),
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: user?.photoURL != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: Image.network(
                                          user!.photoURL!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          userName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      )
                      .animate()
                      .slideY(
                        begin: -0.5,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(),

                  const SizedBox(height: AppConstants.paddingExtraLarge),

                  // Quick Actions Grid
                  Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                      .animate()
                      .slideX(begin: -0.5, delay: 200.ms, duration: 500.ms)
                      .fadeIn(delay: 200.ms),

                  const SizedBox(height: AppConstants.paddingMedium),
                ]),
              ),
            ),

            // Quick Actions Grid - Using SliverGrid for better performance
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio:
                      1.1, // Increased from 1.2 to 1.1 for more height
                ),
                delegate: SliverChildListDelegate([
                  _QuickActionCard(
                        title: 'Detect Emotion',
                        subtitle: 'Analyze your current mood',
                        icon: Icons.camera_alt_rounded,
                        gradient: AppTheme.primaryGradient,
                        onTap: () {
                          // Navigate to emotion detection tab
                          final homeScreenState = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          homeScreenState?._onTabTapped(
                            1,
                          ); // Index 1 is EmotionDetectionScreen
                        },
                      )
                      .animate()
                      .scale(
                        delay: 300.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(delay: 300.ms),

                  _QuickActionCard(
                        title: 'Emotion Diary',
                        subtitle: 'View your emotional journey',
                        icon: Icons.book_rounded,
                        gradient: AppTheme.accentGradient,
                        onTap: () {
                          // Navigate to diary tab
                          final homeScreenState = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          homeScreenState?._onTabTapped(
                            2,
                          ); // Index 2 is DiaryScreen
                        },
                      )
                      .animate()
                      .scale(
                        delay: 400.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(delay: 400.ms),

                  _QuickActionCard(
                        title: 'Analytics',
                        subtitle: 'Insights & trends',
                        icon: Icons.analytics_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        onTap: () {
                          // Navigate to dashboard tab
                          final homeScreenState = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          homeScreenState?._onTabTapped(
                            3,
                          ); // Index 3 is DashboardScreen
                        },
                      )
                      .animate()
                      .scale(
                        delay: 500.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(delay: 500.ms),

                  _QuickActionCard(
                        title: 'Music Therapy',
                        subtitle: 'Mood-based playlists',
                        icon: Icons.music_note_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        onTap: () {
                          // Navigate to music tab
                          final homeScreenState = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          homeScreenState?._onTabTapped(
                            4,
                          ); // Index 4 is MusicScreen
                        },
                      )
                      .animate()
                      .scale(
                        delay: 600.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(delay: 600.ms),
                ]),
              ),
            ),

            // Daily Mood Section
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppConstants.paddingExtraLarge),

                  Text(
                        'Today\'s Mood Journey',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                      .animate()
                      .slideX(begin: -0.5, delay: 700.ms, duration: 500.ms)
                      .fadeIn(delay: 700.ms),

                  const SizedBox(height: AppConstants.paddingMedium),

                  Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          AppConstants.paddingLarge,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.white.withAlpha((0.9 * 255).toInt()),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.05 * 255).toInt(),
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // Important: Prevents overflow
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.timeline_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize:
                                        MainAxisSize.min, // Prevents overflow
                                    children: [
                                      Text(
                                        'Emotional Timeline',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Track your emotions throughout the day',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 80,
                              width: double.infinity, // Explicit width
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Start detecting emotions to see your timeline',
                                  textAlign:
                                      TextAlign.center, // Center align text
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        delay: 800.ms,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(delay: 800.ms),

                  const SizedBox(height: AppConstants.paddingExtraLarge),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha((0.3 * 255).toInt()),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding from 20 to 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 28,
              ), // Reduced size from 32 to 28
              const SizedBox(height: 8), // Add small spacing
              Flexible(
                // Wrap in Flexible to prevent overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Reduced from 16 to 14
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2, // Limit lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha((0.9 * 255).toInt()),
                        fontSize: 11, // Reduced from 12 to 11
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2, // Limit lines
                      overflow: TextOverflow.ellipsis,
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
