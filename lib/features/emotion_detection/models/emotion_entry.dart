import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionEntry {
  final String id;
  final String userId;
  final String emotion;
  final double confidence;
  final DateTime timestamp;
  final String? note;

  const EmotionEntry({required this.id, required this.userId, required this.emotion, required this.confidence, required this.timestamp, this.note});

  // Convert EmotionEntry to Map for Firestore
  Map<String, dynamic> toMap() {
    return {'id': id, 'userId': userId, 'emotion': emotion, 'confidence': confidence, 'timestamp': Timestamp.fromDate(timestamp), 'note': note};
  }

  // Create EmotionEntry from Firestore Map
  static EmotionEntry fromMap(Map<String, dynamic> map) {
    return EmotionEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      emotion: map['emotion'] ?? 'neutral',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      note: map['note'],
    );
  }

  // Create a copy with modified fields
  EmotionEntry copyWith({String? id, String? userId, String? emotion, double? confidence, DateTime? timestamp, String? note}) {
    return EmotionEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emotion: emotion ?? this.emotion,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmotionEntry &&
        other.id == id &&
        other.userId == userId &&
        other.emotion == emotion &&
        other.confidence == confidence &&
        other.timestamp == timestamp &&
        other.note == note;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ emotion.hashCode ^ confidence.hashCode ^ timestamp.hashCode ^ note.hashCode;
  }

  @override
  String toString() {
    return 'EmotionEntry(id: $id, userId: $userId, emotion: $emotion, confidence: $confidence, timestamp: $timestamp, note: $note)';
  }
}
