import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MinimalActivityStreak extends StatelessWidget {
  final int streakDays;

  const MinimalActivityStreak({
    super.key,
    this.streakDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.flame,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays day streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep it going! 🔥',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

