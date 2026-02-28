import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../models/book.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_transitions.dart';
import 'add_edit_book_screen.dart';
import 'admin_qr_screen.dart';

class AdminBookListScreen extends StatefulWidget {
  const AdminBookListScreen({super.key});

  @override
  State<AdminBookListScreen> createState() => _AdminBookListScreenState();
}

class _AdminBookListScreenState extends State<AdminBookListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).fetchBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final books = libraryProvider.allBooks;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: libraryProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.adminAccent))
          : RefreshIndicator(
              onRefresh: () async {
                await libraryProvider.fetchBooks();
              },
              color: AppColors.adminAccent,
              child: books.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No books yet',
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text('Tap + to add your first book',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textTertiary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _AdminBookCard(
                          book: book,
                          onEdit: () {
                            Navigator.push(
                              context,
                              FadeSlideRoute(
                                  page: AddEditBookScreen(book: book)),
                            );
                          },
                          onDelete: () =>
                              _showDeleteDialog(context, book, libraryProvider),
                          onQr: () {
                            Navigator.push(
                              context,
                              FadeSlideRoute(page: AdminQrScreen(book: book)),
                            );
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            FadeSlideRoute(page: const AddEditBookScreen()),
          );
        },
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Book',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, Book book, LibraryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Book',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${book.title}"?',
            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteBook(book.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          const Text('Book deleted'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AdminBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onQr;

  const _AdminBookCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    required this.onQr,
  });

  List<Color> _getBookGradient() {
    final gradients = [
      [const Color(0xFFE0E7FF), const Color(0xFFC7D2FE)],
      [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
      [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
      [const Color(0xFFFFE4E6), const Color(0xFFFDA4AF)],
      [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
      [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)],
    ];
    return gradients[book.title.hashCode.abs() % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getBookGradient();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.auto_stories_rounded,
                      size: 22, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: book.availableCopies > 0
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${book.availableCopies} available',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: book.availableCopies > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SmallActionButton(
                icon: Icons.qr_code_rounded,
                color: AppColors.primary,
                bgColor: AppColors.primaryLight,
                onTap: onQr,
                tooltip: 'Generate QR',
              ),
              const SizedBox(width: 8),
              _SmallActionButton(
                icon: Icons.edit_rounded,
                color: AppColors.adminAccent,
                bgColor: AppColors.adminAccent.withAlpha(15),
                onTap: onEdit,
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              _SmallActionButton(
                icon: Icons.delete_rounded,
                color: AppColors.error,
                bgColor: AppColors.errorLight,
                onTap: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final String tooltip;

  const _SmallActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
