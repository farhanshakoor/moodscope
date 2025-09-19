import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:moodscope/core/constants/app_constants.dart';
import 'package:moodscope/core/theme/app_theme.dart';
import 'package:moodscope/features/emotion_detection/models/emotion_entry.dart';

class EmotionEntryCard extends StatelessWidget {
  final EmotionEntry entry;
  final VoidCallback? onDelete;

  const EmotionEntryCard({super.key, required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final emotionColor = AppTheme.emotionColors[entry.emotion] ?? Colors.grey;
    final emotionEmoji = AppConstants.emotionEmojis[entry.emotion] ?? '😐';

    return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: emotionColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: emotionColor.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Emotion Emoji
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: emotionColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: emotionColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        emotionEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Emotion and Confidence
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.emotion.toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Confidence: ${entry.confidence.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Delete Button
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Timestamp
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(entry.timestamp),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                ),
                // Note
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.note!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut);
  }
}
