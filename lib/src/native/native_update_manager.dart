import 'dart:io';
import 'package:flutter/services.dart';

/// Type of native in-app update (Android only).
enum NativeUpdateType {
  /// Downloads in background. User can keep using the app.
  /// Call [NativeUpdateManager.completeUpdate] when ready to install.
  flexible,

  /// Full-screen blocking UI. User must update to continue.
  immediate,
}

/// Result of a native update availability check.
class NativeUpdateInfo {
  /// Whether a native in-app update is available.
  final bool isAvailable;

  /// Whether flexible (background) update is allowed.
  final bool flexibleAllowed;

  /// Whether immediate (blocking) update is allowed.
  final bool immediateAllowed;

  /// Days since the update was published on the Play Store.
  final int? staleDays;

  /// Update priority (0-5) set in Google Play Console.
  final int priority;

  /// Available version code from the store.
  final int availableVersionCode;

  /// Current install status code.
  final int installStatus;

  /// Creates a [NativeUpdateInfo].
  const NativeUpdateInfo({
    required this.isAvailable,
    required this.flexibleAllowed,
    required this.immediateAllowed,
    this.staleDays,
    this.priority = 0,
    this.availableVersionCode = 0,
    this.installStatus = 0,
  });

  /// Whether native in-app updates are supported on this platform.
  bool get isSupported => Platform.isAndroid;
}

/// Manages native in-app updates via platform channels.
///
/// On **Android**, uses Google's Play In-App Updates API to download and
/// install updates without leaving the app.
///
/// On **iOS**, native in-app updates are not available. Use
/// [AppUpdatePilot.openStore] to redirect users to the App Store.
///
/// Usage:
/// ```dart
/// final info = await NativeUpdateManager.checkUpdate();
/// if (info.isAvailable && info.flexibleAllowed) {
///   await NativeUpdateManager.startUpdate(NativeUpdateType.flexible);
///   // Listen for progress via onDownloadProgress
///   // When done, call NativeUpdateManager.completeUpdate()
/// }
/// ```
class NativeUpdateManager {
  NativeUpdateManager._();

  static const _channel = MethodChannel('app_update_pilot');

  /// Callback for flexible download progress (0.0 to 1.0).
  static void Function(double progress)? onDownloadProgress;

  /// Callback when flexible download completes and is ready to install.
  static void Function()? onDownloadComplete;

  static bool _listenerRegistered = false;

  /// Check if a native in-app update is available.
  ///
  /// Returns [NativeUpdateInfo] with availability and type support.
  /// On iOS, always returns [NativeUpdateInfo.isAvailable] = false.
  static Future<NativeUpdateInfo> checkUpdate() async {
    if (!Platform.isAndroid) {
      return const NativeUpdateInfo(
        isAvailable: false,
        flexibleAllowed: false,
        immediateAllowed: false,
      );
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'checkNativeUpdate',
      );
      if (result == null) {
        return const NativeUpdateInfo(
          isAvailable: false,
          flexibleAllowed: false,
          immediateAllowed: false,
        );
      }
      return NativeUpdateInfo(
        isAvailable: result['isAvailable'] as bool? ?? false,
        flexibleAllowed: result['flexibleAllowed'] as bool? ?? false,
        immediateAllowed: result['immediateAllowed'] as bool? ?? false,
        staleDays: result['staleDays'] as int?,
        priority: result['priority'] as int? ?? 0,
        availableVersionCode: result['availableVersionCode'] as int? ?? 0,
        installStatus: result['installStatus'] as int? ?? 0,
      );
    } on PlatformException {
      return const NativeUpdateInfo(
        isAvailable: false,
        flexibleAllowed: false,
        immediateAllowed: false,
      );
    }
  }

  /// Start a native in-app update.
  ///
  /// [type] controls the update experience:
  /// - [NativeUpdateType.flexible]: Downloads in background. User keeps using
  ///   the app. Set [onDownloadProgress] and [onDownloadComplete] callbacks
  ///   before calling this. Call [completeUpdate] when ready to install.
  /// - [NativeUpdateType.immediate]: Shows a full-screen update UI managed
  ///   by the Play Store. App restarts automatically after install.
  ///
  /// Throws [PlatformException] on iOS or if no update is available.
  static Future<bool> startUpdate(NativeUpdateType type) async {
    _ensureListener();
    final result = await _channel.invokeMethod<bool>(
      'startNativeUpdate',
      {'type': type == NativeUpdateType.immediate ? 'immediate' : 'flexible'},
    );
    return result ?? false;
  }

  /// Complete a flexible update (triggers app restart).
  ///
  /// Call this after a flexible download finishes. The app will restart
  /// with the new version.
  static Future<bool> completeUpdate() async {
    final result = await _channel.invokeMethod<bool>('completeNativeUpdate');
    return result ?? false;
  }

  /// Register the method call handler for install state updates from native.
  static void _ensureListener() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onInstallStateUpdate') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final status = args['status'] as int? ?? 0;
        final downloaded = args['bytesDownloaded'] as int? ?? 0;
        final total = args['totalBytesToDownload'] as int? ?? 1;

        if (total > 0) {
          final progress = downloaded / total;
          onDownloadProgress?.call(progress);
        }

        // InstallStatus.DOWNLOADED == 11
        if (status == 11) {
          onDownloadComplete?.call();
        }
      }
    });
  }
}
