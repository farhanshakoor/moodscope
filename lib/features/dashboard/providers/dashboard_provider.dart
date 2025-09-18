import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../emotion_detection/models/emotion_entry.dart';
import '../models/emotion_stats.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  EmotionStats? _weeklyStats;
  EmotionStats? _monthlyStats;
  EmotionStats? _yearlyStats;
  bool _isLoading = false;
  String? _errorMessage;

  EmotionStats? get weeklyStats => _weeklyStats;
  EmotionStats? get monthlyStats => _monthlyStats;
  EmotionStats? get yearlyStats => _yearlyStats;
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

  // Load all statistics
  Future<void> loadAllStats() async {
    try {
      _setLoading(true);
      _setError(null);

      final now = DateTime.now();

      // Weekly stats (last 7 days)
      final weekStart = now.subtract(const Duration(days: 7));
      _weeklyStats = await _getEmotionStats(weekStart, now, 'week');

      // Monthly stats (last 30 days)
      final monthStart = now.subtract(const Duration(days: 30));
      _monthlyStats = await _getEmotionStats(monthStart, now, 'month');

      // Yearly stats (last 365 days)
      final yearStart = now.subtract(const Duration(days: 365));
      _yearlyStats = await _getEmotionStats(yearStart, now, 'year');
    } catch (e) {
      _setError('Failed to load statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get emotion statistics for a specific period
  Future<EmotionStats> _getEmotionStats(DateTime startDate, DateTime endDate, String period) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _firestore
        .collection(AppConstants.emotionEntriesCollection)
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp', descending: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return EmotionStats.empty(period);
    }

    final entries = snapshot.docs.map((doc) => EmotionEntry.fromMap(doc.data())).toList();

    return _calculateEmotionStats(entries, period, startDate, endDate);
  }

  // Calculate emotion statistics from entries
  EmotionStats _calculateEmotionStats(List<EmotionEntry> entries, String period, DateTime startDate, DateTime endDate) {
    if (entries.isEmpty) {
      return EmotionStats.empty(period);
    }

    // Calculate emotion counts
    final emotionCounts = <String, int>{};
    final emotionConfidences = <String, List<double>>{};
    final dailyEmotions = <DateTime, Map<String, int>>{};

    double totalConfidence = 0;

    for (final entry in entries) {
      // Count emotions
      emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;

      // Track confidences
      emotionConfidences[entry.emotion] ??= [];
      emotionConfidences[entry.emotion]!.add(entry.confidence);
      totalConfidence += entry.confidence;

      // Daily breakdown
      final date = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      dailyEmotions[date] ??= {};
      dailyEmotions[date]![entry.emotion] = (dailyEmotions[date]![entry.emotion] ?? 0) + 1;
    }

    // Find most frequent emotion
    final mostFrequent = emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Calculate average confidences per emotion
    final avgConfidencePerEmotion = <String, double>{};
    emotionConfidences.forEach((emotion, confidences) {
      avgConfidencePerEmotion[emotion] = confidences.reduce((a, b) => a + b) / confidences.length;
    });

    // Generate chart data points
    final chartData = _generateChartData(dailyEmotions, startDate, endDate, period);

    return EmotionStats(
      period: period,
      totalEntries: entries.length,
      emotionCounts: emotionCounts,
      mostFrequentEmotion: mostFrequent.key,
      averageConfidence: totalConfidence / entries.length,
      avgConfidencePerEmotion: avgConfidencePerEmotion,
      chartData: chartData,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Generate chart data based on period
  List<ChartDataPoint> _generateChartData(Map<DateTime, Map<String, int>> dailyEmotions, DateTime startDate, DateTime endDate, String period) {
    final chartData = <ChartDataPoint>[];

    if (period == 'week') {
      // Daily data for week
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dayKey = DateTime(date.year, date.month, date.day);
        final emotions = dailyEmotions[dayKey] ?? {};

        final totalForDay = emotions.values.fold<int>(0, (sum, count) => sum + count);
        final mostFrequent = emotions.isNotEmpty ? emotions.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'neutral';

        chartData.add(ChartDataPoint(x: i.toDouble(), y: totalForDay.toDouble(), label: _getDayLabel(date), emotion: mostFrequent));
      }
    } else if (period == 'month') {
      // Weekly data for month
      for (int week = 0; week < 4; week++) {
        final weekStart = startDate.add(Duration(days: week * 7));
        weekStart.add(const Duration(days: 6));

        int weekTotal = 0;
        final weekEmotions = <String, int>{};

        for (int day = 0; day < 7; day++) {
          final date = weekStart.add(Duration(days: day));
          final dayKey = DateTime(date.year, date.month, date.day);
          final dayEmotions = dailyEmotions[dayKey] ?? {};

          dayEmotions.forEach((emotion, count) {
            weekEmotions[emotion] = (weekEmotions[emotion] ?? 0) + count;
            weekTotal += count;
          });
        }

        final mostFrequent = weekEmotions.isNotEmpty ? weekEmotions.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'neutral';

        chartData.add(ChartDataPoint(x: week.toDouble(), y: weekTotal.toDouble(), label: 'Week ${week + 1}', emotion: mostFrequent));
      }
    } else {
      // Monthly data for year
      for (int month = 0; month < 12; month++) {
        final monthStart = DateTime(startDate.year, startDate.month + month, 1);
        final monthEnd = DateTime(startDate.year, startDate.month + month + 1, 0);

        int monthTotal = 0;
        final monthEmotions = <String, int>{};

        dailyEmotions.forEach((date, emotions) {
          if (date.isAfter(monthStart.subtract(const Duration(days: 1))) && date.isBefore(monthEnd.add(const Duration(days: 1)))) {
            emotions.forEach((emotion, count) {
              monthEmotions[emotion] = (monthEmotions[emotion] ?? 0) + count;
              monthTotal += count;
            });
          }
        });

        final mostFrequent = monthEmotions.isNotEmpty ? monthEmotions.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'neutral';

        chartData.add(ChartDataPoint(x: month.toDouble(), y: monthTotal.toDouble(), label: _getMonthLabel(month), emotion: mostFrequent));
      }
    }

    return chartData;
  }

  String _getDayLabel(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  String _getMonthLabel(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
