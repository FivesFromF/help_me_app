import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';

/// Lớp phủ hiển thị trong lúc chờ máy chủ đối chiếu khuôn mặt.
///
/// Việc tìm kiếm có thể kéo dài tới ~25 giây (thử nhanh 4 giây, sau đó tải ảnh
/// lên S3 rồi chờ AI worker trả kết quả qua tối đa 20 lần poll). Nếu màn hình
/// đứng im suốt quãng đó, người quét sẽ tưởng máy bị treo và thoát ra giữa
/// chừng — điều tệ nhất có thể xảy ra trong "giờ vàng".
///
/// Vì vậy lớp phủ này luôn trả lời ba câu hỏi: *hệ thống đang làm gì*,
/// *đã chờ bao lâu* và *làm sao để dừng lại*.
class FaceMatchProgressOverlay extends StatefulWidget {
  const FaceMatchProgressOverlay({super.key, required this.onCancel});

  /// Gọi khi người dùng bấm "Huỷ quét" — trang cha quyết định thoát đi đâu.
  final VoidCallback onCancel;

  @override
  State<FaceMatchProgressOverlay> createState() =>
      _FaceMatchProgressOverlayState();
}

/// Một bước trong tiến trình đối chiếu, kèm mốc giây mà bước đó bắt đầu.
class _MatchStep {
  const _MatchStep(this.label, this.startsAtSeconds);

  final String label;
  final int startsAtSeconds;
}

const List<_MatchStep> _matchSteps = [
  _MatchStep('Đang gửi ảnh lên máy chủ', 0),
  _MatchStep('Đang phân tích đặc trưng khuôn mặt', 4),
  _MatchStep('Đang đối chiếu với hồ sơ công dân', 9),
];

class _FaceMatchProgressOverlayState extends State<FaceMatchProgressOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(milliseconds: 200);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ring.dispose();
    super.dispose();
  }

  /// Không thể biết trước máy chủ trả lời lúc nào, nên thanh tiến trình tiến
  /// dần theo hàm mũ rồi dừng ở 94% — luôn "đang chạy", không hứa hão là xong.
  double get _progress {
    final seconds = _elapsed.inMilliseconds / 1000.0;
    return (1 - math.exp(-seconds / 7)) * 0.94;
  }

  int get _activeStep {
    final seconds = _elapsed.inSeconds;
    var index = 0;
    for (var i = 0; i < _matchSteps.length; i++) {
      if (seconds >= _matchSteps[i].startsAtSeconds) index = i;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.62)),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRing(),
                    const SizedBox(height: 28),
                    const Text(
                      'Đang đối chiếu khuôn mặt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giữ máy ổn định, đừng thoát ra.\nHệ thống đang tìm hồ sơ khớp với khuôn mặt vừa chụp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildSteps(_activeStep),
                    const SizedBox(height: 22),
                    _buildProgressBar(),
                    const SizedBox(height: 26),
                    _buildCancelButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRing() {
    return SizedBox(
      width: 132,
      height: 132,
      child: AnimatedBuilder(
        animation: _ring,
        builder: (context, child) {
          return CustomPaint(
            painter: _MatchRingPainter(sweep: _ring.value, progress: _progress),
            child: child,
          );
        },
        child: const Center(
          child: Icon(
            Icons.person_search_rounded,
            color: Colors.white,
            size: 46,
          ),
        ),
      ),
    );
  }

  Widget _buildSteps(int activeStep) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _matchSteps.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _MatchStepRow(
              label: _matchSteps[i].label,
              state: i < activeStep
                  ? _StepState.done
                  : (i == activeStep ? _StepState.active : _StepState.pending),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final seconds = _elapsed.inSeconds;
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          seconds >= 12
              ? 'Đã chờ $seconds giây — đường truyền chậm, vẫn đang xử lý...'
              : 'Đã chờ $seconds giây',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton.icon(
      onPressed: widget.onCancel,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text(
        'Huỷ quét',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _MatchStepRow extends StatelessWidget {
  const _MatchStepRow({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    switch (state) {
      case _StepState.done:
        textColor = Colors.white.withValues(alpha: 0.65);
      case _StepState.active:
        textColor = Colors.white;
      case _StepState.pending:
        textColor = Colors.white.withValues(alpha: 0.38);
    }

    return Row(
      children: [
        SizedBox(width: 22, height: 22, child: _buildMarker()),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: state == _StepState.active
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarker() {
    switch (state) {
      case _StepState.done:
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        );
      case _StepState.active:
        return const CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
        );
      case _StepState.pending:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        );
    }
  }
}

/// Vòng tròn quanh biểu tượng: một cung xanh chạy vòng (báo "vẫn đang chạy")
/// chồng lên cung tiến trình màu cam.
class _MatchRingPainter extends CustomPainter {
  const _MatchRingPainter({required this.sweep, required this.progress});

  /// Vị trí 0..1 của cung xoay.
  final double sweep;

  /// Tiến trình ước lượng 0..1.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    final progressPaint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final runner = Paint()
      ..color = AppColors.primaryGreen
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2 + 2 * math.pi * sweep,
      math.pi / 5,
      false,
      runner,
    );
  }

  @override
  bool shouldRepaint(covariant _MatchRingPainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.progress != progress;
}
