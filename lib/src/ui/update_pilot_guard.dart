import 'package:flutter/material.dart';

import '../app_update_pilot.dart';
import '../models/update_config.dart';
import '../models/update_status.dart';

/// A wrapper widget that automatically checks for updates on initialization
/// and shows the appropriate UI based on the result.
///
/// Wrap your app's home screen (or any subtree) with [UpdatePilotGuard] to
/// gate access behind update and maintenance checks:
///
/// ```dart
/// UpdatePilotGuard(
///   config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
///   forceUpdateBuilder: (context, status) => MyForceUpdateScreen(status),
///   child: HomeScreen(),
/// )
/// ```
///
/// While the check is in progress the [child] is shown. Once the check
/// completes, the guard decides what to render:
///
/// 1. **Maintenance mode** and [maintenanceBuilder] provided -> maintenance UI.
/// 2. **Force update** and [forceUpdateBuilder] provided -> force update UI.
/// 3. **Optional update** and [optionalUpdateBuilder] provided -> optional update UI.
/// 4. Otherwise the [child] is shown (and if a [BuildContext] is available,
///    [AppUpdatePilot.check] is called to show the default built-in UI).
class UpdatePilotGuard extends StatefulWidget {
  /// The widget to display when no blocking update UI is needed.
  final Widget child;

  /// Configuration describing how the update check is performed.
  final UpdateConfig config;

  /// Custom builder shown when a force update is required.
  ///
  /// If `null` and a force update is detected, the built-in
  /// [AppUpdatePilot.check] default UI is used instead.
  final Widget Function(BuildContext, UpdateStatus)? forceUpdateBuilder;

  /// Custom builder shown when an optional update is available.
  ///
  /// If `null` and an optional update is detected, the built-in
  /// [AppUpdatePilot.check] default UI is used instead.
  final Widget Function(BuildContext, UpdateStatus)? optionalUpdateBuilder;

  /// Custom builder shown when the app is in maintenance mode.
  ///
  /// If `null` and maintenance mode is active, the built-in
  /// [AppUpdatePilot.check] default UI is used instead.
  final Widget Function(BuildContext, UpdateStatus)? maintenanceBuilder;

  /// Called after the update check completes, regardless of the outcome.
  final void Function(UpdateStatus)? onStatus;

  /// Whether to display changelog information in the default prompt UI.
  final bool showChangelog;

  /// Whether to allow the user to skip an optional update in the default
  /// prompt UI.
  final bool allowSkip;

  /// Set to `false` to disable the automatic update check entirely.
  /// When disabled the [child] is always shown immediately.
  final bool enabled;

  const UpdatePilotGuard({
    super.key,
    required this.child,
    required this.config,
    this.forceUpdateBuilder,
    this.optionalUpdateBuilder,
    this.maintenanceBuilder,
    this.onStatus,
    this.showChangelog = false,
    this.allowSkip = false,
    this.enabled = true,
  });

  @override
  State<UpdatePilotGuard> createState() => _UpdatePilotGuardState();
}

class _UpdatePilotGuardState extends State<UpdatePilotGuard> {
  UpdateStatus? _status;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      // Defer until the first frame so the widget is fully settled in the
      // navigator before we show any dialogs or push any routes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _performCheck();
      });
    }
  }

  Future<void> _performCheck() async {
    if (_checking) return;
    _checking = true;

    try {
      final status = await AppUpdatePilot.checkForUpdate(
        config: widget.config,
      );

      widget.onStatus?.call(status);

      if (!mounted) return;

      final hasCustomBuilder = _hasCustomBuilderFor(status);

      if (hasCustomBuilder) {
        // A custom builder is available — let build() render it.
        setState(() {
          _status = status;
        });
      } else if (status.isMaintenanceMode ||
          status.isForceUpdate ||
          status.shouldShowPrompt) {
        // No custom builder but an action is needed — delegate to the
        // default built-in UI provided by AppUpdatePilot.check().
        if (!mounted) return;
        AppUpdatePilot.check(
          context: context,
          config: widget.config,
          showChangelog: widget.showChangelog,
          allowSkip: widget.allowSkip,
        );
        // The child remains visible underneath the dialog / wall.
        setState(() {
          _status = status;
        });
      } else {
        // Up to date — just record the status so we stop "loading".
        setState(() {
          _status = status;
        });
      }
    } catch (_) {
      // On failure, silently fall through to show the child.
      if (mounted) {
        setState(() {
          _status = null;
        });
      }
    } finally {
      _checking = false;
    }
  }

  /// Returns `true` when a custom builder matching the given [status] has
  /// been provided by the caller.
  bool _hasCustomBuilderFor(UpdateStatus status) {
    if (status.isMaintenanceMode && widget.maintenanceBuilder != null) {
      return true;
    }
    if (status.isForceUpdate && widget.forceUpdateBuilder != null) {
      return true;
    }
    if (status.shouldShowPrompt && widget.optionalUpdateBuilder != null) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // While still loading or when checking is disabled, show the child.
    if (!widget.enabled || _status == null) {
      return widget.child;
    }

    final status = _status!;

    // Maintenance mode takes highest priority.
    if (status.isMaintenanceMode && widget.maintenanceBuilder != null) {
      return widget.maintenanceBuilder!(context, status);
    }

    // Force update is next.
    if (status.isForceUpdate && widget.forceUpdateBuilder != null) {
      return widget.forceUpdateBuilder!(context, status);
    }

    // Optional / recommended update.
    if (status.shouldShowPrompt && widget.optionalUpdateBuilder != null) {
      return widget.optionalUpdateBuilder!(context, status);
    }

    // No blocking condition or no custom builder — show the child.
    return widget.child;
  }
}
