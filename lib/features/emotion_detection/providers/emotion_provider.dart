import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:moodscope/features/emotion_detection/models/emotion_entry.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:math';

import '../../../core/constants/app_constants.dart';

class EmotionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  CameraController? _cameraController;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isCameraInitialized = false;
  bool _isModelLoaded = false;
  bool _isDetecting = false;
  String _currentEmotion = 'neutral';
  double _confidence = 0.0;
  String? _errorMessage;

  // Model input/output specifications
  static const int inputSize = 224;
  static const int numChannels = 3;

  // Getters
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isModelLoaded => _isModelLoaded;
  bool get isDetecting => _isDetecting;
  String get currentEmotion => _currentEmotion;
  double get confidence => _confidence;
  String? get errorMessage => _errorMessage;

  // Initialize camera
  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    try {
      if (cameras.isEmpty) {
        _setError('No cameras available');
        return;
      }

      // Use front camera
      final CameraDescription camera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

      _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);

      await _cameraController!.initialize();

      if (_cameraController!.value.isInitialized) {
        _isCameraInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to initialize camera: $e');
    }
  }

  // Load TensorFlow Lite model
  Future<void> loadModel() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((line) => line.isNotEmpty).toList();

      _isModelLoaded = true;
      notifyListeners();

      print('Model loaded successfully with ${_labels.length} labels');
    } catch (e) {
      _setError('Failed to load emotion detection model: $e');
    }
  }

  // Start emotion detection
  Future<void> startEmotionDetection() async {
    if (!_isCameraInitialized || !_isModelLoaded || _isDetecting) return;

    try {
      _isDetecting = true;
      notifyListeners();

      await _cameraController!.startImageStream((CameraImage image) {
        if (!_isDetecting) return;
        _runEmotionDetection(image);
      });
    } catch (e) {
      _setError('Failed to start emotion detection: $e');
      _isDetecting = false;
      notifyListeners();
    }
  }

  // Stop emotion detection
  Future<void> stopEmotionDetection() async {
    if (!_isDetecting) return;

    try {
      _isDetecting = false;
      await _cameraController?.stopImageStream();
      notifyListeners();
    } catch (e) {
      print('Error stopping emotion detection: $e');
    }
  }

  // Convert CameraImage to input tensor
  Float32List _preprocessImage(CameraImage image) {
    try {
      // Convert YUV420 to RGB
      img.Image? rgbImage = _convertYUV420ToImage(image);
      if (rgbImage == null) return Float32List(0);

      // Resize image to model input size
      img.Image resizedImage = img.copyResize(rgbImage, width: inputSize, height: inputSize);

      // Convert to Float32List and normalize
      Float32List inputBuffer = Float32List(1 * inputSize * inputSize * numChannels);

      int pixelIndex = 0;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          img.Pixel pixel = resizedImage.getPixel(x, y);

          // Normalize pixel values to [0, 1]
          inputBuffer[pixelIndex++] = pixel.r.toDouble() / 255.0;
          inputBuffer[pixelIndex++] = pixel.g.toDouble() / 255.0;
          inputBuffer[pixelIndex++] = pixel.b.toDouble() / 255.0;
        }
      }

      return inputBuffer;
    } catch (e) {
      print('Error preprocessing image: $e');
      return Float32List(0);
    }
  }

  // Convert YUV420 CameraImage to RGB Image
  img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      // Get planes
      final Uint8List yPlane = cameraImage.planes[0].bytes;
      final Uint8List uPlane = cameraImage.planes[1].bytes;
      final Uint8List vPlane = cameraImage.planes[2].bytes;

      // Get strides
      final int yStride = cameraImage.planes[0].bytesPerRow;
      final int uvStride = cameraImage.planes[1].bytesPerRow;
      final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

      // Create image
      final img.Image image = img.Image(width: width, height: height);

      // Convert YUV to RGB
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Get Y value
          final int yIndex = y * yStride + x;
          final int yValue = yPlane[yIndex];

          // Get UV values (subsampled by 2)
          final int uvX = x ~/ 2;
          final int uvY = y ~/ 2;
          final int uvIndex = uvY * uvStride + uvX * uvPixelStride;

          if (uvIndex >= uPlane.length || uvIndex >= vPlane.length) {
            continue;
          }

          final int uValue = uPlane[uvIndex];
          final int vValue = vPlane[uvIndex];

          // YUV to RGB conversion
          int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
          int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return image;
    } catch (e) {
      print('Error converting YUV420 to Image: $e');
      return null;
    }
  }

  // Run emotion detection on camera image
  Future<void> _runEmotionDetection(CameraImage image) async {
    if (!_isModelLoaded || _interpreter == null) return;

    try {
      // Preprocess image
      Float32List inputBuffer = _preprocessImage(image);
      if (inputBuffer.isEmpty) return;

      // Prepare input and output tensors
      var input = inputBuffer.reshape([1, inputSize, inputSize, numChannels]);
      var output = List.filled(1, List.filled(_labels.length, 0.0));

      // Run inference
      _interpreter!.run(input, output);

      // Process results
      List<double> probabilities = output[0].cast<double>();

      // Find the emotion with highest confidence
      double maxConfidence = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxConfidence) {
          maxConfidence = probabilities[i];
          maxIndex = i;
        }
      }

      if (maxIndex < _labels.length) {
        final emotion = _labels[maxIndex];
        final confidence = maxConfidence * 100;

        // Clean emotion label
        final cleanEmotion = _cleanEmotionLabel(emotion);

        if (cleanEmotion != _currentEmotion || (confidence - _confidence).abs() > 5) {
          _currentEmotion = cleanEmotion;
          _confidence = confidence;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error running emotion detection: $e');
    }
  }

  // Clean emotion label
  String _cleanEmotionLabel(String label) {
    return label.replaceAll(RegExp(r'^\d+\s*'), '').toLowerCase().trim();
  }

  // Save emotion entry to Firestore
  Future<bool> saveEmotionEntry({String? note}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final entry = EmotionEntry(id: _uuid.v4(), userId: user.uid, emotion: _currentEmotion, confidence: _confidence, timestamp: DateTime.now(), note: note);

      await _firestore.collection(AppConstants.emotionEntriesCollection).doc(entry.id).set(entry.toMap());

      return true;
    } catch (e) {
      _setError('Failed to save emotion entry: $e');
      return false;
    }
  }

  // Get motivational message based on current emotion
  String getMotivationalMessage() {
    final messages = AppConstants.emotionMessages[_currentEmotion] ?? AppConstants.emotionMessages['neutral']!;
    final randomIndex = Random().nextInt(messages.length);
    return messages[randomIndex];
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopEmotionDetection();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }
}
