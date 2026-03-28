## 0.1.0

Initial release of `app_update_pilot`.

### Core Features
- **Store version checking** — automatic Play Store (HTML scraping) and App Store (iTunes Lookup API) detection.
- **Remote config** — fetch update rules from any JSON API endpoint with custom headers.
- **Firebase Remote Config** — ready-to-use `UpdateConfig.firebase()` factory.
- **Force update wall** — non-dismissible full-screen UI when current version is below minimum required.
- **Maintenance mode wall** — block app usage during server downtime with custom messaging.
- **Version comparison** — robust semantic version parsing and comparison (`1.2.3`, `v1.2.3`, `1.2`).

### Update Prompts
- **Optional update prompt** — Material 3 dialog with changelog, skip, and remind-later actions.
- **Changelog bottom sheet** — draggable sheet with markdown rendering via `flutter_markdown`.
- **Update banner** — non-intrusive notification bar with dismiss and update actions.
- **UpdatePilotGuard** — wrapper widget that auto-checks on app start and shows appropriate UI.

### Advanced Features
- **A/B rollout** — show updates to a percentage of users with stable per-device hashing.
- **Per-platform minimum version** — separate Android/iOS force-update thresholds.
- **Skip version with cooldown** — persist user's skip choice with configurable re-prompt timer.
- **Remind me later** — re-prompt after configurable delay (default 24 hours).
- **Staged urgency** — `optional`, `recommended`, and `critical` levels.

### Customization
- **Full UI override** — `customBuilder` on every widget to replace the entire screen.
- **Granular overrides** — `icon`, `title`, `description`, button text on all widgets.
- **Footer builder** — inject custom widgets below action buttons (e.g. update size, support links).
- **Custom themes** — all widgets use `ColorScheme` for automatic dark mode support.

### Analytics
- **`UpdateAnalytics`** — structured callbacks: `onPromptShown`, `onUpdateAccepted`, `onUpdateSkipped`, `onRemindLater`, `onForceUpdateShown`, `onMaintenanceShown`, `onCheckFailed`.
- **`AppUpdatePilot.configure()`** — set analytics globally once at app start.
- Automatic event firing from `AppUpdatePilot.check()`.

### Public API
- `AppUpdatePilot.check()` — one-line setup with auto UI.
- `AppUpdatePilot.checkForUpdate()` — headless check returning `UpdateStatus`.
- `AppUpdatePilot.showForceUpdateWall()` / `showUpdatePrompt()` / `showMaintenanceWall()` — manual UI display.
- `AppUpdatePilot.showChangelog()` — standalone changelog bottom sheet.
- `AppUpdatePilot.openStore()` — open platform store listing.
- `AppUpdatePilot.skipVersion()` / `remindLater()` / `isVersionSkipped()` — programmatic skip/remind control.
- `AppUpdatePilot.isInRolloutGroup()` — check rollout eligibility.
- `AppUpdatePilot.clearPersistedState()` — reset all skip/remind state.
