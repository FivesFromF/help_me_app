import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/pages/identity_verification/identity_result_page.dart';

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  bool _isScanning = true;
  String _statusMessage = 'Đang quét khuôn mặt...';
  bool _flashOn = false;

  // Continuous Scan States
  DateTime? _lastSearchTime;
  bool _isProcessingMatch = false;
  double _livenessProgress = 0.0;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Initialize Face Detector
    final options = FaceDetectorOptions(performanceMode: FaceDetectorMode.fast);
    _faceDetector = FaceDetector(options: options);

    // 2. Initialize Camera
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController?.initialize();
    if (!mounted) return;

    // 3. Start Image Stream
    _cameraController?.startImageStream(_processCameraImage);

    setState(() {});
  }

  @override
  void dispose() {
    _waveController.dispose();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy || _faceDetector == null || !_isScanning || _isProcessingMatch)
      return;
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
          _updateStatus('Xích lại gần hơn', 0.0);
        } else {
          // Check if it's time to call the API (every 1 second)
          final now = DateTime.now();
          final diff = _lastSearchTime == null
              ? 1000
              : now.difference(_lastSearchTime!).inMilliseconds;

          double progress = (diff % 1000) / 1000.0;
          _updateStatus('Đang nhận diện...', progress);

          if (diff >= 1000) {
            _lastSearchTime = now;
            // Trigger background search
            _performBackgroundSearch();
          }
        }
      } else {
        _updateStatus('Đang tìm kiếm khuôn mặt...', 0.0);
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _performBackgroundSearch() async {
    if (_cameraController == null || _isProcessingMatch) return;

    try {
      final XFile file = await _cameraController!.takePicture();
      final bytes = await File(file.path).readAsBytes();
      final b64 = base64Encode(bytes);

      // Call API in background
      final result = await AuthService.searchByFace(faceImageB64: b64);

      // If we reach here, a match was found!
      _isProcessingMatch = true;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => IdentityResultPage(data: result)),
        );
      }
    } catch (e) {
      // No match or error, just continue scanning silently
      debugPrint("Background search: No match found yet.");
    }
  }

  void _updateStatus(String msg, double progress) {
    if (!mounted) return;
    setState(() {
      _statusMessage = msg;
      _livenessProgress = progress; // Used for the UI progress bar
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

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black);
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
            child: CustomPaint(painter: FaceScanningOverlayPainter()),
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
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash Toggle
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _flashOn ? Icons.flash_on : Icons.flashlight_on,
                          color: AppColors.primaryOrange,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                // Status Pill
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Animated Wave
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Image.asset(
                            'assets/screenshots/VerifyIdentity/HeartBeatLine.png',
                            height: 20,
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.6 + 0.4 * _waveController.value,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Cancel Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FaceScanningOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C08B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final frameWidth = size.width * 0.75;
    final frameHeight = size.height * 0.55;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameWidth,
      height: frameHeight,
    );

    // Draw Oval Frame
    canvas.drawOval(rect, paint);

    // Draw Crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2 - 100, size.height / 2),
      Offset(size.width / 2 + 100, size.height / 2),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 100),
      Offset(size.width / 2, size.height / 2 + 100),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
