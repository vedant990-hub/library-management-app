import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrowing.dart';
import 'auth_provider.dart';

class StatsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, int> _genreStats = {};
  Map<String, int> _monthlyBorrows = {};
  double _avgCompletionTime = 0;
  int _totalBooksRead = 0;
  bool _isLoading = false;

  Map<String, int> get genreStats => _genreStats;
  Map<String, int> get monthlyBorrows => _monthlyBorrows;
  double get avgCompletionTime => _avgCompletionTime;
  int get totalBooksRead => _totalBooksRead;
  bool get isLoading => _isLoading;

  Future<void> fetchStats(AppAuthProvider auth) async {
    final user = auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'returned')
          .get();

      final borrowings = snapshot.docs
          .map((doc) => Borrowing.fromMap(doc.data(), doc.id))
          .toList();

      _totalBooksRead = borrowings.length;
      
      // Calculate Genre Stats & Monthly Borrows
      final genres = <String, int>{};
      final monthly = <String, int>{};
      double totalDays = 0;

      // Batch fetch book details to get genres
      final bookIds = borrowings.map((b) => b.bookId).toSet().toList();
      final bookDocs = await Future.wait(
        bookIds.map((id) => _firestore.collection('books').doc(id).get())
      );
      final bookMap = {
        for (var doc in bookDocs) 
          if (doc.exists) doc.id: doc.data()?['genres'] as List<dynamic>? ?? []
      };

      for (var b in borrowings) {
        if (b.borrowedAt != null && b.returnedAt != null) {
          totalDays += b.returnedAt!.difference(b.borrowedAt!).inDays;
        }

        final month = _getMonthKey(b.returnedAt ?? b.reservedAt);
        monthly[month] = (monthly[month] ?? 0) + 1;

        final bookGenres = bookMap[b.bookId] ?? [];
        for (var g in bookGenres) {
          final genreName = g.toString();
          genres[genreName] = (genres[genreName] ?? 0) + 1;
        }
      }

      _genreStats = genres;
      _monthlyBorrows = monthly;
      _avgCompletionTime = borrowings.isNotEmpty ? totalDays / borrowings.length : 0;

    } catch (e) {
      debugPrint('Error fetching stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getMonthKey(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}
