import Flutter
import UIKit

public class AppUpdatePilotPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "app_update_pilot",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppUpdatePilotPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkNativeUpdate":
            // iOS does not support native in-app updates
            result([
                "isAvailable": false,
                "updateAvailability": 1, // UPDATE_NOT_AVAILABLE
                "flexibleAllowed": false,
                "immediateAllowed": false,
                "staleDays": NSNull(),
                "priority": 0,
                "installStatus": 0,
                "availableVersionCode": 0,
            ] as [String: Any])
        case "startNativeUpdate":
            result(FlutterError(
                code: "NOT_SUPPORTED",
                message: "Native in-app updates are not supported on iOS. Use openStore() instead.",
                details: nil
            ))
        case "completeNativeUpdate":
            result(FlutterError(
                code: "NOT_SUPPORTED",
                message: "Native in-app updates are not supported on iOS.",
                details: nil
            ))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
