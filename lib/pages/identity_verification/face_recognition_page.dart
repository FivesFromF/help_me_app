import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/pages/identity_verification/identity_result_page.dart';
import 'package:help_me_app/pages/identity_verification/widgets/face_match_progress_overlay.dart';

/// Trạng thái căn khung khuôn mặt trước ống kính.
enum FaceAlign {
  /// Chưa thấy khuôn mặt nào trong khung hình.
  searching,

  /// Thấy mặt nhưng còn quá xa để nhận diện.
  tooFar,

  /// Khuôn mặt đã đủ lớn và nằm trong khung — sẵn sàng gửi đi đối chiếu.
  aligned,
}

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  final bool _isScanning = true;
  String _statusMessage = 'Đang quét khuôn mặt...';
  bool _flashOn = false;

  // Continuous Scan States
  DateTime? _lastSearchTime;
  bool _isProcessingMatch = false;

  /// Bật khi đang chờ máy chủ trả kết quả — dùng để bật lớp phủ tiến trình.
  bool _isSearching = false;

  /// Trạng thái căn khung hiện tại, quyết định màu viền của khung oval.
  FaceAlign _align = FaceAlign.searching;

  /// Thông báo ngắn hiện lên sau một lượt đối chiếu không ra kết quả.
  String? _retryHint;
  Timer? _retryHintTimer;

  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  late AnimationController _waveController;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Initialize Face Detector
    final options = FaceDetectorOptions(performanceMode: FaceDetectorMode.fast);
    _faceDetector = FaceDetector(options: options);

    // 2. Discover Cameras
    _availableCameras = await availableCameras();
    if (_availableCameras.isEmpty) return;

    _selectedCameraIndex = _availableCameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

    await _startCameraController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _startCameraController(CameraDescription camera) async {
    final oldController = _cameraController;
    if (oldController != null) {
      _cameraController = null;
      await oldController.dispose();
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      _cameraController?.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      debugPrint('Error starting camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    _flashOn = false;
    await _startCameraController(_availableCameras[_selectedCameraIndex]);
  }

  @override
  void dispose() {
    _retryHintTimer?.cancel();
    _waveController.dispose();
    _scanLineController.dispose();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy ||
        _faceDetector == null ||
        !_isScanning ||
        _isProcessingMatch) {
      return;
    }
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        // Position Check
        final faceWidth = face.boundingBox.width;
        final faceHeight = face.boundingBox.height;
        final imgWidth = image.width.toDouble();
        final imgHeight = image.height.toDouble();
        final ratio = (faceWidth * faceHeight) / (imgWidth * imgHeight);

        if (ratio < 0.15) {
          _updateStatus('Xích lại gần hơn', FaceAlign.tooFar);
        } else {
          // Check if it's time to call the API (every 1 second)
          final now = DateTime.now();
          final diff = _lastSearchTime == null
              ? 1000
              : now.difference(_lastSearchTime!).inMilliseconds;

          _updateStatus('Đã căn đúng khung — giữ yên', FaceAlign.aligned);

          if (diff >= 1000) {
            _lastSearchTime = now;
            // Trigger background search
            _performBackgroundSearch();
          }
        }
      } else {
        _updateStatus('Đang tìm kiếm khuôn mặt...', FaceAlign.searching);
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _performBackgroundSearch() async {
    if (_cameraController == null || _isProcessingMatch) return;
    _isProcessingMatch = true;

    // Từ đây tới lúc có kết quả, luồng ảnh ngừng được phân tích và khung hình
    // gần như đứng yên — bật lớp phủ tiến trình để người quét biết máy vẫn chạy.
    if (mounted) {
      setState(() {
        _isSearching = true;
        _retryHint = null;
      });
      _retryHintTimer?.cancel();
    }

    try {
      final XFile file = await _cameraController!.takePicture();

      // Call API in background using filePath directly
      final result = await AuthService.searchByFace(filePath: file.path);

      if (result['matchStatus'] == 'MATCH_FOUND' ||
          result['victim'] != null ||
          result['citizen'] != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => IdentityResultPage(data: result)),
          );
        }
        return;
      }

      _showRetryHint('Chưa khớp hồ sơ nào — đang quét lại');
    } catch (e) {
      // No match or error, just continue scanning silently
      debugPrint("Background search: No match found yet ($e).");
      _showRetryHint(_retryHintFor(e));
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
        _isProcessingMatch = false;
      }
    }
  }

  /// Diễn giải lỗi thành một câu ngắn cho người quét, thay vì im lặng bỏ qua.
  String _retryHintFor(Object error) {
    final message = error.toString().replaceAll('Exception: ', '');
    if (error is TimeoutException) {
      return 'Máy chủ phản hồi chậm — đang thử lại';
    }
    if (message.contains('thu hồi')) {
      return 'Hồ sơ này đã bị thu hồi quyền truy cập';
    }
    if (message.contains('SocketException') ||
        message.contains('Failed host')) {
      return 'Mất kết nối mạng — kiểm tra Internet rồi thử lại';
    }
    return 'Chưa khớp hồ sơ nào — đang quét lại';
  }

  void _showRetryHint(String hint) {
    if (!mounted) return;
    _retryHintTimer?.cancel();
    setState(() => _retryHint = hint);
    _retryHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _retryHint = null);
    });
  }

  void _updateStatus(String msg, FaceAlign align) {
    if (!mounted) return;
    // Hàm này chạy theo từng khung hình camera; chỉ dựng lại giao diện khi
    // thông tin thực sự đổi để không đốt CPU vô ích lúc đang quét.
    if (_statusMessage == msg && _align == align) return;
    setState(() {
      _statusMessage = msg;
      _align = align;
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    final newMode = _flashOn ? FlashMode.off : FlashMode.torch;
    await _cameraController!.setFlashMode(newMode);
    setState(() => _flashOn = !_flashOn);
  }

  /// Màu đại diện cho [_align] — dùng chung cho chấm trạng thái và khung oval.
  Color get _alignColor {
    switch (_align) {
      case FaceAlign.aligned:
        return AppColors.primaryGreen;
      case FaceAlign.tooFar:
        return AppColors.primaryOrange;
      case FaceAlign.searching:
        return const Color(0xFFBDBDBD);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // Trước đây là một màn hình đen trống trơn; giờ nói rõ máy đang khởi động.
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Đang khởi động máy ảnh...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // 2. Overlay Frame
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanLineController,
              builder: (context, _) {
                return CustomPaint(
                  painter: FaceScanningOverlayPainter(
                    align: _align,
                    sweep: _scanLineController.value,
                    // Lúc đang chờ máy chủ, tắt vạch quét để khỏi "nói dối"
                    // rằng camera vẫn đang phân tích khung hình.
                    showScanLine: !_isSearching,
                  ),
                );
              },
            ),
          ),

          // 3. Top Instruction Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
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
                              'Giữ bình tĩnh',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Vui lòng thực hiện các hành động theo hướng dẫn bên dưới',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // // Liveness Progress Bar
                // Container(
                //   height: 6,
                //   width: double.infinity,
                //   decoration: BoxDecoration(
                //     color: Colors.white.withValues(alpha: 0.3),
                //     borderRadius: BorderRadius.circular(3),
                //   ),
                //   child: FractionallySizedBox(
                //     alignment: Alignment.centerLeft,
                //     widthFactor: _livenessProgress,
                //     child: Container(
                //       decoration: BoxDecoration(
                //         color: AppColors.primaryOrange,
                //         borderRadius: BorderRadius.circular(3),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          // 4. Bottom Controls
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Flash Toggle
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _flashOn ? Icons.flash_on : Icons.flashlight_on,
                      color: AppColors.primaryOrange,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Switch Camera (Front / Back)
                if (_availableCameras.length > 1) ...[
                  GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cameraswitch_rounded,
                        color: AppColors.primaryOrange,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Status Pill (Expanded to prevent overflow)
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Chấm trạng thái: xanh khi đã căn đúng khung,
                        // cam khi cần chỉnh lại, xám khi chưa thấy mặt.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _alignColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _statusMessage,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Animated Wave
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return Image.asset(
                              'assets/screenshots/VerifyIdentity/HeartBeatLine.png',
                              height: 14,
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.6 + 0.4 * _waveController.value,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.primaryOrange,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Thông báo sau một lượt đối chiếu không ra kết quả
          Positioned(
            left: 24,
            right: 24,
            bottom: 92,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                offset: _retryHint == null ? const Offset(0, 0.4) : Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _retryHint == null ? 0 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primaryOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _retryHint ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 6. Lớp phủ tiến trình trong lúc chờ máy chủ đối chiếu
          if (_isSearching)
            Positioned.fill(
              child: FaceMatchProgressOverlay(
                onCancel: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// Khung ngắm khuôn mặt: làm tối vùng ngoài khung oval, đổi màu viền theo
/// trạng thái căn khung và chạy một vạch quét dọc trong lúc camera đang phân
/// tích khung hình.
class FaceScanningOverlayPainter extends CustomPainter {
  const FaceScanningOverlayPainter({
    required this.align,
    required this.sweep,
    required this.showScanLine,
  });

  final FaceAlign align;

  /// Vị trí 0..1 của vạch quét trong khung oval.
  final double sweep;

  final bool showScanLine;

  Color get _frameColor {
    switch (align) {
      case FaceAlign.aligned:
        return AppColors.primaryGreen;
      case FaceAlign.tooFar:
        return AppColors.primaryOrange;
      case FaceAlign.searching:
        return Colors.white.withValues(alpha: 0.75);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.75;
    final frameHeight = size.height * 0.55;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameWidth,
      height: frameHeight,
    );

    final ovalPath = Path()..addOval(rect);

    // Làm tối phần ngoài khung để mắt tự dồn vào khuôn mặt.
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      ovalPath,
    );
    canvas.drawPath(
      scrim,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Vạch quét chạy lên xuống bên trong khung oval.
    if (showScanLine) {
      canvas.save();
      canvas.clipPath(ovalPath);
      final lineY = rect.top + rect.height * sweep;
      final glow = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _frameColor.withValues(alpha: 0),
            _frameColor.withValues(alpha: 0.28),
            _frameColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(rect.left, lineY - 28, rect.width, 56));
      canvas.drawRect(
        Rect.fromLTWH(rect.left, lineY - 28, rect.width, 56),
        glow,
      );
      canvas.drawLine(
        Offset(rect.left, lineY),
        Offset(rect.right, lineY),
        Paint()
          ..color = _frameColor.withValues(alpha: 0.9)
          ..strokeWidth = 2,
      );
      canvas.restore();
    }

    // Viền khung oval.
    canvas.drawOval(
      rect,
      Paint()
        ..color = _frameColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Bốn dấu góc bám vào khung, giúp căn máy nhanh hơn.
    final corner = Paint()
      ..color = _frameColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const arc = 0.42;
    for (final start in [
      -math.pi / 2 - arc / 2,
      math.pi / 2 - arc / 2,
      -arc / 2,
      math.pi - arc / 2,
    ]) {
      canvas.drawArc(rect.inflate(6), start, arc, false, corner);
    }

    // Chữ thập canh giữa, mờ hơn trước để không lấn át khuôn mặt.
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2 - 60, size.height / 2),
      Offset(size.width / 2 + 60, size.height / 2),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 60),
      Offset(size.width / 2, size.height / 2 + 60),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceScanningOverlayPainter oldDelegate) =>
      oldDelegate.align != align ||
      oldDelegate.sweep != sweep ||
      oldDelegate.showScanLine != showScanLine;
}
