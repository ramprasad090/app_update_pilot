import 'package:flutter/material.dart';
import 'package:app_update_pilot/app_update_pilot.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure global analytics
  AppUpdatePilot.configure(
    analytics: UpdateAnalytics(
      onPromptShown: (info) => debugPrint('[Analytics] Prompt shown: ${info.latestVersion}'),
      onUpdateAccepted: (info) => debugPrint('[Analytics] Update accepted'),
      onUpdateSkipped: (info, version) => debugPrint('[Analytics] Skipped $version'),
      onRemindLater: (info, delay) => debugPrint('[Analytics] Remind later: $delay'),
      onForceUpdateShown: (info) => debugPrint('[Analytics] Force update shown'),
      onMaintenanceShown: (info) => debugPrint('[Analytics] Maintenance shown'),
      onCheckFailed: (error) => debugPrint('[Analytics] Check failed: $error'),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Update Pilot Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UpdateStatus? _bannerStatus;

  static const _demoChangelog =
      '## What\'s New in 2.0.0\n\n'
      '- Redesigned home screen with Material 3\n'
      '- Dark mode support\n'
      '- Performance improvements up to 40%\n'
      '- Bug fixes and stability updates\n'
      '- New onboarding experience';

  /// Demo: Optional update prompt with changelog
  Future<void> _showOptionalUpdate() async {
    await AppUpdatePilot.check(
      context: context,
      config: const UpdateConfig(
        latestVersion: '2.0.0',
        urgency: UpdateUrgency.recommended,
        changelog: _demoChangelog,
      ),
      showChangelog: true,
      allowSkip: true,
      onAction: (action) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User action: ${action.name}')),
          );
        }
      },
    );
  }

  /// Demo: Customized prompt with custom icon, title, footer
  Future<void> _showCustomizedPrompt() async {
    await AppUpdatePilot.check(
      context: context,
      config: const UpdateConfig(
        latestVersion: '3.0.0',
        urgency: UpdateUrgency.recommended,
        changelog: _demoChangelog,
      ),
      showChangelog: true,
      allowSkip: true,
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
      title: 'Exciting New Update!',
      description: 'We\'ve been working hard on this one.',
      updateButtonText: 'Get It Now',
      skipButtonText: 'Not Now',
      remindButtonText: 'Maybe Later',
      footerBuilder: (context) => Text(
        'Update size: ~15 MB',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Demo: Force update wall
  Future<void> _showForceUpdate() async {
    await AppUpdatePilot.check(
      context: context,
      config: const UpdateConfig(
        latestVersion: '3.0.0',
        minVersion: '2.5.0',
        urgency: UpdateUrgency.critical,
        changelog:
            '## Critical Security Update\n\n'
            '- Fixed critical security vulnerability\n'
            '- Updated encryption protocols\n'
            '- You must update to continue using the app',
      ),
      showChangelog: true,
    );
  }

  /// Demo: Maintenance wall
  Future<void> _showMaintenance() async {
    await AppUpdatePilot.check(
      context: context,
      config: const UpdateConfig(
        maintenanceMode: true,
        maintenanceMessage:
            'We are performing scheduled maintenance.\n'
            'The app will be back online shortly.\n\n'
            'Expected downtime: ~30 minutes.',
      ),
    );
  }

  /// Demo: Maintenance wall with custom footer
  Future<void> _showMaintenanceWithFooter() async {
    await AppUpdatePilot.check(
      context: context,
      config: const UpdateConfig(
        maintenanceMode: true,
        maintenanceMessage: 'Upgrading our servers for better performance.',
      ),
      footerBuilder: (context) => OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening support...')),
          );
        },
        icon: const Icon(Icons.support_agent, size: 18),
        label: const Text('Contact Support'),
      ),
    );
  }

  /// Demo: Changelog bottom sheet
  void _showChangelogSheet() {
    AppUpdatePilot.showChangelog(
      context: context,
      changelog: _demoChangelog,
      version: '2.0.0',
    );
  }

  /// Demo: Update banner
  void _toggleBanner() {
    setState(() {
      if (_bannerStatus != null) {
        _bannerStatus = null;
      } else {
        _bannerStatus = const UpdateStatus(
          updateAvailable: true,
          isForceUpdate: false,
          isMaintenanceMode: false,
          currentVersion: '1.0.0',
          latestVersion: '2.0.0',
          config: UpdateConfig(latestVersion: '2.0.0'),
        );
      }
    });
  }

  /// Demo: Manual check with full control
  Future<void> _manualCheck() async {
    final status = await AppUpdatePilot.checkForUpdate(
      config: const UpdateConfig(
        latestVersion: '1.5.0',
        urgency: UpdateUrgency.optional,
        changelog: '## Version 1.5.0\n\n- Minor improvements\n- Bug fixes',
      ),
    );

    if (!mounted) return;

    if (status.updateAvailable) {
      if (status.isForceUpdate) {
        AppUpdatePilot.showForceUpdateWall(context, status);
      } else {
        final action = await AppUpdatePilot.showUpdatePrompt(
          context,
          status,
          showChangelog: true,
          allowSkip: true,
        );
        if (mounted && action != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User chose: ${action.name}')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App is up to date!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Scaffold(
      appBar: AppBar(title: const Text('App Update Pilot Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Update Prompts
                const _SectionHeader(title: 'Update Prompts', icon: Icons.system_update),
                const SizedBox(height: 12),
                _DemoButton(
                  onPressed: _showOptionalUpdate,
                  icon: Icons.rocket_launch_rounded,
                  label: 'Optional Update',
                  subtitle: 'With changelog, skip & remind',
                ),
                _DemoButton(
                  onPressed: _showCustomizedPrompt,
                  icon: Icons.palette_rounded,
                  label: 'Customized Prompt',
                  subtitle: 'Custom icon, title, footer, buttons',
                ),
                _DemoButton(
                  onPressed: _showForceUpdate,
                  icon: Icons.shield_rounded,
                  label: 'Force Update Wall',
                  subtitle: 'Non-dismissible, blocks the app',
                  isDestructive: true,
                ),

                const SizedBox(height: 28),

                // Walls & Sheets
                const _SectionHeader(title: 'Walls & Sheets', icon: Icons.layers_rounded),
                const SizedBox(height: 12),
                _DemoButton(
                  onPressed: _showMaintenance,
                  icon: Icons.build_circle_rounded,
                  label: 'Maintenance Wall',
                  subtitle: 'Full-screen maintenance screen',
                ),
                _DemoButton(
                  onPressed: _showMaintenanceWithFooter,
                  icon: Icons.support_agent,
                  label: 'Maintenance + Footer',
                  subtitle: 'With custom support button',
                ),
                _DemoButton(
                  onPressed: _showChangelogSheet,
                  icon: Icons.auto_awesome_rounded,
                  label: 'Changelog Sheet',
                  subtitle: 'Draggable bottom sheet with markdown',
                ),
                _DemoButton(
                  onPressed: _toggleBanner,
                  icon: Icons.flag_rounded,
                  label: _bannerStatus != null ? 'Hide Banner' : 'Show Banner',
                  subtitle: 'Non-intrusive update notification',
                ),

                const SizedBox(height: 28),

                // Advanced
                const _SectionHeader(title: 'Advanced', icon: Icons.tune_rounded),
                const SizedBox(height: 12),
                _DemoButton(
                  onPressed: _manualCheck,
                  icon: Icons.code_rounded,
                  label: 'Manual Check',
                  subtitle: 'checkForUpdate() + conditional UI',
                ),
                _DemoButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await AppUpdatePilot.clearPersistedState();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Skip/remind state cleared')),
                    );
                  },
                  icon: Icons.refresh_rounded,
                  label: 'Clear Persisted State',
                  subtitle: 'Reset all skip & remind timers',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with banner if active
    if (_bannerStatus != null) {
      body = Column(
        children: [
          UpdateBanner(
            status: _bannerStatus!,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening store...')),
            ),
            onDismiss: () => setState(() => _bannerStatus = null),
          ),
          Expanded(child: body),
        ],
      );
    }

    return body;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _DemoButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDestructive;

  const _DemoButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
