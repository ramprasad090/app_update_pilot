import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Determines if the current device is in the rollout group
/// based on a stable device identifier.
class RolloutUtils {
  static const _deviceIdKey = 'app_update_pilot_device_id';

  RolloutUtils._();

  /// Returns true if the current device falls within the rollout percentage.
  /// Uses a stable random ID stored in shared preferences so the same
  /// device always gets the same result for a given percentage.
  static Future<bool> isInRolloutGroup(double rolloutPercentage) async {
    if (rolloutPercentage >= 1.0) return true;
    if (rolloutPercentage <= 0.0) return false;

    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    final hash = _stableHash(deviceId);
    final bucket = (hash % 100) / 100.0;
    return bucket < rolloutPercentage;
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static int _stableHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }
}
