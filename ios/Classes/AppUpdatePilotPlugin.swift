import Flutter
import UIKit

public class AppUpdatePilotPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // No method channels needed — this plugin uses Dart-only HTTP calls.
        // The native registration is required so Flutter recognises the plugin.
    }
}
