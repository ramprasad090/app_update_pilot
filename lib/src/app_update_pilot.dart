import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/update_action.dart';
import 'models/update_analytics.dart';
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
import 'ui/changelog_sheet.dart';

/// The main entry point for app_update_pilot.
///
/// Provides a simple, high-level API for checking for updates and
/// displaying update prompts, force update walls, and maintenance screens.
class AppUpdatePilot {
  AppUpdatePilot._();

  static UpdateAnalytics? _analytics;

  /// Configure global analytics callbacks.
  ///
  /// Call once at app start:
  /// ```dart
  /// AppUpdatePilot.configure(
  ///   analytics: UpdateAnalytics(
  ///     onPromptShown: (info) => tracker.track('update_shown', info),
  ///     onUpdateAccepted: (info) => tracker.track('update_accepted', info),
  ///   ),
  /// );
  /// ```
  static void configure({
    UpdateAnalytics? analytics,
  }) {
    _analytics = analytics;
  }

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
    Widget Function(BuildContext)? footerBuilder,
    Widget? icon,
    String? title,
    String? description,
    String? updateButtonText,
    String? skipButtonText,
    String? remindButtonText,
  }) async {
    final status = await checkForUpdate(config: config);

    if (!context.mounted) return status;

    if (status.isMaintenanceMode) {
      _analytics?.onMaintenanceShown?.call(status);
      showMaintenanceWall(
        context,
        status,
        customBuilder: maintenanceBuilder,
        footerBuilder: footerBuilder,
        icon: icon,
        title: title,
        message: description,
      );
      return status;
    }

    if (status.isForceUpdate) {
      _analytics?.onForceUpdateShown?.call(status);
      showForceUpdateWall(
        context,
        status,
        onAction: onAction,
        customBuilder: forceUpdateBuilder,
        footerBuilder: footerBuilder,
        icon: icon,
        title: title,
        description: description,
        updateButtonText: updateButtonText,
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
      _analytics?.onPromptShown?.call(status);

      final result = await showUpdatePrompt(
        context,
        status,
        showChangelog: showChangelog,
        allowSkip: allowSkip,
        allowRemindLater: allowRemindLater,
        onAction: onAction,
        customBuilder: promptBuilder,
        footerBuilder: footerBuilder,
        icon: icon,
        title: title,
        description: description,
        updateButtonText: updateButtonText,
        skipButtonText: skipButtonText,
        remindButtonText: remindButtonText,
      );

      // Handle skip / remind-later persistence + analytics
      if (result == UpdateAction.updated) {
        _analytics?.onUpdateAccepted?.call(status);
      } else if (result == UpdateAction.skipped && status.latestVersion != null) {
        _analytics?.onUpdateSkipped?.call(status, status.latestVersion!);
        await SkipVersionManager.skipVersion(status.latestVersion!);
      } else if (result == UpdateAction.remindLater) {
        _analytics?.onRemindLater?.call(status, remindLaterCooldown);
        await SkipVersionManager.setRemindLater();
      } else if (result == UpdateAction.dismissed) {
        _analytics?.onPromptDismissed?.call(status);
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
    Widget Function(BuildContext)? footerBuilder,
    Widget? icon,
    String? title,
    String? description,
    String? updateButtonText,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForceUpdateWall(
          status: status,
          onAction: onAction,
          customBuilder: customBuilder,
          footerBuilder: footerBuilder,
          icon: icon,
          title: title,
          description: description,
          updateButtonText: updateButtonText,
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
    Widget Function(BuildContext)? footerBuilder,
    Widget? icon,
    String? title,
    String? message,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MaintenanceWall(
          status: status,
          customBuilder: customBuilder,
          footerBuilder: footerBuilder,
          icon: icon,
          title: title,
          message: message,
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
    Widget Function(BuildContext)? footerBuilder,
    Widget? icon,
    String? title,
    String? description,
    String? updateButtonText,
    String? skipButtonText,
    String? remindButtonText,
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
        footerBuilder: footerBuilder,
        icon: icon,
        title: title,
        description: description,
        updateButtonText: updateButtonText,
        skipButtonText: skipButtonText,
        remindButtonText: remindButtonText,
      ),
    );
  }

  /// Show a changelog bottom sheet.
  ///
  /// ```dart
  /// AppUpdatePilot.showChangelog(
  ///   context: context,
  ///   changelog: '## What\'s New\n- Bug fixes',
  ///   version: '2.1.0',
  /// );
  /// ```
  static Future<void> showChangelog({
    required BuildContext context,
    required String changelog,
    required String version,
  }) {
    return ChangelogSheet.show(context, changelog: changelog, version: version);
  }

  /// Open the app's store listing.
  static Future<void> openStore(UpdateStatus status) async {
    final url = status.storeUrl;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Skip a specific version. The prompt won't show again for this version
  /// until the [cooldown] expires.
  static Future<void> skipVersion(
    String version, {
    Duration cooldown = const Duration(days: 7),
  }) {
    return SkipVersionManager.skipVersion(version);
  }

  /// Set a remind-later timer. The prompt won't show again until [delay]
  /// has elapsed.
  static Future<void> remindLater([
    Duration delay = const Duration(hours: 24),
  ]) {
    return SkipVersionManager.setRemindLater();
  }

  /// Check whether a version was previously skipped and is still within
  /// the cooldown window.
  static Future<bool> isVersionSkipped(
    String version, {
    Duration cooldown = const Duration(days: 7),
  }) {
    return SkipVersionManager.isVersionSkipped(version, cooldown: cooldown);
  }

  /// Check whether the current device is in the rollout group for the
  /// given [percentage] (0.0–1.0).
  static Future<bool> isInRolloutGroup(double percentage) {
    return RolloutUtils.isInRolloutGroup(percentage);
  }

  /// Clear all persisted skip/remind-later state.
  static Future<void> clearPersistedState() {
    return SkipVersionManager.clearAll();
  }

  /// Access the configured analytics instance (if any).
  static UpdateAnalytics? get analytics => _analytics;
}
