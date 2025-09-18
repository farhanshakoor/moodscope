import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/music/models/music_track.dart';

import '../../../core/theme/app_theme.dart';

class MusicTrackCard extends StatelessWidget {
  final MusicTrack track;
  final VoidCallback onPlay;

  const MusicTrackCard({super.key, required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppTheme.primaryGradient),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: track.imageUrl.isNotEmpty
                    ? Image.network(
                        track.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderArt();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderArt();
                        },
                      )
                    : _buildPlaceholderArt(),
              ),
            ),

            const SizedBox(width: 16),

            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${track.album} • ${track.duration}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Play Button
            GestureDetector(
              onTap: () {
                onPlay();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.music_note_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Playing: ${track.title}')),
                      ],
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
            ).animate(onComplete: (controller) => controller.repeat()).shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Icon(Icons.music_note_rounded, color: Colors.white, size: 30)),
    );
  }
}
