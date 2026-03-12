import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/book.dart';
import '../models/borrowing.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class ReservationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AppAuthProvider _authProvider;
  StreamSubscription<QuerySnapshot>? _reservationSubscription;

  bool _isLoading = false;
  bool _disposed = false;
  List<Borrowing> _activeReservations = [];

  bool get isLoading => _isLoading;
  List<Borrowing> get activeReservations => _activeReservations;

  String? _uid;

  ReservationProvider(this._authProvider) {
    _uid = _authProvider.currentUser?.uid;
    _initListener();
  }

  void update(AppAuthProvider authProvider) {
    _authProvider = authProvider;
    if (_uid != authProvider.currentUser?.uid) {
      _uid = authProvider.currentUser?.uid;
      _initListener();
    }
  }

  void _initListener() {
    _reservationSubscription?.cancel();
    final user = _authProvider.currentUser;
    if (user != null) {
      _isLoading = true;
      
      _reservationSubscription = _firestore
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['reserved', 'borrowed', 'overdue'])
          .snapshots()
          .listen((snapshot) {
        _activeReservations = snapshot.docs
            .map((doc) => Borrowing.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) print('Error listening to active reservations: $e');
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _activeReservations = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reserveBook(Book book, double depositAmount, double finePerDay) async {
    final user = _authProvider.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (book.availableCopies <= 0) throw Exception('Book not available');

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final walletRef = userRef.collection('wallet').doc('default');
        final bookRef = _firestore.collection('books').doc(book.id);
        final reservationRef = _firestore.collection('reservations').doc();

        final userDoc = await transaction.get(userRef);
        final walletDoc = await transaction.get(walletRef);
        final bookDoc = await transaction.get(bookRef);

        if (!userDoc.exists) throw Exception('User not found');
        if (!bookDoc.exists) throw Exception('Book not found');
        if (userDoc.data()?['isBlocked'] == true) throw Exception('Your account is blocked. You cannot borrow books.');

        final currentAvailableCopies = bookDoc.data()?['availableCopies'] as int? ?? 0;
        if (currentAvailableCopies <= 0) throw Exception('Book not available');

        final currentWalletBalance = (walletDoc.data()?['availableBalance'] as num?)?.toDouble() ?? 0.0;
        
        if (currentWalletBalance < depositAmount) throw Exception('Insufficient wallet balance for deposit');

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
          'userId': user.uid,
          'bookId': book.id,
          'bookTitle': book.title,
          'reservedAt': now,
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
          'borrowedAt': null,
          'dueAt': null,
          'returnedAt': null,
          'depositAmount': depositAmount,
          'fineAmount': 0.0,
          'finePerDay': finePerDay,
          'status': 'reserved',
        });

        _logActivity(transaction, user.name, 'reserved', book.title);
      });
    } catch (e) {
      if (kDebugMode) print('Error reserving book: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmBorrow(Borrowing reservation) async {
    _isLoading = true;
    notifyListeners();

    try {
      final reservationRef = _firestore.collection('reservations').doc(reservation.id);
      final dueAt = DateTime.now().add(const Duration(days: 7));

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(reservationRef);
        if (!doc.exists) throw Exception('Reservation not found');
        
        if (doc.data()?['status'] != 'reserved') {
          throw Exception('Can only confirm borrow for reserved books');
        }

        transaction.update(reservationRef, {
          'status': 'borrowed',
          'borrowedAt': FieldValue.serverTimestamp(),
          'dueAt': Timestamp.fromDate(dueAt),
        });

        final user = _authProvider.currentUser;
        _logActivity(transaction, user?.name ?? "User", 'borrowed', reservation.bookTitle);
      });

      // Schedule notification after transaction succeeds
      try {
        await NotificationService().scheduleDueReminder(
          id: reservation.id.hashCode,
          title: 'Return Reminder 📚',
          body: 'Your book "${reservation.bookTitle}" is due tomorrow.',
          scheduledDate: dueAt,
        );
      } catch (ne) {
        if (kDebugMode) print('Warning: Failed to schedule notification: $ne');
        // Do not rethrow; we want the borrow to remain confirmed in FS
      }

    } catch (e) {
      if (kDebugMode) print('Error confirming borrow: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelReservation(Borrowing reservation) async {
    final user = _authProvider.currentUser;
    if (user == null) throw Exception('User not logged in');

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(reservation.userId);
        final walletRef = userRef.collection('wallet').doc('default');
        final bookRef = _firestore.collection('books').doc(reservation.bookId);
        final reservationRef = _firestore.collection('reservations').doc(reservation.id);

        final reservationDoc = await transaction.get(reservationRef);
        if (!reservationDoc.exists) throw Exception('Reservation not found');
        
        final currentStatus = reservationDoc.data()?['status'];
        if (currentStatus != 'reserved') {
            throw Exception('Can only cancel a book that is in reserved state');
        }

        final depositAmount = (reservationDoc.data()?['depositAmount'] as num).toDouble();

        transaction.update(walletRef, {
          'availableBalance': FieldValue.increment(depositAmount),
          'lockedDeposit': FieldValue.increment(-depositAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(bookRef, {
          'availableCopies': FieldValue.increment(1),
        });

        transaction.update(reservationRef, {
          'status': 'returned',
          'returnedAt': FieldValue.serverTimestamp(),
        });

        _logActivity(transaction, user.name, 'cancelled', reservation.bookTitle);
      });
    } catch (e) {
      if (kDebugMode) print('Error cancelling reservation: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> returnBook(Borrowing reservation) async {
    final user = _authProvider.currentUser;
    if (user == null) throw Exception('User not logged in');

    if (reservation.status == 'reserved') {
      return cancelReservation(reservation);
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(reservation.userId);
        final walletRef = userRef.collection('wallet').doc('default');
        final bookRef = _firestore.collection('books').doc(reservation.bookId);
        final reservationRef = _firestore.collection('reservations').doc(reservation.id);

        final reservationDoc = await transaction.get(reservationRef);
        if (!reservationDoc.exists) throw Exception('Reservation record not found');
        
        final userDoc = await transaction.get(userRef);
        
        final currentStatus = reservationDoc.data()?['status'];
        if (currentStatus != 'borrowed' && currentStatus != 'overdue') {
            throw Exception('Cannot return a book with this status');
        }

        final dueAt = (reservationDoc.data()?['dueAt'] as Timestamp).toDate();
        final depositAmount = (reservationDoc.data()?['depositAmount'] as num).toDouble();
        final finePerDay = (reservationDoc.data()?['finePerDay'] as num).toDouble();

        final now = DateTime.now();
        double fine = 0.0;
        
        if (now.isAfter(dueAt)) {
          final calculatedLateDays = now.difference(dueAt).inHours > 0 ? (now.difference(dueAt).inHours / 24).ceil() : 0;
          fine = calculatedLateDays * finePerDay;
        }

        double refund = depositAmount - fine;
        if (refund < 0) refund = 0;

        transaction.update(walletRef, {
          'availableBalance': FieldValue.increment(refund),
          'lockedDeposit': FieldValue.increment(-depositAmount),
          'totalFinesPaid': FieldValue.increment(fine),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(bookRef, {
          'availableCopies': FieldValue.increment(1),
        });

        transaction.update(reservationRef, {
          'status': 'returned',
          'returnedAt': FieldValue.serverTimestamp(),
          'fineAmount': fine, 
        });

        final userName = userDoc.data()?['name'] ?? "User";
        _logActivity(transaction, userName, 'returned', reservation.bookTitle);

        final userData = userDoc.data() ?? {};
        final booksBorrowed = (userData['booksBorrowed'] as int? ?? 0) + 1;
        int readingStreak = userData['readingStreak'] as int? ?? 0;
        int onTimeReturns = userData['onTimeReturns'] as int? ?? 0;
        List<String> badges = List<String>.from(userData['badges'] ?? []);

        final isOnTime = !now.isAfter(dueAt);
        if (isOnTime) {
          readingStreak++;
          onTimeReturns++;
        } else {
          readingStreak = 0;
        }

        if (booksBorrowed >= 5 && !badges.contains('Bookworm')) badges.add('Bookworm');
        if (onTimeReturns >= 3 && !badges.contains('Early Bird')) badges.add('Early Bird');
        if (readingStreak >= 5 && !badges.contains('Consistent Reader')) badges.add('Consistent Reader');

        transaction.update(userRef, {
          'booksBorrowed': booksBorrowed,
          'readingStreak': readingStreak,
          'onTimeReturns': onTimeReturns,
          'badges': badges,
        });
      });

      // Cancel notification after transaction succeeds
      try {
        await NotificationService().cancelNotification(reservation.id.hashCode);
      } catch (ne) {
        if (kDebugMode) print('Warning: Failed to cancel notification: $ne');
      }

    } catch (e) {
      if (kDebugMode) print('Error returning book: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reservationSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void _logActivity(Transaction transaction, String userName, String actionType, String bookTitle) {
    final activityRef = _firestore.collection('activity_logs').doc();
    transaction.set(activityRef, {
      'userName': userName,
      'actionType': actionType,
      'bookTitle': bookTitle,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
