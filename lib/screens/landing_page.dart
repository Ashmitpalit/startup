import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/gait_analysis_provider.dart';
import '../providers/tts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/badge_provider.dart';
import '../services/step_counter_service.dart';
import '../widgets/enhanced_scan_screen.dart';
import 'results_screen.dart';
import 'profile_screen.dart';
import '../widgets/minimal_weekly_progress.dart';
import '../l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TTSProvider>().initializeTTS();
      _initializeStepCounter();
    });
  }

  Future<void> _initializeStepCounter() async {
    final stepCounter = context.read<StepCounterService>();
    final gaitProvider = context.read<GaitAnalysisProvider>();
    final badgeProvider = context.read<BadgeProvider>();

    // Check if permission already granted
    final hasPermission = await stepCounter.checkPermission();
    
    if (!hasPermission) {
      // Request permission
      final granted = await stepCounter.requestPermission();
      if (!granted) {
        // Permission denied - show dialog or handle gracefully
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }
    }

    // Start listening to steps
    stepCounter.startListening();

    // Update gait provider with actual steps
    stepCounter.addListener(() {
      final steps = stepCounter.todaySteps;
      gaitProvider.updateDailySteps(steps);

      // Check for step milestone badges
      badgeProvider.checkStepMilestones(steps).then((newBadges) {
        if (newBadges.isNotEmpty && mounted) {
          _showBadgeUnlockedDialog(newBadges);
        }
      });
    });

    // Initial update
    gaitProvider.updateDailySteps(stepCounter.todaySteps);
    badgeProvider.checkStepMilestones(stepCounter.todaySteps);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121218),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Step Counter Permission',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: const Text(
          'Kadam needs permission to track your steps for accurate activity monitoring and badges. You can enable this in app settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showBadgeUnlockedDialog(List badges) {
    // Show badge unlock animation/notification
    // This can be enhanced with a custom animation widget
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(
              badges.first.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Badge Unlocked!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    badges.first.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: badges.first.color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0B0F),
              Color(0xFF1A1A2E),
              Color(0xFF0B0B0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<GaitAnalysisProvider>(
            builder: (context, gaitProvider, child) {
              return CustomScrollView(
                slivers: [
                  // Header with gradient
                  SliverToBoxAdapter(
                    child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          _buildAwesomeHeader(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Main Content Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hero Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildGradientCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.hand_raised,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '${((gaitProvider.dailySteps / 10000) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${gaitProvider.dailySteps.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Steps Today',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  gradient: const [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildGradientCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.flame,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${gaitProvider.scanHistory.length > 7 ? 7 : gaitProvider.scanHistory.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Day Streak',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  gradient: const [
                                    Color(0xFFEC4899),
                                    Color(0xFFF472B6),
                                  ],
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),

                          const SizedBox(height: 16),

                          // Health Score Hero Card
                          _buildHealthHeroCard(gaitProvider).animate().fadeIn(
                                duration: 600.ms,
                              ).slideY(begin: 0.2),

                          const SizedBox(height: 16),

                          // Weekly Progress - only show if we have scans
                          if (gaitProvider.scanHistory.isNotEmpty)
                            MinimalWeeklyProgress(
                              weeklyScores: gaitProvider.scanHistory
                                  .take(7)
                                  .map((s) => s.healthScore)
                                  .toList()
                                  .reversed
                                  .toList(),
                            ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.2),

                          if (gaitProvider.scanHistory.isNotEmpty)
                            const SizedBox(height: 24),

                          // Action Buttons with Glassmorphism
                          Row(
                            children: [
                              Expanded(
                                child: _buildAwesomeActionButton(
                                  icon: CupertinoIcons.camera,
                                  label: AppLocalizations.of(context).t('run_scan'),
                                  onTap: () => _navigateToScan(context),
                                  isPrimary: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAwesomeActionButton(
                                  icon: CupertinoIcons.chart_bar,
                                  label: AppLocalizations.of(context)
                                      .t('view_results'),
                                  onTap: () => _navigateToResults(context),
                                  isPrimary: false,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),

                          // Spacing before stats (only if scans exist, otherwise extra spacing)
                          SizedBox(height: gaitProvider.scanHistory.isNotEmpty ? 24 : 32),

                          // Quick Stats Grid - only show if we have scans
                          if (gaitProvider.scanHistory.isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatMiniCard(
                                    icon: CupertinoIcons.chart_bar,
                                    value: gaitProvider.scanHistory.length.toString(),
                                    label: 'Total Scans',
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatMiniCard(
                                    icon: CupertinoIcons.arrow_up_right,
                                    value:
                                        gaitProvider.overallHealthScore.toStringAsFixed(0),
                                    label: 'Avg Score',
                                    color: const Color(0xFF22C55E),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 900.ms).slideY(begin: 0.2),
                            const SizedBox(height: 20),
                          ],

                          // Recent Scans Section - only show if we have scans
                          if (gaitProvider.scanHistory.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    AppLocalizations.of(context).t('recent_scans'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Swipe',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        CupertinoIcons.arrow_right,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(right: 20),
                                itemCount: gaitProvider.scanHistory.length,
                                itemBuilder: (context, index) {
                                  final scan = gaitProvider.scanHistory[index];
                                  return _buildScanCard(scan, context).animate()
                                      .fadeIn(duration: 300.ms)
                                      .slideX(begin: 0.2);
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            // Extra spacing when no scans
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAwesomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'asset/logo.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          CupertinoIcons.rosette,
                          color: Colors.white,
                          size: 20,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context).t('app_title'),
                      style: const TextStyle(
                color: Colors.white,
                        fontSize: 32,
                fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).t('subtitle'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            ],
          ),
        ),
        _buildProfileButton(context),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2);
  }

  Widget _buildGradientCard({
    required Widget child,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            ),
          ],
        ),
      child: child,
    );
  }

  Widget _buildHealthHeroCard(GaitAnalysisProvider gaitProvider) {
    final score = gaitProvider.overallHealthScore;
    final hasData = gaitProvider.scanHistory.isNotEmpty;

    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chart_bar,
                color: Colors.white70,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No scans yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Run your first scan to get started',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(score).withOpacity(0.2),
            _getScoreColor(score).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getScoreColor(score).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(score).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Score',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          score.toStringAsFixed(0),
                          style: TextStyle(
                            color: _getScoreColor(score),
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(score),
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(score),
                    ),
                  ),
                ),
                Text(
                  '${(score / 100 * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwesomeActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMiniCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                    color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard(scan, BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(scan.healthScore).withOpacity(0.2),
            _getScoreColor(scan.healthScore).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getScoreColor(scan.healthScore).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getScoreColor(scan.healthScore),
                  shape: BoxShape.circle,
            ),
          ),
          Text(
            '${scan.timestamp.day}/${scan.timestamp.month}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${scan.healthScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: _getScoreColor(scan.healthScore),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) return const SizedBox.shrink();
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: authProvider.user?.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      authProvider.user!.photoURL!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          CupertinoIcons.person,
                          color: Colors.white70,
                          size: 18,
                        );
                      },
                    ),
                  )
                : const Icon(
                    CupertinoIcons.person,
                    color: Colors.white70,
                    size: 18,
                  ),
          ),
        );
      },
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

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EnhancedScanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToResults(BuildContext context) {
    final gaitProvider = context.read<GaitAnalysisProvider>();
    if (gaitProvider.currentScan != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResultsScreen(scanResult: gaitProvider.currentScan!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('no_scan_data')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}


