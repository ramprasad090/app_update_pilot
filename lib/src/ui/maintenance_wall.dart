import 'package:flutter/material.dart';
import '../models/update_status.dart';

/// A full-screen wall shown when the app is in maintenance mode.
class MaintenanceWall extends StatelessWidget {
  final UpdateStatus status;
  final Widget Function(BuildContext, UpdateStatus)? customBuilder;

  const MaintenanceWall({
    super.key,
    required this.status,
    this.customBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, status);
    }

    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Under Maintenance',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  status.maintenanceMessage ??
                      'We are currently performing maintenance. '
                          'Please try again later.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
