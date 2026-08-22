import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
            isPreferPrivateSession: false, // Allows selecting already signed-in Google accounts from the browser
          ),
        ),
      );

      if (!result.isSignedIn) {
        throw Exception('Đăng nhập không thành công');
      }

      String accessToken = '';
      if (session is CognitoAuthSession) {
        try {
          accessToken = session.userPoolTokensResult.value.accessToken.raw;
        } catch (e) {
          safePrint('Tokens not available directly from session: $e');
        }
      }

      String email = '';
      try {
        final attributes = await Amplify.Auth.fetchUserAttributes();
        for (final attr in attributes) {
          if (attr.userAttributeKey == AuthUserAttributeKey.email) {
            email = attr.value;
            break;
          }
        }
      } catch (e) {
        safePrint('Error fetching user attributes on signIn: $e');
      }

      // Backend tự động đồng bộ user qua Cognito Trigger. 
      // Chỉ cần gọi GET Profile để lấy thông tin mới nhất.
      Map<String, dynamic> data = {'role': 'citizen'};
      try {
        final response = await http
            .get(
              Uri.parse('$_baseUrl/api/v1/read/citizen/profile'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final profileData = jsonDecode(response.body);
          final profile = profileData['profile'] ?? {};
          if (email.isNotEmpty &&
              (profile['email'] == null ||
                  profile['email'].toString().isEmpty)) {
            profile['email'] = email;
          }
          data['profile'] = profile;
          data['citizen'] = profile;
        } else {
          final skeleton = {
            'email': email,
            'firstDeclareProfile': false,
            'consentRegulation': false,
          };
          data['profile'] = skeleton;
          data['citizen'] = skeleton;
        }
      } catch (e) {
        safePrint('Profile fetch network note: $e');
        final skeleton = {
          'email': email,
          'firstDeclareProfile': false,
          'consentRegulation': false,
        };
        data['profile'] = skeleton;
        data['citizen'] = skeleton;
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
  // Lấy Email của người dùng hiện tại
  // =============================================

  static Future<String?> getUserEmail() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      for (final attr in attributes) {
        if (attr.userAttributeKey == AuthUserAttributeKey.email) {
          return attr.value;
        }
      }
    } catch (e) {
      safePrint('Error fetching user email: $e');
    }
    final profile = await getCachedProfile();
    return profile?['citizen']?['email'] ?? profile?['profile']?['email'];
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
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn && session is CognitoAuthSession) {
        final tokens = session.userPoolTokensResult.value;
        final rawToken = tokens.accessToken.raw;
        if (rawToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', rawToken);
          return rawToken;
        }
      }
    } catch (e) {
      safePrint('Amplify token fetch / refresh note: $e');
    }
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
  // Async S3 Upload & AI Job Polling
  // =============================================

  static Future<Map<String, dynamic>> getUploadUrl({
    required String operation,
    String? citizenId,
    String fileType = 'image/jpeg',
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/write/upload-url'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'operation': operation,
        'fileType': fileType,
        if (citizenId != null) 'citizenId': citizenId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Lỗi tạo URL tải ảnh: ${response.body}');
  }

  static Future<void> uploadBytesToS3({
    required String uploadUrl,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Tải ảnh lên S3 thất bại: mã lỗi ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> pollScanJob({
    required String jobId,
    int maxAttempts = 20,
    Duration interval = const Duration(seconds: 1),
  }) async {
    final token = await getAccessToken();
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);

      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/read/scan/jobs/$jobId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final job = data['job'];
        if (job != null) {
          final status = job['status'];
          if (status == 'COMPLETED') {
            final result = job['result'] ?? job;
            return _deepCastMap(result);
          } else if (status == 'FAILED') {
            final error = job['error'] ?? 'Xử lý hình ảnh thất bại';
            throw Exception(error);
          }
        }
      }
    }
    throw TimeoutException('Hết thời gian chờ xử lý khuôn mặt');
  }

  // =============================================
  // Citizen: Đăng ký sinh trắc học khuôn mặt
  // =============================================

  static Future<Map<String, dynamic>> registerFace({
    String? base64Image,
    String? filePath,
    List<int>? imageBytes,
  }) async {
    List<int> bytes;
    if (imageBytes != null) {
      bytes = imageBytes;
    } else if (filePath != null) {
      bytes = await File(filePath).readAsBytes();
    } else if (base64Image != null && base64Image.isNotEmpty) {
      bytes = base64Decode(
        base64Image.contains(',') ? base64Image.split(',').last : base64Image,
      );
    } else {
      throw Exception('Thiếu dữ liệu hình ảnh khuôn mặt');
    }

    // Get current citizen ID
    final profileData = await getCachedProfile();
    final citizen = profileData?['citizen'] ?? profileData?['profile'];
    final citizenId = citizen?['id'] ?? citizen?['cognitoId'];

    // 1. Get presigned S3 upload URL for FACE_ENROLL
    final uploadInfo = await getUploadUrl(
      operation: 'FACE_ENROLL',
      citizenId: citizenId?.toString(),
      fileType: 'image/jpeg',
    );

    final uploadUrl = uploadInfo['uploadUrl'] as String;
    final jobId = uploadInfo['jobId'] as String;

    // 2. Upload raw JPEG bytes directly to S3
    await uploadBytesToS3(uploadUrl: uploadUrl, bytes: bytes);

    // 3. Poll AI worker scan job in DynamoDB
    final result = await pollScanJob(jobId: jobId);

    // 4. Refresh local profile cache
    await fetchAndCacheProfile().catchError((_) => <String, dynamic>{});

    return result;
  }

  static Future<Map<String, dynamic>> fetchAndCacheProfile() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/read/citizen/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final prefs = await SharedPreferences.getInstance();
    final currentRaw = prefs.getString('profile');
    final current = currentRaw != null
        ? jsonDecode(currentRaw) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      final profile = resData['profile'] ?? {};
      final merged = <String, dynamic>{
        ...current,
        'citizen': profile,
        'profile': profile,
      };
      await prefs.setString('profile', jsonEncode(merged));
      return {'profile': profile, 'citizen': profile};
    } else if (response.statusCode == 404) {
      final skeleton = <String, dynamic>{
        'firstDeclareProfile': false,
        'consentRegulation': false,
      };
      final merged = <String, dynamic>{
        ...current,
        'citizen': skeleton,
        'profile': skeleton,
      };
      await prefs.setString('profile', jsonEncode(merged));
      return {'profile': skeleton, 'citizen': skeleton};
    }
    throw Exception('Lỗi lấy thông tin hồ sơ: ${response.body}');
  }

  // =============================================
  // Citizen: Credentials Management (NFC & QR)
  // =============================================

  static Future<Map<String, dynamic>> getCredentials() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/read/citizen/credentials'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return _deepCastMap(decoded);
    }
    throw Exception('Lỗi lấy danh sách thẻ và mã QR: ${response.body}');
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
      return _deepCastMap(jsonDecode(response.body));
    }
    throw Exception('Lỗi kích hoạt thẻ NFC: ${response.body}');
  }

  static Future<List<dynamic>> getNFCTags() async {
    try {
      final creds = await getCredentials();
      return creds['nfcTags'] ?? [];
    } catch (_) {
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
      return [];
    }
  }

  static Future<void> updateNFCTagStatus(String nfcId, String status) async {
    final token = await getAccessToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/v1/write/nfc/$nfcId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Lỗi cập nhật trạng thái thẻ NFC');
    }
  }

  static Future<void> deleteNFCTag(String nfcId) async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/write/nfc/$nfcId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Lỗi gỡ liên kết thẻ NFC');
    }
  }

  // =============================================
  // Citizen: QR Management
  // =============================================

  static Future<List<dynamic>> getQRCodes() async {
    final creds = await getCredentials();
    return creds['qrCodes'] ?? [];
  }

  static Future<Map<String, dynamic>> createQRCode(String name) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/write/qr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _deepCastMap(jsonDecode(response.body));
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Lỗi tạo mã QR cứu hộ');
  }

  static Future<void> updateQRCodeStatus(String qrId, String status) async {
    final token = await getAccessToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/v1/write/qr/$qrId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Lỗi cập nhật trạng thái mã QR');
    }
  }

  static Future<void> deleteQRCode(String qrId) async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/write/qr/$qrId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Lỗi xóa mã QR');
    }
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
        if (nfcId != null) 'tagId': nfcId,
        if (qrId != null) 'qrId': qrId,
        'hashId': hashedCitizenId,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return _deepCastMap(decoded);
    }
    
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Lỗi xác minh danh tính');
  }

  static Map<String, dynamic> _deepCastMap(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), v is Map ? _deepCastMap(v) : v),
      );
    }
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> searchByFace({
    String? faceImageB64,
    String? filePath,
    List<int>? imageBytes,
    List<double>? faceVector,
  }) async {
    List<int> bytes;
    if (imageBytes != null) {
      bytes = imageBytes;
    } else if (filePath != null) {
      bytes = await File(filePath).readAsBytes();
    } else if (faceImageB64 != null && faceImageB64.isNotEmpty) {
      bytes = base64Decode(
        faceImageB64.contains(',') ? faceImageB64.split(',').last : faceImageB64,
      );
    } else {
      throw Exception('Thiếu dữ liệu hình ảnh khuôn mặt');
    }

    // 1. Get presigned S3 upload URL for FACE_SCAN
    final uploadInfo = await getUploadUrl(
      operation: 'FACE_SCAN',
      fileType: 'image/jpeg',
    );

    final uploadUrl = uploadInfo['uploadUrl'] as String;
    final jobId = uploadInfo['jobId'] as String;

    // 2. Upload raw JPEG bytes directly to S3
    await uploadBytesToS3(uploadUrl: uploadUrl, bytes: bytes);

    // 3. Poll AI worker scan job in DynamoDB
    final result = await pollScanJob(jobId: jobId, maxAttempts: 20);

    if (result['matchStatus'] == 'NO_MATCH') {
      throw Exception('Không tìm thấy thông tin nạn nhân khớp trong hệ thống');
    } else if (result['matchStatus'] == 'ACCESS_REVOKED') {
      throw Exception('Truy cập hồ sơ công dân đã bị thu hồi do khiếu nại');
    }

    return result;
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
      return _deepCastMap(jsonDecode(response.body));
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Lỗi truy cập hồ sơ nạn nhân');
  }

  // =============================================
  // Citizen History - GET /api/v1/read/citizen/history
  // =============================================

  static Future<Map<String, dynamic>> getHistory() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/read/citizen/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return _deepCastMap(jsonDecode(response.body));
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Lỗi tải lịch sử hoạt động');
  }

  // =============================================
  // Access Complaint - POST /api/v1/write/access/:sessionId/complain
  // =============================================

  static Future<Map<String, dynamic>> submitAccessComplaint(
    String sessionId, {
    String? reason,
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/write/access/$sessionId/complain'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }),
    );

    if (response.statusCode == 200) {
      return _deepCastMap(jsonDecode(response.body));
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Lỗi khiếu nại phiên truy cập');
  }
}
