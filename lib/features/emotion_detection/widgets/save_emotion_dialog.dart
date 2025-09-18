import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SaveEmotionDialog extends StatefulWidget {
  final String emotion;
  final double confidence;
  final Function(String?) onSave;

  const SaveEmotionDialog({super.key, required this.emotion, required this.confidence, required this.onSave});

  @override
  State<SaveEmotionDialog> createState() => _SaveEmotionDialogState();
}

class _SaveEmotionDialogState extends State<SaveEmotionDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _saveEmotion() {
    widget.onSave(_noteController.text.trim().isEmpty ? null : _noteController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final emotionColor = AppTheme.emotionColors[widget.emotion] ?? AppTheme.textTertiary;
    final emotionEmoji = AppConstants.emotionEmojis[widget.emotion] ?? '😐';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _animationController.value,
            child: Opacity(
              opacity: _animationController.value,
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 0,
                borderRadius: 24,
                blur: 20,
                alignment: Alignment.bottomCenter,
                border: 2,
                linearGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
                borderGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)]),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [emotionColor.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: emotionColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: emotionColor.withOpacity(0.3), width: 2),
                            ),
                            child: Center(child: Text(emotionEmoji, style: const TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Save Emotion',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.emotion.toUpperCase()} (${widget.confidence.toStringAsFixed(1)}%)',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().slideX(begin: -0.5, duration: 400.ms, curve: Curves.easeOut).fadeIn(),

                      const SizedBox(height: 24),

                      // Note Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a note (optional)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: TextField(
                              controller: _noteController,
                              maxLines: 4,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'How are you feeling? What happened today?',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 400.ms, curve: Curves.easeOut).fadeIn(delay: 200.ms),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [emotionColor.withOpacity(0.8), emotionColor]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: emotionColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)],
                              ),
                              child: TextButton(
                                onPressed: _saveEmotion,
                                child: const Text(
                                  'Save Entry',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().slideY(begin: 0.3, delay: 400.ms, duration: 400.ms, curve: Curves.easeOut).fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
