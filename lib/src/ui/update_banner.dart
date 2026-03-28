import 'package:flutter/material.dart';
import '../models/update_status.dart';

/// Position of the banner relative to the child content.
enum BannerPosition {
  /// Banner appears above the child.
  top,

  /// Banner appears below the child.
  bottom,
}

/// A non-intrusive banner widget for subtle update notifications.
///
/// Designed to sit at the top or bottom of a screen, providing a compact
/// prompt for users to update without interrupting their workflow.
///
/// Uses Material 3 color scheme tokens for automatic dark mode support.
class UpdateBanner extends StatelessWidget {
  /// The current update status containing version information.
  final UpdateStatus status;

  /// Called when the user taps the banner or the "Update" chip.
  final VoidCallback? onTap;

  /// Called when the user taps the close/dismiss icon.
  final VoidCallback? onDismiss;

  /// Where to position the banner when using [UpdateBanner.wrap].
  final BannerPosition position;

  const UpdateBanner({
    super.key,
    required this.status,
    this.onTap,
    this.onDismiss,
    this.position = BannerPosition.top,
  });

  /// Conditionally wraps a [child] with an [UpdateBanner] above or below it.
  ///
  /// If [status] is `null` or [status.updateAvailable] is `false`, only the
  /// [child] is returned — no banner is shown.
  ///
  /// ```dart
  /// UpdateBanner.wrap(
  ///   status: updateStatus,
  ///   onTap: () => launchStore(),
  ///   child: MyHomePage(),
  /// )
  /// ```
  static Widget wrap({
    Key? key,
    required Widget child,
    required UpdateStatus? status,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    BannerPosition position = BannerPosition.top,
  }) {
    if (status == null || !status.updateAvailable) {
      return child;
    }

    final banner = UpdateBanner(
      key: key,
      status: status,
      onTap: onTap,
      onDismiss: onDismiss,
      position: position,
    );

    return Column(
      children: position == BannerPosition.top
          ? [banner, Expanded(child: child)]
          : [Expanded(child: child), banner],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderRadius = BorderRadius.circular(16);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.55),
                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Rocket icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),

                // Version text
                Expanded(
                  child: Text(
                    'Update available: v${status.latestVersion ?? "latest"}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // "Update" chip
                ActionChip(
                  label: Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  onPressed: onTap,
                  backgroundColor: colorScheme.primary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),

                // Close / dismiss icon
                if (onDismiss != null) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      onPressed: onDismiss,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 16,
                      tooltip: 'Dismiss',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
