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
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Flutter host plus the native Child Mode telemetry bridge.
 *
 * Pairing credentials are never returned to Flutter after setup: configure
 * writes them to Android Keystore-backed storage. Location collection starts
 * only after real Android permissions are granted; chat uses a scoped native
 * request proxy without exposing the credential.
 */
class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val chatExecutor = Executors.newSingleThreadExecutor()
    private val chatHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TELEMETRY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestLocationPermissions" -> requestLocationPermissions(result)
                    "configureAndStart" -> configureAndStart(call, result)
                    "chatRequest" -> proxyFamilyChatRequest(call, result)
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
        if (!validOrigin(apiOrigin) || !validUuid(deviceId) || credential == null || !Regex("^[A-Za-z0-9_-]{32,128}$").matches(credential)) {
            result.success(mapOf<String, Any>("started" to false, "reason" to "invalid_native_telemetry_configuration"))
            return
        }
        try {
            // Pairing is a chat capability too: retain the credential securely even if the
            // guardian or child declines location permission. Location collection remains off.
            TelemetryConfigStore(this).write(TelemetryConfig(apiOrigin!!.trimEnd('/'), deviceId!!, credential))
            LocationReportStatusStore(this).resetForNewPairing()
            if (!hasFineLocation() || !hasBackgroundLocation()) {
                result.success(mapOf<String, Any>("started" to false, "reason" to "location_permission_required"))
                return
            }
            val serviceIntent = Intent(this, ChildTelemetryService::class.java)
            ContextCompat.startForegroundService(this, serviceIntent)
            result.success(mapOf<String, Any>("started" to true, "reason" to "started"))
        } catch (_: Exception) {
            result.success(mapOf<String, Any>("started" to false, "reason" to "native_telemetry_start_failed"))
        }
    }

    private fun stopTelemetry(result: MethodChannel.Result) {
        val stopped = stopService(Intent(this, ChildTelemetryService::class.java))
        result.success(mapOf<String, Any>("stopped" to (stopped || !ChildTelemetryService.isRunning)))
    }

    private fun telemetryStatus(result: MethodChannel.Result) {
        val config = TelemetryConfigStore(this).read()
        // The last report's outcome travels as a closed vocabulary (see LocationReportOutcome)
        // plus times, so the child's screen can say "sharing stopped: this phone was
        // disconnected" from what the server actually answered, not from a guess.
        result.success(mapOf(
            "available" to true,
            "running" to ChildTelemetryService.isRunning,
            "configured" to (config != null),
            "deviceId" to (config?.deviceId ?: ""),
            "fineLocationGranted" to hasFineLocation(),
            "backgroundLocationGranted" to hasBackgroundLocation(),
        ) + LocationReportStatusStore(this).snapshot())
    }

    /**
     * Runs one of the six allow-listed child chat operations without returning the device
     * credential to Dart. IDs, verbs and request paths are reconstructed here from operation
     * names; a Flutter caller cannot turn this bridge into an arbitrary authenticated proxy.
     */
    private fun proxyFamilyChatRequest(call: MethodCall, result: MethodChannel.Result) {
        val config = TelemetryConfigStore(this).read()
        if (config == null) {
            result.error("device_chat_not_configured", "No paired device session is available.", null)
            return
        }
        val requestedDeviceId = call.argument<String>("deviceId")?.trim()
        if (requestedDeviceId != config.deviceId) {
            result.error("device_chat_scope_mismatch", "The device scope does not match this paired handset.", null)
            return
        }
        val operation = call.argument<String>("operation") ?: ""
        val threadId = call.argument<String>("threadId")?.trim()
        val messageId = call.argument<String>("messageId")?.trim()
        val body = call.argument<String>("body")
        val idempotencyKey = call.argument<String>("idempotencyKey")?.trim()
        val query = call.argument<Map<*, *>>("queryParameters") ?: emptyMap<Any, Any>()
        val spec = familyChatRequestSpec(
            operation = operation,
            deviceId = config.deviceId,
            threadId = threadId,
            messageId = messageId,
            query = query,
            body = body,
            idempotencyKey = idempotencyKey,
        )
        if (spec == null) {
            result.error("invalid_device_chat_request", "The chat operation is not valid for this route.", null)
            return
        }
        chatExecutor.execute {
            try {
                val requestBuilder = Request.Builder()
                    .url("${config.apiOrigin}${spec.path}")
                    .header("Authorization", "Device ${config.deviceCredential}")
                    .header("Accept", "application/json")
                if (spec.idempotencyKey != null) {
                    requestBuilder.header("Idempotency-Key", spec.idempotencyKey)
                }
                val requestBody = spec.body?.toRequestBody(JSON_MEDIA_TYPE)
                val request = requestBuilder.method(spec.method, requestBody).build()
                val answer = chatHttpClient.newCall(request).execute().use { response ->
                    mapOf(
                        "statusCode" to response.code,
                        "body" to (response.body?.string() ?: ""),
                    )
                }
                runOnUiThread { result.success(answer) }
            } catch (_: Exception) {
                // Credentials, message bodies and server response text are never logged.
                runOnUiThread {
                    result.error("device_chat_unreachable", "The family chat service did not answer.", null)
                }
            }
        }
    }

    private fun familyChatRequestSpec(
        operation: String,
        deviceId: String,
        threadId: String?,
        messageId: String?,
        query: Map<*, *>,
        body: String?,
        idempotencyKey: String?,
    ): ChatRequestSpec? {
        if (query.keys.any { it !in setOf("afterSeq", "limit") }) return null
        val base = "/v1/devices/$deviceId/chat"
        return when (operation) {
            "listThreads" -> if (threadId == null && messageId == null && body == null && query.isEmpty()) {
                ChatRequestSpec("GET", "$base/threads", null, null)
            } else null
            "listParticipants" -> if (threadId == null && messageId == null && body == null && query.isEmpty()) {
                ChatRequestSpec("GET", "$base/participants", null, null)
            } else null
            "createThread" -> if (threadId == null && messageId == null && validJsonObject(body) && validIdempotencyKey(idempotencyKey) && query.isEmpty()) {
                ChatRequestSpec("POST", "$base/threads", body, idempotencyKey)
            } else null
            "addThreadMember" -> if (validUuid(threadId) && messageId == null && validJsonObject(body) && validIdempotencyKey(idempotencyKey) && query.isEmpty()) {
                ChatRequestSpec("POST", "$base/threads/$threadId/members", body, idempotencyKey)
            } else null
            "listMessages" -> {
                if (!validUuid(threadId) || messageId != null || body != null) return null
                val afterRaw = query["afterSeq"] as? String
                val limitRaw = query["limit"] as? String
                val afterSeq = if (afterRaw == null) 0L else afterRaw.toLongOrNull() ?: return null
                val limit = if (limitRaw == null) 50 else limitRaw.toIntOrNull() ?: return null
                if (afterSeq < 0 || afterSeq > 9007199254740991L || limit !in 1..200) return null
                val uri = Uri.parse("$base/threads/$threadId/messages").buildUpon()
                    .appendQueryParameter("afterSeq", afterSeq.toString())
                    .appendQueryParameter("limit", limit.toString())
                    .build()
                ChatRequestSpec("GET", uri.toString(), null, null)
            }
            "sendMessage" -> if (validUuid(threadId) && messageId == null && validJsonObject(body) && validIdempotencyKey(idempotencyKey) && query.isEmpty()) {
                ChatRequestSpec("POST", "$base/threads/$threadId/messages", body, idempotencyKey)
            } else null
            "editMessage" -> if (validUuid(threadId) && validUuid(messageId) && validJsonObject(body) && idempotencyKey == null && query.isEmpty()) {
                ChatRequestSpec("PATCH", "$base/threads/$threadId/messages/$messageId", body, null)
            } else null
            "deleteMessage" -> if (validUuid(threadId) && validUuid(messageId) && body == "{}" && validIdempotencyKey(idempotencyKey) && query.isEmpty()) {
                ChatRequestSpec("POST", "$base/threads/$threadId/messages/$messageId/deletion", body, idempotencyKey)
            } else null
            "markRead" -> if (validUuid(threadId) && messageId == null && validJsonObject(body) && validIdempotencyKey(idempotencyKey) && query.isEmpty()) {
                ChatRequestSpec("POST", "$base/threads/$threadId/reads", body, idempotencyKey)
            } else null
            "markDelivered" -> if (validUuid(threadId) && messageId == null && validJsonObject(body) && validIdempotencyKey(idempotencyKey) && query.isEmpty()) {
                ChatRequestSpec("POST", "$base/threads/$threadId/delivered", body, idempotencyKey)
            } else null
            else -> null
        }
    }

    private fun validJsonObject(value: String?): Boolean = try {
        value != null && value.length <= 4096 && org.json.JSONObject(value).length() >= 0
    } catch (_: Exception) {
        false
    }

    private fun validIdempotencyKey(value: String?): Boolean =
        !value.isNullOrBlank() && value.length <= 128

    override fun onDestroy() {
        chatExecutor.shutdownNow()
        super.onDestroy()
    }

    private data class ChatRequestSpec(
        val method: String,
        val path: String,
        val body: String?,
        val idempotencyKey: String?,
    )

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
        private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
        private const val TELEMETRY_CHANNEL = "com.familyos.family_os/native_child_telemetry"
        private const val REQUEST_FOREGROUND_LOCATION = 8101
        private const val REQUEST_BACKGROUND_LOCATION = 8102
        const val EXTRA_FLUTTER_ROUTE = "flutter_route"
        const val EXTRA_FLUTTER_AUDIT = "flutter_audit"
    }
}
