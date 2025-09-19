import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SaveEmotionDialog extends StatefulWidget {
  final String emotion;
  final double confidence;
  final Function(String?) onSave;

  const SaveEmotionDialog({
    super.key,
    required this.emotion,
    required this.confidence,
    required this.onSave,
  });

  @override
  State<SaveEmotionDialog> createState() => _SaveEmotionDialogState();
}

class _SaveEmotionDialogState extends State<SaveEmotionDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  late AnimationController _animationController;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();

    // Auto-focus on text field after animation
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveEmotion() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final note = _noteController.text.trim();
      await widget.onSave(note.isEmpty ? null : note);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving emotion: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save emotion. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emotionColor =
        AppTheme.emotionColors[widget.emotion] ?? AppTheme.textTertiary;
    final emotionEmoji = AppConstants.emotionEmojis[widget.emotion] ?? '😐';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.3 + (_animationController.value * 0.7),
            child: Opacity(
              opacity: _animationController.value,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            emotionColor.withOpacity(0.15),
                            Colors.white.withOpacity(0.1),
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeader(emotionColor, emotionEmoji),

                            const SizedBox(height: 24),

                            // Note Input Section
                            _buildNoteInput(),

                            const SizedBox(height: 28),

                            // Action Buttons
                            _buildActionButtons(emotionColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color emotionColor, String emotionEmoji) {
    return Row(
          children: [
            // Emotion Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: emotionColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: emotionColor.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: emotionColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(emotionEmoji, style: const TextStyle(fontSize: 28)),
              ),
            ),

            const SizedBox(width: 20),

            // Title and Emotion Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save Emotion Entry',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: emotionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: emotionColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.emotion.toUpperCase()} • ${widget.confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .slideX(begin: -0.3, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 500.ms);
  }

  Widget _buildNoteInput() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a personal note about this moment (optional)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Text Input Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _noteController,
                focusNode: _focusNode,
                maxLines: 4,
                maxLength: 500,
                // style: TextStyle(
                //   color: Colors.white,
                //   fontSize: 16,
                //   height: 1.4,
                // ),
                decoration: InputDecoration(
                  hintText:
                      'What happened today? How are you feeling right now?',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                  counterStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                textInputAction: TextInputAction.newline,
              ),
            ),
          ],
        )
        .animate()
        .slideY(
          begin: 0.3,
          delay: 200.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildActionButtons(Color emotionColor) {
    return Row(
          children: [
            // Cancel Button
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: _isLoading
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Save Button
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [emotionColor.withOpacity(0.8), emotionColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: emotionColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _isLoading ? null : _saveEmotion,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Save Entry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
        .animate()
        .slideY(
          begin: 0.3,
          delay: 400.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: 400.ms, duration: 500.ms);
  }
}
