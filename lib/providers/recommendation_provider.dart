import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../models/borrowing.dart';
import 'auth_provider.dart';
import 'library_provider.dart';

class RecommendationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Book> _recommendedBooks = [];
  bool _isLoading = false;

  List<Book> get recommendedBooks => _recommendedBooks;
  bool get isLoading => _isLoading;

  Future<void> updateRecommendations(AppAuthProvider auth, LibraryProvider library) async {
    final user = auth.currentUser;
    if (user == null || library.allBooks.isEmpty) {
      _recommendedBooks = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch user's borrowing history (limited to returned/borrowed)
      final historySnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['borrowed', 'returned', 'overdue'])
          .get();

      final history = historySnapshot.docs
          .map((doc) => Borrowing.fromMap(doc.data(), doc.id))
          .toList();

      if (history.isEmpty) {
        // If no history, suggest top rated or diverse books
        _recommendedBooks = library.allBooks.take(5).toList();
      } else {
        // 2. Analyze favorite genres
        final genreCounts = <String, int>{};
        for (var borrowing in history) {
          // Find the book in library to get its genres
          final book = library.allBooks.firstWhere(
            (b) => b.id == borrowing.bookId,
            orElse: () => Book(id: '', title: '', author: '', availableCopies: 0),
          );
          
          for (var genre in book.genres) {
            genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
          }
        }

        if (genreCounts.isEmpty) {
          _recommendedBooks = library.allBooks.take(5).toList();
        } else {
          // Get top 2 genres
          final sortedGenres = genreCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final favoriteGenres = sortedGenres.take(2).map((e) => e.key).toList();

          // 3. Recommend books from these genres that user hasn't borrowed
          final borrowedBookIds = history.map((e) => e.bookId).toSet();
          
          _recommendedBooks = library.allBooks
              .where((book) => 
                  !borrowedBookIds.contains(book.id) && 
                  book.genres.any((g) => favoriteGenres.contains(g)))
              .take(10)
              .toList();
          
          // If still empty, just take some from library
          if (_recommendedBooks.isEmpty) {
            _recommendedBooks = library.allBooks
                .where((book) => !borrowedBookIds.contains(book.id))
                .take(5)
                .toList();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error calculating recommendations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
