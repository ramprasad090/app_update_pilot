import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// A premium bottom sheet for displaying version changelogs.
///
/// Usage:
/// ```dart
/// ChangelogSheet.show(context, changelog: '- Bug fixes\n- New feature', version: '2.1.0');
/// ```
class ChangelogSheet extends StatelessWidget {
  /// The markdown changelog text to render.
  final String changelog;

  /// The version string to display in the header badge.
  final String version;

  const ChangelogSheet({
    super.key,
    required this.changelog,
    required this.version,
  });

  /// Show the changelog bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String changelog,
    required String version,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangelogSheet(
        changelog: changelog,
        version: version,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.5),
                      colorScheme.primaryContainer.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "What's New",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                              'v$version',
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
                  ],
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),

              // Markdown body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                  children: [
                    MarkdownBody(
                      data: changelog,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        h1: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        h2: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        h3: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        listBullet: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        code: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          backgroundColor:
                              colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
