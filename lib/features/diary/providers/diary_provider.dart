import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodscope/features/diary/models/diary_entry.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';

class DiaryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DiaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Get diary entries stream
  Stream<List<DiaryEntry>> getDiaryEntriesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.diaryEntriesCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DiaryEntry.fromMap(doc.data())).toList());
  }

  // Add diary entry
  Future<bool> addDiaryEntry({required String title, required String content, required String mood, List<String>? tags}) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        return false;
      }

      final entry = DiaryEntry(id: _uuid.v4(), userId: user.uid, title: title, content: content, mood: mood, tags: tags ?? [], timestamp: DateTime.now());

      await _firestore.collection(AppConstants.diaryEntriesCollection).doc(entry.id).set(entry.toMap());

      return true;
    } catch (e) {
      _setError('Failed to add diary entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update diary entry
  Future<bool> updateDiaryEntry(DiaryEntry entry) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection(AppConstants.diaryEntriesCollection).doc(entry.id).update(entry.toMap());

      return true;
    } catch (e) {
      _setError('Failed to update diary entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete diary entry
  Future<bool> deleteDiaryEntry(String entryId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection(AppConstants.diaryEntriesCollection).doc(entryId).delete();

      return true;
    } catch (e) {
      _setError('Failed to delete diary entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search diary entries
  Future<List<DiaryEntry>> searchEntries(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore.collection(AppConstants.diaryEntriesCollection).where('userId', isEqualTo: user.uid).get();

      final entries = snapshot.docs
          .map((doc) => DiaryEntry.fromMap(doc.data()))
          .where(
            (entry) =>
                entry.title.toLowerCase().contains(query.toLowerCase()) ||
                entry.content.toLowerCase().contains(query.toLowerCase()) ||
                entry.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())),
          )
          .toList();

      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      _setError('Failed to search entries: $e');
      return [];
    }
  }

  // Get entries by mood
  Future<List<DiaryEntry>> getEntriesByMood(String mood) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(AppConstants.diaryEntriesCollection)
          .where('userId', isEqualTo: user.uid)
          .where('mood', isEqualTo: mood)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => DiaryEntry.fromMap(doc.data())).toList();
    } catch (e) {
      _setError('Failed to get entries by mood: $e');
      return [];
    }
  }

  // Get mood statistics
  Future<Map<String, int>> getMoodStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final snapshot = await _firestore.collection(AppConstants.diaryEntriesCollection).where('userId', isEqualTo: user.uid).get();

      final moodCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final entry = DiaryEntry.fromMap(doc.data());
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }

      return moodCounts;
    } catch (e) {
      _setError('Failed to get mood statistics: $e');
      return {};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
