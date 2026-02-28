import 'package:cloud_firestore/cloud_firestore.dart';

class Borrowing {
  final String id;
  final String userId;
  final String bookId;
  final DateTime reservedAt;
  final DateTime expiresAt;    // Time allowed to pick up the book
  final DateTime? borrowedAt;  // When the user actually took the book
  final DateTime? dueAt;       // Deadline to return the book
  final DateTime? returnedAt;  // When the user brought it back
  final double depositAmount;
  final double fineAmount;
  final double finePerDay;
  final String status; // "reserved" | "borrowed" | "returned" | "overdue" | "expired" | "lost"

  Borrowing({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.reservedAt,
    required this.expiresAt,
    this.borrowedAt,
    this.dueAt,
    this.returnedAt,
    required this.depositAmount,
    required this.fineAmount,
    required this.finePerDay,
    required this.status,
  });

  factory Borrowing.fromMap(Map<String, dynamic> map, String documentId) {
    return Borrowing(
      id: documentId,
      userId: map['userId'] ?? '',
      bookId: map['bookId'] ?? '',
      reservedAt: (map['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      borrowedAt: (map['borrowedAt'] as Timestamp?)?.toDate(),
      dueAt: (map['dueAt'] as Timestamp?)?.toDate(),
      returnedAt: (map['returnedAt'] as Timestamp?)?.toDate(),
      depositAmount: (map['depositAmount'] ?? 0).toDouble(),
      fineAmount: (map['fineAmount'] ?? 0).toDouble(),
      finePerDay: (map['finePerDay'] ?? 0).toDouble(),
      status: map['status'] ?? 'reserved',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'reservedAt': Timestamp.fromDate(reservedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'borrowedAt': borrowedAt != null ? Timestamp.fromDate(borrowedAt!) : null,
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'depositAmount': depositAmount,
      'fineAmount': fineAmount,
      'finePerDay': finePerDay,
      'status': status,
    };
  }

  Borrowing copyWith({
    String? id,
    String? userId,
    String? bookId,
    DateTime? reservedAt,
    DateTime? expiresAt,
    DateTime? borrowedAt,
    DateTime? dueAt,
    DateTime? returnedAt,
    double? depositAmount,
    double? fineAmount,
    double? finePerDay,
    String? status,
  }) {
    return Borrowing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      reservedAt: reservedAt ?? this.reservedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      borrowedAt: borrowedAt ?? this.borrowedAt,
      dueAt: dueAt ?? this.dueAt,
      returnedAt: returnedAt ?? this.returnedAt,
      depositAmount: depositAmount ?? this.depositAmount,
      fineAmount: fineAmount ?? this.fineAmount,
      finePerDay: finePerDay ?? this.finePerDay,
      status: status ?? this.status,
    );
  }
}
