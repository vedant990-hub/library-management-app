import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../models/book.dart';
import '../../theme/app_theme.dart';

class AddEditBookScreen extends StatefulWidget {
  final Book? book;

  const AddEditBookScreen({super.key, this.book});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _copiesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _copiesController.text = widget.book!.availableCopies.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _copiesController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<LibraryProvider>(context, listen: false);
    final copies = int.tryParse(_copiesController.text) ?? 0;

    try {
      if (widget.book == null) {
        final newBook = Book(
          id: '',
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          availableCopies: copies,
        );
        await provider.addBook(newBook);
      } else {
        final updatedBook = widget.book!.copyWith(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          availableCopies: copies,
        );
        await provider.updateBook(updatedBook);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(widget.book == null
                    ? 'Book added successfully!'
                    : 'Book updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save book: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.book != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Book' : 'Add New Book',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.adminAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header illustration
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.bookCoverGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isEditing
                                ? Icons.edit_note_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isEditing
                                ? 'Update book information'
                                : 'Fill in the book details',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        prefixIcon: Icon(Icons.book_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter a title'
                              : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter an author'
                              : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _copiesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Available Copies',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter number of copies';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Copies cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),
                    ElevatedButton.icon(
                      onPressed: _saveBook,
                      icon: Icon(
                          isEditing ? Icons.save_rounded : Icons.add_rounded,
                          size: 20),
                      label: Text(
                        isEditing ? 'Save Changes' : 'Add Book',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
