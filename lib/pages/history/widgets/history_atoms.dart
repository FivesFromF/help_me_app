import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'history_tokens.dart';

/// Các thành phần nhỏ dùng lại nhiều lần trong màn "Lịch sử hoạt động":
/// huy hiệu trạng thái, chip phương thức quét, đồng hồ đếm ngược và ô icon.

/// Huy hiệu trạng thái: nền nhạt + viền + chữ đậm theo [tone].
class HistoryBadge extends StatelessWidget {
  const HistoryBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.dense = false,
  });

  final String label;
  final HistoryTone tone;
  final IconData? icon;

  /// Bản gọn hơn, dùng khi nằm cạnh tiêu đề trong danh sách.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final double fontSize = dense ? 10.5 : 11.5;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4.5,
      ),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: fontSize + 2, color: tone.content),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: tone.content,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip hiển thị phương thức nhận diện (NFC / QR / Khuôn mặt).
class HistoryMethodChip extends StatelessWidget {
  const HistoryMethodChip({super.key, required this.method});

  final String? method;

  @override
  Widget build(BuildContext context) {
    final HistoryStatusStyle style = methodStyle(method);
    return HistoryBadge(
      label: style.label,
      icon: style.icon,
      tone: style.tone,
      dense: true,
    );
  }
}

/// Chip cho biết báo cáo đến từ luồng cứu trợ đã xác thực nạn nhân
/// (`origin == 'identified'`) hay là một báo cáo độc lập.
class HistoryOriginBadge extends StatelessWidget {
  const HistoryOriginBadge({
    super.key,
    required this.isIdentified,
    this.dense = true,
  });

  final bool isIdentified;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return HistoryBadge(
      label: isIdentified ? 'Cứu trợ xác thực' : 'Báo cáo độc lập',
      icon: isIdentified ? PhosphorIconsFill.sealCheck : PhosphorIconsFill.note,
      tone: isIdentified ? HistoryPalette.success : HistoryPalette.neutral,
      dense: dense,
    );
  }
}

/// Ô icon bo góc dùng làm phần dẫn đầu của thẻ / tiêu đề bottom sheet.
class HistoryIconTile extends StatelessWidget {
  const HistoryIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.background,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Đồng hồ đếm ngược của một phiên xem hồ sơ.
///
/// Chỉ đọc `secondsRemaining` sẵn có từ API — không tự tính lại thời hạn.
/// Thanh tiến trình lấy mốc 1 giờ theo đúng chính sách phiên của hệ thống,
/// và chuyển sang màu hổ phách khi còn dưới 10 phút.
class HistoryCountdown extends StatelessWidget {
  const HistoryCountdown({super.key, required this.secondsRemaining});

  final int secondsRemaining;

  /// Phiên truy cập hồ sơ y tế kéo dài 1 giờ.
  static const int sessionWindowSeconds = 3600;

  /// Dưới ngưỡng này thì hiển thị cảnh báo sắp hết hạn.
  static const int urgentThresholdSeconds = 600;

  @override
  Widget build(BuildContext context) {
    final int clamped = secondsRemaining.clamp(0, sessionWindowSeconds);
    final double progress = clamped / sessionWindowSeconds;
    final bool isUrgent = clamped <= urgentThresholdSeconds;
    final HistoryTone tone = isUrgent
        ? HistoryPalette.warning
        : HistoryPalette.success;

    final int minutes = (secondsRemaining / 60).ceil();
    final String label = minutes <= 0
        ? 'Sắp hết hạn'
        : 'Còn $minutes phút truy cập';

    return Semantics(
      label: 'Phiên xem hồ sơ $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isUrgent ? PhosphorIconsFill.timer : PhosphorIconsFill.clock,
                size: 14,
                color: tone.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: tone.content,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: tone.surface,
              valueColor: AlwaysStoppedAnimation<Color>(tone.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng gợi ý / trạng thái ở chân thẻ, ngăn cách bằng một đường kẻ mảnh.
class HistoryCardFooter extends StatelessWidget {
  const HistoryCardFooter({super.key, required this.child, this.padTop = 12});

  final Widget child;
  final double padTop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: padTop, bottom: padTop),
          child: const ColoredBox(
            color: HistoryPalette.divider,
            child: SizedBox(height: 1, width: double.infinity),
          ),
        ),
        child,
      ],
    );
  }
}

/// Dòng chân thẻ dạng "icon + chữ", dùng cho các trạng thái không thao tác được.
class HistoryStatusLine extends StatelessWidget {
  const HistoryStatusLine({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
