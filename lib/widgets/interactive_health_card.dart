import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InteractiveHealthCard extends StatefulWidget {
  final double score;
  final bool hasData;

  const InteractiveHealthCard({
    super.key,
    required this.score,
    required this.hasData,
  });

  @override
  State<InteractiveHealthCard> createState() => _InteractiveHealthCardState();
}

class _InteractiveHealthCardState extends State<InteractiveHealthCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.hasData) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF121218),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: Colors.white38,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No scans yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white60,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Run your first scan to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                  ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121218),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getScoreColor(widget.score).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.score.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: _getScoreColor(widget.score),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '/100',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white38,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getScoreColor(widget.score).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: _getScoreColor(widget.score),
                    size: 24,
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 20),
              Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 16),
              _buildStatRow('Status', _getStatusText(widget.score)),
              const SizedBox(height: 12),
              _buildStatRow('Trend', 'Improving'),
              const SizedBox(height: 12),
              _buildStatRow('Last Scan', 'Today'),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFF34D399);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getStatusText(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }
}
