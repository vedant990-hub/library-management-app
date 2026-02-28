import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/book_card.dart';
import '../theme/app_theme.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    if (reservationProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('My Reservations', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final reservations = reservationProvider.activeReservations;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('My Reservations', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: reservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Reservations',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse books and make a reservation',
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
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final borrowing = reservations[index];
                final matchedBook = libraryProvider.allBooks.where(
                  (b) => b.id == borrowing.bookId,
                );
                final book = matchedBook.isNotEmpty
                    ? matchedBook.first
                    : null;

                if (book == null) return const SizedBox.shrink();

                return BookCard(
                  book: book,
                  borrowing: borrowing,
                  primaryActionLabel:
                      borrowing.status == 'reserved' ? 'Confirm Borrow' : null,
                  onPrimaryAction: borrowing.status == 'reserved'
                      ? () async {
                          try {
                            await reservationProvider
                                .confirmBorrow(borrowing);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 12),
                                      const Text('Borrowing confirmed!'),
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
                                  content: Text(e
                                      .toString()
                                      .replaceAll('Exception: ', '')),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  secondaryActionLabel: borrowing.status == 'reserved'
                      ? 'Cancel'
                      : null,
                  onSecondaryAction: borrowing.status == 'reserved'
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Cancel Reservation',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700)),
                              content: Text(
                                  'Are you sure? Your ₹${borrowing.depositAmount.toStringAsFixed(0)} deposit will be refunded.',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Keep',
                                      style: TextStyle(
                                          color: AppColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Cancel Reservation'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await reservationProvider
                                  .cancelReservation(borrowing);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Reservation cancelled. Deposit refunded.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      : null,
                );
              },
            ),
    );
  }
}
