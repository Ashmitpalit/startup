import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/badge.dart';

class BadgeProvider extends ChangeNotifier {
  List<Badge> _unlockedBadges = [];
  int _totalSteps = 0;
  int _improvementStreak = 0;
  int _scanStreak = 0;
  DateTime? _lastScanDate;

  List<Badge> get unlockedBadges => _unlockedBadges;
  int get totalSteps => _totalSteps;
  int get improvementStreak => _improvementStreak;
  int get scanStreak => _scanStreak;

  BadgeProvider() {
    _loadBadges();
  }

  // Load badges from shared preferences
  Future<void> _loadBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final badgesJson = prefs.getStringList('unlocked_badges') ?? [];
      _unlockedBadges = badgesJson.map((json) => Badge.fromJson(jsonDecode(json))).toList();
      
      _totalSteps = prefs.getInt('total_steps') ?? 0;
      _improvementStreak = prefs.getInt('improvement_streak') ?? 0;
      _scanStreak = prefs.getInt('scan_streak') ?? 0;
      
      final lastScanDateStr = prefs.getString('last_scan_date');
      if (lastScanDateStr != null) {
        _lastScanDate = DateTime.parse(lastScanDateStr);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading badges: $e');
    }
  }

  // Save badges to shared preferences
  Future<void> _saveBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final badgesJson = _unlockedBadges.map((badge) => jsonEncode(badge.toJson())).toList();
      await prefs.setStringList('unlocked_badges', badgesJson);
      
      await prefs.setInt('total_steps', _totalSteps);
      await prefs.setInt('improvement_streak', _improvementStreak);
      await prefs.setInt('scan_streak', _scanStreak);
      
      if (_lastScanDate != null) {
        await prefs.setString('last_scan_date', _lastScanDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving badges: $e');
    }
  }

  // Check and unlock step milestone badges
  Future<List<Badge>> checkStepMilestones(int steps) async {
    _totalSteps = steps;
    final newBadges = <Badge>[];

    for (final milestone in BadgeDefinitions.stepMilestones) {
      final badgeId = milestone['id'] as String;
      
      // Check if already unlocked
      if (_unlockedBadges.any((b) => b.id == badgeId)) {
        continue;
      }

      // Check if threshold is reached
      final threshold = milestone['threshold'] as int;
      if (steps >= threshold) {
        final badge = Badge(
          id: badgeId,
          name: milestone['name'] as String,
          description: milestone['description'] as String,
          type: BadgeType.stepMilestone,
          unlockedAt: DateTime.now(),
          emoji: milestone['emoji'] as String,
          color: Color(milestone['color'] as int),
        );

        _unlockedBadges.add(badge);
        newBadges.add(badge);
      }
    }

    if (newBadges.isNotEmpty) {
      await _saveBadges();
      notifyListeners();
    }

    return newBadges;
  }

  // Check and unlock gait improvement badges
  Future<List<Badge>> checkGaitImprovement(double previousScore, double currentScore) async {
    final newBadges = <Badge>[];

    // Check if score improved
    if (currentScore > previousScore) {
      _improvementStreak++;
    } else {
      _improvementStreak = 0;
    }

    for (final improvement in BadgeDefinitions.gaitImprovements) {
      final badgeId = improvement['id'] as String;
      
      // Check if already unlocked
      if (_unlockedBadges.any((b) => b.id == badgeId)) {
        continue;
      }

      // Check if streak threshold is reached
      final threshold = improvement['threshold'] as int;
      if (_improvementStreak >= threshold) {
        final badge = Badge(
          id: badgeId,
          name: improvement['name'] as String,
          description: improvement['description'] as String,
          type: BadgeType.gaitImprovement,
          unlockedAt: DateTime.now(),
          emoji: improvement['emoji'] as String,
          color: Color(improvement['color'] as int),
        );

        _unlockedBadges.add(badge);
        newBadges.add(badge);
      }
    }

    if (newBadges.isNotEmpty || _improvementStreak != _improvementStreak) {
      await _saveBadges();
      notifyListeners();
    }

    return newBadges;
  }

  // Check and unlock consistency badges
  Future<List<Badge>> checkScanConsistency() async {
    final newBadges = <Badge>[];
    final now = DateTime.now();

    // Check if scanning today
    if (_lastScanDate != null) {
      final daysDifference = now.difference(_lastScanDate!).inDays;
      
      if (daysDifference == 0) {
        // Same day - don't increment
      } else if (daysDifference == 1) {
        // Consecutive day
        _scanStreak++;
      } else {
        // Streak broken
        _scanStreak = 1;
      }
    } else {
      // First scan
      _scanStreak = 1;
    }

    _lastScanDate = now;

    for (final consistency in BadgeDefinitions.consistencyBadges) {
      final badgeId = consistency['id'] as String;
      
      // Check if already unlocked
      if (_unlockedBadges.any((b) => b.id == badgeId)) {
        continue;
      }

      // Check if streak threshold is reached
      final threshold = consistency['threshold'] as int;
      if (_scanStreak >= threshold) {
        final badge = Badge(
          id: badgeId,
          name: consistency['name'] as String,
          description: consistency['description'] as String,
          type: BadgeType.consistency,
          unlockedAt: DateTime.now(),
          emoji: consistency['emoji'] as String,
          color: Color(consistency['color'] as int),
        );

        _unlockedBadges.add(badge);
        newBadges.add(badge);
      }
    }

    if (newBadges.isNotEmpty) {
      await _saveBadges();
      notifyListeners();
    }

    return newBadges;
  }

  // Check if badge is already unlocked
  bool isBadgeUnlocked(String badgeId) {
    return _unlockedBadges.any((b) => b.id == badgeId);
  }

  // Get badges by type
  List<Badge> getBadgesByType(BadgeType type) {
    return _unlockedBadges.where((b) => b.type == type).toList()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
  }
}
