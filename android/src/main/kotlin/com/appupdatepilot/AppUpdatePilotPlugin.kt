package com.appupdatepilot

import android.app.Activity
import android.content.IntentSender
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class AppUpdatePilotPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var appUpdateManager: AppUpdateManager? = null
    private var installStateListener: InstallStateUpdatedListener? = null

    // ── FlutterPlugin ──────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "app_update_pilot")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ── ActivityAware ──────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        appUpdateManager = AppUpdateManagerFactory.create(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        appUpdateManager = AppUpdateManagerFactory.create(binding.activity)
    }
    override fun onDetachedFromActivity() {
        unregisterListener()
        activity = null
        appUpdateManager = null
    }

    // ── MethodCallHandler ──────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkNativeUpdate" -> checkNativeUpdate(result)
            "startNativeUpdate" -> {
                val type = call.argument<String>("type") ?: "flexible"
                startNativeUpdate(type, result)
            }
            "completeNativeUpdate" -> completeNativeUpdate(result)
            else -> result.notImplemented()
        }
    }

    // ── Check ──────────────────────────────────────────────────────

    private fun checkNativeUpdate(result: MethodChannel.Result) {
        val manager = appUpdateManager
        if (manager == null) {
            result.error("NO_ACTIVITY", "Activity not attached", null)
            return
        }

        manager.appUpdateInfo.addOnSuccessListener { info: AppUpdateInfo ->
            val map = hashMapOf<String, Any?>(
                "updateAvailability" to info.updateAvailability(),
                "availableVersionCode" to info.availableVersionCode(),
                "installStatus" to info.installStatus(),
                "staleDays" to info.clientVersionStalenessDays(),
                "priority" to info.updatePriority(),
                "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                "immediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                "isAvailable" to (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE),
            )
            result.success(map)
        }.addOnFailureListener { e ->
            result.error("CHECK_FAILED", e.message, null)
        }
    }

    // ── Start update ───────────────────────────────────────────────

    private fun startNativeUpdate(type: String, result: MethodChannel.Result) {
        val manager = appUpdateManager
        val act = activity
        if (manager == null || act == null) {
            result.error("NO_ACTIVITY", "Activity not attached", null)
            return
        }

        val updateType = if (type == "immediate") AppUpdateType.IMMEDIATE else AppUpdateType.FLEXIBLE

        manager.appUpdateInfo.addOnSuccessListener { info: AppUpdateInfo ->
            if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE) {
                result.error("NO_UPDATE", "No update available", null)
                return@addOnSuccessListener
            }

            if (!info.isUpdateTypeAllowed(updateType)) {
                result.error("TYPE_NOT_ALLOWED", "$type update not allowed", null)
                return@addOnSuccessListener
            }

            if (updateType == AppUpdateType.FLEXIBLE) {
                registerFlexibleListener()
            }

            try {
                manager.startUpdateFlowForResult(
                    info,
                    act,
                    AppUpdateOptions.newBuilder(updateType).build(),
                    REQUEST_CODE_UPDATE,
                )
                result.success(true)
            } catch (e: IntentSender.SendIntentException) {
                result.error("START_FAILED", e.message, null)
            } catch (e: Exception) {
                result.error("START_FAILED", e.message, null)
            }
        }.addOnFailureListener { e ->
            result.error("START_FAILED", e.message, null)
        }
    }

    // ── Complete flexible update ───────────────────────────────────

    private fun completeNativeUpdate(result: MethodChannel.Result) {
        val manager = appUpdateManager
        if (manager == null) {
            result.error("NO_ACTIVITY", "Activity not attached", null)
            return
        }
        manager.completeUpdate().addOnSuccessListener {
            result.success(true)
        }.addOnFailureListener { e ->
            result.error("COMPLETE_FAILED", e.message, null)
        }
    }

    // ── Flexible download listener ─────────────────────────────────

    private fun registerFlexibleListener() {
        unregisterListener()
        installStateListener = InstallStateUpdatedListener { state ->
            val map = hashMapOf<String, Any?>(
                "status" to state.installStatus(),
                "bytesDownloaded" to state.bytesDownloaded(),
                "totalBytesToDownload" to state.totalBytesToDownload(),
            )
            channel.invokeMethod("onInstallStateUpdate", map)
        }
        appUpdateManager?.registerListener(installStateListener!!)
    }

    private fun unregisterListener() {
        installStateListener?.let { appUpdateManager?.unregisterListener(it) }
        installStateListener = null
    }

    companion object {
        private const val REQUEST_CODE_UPDATE = 7289
    }
}
