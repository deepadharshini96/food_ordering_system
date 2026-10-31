import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

// ============================================================
// DIRECT CLIENT-SIDE FCM SENDER
//
// Sends a push notification straight from the app, using a bundled
// Firebase service account key — no Cloud Functions or Blaze plan
// needed. This is a simplified setup meant for personal/learning
// projects. In a production app, this key and this logic should
// live on a real server instead, never inside a shipped app.
// ============================================================

class FcmSender {
  FcmSender._internal();
  static final FcmSender instance = FcmSender._internal();

  static const _projectId = 'food-ordering-app-5c822';
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  auth.AutoRefreshingAuthClient? _client;

  Future<auth.AutoRefreshingAuthClient> _getClient() async {
    if (_client != null) return _client!;

    final jsonString =
        await rootBundle.loadString('assets/service_account.json');
    final credentials =
        auth.ServiceAccountCredentials.fromJson(jsonDecode(jsonString));

    _client = await auth.clientViaServiceAccount(credentials, _scopes);
    return _client!;
  }

  // Sends a notification to a specific device token.
  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final client = await _getClient();

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final payload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // ignore: avoid_print
        print('FCM push sent successfully.');
      } else {
        // ignore: avoid_print
        print('FCM push failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('FCM push error: $e');
    }
  }
}