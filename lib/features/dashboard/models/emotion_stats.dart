class EmotionStats {
  final String period;
  final int totalEntries;
  final Map<String, int> emotionCounts;
  final String mostFrequentEmotion;
  final double averageConfidence;
  final Map<String, double> avgConfidencePerEmotion;
  final List<ChartDataPoint> chartData;
  final DateTime startDate;
  final DateTime endDate;

  const EmotionStats({
    required this.period,
    required this.totalEntries,
    required this.emotionCounts,
    required this.mostFrequentEmotion,
    required this.averageConfidence,
    required this.avgConfidencePerEmotion,
    required this.chartData,
    required this.startDate,
    required this.endDate,
  });

  // Create empty stats
  factory EmotionStats.empty(String period) {
    final now = DateTime.now();
    return EmotionStats(
      period: period,
      totalEntries: 0,
      emotionCounts: {},
      mostFrequentEmotion: 'neutral',
      averageConfidence: 0.0,
      avgConfidencePerEmotion: {},
      chartData: [],
      startDate: now,
      endDate: now,
    );
  }

  // Get emotion percentage
  double getEmotionPercentage(String emotion) {
    if (totalEntries == 0) return 0.0;
    return (emotionCounts[emotion] ?? 0) / totalEntries * 100;
  }

  // Get sorted emotions by count
  List<MapEntry<String, int>> get sortedEmotions {
    return emotionCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  String toString() {
    return 'EmotionStats(period: $period, totalEntries: $totalEntries, mostFrequent: $mostFrequentEmotion)';
  }
}

class ChartDataPoint {
  final double x;
  final double y;
  final String label;
  final String emotion;

  const ChartDataPoint({required this.x, required this.y, required this.label, required this.emotion});

  @override
  String toString() {
    return 'ChartDataPoint(x: $x, y: $y, label: $label, emotion: $emotion)';
  }
}
