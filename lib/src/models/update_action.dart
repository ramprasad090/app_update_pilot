/// Actions a user can take on the update prompt.
enum UpdateAction {
  /// User tapped "Update Now".
  updated,

  /// User dismissed the prompt.
  dismissed,

  /// User tapped "Skip This Version".
  skipped,

  /// User tapped "Remind Me Later".
  remindLater,

  /// The update prompt was shown to the user.
  shown,
}

/// Callback type for analytics hooks.
typedef UpdateActionCallback = void Function(UpdateAction action);
