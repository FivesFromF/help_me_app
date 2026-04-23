import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  /// Kiểm tra xem thiết bị có hỗ trợ NFC và đang bật hay không.
  static Future<bool> isAvailable() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      debugPrint('NFC Service: isAvailable = $available');
      return available;
    } catch (e) {
      debugPrint('NFC Service: Error checking availability: $e');
      return false;
    }
  }

  /// Hàm chung để bắt đầu một phiên NFC mới.
  static Future<void> startSession({
    required Future<void> Function(NfcTag tag) onTag,
    required Function(String error) onError,
  }) async {
    debugPrint('NFC Service: Starting session...');
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          debugPrint('NFC Service: Tag discovered! Data: ${tag.data}');
          try {
            await onTag(tag);
          } catch (e) {
            debugPrint('NFC Service: Error in onTag callback: $e');
            onError(e.toString());
            await NfcManager.instance.stopSession(errorMessage: e.toString());
          }
        },
        onError: (error) async {
          debugPrint('NFC Service: Session error: ${error.message}');
          onError(error.message);
        },
      );
    } catch (e) {
      debugPrint('NFC Service: Failed to start session: $e');
      onError(e.toString());
    }
  }

  /// Dừng phiên NFC.
  static Future<void> stopSession({String? errorMessage}) async {
    debugPrint('NFC Service: Stopping session... ${errorMessage ?? ""}');
    try {
      await NfcManager.instance.stopSession(errorMessage: errorMessage);
    } catch (e) {
      debugPrint('NFC Service: Error stopping session: $e');
    }
  }

  /// Lấy UID từ thẻ NFC.
  static String? getTagUid(NfcTag tag) {
    final platformData = tag.data;
    Object? identifier;

    // Android
    if (platformData.containsKey('nfca')) {
      identifier = platformData['nfca']['identifier'];
    } else if (platformData.containsKey('mifareclassic')) {
      identifier = platformData['mifareclassic']['identifier'];
    } else if (platformData.containsKey('isodep')) {
      identifier = platformData['isodep']['identifier'];
    } else if (platformData.containsKey('nfcv')) {
      identifier = platformData['nfcv']['identifier'];
    }
    // iOS
    else if (platformData.containsKey('mifare')) {
      identifier = platformData['mifare']['identifier'];
    }

    if (identifier == null) {
      debugPrint('NFC Service: Could not find identifier in platformData');
      return null;
    }

    String? uid;
    if (identifier is Uint8List) {
      uid = _formatUid(identifier);
    } else if (identifier is List<int>) {
      uid = _formatUid(Uint8List.fromList(identifier));
    }

    debugPrint('NFC Service: Formatted UID: $uid');
    return uid;
  }

  /// Ghi mã băm vào thẻ (phải gọi trong khi session đang chạy).
  static Future<bool> writeNdef(NfcTag tag, String text) async {
    debugPrint('NFC Service: Attempting to write NDEF text: $text');
    
    // Small delay before even getting Ndef object to let hardware settle
    await Future.delayed(const Duration(milliseconds: 300));
    
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      debugPrint('NFC Service: NDEF is not supported on this tag or tag was moved too fast');
      return false;
    }
    
    if (!ndef.isWritable) {
      debugPrint('NFC Service: Tag is not writable (maybe locked?)');
      return false;
    }

    final record = NdefRecord.createText(text);
    final message = NdefMessage([record]);

    try {
      // Increased delay to ensure hardware is ready after backend call/discovery
      await Future.delayed(const Duration(milliseconds: 500));
      
      await ndef.write(message);
      debugPrint('NFC Service: Write successful!');
      return true;
    } catch (e) {
      debugPrint('NFC Service: Initial write failed: $e. Retrying in 1 second...');
      try {
        await Future.delayed(const Duration(milliseconds: 1000));
        await ndef.write(message);
        debugPrint('NFC Service: Write successful on retry!');
        return true;
      } catch (retryError) {
        debugPrint('NFC Service: Write failed after retry: $retryError');
        // Check if tag is still there
        rethrow;
      }
    }
  }

  /// Đọc dữ liệu NDEF từ thẻ.
  static Future<String?> readNdef(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      debugPrint('NFC Service: NDEF not supported');
      return null;
    }

    try {
      final message = ndef.cachedMessage;
      if (message == null || message.records.isEmpty) {
        debugPrint('NFC Service: NDEF message is empty');
        return null;
      }

      for (var record in message.records) {
        if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
            listEquals(record.type, Uint8List.fromList([0x54]))) {
          // Type 'T' (Text)
          final payload = record.payload;
          if (payload.isEmpty) continue;
          
          // First byte is status (language code length)
          final langCodeLen = payload[0] & 0x3F;
          return utf8.decode(payload.sublist(1 + langCodeLen));
        }
      }
      return null;
    } catch (e) {
      debugPrint('NFC Service: Read error: $e');
      return null;
    }
  }

  static String _formatUid(Uint8List bytes) {
    if (bytes.isEmpty) return 'UNKNOWN';
    return bytes
        .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
}
