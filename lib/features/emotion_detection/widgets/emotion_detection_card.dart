import 'package:flutter/material.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EmotionDetectionCard extends StatefulWidget {
  final String emotion;
  final double confidence;
  final bool isDetecting;
  final bool isCapturing;
  final String motivationalMessage;
  final VoidCallback onSave;
  final VoidCallback onToggleDetection;
  final VoidCallback onManualCapture;

  const EmotionDetectionCard({
    super.key,
    required this.emotion,
    required this.confidence,
    required this.isDetecting,
    required this.isCapturing,
    required this.motivationalMessage,
    required this.onSave,
    required this.onToggleDetection,
    required this.onManualCapture,
  });

  @override
  State<EmotionDetectionCard> createState() => _EmotionDetectionCardState();
}

class _EmotionDetectionCardState extends State<EmotionDetectionCard>
    with TickerProviderStateMixin {
  late AnimationController _emojiPulseController;
  late AnimationController _captureButtonController;
  String _previousEmotion = '';

  @override
  void initState() {
    super.initState();
    _emojiPulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _captureButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(EmotionDetectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.emotion != _previousEmotion && widget.emotion != 'neutral') {
      _previousEmotion = widget.emotion;
      _emojiPulseController.forward().then((_) {
        _emojiPulseController.reset();
      });
    }

    if (widget.isCapturing != oldWidget.isCapturing) {
      if (widget.isCapturing) {
        _captureButtonController.forward();
      } else {
        _captureButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _emojiPulseController.dispose();
    _captureButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotionColor = AppTheme.emotionColors[widget.emotion] ?? Colors.grey;
    final emotionEmoji = AppConstants.emotionEmojis[widget.emotion] ?? '😐';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: emotionColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildEmotionSection(emotionColor, emotionEmoji),
                ),

                const SizedBox(height: 16),

                _buildControlsSection(emotionColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionSection(Color emotionColor, String emotionEmoji) {
    return Row(
      children: [
        // Emoji and basic info
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Emoji with improved feedback
              AnimatedBuilder(
                animation: _emojiPulseController,
                builder: (context, child) {
                  final size = 60.0 + (_emojiPulseController.value * 8);
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: emotionColor.withOpacity(
                        widget.confidence > 0 ? 0.15 : 0.05,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: emotionColor.withOpacity(
                          widget.confidence > 0
                              ? 0.4 + _emojiPulseController.value * 0.3
                              : 0.2,
                        ),
                        width: 2,
                      ),
                      boxShadow: widget.confidence > 0
                          ? [
                              BoxShadow(
                                color: emotionColor.withOpacity(0.3),
                                blurRadius:
                                    8 + (_emojiPulseController.value * 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emotionEmoji,
                        style: TextStyle(
                          fontSize: 28 + (_emojiPulseController.value * 4),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Emotion name with better status indication
              Text(
                widget.emotion.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: widget.confidence > 0 ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              // Confidence with improved display
              if (widget.confidence > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: emotionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.confidence.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else if (widget.isDetecting) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ready',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Motivational message or status
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.confidence > 0 &&
                    widget.motivationalMessage.isNotEmpty) ...[
                  Text(
                    widget.motivationalMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (widget.isCapturing) ...[
                  const Icon(Icons.psychology, color: Colors.white70, size: 24),
                  const SizedBox(height: 4),
                  const Text(
                    'Analyzing...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (widget.isDetecting) ...[
                  const Icon(Icons.camera_alt, color: Colors.white70, size: 24),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to capture your emotion',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Icon(Icons.play_arrow, color: Colors.white70, size: 24),
                  const SizedBox(height: 4),
                  const Text(
                    'Start detection to begin',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsSection(Color emotionColor) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Start/Stop Detection Button
          Expanded(
            child: _buildActionButton(
              onPressed: widget.onToggleDetection,
              icon: widget.isDetecting
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
              label: widget.isDetecting ? 'Stop' : 'Start',
              colors: widget.isDetecting
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [emotionColor.withOpacity(0.8), emotionColor],
              glowColor: widget.isDetecting ? Colors.red : emotionColor,
            ),
          ),

          const SizedBox(width: 12),

          // Manual Capture Button (only when detecting)
          if (widget.isDetecting) ...[
            Expanded(
              child: AnimatedBuilder(
                animation: _captureButtonController,
                builder: (context, child) {
                  return _buildActionButton(
                    onPressed: widget.isCapturing
                        ? null
                        : widget.onManualCapture,
                    icon: widget.isCapturing
                        ? Icons.hourglass_empty
                        : Icons.camera_alt,
                    label: widget.isCapturing ? 'Wait...' : 'Capture',
                    colors: [
                      Colors.blue.shade400.withOpacity(0.8),
                      Colors.blue.shade600,
                    ],
                    glowColor: Colors.blue,
                    isEnabled: !widget.isCapturing,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Save Button
          Expanded(
            child: _buildActionButton(
              onPressed: widget.confidence > 0 ? widget.onSave : null,
              icon: Icons.bookmark_add_rounded,
              label: 'Save',
              colors: [
                AppTheme.accentColor.withOpacity(0.8),
                AppTheme.accentColor,
              ],
              glowColor: AppTheme.accentColor,
              isEnabled: widget.confidence > 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Color glowColor,
    bool isEnabled = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(colors: colors)
            : LinearGradient(
                colors: [Colors.grey.shade600, Colors.grey.shade700],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
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
    );
  }
}
