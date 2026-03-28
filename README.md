# app_update_pilot

The complete app update lifecycle manager for Flutter. One package to handle store version checks, force update walls, A/B rollout, rich changelogs, skip with cooldown, analytics hooks, and remote config from any JSON API.

[![pub package](https://img.shields.io/pub/v/app_update_pilot.svg)](https://pub.dev/packages/app_update_pilot)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

| Feature | app_update_pilot |
|---|---|
| Store version check (Play Store / App Store) | ✅ |
| Native in-app update (Android) | ✅ |
| Force update wall | ✅ Full-screen blocking UI |
| Remote config rules | ✅ Any JSON API |
| A/B rollout % | ✅ Show update to X% of users |
| Changelog display | ✅ Rich markdown |
| Skip version / remind later | ✅ With configurable cooldown |
| Custom UI builder | ✅ Full control |
| Min version by platform | ✅ Android/iOS separate |
| Analytics callbacks | ✅ shown/dismissed/updated/skipped |
| Maintenance mode wall | ✅ |
| Staged rollout | ✅ critical → recommended → optional |

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  app_update_pilot: ^0.1.0
```

### 2. One-line setup

```dart
import 'package:app_update_pilot/app_update_pilot.dart';

// In your home screen's initState or similar:
AppUpdatePilot.check(
  context: context,
  config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
);
```

That's it! The package will fetch your remote config, compare versions, and automatically show the right UI (force wall, update prompt, or nothing).

## Configuration Sources

### Remote JSON API

```dart
AppUpdatePilot.check(
  context: context,
  config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
);
```

Expected JSON format:

```json
{
  "latest_version": "2.1.0",
  "min_version": "1.5.0",
  "min_version_android": "1.5.0",
  "min_version_ios": "1.4.0",
  "urgency": "recommended",
  "changelog": "## What's new\n- Bug fixes\n- Performance improvements",
  "rollout_percentage": 0.5,
  "maintenance_mode": false,
  "maintenance_message": null
}
```

### Store Check (Auto-detect Play Store / App Store)

```dart
AppUpdatePilot.check(
  context: context,
  config: UpdateConfig.fromStore(),
);
```

### Firebase Remote Config

```dart
AppUpdatePilot.check(
  context: context,
  config: UpdateConfig.firebase(),
);
```

## Full Control API

For complete control over the update flow:

```dart
final status = await AppUpdatePilot.checkForUpdate(
  config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
);

if (status.updateAvailable) {
  if (status.isForceUpdate) {
    AppUpdatePilot.showForceUpdateWall(context, status);
  } else {
    AppUpdatePilot.showUpdatePrompt(context, status,
      showChangelog: true,
      allowSkip: true,
      onAction: (action) => analytics.track('update_$action'),
    );
  }
}
```

## Advanced Features

### A/B Rollout

Show the update to only a percentage of users:

```json
{
  "latest_version": "2.1.0",
  "rollout_percentage": 0.2
}
```

Only 20% of users will see the update prompt. The selection is stable per device (same user always gets the same result).

### Per-Platform Minimum Version

```json
{
  "latest_version": "2.1.0",
  "min_version_android": "1.5.0",
  "min_version_ios": "1.4.0"
}
```

### Skip Version with Cooldown

```dart
AppUpdatePilot.check(
  context: context,
  config: config,
  allowSkip: true,
  skipCooldown: Duration(days: 3),  // re-prompt after 3 days
);
```

### Analytics Hooks

```dart
AppUpdatePilot.check(
  context: context,
  config: config,
  onAction: (action) {
    // action: shown | dismissed | updated | skipped | remindLater
    analytics.track('update_$action');
  },
);
```

### Custom UI

```dart
AppUpdatePilot.check(
  context: context,
  config: config,
  promptBuilder: (context, status) => MyCustomUpdateDialog(status: status),
  forceUpdateBuilder: (context, status) => MyCustomForceWall(status: status),
  maintenanceBuilder: (context, status) => MyMaintenancePage(status: status),
);
```

### Staged Rollout (Urgency Levels)

Use the `urgency` field to control how strongly the update is presented:

- `"optional"` — dismissible prompt
- `"recommended"` — prominent prompt, still dismissible
- `"critical"` — force update wall, cannot dismiss

```json
{
  "latest_version": "2.1.0",
  "urgency": "critical"
}
```

### Maintenance Mode

```json
{
  "maintenance_mode": true,
  "maintenance_message": "We're upgrading our servers. Back in 30 minutes!"
}
```

## Platform Setup

### Android

No additional setup required. The package uses `in_app_update` for native Android in-app updates when available.

### iOS

No additional setup required. The package checks the App Store via the iTunes Lookup API.

## API Reference

### `AppUpdatePilot.check()`

One-line setup that auto-checks and shows the appropriate UI.

### `AppUpdatePilot.checkForUpdate()`

Check for updates without showing UI. Returns `UpdateStatus`.

### `AppUpdatePilot.showForceUpdateWall()`

Show a full-screen blocking update wall.

### `AppUpdatePilot.showUpdatePrompt()`

Show an update prompt dialog.

### `AppUpdatePilot.showMaintenanceWall()`

Show a maintenance mode wall.

### `AppUpdatePilot.clearPersistedState()`

Clear all skip/remind-later persisted state.

## License

MIT License. See [LICENSE](LICENSE) for details.
