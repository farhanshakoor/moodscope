import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/core/utils/toast_utils.dart';
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

class _EmotionDetectionScreenState extends State<EmotionDetectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _captureController;
  late AnimationController _breathingController;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDetection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _captureController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initializeDetection() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      final emotionProvider = context.read<EmotionProvider>();

      if (!emotionProvider.isModelLoaded) {
        await emotionProvider.loadModel();
      }

      if (!emotionProvider.isCameraInitialized && widget.cameras.isNotEmpty) {
        await emotionProvider.initializeCamera(widget.cameras);
      }
    } catch (e) {
      print('Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _captureController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _showSaveEmotionDialog(EmotionProvider emotionProvider) {
    if (emotionProvider.confidence <= 0) {
      ToastUtils.showSuccessToast(
        message:
            'No emotion detected yet. Try capturing your expression first.',
        context: context,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SaveEmotionDialog(
        emotion: emotionProvider.currentEmotion,
        confidence: emotionProvider.confidence,
        onSave: (note) async {
          try {
            final success = await emotionProvider.saveEmotionEntry(note: note);
            if (success && mounted) {
              ToastUtils.showSuccessToast(
                message:
                    'Emotion saved successfully! ${AppConstants.emotionEmojis[emotionProvider.currentEmotion] ?? ''}',
                context: context,
              );
              _rippleController.forward().then((_) {
                _rippleController.reset();
              });
            } else if (mounted) {
              ToastUtils.showSuccessToast(
                message:
                    emotionProvider.errorMessage ?? 'Failed to save emotion',
                context: context,
              );
            }
          } catch (e) {
            if (mounted) {
              ToastUtils.showSuccessToast(
                message: 'Error saving emotion: $e',
                context: context,
              );
            }
          }
        },
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Connection Issue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(error, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeDetection();
            },
            child: Text(
              'Retry',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Consumer<EmotionProvider>(
            builder: (context, emotionProvider, child) {
              if (emotionProvider.errorMessage != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showErrorDialog(emotionProvider.errorMessage!);
                  emotionProvider.clearError();
                });
              }

              return Column(
                children: [
                  _buildHeader(emotionProvider),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildCameraSection(emotionProvider),
                          ),

                          const SizedBox(height: 16),

                          Expanded(
                            flex: 4,
                            child: _buildEmotionControlsSection(
                              emotionProvider,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EmotionProvider emotionProvider) {
    return Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emotion Detection',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Capture your moment when ready',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  _buildStatusIndicator(
                    emotionProvider.isModelLoaded,
                    Icons.psychology,
                    'AI Model',
                  ),
                  const SizedBox(width: 8),
                  _buildStatusIndicator(
                    emotionProvider.isCameraInitialized,
                    Icons.camera_alt,
                    'Camera',
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn();
  }

  Widget _buildStatusIndicator(bool isActive, IconData icon, String label) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.green : Colors.orange,
        size: 16,
      ),
    );
  }

  Widget _buildCameraSection(EmotionProvider emotionProvider) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                if (emotionProvider.isCameraInitialized &&
                    emotionProvider.cameraController != null)
                  _buildCameraPreview(emotionProvider)
                else
                  _buildCameraPlaceholder(emotionProvider),

                // Enhanced capture overlay
                if (emotionProvider.isCapturing)
                  _buildCaptureOverlay(emotionProvider),

                // Improved detection indicators
                if (emotionProvider.isDetecting && !emotionProvider.isCapturing)
                  _buildDetectionReadyOverlay(emotionProvider),

                // Success ripple effect
                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RipplePainter(
                        animation: _rippleController,
                        color:
                            AppTheme.emotionColors[emotionProvider
                                .currentEmotion] ??
                            Colors.white,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Manual capture button when ready
                if (emotionProvider.isDetecting &&
                    !emotionProvider.isCapturing &&
                    emotionProvider.isCameraInitialized)
                  _buildCaptureButton(emotionProvider),
              ],
            ),
          ),
        )
        .animate()
        .scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut)
        .fadeIn();
  }

  Widget _buildCameraPreview(EmotionProvider emotionProvider) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width:
              emotionProvider.cameraController!.value.previewSize?.height ?? 1,
          height:
              emotionProvider.cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(emotionProvider.cameraController!),
        ),
      ),
    );
  }

  Widget _buildCaptureButton(EmotionProvider emotionProvider) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await emotionProvider.captureEmotion();
            _captureController.forward().then((_) {
              _captureController.reset();
            });
          },
          child: AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              return Container(
                width: 80 + (_breathingController.value * 10),
                height: 80 + (_breathingController.value * 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Color(0xFF1A1A2E),
                  size: 32,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureOverlay(EmotionProvider emotionProvider) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _captureController,
              builder: (context, child) {
                return Container(
                  width: 120 + (_captureController.value * 20),
                  height: 120 + (_captureController.value * 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(
                        0.6 + _captureController.value * 0.4,
                      ),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 40 + (_captureController.value * 8),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              'Analyzing your expression...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionReadyOverlay(EmotionProvider emotionProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.1),
            Colors.black.withOpacity(0.3),
          ],
          stops: [0.7, 0.85, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Corner indicators
          ..._buildCornerIndicators(),

          // Ready status
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        begin: Offset(0.8, 0.8),
                        end: Offset(1.2, 1.2),
                        duration: 1000.ms,
                      ),
                  SizedBox(width: 8),
                  Text(
                    'Ready to capture • Tap camera button',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerIndicators() {
    return [
      Positioned(top: 30, left: 30, child: _buildCornerIndicator(true, true)),
      Positioned(top: 30, right: 30, child: _buildCornerIndicator(true, false)),
      Positioned(
        bottom: 120,
        left: 30,
        child: _buildCornerIndicator(false, true),
      ),
      Positioned(
        bottom: 120,
        right: 30,
        child: _buildCornerIndicator(false, false),
      ),
    ];
  }

  Widget _buildCornerIndicator(bool isTop, bool isLeft) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              top: isTop
                  ? BorderSide(
                      color: Colors.white.withOpacity(
                        0.6 + _pulseController.value * 0.4,
                      ),
                      width: 3,
                    )
                  : BorderSide.none,
              bottom: !isTop
                  ? BorderSide(
                      color: Colors.white.withOpacity(
                        0.6 + _pulseController.value * 0.4,
                      ),
                      width: 3,
                    )
                  : BorderSide.none,
              left: isLeft
                  ? BorderSide(
                      color: Colors.white.withOpacity(
                        0.6 + _pulseController.value * 0.4,
                      ),
                      width: 3,
                    )
                  : BorderSide.none,
              right: !isLeft
                  ? BorderSide(
                      color: Colors.white.withOpacity(
                        0.6 + _pulseController.value * 0.4,
                      ),
                      width: 3,
                    )
                  : BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmotionControlsSection(EmotionProvider emotionProvider) {
    return EmotionDetectionCard(
          emotion: emotionProvider.currentEmotion,
          confidence: emotionProvider.confidence,
          isDetecting: emotionProvider.isDetecting,
          motivationalMessage: emotionProvider.getMotivationalMessage(),
          onSave: () => _showSaveEmotionDialog(emotionProvider),
          onToggleDetection: () => _handleToggleDetection(emotionProvider),
          isCapturing: emotionProvider.isCapturing,
          onManualCapture: () async {
            await emotionProvider.captureEmotion();
            _captureController.forward().then((_) {
              _captureController.reset();
            });
          },
        )
        .animate()
        .slideY(
          begin: 0.5,
          delay: 400.ms,
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(delay: 400.ms);
  }

  Future<void> _handleToggleDetection(EmotionProvider emotionProvider) async {
    try {
      if (emotionProvider.isDetecting) {
        await emotionProvider.stopEmotionDetection();
      } else {
        if (!emotionProvider.isModelLoaded) {
          await emotionProvider.loadModel();
        }
        if (!emotionProvider.isCameraInitialized) {
          await emotionProvider.initializeCamera(widget.cameras);
        }
        if (emotionProvider.isModelLoaded &&
            emotionProvider.isCameraInitialized) {
          await emotionProvider.startEmotionDetection();
        }
      }
    } catch (e) {
      print('Error toggling detection: $e');
      if (mounted) {
        ToastUtils.showSuccessToast(
          message: 'Error: ${e.toString()}',
          context: context,
        );
      }
    }
  }

  Widget _buildCameraPlaceholder(EmotionProvider emotionProvider) {
    String statusText = 'Initializing system...';
    IconData statusIcon = Icons.psychology;
    Color statusColor = Colors.white54;

    if (_isInitializing) {
      statusText = 'Loading emotion detection model...';
      statusIcon = Icons.download;
      statusColor = Colors.blue;
    } else if (!emotionProvider.isModelLoaded &&
        !emotionProvider.isCameraInitialized) {
      statusText = 'Loading AI model and camera...';
      statusIcon = Icons.build;
      statusColor = Colors.orange;
    } else if (!emotionProvider.isModelLoaded) {
      statusText = 'Loading emotion recognition model...';
      statusIcon = Icons.psychology;
      statusColor = Colors.purple;
    } else if (!emotionProvider.isCameraInitialized) {
      statusText = 'Starting camera...';
      statusIcon = Icons.camera_alt_outlined;
      statusColor = Colors.green;
    } else if (emotionProvider.errorMessage != null) {
      statusText = 'Connection error occurred';
      statusIcon = Icons.error_outline;
      statusColor = Colors.red;
    }

    return Container(
      color: Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                return Container(
                  width: 100 + (_breathingController.value * 20),
                  height: 100 + (_breathingController.value * 20),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withOpacity(
                        0.5 + _breathingController.value * 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                  child: Icon(statusIcon, size: 40, color: statusColor),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              statusText,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            if (_isInitializing) ...[
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              _isInitializing
                  ? 'Setting up your emotion detection system...'
                  : emotionProvider.errorMessage != null
                  ? 'Tap retry to try again'
                  : 'Almost ready to start detecting emotions',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            if (emotionProvider.errorMessage != null && !_isInitializing) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initializeDetection,
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
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
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * animation.value;

    canvas.drawCircle(center, radius, paint);

    final innerPaint = Paint()
      ..color = color.withOpacity((1.0 - animation.value) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius * 0.7, innerPaint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}
