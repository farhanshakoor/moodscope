import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EmotionBreakdown extends StatelessWidget {
  final Map<String, int> emotionCounts;
  final int totalEntries;

  const EmotionBreakdown({super.key, required this.emotionCounts, required this.totalEntries});

  @override
  Widget build(BuildContext context) {
    if (emotionCounts.isEmpty || totalEntries == 0) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_rounded, size: 48, color: AppTheme.textTertiary),
              SizedBox(height: 8),
              Text('No emotion data available', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Sort emotions by count (descending)
    final sortedEmotions = emotionCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: sortedEmotions.map((entry) {
          final emotion = entry.key;
          final count = entry.value;
          final percentage = (count / totalEntries) * 100;
          final emotionColor = AppTheme.emotionColors[emotion] ?? AppTheme.textTertiary;
          final emotionEmoji = AppConstants.emotionEmojis[emotion] ?? '😐';
          final index = sortedEmotions.indexOf(entry);

          return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Emotion emoji and name
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: emotionColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: emotionColor.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Center(child: Text(emotionEmoji, style: const TextStyle(fontSize: 18))),
                        ),

                        const SizedBox(width: 12),

                        // Emotion name
                        Expanded(
                          child: Text(
                            emotion.toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),

                        // Count and percentage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$count entries',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            Text('${percentage.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [emotionColor.withValues(alpha: 0.8), emotionColor]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .slideX(
                begin: 0.3,
                delay: Duration(milliseconds: index * 100),
                duration: 500.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(delay: Duration(milliseconds: index * 100));
        }).toList(),
      ),
    );
  }
}
