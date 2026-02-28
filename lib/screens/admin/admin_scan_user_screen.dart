import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/book.dart';
import '../../models/borrowing.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/library_provider.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

class AdminScanUserScreen extends StatefulWidget {
  final bool isActive;
  const AdminScanUserScreen({super.key, this.isActive = true});

  @override
  State<AdminScanUserScreen> createState() => _AdminScanUserScreenState();
}

class _AdminScanUserScreenState extends State<AdminScanUserScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.isActive) {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(AdminScanUserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.start();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _scanned = true);
    HapticFeedback.heavyImpact();

    _processQr(barcode.rawValue!);
  }

  Future<void> _processQr(String raw) async {
    setState(() => _isProcessing = true);

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final userId = data['userId'] as String?;
      if (userId == null) throw Exception('Invalid QR');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) throw Exception('User not found');

      final walletDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('default')
          .get();

      final walletBalance = walletDoc.exists
          ? (walletDoc.data()?['availableBalance'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      final borrowingsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['reserved', 'borrowed', 'overdue']).get();
      
      final activeBorrowingsList = borrowingsSnapshot.docs
          .map((d) => Borrowing.fromMap(d.data(), d.id))
          .toList();

      if (!mounted) return;

      _showUserDetails(
        context,
        userId: userId,
        userData: userDoc.data()!,
        walletBalance: walletBalance,
        activeBorrowings: activeBorrowingsList,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _scanned = false;
          _isProcessing = false;
        });
      }
    }
  }

  void _showUserDetails(
    BuildContext context, {
    required String userId,
    required Map<String, dynamic> userData,
    required double walletBalance,
    required List<Borrowing> activeBorrowings,
  }) {
    setState(() => _isProcessing = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _UserDetailSheet(
        userId: userId,
        userData: userData,
        walletBalance: walletBalance,
        activeBorrowings: activeBorrowings,
        onDone: () {
          Navigator.pop(ctx);
        },
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _scanned = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Scan User QR',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Dark overlay with cutout
          _buildScanOverlay(),
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.7;
        return Stack(
          children: [
            // Darkened background
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(140), BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(
                      decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut)),
                  Center(
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Any color — will be cut out
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corner borders
            Center(
              child: SizedBox(
                width: scanSize,
                height: scanSize,
                child: CustomPaint(
                  painter: _CornerPainter(),
                ),
              ),
            ),
            // Bottom instruction
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Point at user\'s Library ID QR',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Corner Painter ───
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.adminAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 30.0;
    const r = 12.0;

    // Top-left
    canvas.drawArc(
        Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14, 1.57, false, paint);
    canvas.drawLine(Offset(0, r), Offset(0, len), paint);
    canvas.drawLine(Offset(r, 0), Offset(len, 0), paint);

    // Top-right
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        -1.57, 1.57, false, paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);
    canvas.drawLine(
        Offset(size.width - r, 0), Offset(size.width - len, 0), paint);

    // Bottom-left
    canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        1.57, 1.57, false, paint);
    canvas.drawLine(
        Offset(0, size.height - r), Offset(0, size.height - len), paint);
    canvas.drawLine(
        Offset(r, size.height), Offset(len, size.height), paint);

    // Bottom-right
    canvas.drawArc(
        Rect.fromLTWH(
            size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        0,
        1.57,
        false,
        paint);
    canvas.drawLine(Offset(size.width, size.height - r),
        Offset(size.width, size.height - len), paint);
    canvas.drawLine(Offset(size.width - r, size.height),
        Offset(size.width - len, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── User Detail Bottom Sheet ───
class _UserDetailSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final double walletBalance;
  final List<Borrowing> activeBorrowings;
  final VoidCallback onDone;

  const _UserDetailSheet({
    required this.userId,
    required this.userData,
    required this.walletBalance,
    required this.activeBorrowings,
    required this.onDone,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _isBorrowing = false;
  Book? _selectedBook;
  List<Book> _availableBooks = [];
  bool _loadingBooks = true;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('books').get();
      setState(() {
        _availableBooks = snapshot.docs
            .map((doc) => Book.fromMap(doc.data(), doc.id))
            .where((b) => b.availableCopies > 0)
            .toList();
        _loadingBooks = false;
      });
    } catch (_) {
      setState(() => _loadingBooks = false);
    }
  }

  Future<void> _borrowBook() async {
    if (_selectedBook == null) return;
    setState(() => _isBorrowing = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final firestore = FirebaseFirestore.instance;
      const depositAmount = 100.0;
      const finePerDay = 5.0;

      await firestore.runTransaction((transaction) async {
        final walletRef = firestore
            .collection('users')
            .doc(widget.userId)
            .collection('wallet')
            .doc('default');
        final bookRef =
            firestore.collection('books').doc(_selectedBook!.id);
        final reservationRef = firestore.collection('reservations').doc();

        final walletDoc = await transaction.get(walletRef);
        final bookDoc = await transaction.get(bookRef);

        final balance =
            (walletDoc.data()?['availableBalance'] as num?)?.toDouble() ?? 0.0;
        if (balance < depositAmount) {
          throw Exception('User has insufficient wallet balance');
        }

        final copies = bookDoc.data()?['availableCopies'] as int? ?? 0;
        if (copies <= 0) throw Exception('Book not available');

        final now = FieldValue.serverTimestamp();

        transaction.update(walletRef, {
          'availableBalance': FieldValue.increment(-depositAmount),
          'lockedDeposit': FieldValue.increment(depositAmount),
          'updatedAt': now,
        });

        transaction.update(bookRef, {
          'availableCopies': FieldValue.increment(-1),
        });

        transaction.set(reservationRef, {
          'userId': widget.userId,
          'bookId': _selectedBook!.id,
          'reservedAt': now,
          'expiresAt':
              Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
          'borrowedAt': now,
          'dueAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 14))),
          'returnedAt': null,
          'depositAmount': depositAmount,
          'fineAmount': 0.0,
          'finePerDay': finePerDay,
          'status': 'borrowed',
        });
      });

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'Borrowed "${_selectedBook!.title}" for ${widget.userData['name']}')),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onDone();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Borrow failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isBorrowing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
          // User info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (widget.userData['name'] as String?)?.isNotEmpty == true
                        ? (widget.userData['name'] as String)[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userData['name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    Text(widget.userData['email'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.account_balance_wallet_rounded,
                label: '₹${widget.walletBalance.toStringAsFixed(0)}',
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.menu_book_rounded,
                label: '${widget.activeBorrowings.length} active',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text('Borrow a Book',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 12),
          // Book dropdown
          _loadingBooks
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<Book>(
                  initialValue: _selectedBook,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select a book',
                    hintStyle: GoogleFonts.poppins(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  items: _availableBooks.map((book) {
                    return DropdownMenuItem<Book>(
                      value: book,
                      child: Text('${book.title} (${book.availableCopies})',
                          style: GoogleFonts.poppins(fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedBook = v),
                ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                _selectedBook == null || _isBorrowing ? null : _borrowBook,
            icon: _isBorrowing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.book_rounded, size: 20),
            label: Text(
              _isBorrowing ? 'Borrowing...' : 'Borrow on Behalf',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (widget.activeBorrowings.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text('Active Borrowings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.activeBorrowings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final borrowing = widget.activeBorrowings[idx];
                final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
                final book = libraryProvider.allBooks.firstWhere(
                  (b) => b.id == borrowing.bookId,
                  orElse: () => Book(id: '', title: 'Unknown Book', author: '', availableCopies: 0, genres: const [], avgRating: 0.0, totalReviews: 0),
                );

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 24, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              borrowing.status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: borrowing.status == 'overdue' ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Return Book', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                              content: Text('Confirm return of "${book.title}" on behalf of the user?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Return')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await Provider.of<ReservationProvider>(context, listen: false).returnBook(borrowing);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Book returned!'), backgroundColor: AppColors.success),
                                );
                                widget.onDone(); // close sheet to refresh scanning
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to return: $e'), backgroundColor: AppColors.error),
                                );
                              }
                            }
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: Text('Return', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}
