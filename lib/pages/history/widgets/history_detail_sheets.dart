import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'history_atoms.dart';
import 'history_card.dart';
import 'history_sheet.dart';
import 'history_tokens.dart';

/// Hai bottom sheet chi tiết của màn "Lịch sử hoạt động".

/// Màu nền dải tiêu đề của sheet "Nhật ký truy xuất" khi phiên bình thường.
const Color _slateHeader = Color(0xFF1E293B);

// =======================================================================
// Chi tiết báo cáo sự cố
// =======================================================================

class ReportDetailSheet extends StatelessWidget {
  const ReportDetailSheet({
    super.key,
    required this.report,
    required this.onOpenVictimRecord,
  });

  final Map<String, dynamic> report;

  /// Mở hồ sơ y tế của nạn nhân gắn với báo cáo này.
  final void Function(String victimId) onOpenVictimRecord;

  Future<void> _openMap(String lat, String lon) async {
    final uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final victim = report['victim'] is Map ? report['victim'] : null;
    final String? victimId = victim?['id'];
    final String victimName = victim?['fullName'] ?? 'Nạn nhân tại hiện trường';
    final String desc =
        report['situationDescription'] ?? 'Không có mô tả chi tiết';
    final String lat = report['locationLat'] ?? '';
    final String lon = report['locationLon'] ?? '';
    final String status = report['status'] ?? 'PENDING';
    final String date = formatHistoryTimestamp(report['createdAt']);
    final String reportId = (report['reportId'] ?? report['id'] ?? 'N/A')
        .toString();
    final bool isIdentified = report['origin'] == 'identified';

    final String shortId = reportId.length > 8
        ? reportId.substring(0, 8).toUpperCase()
        : reportId;
    final HistoryStatusStyle statusStyle = reportStatusStyle(status);

    return HistorySheet(
      headerColor: HistoryPalette.danger.accent,
      icon: PhosphorIconsFill.siren,
      title: 'Chi tiết báo cáo sự cố',
      subtitle: 'Mã sự cố #$shortId',
      heightFactor: 0.82,
      footer: victimId != null
          ? HistorySheetButton(
              label: 'Xem hồ sơ y tế nạn nhân',
              icon: PhosphorIconsFill.firstAid,
              color: AppColors.primaryGreen,
              onPressed: () {
                Navigator.of(context).pop();
                onOpenVictimRecord(victimId);
              },
            )
          : null,
      children: <Widget>[
        HistoryMetaRow(
          children: <Widget>[
            HistoryBadge(
              label: statusStyle.label,
              icon: statusStyle.icon,
              tone: statusStyle.tone,
            ),
            HistoryOriginBadge(isIdentified: isIdentified, dense: false),
            HistoryMetaText(date, emphasize: true),
          ],
        ),
        HistorySection(
          title: 'Tình trạng sự cố hiện trường',
          icon: PhosphorIconsFill.notepad,
          child: HistoryDataBlock(
            tone: HistoryPalette.danger,
            icon: PhosphorIconsFill.warningCircle,
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: HistoryPalette.danger.content,
              ),
            ),
          ),
        ),
        if (victimName.isNotEmpty)
          HistorySection(
            title: 'Nạn nhân liên quan',
            icon: PhosphorIconsFill.user,
            child: HistoryDataBlock(
              tone: HistoryPalette.neutral,
              icon: PhosphorIconsFill.user,
              child: Text(
                victimName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: HistoryPalette.ink,
                  height: 1.3,
                ),
              ),
            ),
          ),
        if (lat.isNotEmpty && lon.isNotEmpty)
          HistorySection(
            title: 'Tọa độ định vị GPS hiện trường',
            icon: PhosphorIconsFill.mapPin,
            child: HistoryDataBlock(
              tone: HistoryPalette.info,
              icon: PhosphorIconsFill.mapPin,
              onTap: () => _openMap(lat, lon),
              trailing: const _MapPill(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$lat, $lon',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: HistoryPalette.info.content,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Chạm để mở bằng ứng dụng bản đồ',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: HistoryPalette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HistoryPalette.info.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(PhosphorIconsBold.arrowSquareOut, size: 13, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'Bản đồ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// Chi tiết một lượt người khác truy xuất hồ sơ của mình
// =======================================================================

class AccessReceivedSheet extends StatelessWidget {
  const AccessReceivedSheet({
    super.key,
    required this.item,
    required this.onComplain,
  });

  final Map<String, dynamic> item;

  /// Mở luồng khiếu nại cho phiên truy cập này.
  final void Function(String sessionId, String responderName) onComplain;

  @override
  Widget build(BuildContext context) {
    final String sessionId = item['sessionId'] ?? '';
    final responder = item['responder'] is Map ? item['responder'] : null;
    final String responderName =
        responder?['name'] ?? 'Người hỗ trợ / Đội cứu nạn';
    final String role = responder?['role'] ?? 'citizen';
    final String method = item['method'] ?? 'NFC';
    final String grantedDate = formatHistoryTimestamp(item['grantedAt']);
    final String expiresDate = formatHistoryTimestamp(item['expiresAt']);
    final String status = item['status'] ?? 'ACTIVE';
    final bool isComplained = status.toUpperCase() == 'COMPLAINED';
    final bool canComplain = item['canComplain'] == true && !isComplained;
    final String? complaintReason = item['complaintReason'];
    final String? complainedAt = item['complainedAt'];

    final HistoryStatusStyle statusStyle = accessStatusStyle(status);

    return HistorySheet(
      headerColor: isComplained ? HistoryPalette.danger.accent : _slateHeader,
      icon: PhosphorIconsFill.shieldCheck,
      title: 'Nhật ký truy xuất hồ sơ y tế',
      subtitle: 'Minh bạch mọi lượt xem hồ sơ của bạn',
      heightFactor: 0.8,
      footer: canComplain
          ? HistorySheetButton(
              label: 'Báo cáo truy cập trái phép / Khiếu nại',
              icon: PhosphorIconsFill.warningOctagon,
              color: HistoryPalette.danger.accent,
              outlined: true,
              onPressed: () {
                Navigator.of(context).pop();
                onComplain(sessionId, responderName);
              },
            )
          : null,
      children: <Widget>[
        _ResponderBlock(
          responderName: responderName,
          role: role,
          statusStyle: statusStyle,
        ),
        HistorySection(
          title: 'Thông tin phiên truy xuất',
          icon: PhosphorIconsFill.info,
          child: HistoryInfoTable(
            rows: <HistoryInfoRow>[
              HistoryInfoRow(
                label: 'Phương thức quét',
                value: method,
                trailing: HistoryMethodChip(method: method),
              ),
              HistoryInfoRow(label: 'Thời điểm quét', value: grantedDate),
              HistoryInfoRow(label: 'Hết hạn lúc', value: expiresDate),
            ],
          ),
        ),
        if (isComplained)
          HistorySection(
            title: 'Kết quả khiếu nại',
            icon: PhosphorIconsFill.warningOctagon,
            child: HistoryNotice(
              tone: HistoryPalette.danger,
              icon: PhosphorIconsFill.warningCircle,
              title: 'Đã ghi nhận khiếu nại truy cập',
              children: <Widget>[
                const SizedBox(height: 10),
                Text(
                  'Thời gian khiếu nại: ${formatHistoryTimestamp(complainedAt)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: HistoryPalette.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (complaintReason != null &&
                    complaintReason.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    'Lý do: $complaintReason',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: HistoryPalette.danger.content,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      PhosphorIconsFill.lockKey,
                      size: 15,
                      color: HistoryPalette.danger.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Quyền truy cập của người này đã bị thu hồi vĩnh viễn và không thể quét lại.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: HistoryPalette.danger.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (canComplain)
          HistorySection(
            title: 'Bạn nghi ngờ phiên truy cập này không hợp lệ?',
            icon: PhosphorIconsFill.shieldStar,
            child: HistoryDataBlock(
              tone: HistoryPalette.warning,
              icon: PhosphorIconsFill.info,
              child: Text(
                'Gửi khiếu nại sẽ thu hồi ngay quyền xem hồ sơ y tế của người này và chặn họ quét lại.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: HistoryPalette.warning.content,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Khối giới thiệu người đã truy cập hồ sơ, ở đầu sheet.
class _ResponderBlock extends StatelessWidget {
  const _ResponderBlock({
    required this.responderName,
    required this.role,
    required this.statusStyle,
  });

  final String responderName;
  final String role;
  final HistoryStatusStyle statusStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HistoryPalette.neutral.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HistoryPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HistoryIconTile(
            icon: role == 'admin'
                ? PhosphorIconsFill.stethoscope
                : PhosphorIconsFill.user,
            color: statusStyle.tone.accent,
            size: 48,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  responderName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: HistoryPalette.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  historyRoleLabel(role),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: HistoryPalette.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: HistoryBadge(
                    label: statusStyle.label,
                    icon: statusStyle.icon,
                    tone: statusStyle.tone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
