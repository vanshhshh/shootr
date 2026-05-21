import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class BackendApiService {
  BackendApiService({FirebaseAuth? auth, http.Client? client, String? baseUrl})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ?? const String.fromEnvironment('SHOOTR_BACKEND_URL').trim();

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _baseUrl;

  bool get isEnabled => _baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, Object?> body = const <String, Object?>{},
  }) async {
    if (!isEnabled) {
      throw StateError('SHOOTR_BACKEND_URL is not configured.');
    }

    final user = _auth.currentUser;
    final token = await user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in before calling the backend.');
    }

    final uri = Uri.parse(_join(_baseUrl, path));
    final response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));

    final payload = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['error'] as String? ?? 'Backend request failed.');
    }
    return payload;
  }

  Future<void> notifyBookingCreated(String bookingId) async {
    if (!isEnabled) {
      return;
    }
    await postJson(
      '/api/booking-created',
      body: <String, Object?>{'bookingId': bookingId},
    );
  }

  Future<void> notifyBookingAssigned(String bookingId) async {
    if (!isEnabled) {
      return;
    }
    await postJson(
      '/api/booking-assigned',
      body: <String, Object?>{'bookingId': bookingId},
    );
  }

  void dispose() {
    _client.close();
  }

  String _join(String baseUrl, String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }
}
