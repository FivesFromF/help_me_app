import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcCardData {
  const NfcCardData({
    required this.uid,
    this.hashedId,
  });

  /// Formatted hardware UID, e.g. "F0:79:CF:5F"
  final String uid;

  /// HMAC SHA-256 token / payload burned on the tag
  final String? hashedId;
}

class NfcService {
  NfcService._();

  /// Kiểm tra xem thiết bị có hỗ trợ NFC và đang bật hay không.
  static Future<bool> isAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      debugPrint('NFC Service: Error checking availability: $e');
      return false;
    }
  }

  /// Đọc mã serial phần cứng (UID) của thẻ NFC.
  static Future<String?> readTagUid({
    String iosAlertMessage = 'Đưa thẻ NFC lại gần để quét.',
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final tag = await FlutterNfcKit.poll(
        iosAlertMessage: iosAlertMessage,
        timeout: timeout,
      );
      final formatted = _formatUid(tag.id);
      debugPrint('NFC Service: Read Tag UID = $formatted');
      return formatted;
    } catch (e) {
      debugPrint('NFC Service: Error reading tag UID: $e');
      return null;
    } finally {
      await FlutterNfcKit.finish(iosAlertMessage: 'Đọc thẻ thành công!');
    }
  }

  /// Đọc cả UID và nội dung NDEF Text payload trong 1 lần chạm.
  static Future<NfcCardData?> readCardData({
    String iosAlertMessage = 'Đưa thẻ NFC lại gần để xác thực danh tính.',
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final tag = await FlutterNfcKit.poll(
        iosAlertMessage: iosAlertMessage,
        timeout: timeout,
      );

      final uid = _formatUid(tag.id);
      String? hashedId;

      if (tag.ndefAvailable == true) {
        try {
          final records = await FlutterNfcKit.readNDEFRecords(cached: false);
          if (records.isNotEmpty) {
            final first = records.first;
            if (first is ndef.TextRecord) {
              hashedId = first.text;
            } else if (first is ndef.UriRecord) {
              hashedId = first.uri?.toString();
            } else if (first.payload != null && first.payload!.isNotEmpty) {
              final raw = first.payload!;
              final langLen = raw[0] & 0x3F;
              if (raw.length > 1 + langLen) {
                hashedId = utf8.decode(raw.sublist(1 + langLen));
              }
            }
          }
        } catch (e) {
          debugPrint('NFC Service: Error reading NDEF records: $e');
        }
      }

      debugPrint('NFC Service: Parsed Card: UID=$uid, HashedId=$hashedId');
      return NfcCardData(uid: uid, hashedId: hashedId);
    } catch (e) {
      debugPrint('NFC Service: Error during readCardData: $e');
      return null;
    } finally {
      await FlutterNfcKit.finish(iosAlertMessage: 'Đọc thẻ hoàn tất!');
    }
  }

  /// Ghi mã băm vào thẻ NFC (NDEF Text Record).
  static Future<bool> writeNdef(
    String text, {
    String iosAlertMessage = 'Đưa thẻ NFC lại gần để ghi dữ liệu.',
    Duration timeout = const Duration(seconds: 20),
  }) async {
    assert(text.isNotEmpty, 'Nội dung ghi không được để trống');
    try {
      final tag = await FlutterNfcKit.poll(
        iosAlertMessage: iosAlertMessage,
        timeout: timeout,
      );

      if (tag.ndefWritable != true) {
        final errorMsg = tag.ndefAvailable != true
            ? 'Thẻ không hỗ trợ chuẩn NDEF.'
            : 'Thẻ ở chế độ chỉ đọc, không thể ghi.';
        debugPrint('NFC Service: $errorMsg');
        await FlutterNfcKit.finish(iosErrorMessage: errorMsg);
        return false;
      }

      await FlutterNfcKit.writeNDEFRecords([
        ndef.TextRecord(language: 'en', text: text),
      ]);

      debugPrint('NFC Service: Successfully written NDEF text: $text');
      return true;
    } catch (e) {
      debugPrint('NFC Service: Error writing NDEF: $e');
      return false;
    } finally {
      await FlutterNfcKit.finish(iosAlertMessage: 'Ghi thẻ thành công!');
    }
  }

  /// Dừng phiên NFC thủ công nếu cần.
  static Future<void> stopSession({String? errorMessage, String? alertMessage}) async {
    try {
      await FlutterNfcKit.finish(
        iosErrorMessage: errorMessage,
        iosAlertMessage: alertMessage,
      );
    } catch (e) {
      debugPrint('NFC Service: Error stopping session: $e');
    }
  }

  /// Định dạng chuỗi hex thành định dạng "AA:BB:CC:DD" chuẩn
  static String _formatUid(String rawId) {
    if (rawId.isEmpty) return 'UNKNOWN';
    final clean = rawId.replaceAll(':', '').replaceAll(' ', '').toUpperCase();
    if (clean.length % 2 == 0 && clean.length >= 8) {
      final buffer = StringBuffer();
      for (int i = 0; i < clean.length; i += 2) {
        buffer.write(clean.substring(i, i + 2));
        if (i + 2 < clean.length) buffer.write(':');
      }
      return buffer.toString();
    }
    return rawId.toUpperCase();
  }
}
