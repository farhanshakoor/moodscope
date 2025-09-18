import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/emotion_stats.dart';

class EmotionChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String period;

  const EmotionChart({super.key, required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.textTertiary),
              SizedBox(height: 8),
              Text('No data available', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        data[index].label,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateInterval(data.map((e) => e.y).reduce((a, b) => a > b ? a : b)),
                reservedSize: 42,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade200)),
          minX: 0,
          maxX: data.length > 1 ? (data.length - 1).toDouble() : 1,
          minY: 0,
          maxY: data.isNotEmpty ? data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1 : 10,
          lineBarsData: [
            LineChartBarData(
              spots: data.map((point) => FlSpot(point.x, point.y)).toList(),
              isCurved: true,
              gradient: AppTheme.primaryGradient,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final emotion = data[index].emotion;
                  final color = AppTheme.emotionColors[emotion] ?? AppTheme.primaryColor;
                  return FlDotCirclePainter(radius: 6, color: color, strokeWidth: 3, strokeColor: Colors.white);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryColor.withValues(alpha: 0.3), AppTheme.primaryColor.withValues(alpha: 0.1)],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  if (index >= 0 && index < data.length) {
                    final dataPoint = data[index];
                    final emotion = dataPoint.emotion;
                    final emoji = AppConstants.emotionEmojis[emotion] ?? '😐';

                    return LineTooltipItem('$emoji ${dataPoint.label}\n${barSpot.y.toInt()} entries', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 25) return 5;
    if (maxValue <= 50) return 10;
    return 20;
  }
}
