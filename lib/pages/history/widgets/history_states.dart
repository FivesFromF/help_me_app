import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'history_tokens.dart';

/// Trạng thái rỗng của một tab.
///
/// Bọc trong vùng cuộn được để cử chỉ "kéo xuống để tải lại" vẫn hoạt động
/// ngay cả khi danh sách chưa có dữ liệu nào.
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 140),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: HistoryPalette.brand.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: HistoryPalette.brand.border),
                      ),
                      child: Icon(
                        icon,
                        size: 42,
                        color: HistoryPalette.brand.accent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: HistoryPalette.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: HistoryPalette.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          PhosphorIconsRegular.arrowsClockwise,
                          size: 14,
                          color: HistoryPalette.inkFaint,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Kéo xuống để tải lại',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: HistoryPalette.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Trạng thái lỗi khi không tải được lịch sử.
class HistoryErrorState extends StatelessWidget {
  const HistoryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const HistoryTone tone = HistoryPalette.danger;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HistoryPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tone.border),
            boxShadow: HistoryPalette.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tone.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.warningCircle,
                  size: 32,
                  color: tone.accent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tải được lịch sử',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: HistoryPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: HistoryPalette.inkMuted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(PhosphorIconsBold.arrowsClockwise, size: 18),
                  label: const Text(
                    'Thử lại',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HistoryPalette.brand.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung xương (skeleton) hiển thị trong lúc chờ dữ liệu, thay cho vòng xoay.
///
/// Dựng đúng dáng của thẻ thật để nội dung không "nhảy" khi tải xong.
class HistorySkeletonList extends StatefulWidget {
  const HistorySkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  State<HistorySkeletonList> createState() => _HistorySkeletonListState();
}

class _HistorySkeletonListState extends State<HistorySkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: widget.itemCount,
        itemBuilder: (BuildContext context, int index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                opacity: 0.45 + (_controller.value * 0.35),
                child: child,
              );
            },
            child: const _SkeletonCard(),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HistoryPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HistoryPalette.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SkeletonBox(width: 46, height: 46, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SkeletonBox(width: 170, height: 13),
                SizedBox(height: 10),
                _SkeletonBox(width: 110, height: 11),
                SizedBox(height: 16),
                _SkeletonBox(width: double.infinity, height: 6, radius: 999),
              ],
            ),
          ),
          SizedBox(width: 12),
          _SkeletonBox(width: 58, height: 20, radius: 999),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: HistoryPalette.neutral.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
