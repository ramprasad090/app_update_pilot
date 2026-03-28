import 'package:flutter/material.dart';
import '../models/update_status.dart';

/// A full-screen wall shown when the app is in maintenance mode.
///
/// Developers can customize this in three ways:
/// 1. **Replace entirely** — pass [customBuilder] to build your own widget.
/// 2. **Tweak pieces** — override [icon], [title], [message].
/// 3. **Add extra content** — pass [footerBuilder] to inject a widget
///    below the status indicator (e.g. contact support link, ETA info).
class MaintenanceWall extends StatelessWidget {
  /// The update status containing maintenance info.
  final UpdateStatus status;

  /// Replace the entire wall with a custom widget.
  final Widget Function(BuildContext, UpdateStatus)? customBuilder;

  /// Inject a widget below the status indicator.
  final Widget Function(BuildContext)? footerBuilder;

  /// Override the header icon. Defaults to a build icon.
  final Widget? icon;

  /// Override the title text. Defaults to "Under Maintenance".
  final String? title;

  /// Override the maintenance message.
  final String? message;

  const MaintenanceWall({
    super.key,
    required this.status,
    this.customBuilder,
    this.footerBuilder,
    this.icon,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, status);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                colorScheme.surface,
                colorScheme.surface,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Icon with subtle glow
                  icon ??
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.tertiary.withValues(alpha: 0.12),
                              blurRadius: 32,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.build_circle_rounded,
                          size: 44,
                          color: colorScheme.tertiary,
                        ),
                      ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    title ?? 'Under Maintenance',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 24,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message ??
                              status.maintenanceMessage ??
                              'We are currently performing scheduled maintenance to improve your experience. Please check back shortly.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Working on it...',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  if (footerBuilder != null) ...[
                    const SizedBox(height: 24),
                    footerBuilder!(context),
                  ],

                  const Spacer(flex: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
