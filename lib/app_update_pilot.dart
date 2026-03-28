/// The complete app update lifecycle manager for Flutter.
///
/// Provides store version checks, force update walls, A/B rollout,
/// rich changelogs, skip with cooldown, analytics hooks, and
/// remote config from any JSON API.
library app_update_pilot;

export 'src/app_update_pilot.dart';
export 'src/models/update_config.dart';
export 'src/models/update_status.dart';
export 'src/models/update_action.dart';
export 'src/ui/update_prompt_dialog.dart';
export 'src/ui/force_update_wall.dart';
export 'src/ui/maintenance_wall.dart';
export 'src/utils/version_utils.dart';
export 'src/utils/skip_version_manager.dart';
