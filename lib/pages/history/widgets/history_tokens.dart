import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bảng màu, "tone" ngữ nghĩa và tiện ích định dạng dùng chung cho
/// màn hình "Lịch sử hoạt động".
///
/// Trước đây các mã màu này nằm rải rác dưới dạng hex trong `history_page.dart`.
/// Gom về một chỗ để badge / thẻ / bottom sheet luôn nói cùng một ngôn ngữ màu.

/// Một bộ 4 màu mô tả trạng thái: nền nhạt, viền, chữ, và màu nhấn đậm.
@immutable
class HistoryTone {
  const HistoryTone({
    required this.surface,
    required this.border,
    required this.content,
    required this.accent,
  });

  /// Nền nhạt cho badge / hộp thông báo.
  final Color surface;

  /// Viền của badge / hộp thông báo / thẻ.
  final Color border;

  /// Màu chữ & icon đặt trên [surface].
  final Color content;

  /// Màu đậm nhất — dùng cho dải màu bên trái thẻ, thanh tiến trình, nút.
  final Color accent;
}

/// Màu nền / chữ trung tính của màn hình lịch sử.
abstract final class HistoryPalette {
  /// Nền của toàn trang.
  static const Color canvas = AppColors.tertiaryBlack;
  static const Color surface = Colors.white;

  /// Viền mặc định của thẻ khi không mang trạng thái đặc biệt.
  static const Color border = Color(0xFFE6E8EC);
  static const Color divider = Color(0xFFF0F1F4);

  static const Color ink = AppColors.primaryBlack;
  static const Color inkMuted = Color(0xFF6B7280);
  static const Color inkFaint = Color(0xFF9AA0A6);

  /// Đỏ khẩn cấp — sự cố, khiếu nại, thu hồi quyền.
  static const HistoryTone danger = HistoryTone(
    surface: Color(0xFFFFF1F2),
    border: Color(0xFFFECDD3),
    content: Color(0xFF9F1239),
    accent: Color(0xFFDC2626),
  );

  /// Xanh lá — phiên đang mở, sự cố đã xử lý.
  static const HistoryTone success = HistoryTone(
    surface: Color(0xFFE8F8F1),
    border: AppColors.secondaryGreen,
    content: Color(0xFF04795A),
    accent: AppColors.primaryGreen,
  );

  /// Hổ phách — chờ tiếp nhận, phiên sắp hết hạn.
  static const HistoryTone warning = HistoryTone(
    surface: Color(0xFFFFF7E6),
    border: Color(0xFFFCE3B0),
    content: Color(0xFF95590A),
    accent: Color(0xFFD97706),
  );

  /// Xanh dương — đang điều phối, toạ độ GPS, thẻ NFC.
  static const HistoryTone info = HistoryTone(
    surface: Color(0xFFEFF6FF),
    border: Color(0xFFBFDBFE),
    content: Color(0xFF1D4ED8),
    accent: Color(0xFF0284C7),
  );

  /// Cam thương hiệu.
  static const HistoryTone brand = HistoryTone(
    surface: AppColors.secondaryOrange,
    border: Color(0xFFFFD9B8),
    content: Color(0xFFB34D00),
    accent: AppColors.primaryOrange,
  );

  /// Xám — đã hết hạn, thông tin phụ.
  static const HistoryTone neutral = HistoryTone(
    surface: Color(0xFFF3F4F6),
    border: Color(0xFFE1E4E8),
    content: Color(0xFF5A616B),
    accent: Color(0xFF8A9099),
  );

  /// Tím — mã QR.
  static const HistoryTone violet = HistoryTone(
    surface: Color(0xFFF5F3FF),
    border: Color(0xFFDDD6FE),
    content: Color(0xFF6D28D9),
    accent: Color(0xFF8B5CF6),
  );

  /// Đổ bóng rất nhẹ, dùng chung cho mọi thẻ trong màn hình.
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F101828), blurRadius: 14, offset: Offset(0, 4)),
  ];
}

/// Nhãn + icon + tone của một trạng thái, để badge tự vẽ được.
@immutable
class HistoryStatusStyle {
  const HistoryStatusStyle({
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String label;
  final IconData icon;
  final HistoryTone tone;
}

/// Trạng thái của một **báo cáo sự cố** (`report['status']`).
HistoryStatusStyle reportStatusStyle(String status) {
  switch (status.toUpperCase()) {
    case 'DISPATCHED':
      return const HistoryStatusStyle(
        label: 'Đang điều phối',
        icon: PhosphorIconsFill.ambulance,
        tone: HistoryPalette.info,
      );
    case 'RESOLVED':
      return const HistoryStatusStyle(
        label: 'Đã xử lý',
        icon: PhosphorIconsFill.checkCircle,
        tone: HistoryPalette.success,
      );
    case 'PENDING':
    default:
      return const HistoryStatusStyle(
        label: 'Chờ tiếp nhận',
        icon: PhosphorIconsFill.clock,
        tone: HistoryPalette.warning,
      );
  }
}

/// Trạng thái của một **phiên truy cập** (`session['status']`).
HistoryStatusStyle accessStatusStyle(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLAINED':
      return const HistoryStatusStyle(
        label: 'Đã khiếu nại',
        icon: PhosphorIconsFill.warningOctagon,
        tone: HistoryPalette.danger,
      );
    case 'EXPIRED':
      return const HistoryStatusStyle(
        label: 'Đã hết hạn',
        icon: PhosphorIconsFill.clockCountdown,
        tone: HistoryPalette.neutral,
      );
    case 'ACTIVE':
    default:
      return const HistoryStatusStyle(
        label: 'Đang mở',
        icon: PhosphorIconsFill.shieldCheck,
        tone: HistoryPalette.success,
      );
  }
}

/// Icon + tone theo phương thức nhận diện (NFC / QR / FACE).
HistoryStatusStyle methodStyle(String? method) {
  final String normalized = (method ?? '').toUpperCase();
  switch (normalized) {
    case 'NFC':
      return const HistoryStatusStyle(
        label: 'NFC',
        icon: PhosphorIconsFill.creditCard,
        tone: HistoryPalette.info,
      );
    case 'QR':
      return const HistoryStatusStyle(
        label: 'QR',
        icon: PhosphorIconsFill.qrCode,
        tone: HistoryPalette.violet,
      );
    case 'FACE':
      return const HistoryStatusStyle(
        label: 'Khuôn mặt',
        icon: PhosphorIconsFill.userFocus,
        tone: HistoryPalette.brand,
      );
    default:
      return HistoryStatusStyle(
        label: normalized.isEmpty ? 'Khác' : normalized,
        icon: PhosphorIconsFill.shieldCheck,
        tone: HistoryPalette.neutral,
      );
  }
}

/// Nhãn vai trò của người đã truy xuất hồ sơ.
String historyRoleLabel(String? role) {
  return role == 'admin'
      ? 'Tổng đài / Y tế cấp cứu'
      : 'Người hỗ trợ hiện trường';
}

/// `2026-08-23T07:12:00Z` -> `14:12 - 23/08/2026` (giờ địa phương).
///
/// Giữ nguyên định dạng cũ của màn hình để không đổi cách người dùng đọc ngày.
String formatHistoryTimestamp(String? isoString) {
  if (isoString == null || isoString.isEmpty) return 'N/A';
  try {
    final DateTime dt = DateTime.parse(isoString).toLocal();
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
