package com.familyos.family_os

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter host plus the native Child Mode telemetry bridge.
 *
 * Pairing credentials are never returned to Flutter after setup: configure
 * writes them to Android Keystore-backed storage and starts the foreground
 * service only after real Android permissions are granted.
 */
class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TELEMETRY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestLocationPermissions" -> requestLocationPermissions(result)
                    "configureAndStart" -> configureAndStart(call, result)
                    "stop" -> stopTelemetry(result)
                    "status" -> telemetryStatus(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestLocationPermissions(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("permission_request_in_progress", "A location permission request is already active.", null)
            return
        }
        if (hasFineLocation() && hasBackgroundLocation()) {
            result.success(permissionState())
            return
        }
        pendingPermissionResult = result
        if (!hasFineLocation()) {
            val permissions = mutableListOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS)
            }
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), REQUEST_FOREGROUND_LOCATION)
            return
        }
        requestBackgroundLocation()
    }

    private fun requestBackgroundLocation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !hasBackgroundLocation()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                REQUEST_BACKGROUND_LOCATION,
            )
            return
        }
        completePermissionRequest()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_FOREGROUND_LOCATION -> {
                if (hasFineLocation()) requestBackgroundLocation() else completePermissionRequest()
            }
            REQUEST_BACKGROUND_LOCATION -> completePermissionRequest()
        }
    }

    private fun completePermissionRequest() {
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        result.success(permissionState())
    }

    private fun configureAndStart(call: MethodCall, result: MethodChannel.Result) {
        val apiOrigin = call.argument<String>("apiOrigin")?.trim()
        val deviceId = call.argument<String>("deviceId")?.trim()
        val credential = call.argument<String>("deviceCredential")?.trim()
        if (!hasFineLocation() || !hasBackgroundLocation()) {
            result.success(mapOf("started" to false, "reason" to "location_permission_required"))
            return
        }
        if (!validOrigin(apiOrigin) || !validUuid(deviceId) || credential == null || !Regex("^[A-Za-z0-9_-]{32,128}$").matches(credential)) {
            result.success(mapOf("started" to false, "reason" to "invalid_native_telemetry_configuration"))
            return
        }
        try {
            TelemetryConfigStore(this).write(TelemetryConfig(apiOrigin!!.trimEnd('/'), deviceId!!, credential))
            val serviceIntent = Intent(this, ChildTelemetryService::class.java)
            ContextCompat.startForegroundService(this, serviceIntent)
            result.success(mapOf("started" to true, "reason" to "started"))
        } catch (_: Exception) {
            result.success(mapOf("started" to false, "reason" to "native_telemetry_start_failed"))
        }
    }

    private fun stopTelemetry(result: MethodChannel.Result) {
        val stopped = stopService(Intent(this, ChildTelemetryService::class.java))
        result.success(mapOf<String, Any>("stopped" to (stopped || !ChildTelemetryService.isRunning)))
    }

    private fun telemetryStatus(result: MethodChannel.Result) {
        result.success(mapOf(
            "available" to true,
            "running" to ChildTelemetryService.isRunning,
            "configured" to (TelemetryConfigStore(this).read() != null),
            "fineLocationGranted" to hasFineLocation(),
            "backgroundLocationGranted" to hasBackgroundLocation(),
        ))
    }

    private fun hasFineLocation(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun hasBackgroundLocation(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun permissionState(): Map<String, Any> = mapOf(
        "available" to true,
        "fineLocationGranted" to hasFineLocation(),
        "backgroundLocationGranted" to hasBackgroundLocation(),
    )

    private fun validOrigin(raw: String?): Boolean = try {
        val uri = Uri.parse(raw)
        uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo.isNullOrBlank() &&
            uri.query.isNullOrBlank() && uri.fragment.isNullOrBlank() &&
            (uri.path.isNullOrBlank() || uri.path == "/")
    } catch (_: Exception) {
        false
    }

    private fun validUuid(value: String?): Boolean =
        value != null && Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$").matches(value)

    override fun getInitialRoute(): String? {
        val fromIntent = intent?.getStringExtra(EXTRA_FLUTTER_ROUTE)?.trim()
        if (!fromIntent.isNullOrEmpty()) {
            val audit = intent?.getStringExtra(EXTRA_FLUTTER_AUDIT)?.trim()
            if (audit == "populated" && !fromIntent.contains("audit=")) {
                val join = if (fromIntent.contains("?")) "&" else "?"
                return "$fromIntent${join}audit=populated"
            }
            return fromIntent
        }
        return super.getInitialRoute()
    }

    companion object {
        private const val TELEMETRY_CHANNEL = "com.familyos.family_os/native_child_telemetry"
        private const val REQUEST_FOREGROUND_LOCATION = 8101
        private const val REQUEST_BACKGROUND_LOCATION = 8102
        const val EXTRA_FLUTTER_ROUTE = "flutter_route"
        const val EXTRA_FLUTTER_AUDIT = "flutter_audit"
    }
}
