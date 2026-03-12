import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class LeaderboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserProfile> _topReaders = [];
  bool _isLoading = false;

  List<UserProfile> get topReaders => _topReaders;
  bool get isLoading => _isLoading;

  LeaderboardProvider() {
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('booksBorrowed', descending: true)
          .limit(5)
          .get();

      _topReaders = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _fetchLeaderboard();
}
