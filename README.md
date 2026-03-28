# app_update_pilot

The complete app update lifecycle manager for Flutter. One package to handle store version checks, force update walls, A/B rollout, rich changelogs, skip with cooldown, analytics hooks, maintenance mode, and remote config from any JSON API.

[![pub package](https://img.shields.io/pub/v/app_update_pilot.svg)](https://pub.dev/packages/app_update_pilot)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Why app_update_pilot?

| Feature | app_update_pilot | upgrader | in_app_update |
|---|:---:|:---:|:---:|
| Store version check (Play Store / App Store) | ✅ | ✅ | ❌ |
| Native Android in-app update | ✅ | ❌ | ✅ |
| Force update wall | ✅ | ❌ | ❌ |
| Remote config (any JSON API) | ✅ | ❌ | ❌ |
| A/B rollout percentage | ✅ | ❌ | ❌ |
| Rich markdown changelog | ✅ | ❌ | ❌ |
| Skip version / remind later | ✅ | ❌ | ❌ |
| Per-platform min version | ✅ | ❌ | ❌ |
| Maintenance mode | ✅ | ❌ | ❌ |
| Structured analytics callbacks | ✅ | ❌ | ❌ |
| Changelog bottom sheet | ✅ | ❌ | ❌ |
| Non-intrusive update banner | ✅ | ❌ | ❌ |
| Auto-check guard widget | ✅ | ❌ | ❌ |
| Full UI customization | ✅ | Partial | ❌ |
| Dark mode support | ✅ | ✅ | N/A |

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  app_update_pilot: ^0.1.0
```

### 2. One-line setup

```dart
import 'package:app_update_pilot/app_update_pilot.dart';

@override
void initState() {
  super.initState();
  AppUpdatePilot.check(
    context: context,
    config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
  );
}
```

That's it! The package fetches your remote config, compares versions, and automatically shows the right UI — force wall, update prompt, or nothing.

## Configuration Sources

### Remote JSON API

```dart
AppUpdatePilot.check(
  context: context,
  config: UpdateConfig.fromUrl(
    'https://api.myapp.com/version',
    headers: {'Authorization': 'Bearer $token'},
  ),
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

All fields are optional. The package uses sensible defaults for any omitted field.

### Store Check (Auto-detect)

```dart
AppUpdatePilot.check(
  context: context,
  config: UpdateConfig.fromStore(),
);
```

- **Android:** Queries Play Store for latest version
- **iOS:** Uses iTunes Lookup API by bundle ID

### Firebase Remote Config

```dart
AppUpdatePilot.check(
  context: context,
  config: UpdateConfig.firebase(),
);
```

### Direct Configuration

```dart
AppUpdatePilot.check(
  context: context,
  config: const UpdateConfig(
    latestVersion: '2.0.0',
    minVersion: '1.5.0',
    urgency: UpdateUrgency.recommended,
    changelog: '## What\'s New\n- Bug fixes',
  ),
);
```

## Update Prompts

### Optional Update Prompt

A Material 3 dialog with version badge, changelog, skip, and remind-later actions.

```dart
AppUpdatePilot.check(
  context: context,
  config: config,
  showChangelog: true,
  allowSkip: true,
);
```

### Force Update Wall

A full-screen, non-dismissible wall when the current version is below the minimum required.

```dart
// Automatic — triggers when currentVersion < minVersion
AppUpdatePilot.check(
  context: context,
  config: const UpdateConfig(
    latestVersion: '3.0.0',
    minVersion: '2.5.0',
    urgency: UpdateUrgency.critical,
  ),
);

// Manual
AppUpdatePilot.showForceUpdateWall(context, status);
```

### Maintenance Wall

Blocks the app with a maintenance message and a spinner.

```dart
AppUpdatePilot.check(
  context: context,
  config: const UpdateConfig(
    maintenanceMode: true,
    maintenanceMessage: 'Back in 30 minutes!',
  ),
);
```

### Changelog Bottom Sheet

A draggable bottom sheet with markdown rendering — usable standalone.

```dart
AppUpdatePilot.showChangelog(
  context: context,
  changelog: '## What\'s New\n- Feature A\n- Bug fix B',
  version: '2.1.0',
);
```

### Update Banner

A non-intrusive notification bar for subtle update prompts.

```dart
UpdateBanner(
  status: status,
  onTap: () => AppUpdatePilot.openStore(status),
  onDismiss: () => setState(() => _showBanner = false),
)

// Or wrap any widget conditionally:
UpdateBanner.wrap(
  status: status,
  onTap: () => AppUpdatePilot.openStore(status),
  position: BannerPosition.bottom,
  child: MyHomePage(),
)
```

### UpdatePilotGuard

A wrapper widget that auto-checks on initialization and shows the appropriate UI.

```dart
UpdatePilotGuard(
  config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
  forceUpdateBuilder: (context, status) => MyForceUpdateScreen(status: status),
  maintenanceBuilder: (context, status) => MyMaintenancePage(status: status),
  onStatus: (status) => debugPrint('Update check: ${status.updateAvailable}'),
  child: HomeScreen(),
)
```

## Full Control API

For complete control over the update flow:

```dart
final status = await AppUpdatePilot.checkForUpdate(
  config: UpdateConfig.fromUrl('https://api.myapp.com/version'),
);

if (status.isMaintenanceMode) {
  AppUpdatePilot.showMaintenanceWall(context, status);
} else if (status.isForceUpdate) {
  AppUpdatePilot.showForceUpdateWall(context, status);
} else if (status.updateAvailable) {
  final action = await AppUpdatePilot.showUpdatePrompt(
    context, status,
    showChangelog: true,
    allowSkip: true,
  );
  debugPrint('User chose: $action'); // updated, skipped, remindLater, dismissed
}
```

## UI Customization

### Three levels of customization

**1. Replace entirely** — pass `customBuilder` to build your own widget:

```dart
AppUpdatePilot.check(
  context: context,
  config: config,
  promptBuilder: (context, status) => MyCustomDialog(status: status),
  forceUpdateBuilder: (context, status) => MyForceWall(status: status),
  maintenanceBuilder: (context, status) => MyMaintenancePage(status: status),
);
```

**2. Tweak pieces** — override individual elements:

```dart
AppUpdatePilot.check(
  context: context,
  config: config,
  icon: Icon(Icons.celebration, size: 28),
  title: 'Exciting New Update!',
  description: 'We\'ve been working hard on this one.',
  updateButtonText: 'Get It Now',
  skipButtonText: 'Not Now',
  remindButtonText: 'Maybe Later',
);
```

**3. Add extra content** — inject a widget below the action buttons:

```dart
AppUpdatePilot.check(
  context: context,
  config: config,
  footerBuilder: (context) => Text('Update size: ~15 MB'),
);
```

All widgets use `ColorScheme` tokens for automatic **dark mode** support.

## Advanced Features

### A/B Rollout

Show the update to only a percentage of users. The selection is deterministic per device — the same user always gets the same result.

```json
{
  "latest_version": "2.1.0",
  "rollout_percentage": 0.2
}
```

```dart
// Programmatic check
final inGroup = await AppUpdatePilot.isInRolloutGroup(0.2);
```

### Per-Platform Minimum Version

Set different force-update thresholds for Android and iOS:

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
  skipCooldown: Duration(days: 3),
  allowRemindLater: true,
  remindLaterCooldown: Duration(hours: 12),
);

// Programmatic control
await AppUpdatePilot.skipVersion('2.1.0');
await AppUpdatePilot.remindLater(Duration(hours: 12));
final skipped = await AppUpdatePilot.isVersionSkipped('2.1.0');
await AppUpdatePilot.clearPersistedState();
```

### Staged Urgency Levels

Control how strongly the update is presented:

| Urgency | Behavior |
|---|---|
| `optional` | Dismissible prompt |
| `recommended` | Prominent prompt, still dismissible |
| `critical` | Force update wall, cannot dismiss |

```json
{
  "latest_version": "2.1.0",
  "urgency": "critical"
}
```

## Analytics

### Global Configuration

```dart
void main() {
  AppUpdatePilot.configure(
    analytics: UpdateAnalytics(
      onPromptShown: (info) => tracker.track('update_prompt_shown', {
        'current': info.currentVersion,
        'latest': info.latestVersion,
      }),
      onUpdateAccepted: (info) => tracker.track('update_accepted'),
      onUpdateSkipped: (info, version) => tracker.track('update_skipped', {
        'version': version,
      }),
      onRemindLater: (info, delay) => tracker.track('update_remind_later'),
      onForceUpdateShown: (info) => tracker.track('force_update_shown'),
      onMaintenanceShown: (info) => tracker.track('maintenance_shown'),
      onCheckFailed: (error) => tracker.track('update_check_failed'),
    ),
  );

  runApp(MyApp());
}
```

### Per-call Callbacks

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

## Remote Config JSON Schema

| Field | Type | Default | Description |
|---|---|---|---|
| `latest_version` | `String` | — | Latest available version (e.g. `"2.1.0"`) |
| `min_version` | `String?` | `null` | Force update if current version is below this |
| `min_version_android` | `String?` | `null` | Android-specific minimum version |
| `min_version_ios` | `String?` | `null` | iOS-specific minimum version |
| `urgency` | `String?` | `"optional"` | `"optional"`, `"recommended"`, or `"critical"` |
| `changelog` | `String?` | `null` | Markdown changelog text |
| `rollout_percentage` | `double?` | `1.0` | Fraction of users to show the update (0.0–1.0) |
| `maintenance_mode` | `bool?` | `false` | Block app with maintenance screen |
| `maintenance_message` | `String?` | `null` | Custom maintenance message |
| `android_store_url` | `String?` | Auto | Override Android store URL |
| `ios_store_url` | `String?` | Auto | Override iOS store URL |

## Native In-App Updates (Android)

On Android, you can download and install updates **without leaving the app** using Google's Play In-App Updates API.

### Flexible Update (Background Download)

User can keep using the app while the update downloads. Show a snackbar when ready.

```dart
final info = await AppUpdatePilot.checkNativeUpdate();

if (info.isAvailable && info.flexibleAllowed) {
  // Listen for progress
  AppUpdatePilot.onNativeDownloadProgress = (progress) {
    print('Download: ${(progress * 100).toInt()}%');
  };

  // Listen for completion
  AppUpdatePilot.onNativeDownloadComplete = () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update ready!'),
        action: SnackBarAction(
          label: 'Restart',
          onPressed: () => AppUpdatePilot.completeNativeUpdate(),
        ),
      ),
    );
  };

  await AppUpdatePilot.startNativeUpdate(NativeUpdateType.flexible);
}
```

### Immediate Update (Full-Screen)

Blocks the app with a Play Store managed UI. App restarts automatically.

```dart
final info = await AppUpdatePilot.checkNativeUpdate();

