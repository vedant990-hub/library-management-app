import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'book_detail_screen.dart';

class ScanBookScreen extends StatefulWidget {
  const ScanBookScreen({super.key});

  @override
  State<ScanBookScreen> createState() => _ScanBookScreenState();
}

class _ScanBookScreenState extends State<ScanBookScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _hasNavigated = false;
  bool _torchOn = false;
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasNavigated) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawValue = barcode.rawValue!.trim();

    if (!rawValue.startsWith('book_')) {
      _showError('Invalid QR code. This doesn\'t appear to be a library book.');
      return;
    }

    final bookId = rawValue.substring(5);
    if (bookId.isEmpty) {
      _showError('Invalid QR code. Book ID is empty.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    _fetchAndNavigate(bookId);
  }

  Future<void> _fetchAndNavigate(String bookId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        setState(() => _isProcessing = false);
        _showError('Book not found in the library catalog.');
        return;
      }

      final book = Book.fromMap(doc.data()!, doc.id);

      setState(() => _hasNavigated = true);
      _scannerController.stop();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          FadeSlideRoute(page: BookDetailScreen(book: book)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Failed to fetch book details. Please try again.');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        title: Text(
          'Scan Book QR',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _scannerController.toggleTorch();
              if (mounted) {
                setState(() => _torchOn = !_torchOn);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _torchOn
                    ? Colors.amber.withAlpha(100)
                    : Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _torchOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            color: Colors.red, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Camera Access Required',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please grant camera permission in your device settings to scan QR codes.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Scanning overlay
          _buildScanOverlay(),

          // Bottom instruction card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87, Colors.black],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing)
                    Column(
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fetching book details...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_scanner_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Point at a book\'s QR code',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The QR code is usually on the inside front cover',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanSize) / 2;
        final top = (constraints.maxHeight - scanSize) / 2 - 40;

        return Stack(
          children: [
            // Dimmed background with cutout
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner decorations
            Positioned(
              left: left,
              top: top,
              child: _buildCorners(scanSize),
            ),

            // Animated scan line
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: left + 16,
                  top: top + 16 + (_scanLineAnimation.value * (scanSize - 32)),
                  child: Container(
                    width: scanSize - 32,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withAlpha(200),
                          AppColors.primary,
                          AppColors.primary.withAlpha(200),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorners(double size) {
    const cornerLength = 30.0;
    const cornerWidth = 3.5;
    const color = Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(top: 0, left: 0,
            child: Container(width: cornerLength, height: cornerWidth,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
          Positioned(top: 0, left: 0,
            child: Container(width: cornerWidth, height: cornerLength,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
          // Top-right
          Positioned(top: 0, right: 0,
            child: Container(width: cornerLength, height: cornerWidth,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
          Positioned(top: 0, right: 0,
            child: Container(width: cornerWidth, height: cornerLength,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
          // Bottom-left
          Positioned(bottom: 0, left: 0,
            child: Container(width: cornerLength, height: cornerWidth,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
          Positioned(bottom: 0, left: 0,
            child: Container(width: cornerWidth, height: cornerLength,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
          // Bottom-right
          Positioned(bottom: 0, right: 0,
            child: Container(width: cornerLength, height: cornerWidth,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
          Positioned(bottom: 0, right: 0,
            child: Container(width: cornerWidth, height: cornerLength,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
        ],
      ),
    );
  }
}
