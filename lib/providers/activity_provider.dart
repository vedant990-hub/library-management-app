import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String userName;
  final String actionType;
  final String bookTitle;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userName,
    required this.actionType,
    required this.bookTitle,
    required this.timestamp,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      userName: map['userName'] ?? 'Someone',
      actionType: map['actionType'] ?? 'activity',
      bookTitle: map['bookTitle'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ActivityProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ActivityLog> _activities = [];
  bool _isLoading = false;

  List<ActivityLog> get activities => _activities;
  bool get isLoading => _isLoading;

  ActivityProvider() {
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    _firestore
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      _activities = snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }
}
