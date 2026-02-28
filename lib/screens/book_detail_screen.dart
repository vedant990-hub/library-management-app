import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/library_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false).fetchReviews(widget.book.id);
    });
  }

  List<Color> _getBookGradient() {
    final gradients = [
      [const Color(0xFFE0E7FF), const Color(0xFFC7D2FE)],
      [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
      [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
      [const Color(0xFFFFE4E6), const Color(0xFFFDA4AF)],
      [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
      [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)],
    ];
    final idx = widget.book.title.hashCode.abs() % gradients.length;
    return gradients[idx];
  }

  Color _getBookIconColor() {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFF43F5E),
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
    ];
    final idx = widget.book.title.hashCode.abs() % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final authProvider = Provider.of<AppAuthProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);

    final currentBook = libraryProvider.allBooks.firstWhere(
      (b) => b.id == widget.book.id,
      orElse: () => widget.book,
    );
    final bool isAvailable = currentBook.availableCopies > 0;
    final gradient = _getBookGradient();
    final iconColor = _getBookIconColor();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Book Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book cover area
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: gradient[0],
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[1].withAlpha(80),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.auto_stories_rounded, size: 56, color: iconColor),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
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
                              currentBook.title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                height: 1.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentBook.author,
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            if (currentBook.avgRating > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${currentBook.avgRating}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    ' (${currentBook.totalReviews} reviews)',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.successLight : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Out of Stock',
                          style: GoogleFonts.poppins(
                            color: isAvailable ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Info chips
                  if (isAvailable)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${currentBook.availableCopies} copies available',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dive into the world of ${currentBook.title} written by the brilliant ${currentBook.author}. '
                    'This classic piece of literature explores profound themes and offers a compelling narrative that has captivated readers for generations. '
                    'Reserve your copy today to experience this timeless masterpiece.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Deposit info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Reservation requires ₹100 deposit (refundable on return)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (authProvider.currentUser != null && !authProvider.currentUser!.isAdmin)
                        TextButton.icon(
                          onPressed: () => _showReviewSheet(context, authProvider.currentUser!.uid, authProvider.currentUser!.name),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: Text('Write a Review', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (reviewProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (reviewProvider.reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'No reviews yet. Be the first to review!',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviewProvider.reviews.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final review = reviewProvider.reviews[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review.userName,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                if (authProvider.currentUser?.isAdmin == true)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    onPressed: () {
                                      reviewProvider.deleteReview(widget.book.id, review.userId);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review.comment,
                              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: ElevatedButton(
            onPressed: isAvailable
                ? () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Text('Reserving...', style: GoogleFonts.poppins()),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppColors.primary,
                      ),
                    );

                    try {
                      await reservationProvider.reserveBook(
                          currentBook, 100.0, 5.0);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                const Text('Book reserved successfully!'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
            ),
            child: Text(
              isAvailable ? 'Reserve Book — ₹100 Deposit' : 'Out of Stock',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, String userId, String userName) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Write a Review', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 32,
                          color: Colors.orange,
                        ),
                        onPressed: () => setState(() => rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLength: 150,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts about this book...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (commentController.text.trim().isEmpty) return;
                            setState(() => isSubmitting = true);
                            try {
                              await Provider.of<ReviewProvider>(context, listen: false).submitReview(
                                bookId: widget.book.id,
                                userId: userId,
                                userName: userName,
                                rating: rating,
                                comment: commentController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setState(() => isSubmitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Submit Review', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
