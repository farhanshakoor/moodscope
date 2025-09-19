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
import 'dart:async';

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
  bool _isProcessing = false;

  // Enhanced flow control
  bool _isCapturing = false;
  Timer? _detectionTimer;
  Timer? _stabilizationTimer;
  DateTime _lastDetectionTime = DateTime.now();
  DateTime _lastEmotionChangeTime = DateTime.now();

  // Debug mode
  bool _debugMode = true;

  // Adjusted parameters for better detection
  static const int detectionIntervalMs = 3000; // Even slower for testing
  static const int stabilizationDelayMs = 2000;
  static const double confidenceThreshold = 10.0; // Lower threshold for testing
  static const double minimumConfidence = 15.0; // Lower minimum for debugging
  static const int maxConsecutiveProcessing = 3;

  // Emotion history for smoothing
  List<DetectionResult> _recentDetections = [];
  static const int maxHistoryLength = 3; // Reduced for faster response

  // Model specifications - might need adjustment for your specific model
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
  bool get isCapturing => _isCapturing;

  // Initialize camera with better settings
  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    try {
      if (cameras.isEmpty) {
        _setError('No cameras available');
        return;
      }

      final CameraDescription camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (_cameraController!.value.isInitialized) {
        _isCameraInitialized = true;
        notifyListeners();
        if (_debugMode) print('Camera initialized successfully');
      }
    } catch (e) {
      if (_debugMode) print('Camera initialization error: $e');
      _setError('Failed to initialize camera: $e');
    }
  }

  // Load your model with better debugging
  Future<void> loadModel() async {
    try {
      if (_debugMode) print('Loading emotion_model.tflite...');

      _interpreter = await Interpreter.fromAsset('assets/emotion_model.tflite');
      _interpreter!.allocateTensors();

      // Debug model input/output shapes
      var inputTensors = _interpreter!.getInputTensors();
      var outputTensors = _interpreter!.getOutputTensors();

      if (_debugMode) {
        print('Input tensor shape: ${inputTensors.first.shape}');
        print('Output tensor shape: ${outputTensors.first.shape}');
        print('Input tensor type: ${inputTensors.first.type}');
        print('Output tensor type: ${outputTensors.first.type}');
      }

      // Load labels
      final labelsData = await rootBundle.loadString(
        'assets/emotion_labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .where((line) => line.isNotEmpty)
          .map((line) => _cleanEmotionLabel(line))
          .toList();

      _isModelLoaded = true;
      notifyListeners();

      if (_debugMode) {
        print('Model loaded successfully!');
        print('Labels: $_labels');
        print('Number of labels: ${_labels.length}');
      }
    } catch (e) {
      if (_debugMode) print('Model loading error: $e');
      _setError('Failed to load emotion detection model: $e');
    }
  }

  // Debug method to check model predictions
  Future<void> _debugModelPrediction(List<double> rawOutput) async {
    if (!_debugMode) return;

    print('\n=== DEBUG MODEL PREDICTION ===');
    print('Raw model output: $rawOutput');

    for (int i = 0; i < rawOutput.length && i < _labels.length; i++) {
      print('${_labels[i]}: ${(rawOutput[i] * 100).toStringAsFixed(2)}%');
    }

    var maxIndex = 0;
    var maxValue = rawOutput[0];
    for (int i = 1; i < rawOutput.length; i++) {
      if (rawOutput[i] > maxValue) {
        maxValue = rawOutput[i];
        maxIndex = i;
      }
    }

    print(
      'Predicted: ${_labels[maxIndex]} with confidence: ${(maxValue * 100).toStringAsFixed(2)}%',
    );
    print('===============================\n');
  }

  // Improved detection start
  Future<void> startEmotionDetection() async {
    if (!_isCameraInitialized || !_isModelLoaded || _isDetecting) return;

    try {
      _isDetecting = true;
      _isProcessing = false;
      _isCapturing = false;
      _recentDetections.clear();
      notifyListeners();

      if (_debugMode) print('Started emotion detection');

      // Start with immediate capture for testing
      _captureAndProcess();

      _detectionTimer = Timer.periodic(
        Duration(milliseconds: detectionIntervalMs),
        (timer) {
          if (_isDetecting && !_isProcessing) {
            if (_debugMode) print('Auto-capture triggered');
            _captureAndProcess();
          }
        },
      );
    } catch (e) {
      if (_debugMode) print('Start detection error: $e');
      _setError('Failed to start emotion detection: $e');
      _isDetecting = false;
      notifyListeners();
    }
  }

  // Manual capture for testing
  Future<void> captureEmotion() async {
    if (!_isDetecting || _isProcessing || _isCapturing) return;

    if (_debugMode) print('Manual capture initiated');
    await _captureAndProcess();
  }

  // Stop detection
  Future<void> stopEmotionDetection() async {
    if (!_isDetecting) return;

    try {
      _isDetecting = false;
      _isProcessing = false;
      _isCapturing = false;
      _detectionTimer?.cancel();
      _stabilizationTimer?.cancel();
      _detectionTimer = null;
      _stabilizationTimer = null;
      _recentDetections.clear();
      notifyListeners();

      if (_debugMode) print('Stopped emotion detection');
    } catch (e) {
      if (_debugMode) print('Stop detection error: $e');
    }
  }

  // Enhanced capture and process
  Future<void> _captureAndProcess() async {
    if (_isProcessing ||
        _isCapturing ||
        !_isDetecting ||
        _cameraController == null) {
      if (_debugMode)
        print(
          'Capture skipped: processing=$_isProcessing, capturing=$_isCapturing, detecting=$_isDetecting',
        );
      return;
    }

    try {
      _isCapturing = true;
      _isProcessing = true;
      notifyListeners();

      if (_debugMode) print('Capturing image...');

      // Capture with better error handling
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      if (_debugMode) print('Image captured, size: ${imageBytes.length} bytes');

      await _processImageWithDebugging(imageBytes);
    } catch (e) {
      if (_debugMode) print('Capture error: $e');
      _setError('Error capturing image: $e');
    } finally {
      _isProcessing = false;
      _isCapturing = false;
      notifyListeners();
    }
  }

  // Process image with extensive debugging
  Future<void> _processImageWithDebugging(Uint8List imageBytes) async {
    try {
      if (_debugMode) print('Processing image...');

      // Decode image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        if (_debugMode) print('Failed to decode image');
        return;
      }

      if (_debugMode)
        print(
          'Original image size: ${originalImage.width}x${originalImage.height}',
        );

      // Resize image
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );

      if (_debugMode) {
        print('Resized to: ${resizedImage.width}x${resizedImage.height}');
      }

      // Convert to model input
      Float32List inputBuffer = _convertImageToInputWithDebug(resizedImage);

      if (_interpreter != null && inputBuffer.isNotEmpty) {
        if (_debugMode) print('Running inference...');

        var input = inputBuffer.reshape([1, inputSize, inputSize, numChannels]);
        var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

        _interpreter!.run(input, output);

        if (_debugMode) print('Inference completed');

        // Debug the raw output
        await _debugModelPrediction(output[0]);

        _processInferenceResultsWithDebug(output[0]);
      }
    } catch (e) {
      if (_debugMode) print('Processing error: $e');
      _setError('Error processing image: $e');
    }
  }

  // Enhanced image conversion with debugging
  Float32List _convertImageToInputWithDebug(img.Image image) {
    try {
      Float32List inputBuffer = Float32List(
        inputSize * inputSize * numChannels,
      );
      int pixelIndex = 0;

      // Try different normalization approaches
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          img.Pixel pixel = image.getPixel(x, y);

          // Method 1: [0,1] normalization (try this first)
          inputBuffer[pixelIndex++] = pixel.r.toDouble() / 255.0;
          inputBuffer[pixelIndex++] = pixel.g.toDouble() / 255.0;
          inputBuffer[pixelIndex++] = pixel.b.toDouble() / 255.0;

          // Method 2: [-1,1] normalization (uncomment if method 1 doesn't work)
          // inputBuffer[pixelIndex++] = (pixel.r.toDouble() / 255.0) * 2.0 - 1.0;
          // inputBuffer[pixelIndex++] = (pixel.g.toDouble() / 255.0) * 2.0 - 1.0;
          // inputBuffer[pixelIndex++] = (pixel.b.toDouble() / 255.0) * 2.0 - 1.0;
        }
      }

      if (_debugMode) {
        print('Input buffer size: ${inputBuffer.length}');
        print('First few values: ${inputBuffer.take(6).toList()}');
        print(
          'Value range: min=${inputBuffer.reduce(min)}, max=${inputBuffer.reduce(max)}',
        );
      }

      return inputBuffer;
    } catch (e) {
      if (_debugMode) print('Image conversion error: $e');
      return Float32List(0);
    }
  }

  // Process results with detailed debugging
  void _processInferenceResultsWithDebug(List<double> probabilities) {
    try {
      if (_debugMode) {
        print('Processing inference results...');
        print('Probabilities length: ${probabilities.length}');
        print('Labels length: ${_labels.length}');
      }

      double maxConfidence = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        if (probabilities[i] > maxConfidence) {
          maxConfidence = probabilities[i];
          maxIndex = i;
        }
      }

      if (maxIndex >= _labels.length) {
        if (_debugMode)
          print('Invalid max index: $maxIndex >= ${_labels.length}');
        return;
      }

      final emotion = _labels[maxIndex];
      final confidence = maxConfidence * 100;

      if (_debugMode) {
        print(
          'Detected: $emotion with ${confidence.toStringAsFixed(2)}% confidence',
        );
        print('Minimum confidence threshold: $minimumConfidence');
      }

      // For debugging, accept even low confidence detections temporarily
      if (confidence < 5.0) {
        if (_debugMode) print('Very low confidence detection - ignored');
        return;
      }

      // Add to history
      _recentDetections.add(
        DetectionResult(
          emotion: emotion,
          confidence: confidence,
          timestamp: DateTime.now(),
        ),
      );

      if (_recentDetections.length > maxHistoryLength) {
        _recentDetections.removeAt(0);
      }

      // For debugging, use simpler logic
      _updateEmotionStateDebug(emotion, confidence);
    } catch (e) {
      if (_debugMode) print('Results processing error: $e');
    }
  }

  // Simplified emotion update for debugging
  void _updateEmotionStateDebug(String newEmotion, double newConfidence) {
    if (_debugMode) {
      print(
        'Updating emotion state: $newEmotion (${newConfidence.toStringAsFixed(1)}%)',
      );
      print('Current emotion: $_currentEmotion');
      print('Current confidence: ${_confidence.toStringAsFixed(1)}%');
    }

    // For debugging, be more permissive with updates
    bool shouldUpdate = false;

    if (newEmotion != _currentEmotion) {
      if (newConfidence > 10.0) {
        // Very low threshold for debugging
        shouldUpdate = true;
      }
    } else {
      if (newConfidence > _confidence + 5.0) {
        shouldUpdate = true;
      }
    }

    if (shouldUpdate) {
      _currentEmotion = newEmotion;
      _confidence = newConfidence;
      _lastDetectionTime = DateTime.now();

      if (_debugMode) {
        print(
          '✓ Emotion updated to: $newEmotion (${newConfidence.toStringAsFixed(1)}%)',
        );
      }

      notifyListeners();
    } else {
      if (_debugMode)
        print('✗ Update rejected - not enough confidence or change');
    }
  }

  // Enhanced emotion saving
  Future<bool> saveEmotionEntry({String? note}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        return false;
      }

      if (_currentEmotion.isEmpty) {
        _setError('No emotion detected');
        return false;
      }

      final entry = EmotionEntry(
        id: _uuid.v4(),
        userId: user.uid,
        emotion: _currentEmotion,
        confidence: _confidence,
        timestamp: DateTime.now(),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
      );

      final batch = _firestore.batch();
      final docRef = _firestore
          .collection(AppConstants.emotionEntriesCollection)
          .doc(entry.id);

      batch.set(docRef, entry.toMap());
      await batch.commit();

      if (_debugMode) print('Emotion entry saved: $entry');
      return true;
    } catch (e) {
      if (_debugMode) print('Save error: $e');
      _setError('Failed to save emotion entry: ${e.toString()}');
      return false;
    }
  }

  Stream<List<EmotionEntry>> getEmotionEntriesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.emotionEntriesCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EmotionEntry.fromMap(doc.data()))
              .toList(),
        );
  }

  // Improved label cleaning
  String _cleanEmotionLabel(String label) {
    // Remove number prefix and clean
    String cleaned = label
        .replaceAll(RegExp(r'^\d+\s*'), '')
        .toLowerCase()
        .trim();

    if (_debugMode) print('Cleaned label: "$label" -> "$cleaned"');

    // Map your specific labels
    switch (cleaned) {
      case 'angry':
        return 'angry';
      case 'disgust':
        return 'disgust';
      case 'fear':
        return 'fear';
      case 'happy':
        return 'happy';
      case 'neutral':
        return 'neutral';
      case 'sad':
        return 'sad';
      case 'surprise':
      case 'surprised':
        return 'surprised';
      default:
        return cleaned;
    }
  }

  // Toggle debug mode
  void toggleDebugMode() {
    _debugMode = !_debugMode;
    notifyListeners();
    print('Debug mode: ${_debugMode ? "ON" : "OFF"}');
  }

  // Get motivational message
  String getMotivationalMessage() {
    final messages =
        AppConstants.emotionMessages[_currentEmotion] ??
        AppConstants.emotionMessages['neutral'] ??
        ['Keep going! You\'re doing great!'];

    final randomIndex = Random().nextInt(messages.length);
    return messages[randomIndex];
  }

  // Set error with automatic clear
  void _setError(String error) {
    _errorMessage = error;
    if (_debugMode) print('Error set: $error');
    notifyListeners();

    Timer(Duration(seconds: 5), () {
      if (_errorMessage == error) {
        clearError();
      }
    });
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _stabilizationTimer?.cancel();
    stopEmotionDetection();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }
}

// Helper class for detection results
class DetectionResult {
  final String emotion;
  final double confidence;
  final DateTime timestamp;

  DetectionResult({
    required this.emotion,
    required this.confidence,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'DetectionResult(emotion: $emotion, confidence: ${confidence.toStringAsFixed(1)}%, time: $timestamp)';
  }
}
