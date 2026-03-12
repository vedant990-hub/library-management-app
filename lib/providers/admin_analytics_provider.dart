import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  Map<String, int> _monthlyBorrowings = {};
  Map<String, int> _monthlyUsers = {};
  Map<String, double> _monthlyFines = {};

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  int get totalUsers => _totalUsers;
  int get totalBooks => _totalBooks;
  int get activeBorrowings => _activeBorrowings;
  int get overdueBorrowings => _overdueBorrowings;
  double get totalFinesCollected => _totalFinesCollected;
  double get totalWalletBalance => _totalWalletBalance;
  double get totalLockedDeposits => _totalLockedDeposits;

  Map<String, int> get monthlyBorrowings => _monthlyBorrowings;
  Map<String, int> get monthlyUsers => _monthlyUsers;
  Map<String, double> get monthlyFines => _monthlyFines;

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final usersSnapshot = await _firestore.collection('users').get();
      _totalUsers = usersSnapshot.size;

      final booksSnapshot = await _firestore.collection('books').get();
      _totalBooks = booksSnapshot.size;

      final activeBorrowingsSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'borrowed')
          .get();
      _activeBorrowings = activeBorrowingsSnapshot.size;

      final overdueBorrowingsSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'overdue')
          .get();
      _overdueBorrowings = overdueBorrowingsSnapshot.size;

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

      await Future.wait([
        _fetchMonthlyBorrowings(),
        _fetchMonthlyUsers(),
        _fetchMonthlyFines(),
      ]);

    } catch (e) {
      if (kDebugMode) print('Error fetching admin analytics: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchMonthlyBorrowings() async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final resSnapshot = await _firestore
          .collection('reservations')
          .where('reservedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      Map<String, int> data = _initMonthlyMapInt();

      for (var doc in resSnapshot.docs) {
        final reservedAt = (doc.data()['reservedAt'] as Timestamp).toDate();
        final monthKey = DateFormat('MMM').format(reservedAt);
        if (data.containsKey(monthKey)) {
          data[monthKey] = data[monthKey]! + 1;
        }
      }
      _monthlyBorrowings = data;
    } catch (_) {
      _monthlyBorrowings = {};
    }
  }

  Future<void> _fetchMonthlyUsers() async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final usersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      Map<String, int> data = _initMonthlyMapInt();

      for (var doc in usersSnapshot.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        final monthKey = DateFormat('MMM').format(createdAt);
        if (data.containsKey(monthKey)) {
          data[monthKey] = data[monthKey]! + 1;
        }
      }
      _monthlyUsers = data;
    } catch (_) {
      _monthlyUsers = {};
    }
  }

  Future<void> _fetchMonthlyFines() async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      
      final transactionsSnapshot = await _firestore
          .collectionGroup('transactions')
          .where('type', isEqualTo: 'fine')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      Map<String, double> data = _initMonthlyMapDouble();

      for (var doc in transactionsSnapshot.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        final monthKey = DateFormat('MMM').format(createdAt);
        if (data.containsKey(monthKey)) {
          data[monthKey] = data[monthKey]! + amount;
        }
      }
      _monthlyFines = data;
    } catch (_) {
      _monthlyFines = {};
    }
  }

  Map<String, int> _initMonthlyMapInt() {
    final now = DateTime.now();
    Map<String, int> map = {};
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      map[DateFormat('MMM').format(monthDate)] = 0;
    }
    return map;
  }

  Map<String, double> _initMonthlyMapDouble() {
    final now = DateTime.now();
    Map<String, double> map = {};
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      map[DateFormat('MMM').format(monthDate)] = 0.0;
    }
    return map;
  }
}
