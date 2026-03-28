package com.appupdatepilot

import io.flutter.embedding.engine.plugins.FlutterPlugin

class AppUpdatePilotPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No method channels needed — this plugin uses Dart-only HTTP calls.
        // The native registration is required so Flutter recognises the plugin.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }
}
