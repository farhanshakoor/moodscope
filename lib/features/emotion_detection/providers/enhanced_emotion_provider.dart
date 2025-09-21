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

class EnhancedEmotionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  CameraController? _cameraController;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isCameraInitialized = false;
  bool _isModelLoaded = false;
  String _currentEmotion = 'neutral';
  double _confidence = 0.0;
  String? _errorMessage;
  bool _isProcessing = false;
  bool _isCapturing = false;

  // Last detected emotion for music recommendations
  String _lastDetectedEmotion = 'neutral';
  DateTime _lastEmotionTime = DateTime.now();

  // Model specifications
  static const int inputSize = 224;
  static const int numChannels = 3;
  static const double confidenceThreshold = 15.0;

  // Getters
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isModelLoaded => _isModelLoaded;
  String get currentEmotion => _currentEmotion;
  double get confidence => _confidence;
  String? get errorMessage => _errorMessage;
  bool get isCapturing => _isCapturing;
  bool get isProcessing => _isProcessing;
  String get lastDetectedEmotion => _lastDetectedEmotion;
  DateTime get lastEmotionTime => _lastEmotionTime;

  // Initialize camera
  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    try {
      if (cameras.isEmpty) {
        _setError('No cameras available');
        return;
      }

      final CameraDescription camera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

      _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);

      await _cameraController!.initialize();

      if (_cameraController!.value.isInitialized) {
        _isCameraInitialized = true;
        notifyListeners();
        print('Camera initialized successfully');
      }
    } catch (e) {
      print('Camera initialization error: $e');
      _setError('Failed to initialize camera: $e');
    }
  }

  // Load emotion detection model
  Future<void> loadModel() async {
    try {
      print('Loading emotion_model.tflite...');

      _interpreter = await Interpreter.fromAsset('assets/emotion_model.tflite');
      _interpreter!.allocateTensors();

      // Load labels
      final labelsData = await rootBundle.loadString('assets/emotion_labels.txt');
      _labels = labelsData.split('\n').where((line) => line.isNotEmpty).map((line) => _cleanEmotionLabel(line)).toList();

      _isModelLoaded = true;
      notifyListeners();

      print('Model loaded successfully with ${_labels.length} labels');
    } catch (e) {
      print('Model loading error: $e');
      _setError('Failed to load emotion detection model: $e');
    }
  }

  // Capture and analyze single image
  Future<void> captureAndAnalyzeEmotion() async {
    if (_isProcessing || _isCapturing || !_isCameraInitialized || !_isModelLoaded) {
      print('Cannot capture: processing=$_isProcessing, capturing=$_isCapturing, camera=$_isCameraInitialized, model=$_isModelLoaded');
      return;
    }

    try {
      _isCapturing = true;
      _isProcessing = true;
      notifyListeners();

      print('Starting emotion capture and analysis...');

      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      print('Image captured, analyzing emotion...');

      // Process the image
      await _processImage(imageBytes);

      print('Emotion analysis completed');
    } catch (e) {
      print('Capture error: $e');
      _setError('Error capturing and analyzing emotion: $e');
    } finally {
      _isProcessing = false;
      _isCapturing = false;
      notifyListeners();
    }
  }

  // Process captured image
  Future<void> _processImage(Uint8List imageBytes) async {
    try {
      // Decode image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to model input size
      img.Image resizedImage = img.copyResize(originalImage, width: inputSize, height: inputSize, interpolation: img.Interpolation.linear);

      // Convert to model input format
      Float32List inputBuffer = _convertImageToInput(resizedImage);

      if (_interpreter != null && inputBuffer.isNotEmpty) {
        // Run inference
        var input = inputBuffer.reshape([1, inputSize, inputSize, numChannels]);
        var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

        _interpreter!.run(input, output);

        // Process results
        _processInferenceResults(output[0]);
      }
    } catch (e) {
      print('Image processing error: $e');
      throw Exception('Error processing image: $e');
    }
  }

  // Convert image to model input
  Float32List _convertImageToInput(img.Image image) {
    Float32List inputBuffer = Float32List(inputSize * inputSize * numChannels);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        img.Pixel pixel = image.getPixel(x, y);

        // Normalize to [0, 1]
        inputBuffer[pixelIndex++] = pixel.r.toDouble() / 255.0;
        inputBuffer[pixelIndex++] = pixel.g.toDouble() / 255.0;
        inputBuffer[pixelIndex++] = pixel.b.toDouble() / 255.0;
      }
    }

    return inputBuffer;
  }

  // Process inference results
  void _processInferenceResults(List<double> probabilities) {
    try {
      double maxConfidence = 0.0;
      int maxIndex = 0;

      // Find emotion with highest confidence
      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        if (probabilities[i] > maxConfidence) {
          maxConfidence = probabilities[i];
          maxIndex = i;
        }
      }

      if (maxIndex >= _labels.length) return;

      final emotion = _labels[maxIndex];
      final confidence = maxConfidence * 100;

      print('Detected emotion: $emotion with ${confidence.toStringAsFixed(1)}% confidence');

      // Update emotion state if confidence is high enough
      if (confidence >= confidenceThreshold) {
        _currentEmotion = emotion;
        _confidence = confidence;
        _lastDetectedEmotion = emotion;
        _lastEmotionTime = DateTime.now();

        print('Emotion updated: $emotion (${confidence.toStringAsFixed(1)}%)');
        notifyListeners();
      } else {
        print('Low confidence detection ignored');
      }
    } catch (e) {
      print('Results processing error: $e');
    }
  }

  // Clean emotion labels
  String _cleanEmotionLabel(String label) {
    String cleaned = label.replaceAll(RegExp(r'^\d+\s*'), '').toLowerCase().trim();

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

  // Save emotion entry
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
      final docRef = _firestore.collection(AppConstants.emotionEntriesCollection).doc(entry.id);

      batch.set(docRef, entry.toMap());
      await batch.commit();

      print('Emotion entry saved: $entry');
      return true;
    } catch (e) {
      print('Save error: $e');
      _setError('Failed to save emotion entry: ${e.toString()}');
      return false;
    }
  }

  // Get emotion entries stream
  Stream<List<EmotionEntry>> getEmotionEntriesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.emotionEntriesCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => EmotionEntry.fromMap(doc.data())).toList());
  }

  // Get most recent emotion for music recommendations
  Future<String> getMostRecentEmotionForMusic() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'neutral';

      final querySnapshot = await _firestore
          .collection(AppConstants.emotionEntriesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final entry = EmotionEntry.fromMap(querySnapshot.docs.first.data());
        return entry.emotion;
      }

      return _lastDetectedEmotion;
    } catch (e) {
      print('Error getting recent emotion: $e');
      return 'neutral';
    }
  }

  // Get motivational message
  String getMotivationalMessage() {
    final messages = AppConstants.emotionMessages[_currentEmotion] ?? AppConstants.emotionMessages['neutral'] ?? ['Keep going! You\'re doing great!'];

    final randomIndex = Random().nextInt(messages.length);
    return messages[randomIndex];
  }

  // Set error
  void _setError(String error) {
    _errorMessage = error;
    print('Error: $error');
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
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }
}
