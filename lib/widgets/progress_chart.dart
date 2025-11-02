import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>> progressData;

  const ProgressChart({super.key, required this.progressData});

  @override
  Widget build(BuildContext context) {
    if (progressData.length < 2) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Over Time',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your health score improvement',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= progressData.length)
                          return const SizedBox.shrink();
                        final date = DateTime.parse(
                          progressData[value.toInt()]['date'],
                        );
                        return Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (progressData.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: progressData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['score']?.toDouble() ?? 0.0,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF4CAF50),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withOpacity(0.3),
                          const Color(0xFF4CAF50).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Trend indicator
          _buildTrendIndicator(),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator() {
    if (progressData.length < 2) return const SizedBox.shrink();

    final firstScore = progressData.first['score']?.toDouble() ?? 0.0;
    final lastScore = progressData.last['score']?.toDouble() ?? 0.0;
    final trend = lastScore - firstScore;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          trend > 0
              ? CupertinoIcons.arrow_up
              : trend < 0
              ? CupertinoIcons.arrow_down
              : CupertinoIcons.minus,
          color: trend > 0
              ? Colors.green
              : trend < 0
              ? Colors.red
              : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          trend > 0
              ? 'Improving (+${trend.toStringAsFixed(1)})'
              : trend < 0
              ? 'Declining (${trend.toStringAsFixed(1)})'
              : 'Stable',
          style: TextStyle(
            color: trend > 0
                ? Colors.green
                : trend < 0
                ? Colors.red
                : Colors.orange,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }
}






