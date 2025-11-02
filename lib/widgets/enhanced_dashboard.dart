import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/gait_analysis_provider.dart';

class EnhancedDashboard extends StatelessWidget {
  const EnhancedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GaitAnalysisProvider>(
      builder: (context, gaitProvider, child) {
        final scanHistory = gaitProvider.scanHistory;
        final overallScore = gaitProvider.overallHealthScore;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gait Health',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Overall Score',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getScoreColor(overallScore).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getScoreColor(overallScore),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      overallScore > 0 ? overallScore.toStringAsFixed(0) : '--',
                      style: TextStyle(
                        color: _getScoreColor(overallScore),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().scale(duration: 800.ms),
                ],
              ),

              const SizedBox(height: 24),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Scans',
                      scanHistory.length.toString(),
                      Icons.analytics,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Last Score',
                      scanHistory.isNotEmpty
                          ? scanHistory.first.healthScore.toStringAsFixed(0)
                          : '--',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Best Score',
                      scanHistory.isNotEmpty
                          ? scanHistory
                                .map((s) => s.healthScore)
                                .reduce((a, b) => a > b ? a : b)
                                .toStringAsFixed(0)
                          : '--',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Avg Score',
                      overallScore > 0 ? overallScore.toStringAsFixed(0) : '--',
                      Icons.assessment,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Progress indicator
              if (scanHistory.isNotEmpty) ...[
                Text(
                  'Progress Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressIndicator(scanHistory),
              ],

              const SizedBox(height: 20),

              // Quick insights
              _buildQuickInsights(context, scanHistory),
            ],
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3);
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms);
  }

  Widget _buildProgressIndicator(List scanHistory) {
    if (scanHistory.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Complete more scans to see your progress trend',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Get last 5 scores for trend
    final recentScores = scanHistory.take(5).map((s) => s.healthScore).toList();
    final minScore = recentScores.reduce((a, b) => a < b ? a : b);
    final maxScore = recentScores.reduce((a, b) => a > b ? a : b);
    final range = maxScore - minScore;

    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: recentScores.asMap().entries.map((entry) {
          final index = entry.key;
          final score = entry.value;
          final height = range > 0
              ? ((score - minScore) / range) * 40 + 10
              : 25;
          final isLatest = index == 0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                    width: 8,
                    height: height,
                    decoration: BoxDecoration(
                      color: isLatest
                          ? Colors.green
                          : Colors.blue.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                  .animate(delay: Duration(milliseconds: index * 100))
                  .scaleY(
                    begin: 0,
                    duration: const Duration(milliseconds: 600),
                  ),
              const SizedBox(height: 4),
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickInsights(BuildContext context, List scanHistory) {
    List<String> insights = [];

    if (scanHistory.isEmpty) {
      insights.add('Start your first scan to get personalized insights');
    } else {
      final lastScore = scanHistory.first.healthScore;
      final avgScore =
          scanHistory.map((s) => s.healthScore).reduce((a, b) => a + b) /
          scanHistory.length;

      if (lastScore > 85) {
        insights.add('Excellent gait health! Keep up the great work');
      } else if (lastScore > 70) {
        insights.add('Good gait health with room for improvement');
      } else {
        insights.add('Consider focusing on gait improvement exercises');
      }

      if (scanHistory.length >= 2) {
        final trend = lastScore - scanHistory[1].healthScore;
        if (trend > 5) {
          insights.add('Great progress! Your gait is improving');
        } else if (trend < -5) {
          insights.add('Your gait has declined slightly - consider a new scan');
        } else {
          insights.add('Your gait health is stable');
        }
      }

      if (avgScore > 80) {
        insights.add('You consistently maintain good gait health');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...insights
            .map(
              (insight) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
