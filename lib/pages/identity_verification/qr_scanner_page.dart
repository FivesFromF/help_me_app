import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/pages/identity_verification/identity_result_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Parse JSON from QR code
      final Map<String, dynamic> qrData = jsonDecode(code);
      final String? qrId = qrData['qrId'];
      final String? hash = qrData['hash'];

      if (qrId == null || hash == null) {
        throw Exception('Mã QR không đúng định dạng');
      }

      // 2. Call API to verify
      final result = await AuthService.verifyIdentity(
        qrId: qrId,
        hashedCitizenId: hash,
      );

      // 3. Navigate to result page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => IdentityResultPage(data: result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        // Allow re-scanning after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(controller: controller, onDetect: _onDetect),

          // Professional Overlay
          CustomPaint(painter: ScannerOverlayPainter(), child: Container()),

          // Header UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Quét mã QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // In mobile_scanner 7.0.0+, controller implements ValueListenable<MobileScannerState>
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: controller,
                    builder: (context, state, child) {
                      final TorchState torchState = state.torchState;
                      return IconButton(
                        onPressed: () => controller.toggleTorch(),
                        icon: Icon(
                          torchState == TorchState.on
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instruction
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                const Text(
                  'Căn chỉnh mã QR vào giữa khung hình',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                // New Note Box from screenshot
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      // Logo
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: SvgPicture.asset('assets/logo.svg'),
                      ),
                      const SizedBox(width: 8),
                      // Text
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giữ bình tĩnh.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hướng camera vào mã QR của nạn nhân và giữ yên',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Scanner window size
    const double scanAreaSize = 260.0;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);
    final RRect scanRRect = RRect.fromRectAndRadius(
      scanRect,
      const Radius.circular(24),
    );

    // Draw background with cutout
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(scanRRect),
      ),
      paint,
    );

    // Draw corners
    final cornerPaint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + 24)
        ..arcToPoint(Offset(left + 24, top), radius: const Radius.circular(24))
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top)
        ..lineTo(left + scanAreaSize - 24, top)
        ..arcToPoint(
          Offset(left + scanAreaSize, top + 24),
          radius: const Radius.circular(24),
        )
        ..lineTo(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanAreaSize - cornerLength)
        ..lineTo(left, top + scanAreaSize - 24)
        ..arcToPoint(
          Offset(left + 24, top + scanAreaSize),
          radius: const Radius.circular(24),
          clockwise: false,
        )
        ..lineTo(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
        ..lineTo(left + scanAreaSize - 24, top + scanAreaSize)
        ..arcToPoint(
          Offset(left + scanAreaSize, top + scanAreaSize - 24),
          radius: const Radius.circular(24),
          clockwise: false,
        )
        ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
