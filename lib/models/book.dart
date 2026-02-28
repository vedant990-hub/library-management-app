class Book {
  final String id;
  final String title;
  final String author;
  final int availableCopies;
  final List<String> genres;
  final double avgRating;
  final int totalReviews;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.availableCopies,
    this.genres = const [],
    this.avgRating = 0.0,
    this.totalReviews = 0,
  });

  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      id: documentId,
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      availableCopies: map['availableCopies'] as int? ?? 0,
      genres: (map['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'availableCopies': availableCopies,
      'genres': genres,
      'avgRating': avgRating,
      'totalReviews': totalReviews,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? availableCopies,
    List<String>? genres,
    double? avgRating,
    int? totalReviews,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      availableCopies: availableCopies ?? this.availableCopies,
      genres: genres ?? this.genres,
      avgRating: avgRating ?? this.avgRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
