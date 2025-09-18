import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String mood;
  final List<String> tags;
  final DateTime timestamp;
  final DateTime? updatedAt;

  const DiaryEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.mood,
    required this.tags,
    required this.timestamp,
    this.updatedAt,
  });

  // Convert DiaryEntry to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'tags': tags,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create DiaryEntry from Firestore Map
  static DiaryEntry fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      mood: map['mood'] ?? 'neutral',
      tags: List<String>.from(map['tags'] ?? []),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  // Create a copy with modified fields
  DiaryEntry copyWith({String? id, String? userId, String? title, String? content, String? mood, List<String>? tags, DateTime? timestamp, DateTime? updatedAt}) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiaryEntry &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.content == content &&
        other.mood == mood &&
        other.tags.toString() == tags.toString() &&
        other.timestamp == timestamp &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ title.hashCode ^ content.hashCode ^ mood.hashCode ^ tags.hashCode ^ timestamp.hashCode ^ updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'DiaryEntry(id: $id, userId: $userId, title: $title, content: $content, mood: $mood, tags: $tags, timestamp: $timestamp, updatedAt: $updatedAt)';
  }
}
