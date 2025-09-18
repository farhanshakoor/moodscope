import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EmotionDetectionCard extends StatelessWidget {
  final String emotion;
  final double confidence;
  final bool isDetecting;
  final String motivationalMessage;
  final VoidCallback onSave;
  final VoidCallback onToggleDetection;

  const EmotionDetectionCard({
    super.key,
    required this.emotion,
    required this.confidence,
    required this.isDetecting,
    required this.motivationalMessage,
    required this.onSave,
    required this.onToggleDetection,
  });

  @override
  Widget build(BuildContext context) {
    final emotionColor =
        AppTheme.emotionColors[emotion] ?? AppTheme.textTertiary;
    final emotionEmoji = AppConstants.emotionEmojis[emotion] ?? '😐';

    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 24,
      blur: 20,
      alignment: Alignment.bottomCenter,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Emotion Display
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: emotionColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: emotionColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emotionEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .shimmer(
                        duration: 1200.ms,
                        color: emotionColor.withOpacity(0.5),
                      ),

                  const SizedBox(height: 12),

                  // Emotion Name
                  Text(
                        emotion.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                      )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(),

                  const SizedBox(height: 8),

                  // Confidence
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: emotionColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: emotionColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${confidence.toStringAsFixed(1)}% Confidence',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        delay: 100.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  // Motivational Message
                  Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          motivationalMessage,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
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
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  // Toggle Detection Button
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isDetecting
                            ? LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                ],
                              )
                            : LinearGradient(
                                colors: AppTheme.primaryGradient.colors,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDetecting
                                        ? Colors.red
                                        : AppTheme.primaryColor)
                                    .withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: onToggleDetection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isDetecting
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDetecting ? 'Stop' : 'Start',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Save Button
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: confidence > 0 ? onSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
