import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/book_card.dart';
import '../theme/app_theme.dart';

class BorrowingsScreen extends StatelessWidget {
  const BorrowingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    if (reservationProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('My Borrowings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final borrowings = reservationProvider.activeReservations
        .where((b) => b.status == 'borrowed' || b.status == 'overdue')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('My Borrowings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: borrowings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 56,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Borrowings',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reserve a book and confirm borrowing',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: borrowings.length,
              itemBuilder: (context, index) {
                final borrowing = borrowings[index];
                final matchedBook = libraryProvider.allBooks.where(
                  (b) => b.id == borrowing.bookId,
                );
                final book = matchedBook.isNotEmpty
                    ? matchedBook.first
                    : null;

                if (book == null) return const SizedBox.shrink();

                final isOverdue = borrowing.status == 'overdue' ||
                    (borrowing.dueAt != null &&
                        DateTime.now().isAfter(borrowing.dueAt!));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BookCard(
                      book: book,
                      borrowing: borrowing,
                    ),
                    // Fine info
                    if (isOverdue && borrowing.fineAmount > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14, top: 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.error.withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 10),
                            Text(
                              'Fine: ₹${borrowing.fineAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
