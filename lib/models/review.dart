import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    return Review(
      userId: docId,
      userName: map['userName'] as String? ?? 'Anonymous',
      rating: map['rating'] as int? ?? 0,
      comment: map['comment'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
