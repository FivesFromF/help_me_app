import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/shared/services/nfc_service.dart';
import 'package:help_me_app/pages/identity_verification/identity_result_page.dart';

class IdentityScanPage extends StatefulWidget {
  const IdentityScanPage({super.key});

  @override
  State<IdentityScanPage> createState() => _IdentityScanPageState();
}

class _IdentityScanPageState extends State<IdentityScanPage>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  String _statusMessage = 'Đang chờ quét thẻ...';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Defer NFC start until after the first frame is rendered to prevent UI freeze
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('IdentityScanPage: Frame rendered, starting NFC session...');
      _startNfcSession();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    NfcService.stopSession();
    super.dispose();
  }

  Future<void> _startNfcSession() async {
    debugPrint('IdentityScanPage: _startNfcSession called');

    // Safety: ensure any existing session is stopped
    await NfcService.stopSession();

    debugPrint('IdentityScanPage: Checking NFC availability...');
    final available = await NfcService.isAvailable();
    debugPrint('IdentityScanPage: NFC availability = $available');

    if (!available) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'NFC không khả dụng hoặc chưa được bật.';
        });
      }
      return;
    }

    debugPrint('IdentityScanPage: Calling NfcService.startSession...');
    await NfcService.startSession(
      onTag: (tag) async {
        if (!_isScanning) return;

        setState(() => _statusMessage = 'Đang đọc dữ liệu thẻ...');

        // 1. Read Identifier and HashedID
        final uid = NfcService.getTagUid(tag);
        final hashedId = await NfcService.readNdef(tag);

        if (hashedId == null) {
          setState(
            () => _statusMessage = 'Thẻ không chứa dữ liệu HelpMe hợp lệ.',
          );
          return;
        }

        setState(() {
          _isScanning = false;
          _statusMessage = 'Đang xác thực thông tin...';
        });

        try {
          final result = await AuthService.verifyIdentity(
            nfcId: uid,
            hashedCitizenId: hashedId,
          );

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => IdentityResultPage(data: result),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isScanning = true;
              _statusMessage = 'Lỗi xác thực: $e\nVui lòng thử lại.';
            });
          }
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _statusMessage = 'Lỗi NFC: $err');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Top Instruction Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C08B), // HelpMe Green
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/logo.svg',
                      height: 50,
                      placeholderBuilder: (context) => const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giữ bình tĩnh.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Hướng đầu đọc vào thẻ NFC của nạn nhân và giữ yên',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Central Scan Area
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Scan Corners (The frame)
                  SizedBox(
                    width: 320,
                    height: 460,
                    child: CustomPaint(painter: ScanFramePainter()),
                  ),

                  // NFC Card Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RotatedBox(
                      quarterTurns: 1, // Rotate 90 degrees
                      child: Image.asset(
                        'assets/screenshots/VerifyIdentity/FrontNFCCard.png',
                        width:
                            400, // Increased width as it's now the "height" after rotation
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Animation Overlay (Optional subtle pulse)
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 280 * (1 + 0.05 * _pulseController.value),
                          height: 420 * (1 + 0.05 * _pulseController.value),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(
                                0xFF00C08B,
                              ).withValues(alpha: 1 - _pulseController.value),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  // Status Indicator
                  Expanded(
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Heartbeat line image
                          Image.asset(
                            'assets/screenshots/VerifyIdentity/HeartBeatLine.png',
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Close Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40FF6B00),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C08B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLength = 40.0;
    const radius = 24.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..arcToPoint(
          const Offset(radius, 0),
          radius: const Radius.circular(radius),
        )
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(
          Offset(size.width, radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(
          Offset(radius, size.height),
          radius: const Radius.circular(radius),
        )
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(
          Offset(size.width, size.height - radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
