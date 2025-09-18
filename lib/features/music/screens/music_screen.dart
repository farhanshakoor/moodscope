import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/music/providers/music_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/emotion_selector.dart';
import '../widgets/music_track_card.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load default recommendations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().getRecommendations('neutral');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                        'Music Therapy',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Music that matches your mood',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOut)
                .fadeIn(),

            // Search Bar
            Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.05 * 255).toInt()),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for songs, artists, albums...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintStyle: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                      onSubmitted: (value) async {
                        if (value.trim().isNotEmpty) {
                          final results = await context
                              .read<MusicProvider>()
                              .searchTracks(value.trim());
                          // Handle search results
                        }
                      },
                    ),
                  ),
                )
                .animate()
                .slideY(
                  begin: 0.3,
                  delay: 200.ms,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(delay: 200.ms),

            const SizedBox(height: AppConstants.paddingLarge),

            // Emotion Selector
            Consumer<MusicProvider>(
                  builder: (context, musicProvider, child) {
                    return EmotionSelector(
                      selectedEmotion: musicProvider.currentEmotion,
                      onEmotionSelected: (emotion) {
                        musicProvider.getRecommendations(emotion);
                      },
                    );
                  },
                )
                .animate()
                .slideX(
                  begin: -0.3,
                  delay: 400.ms,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(delay: 400.ms),

            const SizedBox(height: AppConstants.paddingLarge),

            // Music Recommendations
            Expanded(
              child: Consumer<MusicProvider>(
                builder: (context, musicProvider, child) {
                  if (musicProvider.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Finding perfect songs for you...',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (musicProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading music',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            musicProvider.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (musicProvider.recommendations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_off_rounded,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No music recommendations',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select an emotion to get personalized music suggestions',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge,
                        ),
                        child: Row(
                          children: [
                            Text(
                              AppConstants.emotionEmojis[musicProvider
                                      .currentEmotion] ??
                                  '🎵',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Music for ${musicProvider.currentEmotion} mood',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Music List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingLarge,
                          ),
                          itemCount: musicProvider.recommendations.length,
                          itemBuilder: (context, index) {
                            final track = musicProvider.recommendations[index];
                            return MusicTrackCard(
                                  track: track,
                                  onPlay: () => musicProvider.playTrack(track),
                                )
                                .animate()
                                .slideX(
                                  begin: 0.3,
                                  delay: Duration(
                                    milliseconds: index * 100 + 600,
                                  ),
                                  duration: 500.ms,
                                  curve: Curves.easeOut,
                                )
                                .fadeIn(
                                  delay: Duration(
                                    milliseconds: index * 100 + 600,
                                  ),
                                );
                          },
                        ),
                      ),
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
