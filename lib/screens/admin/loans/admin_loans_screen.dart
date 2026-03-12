import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/borrowing.dart';
import '../../../theme/app_theme.dart';

class AdminLoansScreen extends StatelessWidget {
  final String statusFilter; // e.g., 'borrowed', 'overdue'

  const AdminLoansScreen({super.key, required this.statusFilter});

  String get _title {
    if (statusFilter == 'borrowed') return 'Active Loans';
    if (statusFilter == 'overdue') return 'Overdue Loans';
    return 'Loans';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('status', isEqualTo: statusFilter)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load ${_title.toLowerCase()}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  if (snapshot.error != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        snapshot.error.toString(),
                        style: GoogleFonts.poppins(fontSize: 10, color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.adminAccent));
          }

          final borrowings = snapshot.data!.docs
              .map((doc) => Borrowing.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          // Client-side sort to avoid composite index requirement
          borrowings.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));

          if (borrowings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    statusFilter == 'overdue' ? Icons.check_circle_outline_rounded : Icons.library_books_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text('No $_title found',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: borrowings.length,
            itemBuilder: (context, index) {
              return _LoanItem(
                borrowing: borrowings[index],
                statusFilter: statusFilter,
              );
            },
          );
        },
      ),
    );
  }
}

class _LoanItem extends StatelessWidget {
  final Borrowing borrowing;
  final String statusFilter;

  const _LoanItem({required this.borrowing, required this.statusFilter});

  Future<Map<String, String>> _fetchDetails() async {
    String userName = 'Loading...';
    String bookTitle = 'Loading...';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(borrowing.userId)
          .get();
      if (userDoc.exists) {
        userName = userDoc.data()?['name'] ?? 'Unknown User';
      }

      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(borrowing.bookId)
          .get();
      if (bookDoc.exists) {
        bookTitle = bookDoc.data()?['title'] ?? 'Unknown Book';
      }
    } catch (_) {}

    return {'userName': userName, 'bookTitle': bookTitle};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _fetchDetails(),
      builder: (context, snapshot) {
        final details = snapshot.data ?? {'userName': '...', 'bookTitle': '...'};
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details['bookTitle']!,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${borrowing.bookId}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusFilter == 'overdue' ? AppColors.errorLight : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusFilter.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusFilter == 'overdue' ? AppColors.error : AppColors.info,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details['userName']!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'User ID: ${borrowing.userId}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (borrowing.borrowedAt != null)
                    _DateInfo(
                      label: 'Borrowed',
                      date: borrowing.borrowedAt!,
                    ),
                  if (borrowing.dueAt != null)
                    _DateInfo(
                      label: 'Due Date',
                      date: borrowing.dueAt!,
                      isUrgent: statusFilter == 'overdue',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isUrgent;

  const _DateInfo({
    required this.label,
    required this.date,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          DateFormat('MMM dd, yyyy').format(date),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w600,
            color: isUrgent ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

