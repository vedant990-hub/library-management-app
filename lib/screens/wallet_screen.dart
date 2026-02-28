import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final uid = authProvider.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('My Wallet', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('My Wallet', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('wallet')
            .doc('default')
            .snapshots(),
        builder: (context, snapshot) {
          double availableBalance = 0.0;
          double lockedDeposit = 0.0;
          double totalFinesPaid = 0.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            availableBalance = (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
            lockedDeposit = (data['lockedDeposit'] as num?)?.toDouble() ?? 0.0;
            totalFinesPaid = (data['totalFinesPaid'] as num?)?.toDouble() ?? 0.0;
          }

          final totalBalance = availableBalance + lockedDeposit;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.walletGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withAlpha(50),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Balance',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${totalBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Balance breakdown
                      Row(
                        children: [
                          Flexible(
                            child: _BalanceChip(
                              label: 'Available',
                              amount: availableBalance,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: _BalanceChip(
                              label: 'Locked',
                              amount: lockedDeposit,
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Add Money Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddMoneySheet(context, walletProvider),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: Text(
                            'Add Money',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF667EEA),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Fines Paid Card
                if (totalFinesPaid > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: AppColors.error, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Fines Paid',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              '₹${totalFinesPaid.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Active Deposits
                Text(
                  'Active Deposits',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                reservationProvider.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    : reservationProvider.activeReservations.isEmpty
                        ? _EmptyState(
                            icon: Icons.book_outlined,
                            message: 'No active deposits',
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reservationProvider.activeReservations.length,
                            itemBuilder: (context, index) {
                              final borrowing = reservationProvider.activeReservations[index];
                              final isOverdue = borrowing.status == 'overdue' ||
                                  (borrowing.dueAt != null &&
                                      DateTime.now().isAfter(borrowing.dueAt!));

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
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
                                        color: isOverdue
                                            ? AppColors.errorLight
                                            : AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.menu_book_rounded,
                                        color: isOverdue
                                            ? AppColors.error
                                            : AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            borrowing.status == 'reserved'
                                                ? 'Reserved Book'
                                                : 'Borrowed Book',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Deposit: ₹${borrowing.depositAmount.toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isOverdue
                                            ? AppColors.errorLight
                                            : borrowing.status == 'reserved'
                                                ? AppColors.warningLight
                                                : AppColors.successLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        borrowing.status.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isOverdue
                                              ? AppColors.error
                                              : borrowing.status == 'reserved'
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMoneySheet(BuildContext context, WalletProvider walletProvider) {
    final controller = TextEditingController();
    final quickAmounts = [100, 200, 300, 500];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Money',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Quick amounts
              Wrap(
                spacing: 10,
                children: quickAmounts.map((amt) {
                  return ActionChip(
                    label: Text('₹$amt'),
                    onPressed: () {
                      controller.text = amt.toString();
                    },
                    backgroundColor: AppColors.primaryLight,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Enter amount',
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600),
                  helperText: 'Max wallet balance: ₹${WalletProvider.maxBalance.toStringAsFixed(0)}',
                  helperStyle: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Enter a valid amount'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    await walletProvider.addMoney(amount);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Text('₹${amount.toStringAsFixed(0)} added!'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Add Money',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Balance Chip ───
class _BalanceChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BalanceChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: ₹${amount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ───
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.poppins(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
