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

  /// Chuyển đổi đệ quy bất kỳ Map/List nào từ Platform channel thành Map<String, dynamic> chuẩn
  static Map<String, dynamic> _deepCastMap(Map dynamicMap) {
    final Map<String, dynamic> result = {};
    dynamicMap.forEach((key, value) {
      final stringKey = key.toString();
      if (value is Map) {
        result[stringKey] = _deepCastMap(value);
      } else if (value is List) {
        result[stringKey] = _deepCastList(value);
      } else {
        result[stringKey] = value;
      }
    });
    return result;
  }

  static List<dynamic> _deepCastList(List dynamicList) {
    return dynamicList.map((item) {
      if (item is Map) {
        return _deepCastMap(item);
      } else if (item is List) {
        return _deepCastList(item);
      }
      return item;
    }).toList();
  }

  static NfcTag _sanitizeTag(NfcTag tag) {
    final sanitizedData = _deepCastMap(tag.data);
    return NfcTag(
      handle: tag.handle,
      data: sanitizedData,
    );
  }

  /// Lấy UID từ thẻ NFC.
  static String? getTagUid(NfcTag tag) {
    final platformData = tag.data;
    Object? identifier;

    // Android
    if (platformData.containsKey('nfca') && platformData['nfca'] is Map) {
      identifier = platformData['nfca']['identifier'];
    } else if (platformData.containsKey('mifareclassic') && platformData['mifareclassic'] is Map) {
      identifier = platformData['mifareclassic']['identifier'];
    } else if (platformData.containsKey('isodep') && platformData['isodep'] is Map) {
      identifier = platformData['isodep']['identifier'];
    } else if (platformData.containsKey('nfcv') && platformData['nfcv'] is Map) {
      identifier = platformData['nfcv']['identifier'];
    }
    // iOS
    else if (platformData.containsKey('mifare') && platformData['mifare'] is Map) {
      identifier = platformData['mifare']['identifier'];
    }

    if (identifier == null) {
      debugPrint('NFC Service: Could not find identifier in platformData');
      return null;
    }

    String? uid;
    if (identifier is Uint8List) {
      uid = _formatUid(identifier);
    } else if (identifier is List) {
      uid = _formatUid(Uint8List.fromList(identifier.cast<int>()));
    }

    debugPrint('NFC Service: Formatted UID: $uid');
    return uid;
  }

  /// Ghi mã băm vào thẻ (phải gọi trong khi session đang chạy).
  static Future<bool> writeNdef(NfcTag tag, String text) async {
    debugPrint('NFC Service: Attempting to write NDEF text: $text');
    
    // Small delay before getting Ndef object to let hardware settle
    await Future.delayed(const Duration(milliseconds: 300));
    
    final sanitized = _sanitizeTag(tag);
    final ndef = Ndef.from(sanitized);
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
        rethrow;
      }
    }
  }

  /// Đọc dữ liệu NDEF từ thẻ một cách an toàn (tránh lỗi cast _Map<dynamic, dynamic> trên Android).
  static Future<String?> readNdef(NfcTag tag) async {
    try {
      final platformData = tag.data;

      // Cách 1: Đọc trực tiếp từ cachedMessage trong raw platformData để không bị lỗi type cast của plugin
      if (platformData.containsKey('ndef') && platformData['ndef'] is Map) {
        final ndefData = platformData['ndef'] as Map;
        if (ndefData.containsKey('cachedMessage') && ndefData['cachedMessage'] is Map) {
          final cachedMsg = ndefData['cachedMessage'] as Map;
          if (cachedMsg.containsKey('records') && cachedMsg['records'] is List) {
            final records = cachedMsg['records'] as List;
            for (final record in records) {
              if (record is Map && record.containsKey('payload')) {
                final rawPayload = record['payload'];
                if (rawPayload is List && rawPayload.isNotEmpty) {
                  final List<int> payload = rawPayload.cast<int>();
                  // Byte đầu tiên là độ dài mã ngôn ngữ (status byte)
                  final langCodeLen = payload[0] & 0x3F;
                  if (payload.length > 1 + langCodeLen) {
                    final text = utf8.decode(payload.sublist(1 + langCodeLen));
                    debugPrint('NFC Service: Successfully decoded NDEF Text directly: $text');
                    return text;
                  }
                }
              }
            }
          }
        }
      }

      // Cách 2: Fallback qua Ndef.from với sanitized tag
      final sanitized = _sanitizeTag(tag);
      final ndef = Ndef.from(sanitized);
      if (ndef != null && ndef.cachedMessage != null) {
        for (var record in ndef.cachedMessage!.records) {
          if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
              listEquals(record.type, Uint8List.fromList([0x54]))) {
            final payload = record.payload;
            if (payload.isEmpty) continue;
            final langCodeLen = payload[0] & 0x3F;
            final text = utf8.decode(payload.sublist(1 + langCodeLen));
            debugPrint('NFC Service: Successfully decoded NDEF Text via Ndef.from: $text');
            return text;
          }
        }
      }

      debugPrint('NFC Service: No valid NDEF text payload found');
      return null;
    } catch (e, stack) {
      debugPrint('NFC Service: Error in readNdef: $e\n$stack');
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
