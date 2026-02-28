import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../models/borrowing.dart';
import '../../theme/app_theme.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserProfile user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  List<Borrowing> _borrowings = [];
  bool _historyLoading = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: widget.user.uid)
          .get();

      final list = snapshot.docs
          .map((doc) => Borrowing.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by reservedAt descending
      list.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));

      if (mounted) {
        setState(() {
          _borrowings = list;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
          _historyLoading = false;
        });
      }
    }
  }

  Stream<DocumentSnapshot> _fetchWallet() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('wallet')
        .doc('default')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('User Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.adminAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: user.isAdmin
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: user.isAdmin
                            ? const Color(0xFFFEF3C7)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.isAdmin ? '⭐ Administrator' : 'Member',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: user.isAdmin
                              ? const Color(0xFFB45309)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wallet
              Text(
                'Wallet Status (Read-Only)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              if (user.isAdmin)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.textTertiary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Admins do not have wallets',
                        style: GoogleFonts.poppins(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                StreamBuilder<DocumentSnapshot>(
                  stream: _fetchWallet(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(20),
                        child:
                            CircularProgressIndicator(color: AppColors.adminAccent),
                      ));
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          'Wallet not initialized',
                          style: GoogleFonts.poppins(
                              color: AppColors.textTertiary, fontSize: 14),
                        ),
                      );
                    }

                    final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final available =
                        (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
                    final locked =
                        (data['lockedDeposit'] as num?)?.toDouble() ?? 0.0;

                    return Row(
                      children: [
                        Expanded(
                          child: _ValueCard(
                            label: 'Available',
                            value: '₹${available.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppColors.success,
                            bgColor: AppColors.successLight,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ValueCard(
                            label: 'Locked',
                            value: '₹${locked.toStringAsFixed(2)}',
                            icon: Icons.lock_rounded,
                            color: AppColors.warning,
                            bgColor: AppColors.warningLight,
                          ),
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 28),
              Text(
                'Borrowing History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Borrowing History (loaded via get())
              if (_historyLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.adminAccent),
                ))
              else if (_historyError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load history',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _historyError!,
                          style: GoogleFonts.poppins(
                              color: AppColors.textTertiary, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadHistory,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_borrowings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No borrowing history',
                          style: GoogleFonts.poppins(
                              color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _borrowings.length,
                  itemBuilder: (context, index) {
                    final b = _borrowings[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          _buildStatusIcon(b.status),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Book: ${b.bookId.length > 12 ? '${b.bookId.substring(0, 12)}...' : b.bookId}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _statusColor(b.status).withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    b.status.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(b.status),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (b.fineAmount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${b.fineAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    final iconMap = {
      'reserved': (Icons.timer_rounded, AppColors.info, AppColors.infoLight),
      'borrowed': (Icons.menu_book_rounded, AppColors.success, AppColors.successLight),
      'overdue': (Icons.warning_rounded, AppColors.error, AppColors.errorLight),
      'returned': (Icons.check_circle_rounded, AppColors.textTertiary, const Color(0xFFF3F4F6)),
      'expired': (Icons.cancel_rounded, AppColors.warning, AppColors.warningLight),
    };
    final entry = iconMap[status] ?? (Icons.book_rounded, AppColors.textSecondary, const Color(0xFFF3F4F6));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: entry.$3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(entry.$1, color: entry.$2, size: 20),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reserved':
        return AppColors.info;
      case 'borrowed':
        return AppColors.success;
      case 'overdue':
        return AppColors.error;
      case 'returned':
        return AppColors.textTertiary;
      case 'expired':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _ValueCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
