import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/pages/identity_verification/identity_result_page.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _accessGranted = [];
  List<dynamic> _accessReceived = [];
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await AuthService.getHistory();
      if (mounted) {
        setState(() {
          _accessGranted = data['accessGranted'] as List<dynamic>? ?? [];
          _accessReceived = data['accessReceived'] as List<dynamic>? ?? [];
          _reports = data['reports'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final String day = dt.day.toString().padLeft(2, '0');
      final String month = dt.month.toString().padLeft(2, '0');
      final String year = dt.year.toString();
      final String hour = dt.hour.toString().padLeft(2, '0');
      final String minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute - $day/$month/$year';
    } catch (_) {
      return isoString;
    }
  }

  IconData _getMethodIcon(String? method) {
    switch (method?.toUpperCase()) {
      case 'NFC':
        return PhosphorIconsFill.creditCard;
      case 'QR':
        return PhosphorIconsFill.qrCode;
      case 'FACE':
        return PhosphorIconsFill.userFocus;
      default:
        return PhosphorIconsFill.shieldCheck;
    }
  }

  Color _getMethodColor(String? method) {
    switch (method?.toUpperCase()) {
      case 'NFC':
        return const Color(0xFF0284C7);
      case 'QR':
        return const Color(0xFF8B5CF6);
      case 'FACE':
        return AppColors.primaryOrange;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _openVictimRecord(BuildContext context, String victimId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      ),
    );

    try {
      final result = await AuthService.getVictimSession(victimId);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => IdentityResultPage(data: result)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải hồ sơ nạn nhân: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSessionStatusDialog(BuildContext context, {required String status}) {
    final bool isComplained = status.toUpperCase() == 'COMPLAINED';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isComplained ? PhosphorIconsFill.warningOctagon : PhosphorIconsFill.clockAfternoon,
              color: isComplained ? const Color(0xFFDC2626) : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isComplained ? 'Quyền truy cập đã bị hủy' : 'Phiên xem đã hết hạn',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          isComplained
              ? 'Nạn nhân đã khiếu nại phiên truy cập này. Vì lý do bảo mật và quyền riêng tư, quyền xem hồ sơ y tế đã bị vô hiệu hóa vĩnh viễn.'
              : 'Phiên truy cập 1 giờ đã hết hạn theo chính sách bảo mật dữ liệu y tế. Vui lòng quét lại thẻ NFC hoặc mã QR nếu nạn nhân vẫn cần hỗ trợ cứu nạn.',
          style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isComplained ? const Color(0xFFDC2626) : AppColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showReportDetailModal(BuildContext context, Map<String, dynamic> report) {
    final victim = report['victim'] is Map ? report['victim'] : null;
    final String? victimId = victim?['id'];
    final String victimName = victim?['fullName'] ?? 'Nạn nhân tại hiện trường';
    final String desc = report['situationDescription'] ?? 'Không có mô tả chi tiết';
    final String lat = report['locationLat'] ?? '';
    final String lon = report['locationLon'] ?? '';
    final String status = report['status'] ?? 'PENDING';
    final String date = _formatDate(report['createdAt']);
    final String reportId = (report['reportId'] ?? report['id'] ?? 'N/A').toString();
    final bool isIdentified = report['origin'] == 'identified';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        height: MediaQuery.of(modalCtx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.siren, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Chi tiết báo cáo sự cố',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(modalCtx).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mã sự cố: #${reportId.length > 8 ? reportId.substring(0, 8).toUpperCase() : reportId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isIdentified ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isIdentified ? 'Cứu trợ xác thực' : 'Báo cáo độc lập',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isIdentified ? const Color(0xFF15803D) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    if (victimName.isNotEmpty) ...[
                      const Text(
                        'Nạn nhân liên quan',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsFill.user, color: Color(0xFFDC2626)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                victimName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Tình trạng sự cố hiện trường',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF881337),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (lat.isNotEmpty && lon.isNotEmpty) ...[
                      const Text(
                        'Tọa độ định vị GPS hiện trường',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsFill.mapPin, color: Color(0xFF0284C7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$lat, $lon',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Bản đồ'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (victimId != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(modalCtx).pop();
                            _openVictimRecord(context, victimId);
                          },
                          icon: const Icon(PhosphorIconsFill.firstAid, size: 20),
                          label: const Text(
                            'Xem hồ sơ y tế nạn nhân',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccessReceivedDetailModal(BuildContext context, Map<String, dynamic> item) {
    final String sessionId = item['sessionId'] ?? '';
    final responder = item['responder'] is Map ? item['responder'] : null;
    final String responderName = responder?['name'] ?? 'Người hỗ trợ / Đội cứu nạn';
    final String role = responder?['role'] ?? 'citizen';
    final String method = item['method'] ?? 'NFC';
    final String grantedDate = _formatDate(item['grantedAt']);
    final String expiresDate = _formatDate(item['expiresAt']);
    final String status = item['status'] ?? 'ACTIVE';
    final bool isComplained = status.toUpperCase() == 'COMPLAINED';
    final bool canComplain = item['canComplain'] == true && !isComplained;
    final String? complaintReason = item['complaintReason'];
    final String? complainedAt = item['complainedAt'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        height: MediaQuery.of(modalCtx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isComplained ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.shieldCheck, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Nhật ký truy xuất hồ sơ y tế',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(modalCtx).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                            radius: 24,
                            child: const Icon(
                              PhosphorIconsFill.user,
                              color: AppColors.primaryOrange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  responderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  role == 'admin' ? 'Tổng đài / Y tế cấp cứu' : 'Người hỗ trợ hiện trường',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildAccessStatusBadge(status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Thông tin phiên truy xuất',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Phương thức quét', method),
                    _buildInfoRow('Thời điểm quét', grantedDate),
                    _buildInfoRow('Hết hạn lúc', expiresDate),
                    const Divider(height: 28),
                    if (isComplained) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(PhosphorIconsFill.warningCircle, color: Color(0xFFDC2626), size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Đã ghi nhận khiếu nại truy cập',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF881337),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Thời gian khiếu nại: ${_formatDate(complainedAt)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                            if (complaintReason != null && complaintReason.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Lý do: $complaintReason',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                              ),
                            ],
                            const SizedBox(height: 6),
                            const Text(
                              'Quyền truy cập của người này đã bị thu hồi vĩnh viễn và không thể quét lại.',
                              style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ] else if (canComplain) ...[
                      const Text(
                        'Bạn nghi ngờ phiên truy cập này không hợp lệ?',
                        style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(modalCtx).pop();
                            _showComplaintDialog(context, sessionId, responderName);
                          },
                          icon: const Icon(PhosphorIconsFill.warningOctagon, size: 20),
                          label: const Text(
                            'Báo cáo truy cập trái phép / Khiếu nại',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintDialog(BuildContext context, String sessionId, String responderName) {
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = 'Không có sự cố y tế nào';
    bool isSubmitting = false;

    final List<String> reasonPresets = [
      'Không có sự cố y tế nào',
      'Người lạ tự ý quét thẻ / QR',
      'Nghi ngờ truy cập trái phép',
      'Khác',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(PhosphorIconsFill.warningOctagon, color: Color(0xFFDC2626), size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Khiếu nại truy cập',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hành động này sẽ THU HỒI NGAY LẬP TỨC quyền xem hồ sơ y tế của "$responderName" và chặn vĩnh viễn người này quét lại.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chọn lý do khiếu nại:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: reasonPresets.map((r) {
                    final isSel = selectedReason == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: isSel,
                      selectedColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (sel) {
                        if (sel) {
                          setDlgState(() {
                            selectedReason = r;
                            if (r != 'Khác') {
                              reasonController.text = r;
                            } else {
                              reasonController.clear();
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú lý do chi tiết...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDlgState(() => isSubmitting = true);
                      try {
                        final String finalReason = reasonController.text.trim().isNotEmpty
                            ? reasonController.text.trim()
                            : selectedReason;

                        await AuthService.submitAccessComplaint(
                          sessionId,
                          reason: finalReason,
                        );

                        if (context.mounted) {
                          Navigator.of(dialogCtx).pop();
                          _loadHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã khiếu nại thành công. Quyền truy cập của người này đã bị khóa vĩnh viễn.'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi khiếu nại: ${e.toString().replaceAll("Exception: ", "")}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Xác nhận khiếu nại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toUpperCase()) {
      case 'DISPATCHED':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1D4ED8);
        label = 'Đang điều phối';
        break;
      case 'RESOLVED':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'Đã xử lý';
        break;
      case 'PENDING':
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'Chờ tiếp nhận';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAccessStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toUpperCase()) {
      case 'COMPLAINED':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        label = 'Đã khiếu nại';
        break;
      case 'EXPIRED':
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        label = 'Đã hết hạn';
        break;
      case 'ACTIVE':
      default:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'Đang mở';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Lịch sử hoạt động',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Đã cấp quyền'),
                Tab(text: 'Báo cáo sự cố'),
                Tab(text: 'Được truy xuất'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsBold.warningCircle, size: 54, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadHistory,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAccessGrantedTab(),
                    _buildReportsTab(),
                    _buildAccessReceivedTab(),
                  ],
                ),
    );
  }

  Widget _buildAccessGrantedTab() {
    if (_accessGranted.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIconsRegular.firstAid,
        title: 'Chưa có phiên cứu trợ nào',
        subtitle: 'Khi bạn quét NFC, QR hoặc khuôn mặt nạn nhân, phiên xem hồ sơ y tế sẽ hiển thị tại đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _accessGranted.length,
        itemBuilder: (context, index) {
          final item = _accessGranted[index] as Map<String, dynamic>;
          final victim = item['victim'] is Map ? item['victim'] : null;
          final String victimName = victim?['fullName'] ?? 'Nạn nhân tại hiện trường';
          final String? victimId = item['victimId'] ?? victim?['id'];
          final String method = item['method'] ?? 'NFC';
          final String status = item['status'] ?? 'ACTIVE';
          final bool canView = item['canView'] == true;
          final bool isComplained = status.toUpperCase() == 'COMPLAINED';
          final int secondsRemaining = item['secondsRemaining'] is int ? item['secondsRemaining'] : 0;
          final int minutesRemaining = (secondsRemaining / 60).ceil();
          final String grantedDate = _formatDate(item['grantedAt']);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: canView
                    ? const Color(0xFFBBF7D0)
                    : (isComplained ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (canView && victimId != null) {
                  _openVictimRecord(context, victimId);
                } else {
                  _showSessionStatusDialog(context, status: status);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getMethodColor(method).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getMethodIcon(method),
                        color: _getMethodColor(method),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  victimName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.primaryBlack,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSessionPill(canView: canView, status: status, minutesRemaining: minutesRemaining),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quét qua: $method • $grantedDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      color: canView ? AppColors.primaryOrange : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionPill({required bool canView, required String status, required int minutesRemaining}) {
    if (status.toUpperCase() == 'COMPLAINED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Bị khiếu nại',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: canView ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        canView ? 'Còn $minutesRemaining p' : 'Hết hạn',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: canView ? const Color(0xFF15803D) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIconsRegular.siren,
        title: 'Chưa có báo cáo sự cố nào',
        subtitle: 'Các sự cố khẩn cấp bạn đã gửi đến tổng đài 114 và người thân sẽ hiển thị tại đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final item = _reports[index] as Map<String, dynamic>;
          final victim = item['victim'] is Map ? item['victim'] : null;
          final String victimName = victim?['fullName'] ?? 'Nạn nhân hiện trường';
          final String desc = item['situationDescription'] ?? 'Báo cáo khẩn cấp';
          final String status = item['status'] ?? 'PENDING';
          final String date = _formatDate(item['createdAt']);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showReportDetailModal(context, item),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            PhosphorIconsFill.siren,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            victimName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'Chi tiết',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 11,
                              color: AppColors.primaryOrange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccessReceivedTab() {
    if (_accessReceived.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIconsRegular.shieldCheck,
        title: 'Chưa có lượt truy xuất nào',
        subtitle: 'Nhật ký bảo mật: Bất kỳ ai quét thẻ NFC hoặc mã QR hồ sơ y tế của bạn sẽ được ghi lại minh bạch tại đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _accessReceived.length,
        itemBuilder: (context, index) {
          final item = _accessReceived[index] as Map<String, dynamic>;
          final responder = item['responder'] is Map ? item['responder'] : null;
          final String responderName = responder?['name'] ?? 'Người hỗ trợ / Đội cứu hộ';
          final String method = item['method'] ?? 'NFC';
          final String grantedDate = _formatDate(item['grantedAt']);
          final String status = item['status'] ?? 'ACTIVE';
          final bool isComplained = status.toUpperCase() == 'COMPLAINED';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isComplained ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showAccessReceivedDetailModal(context, item),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isComplained ? const Color(0xFFDC2626) : const Color(0xFF10B981))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isComplained ? PhosphorIconsFill.warningOctagon : PhosphorIconsFill.shieldCheck,
                        color: isComplained ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  responderName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.primaryBlack,
                                  ),
                                ),
                              ),
                              _buildAccessStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phương thức: $method • $grantedDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primaryOrange),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
