import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/dashboard/widgets/emotion_breakdown.dart';
import 'package:moodscope/features/dashboard/widgets/emotion_chart.dart';
import 'package:moodscope/features/dashboard/widgets/stats_card.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadAllStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Dashboard',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Insights into your emotional patterns', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ).animate().slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOut).fadeIn(),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                  Tab(text: 'Yearly'),
                ],
              ),
            ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 200.ms),

            const SizedBox(height: AppConstants.paddingLarge),

            // Tab Content
            Expanded(
              child: Consumer<DashboardProvider>(
                builder: (context, dashboardProvider, child) {
                  if (dashboardProvider.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryColor),
                          SizedBox(height: 16),
                          Text('Loading your emotional insights...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  if (dashboardProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text('Error loading analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Text(
                            dashboardProvider.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Weekly View
                      _DashboardContent(stats: dashboardProvider.weeklyStats, period: 'week'),
                      // Monthly View
                      _DashboardContent(stats: dashboardProvider.monthlyStats, period: 'month'),
                      // Yearly View
                      _DashboardContent(stats: dashboardProvider.yearlyStats, period: 'year'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final dynamic stats;
  final String period;

  const _DashboardContent({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Overview Cards
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Total Entries',
                  value: stats.totalEntries.toString(),
                  icon: Icons.analytics_rounded,
                  gradient: AppTheme.primaryGradient,
                ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 300.ms),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Avg Confidence',
                  value: '${stats.averageConfidence.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  gradient: AppTheme.accentGradient,
                ).animate().scale(delay: 400.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 400.ms),
              ),
            ],
          ),

          const SizedBox(height: 16),

          StatsCard(
            title: 'Most Frequent Emotion',
            value: stats.mostFrequentEmotion.toUpperCase(),
            subtitle: AppConstants.emotionEmojis[stats.mostFrequentEmotion] ?? '😐',
            icon: Icons.emoji_emotions_rounded,
            gradient: LinearGradient(
              colors: [
                AppTheme.emotionColors[stats.mostFrequentEmotion]?.withOpacity(0.8) ?? AppTheme.primaryColor,
                AppTheme.emotionColors[stats.mostFrequentEmotion] ?? AppTheme.primaryColor,
              ],
            ),
          ).animate().scale(delay: 500.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 500.ms),

          const SizedBox(height: AppConstants.paddingLarge),

          // Emotion Chart
          Text(
            'Emotion Trends',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ).animate().slideX(begin: -0.5, delay: 600.ms, duration: 500.ms).fadeIn(delay: 600.ms),

          const SizedBox(height: 16),

          EmotionChart(data: stats.chartData, period: period).animate().slideY(begin: 0.3, delay: 700.ms, duration: 600.ms, curve: Curves.easeOut).fadeIn(delay: 700.ms),

          const SizedBox(height: AppConstants.paddingLarge),

          // Emotion Breakdown
          Text(
            'Emotion Breakdown',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ).animate().slideX(begin: -0.5, delay: 800.ms, duration: 500.ms).fadeIn(delay: 800.ms),

          const SizedBox(height: 16),

          EmotionBreakdown(
            emotionCounts: stats.emotionCounts,
            totalEntries: stats.totalEntries,
          ).animate().slideY(begin: 0.3, delay: 900.ms, duration: 600.ms, curve: Curves.easeOut).fadeIn(delay: 900.ms),

          const SizedBox(height: AppConstants.paddingLarge),
        ],
      ),
    );
  }
}
