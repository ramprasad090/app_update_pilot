import 'package:shared_preferences/shared_preferences.dart';

/// Manages "skip this version" with a configurable cooldown period.
class SkipVersionManager {
  static const _skippedVersionKey = 'app_update_pilot_skipped_version';
  static const _skippedAtKey = 'app_update_pilot_skipped_at';
  static const _remindLaterKey = 'app_update_pilot_remind_later_at';

  SkipVersionManager._();

  /// Check if the given version was skipped and the cooldown hasn't expired.
  static Future<bool> isVersionSkipped(
    String version, {
    Duration cooldown = const Duration(days: 7),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString(_skippedVersionKey);
    if (skippedVersion != version) return false;

    final skippedAt = prefs.getInt(_skippedAtKey) ?? 0;
    final skippedTime = DateTime.fromMillisecondsSinceEpoch(skippedAt);
    final now = DateTime.now();

    return now.difference(skippedTime) < cooldown;
  }

  /// Mark a version as skipped.
  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedVersionKey, version);
    await prefs.setInt(
      _skippedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if "remind me later" is still active.
  static Future<bool> isRemindLaterActive({
    Duration cooldown = const Duration(hours: 24),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final remindAt = prefs.getInt(_remindLaterKey) ?? 0;
    if (remindAt == 0) return false;

    final remindTime = DateTime.fromMillisecondsSinceEpoch(remindAt);
    final now = DateTime.now();
    return now.difference(remindTime) < cooldown;
  }

  /// Mark "remind me later".
  static Future<void> setRemindLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _remindLaterKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Clear all skip/remind state.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skippedVersionKey);
    await prefs.remove(_skippedAtKey);
    await prefs.remove(_remindLaterKey);
  }
}
