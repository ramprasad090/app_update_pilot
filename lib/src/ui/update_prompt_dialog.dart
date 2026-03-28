import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_action.dart';
import '../models/update_status.dart';

/// A customizable update prompt dialog.
class UpdatePromptDialog extends StatelessWidget {
  final UpdateStatus status;
  final bool showChangelog;
  final bool allowSkip;
  final bool allowRemindLater;
  final UpdateActionCallback? onAction;
  final Widget Function(BuildContext, UpdateStatus)? customBuilder;

  const UpdatePromptDialog({
    super.key,
    required this.status,
    this.showChangelog = false,
    this.allowSkip = false,
    this.allowRemindLater = true,
    this.onAction,
    this.customBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, status);
    }

    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Update Available'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${status.latestVersion ?? "new"} is available.',
              style: theme.textTheme.bodyLarge,
            ),
            if (status.currentVersion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'You are on version ${status.currentVersion}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (showChangelog && status.changelog != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                "What's New",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Markdown(
                  data: status.changelog!,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (allowSkip)
          TextButton(
            onPressed: () {
              onAction?.call(UpdateAction.skipped);
              Navigator.of(context).pop(UpdateAction.skipped);
            },
            child: const Text('Skip Version'),
          ),
        if (allowRemindLater)
          TextButton(
            onPressed: () {
              onAction?.call(UpdateAction.remindLater);
              Navigator.of(context).pop(UpdateAction.remindLater);
            },
            child: const Text('Later'),
          ),
        FilledButton(
          onPressed: () {
            onAction?.call(UpdateAction.updated);
            Navigator.of(context).pop(UpdateAction.updated);
            _openStore();
          },
          child: const Text('Update Now'),
        ),
      ],
    );
  }

  Future<void> _openStore() async {
    final url = status.storeUrl;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
