import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/book.dart';
import '../models/borrowing.dart';
import '../theme/app_theme.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;
  final Borrowing? borrowing;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.borrowing,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionLabel,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.borrowing != null) {
      _calculateTimeLeft();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft());
    }
  }

  @override
  void didUpdateWidget(BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.borrowing != oldWidget.borrowing) {
      _calculateTimeLeft();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    if (widget.borrowing == null) return;

    final b = widget.borrowing!;
    DateTime targetTime;

    if (b.status == 'reserved') {
      targetTime = b.expiresAt;
    } else if (b.status == 'borrowed') {
      targetTime = b.dueAt ?? DateTime.now();
    } else {
      setState(() => _timeLeft = Duration.zero);
      return;
    }

    final now = DateTime.now();
    setState(() {
      _timeLeft = targetTime.isAfter(now) ? targetTime.difference(now) : Duration.zero;
    });
  }

  // Color based on time urgency
  Color _getTimerColor() {
    if (_timeLeft.inHours < 2) return AppColors.error;
    if (_timeLeft.inHours < 24) return AppColors.warning;
    return AppColors.success;
  }

  Color _getTimerBgColor() {
    if (_timeLeft.inHours < 2) return AppColors.errorLight;
    if (_timeLeft.inHours < 24) return AppColors.warningLight;
    return AppColors.successLight;
  }

  Widget _buildTimerBadge() {
    if (widget.borrowing == null) return const SizedBox.shrink();

    final b = widget.borrowing!;
    if (b.status == 'overdue') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
            const SizedBox(width: 6),
            Text(
              'OVERDUE',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (b.status == 'reserved' || b.status == 'borrowed') {
      final timerColor = _getTimerColor();
      final timerBg = _getTimerBgColor();

      String timeStr;
      if (_timeLeft.inDays > 0) {
        timeStr = '${_timeLeft.inDays}d ${_timeLeft.inHours % 24}h';
      } else {
        timeStr =
            '${_timeLeft.inHours.toString().padLeft(2, '0')}:${(_timeLeft.inMinutes % 60).toString().padLeft(2, '0')}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';
      }

      String prefix = b.status == 'reserved' ? 'Expires in ' : 'Due in ';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: timerBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: timerColor),
            const SizedBox(width: 6),
            Text(
              '$prefix$timeStr',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: timerColor,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Generate consistent color from book title
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
    final bool isAvailable = widget.book.availableCopies > 0;
    final colors = _getBookGradient();

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover
                  Container(
                    width: 68,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 28,
                        color: _getBookIconColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.book.author,
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.book.genres.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: widget.book.genres.take(2).map((genre) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  genre,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (widget.book.avgRating > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.book.avgRating}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),

                        // Status Badge
                        if (widget.borrowing != null)
                          _buildTimerBadge()
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isAvailable ? AppColors.successLight : AppColors.errorLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 14,
                                  color: isAvailable ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isAvailable ? 'Available (${widget.book.availableCopies})' : 'Out of Stock',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: isAvailable ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Actions
              if (widget.onPrimaryAction != null || widget.onSecondaryAction != null) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.onSecondaryAction != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onSecondaryAction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withAlpha(80)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.secondaryActionLabel ?? 'Cancel',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    if (widget.onSecondaryAction != null && widget.onPrimaryAction != null)
                      const SizedBox(width: 12),
                    if (widget.onPrimaryAction != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onPrimaryAction,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            widget.primaryActionLabel ?? 'Confirm',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
