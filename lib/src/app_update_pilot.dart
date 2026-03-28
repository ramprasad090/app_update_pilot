import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'models/update_action.dart';
import 'models/update_config.dart';
import 'models/update_status.dart';
import 'checkers/remote_config_checker.dart';
import 'checkers/store_version_checker.dart';
import 'utils/rollout_utils.dart';
import 'utils/skip_version_manager.dart';
import 'utils/version_utils.dart';
import 'ui/update_prompt_dialog.dart';
import 'ui/force_update_wall.dart';
import 'ui/maintenance_wall.dart';

/// The main entry point for app_update_pilot.
///
/// Provides a simple, high-level API for checking for updates and
/// displaying update prompts, force update walls, and maintenance screens.
class AppUpdatePilot {
  AppUpdatePilot._();

  /// One-line check + auto-show appropriate UI.
  ///
  /// This is the simplest way to integrate app_update_pilot:
  /// ```dart
  /// AppUpdatePilot.check(
  ///   context: context,
  ///   config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
  /// );
  /// ```
  static Future<UpdateStatus> check({
    required BuildContext context,
    required UpdateConfig config,
    bool showChangelog = false,
    bool allowSkip = false,
    Duration skipCooldown = const Duration(days: 7),
    bool allowRemindLater = true,
    Duration remindLaterCooldown = const Duration(hours: 24),
    UpdateActionCallback? onAction,
    Widget Function(BuildContext, UpdateStatus)? forceUpdateBuilder,
    Widget Function(BuildContext, UpdateStatus)? promptBuilder,
    Widget Function(BuildContext, UpdateStatus)? maintenanceBuilder,
  }) async {
    final status = await checkForUpdate(config: config);

    if (!context.mounted) return status;

    if (status.isMaintenanceMode) {
      showMaintenanceWall(
        context,
        status,
        customBuilder: maintenanceBuilder,
      );
      return status;
    }

    if (status.isForceUpdate) {
      showForceUpdateWall(
        context,
        status,
        onAction: onAction,
        customBuilder: forceUpdateBuilder,
      );
      return status;
    }

    if (status.shouldShowPrompt) {
      // Check skip / remind-later state
      if (status.latestVersion != null) {
        final skipped = await SkipVersionManager.isVersionSkipped(
          status.latestVersion!,
          cooldown: skipCooldown,
        );
        if (skipped) return status;
      }

      final remindActive = await SkipVersionManager.isRemindLaterActive(
        cooldown: remindLaterCooldown,
      );
      if (remindActive) return status;

      if (!context.mounted) return status;

      onAction?.call(UpdateAction.shown);

      final result = await showUpdatePrompt(
        context,
        status,
        showChangelog: showChangelog,
        allowSkip: allowSkip,
        allowRemindLater: allowRemindLater,
        onAction: onAction,
        customBuilder: promptBuilder,
      );

      // Handle skip / remind-later persistence
      if (result == UpdateAction.skipped && status.latestVersion != null) {
        await SkipVersionManager.skipVersion(status.latestVersion!);
      } else if (result == UpdateAction.remindLater) {
        await SkipVersionManager.setRemindLater();
      }
    }

    return status;
  }

