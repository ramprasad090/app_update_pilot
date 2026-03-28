import 'package:flutter/material.dart';
import 'package:app_update_pilot/app_update_pilot.dart';

void main() {
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
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // One-line setup: auto-check and show appropriate UI
    await AppUpdatePilot.check(
      context: context,
      config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
      showChangelog: true,
      allowSkip: true,
      onAction: (action) {
        debugPrint('Update action: $action');
      },
    );
  }

  Future<void> _checkFromStore() async {
    await AppUpdatePilot.check(
      context: context,
      config: UpdateConfig.fromStore(),
      showChangelog: true,
    );
  }

  Future<void> _manualCheck() async {
    final status = await AppUpdatePilot.checkForUpdate(
      config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
    );

    if (!mounted) return;

    if (status.updateAvailable) {
      if (status.isForceUpdate) {
        AppUpdatePilot.showForceUpdateWall(context, status);
      } else {
        AppUpdatePilot.showUpdatePrompt(
          context,
          status,
          showChangelog: true,
          allowSkip: true,
          onAction: (action) => debugPrint('Update action: $action'),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App is up to date!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Update Pilot Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: _checkForUpdates,
              child: const Text('Check via Remote URL'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _checkFromStore,
              child: const Text('Check from Store'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _manualCheck,
              child: const Text('Manual Check (Full Control)'),
            ),
          ],
        ),
      ),
    );
  }
}
