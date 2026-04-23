import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_action.dart';
import '../models/update_status.dart';

/// A customizable update prompt dialog.
///
/// Developers can customize this in three ways:
/// 1. **Replace entirely** — pass [customBuilder] to build your own widget.
/// 2. **Tweak pieces** — override [icon], [title], [description],
///    [updateButtonText], [skipButtonText], [remindButtonText].
/// 3. **Add extra content** — pass [footerBuilder] to inject a widget
///    below the action buttons (e.g. "What happens after the update").
class UpdatePromptDialog extends StatelessWidget {
  /// The update status to display.
  final UpdateStatus status;

  /// Whether to display the changelog section.
  final bool showChangelog;

  /// Whether to show the "Skip Version" button.
  final bool allowSkip;

  /// Whether to show the "Remind Me Later" button.
  final bool allowRemindLater;

  /// Callback fired when the user takes an action.
  final UpdateActionCallback? onAction;

  /// Replace the entire dialog with a custom widget.
  final Widget Function(BuildContext, UpdateStatus)? customBuilder;

  /// Inject a widget below the action buttons.
  final Widget Function(BuildContext)? footerBuilder;

  /// Override the header icon. Defaults to a rocket icon.
  final Widget? icon;

  /// Override the title text. Defaults to "New Version Available".
  final String? title;

  /// Override the description text below the title.
  final String? description;

  /// Override the primary button label. Defaults to "Update Now".
  final String? updateButtonText;

  /// Override the skip button label. Defaults to "Skip Version".
  final String? skipButtonText;

  /// Override the remind-later button label. Defaults to "Remind Me Later".
  final String? remindButtonText;

  const UpdatePromptDialog({
    super.key,
    required this.status,
    this.showChangelog = false,
    this.allowSkip = false,
    this.allowRemindLater = true,
    this.onAction,
    this.customBuilder,
    this.footerBuilder,
    this.icon,
    this.title,
    this.description,
    this.updateButtonText,
    this.skipButtonText,
    this.remindButtonText,
  });

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, status);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient accent
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                    colorScheme.primaryContainer.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  icon ??
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          size: 28,
                          color: colorScheme.primary,
                        ),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    title ?? 'New Version Available',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${status.currentVersion}  →  ${status.latestVersion ?? "latest"}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Changelog section
            if (showChangelog && status.changelog != null) ...[
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "What's New",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: MarkdownBody(
                            data: status.changelog!,
                            styleSheet: MarkdownStyleSheet(
                              p: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                              listBullet: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Text(
                  description ??
                      'A better experience awaits. Update now to enjoy the latest features and improvements.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () async {
                        await _openStore();
                        onAction?.call(UpdateAction.updated);
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true)
                              .pop(UpdateAction.updated);
                        }
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: Text(updateButtonText ?? 'Update Now'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (allowSkip)
                        TextButton(
                          onPressed: () {
                            onAction?.call(UpdateAction.skipped);
                            Navigator.of(context).pop(UpdateAction.skipped);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: Text(skipButtonText ?? 'Skip Version'),
                        ),
                      if (allowRemindLater)
                        TextButton(
                          onPressed: () {
                            onAction?.call(UpdateAction.remindLater);
                            Navigator.of(context).pop(UpdateAction.remindLater);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: Text(remindButtonText ?? 'Remind Me Later'),
                        ),
                    ],
                  ),
                  if (footerBuilder != null) ...[
                    const SizedBox(height: 12),
                    footerBuilder!(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final url = status.storeUrl;
    if (url == null) return;
    // market:// opens Play Store app directly. Fall back to https:// if the
    // Play Store app is not present (e.g. emulator, alternative stores).
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (url.startsWith('market://')) {
        final packageId = uri.queryParameters['id'];
        if (packageId != null) {
          try {
            await launchUrl(
              Uri.parse(
                'https://play.google.com/store/apps/details?id=$packageId',
              ),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
        }
      }
    }
  }
}
