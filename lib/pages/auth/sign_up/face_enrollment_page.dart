import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:help_me_app/app_colors.dart';

class FaceEnrollmentPage extends StatefulWidget {
  final Function(String base64Image) onFaceCaptured;

  const FaceEnrollmentPage({super.key, required this.onFaceCaptured});

  @override
  State<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends State<FaceEnrollmentPage> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  String _instruction = "Đang khởi tạo camera...";

  // Enrollment Flow States
  bool _hasInitialPosition = false;
  bool _hasBlinked = false;
  bool _hasTurnedHead = false;
  bool _isFinalPosition = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Initialize Face Detector
    final options = FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    // 2. Initialize Camera
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
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

    setState(() {
      _instruction = "Vui lòng đưa khuôn mặt vào khung hình";
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy || _faceDetector == null) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        _updateUI("Không tìm thấy khuôn mặt", 0.0);
      } else {
        final face = faces.first;
        final yaw = face.headEulerAngleY ?? 0;
        final pitch = face.headEulerAngleX ?? 0;

        // Ratio Check
        final faceWidth = face.boundingBox.width;
        final faceHeight = face.boundingBox.height;
        final imgWidth = image.width.toDouble();
        final imgHeight = image.height.toDouble();
        final ratio = (faceWidth * faceHeight) / (imgWidth * imgHeight);

        if (ratio < 0.20) {
          _updateUI("Vui lòng xích lại gần hơn", 0.1);
          return;
        }

        // 1. Initial Position (Look straight)
        if (!_hasInitialPosition) {
          if (yaw.abs() < 10 && pitch.abs() < 10) {
            _hasInitialPosition = true;
            _updateUI("Tốt! Hãy nháy mắt một cái", 0.3);
          } else {
            _updateUI("Nhìn thẳng vào camera", 0.2);
          }
          return;
        }

        // 2. Blink Detection
        if (!_hasBlinked) {
          final leftEye = face.leftEyeOpenProbability ?? 1.0;
          final rightEye = face.rightEyeOpenProbability ?? 1.0;
          if (leftEye < 0.2 || rightEye < 0.2) {
            _hasBlinked = true;
            _updateUI("Tuyệt vời! Bây giờ hãy quay nhẹ đầu", 0.5);
          } else {
            _updateUI("Vui lòng nháy mắt", 0.3);
          }
          return;
        }

        // 3. Head Turn (Yaw)
        if (!_hasTurnedHead) {
          if (yaw.abs() > 20) {
            _hasTurnedHead = true;
            _updateUI("Tốt lắm! Cuối cùng hãy nhìn thẳng", 0.8);
          } else {
            _updateUI("Quay đầu sang trái hoặc phải", 0.6);
          }
          return;
        }

        // 4. Final Position & Capture
        if (!_isFinalPosition) {
          if (yaw.abs() < 5) {
            _isFinalPosition = true;
            _updateUI("Đang xử lý...", 1.0);
            await _captureAndComplete();
          } else {
            _updateUI("Nhìn thẳng để hoàn tất", 0.9);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    } finally {
      _isBusy = false;
    }
  }

  void _updateUI(String msg, double progress) {
    if (!mounted) return;
    setState(() {
      _instruction = msg;
      _progress = progress;
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

  Future<void> _captureAndComplete() async {
    if (_cameraController == null || _progress < 1.0) return;

    try {
      setState(() => _isBusy = true);

      await _cameraController!.stopImageStream();
      final XFile file = await _cameraController!.takePicture();

      widget.onFaceCaptured(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi chụp ảnh: $e")));
      _cameraController?.startImageStream(_processCameraImage);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_cameraController!)),

          // Oval Overlay (Dark background with oval hole)
          Positioned.fill(child: CustomPaint(painter: OvalOverlayPainter())),

          // Oval Border
          Center(
            child: Container(
              width: size.width * 0.75,
              height: size.height * 0.45,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _progress >= 1.0
                      ? AppColors.primaryGreen
                      : AppColors.primaryOrange.withValues(
                          alpha: 0.5 + 0.5 * _progress,
                        ),
                  width: 4,
                ),
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size.width * 0.75, size.height * 0.45),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Progress Bar
                Container(
                  height: 6,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    _instruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class OvalOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final frameWidth = size.width * 0.75;
    final frameHeight = size.height * 0.45;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameWidth,
      height: frameHeight,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addOval(rect),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