if (info.isAvailable && info.immediateAllowed) {
  await AppUpdatePilot.startNativeUpdate(NativeUpdateType.immediate);
}
```

### NativeUpdateInfo Fields

| Field | Type | Description |
|---|---|---|
| `isAvailable` | `bool` | Whether a native update is available |
| `isSupported` | `bool` | Whether the platform supports it (Android only) |
| `flexibleAllowed` | `bool` | Whether flexible update is allowed |
| `immediateAllowed` | `bool` | Whether immediate update is allowed |
| `staleDays` | `int?` | Days since update was published |
| `priority` | `int` | Priority 0-5 (set in Play Console) |

> **Note:** Native in-app updates are Android only. On iOS, use `AppUpdatePilot.openStore()` to redirect to the App Store.

## Platform Setup

### Android

No additional setup required. The package uses Google's Play In-App Updates API for native updates and HTTP for store version checking. `INTERNET` permission is included in the plugin manifest.

Minimum SDK: 21 (Android 5.0)

### iOS

No additional setup required. The package checks the App Store via the iTunes Lookup API and opens store links via `url_launcher`.

Minimum deployment target: iOS 12.0

## API Reference

| Method | Description |
|---|---|
| `AppUpdatePilot.configure()` | Set global analytics callbacks |
| `AppUpdatePilot.check()` | One-line check + auto-show UI |
| `AppUpdatePilot.checkForUpdate()` | Headless check, returns `UpdateStatus` |
| `AppUpdatePilot.showForceUpdateWall()` | Show force update wall |
| `AppUpdatePilot.showUpdatePrompt()` | Show update prompt dialog |
| `AppUpdatePilot.showMaintenanceWall()` | Show maintenance wall |
| `AppUpdatePilot.showChangelog()` | Show changelog bottom sheet |
| `AppUpdatePilot.openStore()` | Open platform store listing |
| `AppUpdatePilot.skipVersion()` | Programmatically skip a version |
| `AppUpdatePilot.remindLater()` | Set remind-later timer |
| `AppUpdatePilot.isVersionSkipped()` | Check if version is skipped |
| `AppUpdatePilot.isInRolloutGroup()` | Check rollout eligibility |
| `AppUpdatePilot.checkNativeUpdate()` | Check for native in-app update (Android) |
| `AppUpdatePilot.startNativeUpdate()` | Start native flexible/immediate update |
| `AppUpdatePilot.completeNativeUpdate()` | Install flexible update and restart |
| `AppUpdatePilot.clearPersistedState()` | Reset all skip/remind state |

### Widgets

| Widget | Description |
|---|---|
| `UpdatePromptDialog` | Customizable update prompt dialog |
| `ForceUpdateWall` | Full-screen blocking update wall |
| `MaintenanceWall` | Full-screen maintenance screen |
| `ChangelogSheet` | Draggable bottom sheet with markdown changelog |
| `UpdateBanner` | Non-intrusive update notification bar |
| `UpdatePilotGuard` | Auto-check wrapper widget |

### Models

| Model | Description |
|---|---|
| `UpdateConfig` | Configuration for update checks |
| `UpdateStatus` | Result of an update check |
| `UpdateAction` | User action enum (updated, skipped, remindLater, dismissed, shown) |
| `UpdateAnalytics` | Structured analytics callbacks |
| `UpdateUrgency` | Urgency enum (optional, recommended, critical) |
| `BannerPosition` | Banner position enum (top, bottom) |
| `NativeUpdateType` | Native update type enum (flexible, immediate) |
| `NativeUpdateInfo` | Result of native update availability check |

## Example

See the [example app](example/lib/main.dart) for a complete demo showcasing all features:

- Optional update prompt with changelog
- Customized prompt with custom icon, title, footer
- Force update wall
- Maintenance wall with custom footer
- Changelog bottom sheet
- Non-intrusive update banner
- Manual check with full control
- Analytics integration

## License

MIT License. See [LICENSE](LICENSE) for details.
