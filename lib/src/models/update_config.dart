
/// How urgently the update should be presented to the user.
enum UpdateUrgency {
  /// User can ignore indefinitely.
  optional,

  /// User is encouraged to update but can dismiss.
  recommended,

  /// User must update to continue using the app.
  critical,
}

/// Configuration for how update checks are performed and what rules apply.
class UpdateConfig {
  /// The latest available version string (e.g. "2.1.0").
  final String? latestVersion;

  /// Minimum required version. If the current app version is below this,
  /// a force update wall is shown.
  final String? minVersion;

  /// Minimum version per platform. Keys: "android", "ios".
  final Map<String, String>? minVersionByPlatform;

  /// URL to fetch the remote config JSON from.
  final String? remoteConfigUrl;

  /// Whether to check the Play Store / App Store directly.
  final bool checkStore;

  /// The urgency level of the update.
  final UpdateUrgency urgency;

  /// Changelog text (supports markdown).
  final String? changelog;

  /// Rollout percentage (0.0 - 1.0). Only this fraction of users will
  /// see the update prompt.
  final double rolloutPercentage;

  /// Whether the app is in maintenance mode.
  final bool maintenanceMode;

  /// Maintenance message to display.
  final String? maintenanceMessage;

  /// Store URL override for Android.
  final String? androidStoreUrl;

  /// Store URL override for iOS.
  final String? iosStoreUrl;

  /// Custom headers for the remote config URL request.
  final Map<String, String>? remoteConfigHeaders;

  /// Creates an [UpdateConfig] with the given parameters.
  const UpdateConfig({
    this.latestVersion,
    this.minVersion,
    this.minVersionByPlatform,
    this.remoteConfigUrl,
    this.checkStore = false,
    this.urgency = UpdateUrgency.optional,
    this.changelog,
    this.rolloutPercentage = 1.0,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.androidStoreUrl,
    this.iosStoreUrl,
    this.remoteConfigHeaders,
  });

  /// Create config that auto-checks the Play Store / App Store.
  factory UpdateConfig.fromStore({
    String? androidStoreUrl,
    String? iosStoreUrl,
  }) {
    return UpdateConfig(
      checkStore: true,
      androidStoreUrl: androidStoreUrl,
      iosStoreUrl: iosStoreUrl,
    );
  }

  /// Create config from a remote JSON URL.
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "latest_version": "2.1.0",
  ///   "min_version": "1.5.0",
  ///   "min_version_android": "1.5.0",
  ///   "min_version_ios": "1.4.0",
  ///   "urgency": "recommended",
  ///   "changelog": "## What's new\n- Bug fixes",
  ///   "rollout_percentage": 0.5,
  ///   "maintenance_mode": false,
  ///   "maintenance_message": null,
  ///   "android_store_url": null,
  ///   "ios_store_url": null
  /// }
  /// ```
  factory UpdateConfig.fromUrl(
    String url, {
    Map<String, String>? headers,
  }) {
    return UpdateConfig(
      remoteConfigUrl: url,
      remoteConfigHeaders: headers,
    );
  }

  /// Create config from a map of key-value pairs.
  ///
  /// Useful for integrating with Firebase Remote Config or any
  /// other key-value config source:
  /// ```dart
  /// final remoteConfig = FirebaseRemoteConfig.instance;
  /// await remoteConfig.fetchAndActivate();
  /// AppUpdatePilot.check(
  ///   context: context,
  ///   config: UpdateConfig.fromMap({
  ///     'latest_version': remoteConfig.getString('app_latest_version'),
  ///     'min_version': remoteConfig.getString('app_min_version'),
  ///     'changelog': remoteConfig.getString('app_changelog'),
  ///     'maintenance_mode': remoteConfig.getBool('app_maintenance'),
  ///   }),
  /// );
  /// ```
  factory UpdateConfig.fromMap(Map<String, dynamic> map) {
    return UpdateConfig.fromJson(map);
  }

  /// Parse a remote JSON response into an UpdateConfig.
  static UpdateConfig fromJson(Map<String, dynamic> json) {
    return UpdateConfig(
      latestVersion: json['latest_version'] as String?,
      minVersion: json['min_version'] as String?,
      minVersionByPlatform: {
        if (json['min_version_android'] != null)
          'android': json['min_version_android'] as String,
        if (json['min_version_ios'] != null)
          'ios': json['min_version_ios'] as String,
      },
      urgency: _parseUrgency(json['urgency'] as String?),
      changelog: json['changelog'] as String?,
      rolloutPercentage:
          (json['rollout_percentage'] as num?)?.toDouble() ?? 1.0,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      maintenanceMessage: json['maintenance_message'] as String?,
      androidStoreUrl: json['android_store_url'] as String?,
      iosStoreUrl: json['ios_store_url'] as String?,
    );
  }

  static UpdateUrgency _parseUrgency(String? value) {
    switch (value) {
      case 'critical':
        return UpdateUrgency.critical;
      case 'recommended':
        return UpdateUrgency.recommended;
      default:
        return UpdateUrgency.optional;
    }
  }

  /// Whether this config was created from a map (e.g. Firebase Remote Config).
  bool get isFromMap => remoteConfigUrl == null && latestVersion != null;

  /// Creates a copy of this config with the given fields replaced.
  UpdateConfig copyWith({
    String? latestVersion,
    String? minVersion,
    Map<String, String>? minVersionByPlatform,
    String? remoteConfigUrl,
    bool? checkStore,
    UpdateUrgency? urgency,
    String? changelog,
    double? rolloutPercentage,
    bool? maintenanceMode,
    String? maintenanceMessage,
    String? androidStoreUrl,
    String? iosStoreUrl,
  }) {
    return UpdateConfig(
      latestVersion: latestVersion ?? this.latestVersion,
      minVersion: minVersion ?? this.minVersion,
      minVersionByPlatform: minVersionByPlatform ?? this.minVersionByPlatform,
      remoteConfigUrl: remoteConfigUrl ?? this.remoteConfigUrl,
      checkStore: checkStore ?? this.checkStore,
      urgency: urgency ?? this.urgency,
      changelog: changelog ?? this.changelog,
      rolloutPercentage: rolloutPercentage ?? this.rolloutPercentage,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      androidStoreUrl: androidStoreUrl ?? this.androidStoreUrl,
      iosStoreUrl: iosStoreUrl ?? this.iosStoreUrl,
    );
  }
}
