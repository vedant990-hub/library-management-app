import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'auth_provider.dart';

class WalletProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AppAuthProvider _authProvider;
  StreamSubscription<DocumentSnapshot>? _walletSubscription;

  bool _isLoading = false;
  bool _disposed = false;
  
  double _availableBalance = 0.0;
  double _lockedDeposit = 0.0;
  double _totalFinesPaid = 0.0;

  bool get isLoading => _isLoading;

  double get availableBalance => _availableBalance;
  double get lockedDeposit => _lockedDeposit;
  double get totalFinesPaid => _totalFinesPaid;
  double get totalBalance => _availableBalance + _lockedDeposit;

  String? _uid;

  WalletProvider(this._authProvider) {
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
    _walletSubscription?.cancel();
    final user = _authProvider.currentUser;
    // Admins don't have wallets in this system
    if (user != null && !user.isAdmin) {
      _isLoading = true;
      _availableBalance = 0.0;
      _lockedDeposit = 0.0;
      _totalFinesPaid = 0.0;
      notifyListeners();

      _walletSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallet')
          .doc('default')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          _availableBalance = (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
          _lockedDeposit = (data['lockedDeposit'] as num?)?.toDouble() ?? 0.0;
          _totalFinesPaid = (data['totalFinesPaid'] as num?)?.toDouble() ?? 0.0;
        } else {
          _availableBalance = 0.0;
          _lockedDeposit = 0.0;
          _totalFinesPaid = 0.0;
        }
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) print('Error listening to wallet: $e');
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _resetBalances();
    }
  }

  void _resetBalances() {
    _availableBalance = 0.0;
    _lockedDeposit = 0.0;
    _totalFinesPaid = 0.0;
    notifyListeners();
  }

  static const double maxBalance = 500.0;
  static const double bookDeposit = 100.0;

  double get maxAddable => (maxBalance - totalBalance).clamp(0.0, maxBalance);

  Future<void> addMoney(double amount) async {
    final user = _authProvider.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (user.isAdmin) throw Exception('Admins cannot have wallets');
    if (amount <= 0) throw Exception('Amount must be positive');

    _isLoading = true;
    notifyListeners();

    try {
      final walletRef = _firestore.collection('users').doc(user.uid).collection('wallet').doc('default');
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(walletRef);
        if (!doc.exists) {
          if (amount > maxBalance) {
            throw Exception('Maximum wallet balance is ₹${maxBalance.toStringAsFixed(0)}');
          }
          transaction.set(walletRef, {
            'availableBalance': amount,
            'lockedDeposit': 0.0,
            'totalFinesPaid': 0.0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final data = doc.data()!;
          final currentAvailable = (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
          final currentLocked = (data['lockedDeposit'] as num?)?.toDouble() ?? 0.0;
          final currentTotal = currentAvailable + currentLocked;

          if (currentTotal + amount > maxBalance) {
            final canAdd = maxBalance - currentTotal;
            throw Exception(
              canAdd <= 0
                  ? 'Wallet is full (₹${maxBalance.toStringAsFixed(0)} limit)'
                  : 'Can only add ₹${canAdd.toStringAsFixed(0)} more (₹${maxBalance.toStringAsFixed(0)} limit)',
            );
          }

          transaction.update(walletRef, {
            'availableBalance': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      // Listener will instantly update local state safely.
    } catch (e) {
      if (kDebugMode) print('Error adding money: $e');
      rethrow;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _walletSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
