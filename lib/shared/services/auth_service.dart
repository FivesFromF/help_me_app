import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Google Sign-In ID phải khớp với Google Console project của bạn
  // và với cái đã cấu hình trong Cognito Identity Provider
  static const String _googleClientId =
      'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _googleClientId,
    scopes: ['email', 'profile', 'openid'],
  );

  // =============================================
  // Google Sign-In → Backend /signin
  // =============================================

  /// Trả về profile từ backend sau khi đăng nhập thành công.
  /// Ném [Exception] nếu thất bại.
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    // 1. Kích hoạt Google Sign-In dialog
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // Người dùng đóng dialog
      throw Exception('Đăng nhập bị hủy');
    }

    // 2. Lấy authentication tokens
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Không lấy được Google ID Token');
    }

    // 3. Gửi token lên backend
    final response = await http.post(
      Uri.parse('$_baseUrl/write-service/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Backend lỗi: ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    // 4. Lưu token + role + profile vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', idToken);
    await prefs.setString('role', data['role'] ?? 'citizen');
    await prefs.setString('profile', jsonEncode(data));

    return data;
  }

  // =============================================
  // Đăng xuất
  // =============================================

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
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
      Map<String, dynamic> data) async {
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
      return jsonDecode(response.body);
    }
    throw Exception('Không thể hoàn thiện hồ sơ: ${response.body}');
  }

  // =============================================
  // Staff/Admin: Sign In (Email + Password — qua Cognito)
  // Staff không dùng Google, được Admin tạo tay trên Cognito Console
  // =============================================

  static Future<Map<String, dynamic>> staffSignIn(
      String email, String password) async {
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
      Map<String, dynamic> staffData) async {
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
}
