import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/scan_result.dart';
import '../widgets/health_score_card.dart';
import '../widgets/real_3d_skeleton.dart';
import '../widgets/recommendations_panel.dart';
import '../widgets/gait_metrics_panel.dart';
import '../widgets/expandable_section.dart';

class ResultsScreen extends StatefulWidget {
  final ScanResult scanResult;

  const ResultsScreen({super.key, required this.scanResult});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedTab = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF0B0B0F)),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Tab Bar
              _buildTabBar(),

              // Content
              Expanded(child: _buildContent()),

              // Bottom Actions
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.arrow_left,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Results',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Completed ${_formatTime(widget.scanResult.timestamp)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.scanResult.getHealthStatus(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF121218),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          _buildTab('Overview', 0),
          _buildTab('3D Skeleton', 1),
          _buildTab('Analysis', 2),
          _buildTab('Recommendations', 3),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _selectedTab = index);
      },
      children: [
        _buildOverviewTab(),
        _buildSkeleton3DTab(),
        _buildAnalysisTab(),
        _buildRecommendationsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Health Score Card
          HealthScoreCard(
            score: widget.scanResult.healthScore,
            hasData: true,
            showDetails: true,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 20),

          // Real 3D Skeleton Heat Map
          Real3DSkeleton(
            injuryRisk: widget.scanResult.injuryRisk,
          ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2),

          const SizedBox(height: 20),

          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildSkeleton3DTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          Text(
            '3D Injury Risk Visualization',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info,
                      color: Colors.blue,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Interactive 3D Skeleton',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Drag to rotate the 3D skeleton\n• Use rotation controls for precise angles\n• Pinch to zoom in/out\n• Colors indicate injury risk levels',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 20),

          // Real 3D Skeleton Heatmap
          Real3DSkeleton(injuryRisk: widget.scanResult.injuryRisk)
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 20),

          // Risk Legend
          _buildRiskLegend(),

          const SizedBox(height: 20),

          // Detailed Risk Breakdown
          _buildRiskBreakdown(),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Gait Metrics Panel (Expandable)
          ExpandableSection(
            title: 'Gait Metrics',
            icon: CupertinoIcons.hand_raised,
            child: GaitMetricsPanel(
              gaitData: widget.scanResult.gaitData,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          // Joint Angles Chart (Expandable)
          ExpandableSection(
            title: 'Joint Angles Analysis',
            icon: Icons.analytics_rounded,
            child: _buildJointAnglesChartContent(),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          // Posture Analysis (Expandable)
          ExpandableSection(
            title: 'Posture Analysis',
            icon: CupertinoIcons.arrow_up_down,
            child: _buildPostureAnalysisContent(),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildJointAnglesChartContent() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 30,
          barTouchData: BarTouchData(enabled: false),
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
                getTitlesWidget: (value, meta) {
                  return Text(
                    widget
                        .scanResult
                        .gaitData
                        .jointAngles[value.toInt()]
                        .jointName
                        .replaceAll('_', ' ')
                        .toUpperCase(),
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
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°',
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
          barGroups: widget.scanResult.gaitData.jointAngles
              .asMap()
              .entries
              .map((entry) {
                final joint = entry.value;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: joint.angle,
                      color: joint.isOutOfRange()
                          ? Colors.red
                          : Colors.green,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              })
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPostureAnalysisContent() {
    return Column(
      children: widget.scanResult.gaitData.postureData
          .map(
            (posture) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: posture.hasIssues()
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: posture.hasIssues() ? Colors.red : Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    posture.hasIssues()
                        ? CupertinoIcons.exclamationmark_triangle
                        : CupertinoIcons.check_mark_circled,
                    color: posture.hasIssues() ? Colors.red : Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          posture.postureType
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          posture.feedback,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          RecommendationsPanel(
            recommendations: widget.scanResult.recommendations,
            corrections: widget.scanResult.corrections,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF121218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Walking Speed',
                  '${widget.scanResult.gaitData.walkingSpeed.toStringAsFixed(1)} m/s',
                  CupertinoIcons.speedometer,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Cadence',
                  '${widget.scanResult.gaitData.averageCadence.toStringAsFixed(0)} steps/min',
                  CupertinoIcons.chart_bar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Stride Length',
                  '${widget.scanResult.gaitData.averageStrideLength.toStringAsFixed(2)} m',
                  CupertinoIcons.arrow_up_down,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Symmetry',
                  '${(widget.scanResult.gaitData.stepSymmetry * 100).toStringAsFixed(1)}%',
                  CupertinoIcons.equal,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Old methods removed - replaced with expandable sections

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                CupertinoIcons.arrow_clockwise,
                size: 20,
              ),
              label: const Text('New Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Share results
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(
                CupertinoIcons.share,
                size: 20,
              ),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Color _getStatusColor() {
    final status = widget.scanResult.getHealthStatus();
    switch (status) {
      case 'Excellent':
        return const Color(0xFF22C55E); // emerald
      case 'Good':
        return const Color(0xFF34D399); // mint
      case 'Fair':
        return const Color(0xFFF59E0B); // amber
      case 'Poor':
        return const Color(0xFFEF4444); // red
      case 'Critical':
        return const Color(0xFF7F1D1D); // dark red
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildRiskLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Level Legend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLegendItem('Low Risk', Colors.blue, '0-20%'),
              ),
              Expanded(
                child: _buildLegendItem('Moderate', Colors.green, '20-40%'),
              ),
              Expanded(
                child: _buildLegendItem('Elevated', Colors.yellow, '40-60%'),
              ),
              Expanded(
                child: _buildLegendItem('High', Colors.orange, '60-80%'),
              ),
              Expanded(
                child: _buildLegendItem('Critical', Colors.red, '80-100%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          range,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRiskBreakdown() {
    final sortedRisks = widget.scanResult.injuryRisk.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Risk Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedRisks.take(10).map((entry) {
            final risk = entry.value;
            final color = _getRiskColor(risk);
            final percentage = (risk * 100).toInt();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatBodyPartName(entry.key),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.2) return Colors.blue;
    if (risk < 0.4) return Colors.green;
    if (risk < 0.6) return Colors.yellow;
    if (risk < 0.8) return Colors.orange;
    return Colors.red;
  }

  String _formatBodyPartName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