  /// Check for an update without showing any UI.
  ///
  /// Returns an [UpdateStatus] describing the current state.
  static Future<UpdateStatus> checkForUpdate({
    required UpdateConfig config,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final packageName = packageInfo.packageName;

    // Resolve the config (fetch remote if needed)
    var resolvedConfig = config;

    if (config.remoteConfigUrl != null && !config.isFirebase) {
      final remoteConfig = await RemoteConfigChecker.fetchConfig(
        config.remoteConfigUrl!,
        headers: config.remoteConfigHeaders,
      );
      if (remoteConfig != null) {
        resolvedConfig = remoteConfig;
      }
    }

    if (config.checkStore && resolvedConfig.latestVersion == null) {
      final storeVersion = await StoreVersionChecker.getLatestVersion(
        packageName: packageName,
        androidStoreUrl: config.androidStoreUrl,
        iosStoreUrl: config.iosStoreUrl,
      );
      if (storeVersion != null) {
        resolvedConfig = resolvedConfig.copyWith(latestVersion: storeVersion);
      }
    }

    // Determine maintenance mode
    if (resolvedConfig.maintenanceMode) {
      return UpdateStatus(
        updateAvailable: false,
        isForceUpdate: false,
        isMaintenanceMode: true,
        currentVersion: currentVersion,
        maintenanceMessage: resolvedConfig.maintenanceMessage,
        config: resolvedConfig,
      );
    }

    // Determine if update is available
    final latestVersion = resolvedConfig.latestVersion;
    if (latestVersion == null) {
      return UpdateStatus.upToDate(
        currentVersion: currentVersion,
        config: resolvedConfig,
      );
    }

    final updateAvailable = VersionUtils.isOlderThan(
      currentVersion,
      latestVersion,
    );

    if (!updateAvailable) {
      return UpdateStatus.upToDate(
        currentVersion: currentVersion,
        config: resolvedConfig,
      );
    }

    // Determine if force update
    final platformKey = Platform.isAndroid ? 'android' : 'ios';
    final minVersion =
        resolvedConfig.minVersionByPlatform?[platformKey] ??
        resolvedConfig.minVersion;

    final isForce =
        minVersion != null &&
        VersionUtils.isOlderThan(currentVersion, minVersion);

    // Determine rollout
    final inRollout = isForce
        ? true
        : await RolloutUtils.isInRolloutGroup(
            resolvedConfig.rolloutPercentage,
          );

    // Determine store URL
    final storeUrl = StoreVersionChecker.getStoreUrl(
      packageName: packageName,
      androidStoreUrl: resolvedConfig.androidStoreUrl,
      iosStoreUrl: resolvedConfig.iosStoreUrl,
    );

    return UpdateStatus(
      updateAvailable: true,
      isForceUpdate: isForce || resolvedConfig.urgency == UpdateUrgency.critical,
      isMaintenanceMode: false,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      minVersion: minVersion,
      changelog: resolvedConfig.changelog,
      urgency: resolvedConfig.urgency,
      storeUrl: storeUrl,
      inRolloutGroup: inRollout,
      config: resolvedConfig,
    );
  }

  /// Show the force update wall (blocks the app).
  static void showForceUpdateWall(
    BuildContext context,
    UpdateStatus status, {
    UpdateActionCallback? onAction,
    Widget Function(BuildContext, UpdateStatus)? customBuilder,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForceUpdateWall(
          status: status,
          onAction: onAction,
          customBuilder: customBuilder,
        ),
      ),
      (_) => false,
    );
  }

  /// Show the maintenance wall (blocks the app).
  static void showMaintenanceWall(
    BuildContext context,
    UpdateStatus status, {
    Widget Function(BuildContext, UpdateStatus)? customBuilder,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MaintenanceWall(
          status: status,
          customBuilder: customBuilder,
        ),
      ),
      (_) => false,
    );
  }

  /// Show the update prompt dialog. Returns the user's action.
  static Future<UpdateAction?> showUpdatePrompt(
    BuildContext context,
    UpdateStatus status, {
    bool showChangelog = false,
    bool allowSkip = false,
    bool allowRemindLater = true,
    UpdateActionCallback? onAction,
    Widget Function(BuildContext, UpdateStatus)? customBuilder,
  }) {
    return showDialog<UpdateAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdatePromptDialog(
        status: status,
        showChangelog: showChangelog,
        allowSkip: allowSkip,
        allowRemindLater: allowRemindLater,
        onAction: onAction,
        customBuilder: customBuilder,
      ),
    );
  }

  /// Clear all persisted skip/remind-later state.
  static Future<void> clearPersistedState() {
    return SkipVersionManager.clearAll();
  }
}
