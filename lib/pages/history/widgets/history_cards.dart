import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'history_atoms.dart';
import 'history_card.dart';
import 'history_tokens.dart';

/// Ba loại thẻ danh sách của màn "Lịch sử hoạt động".
///
/// Các thẻ chỉ *đọc* dữ liệu thô từ API và dựng giao diện; mọi điều hướng
/// đều đẩy ngược ra ngoài qua callback để trang cha quyết định.

/// Gợi ý hành động ở góc phải chân thẻ: "Xem hồ sơ ›", "Chi tiết ›"...
class _ActionHint extends StatelessWidget {
  const _ActionHint(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryOrange,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(
          PhosphorIconsBold.caretRight,
          size: 12,
          color: AppColors.primaryOrange,
        ),
      ],
    );
  }
}

/// Tab "Đã cấp quyền": một phiên bạn được xem hồ sơ y tế của nạn nhân.
class AccessGrantedCard extends StatelessWidget {
  const AccessGrantedCard({
    super.key,
    required this.item,
    required this.onOpenRecord,
    required this.onBlocked,
  });

  final Map<String, dynamic> item;

  /// Phiên còn hiệu lực -> mở hồ sơ y tế của nạn nhân.
  final void Function(String victimId) onOpenRecord;

  /// Phiên đã hết hạn hoặc bị khiếu nại -> giải thích lý do.
  final void Function(String status) onBlocked;

