import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_action.dart';
import '../models/update_status.dart';

/// A full-screen wall that blocks app usage until the user updates.
///
/// Developers can customize this in three ways:
/// 1. **Replace entirely** — pass [customBuilder] to build your own widget.
/// 2. **Tweak pieces** — override [icon], [title], [description],
///    [updateButtonText].
/// 3. **Add extra content** — pass [footerBuilder] to inject a widget
///    below the update button.
class ForceUpdateWall extends StatelessWidget {
  /// The update status to display.
  final UpdateStatus status;

  /// Callback fired when the user takes an action.
  final UpdateActionCallback? onAction;

  /// Replace the entire wall with a custom widget.
  final Widget Function(BuildContext, UpdateStatus)? customBuilder;

  /// Inject a widget below the update button.
  final Widget Function(BuildContext)? footerBuilder;

  /// Override the header icon. Defaults to a shield icon.
  final Widget? icon;

  /// Override the title text. Defaults to "Update Required".
  final String? title;

  /// Override the description text.
  final String? description;

  /// Override the primary button label. Defaults to "Update Now".
  final String? updateButtonText;

  const ForceUpdateWall({
    super.key,
    required this.status,
    this.onAction,
    this.customBuilder,
    this.footerBuilder,
    this.icon,
    this.title,
    this.description,
    this.updateButtonText,
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
                colorScheme.errorContainer.withValues(alpha: 0.3),
                colorScheme.surface,
                colorScheme.surface,
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Shield icon with glow
                  icon ??
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.error.withValues(alpha: 0.15),
                              blurRadius: 32,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          size: 44,
                          color: colorScheme.error,
                        ),
                      ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    title ?? 'Update Required',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    description ??
                        'Version ${status.latestVersion ?? "latest"} is required to continue using this app. Please update for the best experience.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  // Version badge
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${status.currentVersion}  →  ${status.latestVersion ?? "latest"}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Changelog
                  if (status.changelog != null) ...[
                    const SizedBox(height: 28),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "What's New",
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Markdown(
                                data: status.changelog!,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                styleSheet: MarkdownStyleSheet(
                                  p: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                  listBullet:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(flex: 3),

                  const SizedBox(height: 32),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () async {
                        await _openStore();
                        onAction?.call(UpdateAction.updated);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      child: Text(updateButtonText ?? 'Update Now'),
                    ),
                  ),

                  if (footerBuilder != null) ...[
                    const SizedBox(height: 20),
                    footerBuilder!(context),
                  ],

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final url = status.storeUrl;
    if (url == null) return;

    // Derive package ID from whatever scheme is stored (market:// or https://).
    final parsed = Uri.parse(url);
    final packageId = parsed.queryParameters['id'];

    // Try market:// → https:// fallback (handles both Play Store app and browser).
    final uris = [
      if (packageId != null) Uri.parse('market://details?id=$packageId'),
      Uri.parse(
        packageId != null
            ? 'https://play.google.com/store/apps/details?id=$packageId'
            : url,
      ),
    ];

    for (final uri in uris) {
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      if (launched) return;
    }
  }
}
