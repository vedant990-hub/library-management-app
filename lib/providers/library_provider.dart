import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class LibraryProvider with ChangeNotifier {
  List<Book> _allBooks = [];
  final List<Book> _reservedBooks = [];
  bool _isLoading = false;

  List<Book> get allBooks => _allBooks;
  List<Book> get reservedBooks => _reservedBooks;
  bool get isLoading => _isLoading;

  LibraryProvider() {
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance.collection('books').get();
      _allBooks = snapshot.docs
          .map((doc) => Book.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching books: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reserveBook(Book book) async {
    if (book.availableCopies > 0) {
      try {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(book.id)
            .update({
          'availableCopies': book.availableCopies - 1,
        });

        final index = _allBooks.indexWhere((b) => b.id == book.id);
        if (index != -1) {
          final updatedBook = _allBooks[index].copyWith(
            availableCopies: _allBooks[index].availableCopies - 1,
          );
          _allBooks[index] = updatedBook;

          final reservedIndex =
              _reservedBooks.indexWhere((b) => b.id == book.id);
          if (reservedIndex != -1) {
            _reservedBooks[reservedIndex] = updatedBook;
          } else {
            _reservedBooks.add(updatedBook);
          }
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error reserving book: $e');
        }
      }
    }
  }

  Future<void> cancelReservation(Book book) async {
    final reservedIndex = _reservedBooks.indexWhere((b) => b.id == book.id);
    if (reservedIndex != -1) {
      try {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(book.id)
            .update({
          'availableCopies': book.availableCopies + 1,
        });

        _reservedBooks.removeAt(reservedIndex);
        final index = _allBooks.indexWhere((b) => b.id == book.id);
        if (index != -1) {
          _allBooks[index] = _allBooks[index].copyWith(
            availableCopies: _allBooks[index].availableCopies + 1,
          );
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error cancelling reservation: $e');
        }
      }
    }
  }

  Future<void> addBook(Book book) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('books').doc();
      final newBook = book.copyWith(id: docRef.id);
      await docRef.set(newBook.toMap());
      _allBooks.add(newBook);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding book: $e');
      }
      rethrow;
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(book.id)
          .update(book.toMap());
          
      final index = _allBooks.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _allBooks[index] = book;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating book: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
      _allBooks.removeWhere((b) => b.id == bookId);
      // We should potentially handle reserved books too, 
      // but keeping it simple for admin delete scope
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting book: $e');
      }
      rethrow;
    }
  }
}
