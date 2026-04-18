import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Replace with your actual backend URL
  static const String baseUrl = 'https://nv3jx897x9.execute-api.ap-southeast-1.amazonaws.com';

  // Citizen: Request OTP
  static Future<Map<String, dynamic>> requestOTP(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/write-service/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('=== API GATEWAY ERROR === code: ${response.statusCode}, body: ${response.body}');
      throw Exception('Failed to request OTP: ${response.body}');
    }
  }

  // Citizen: Verify OTP
  static Future<Map<String, dynamic>> verifyOTP(String phone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/write-service/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }

  // Staff/Admin: Sign In
  static Future<Map<String, dynamic>> staffSignIn(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/write-service/staff-signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  }

  // Admin: Get System Stats
  static Future<Map<String, dynamic>> getSystemStats(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/write-service/admin/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get stats: ${response.body}');
    }
  }

  // Admin: List Audit Logs
  static Future<Map<String, dynamic>> listAuditLogs(String token, {int limit = 20, String? nextToken}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/write-service/admin/logs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'limit': limit,
        'next_token': nextToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch logs: ${response.body}');
    }
  }

  // Admin: Manage Staff
  static Future<Map<String, dynamic>> manageStaff(String token, String staffId, String newStatus) async {
    final response = await http.post(
      Uri.parse('$baseUrl/write-service/admin/staff/manage'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'staff_id': staffId,
        'new_status': newStatus,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to manage staff: ${response.body}');
    }
  }
}
