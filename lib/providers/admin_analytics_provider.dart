import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _errorMessage = '';

  int _totalUsers = 0;
  int _totalBooks = 0;
  int _activeBorrowings = 0;
  int _overdueBorrowings = 0;
  double _totalFinesCollected = 0.0;
  double _totalWalletBalance = 0.0;
  double _totalLockedDeposits = 0.0;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  int get totalUsers => _totalUsers;
  int get totalBooks => _totalBooks;
  int get activeBorrowings => _activeBorrowings;
  int get overdueBorrowings => _overdueBorrowings;
  double get totalFinesCollected => _totalFinesCollected;
  double get totalWalletBalance => _totalWalletBalance;
  double get totalLockedDeposits => _totalLockedDeposits;

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Total Users
      final usersCountSnapshot = await _firestore.collection('users').count().get();
      _totalUsers = usersCountSnapshot.count ?? 0;

      // 2. Total Books
      final booksCountSnapshot = await _firestore.collection('books').count().get();
      _totalBooks = booksCountSnapshot.count ?? 0;

      // 3. Active Borrowings
      final activeBorrowingsSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      _activeBorrowings = activeBorrowingsSnapshot.count ?? 0;

      // 4. Overdue Borrowings
      final overdueBorrowingsSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'overdue')
          .count()
          .get();
      _overdueBorrowings = overdueBorrowingsSnapshot.count ?? 0;

      // 5. Aggregate Wallet & Fine Data
      double finesSum = 0.0;
      double walletSum = 0.0;
      double lockedSum = 0.0;

      final walletsSnapshot = await _firestore.collectionGroup('wallet').get();
      for (var doc in walletsSnapshot.docs) {
        final data = doc.data();
        finesSum += (data['totalFinesPaid'] as num?)?.toDouble() ?? 0.0;
        walletSum += (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
        lockedSum += (data['lockedDeposit'] as num?)?.toDouble() ?? 0.0;
      }
      
      _totalFinesCollected = finesSum;
      _totalWalletBalance = walletSum;
      _totalLockedDeposits = lockedSum;

    } catch (e) {
      if (kDebugMode) {
        print('Error fetching admin analytics: $e');
      }
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
