import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Checks the latest version from Play Store / App Store.
class StoreVersionChecker {
  StoreVersionChecker._();

  /// Get the latest version from the appropriate store.
  static Future<String?> getLatestVersion({
    required String packageName,
    String? androidStoreUrl,
    String? iosStoreUrl,
  }) async {
    if (Platform.isAndroid) {
      return _getPlayStoreVersion(packageName, androidStoreUrl);
    } else if (Platform.isIOS) {
      return _getAppStoreVersion(packageName, iosStoreUrl);
    }
    return null;
  }

  /// Get store URL for the current platform.
  ///
  /// On Android, auto-generates a Play Store URL from the package name.
  /// On iOS, auto-generates an App Store URL from the bundle ID.
  /// Custom URLs override the defaults.
  static String? getStoreUrl({
    required String packageName,
    String? androidStoreUrl,
    String? iosStoreUrl,
  }) {
    if (Platform.isAndroid) {
      return androidStoreUrl ??
          'https://play.google.com/store/apps/details?id=$packageName';
    } else if (Platform.isIOS) {
      return iosStoreUrl ??
          'https://apps.apple.com/app/$packageName';
    }
    return null;
  }

  static Future<String?> _getPlayStoreVersion(
    String packageName,
    String? customUrl,
  ) async {
    try {
      final url = customUrl ??
          'https://play.google.com/store/apps/details?id=$packageName&hl=en';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Extract version from Play Store page
        final match = RegExp(r'\[\[\["(\d+\.\d+\.?\d*)"]]').firstMatch(
          response.body,
        );
        return match?.group(1);
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _getAppStoreVersion(
    String packageName,
    String? customUrl,
  ) async {
    try {
      final url =
          'https://itunes.apple.com/lookup?bundleId=$packageName&country=us';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final results = json['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['version'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }
}
