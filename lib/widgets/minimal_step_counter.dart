import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MinimalStepCounter extends StatefulWidget {
  final int currentSteps;
  final int dailyGoal;
  final VoidCallback? onTap;

  const MinimalStepCounter({
    super.key,
    required this.currentSteps,
    this.dailyGoal = 10000,
    this.onTap,
  });

  @override
  State<MinimalStepCounter> createState() => _MinimalStepCounterState();
}

class _MinimalStepCounterState extends State<MinimalStepCounter> {
  @override
  Widget build(BuildContext context) {
    final progress = (widget.currentSteps / widget.dailyGoal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.hand_raised,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Steps Today',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white60,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.currentSteps.toString(),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 4),
                              child: Text(
                                '/ ${widget.dailyGoal}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white38,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
