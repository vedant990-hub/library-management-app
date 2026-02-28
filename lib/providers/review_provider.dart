import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Review> _reviews = [];
  bool _isLoading = false;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> fetchReviews(String bookId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _reviews = snapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitReview({
    required String bookId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    try {
      final bookRef = _firestore.collection('books').doc(bookId);
      final reviewRef = bookRef.collection('reviews').doc(userId);

      // Save review (overwrite if exists)
      await reviewRef.set({
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Recalculate avgRating and totalReviews
      final allReviews = await bookRef.collection('reviews').get();
      final totalReviews = allReviews.docs.length;
      double totalRating = 0;
      for (final doc in allReviews.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      final avgRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      await bookRef.update({
        'avgRating': double.parse(avgRating.toStringAsFixed(1)),
        'totalReviews': totalReviews,
      });

      // Refresh local reviews
      await fetchReviews(bookId);
    } catch (e) {
      if (kDebugMode) print('Error submitting review: $e');
      rethrow;
    }
  }

  Future<void> deleteReview(String bookId, String userId) async {
    try {
      final bookRef = _firestore.collection('books').doc(bookId);
      await bookRef.collection('reviews').doc(userId).delete();

      // Recalculate
      final allReviews = await bookRef.collection('reviews').get();
      final totalReviews = allReviews.docs.length;
      double totalRating = 0;
      for (final doc in allReviews.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      final avgRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      await bookRef.update({
        'avgRating': double.parse(avgRating.toStringAsFixed(1)),
        'totalReviews': totalReviews,
      });

      await fetchReviews(bookId);
    } catch (e) {
      if (kDebugMode) print('Error deleting review: $e');
      rethrow;
    }
  }
}