  @override
  Widget build(BuildContext context) {
    final victim = item['victim'] is Map ? item['victim'] : null;
    final String victimName = victim?['fullName'] ?? 'Nạn nhân tại hiện trường';
    final String? victimId = item['victimId'] ?? victim?['id'];
    final String method = item['method'] ?? 'NFC';
    final String status = item['status'] ?? 'ACTIVE';
    final bool canView = item['canView'] == true;
    final bool isComplained = status.toUpperCase() == 'COMPLAINED';
    final int secondsRemaining = item['secondsRemaining'] is int
        ? item['secondsRemaining']
        : 0;
    final String grantedDate = formatHistoryTimestamp(item['grantedAt']);

    final HistoryStatusStyle methodInfo = methodStyle(method);

    // Dải màu của thẻ nói lên: còn mở được (xanh), hết hạn (xám), bị hủy (đỏ).
    final HistoryTone tone = isComplained
        ? HistoryPalette.danger
        : (canView ? HistoryPalette.success : HistoryPalette.neutral);

    final String badgeLabel = isComplained
        ? 'Bị khiếu nại'
        : (canView ? 'Đang mở' : 'Hết hạn');
    final IconData badgeIcon = isComplained
        ? PhosphorIconsFill.warningOctagon
        : (canView
              ? PhosphorIconsFill.shieldCheck
              : PhosphorIconsFill.clockCountdown);

    return HistoryCard(
      tone: tone,
      semanticLabel: '$victimName, $badgeLabel',
      onTap: () {
        if (canView && victimId != null) {
          onOpenRecord(victimId);
        } else {
          onBlocked(status);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HistoryCardHeader(
            leading: HistoryIconTile(
              icon: methodInfo.icon,
              color: methodInfo.tone.accent,
            ),
            title: victimName,
            subtitle: HistoryMetaRow(
              children: <Widget>[
                HistoryMethodChip(method: method),
                HistoryMetaText(grantedDate),
              ],
            ),
            trailing: HistoryBadge(
              label: badgeLabel,
              icon: badgeIcon,
              tone: tone,
              dense: true,
            ),
          ),
          HistoryCardFooter(
            child: _buildFooter(canView, isComplained, secondsRemaining),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool canView, bool isComplained, int secondsRemaining) {
    if (isComplained) {
      return HistoryStatusLine(
        icon: PhosphorIconsFill.lockKey,
        label: 'Quyền truy cập đã bị hủy',
        color: HistoryPalette.danger.accent,
      );
    }

    if (!canView) {
      return HistoryStatusLine(
        icon: PhosphorIconsFill.clockCountdown,
        label: 'Phiên xem đã hết hạn',
        color: HistoryPalette.neutral.content,
      );
    }

    return Row(
      children: <Widget>[
        Expanded(child: HistoryCountdown(secondsRemaining: secondsRemaining)),
        const SizedBox(width: 14),
        const _ActionHint('Xem hồ sơ'),
      ],
    );
  }
}

/// Tab "Báo cáo sự cố": một sự cố bạn đã gửi đi.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final victim = item['victim'] is Map ? item['victim'] : null;
    final String victimName = victim?['fullName'] ?? 'Nạn nhân hiện trường';
    final String desc = item['situationDescription'] ?? 'Báo cáo khẩn cấp';
    final String status = item['status'] ?? 'PENDING';
    final String date = formatHistoryTimestamp(item['createdAt']);
    final bool isIdentified = item['origin'] == 'identified';

    final HistoryStatusStyle statusStyle = reportStatusStyle(status);

    return HistoryCard(
      tone: statusStyle.tone,
      semanticLabel: 'Báo cáo sự cố, ${statusStyle.label}',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HistoryCardHeader(
            // Sự cố luôn là tình huống khẩn cấp -> giữ icon còi đỏ cố định,
            // còn tiến độ xử lý do dải màu và huy hiệu thể hiện.
            leading: HistoryIconTile(
              icon: PhosphorIconsFill.siren,
              color: HistoryPalette.danger.accent,
            ),
            // Mô tả tình huống là thứ giúp nhận ra báo cáo nhanh nhất,
            // nên đưa lên làm tiêu đề thay cho tên nạn nhân mặc định.
            title: desc,
            titleMaxLines: 2,
            subtitle: HistoryMetaRow(
              children: <Widget>[
                HistoryMetaText(victimName, emphasize: true),
                HistoryMetaText(date),
              ],
            ),
            trailing: HistoryBadge(
              label: statusStyle.label,
              icon: statusStyle.icon,
              tone: statusStyle.tone,
              dense: true,
            ),
          ),
          HistoryCardFooter(
            child: Row(
              children: <Widget>[
                Flexible(child: HistoryOriginBadge(isIdentified: isIdentified)),
                const SizedBox(width: 10),
                const _ActionHint('Chi tiết'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab "Được truy xuất": một lượt người khác xem hồ sơ y tế của bạn.
class AccessReceivedCard extends StatelessWidget {
  const AccessReceivedCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responder = item['responder'] is Map ? item['responder'] : null;
    final String responderName =
        responder?['name'] ?? 'Người hỗ trợ / Đội cứu hộ';
    final String role = responder?['role'] ?? 'citizen';
    final String method = item['method'] ?? 'NFC';
    final String grantedDate = formatHistoryTimestamp(item['grantedAt']);
    final String status = item['status'] ?? 'ACTIVE';
    final bool isComplained = status.toUpperCase() == 'COMPLAINED';
    final bool canComplain = item['canComplain'] == true && !isComplained;

    final HistoryStatusStyle statusStyle = accessStatusStyle(status);

    return HistoryCard(
      tone: statusStyle.tone,
      semanticLabel: '$responderName, ${statusStyle.label}',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HistoryCardHeader(
            leading: HistoryIconTile(
              icon: isComplained
                  ? PhosphorIconsFill.warningOctagon
                  : (role == 'admin'
                        ? PhosphorIconsFill.stethoscope
                        : PhosphorIconsFill.user),
              color: statusStyle.tone.accent,
            ),
            title: responderName,
            subtitle: HistoryMetaRow(
              children: <Widget>[
                HistoryMetaText(historyRoleLabel(role), emphasize: true),
                HistoryMethodChip(method: method),
                HistoryMetaText(grantedDate),
              ],
            ),
            trailing: HistoryBadge(
              label: statusStyle.label,
              icon: statusStyle.icon,
              tone: statusStyle.tone,
              dense: true,
            ),
          ),
          if (isComplained)
            HistoryCardFooter(
              child: HistoryStatusLine(
                icon: PhosphorIconsFill.lockKey,
                label: 'Đã thu hồi quyền truy cập vĩnh viễn',
                color: HistoryPalette.danger.accent,
              ),
            )
          // Cho người dùng thấy ngay là còn khiếu nại được, không cần mở modal.
          else if (canComplain)
            HistoryCardFooter(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: HistoryStatusLine(
                      icon: PhosphorIconsFill.warningCircle,
                      label: 'Bạn có thể khiếu nại phiên truy cập này',
                      color: HistoryPalette.danger.accent,
                    ),
                  ),
                  Icon(
                    PhosphorIconsBold.caretRight,
                    size: 13,
                    color: HistoryPalette.danger.accent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
