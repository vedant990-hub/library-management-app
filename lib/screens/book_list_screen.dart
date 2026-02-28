import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/library_provider.dart';
import '../widgets/book_card.dart';
import '../screens/book_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String _searchQuery = '';
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).fetchBooks();
    });
  }

  // Extract all unique genres from books
  List<String> _extractGenres(List<dynamic> books) {
    final genreSet = <String>{};
    for (final book in books) {
      genreSet.addAll(book.genres);
    }
    final sorted = genreSet.toList()..sort();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final allBooks = libraryProvider.allBooks;
    final allGenres = _extractGenres(allBooks);

    // Combined filter: genre first, then title search
    var filteredBooks = allBooks;

    if (_selectedGenre != null) {
      filteredBooks = filteredBooks
          .where((b) => b.genres.contains(_selectedGenre))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredBooks = filteredBooks
          .where((b) =>
              b.title.toLowerCase().contains(query) ||
              b.author.toLowerCase().contains(query))
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Discover Books',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded),
                if (_selectedGenre != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter by genre',
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (genre) => setState(() => _selectedGenre = genre),
            itemBuilder: (context) {
              return [
                PopupMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        _selectedGenre == null
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: _selectedGenre == null
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Text('All Genres',
                          style: GoogleFonts.poppins(
                            fontWeight: _selectedGenre == null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ...allGenres.map((genre) => PopupMenuItem<String?>(
                      value: genre,
                      child: Row(
                        children: [
                          Icon(
                            _selectedGenre == genre
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: _selectedGenre == genre
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 10),
                          Text(genre,
                              style: GoogleFonts.poppins(
                                fontWeight: _selectedGenre == genre
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              )),
                        ],
                      ),
                    )),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with subtle elevation
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by title or author...',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textTertiary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.textTertiary, size: 20),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          // Genre chips
          if (allGenres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: allGenres.length + 1, // +1 for "All" chip
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _GenreChip(
                        label: 'All',
                        isSelected: _selectedGenre == null,
                        onTap: () => setState(() => _selectedGenre = null),
                      );
                    }
                    final genre = allGenres[index - 1];
                    return _GenreChip(
                      label: genre,
                      isSelected: _selectedGenre == genre,
                      onTap: () => setState(() {
                        _selectedGenre =
                            _selectedGenre == genre ? null : genre;
                      }),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filteredBooks.length} ${filteredBooks.length == 1 ? 'book' : 'books'} found',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (_selectedGenre != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedGenre!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Books list
          Expanded(
            child: libraryProvider.isLoading
                ? _buildShimmerList()
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: filteredBooks.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () async {
                              await libraryProvider.fetchBooks();
                            },
                            color: AppColors.primary,
                            child: ListView.builder(
                              key: ValueKey(
                                  '${_selectedGenre}_$_searchQuery'),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 4, 20, 100),
                              itemCount: filteredBooks.length,
                              itemBuilder: (context, index) {
                                final book = filteredBooks[index];
                                return BookCard(
                                  book: book,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      FadeSlideRoute(
                                        page: BookDetailScreen(book: book),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : _selectedGenre != null
                    ? 'No books in "$_selectedGenre"'
                    : 'No Books Found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or genre',
            style: GoogleFonts.poppins(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 24,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Genre Chip ───
class _GenreChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.cardBorder,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
