import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// Luồng đăng nhập citizen:
/// 1. Người dùng nhấn "Đăng nhập với Google"
/// 2. [google_sign_in] mở màn hình chọn tài khoản Google
/// 3. Lấy idToken từ GoogleAuth
/// 4. Gửi idToken lên Cognito để đổi lấy accessToken
///    (Trong MVP: gửi thẳng idToken lên backend /signin)
/// 5. Backend kiểm tra Cognito Group → trả về CitizenProfile
/// 6. Lưu token + profile vào SharedPreferences
/// 7. Chuyển đến màn hình Home (hoặc CompleteProfile nếu lần đầu)

class AuthService {
  static const String _baseUrl =
      'https://nv3jx897x9.execute-api.ap-southeast-1.amazonaws.com';

  // =============================================
  // Google Sign-In → Backend /signin
  // =============================================

  /// Trả về profile từ backend sau khi đăng nhập thành công qua Amplify.
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 1. Kích hoạt Amplify Social Login (Mở trình duyệt Hosted UI)
      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
        options: const SignInWithWebUIOptions(
          pluginOptions: CognitoSignInWithWebUIPluginOptions(
            isPreferPrivateSession: true, // Ép dùng chế độ ẩn danh (iOS)
          ),
        ),
      );

      if (!result.isSignedIn) {
        throw Exception('Đăng nhập không thành công');
      }

      // 2. Lấy Token từ Cognito
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final accessToken = session.userPoolTokensResult.value.accessToken.raw;
      final idToken = session.userPoolTokensResult.value.idToken.raw;

      // 3. Gửi idToken lên backend để đồng bộ DB và lấy Citizen Profile
      // Chúng ta gửi idToken vào trường 'accessToken' của payload 
      // vì backend dùng nó để parse Email và Name.
      final response = await http.post(
        Uri.parse('$_baseUrl/write-service/signin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'accessToken': idToken}),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend lỗi đồng bộ: ${response.body}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // Lưu profile vào SharedPreferences để dùng cho các màn hình khác
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('role', data['role'] ?? 'citizen');
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
      // 1. Chờ đợi Amplify thực hiện đăng xuất hoàn toàn (bao gồm cả việc mở/đóng trình duyệt)
      await Amplify.Auth.signOut(
        options: const SignOutOptions(globalSignOut: true),
      );
    } catch (e) {
      safePrint('SignOut Error: $e');
    }

    // 2. Sau khi đã đăng xuất trên Server, tiến hành xóa dữ liệu cục bộ
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // =============================================
  // Helpers: Đọc thông tin đã lưu
  // =============================================

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
  // Citizen: Hoàn thiện profile sau lần đăng nhập đầu
  // =============================================

  static Future<Map<String, dynamic>> completeCitizenProfile(
    Map<String, dynamic> data,
  ) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/write-service/user/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      print('AuthService: Profile completion response: $resData');
      // Preserve cached envelope shape: { citizen: {...}, role, accessToken }
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
  // Citizen: Cập nhật hồ sơ (Hợp nhất)
  // =============================================

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final token = await getAccessToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/write-service/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      // Preserve cached envelope shape: { citizen: {...}, role, accessToken }
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

  static Future<Map<String, dynamic>> getMedicalRecord() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/read-service/user/medical-record'),
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

  /// Lấy Profile mới nhất từ server và lưu vào cache
  static Future<Map<String, dynamic>> fetchAndCacheProfile() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/read-service/user/profile'),
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
  // Staff/Admin: Sign In (Email + Password — qua Cognito)
  // Staff không dùng Google, được Admin tạo tay trên Cognito Console
  // =============================================

  static Future<Map<String, dynamic>> staffSignIn(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/write-service/signin'),
      headers: {'Content-Type': 'application/json'},
      // Staff dùng Cognito USER_PASSWORD_AUTH flow trực tiếp
      // Trong MVP: gửi email/password, backend tự call Cognito InitiateAuth
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      // Save Token and Profile
      if (data.containsKey('accessToken')) {
        await prefs.setString('access_token', data['accessToken']);
      }

      await prefs.setString('role', data['role'] ?? 'staff');
      await prefs.setString('profile', jsonEncode(data));
      return data;
    }
    throw Exception('Đăng nhập thất bại: ${response.body}');
  }

  // =============================================
  // Admin API helpers
  // =============================================

  static Future<Map<String, dynamic>> getSystemStats() async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/write-service/admin/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Lỗi lấy thống kê: ${response.body}');
  }

  static Future<Map<String, dynamic>> registerStaff(
    Map<String, dynamic> staffData,
  ) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/write-service/admin/staff/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(staffData),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Lỗi đăng ký staff: ${response.body}');
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
      Uri.parse('$_baseUrl/write-service/user/nfc/link'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nfcId': nfcId,
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
      Uri.parse('$_baseUrl/read-service/user/nfc'),
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
    final token = await getAccessToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/write-service/user/nfc/$nfcId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Lỗi cập nhật trạng thái thẻ: ${response.body}');
    }
  }

  static Future<void> deleteNFCTag(String nfcId) async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/write-service/user/nfc/$nfcId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Lỗi gỡ thẻ NFC: ${response.body}');
    }
  }

  // =============================================
  // Citizen: QR Management
  // =============================================

  static Future<List<dynamic>> getQRCodes() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/read-service/user/qr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['qrcodes'] ?? [];
    }
    throw Exception('Lỗi lấy danh sách mã QR: ${response.body}');
  }

  static Future<Map<String, dynamic>> createQRCode(String name) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/write-service/user/qr/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi tạo mã QR: ${response.body}');
  }

  static Future<void> updateQRCodeStatus(String qrId, String status) async {
    final token = await getAccessToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/write-service/user/qr/$qrId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Lỗi cập nhật trạng thái mã QR: ${response.body}');
    }
  }

  static Future<void> deleteQRCode(String qrId) async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/write-service/user/qr/$qrId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Lỗi xóa mã QR: ${response.body}');
    }
  }
  
  // =============================================
  // Identity Verification (NFC/QR)
  // =============================================

  /// Xác định danh tính nạn nhân thông qua NFC hoặc QR.
  /// Trả về { profile, medicalRecord, emergencyContacts }
  static Future<Map<String, dynamic>> verifyIdentity({
    String? nfcId,
    String? qrId,
    required String hashedCitizenId,
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/read-service/user/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nfcId': nfcId,
        'qrId': qrId,
        'hashedCitizenId': hashedCitizenId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Lỗi xác minh danh tính');
  }

  // =============================================
  // Identity Verification (Face Recognition)
  // =============================================

  /// Tìm kiếm danh tính nạn nhân thông qua khuôn mặt.
  /// Trả về { profile, medicalRecord, emergencyContacts }
  static Future<Map<String, dynamic>> searchByFace({
    String? faceImageB64,
    List<double>? faceVector,
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/read-service/user/search'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'faceImageB64': faceImageB64,
        'faceVector': faceVector,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Không tìm thấy thông tin nạn nhân');
  }
}
