import 'package:flutter/material.dart';
import 'history_tokens.dart';

/// Khung bottom sheet dùng chung cho các modal chi tiết của màn lịch sử.
///
/// Gồm: thanh kéo (grabber), dải tiêu đề màu theo ngữ cảnh, phần thân cuộn
/// được, và một chân cố định tuỳ chọn để đặt nút hành động chính.
class HistorySheet extends StatelessWidget {
  const HistorySheet({
    super.key,
    required this.headerColor,
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.heightFactor = 0.82,
  });

  final Color headerColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Nút hành động chính, luôn nhìn thấy dù thân đang cuộn.
  final Widget? footer;

  final double heightFactor;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double bottomInset = media.padding.bottom;

    return SizedBox(
      height: media.size.height * heightFactor,
      child: Column(
        children: <Widget>[
          // Thanh kéo nằm trên nền mờ, ngoài phần trắng của sheet.
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: HistoryPalette.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_radius),
                ),
              ),
              child: Column(
                children: <Widget>[
                  _SheetHeader(
                    color: headerColor,
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        footer == null ? 24 + bottomInset : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    ),
                  ),
                  if (footer != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        14 + bottomInset,
                      ),
                      decoration: const BoxDecoration(
                        color: HistoryPalette.surface,
                        border: Border(
                          top: BorderSide(color: HistoryPalette.divider),
                        ),
                      ),
                      child: footer,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Đóng',
            button: true,
            child: Material(
              color: Colors.white.withValues(alpha: 0.16),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một nhóm nội dung trong bottom sheet, có tiêu đề nhỏ phía trên.
class HistorySection extends StatelessWidget {
  const HistorySection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.topGap = 20,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 15, color: HistoryPalette.brand.accent),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: HistoryPalette.ink,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Bảng thông tin nhãn / giá trị, các dòng ngăn nhau bằng kẻ mảnh.
class HistoryInfoTable extends StatelessWidget {
  const HistoryInfoTable({super.key, required this.rows});

  final List<HistoryInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          const Divider(height: 1, thickness: 1, color: HistoryPalette.divider),
        );
      }
      children.add(rows[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: HistoryPalette.neutral.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HistoryPalette.border),
      ),
      child: Column(children: children),
    );
  }
}

/// Một dòng "nhãn — giá trị" bên trong [HistoryInfoTable].
class HistoryInfoRow extends StatelessWidget {
  const HistoryInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: HistoryPalette.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: trailing != null
                ? Align(alignment: Alignment.centerRight, child: trailing)
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? HistoryPalette.ink,
                      height: 1.35,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Khối nội dung nền màu nhạt: mô tả sự cố, nạn nhân, toạ độ GPS...
class HistoryDataBlock extends StatelessWidget {
  const HistoryDataBlock({
    super.key,
    required this.tone,
    required this.icon,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final HistoryTone tone;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: tone.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: child),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}

/// Hộp cảnh báo / thông báo có tiêu đề, dùng cho khối "đã khiếu nại".
class HistoryNotice extends StatelessWidget {
  const HistoryNotice({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.children,
  });

  final HistoryTone tone;
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: tone.accent, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: tone.content,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Nút hành động chính đặt ở chân bottom sheet.
class HistorySheetButton extends StatelessWidget {
  const HistorySheetButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 19),
              label: _label(),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                shape: shape,
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 19),
              label: _label(),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: shape,
              ),
            ),
    );
  }

  Widget _label() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }
}

/// Thanh tóm tắt đặt ở đầu mỗi tab: số lượng bản ghi + một câu giải thích.
class HistoryTabIntro extends StatelessWidget {
  const HistoryTabIntro({
    super.key,
    required this.icon,
    required this.count,
    required this.unit,
    required this.description,
  });

  final IconData icon;
  final int count;

  /// Đơn vị đếm, ví dụ "phiên", "báo cáo", "lượt".
  final String unit;

  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: HistoryPalette.inkFaint),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$count $unit',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: HistoryPalette.ink,
                    ),
                  ),
                  const TextSpan(text: '  •  '),
                  TextSpan(text: description),
                ],
              ),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: HistoryPalette.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
