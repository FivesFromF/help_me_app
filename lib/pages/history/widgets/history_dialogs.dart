import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'history_tokens.dart';

/// Hộp thoại & thông báo dùng trong màn "Lịch sử hoạt động".

/// SnackBar dạng nổi, màu theo ngữ nghĩa.
void showHistorySnack(
  BuildContext context,
  String message, {
  required HistoryTone tone,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: tone.accent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// Lớp phủ chờ trong lúc tải hồ sơ y tế của nạn nhân.
void showHistoryLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        decoration: BoxDecoration(
          color: HistoryPalette.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: AppColors.primaryOrange),
            SizedBox(height: 16),
            Text(
              'Đang mở hồ sơ y tế...',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: HistoryPalette.inkMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Giải thích vì sao một phiên xem hồ sơ không còn mở được nữa.
void showHistorySessionStatusDialog(
  BuildContext context, {
  required String status,
}) {
  final bool isComplained = status.toUpperCase() == 'COMPLAINED';
  final HistoryTone tone = isComplained
      ? HistoryPalette.danger
      : HistoryPalette.warning;

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: HistoryPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tone.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplained
                  ? PhosphorIconsFill.warningOctagon
                  : PhosphorIconsFill.clockCountdown,
              color: tone.accent,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isComplained ? 'Quyền truy cập đã bị hủy' : 'Phiên xem đã hết hạn',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: HistoryPalette.ink,
              height: 1.3,
            ),
          ),
        ],
      ),
      content: Text(
        isComplained
            ? 'Nạn nhân đã khiếu nại phiên truy cập này. Vì lý do bảo mật và quyền riêng tư, quyền xem hồ sơ y tế đã bị vô hiệu hóa vĩnh viễn.'
            : 'Phiên truy cập 1 giờ đã hết hạn theo chính sách bảo mật dữ liệu y tế. Vui lòng quét lại thẻ NFC hoặc mã QR nếu nạn nhân vẫn cần hỗ trợ cứu nạn.',
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.55,
          color: HistoryPalette.inkMuted,
        ),
      ),
      actions: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isComplained
                  ? HistoryPalette.danger.accent
                  : AppColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Luồng khiếu nại một phiên truy cập trái phép.
///
/// [onComplaintSubmitted] được gọi sau khi API trả về thành công để trang cha
/// nạp lại lịch sử.
void showHistoryComplaintDialog(
  BuildContext context, {
  required String sessionId,
  required String responderName,
  required VoidCallback onComplaintSubmitted,
}) {
  final TextEditingController reasonController = TextEditingController();
  String selectedReason = 'Không có sự cố y tế nào';
  bool isSubmitting = false;

  final List<String> reasonPresets = [
    'Không có sự cố y tế nào',
    'Người lạ tự ý quét thẻ / QR',
    'Nghi ngờ truy cập trái phép',
    'Khác',
  ];

  const HistoryTone tone = HistoryPalette.danger;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setDlgState) => AlertDialog(
        backgroundColor: HistoryPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
        actionsPadding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
        title: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tone.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsFill.warningOctagon,
                color: tone.accent,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Khiếu nại truy cập',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: HistoryPalette.ink,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Nêu rõ hậu quả trước khi người dùng bấm xác nhận.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tone.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tone.border),
                ),
                child: Text(
                  'Hành động này sẽ THU HỒI NGAY LẬP TỨC quyền xem hồ sơ y tế của "$responderName" và chặn vĩnh viễn người này quét lại.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: tone.content,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn lý do khiếu nại:',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: HistoryPalette.ink,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: reasonPresets.map((r) {
                  final isSel = selectedReason == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: isSel,
                    showCheckmark: false,
                    selectedColor: tone.accent,
                    backgroundColor: HistoryPalette.neutral.surface,
                    side: BorderSide(
                      color: isSel ? tone.accent : HistoryPalette.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : HistoryPalette.inkMuted,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
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
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: HistoryPalette.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú lý do chi tiết...',
                  hintStyle: const TextStyle(
                    color: HistoryPalette.inkFaint,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: HistoryPalette.neutral.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HistoryPalette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tone.accent, width: 1.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HistoryPalette.border),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: isSubmitting
                ? null
                : () => Navigator.of(dialogCtx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: HistoryPalette.inkMuted,
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    setDlgState(() => isSubmitting = true);
                    try {
                      final String finalReason =
                          reasonController.text.trim().isNotEmpty
                          ? reasonController.text.trim()
                          : selectedReason;

                      await AuthService.submitAccessComplaint(
                        sessionId,
                        reason: finalReason,
                      );

                      if (context.mounted) {
                        Navigator.of(dialogCtx).pop();
                        onComplaintSubmitted();
                        showHistorySnack(
                          context,
                          'Đã khiếu nại thành công. Quyền truy cập của người này đã bị khóa vĩnh viễn.',
                          tone: HistoryPalette.success,
                        );
                      }
                    } catch (e) {
                      setDlgState(() => isSubmitting = false);
                      if (context.mounted) {
                        showHistorySnack(
                          context,
                          'Lỗi khiếu nại: ${e.toString().replaceAll("Exception: ", "")}',
                          tone: HistoryPalette.danger,
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: tone.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Xác nhận khiếu nại',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    ),
  );
}
