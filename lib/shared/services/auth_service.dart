import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../../config/env.dart';

/// Luồng đăng nhập citizen (Typescript Backend):
/// 1. Người dùng nhấn "Đăng nhập với Google"
/// 2. [google_sign_in] mở màn hình chọn tài khoản Google
/// 3. Backend (Cognito Post-Confirmation Trigger) tự động tạo user trong DB.
/// 4. Lấy accessToken từ CognitoAuthSession
/// 5. Gọi GET /api/v1/read/citizen/profile để lấy dữ liệu về hiển thị
/// 6. Lưu token + profile vào SharedPreferences

class AuthService {
  // Nguồn duy nhất: lib/config/env.dart (Terraform output `api_endpoint`).
  static const String _baseUrl = Env.apiEndpoint;

  // =============================================
  // Google Sign-In → Backend /profile
  // =============================================

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
        options: const SignInWithWebUIOptions(
          pluginOptions: CognitoSignInWithWebUIPluginOptions(
            isPreferPrivateSession: true, 
          ),
        ),
      );

      if (!result.isSignedIn) {
        throw Exception('Đăng nhập không thành công');
      }

      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: true),
      ) as CognitoAuthSession;
      final accessToken = session.userPoolTokensResult.value.accessToken.raw;

      // Backend tự động đồng bộ user qua Cognito Trigger. 
      // Chỉ cần gọi GET Profile để lấy thông tin mới nhất.
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/read/citizen/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      Map<String, dynamic> data = {'role': 'citizen'};
      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        data['profile'] = profileData['profile'];
      } else {
        // First login fallback
        data['profile'] = {};
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('role', data['role']);
      await prefs.setString('profile', jsonEncode(data));

      return data;
    } catch (e) {
      safePrint('SignIn Error: $e');
      rethrow;
    }
  }

  // =============================================
  // Đăng xuất
  // =============================================

  static Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut(
        options: const SignOutOptions(globalSignOut: true),
      );
    } catch (e) {
      safePrint('SignOut Error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('profile');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // =============================================
  // Citizen: Hoàn thiện profile
  // =============================================

  static Future<Map<String, dynamic>> completeCitizenProfile(
    Map<String, dynamic> data,
  ) async {
    final token = await getAccessToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/write/citizen/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      final currentRaw = prefs.getString('profile');
      final current = currentRaw != null
          ? jsonDecode(currentRaw) as Map<String, dynamic>
          : <String, dynamic>{};
      final merged = <String, dynamic>{
        ...current,
        'citizen': (resData['profile'] ?? current['citizen'] ?? {})..['firstDeclareProfile'] = true,
      };
      await prefs.setString('profile', jsonEncode(merged));
      return resData;
    }
    throw Exception('Không thể hoàn thiện hồ sơ: ${response.body}');
  }

  // =============================================
  // Citizen: Cập nhật hồ sơ
  // =============================================

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final token = await getAccessToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/write/citizen/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      final currentRaw = prefs.getString('profile');
      final current = currentRaw != null
          ? jsonDecode(currentRaw) as Map<String, dynamic>
          : <String, dynamic>{};
      final merged = <String, dynamic>{
        ...current,
        'citizen': resData['profile'] ?? current['citizen'],
      };
      await prefs.setString('profile', jsonEncode(merged));
      return resData;
    }
    throw Exception('Lỗi cập nhật hồ sơ: ${response.body}');
  }

  static Future<void> acceptPrivacyPolicy() async {
    await updateProfile({'consentRegulation': true});
  }

  // =============================================
  // Citizen: Hồ sơ y tế (Medical Record)
  // =============================================

  static Future<Map<String, dynamic>> getMedicalRecord() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/read/citizen/medical-record'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi lấy hồ sơ y tế: ${response.body}');
  }

  static Future<Map<String, dynamic>> updateMedicalRecord(
    Map<String, dynamic> data,
  ) async {
    final token = await getAccessToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/write/citizen/medical-record'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi cập nhật hồ sơ y tế: ${response.body}');
  }

  // =============================================
  // Citizen: Đăng ký sinh trắc học khuôn mặt
  // =============================================

  static Future<Map<String, dynamic>> registerFace(String base64Image) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/write/citizen/face'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'imageBase64': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi đăng ký khuôn mặt: ${response.body}');
  }

  static Future<Map<String, dynamic>> fetchAndCacheProfile() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/read/citizen/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      final profile = resData['profile'];
      if (profile != null) {
        final prefs = await SharedPreferences.getInstance();
        final currentRaw = prefs.getString('profile');
        final current = currentRaw != null
            ? jsonDecode(currentRaw) as Map<String, dynamic>
            : <String, dynamic>{};
        final merged = <String, dynamic>{
          ...current,
          'citizen': profile,
        };
        await prefs.setString('profile', jsonEncode(merged));
      }
      return resData;
    }
    throw Exception('Lỗi lấy thông tin hồ sơ: ${response.body}');
  }

  // =============================================
  // Citizen: NFC Management
  // =============================================

  static Future<Map<String, dynamic>> linkNFCTag(
    String nfcId,
    String name,
  ) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/write/nfc'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'tagId': nfcId,
        'name': name,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi kích hoạt thẻ NFC: ${response.body}');
  }

  static Future<List<dynamic>> getNFCTags() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/read/citizen/nfc-tags'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tags'] ?? [];
    }
    throw Exception('Lỗi lấy danh sách thẻ NFC: ${response.body}');
  }

  static Future<void> updateNFCTagStatus(String nfcId, String status) async {
    throw Exception('API updateNFCTagStatus chưa được hỗ trợ ở Backend TS');
  }

  static Future<void> deleteNFCTag(String nfcId) async {
    throw Exception('API deleteNFCTag chưa được hỗ trợ ở Backend TS');
  }

  // =============================================
  // Citizen: QR Management (Chưa triển khai ở TS Backend)
  // =============================================

  static Future<List<dynamic>> getQRCodes() async {
    return []; // Tạm thời ẩn
  }

  static Future<Map<String, dynamic>> createQRCode(String name) async {
    throw Exception('API createQRCode chưa được hỗ trợ ở Backend TS');
  }

  static Future<void> updateQRCodeStatus(String qrId, String status) async {
    throw Exception('API updateQRCodeStatus chưa được hỗ trợ ở Backend TS');
  }

  static Future<void> deleteQRCode(String qrId) async {
    throw Exception('API deleteQRCode chưa được hỗ trợ ở Backend TS');
  }
  
  // =============================================
  // Identity Verification (NFC/QR/Face) - POST /api/v1/read/scan
  // =============================================

  static Future<Map<String, dynamic>> verifyIdentity({
    String? nfcId,
    String? qrId,
    required String hashedCitizenId,
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/read/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'method': qrId != null ? 'QR' : 'NFC',
        'tagId': nfcId ?? qrId,
        'hashId': hashedCitizenId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Lỗi xác minh danh tính');
  }

  static Future<Map<String, dynamic>> searchByFace({
    String? faceImageB64,
    List<double>? faceVector,
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/read/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'method': 'FACE',
        'imageBase64': faceImageB64,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Không tìm thấy thông tin nạn nhân');
  }

  // =============================================
  // Emergency Incident Reporting - POST /api/v1/write/emergency/report
  // =============================================

  static Future<Map<String, dynamic>> reportEmergency({
    String? victimId,
    required String locationLat,
    required String locationLon,
    String? situationDescription,
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/write/emergency/report'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (victimId != null) 'victimId': victimId,
        'locationLat': locationLat,
        'locationLon': locationLon,
        if (situationDescription != null)
          'situationDescription': situationDescription,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi gửi báo cáo khẩn cấp: ${response.body}');
  }

  // =============================================
  // Victim Re-Access - GET /api/v1/read/victim/:victimId
  // =============================================

  static Future<Map<String, dynamic>> getVictimSession(String victimId) async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/read/victim/$victimId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi truy cập hồ sơ nạn nhân: ${response.body}');
  }
}
