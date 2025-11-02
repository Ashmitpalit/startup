import 'package:flutter/material.dart';

enum BadgeType {
  stepMilestone,
  gaitImprovement,
  consistency,
  dedication,
}

class Badge {
  final String id;
  final String name;
  final String description;
  final BadgeType type;
  final DateTime unlockedAt;
  final String emoji;
  final Color color;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.unlockedAt,
    required this.emoji,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'unlockedAt': unlockedAt.toIso8601String(),
      'emoji': emoji,
      'color': color.value,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BadgeType.stepMilestone,
      ),
      unlockedAt: DateTime.parse(json['unlockedAt']),
      emoji: json['emoji'],
      color: Color(json['color']),
    );
  }
}

// Badge definitions
class BadgeDefinitions {
  // Step milestone badges
  static const List<Map<String, dynamic>> stepMilestones = [
    {
      'id': 'steps_1k',
      'name': 'First Steps',
      'description': 'Walked 1,000 steps',
      'emoji': '👣',
      'color': 0xFF6366F1,
      'threshold': 1000,
    },
    {
      'id': 'steps_5k',
      'name': 'Getting There',
      'description': 'Walked 5,000 steps',
      'emoji': '🚶',
      'color': 0xFF8B5CF6,
      'threshold': 5000,
    },
    {
      'id': 'steps_10k',
      'name': 'Daily Goal',
      'description': 'Walked 10,000 steps',
      'emoji': '🏃',
      'color': 0xFF22C55E,
      'threshold': 10000,
    },
    {
      'id': 'steps_25k',
      'name': 'Power Walker',
      'description': 'Walked 25,000 steps',
      'emoji': '💪',
      'color': 0xFFF59E0B,
      'threshold': 25000,
    },
    {
      'id': 'steps_50k',
      'name': 'Marathoner',
      'description': 'Walked 50,000 steps',
      'emoji': '🏆',
      'color': 0xFFEF4444,
      'threshold': 50000,
    },
    {
      'id': 'steps_100k',
      'name': 'Ultra Walker',
      'description': 'Walked 100,000 steps',
      'emoji': '👑',
      'color': 0xFFFFD700,
      'threshold': 100000,
    },
  ];

  // Gait improvement badges
  static const List<Map<String, dynamic>> gaitImprovements = [
    {
      'id': 'improve_3',
      'name': 'On the Rise',
      'description': 'Improved gait score 3 times in a row',
      'emoji': '📈',
      'color': 0xFF22C55E,
      'threshold': 3,
    },
    {
      'id': 'improve_5',
      'name': 'Consistent Progress',
      'description': 'Improved gait score 5 times in a row',
      'emoji': '⭐',
      'color': 0xFF6366F1,
      'threshold': 5,
    },
    {
      'id': 'improve_10',
      'name': 'Master Walker',
      'description': 'Improved gait score 10 times in a row',
      'emoji': '🌟',
      'color': 0xFFF59E0B,
      'threshold': 10,
    },
  ];

  // Consistency badges
  static const List<Map<String, dynamic>> consistencyBadges = [
    {
      'id': 'scan_7',
      'name': 'Week Warrior',
      'description': 'Scanned 7 days in a row',
      'emoji': '🔥',
      'color': 0xFFEF4444,
      'threshold': 7,
    },
    {
      'id': 'scan_30',
      'name': 'Month Master',
      'description': 'Scanned 30 days in a row',
      'emoji': '🎯',
      'color': 0xFF8B5CF6,
      'threshold': 30,
    },
  ];
}
