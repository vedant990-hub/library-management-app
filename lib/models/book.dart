class Book {
  final String id;
  final String title;
  final String author;
  final int availableCopies;
  final String description;
  final List<String> genres;
  final double avgRating;
  final int totalReviews;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.availableCopies,
    this.description = '',
    this.genres = const [],
    this.avgRating = 0.0,
    this.totalReviews = 0,
  });

  String get coverUrl {
    final t = title.toLowerCase();
    if (t.contains('start with why') || t.contains('ghajini') || t.contains('gajni')) {
      return "";
    }
    return "https://covers.openlibrary.org/b/title/${Uri.encodeComponent(title)}-L.jpg";
  }
  String get genre => genres.isNotEmpty ? genres.first : '';

  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      id: documentId,
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      availableCopies: map['availableCopies'] as int? ?? 0,
      description: map['description'] as String? ?? '',
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
      'description': description,
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
    String? description,
    List<String>? genres,
    double? avgRating,
    int? totalReviews,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      availableCopies: availableCopies ?? this.availableCopies,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      avgRating: avgRating ?? this.avgRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
