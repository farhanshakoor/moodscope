import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/core/utils/toast_utils.dart';
import 'package:moodscope/features/emotion_detection/widgets/emotion_detection_card.dart';
import 'package:moodscope/features/emotion_detection/widgets/save_emotion_dialog.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/enhanced_emotion_provider.dart';

class ImageCaptureEmotionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ImageCaptureEmotionScreen({super.key, required this.cameras});

  @override
  State<ImageCaptureEmotionScreen> createState() => _ImageCaptureEmotionScreenState();
}

class _ImageCaptureEmotionScreenState extends State<ImageCaptureEmotionScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _captureController;
  late AnimationController _successController;
  bool _isInitializing = false;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDetection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();

    _captureController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _successController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
  }

  void _initializeDetection() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      final emotionProvider = context.read<EnhancedEmotionProvider>();

      if (!emotionProvider.isModelLoaded) {
        await emotionProvider.loadModel();
      }

      if (!emotionProvider.isCameraInitialized && widget.cameras.isNotEmpty) {
        await emotionProvider.initializeCamera(widget.cameras);
      }

      // Hide instructions after successful initialization
      if (emotionProvider.isModelLoaded && emotionProvider.isCameraInitialized) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showInstructions = false;
            });
          }
        });
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
    _captureController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _showSaveEmotionDialog(EnhancedEmotionProvider emotionProvider) {
    if (emotionProvider.confidence <= 0) {
      ToastUtils.showSuccessToast(message: 'No emotion detected yet. Try capturing your expression first.', context: context);
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
              ToastUtils.showSuccessToast(message: 'Emotion saved successfully! ${AppConstants.emotionEmojis[emotionProvider.currentEmotion] ?? ''}', context: context);
              _successController.forward().then((_) {
                _successController.reset();
              });
            } else if (mounted) {
              ToastUtils.showSuccessToast(message: emotionProvider.errorMessage ?? 'Failed to save emotion', context: context);
            }
          } catch (e) {
            if (mounted) {
              ToastUtils.showSuccessToast(message: 'Error saving emotion: $e', context: context);
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
          'System Error',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(error, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeDetection();
            },
            child: Text('Retry', style: TextStyle(color: AppTheme.primaryColor)),
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
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)]),
        ),
        child: SafeArea(
          child: Consumer<EnhancedEmotionProvider>(
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

                  if (_showInstructions) _buildInstructionsCard(),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Expanded(flex: 6, child: _buildCameraSection(emotionProvider)),

                          const SizedBox(height: 20),

                          Expanded(flex: 4, child: _buildEmotionControlsSection(emotionProvider)),
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

  Widget _buildHeader(EnhancedEmotionProvider emotionProvider) {
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
              icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emotion Capture',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text('Capture a photo to analyze your emotion', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),

          Row(
            children: [
              _buildStatusIndicator(emotionProvider.isModelLoaded, Icons.psychology, 'AI Model'),
              const SizedBox(width: 8),
              _buildStatusIndicator(emotionProvider.isCameraInitialized, Icons.camera_alt, 'Camera'),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildInstructionsCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.info_outline, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text('Position your face in the camera frame and tap the capture button to analyze your current emotion', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showInstructions = false;
              });
            },
            icon: Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 300.ms);
  }

  Widget _buildStatusIndicator(bool isActive, IconData icon, String label) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? Colors.green : Colors.orange, width: 1),
      ),
      child: Icon(icon, color: isActive ? Colors.green : Colors.orange, size: 16),
    );
  }

  Widget _buildCameraSection(EnhancedEmotionProvider emotionProvider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (emotionProvider.isCameraInitialized && emotionProvider.cameraController != null) _buildCameraPreview(emotionProvider) else _buildCameraPlaceholder(emotionProvider),

            // Capture overlay
            if (emotionProvider.isCapturing || emotionProvider.isProcessing) _buildCaptureOverlay(emotionProvider),

            // Capture guidelines overlay
            if (emotionProvider.isCameraInitialized && !emotionProvider.isCapturing && !emotionProvider.isProcessing) _buildCaptureGuidelinesOverlay(),

            // Success animation
            AnimatedBuilder(
              animation: _successController,
              builder: (context, child) {
                return _successController.value > 0
                    ? Container(
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.3 * (1 - _successController.value))),
                        child: Center(
                          child: Transform.scale(
                            scale: 1 + (_successController.value * 0.3),
                            child: Icon(Icons.check_circle, color: Colors.green, size: 80),
                          ),
                        ),
                      )
                    : SizedBox.shrink();
              },
            ),

            // Capture button
            if (emotionProvider.isCameraInitialized && !emotionProvider.isCapturing && !emotionProvider.isProcessing) _buildCaptureButton(emotionProvider),
          ],
        ),
      ),
    ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut).fadeIn();
  }

  Widget _buildCameraPreview(EnhancedEmotionProvider emotionProvider) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: emotionProvider.cameraController!.value.previewSize?.height ?? 1,
          height: emotionProvider.cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(emotionProvider.cameraController!),
        ),
      ),
    );
  }

  Widget _buildCaptureGuidelinesOverlay() {
    return Container(
      child: Stack(
        children: [
          // Face frame guidelines
          Center(
            child: Container(
              width: 250,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                borderRadius: BorderRadius.circular(150),
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3 + (_pulseController.value * 0.4)), width: 1),
                      borderRadius: BorderRadius.circular(130),
                    ),
                  );
                },
              ),
            ),
          ),

          // Guidelines text
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'Position your face within the oval and tap capture',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(EnhancedEmotionProvider emotionProvider) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () async {
            _captureController.forward();
            await emotionProvider.captureAndAnalyzeEmotion();
            _captureController.reset();

            if (emotionProvider.confidence > 0) {
              _successController.forward().then((_) {
                _successController.reset();
              });
            }
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3 + (_pulseController.value * 0.3)),
                      blurRadius: 15 + (_pulseController.value * 10),
                      spreadRadius: 2 + (_pulseController.value * 3),
                    ),
                  ],
                ),
                child: Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 32),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureOverlay(EnhancedEmotionProvider emotionProvider) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _captureController,
              builder: (context, child) {
                return Container(
                  width: 120 + (_captureController.value * 40),
                  height: 120 + (_captureController.value * 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5 + (_captureController.value * 0.5)), width: 3),
                  ),
                  child: Icon(emotionProvider.isCapturing ? Icons.camera_alt : Icons.psychology, color: Colors.white, size: 40 + (_captureController.value * 20)),
                );
              },
            ),

            const SizedBox(height: 30),

            Text(
              emotionProvider.isCapturing ? 'Capturing image...' : 'Analyzing emotion...',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: 200,
              child: LinearProgressIndicator(backgroundColor: Colors.white.withOpacity(0.3), valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
            ),

            const SizedBox(height: 20),

            Text(emotionProvider.isCapturing ? 'Please hold still...' : 'Processing facial expression...', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionControlsSection(EnhancedEmotionProvider emotionProvider) {
    return EmotionDetectionCard(
      emotion: emotionProvider.currentEmotion,
      confidence: emotionProvider.confidence,
      isDetecting: false, // Not using continuous detection
      motivationalMessage: emotionProvider.getMotivationalMessage(),
      onSave: () => _showSaveEmotionDialog(emotionProvider),
      onToggleDetection: () {}, // Disable toggle for image capture mode
      isCapturing: emotionProvider.isCapturing || emotionProvider.isProcessing,
      onManualCapture: () async {
        _captureController.forward();
        await emotionProvider.captureAndAnalyzeEmotion();
        _captureController.reset();

        if (emotionProvider.confidence > 0) {
          _successController.forward().then((_) {
            _successController.reset();
          });
        }
      },
    ).animate().slideY(begin: 0.5, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 400.ms);
  }

  Widget _buildCameraPlaceholder(EnhancedEmotionProvider emotionProvider) {
    String statusText = 'Initializing system...';
    IconData statusIcon = Icons.psychology;
    Color statusColor = Colors.white54;

    if (_isInitializing) {
      statusText = 'Loading emotion detection model...';
      statusIcon = Icons.download;
      statusColor = Colors.blue;
    } else if (!emotionProvider.isModelLoaded && !emotionProvider.isCameraInitialized) {
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
      statusText = 'System error occurred';
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
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 100 + (_pulseController.value * 20),
                  height: 100 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withOpacity(0.5 + _pulseController.value * 0.5), width: 2),
                  ),
                  child: Icon(statusIcon, size: 40, color: statusColor),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              statusText,
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            if (_isInitializing) ...[
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(backgroundColor: Colors.white.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(statusColor)),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              _isInitializing
                  ? 'Setting up your emotion detection system...'
                  : emotionProvider.errorMessage != null
                  ? 'Tap retry to try again'
                  : 'Ready to capture and analyze emotions',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
