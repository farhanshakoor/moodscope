import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EmotionSelector extends StatelessWidget {
  final String selectedEmotion;
  final Function(String) onEmotionSelected;

  const EmotionSelector({super.key, required this.selectedEmotion, required this.onEmotionSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your mood',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.emotionLabels.map((emotion) {
                final isSelected = selectedEmotion == emotion;
                final emotionColor = AppTheme.emotionColors[emotion] ?? AppTheme.textTertiary;
                final emotionEmoji = AppConstants.emotionEmojis[emotion] ?? '😐';
                final index = AppConstants.emotionLabels.indexOf(emotion);

                return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => onEmotionSelected(emotion),
                        child: AnimatedContainer(
                          duration: AppConstants.shortAnimationDuration,
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: isSelected ? LinearGradient(colors: [emotionColor.withOpacity(0.8), emotionColor]) : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: isSelected ? emotionColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(color: emotionColor.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)
                              else
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, spreadRadius: 1),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emotionEmoji, style: TextStyle(fontSize: isSelected ? 32 : 28)),
                              const SizedBox(height: 8),
                              Text(
                                emotion.toUpperCase(),
                                style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(duration: AppConstants.shortAnimationDuration, curve: Curves.elasticOut)
                    .shimmer(duration: 1500.ms, color: isSelected ? Colors.white.withOpacity(0.3) : null)
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
          ),
        ],
      ),
    );
  }
}
