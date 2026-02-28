import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int booksBorrowed;
  final int readingStreak;
  final int onTimeReturns;
  final List<String> badges;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
    this.booksBorrowed = 0,
    this.readingStreak = 0,
    this.onTimeReturns = 0,
    this.badges = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      booksBorrowed: map['booksBorrowed'] as int? ?? 0,
      readingStreak: map['readingStreak'] as int? ?? 0,
      onTimeReturns: map['onTimeReturns'] as int? ?? 0,
      badges: (map['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'booksBorrowed': booksBorrowed,
      'readingStreak': readingStreak,
      'onTimeReturns': onTimeReturns,
      'badges': badges,
    };
  }

  bool get isAdmin => role == 'admin';

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? booksBorrowed,
    int? readingStreak,
    int? onTimeReturns,
    List<String>? badges,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      booksBorrowed: booksBorrowed ?? this.booksBorrowed,
      readingStreak: readingStreak ?? this.readingStreak,
      onTimeReturns: onTimeReturns ?? this.onTimeReturns,
      badges: badges ?? this.badges,
    );
  }
}
