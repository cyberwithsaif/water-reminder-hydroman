import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yourdomain.com/api',
  );
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ─── Auth (Phone + OTP) ───

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: _headers,
      body: jsonEncode({'phone': phone}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ─── Profile ───

  Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  // ─── Water Logs ───

  Future<List<dynamic>> getWaterLogs({String? since}) async {
    final uri = since != null
        ? Uri.parse('$baseUrl/water-logs?since=$since')
        : Uri.parse('$baseUrl/water-logs');
    final res = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    if (body is List) return body;
    return (body as Map<String, dynamic>)['list'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> syncWaterLogs(
    List<Map<String, dynamic>> logs,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/water-logs/sync'),
      headers: _headers,
      body: jsonEncode({'logs': logs}),
    );
    return _handleResponse(res);
  }

  Future<void> deleteWaterLog(String id) async {
    await http.delete(Uri.parse('$baseUrl/water-logs/$id'), headers: _headers);
  }

  // ─── Reminders ───

  Future<List<dynamic>> getReminders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/reminders'),
      headers: _headers,
    );
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> syncReminders(
    List<Map<String, dynamic>> reminders,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reminders/sync'),
      headers: _headers,
      body: jsonEncode({'reminders': reminders}),
    );
    return _handleResponse(res);
  }

  Future<void> deleteReminder(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/reminders/$id'), headers: _headers);
    } catch (_) {
      // Speculative call, ignore errors
    }
  }

  // ─── Health ───

  Future<bool> healthCheck() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Internal ───

  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'list': body};
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: body['error'] ?? 'Unknown error',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
