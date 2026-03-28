import 'update_config.dart';

/// The result of an update check, describing what action (if any) is needed.
class UpdateStatus {
  /// Whether an update is available.
  final bool updateAvailable;

  /// Whether this is a force update (user must update).
  final bool isForceUpdate;

  /// Whether the app is in maintenance mode.
  final bool isMaintenanceMode;

  /// The current app version.
  final String currentVersion;

  /// The latest available version.
  final String? latestVersion;

  /// The minimum required version.
  final String? minVersion;

  /// Changelog text (markdown supported).
  final String? changelog;

  /// The urgency level.
  final UpdateUrgency urgency;

  /// The store URL to open for updating.
  final String? storeUrl;

  /// Maintenance message if in maintenance mode.
  final String? maintenanceMessage;

  /// Whether this user is in the rollout group (A/B rollout).
  final bool inRolloutGroup;

  /// Raw config that produced this status.
  final UpdateConfig config;

  /// Creates an [UpdateStatus] with the given parameters.
  const UpdateStatus({
    required this.updateAvailable,
    required this.isForceUpdate,
    required this.isMaintenanceMode,
    required this.currentVersion,
    required this.config,
    this.latestVersion,
    this.minVersion,
    this.changelog,
    this.urgency = UpdateUrgency.optional,
    this.storeUrl,
    this.maintenanceMessage,
    this.inRolloutGroup = true,
  });

  /// No update needed.
  factory UpdateStatus.upToDate({
    required String currentVersion,
    required UpdateConfig config,
  }) {
    return UpdateStatus(
      updateAvailable: false,
      isForceUpdate: false,
      isMaintenanceMode: false,
      currentVersion: currentVersion,
      config: config,
    );
  }

  /// Whether the update prompt should be shown (considers rollout).
  bool get shouldShowPrompt => updateAvailable && inRolloutGroup;
}
