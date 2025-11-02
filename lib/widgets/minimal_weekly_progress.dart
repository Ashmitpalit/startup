import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MinimalWeeklyProgress extends StatelessWidget {
  final List<double> weeklyScores;

  const MinimalWeeklyProgress({
    super.key,
    this.weeklyScores = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyScores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121218),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Icon(
                  CupertinoIcons.chart_bar,
                  color: Colors.white38,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Complete scans to see your weekly progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                  ),
            ),
          ],
        ),
      );
    }

    final maxScore = weeklyScores.isNotEmpty
        ? weeklyScores.reduce((a, b) => a > b ? a : b)
        : 100.0;
    final minScore = weeklyScores.isNotEmpty
        ? weeklyScores.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final range = maxScore - minScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '7 days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyScores.asMap().entries.map((entry) {
                final index = entry.key;
                final score = entry.value;
                final height = (range > 0
                    ? ((score - minScore) / range) * 40 + 10
                    : 25.0).toDouble();
                final isToday = index == weeklyScores.length - 1;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 6,
                      height: height,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6366F1).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ).animate(delay: Duration(milliseconds: index * 50))
                        .scaleY(begin: 0, duration: 400.ms),
                    const SizedBox(height: 6),
                    Text(
                      _getDayLabel(index),
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  String _getDayLabel(int index) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[index % 7];
  }
}

