import 'package:flutter/material.dart';

import 'history_tokens.dart';

/// Vỏ thẻ dùng chung cho cả ba tab của màn "Lịch sử hoạt động".
///
/// Mỗi thẻ có một dải màu mảnh ở cạnh trái mang ý nghĩa trạng thái
/// (xanh = phiên đang mở, xám = đã hết hạn, đỏ = đã bị khiếu nại...),
/// giúp đọc được tình trạng chỉ bằng một cái liếc khi cuộn danh sách.
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.tone,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 14, 14),
  });

  /// Tone quyết định màu dải cạnh trái và sắc viền của thẻ.
  final HistoryTone tone;

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsets padding;

  static const double _radius = 18;
  static const double _railWidth = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: HistoryPalette.surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: tone.border),
          boxShadow: HistoryPalette.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius - 1),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _railWidth,
                child: ColoredBox(color: tone.accent),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: tone.accent.withValues(alpha: 0.06),
                  highlightColor: tone.accent.withValues(alpha: 0.04),
                  child: Padding(
                    padding: padding.copyWith(left: padding.left + _railWidth),
                    child: child,
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

/// Phần đầu thẻ: ô icon, tiêu đề + dòng phụ, và huy hiệu trạng thái bên phải.
///
/// Tách riêng vì cả ba tab đều lặp lại đúng bố cục này.
class HistoryCardHeader extends StatelessWidget {
  const HistoryCardHeader({
    super.key,
    required this.leading,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.titleMaxLines = 1,
  });

  final Widget leading;
  final String title;
  final Widget? subtitle;
  final Widget trailing;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: HistoryPalette.ink,
                  height: 1.3,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 6),
                subtitle!,
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Ràng buộc bề rộng để tên/nhãn tiếng Việt dài không đẩy vỡ hàng.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 116),
          child: trailing,
        ),
      ],
    );
  }
}

/// Dòng thông tin phụ dưới tiêu đề thẻ: chip + các mẩu chữ ngăn bởi dấu chấm.
class HistoryMetaRow extends StatelessWidget {
  const HistoryMetaRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// Mẩu chữ phụ (thời gian, vai trò...) trong [HistoryMetaRow].
class HistoryMetaText extends StatelessWidget {
  const HistoryMetaText(this.text, {super.key, this.emphasize = false});

  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
        color: emphasize ? HistoryPalette.inkMuted : HistoryPalette.inkFaint,
      ),
    );
  }
}
