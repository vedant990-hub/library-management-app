import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_analytics_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_transitions.dart';
import 'loans/admin_loans_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const AdminDashboardScreen({super.key, this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminAnalyticsProvider>(context, listen: false).fetchAnalytics();
      _migrateGenres();
    });
  }

  /// One-time migration: adds genres to books that don't have them yet.
  Future<void> _migrateGenres() async {
    final genreMap = {
      'the great gatsby': ['Fiction'],
      'pride and prejudice': ['Drama'],
      '1984': ['Novel'],
      'to kill a mockingbird': ['Leadership'],
      'mein kampf': ['Self-Help'],
      'gajni': ['Startups'],
    };

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('books').get();
      for (final doc in snapshot.docs) {
        final title = (doc.data()['title'] as String?)?.toLowerCase() ?? '';
        final existingGenres = doc.data()['genres'] as List<dynamic>?;
        if (genreMap.containsKey(title) && (existingGenres == null || existingGenres.isEmpty)) {
          await doc.reference.update({'genres': genreMap[title]});
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AdminAnalyticsProvider>(context);

    if (analytics.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.adminAccent));
    }

    if (analytics.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load analytics',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => analytics.fetchAnalytics(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => analytics.fetchAnalytics(),
      color: AppColors.adminAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Library analytics at a glance',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),

            // Stat cards grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: analytics.totalUsers,
                  icon: Icons.people_rounded,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  onTap: () => widget.onNavigate?.call(1), // Users Tab
                ),
                _StatCard(
                  title: 'Total Books',
                  value: analytics.totalBooks,
                  icon: Icons.library_books_rounded,
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  onTap: () => widget.onNavigate?.call(3), // Books Tab
                ),
                _StatCard(
                  title: 'Active Loans',
                  value: analytics.activeBorrowings,
                  icon: Icons.menu_book_rounded,
                  gradientColors: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
                  onTap: () {
                    Navigator.push(context, FadeSlideRoute(page: const AdminLoansScreen(statusFilter: 'borrowed')));
                  },
                ),
                _StatCard(
                  title: 'Overdue',
                  value: analytics.overdueBorrowings,
                  icon: Icons.warning_rounded,
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  onTap: () {
                    Navigator.push(context, FadeSlideRoute(page: const AdminLoansScreen(statusFilter: 'overdue')));
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Financial overview
            Text(
              'Financial Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _FinanceCard(
              label: 'Total Wallet Balance',
              value: analytics.totalWalletBalance,
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
            const SizedBox(height: 12),
            _FinanceCard(
              label: 'Locked Deposits',
              value: analytics.totalLockedDeposits,
              icon: Icons.lock_rounded,
              color: AppColors.warning,
              bgColor: AppColors.warningLight,
            ),
            const SizedBox(height: 12),
            _FinanceCard(
              label: 'Fines Collected',
              value: analytics.totalFinesCollected,
              icon: Icons.receipt_long_rounded,
              color: AppColors.error,
              bgColor: AppColors.errorLight,
            ),
            const SizedBox(height: 28),

            // Monthly Library Activity Section
            Text(
              'Monthly Library Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildBorrowingBarChart(analytics),
            const SizedBox(height: 20),
            _buildUsersBarChart(analytics),
            const SizedBox(height: 20),
            _buildFinesBarChart(analytics),
            const SizedBox(height: 28),

            // Reset All Data button
            OutlinedButton.icon(
              onPressed: () => _showResetDialog(context, analytics),
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
              label: Text('Reset All Data',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withAlpha(100)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildBorrowingBarChart(AdminAnalyticsProvider analytics) {
    if (analytics.monthlyBorrowings.isEmpty || analytics.monthlyBorrowings.values.every((v) => v == 0)) {
      return _buildEmptyState('Books Borrowed Per Month');
    }

    final keys = analytics.monthlyBorrowings.keys.toList();
    final values = analytics.monthlyBorrowings.values.toList();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2;

    return _buildChartCard(
      title: 'Books Borrowed Per Month',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 10 : maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary.withAlpha(200),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                  '${rod.toY.round()}',
                  GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) {
                    return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      value.toInt().toString(),
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < keys.length) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(
                        keys[value.toInt()],
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    );
                  }
                  return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            checkToShowHorizontalLine: (value) => value % 1 == 0,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.cardBorder,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: values.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildUsersBarChart(AdminAnalyticsProvider analytics) {
    if (analytics.monthlyUsers.isEmpty || analytics.monthlyUsers.values.every((v) => v == 0)) {
       return _buildEmptyState('New Users Per Month');
    }

    final keys = analytics.monthlyUsers.keys.toList();
    final values = analytics.monthlyUsers.values.toList();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2;

    return _buildChartCard(
      title: 'New Users Per Month',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 10 : maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary.withAlpha(200),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()}',
                  GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) {
                    return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      value.toInt().toString(),
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < keys.length) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(
                        keys[value.toInt()],
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    );
                  }
                  return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            checkToShowHorizontalLine: (value) => value % 1 == 0,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.cardBorder,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: values.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: AppColors.success,
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildFinesBarChart(AdminAnalyticsProvider analytics) {
    if (analytics.monthlyFines.isEmpty || analytics.monthlyFines.values.every((v) => v == 0)) {
       return _buildEmptyState('Monthly Fine Collection');
    }

    final keys = analytics.monthlyFines.keys.toList();
    final values = analytics.monthlyFines.values.toList();
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;

    return _buildChartCard(
      title: 'Monthly Fine Collection',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 10 : maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.error.withAlpha(200),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                  '₹${rod.toY.toStringAsFixed(0)}',
                  GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      '₹${value.toInt()}',
                      style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textTertiary),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < keys.length) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(
                        keys[value.toInt()],
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    );
                  }
                  return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.cardBorder,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: values.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: AppColors.error,
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textTertiary.withAlpha(100)),
          const SizedBox(height: 12),
          Text(
            'No analytics data available yet',
            style: GoogleFonts.poppins(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: child,
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context, AdminAnalyticsProvider analytics) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset All Data?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'This will:\n'
          '• Set all user wallets to ₹500\n'
          '• Set all book copies to 100\n'
          '• Delete ALL reservation & borrowing history\n\n'
          'This cannot be undone!',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show loading
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 16),
            Text('Resetting data...', style: GoogleFonts.poppins()),
          ],
        ),
        duration: const Duration(seconds: 10),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Reset all user wallets to ₹500
      final usersSnapshot = await firestore.collection('users').get();
      for (final userDoc in usersSnapshot.docs) {
        final walletRef = firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('wallet')
            .doc('default');
        await walletRef.set({
          'availableBalance': 500.0,
          'lockedDeposit': 0.0,
          'totalFinesPaid': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Reset all book copies to 100
      final booksSnapshot = await firestore.collection('books').get();
      for (final bookDoc in booksSnapshot.docs) {
        await bookDoc.reference.update({
          'availableCopies': 100,
          'totalCopies': 100,
        });
      }

      // 3. Delete ALL reservations/borrowing history
      final reservationsSnapshot =
          await firestore.collection('reservations').get();
      for (final doc in reservationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Refresh analytics
      await analytics.fetchAnalytics();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('All data reset successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Reset failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return Text(
                    val.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  );
                },
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    ), // This closes the Container
    ); // This closes the GestureDetector
  }
}

class _FinanceCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _FinanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return Text(
                '₹${val.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _BarItem({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, val, _) {
            return Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                widthFactor: val.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
