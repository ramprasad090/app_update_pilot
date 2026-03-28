import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/update_config.dart';

/// Fetches update configuration from a remote JSON endpoint.
class RemoteConfigChecker {
  RemoteConfigChecker._();

  /// Fetch and parse a remote config from the given URL.
  static Future<UpdateConfig?> fetchConfig(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UpdateConfig.fromJson(json);
      }
    } catch (_) {}
    return null;
  }
}
