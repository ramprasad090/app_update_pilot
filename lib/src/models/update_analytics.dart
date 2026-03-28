import 'update_status.dart';

/// Callbacks for tracking update-related analytics events.
class UpdateAnalytics {
  /// Called when an update prompt is shown to the user.
  final void Function(UpdateStatus info)? onPromptShown;

  /// Called when an update prompt is dismissed by the user.
  final void Function(UpdateStatus info)? onPromptDismissed;

  /// Called when the user accepts an update.
  final void Function(UpdateStatus info)? onUpdateAccepted;

  /// Called when the user skips a specific version.
  final void Function(UpdateStatus info, String version)? onUpdateSkipped;

  /// Called when the user chooses to be reminded later.
  final void Function(UpdateStatus info, Duration delay)? onRemindLater;

  /// Called when a force update screen is shown.
  final void Function(UpdateStatus info)? onForceUpdateShown;

  /// Called when a maintenance screen is shown.
  final void Function(UpdateStatus info)? onMaintenanceShown;

  /// Called when an update check fails.
  final void Function(Object error)? onCheckFailed;

  /// Creates an [UpdateAnalytics] instance with optional callback handlers.
  const UpdateAnalytics({
    this.onPromptShown,
    this.onPromptDismissed,
    this.onUpdateAccepted,
    this.onUpdateSkipped,
    this.onRemindLater,
    this.onForceUpdateShown,
    this.onMaintenanceShown,
    this.onCheckFailed,
  });
}
