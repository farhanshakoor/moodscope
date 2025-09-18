import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/emotion_detection/widgets/emotion_detection_card.dart';
import 'package:moodscope/features/emotion_detection/widgets/save_emotion_dialog.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/emotion_provider.dart';

class EmotionDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const EmotionDetectionScreen({super.key, required this.cameras});

  @override
  State<EmotionDetectionScreen> createState() => _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends State<EmotionDetectionScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDetection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
    _rippleController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
  }

  void _initializeDetection() async {
    final emotionProvider = context.read<EmotionProvider>();

    // Load model first
    if (!emotionProvider.isModelLoaded) {
      await emotionProvider.loadModel();
    }

    // Then initialize camera
    if (!emotionProvider.isCameraInitialized && widget.cameras.isNotEmpty) {
      await emotionProvider.initializeCamera(widget.cameras);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _showSaveEmotionDialog(EmotionProvider emotionProvider) {
    showDialog(
      context: context,
      builder: (context) => SaveEmotionDialog(
        emotion: emotionProvider.currentEmotion,
        confidence: emotionProvider.confidence,
        onSave: (note) async {
          final success = await emotionProvider.saveEmotionEntry(note: note);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Emotion saved successfully! ${AppConstants.emotionEmojis[emotionProvider.currentEmotion] ?? ''}'),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            _rippleController.forward().then((_) {
              _rippleController.reset();
            });
          }
        },
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeDetection(); // Retry initialization
            },
            child: const Text('Retry'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Consumer<EmotionProvider>(
            builder: (context, emotionProvider, child) {
              // Show error dialog if there's an error
              if (emotionProvider.errorMessage != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showErrorDialog(emotionProvider.errorMessage!);
                  emotionProvider.clearError();
                });
              }

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_rounded),
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Emotion Detection',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Status indicators
                        Row(
                          children: [
                            Icon(emotionProvider.isModelLoaded ? Icons.check_circle : Icons.pending, color: emotionProvider.isModelLoaded ? Colors.green : Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Icon(
                              emotionProvider.isCameraInitialized ? Icons.videocam : Icons.videocam_off,
                              color: emotionProvider.isCameraInitialized ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

                  // Camera Preview Section
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: emotionProvider.isCameraInitialized && emotionProvider.cameraController != null
                            ? Stack(
                                children: [
                                  // Camera Preview
                                  SizedBox.expand(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: emotionProvider.cameraController!.value.previewSize?.height ?? 1,
                                        height: emotionProvider.cameraController!.value.previewSize?.width ?? 1,
                                        child: CameraPreview(emotionProvider.cameraController!),
                                      ),
                                    ),
                                  ),

                                  // Detection Overlay
                                  if (emotionProvider.isDetecting) _buildDetectionOverlay(),

                                  // Ripple Effect
                                  AnimatedBuilder(
                                    animation: _rippleController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: _RipplePainter(animation: _rippleController, color: AppTheme.emotionColors[emotionProvider.currentEmotion] ?? Colors.white),
                                        size: Size.infinite,
                                      );
                                    },
                                  ),
                                ],
                              )
                            : _buildCameraPlaceholder(emotionProvider),
                      ),
                    ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut).fadeIn(),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Emotion Detection Card
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                      child: EmotionDetectionCard(
                        emotion: emotionProvider.currentEmotion,
                        confidence: emotionProvider.confidence,
                        isDetecting: emotionProvider.isDetecting,
                        motivationalMessage: emotionProvider.getMotivationalMessage(),
                        onSave: () => _showSaveEmotionDialog(emotionProvider),
                        onToggleDetection: () async {
                          if (emotionProvider.isDetecting) {
                            await emotionProvider.stopEmotionDetection();
                          } else {
                            if (!emotionProvider.isModelLoaded) {
                              await emotionProvider.loadModel();
                            }
                            if (!emotionProvider.isCameraInitialized) {
                              await emotionProvider.initializeCamera(widget.cameras);
                            }
                            if (emotionProvider.isModelLoaded && emotionProvider.isCameraInitialized) {
                              await emotionProvider.startEmotionDetection();
                            }
                          }
                        },
                      ),
                    ).animate().slideY(begin: 0.5, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 400.ms),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.3)],
          stops: const [0.6, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Scanning animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.3 * _pulseController.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, AppTheme.accentColor, Colors.transparent]),
                    boxShadow: [BoxShadow(color: AppTheme.accentColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
                  ),
                ),
              );
            },
          ),

          // Detection corners
          Positioned(top: 40, left: 40, child: _buildCornerIndicator(true, true)),
          Positioned(top: 40, right: 40, child: _buildCornerIndicator(true, false)),
          Positioned(bottom: 40, left: 40, child: _buildCornerIndicator(false, true)),
          Positioned(bottom: 40, right: 40, child: _buildCornerIndicator(false, false)),
        ],
      ),
    );
  }

  Widget _buildCornerIndicator(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppTheme.accentColor, width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder(EmotionProvider emotionProvider) {
    String statusText = 'Initializing...';
    IconData statusIcon = Icons.hourglass_empty;

    if (!emotionProvider.isModelLoaded && !emotionProvider.isCameraInitialized) {
      statusText = 'Loading model and camera...';
      statusIcon = Icons.download;
    } else if (!emotionProvider.isModelLoaded) {
      statusText = 'Loading AI model...';
      statusIcon = Icons.psychology;
    } else if (!emotionProvider.isCameraInitialized) {
      statusText = 'Initializing camera...';
      statusIcon = Icons.camera_alt_outlined;
    } else if (emotionProvider.errorMessage != null) {
      statusText = 'Error occurred';
      statusIcon = Icons.error_outline;
    }

    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, size: 80, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            if (emotionProvider.errorMessage != null) ...[const SizedBox(height: 8), Text('Tap to retry', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14))],
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RipplePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0) return;

    final paint = Paint()
      ..color = color.withOpacity(1.0 - animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * animation.value;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}
