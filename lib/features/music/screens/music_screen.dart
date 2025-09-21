import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/music/providers/enhanced_music_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/emotion_selector.dart';
import '../widgets/music_track_card.dart';

class EnhancedMusicScreen extends StatefulWidget {
  const EnhancedMusicScreen({super.key});

  @override
  State<EnhancedMusicScreen> createState() => _EnhancedMusicScreenState();
}

class _EnhancedMusicScreenState extends State<EnhancedMusicScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize with user's recent emotion-based recommendations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnhancedMusicProvider>().initializeWithUserEmotion();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      await context.read<EnhancedMusicProvider>().searchTracks(query.trim());
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<EnhancedMusicProvider>().clearSearch();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Music Therapy',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    Consumer<EnhancedMusicProvider>(
                      builder: (context, musicProvider, child) {
                        return Text('Music for your ${musicProvider.lastUserEmotion} mood', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary));
                      },
                    ),
                  ],
                ),
              ),
              _buildEmotionCaptureButton(),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOut).fadeIn();
  }

  Widget _buildEmotionCaptureButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
      ),
      // child: IconButton(
      //   onPressed: () async {
      //     // Navigate to emotion capture or trigger quick capture
      //     Navigator.pushNamed(context, '/emotion-detection').then((_) {
      //       // Refresh music recommendations after emotion capture
      //       context.read<EnhancedMusicProvider>().refreshBasedOnCurrentEmotion();
      //     });
      //   },
      //   icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 20),
      //   tooltip: 'Capture new emotion',
      // ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 10, spreadRadius: 2)],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for songs, artists, albums...',
            prefixIcon: _isSearching
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
                  )
                : const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          ),
          onChanged: (value) => setState(() {}),
          onSubmitted: _performSearch,
        ),
      ),
    ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 200.ms);
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'For You'),
          Tab(text: 'By Emotion'),
          Tab(text: 'Featured'),
        ],
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
      ),
    ).animate().slideY(begin: 0.2, delay: 400.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 400.ms);
  }

  Widget _buildTabContent() {
    return TabBarView(controller: _tabController, children: [_buildPersonalizedTab(), _buildEmotionBasedTab(), _buildFeaturedTab()]);
  }

  Widget _buildPersonalizedTab() {
    return Consumer<EnhancedMusicProvider>(
      builder: (context, musicProvider, child) {
        if (musicProvider.isLoading) {
          return _buildLoadingState('Finding your perfect songs...');
        }

        if (musicProvider.errorMessage != null) {
          return _buildErrorState(musicProvider.errorMessage!, () => musicProvider.getPersonalizedRecommendations());
        }

        if (musicProvider.recommendations.isEmpty) {
          return _buildEmptyState('No personalized recommendations yet', 'Capture some emotions to get personalized music suggestions', Icons.music_off_rounded);
        }

        return Column(
          children: [
            // Quick stats
            Container(
              margin: EdgeInsets.all(AppConstants.paddingMedium),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('${musicProvider.recommendations.length}', 'Songs', Icons.music_note),
                  _buildStatItem(musicProvider.lastUserEmotion, 'Current Mood', Icons.psychology),
                  _buildStatItem('Mixed', 'Genres', Icons.queue_music),
                ],
              ),
            ),

            // Music list
            Expanded(child: _buildMusicList(musicProvider.recommendations)),
          ],
        );
      },
    );
  }

  Widget _buildEmotionBasedTab() {
    return Column(
      children: [
        // Emotion Selector
        Consumer<EnhancedMusicProvider>(
          builder: (context, musicProvider, child) {
            return EmotionSelector(
              selectedEmotion: musicProvider.currentEmotion,
              onEmotionSelected: (emotion) {
                musicProvider.getRecommendations(emotion);
              },
            );
          },
        ).animate().slideX(begin: -0.3, delay: 100.ms, duration: 600.ms, curve: Curves.easeOut).fadeIn(delay: 100.ms),

        const SizedBox(height: AppConstants.paddingMedium),

        // Music recommendations
        Expanded(
          child: Consumer<EnhancedMusicProvider>(
            builder: (context, musicProvider, child) {
              if (musicProvider.isLoading) {
                return _buildLoadingState('Loading ${musicProvider.currentEmotion} music...');
              }

              if (musicProvider.errorMessage != null) {
                return _buildErrorState(musicProvider.errorMessage!, () => musicProvider.getRecommendations(musicProvider.currentEmotion));
              }

              if (musicProvider.recommendations.isEmpty) {
                return _buildEmptyState('No music found', 'Try selecting a different emotion', Icons.music_off_rounded);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                    child: Row(
                      children: [
                        Text(AppConstants.emotionEmojis[musicProvider.currentEmotion] ?? '🎵', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Music for ${musicProvider.currentEmotion} mood',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(onPressed: () => musicProvider.getPersonalizedRecommendations(), child: Text('Mix All')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Music list
                  Expanded(child: _buildMusicList(musicProvider.recommendations)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedTab() {
    return Consumer<EnhancedMusicProvider>(
      builder: (context, musicProvider, child) {
        if (musicProvider.loadingPlaylists) {
          return _buildLoadingState('Loading featured content...');
        }

        if (musicProvider.featuredPlaylists.isEmpty) {
          return _buildEmptyState('No featured content', 'Check back later for curated playlists', Icons.featured_play_list_outlined);
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppConstants.paddingMedium),
          itemCount: musicProvider.featuredPlaylists.length,
          itemBuilder: (context, index) {
            final playlist = musicProvider.featuredPlaylists[index];
            return _buildFeaturedPlaylistCard(playlist);
          },
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
      ],
    );
  }

  Widget _buildMusicList(List<dynamic> tracks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return MusicTrackCard(
              track: track,
              onPlay: () {
                context.read<EnhancedMusicProvider>().playTrack(track);
                // Save interaction for future recommendations
                context.read<EnhancedMusicProvider>().saveTrackInteraction(track, 'play');
              },
            )
            .animate()
            .slideX(
              begin: 0.3,
              delay: Duration(milliseconds: index * 50 + 100),
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(delay: Duration(milliseconds: index * 50 + 100));
      },
    );
  }

  Widget _buildFeaturedPlaylistCard(Map<String, dynamic> playlist) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: playlist['imageUrl'] != null
              ? Image.network(playlist['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
              : Container(
                  width: 60,
                  height: 60,
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  child: Icon(Icons.queue_music, color: AppTheme.primaryColor, size: 30),
                ),
        ),
        title: Text(
          playlist['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist['description'] != null) ...[Text(playlist['description'], maxLines: 2, overflow: TextOverflow.ellipsis), SizedBox(height: 4)],
            Text('${playlist['tracksTotal']} tracks', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        trailing: Icon(Icons.play_circle_outline, size: 32),
        onTap: () {
          // Handle playlist tap - could navigate to playlist details
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${playlist['name']}...')));
        },
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Error loading music', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
