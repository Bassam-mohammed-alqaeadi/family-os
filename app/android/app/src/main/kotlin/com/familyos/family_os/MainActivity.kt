package com.familyos.family_os

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
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
    private var notificationMethodChannel: MethodChannel? = null
    private var pendingNotificationRoute: String? = null
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
                    "startConfigured" -> startConfiguredTelemetry(result)
                    "chatRequest" -> proxyFamilyChatRequest(call, result)
                    "minutesBalanceRequest" -> proxyMinutesBalanceRequest(call, result)
                    "consentRequest" -> proxyFamilyConsentRequest(call, result)
                    "capabilitySnapshot" -> capabilitySnapshot(result)
                    "stop" -> stopTelemetry(result)
                    "status" -> telemetryStatus(result)
                    "protectionState" -> protectionState(result)
                    "batteryGuidance" -> batteryGuidance(result)
                    "openBatterySettings" -> openBatterySettings(result)
                    else -> result.notImplemented()
                }
            }
        notificationMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "showForegroundNotification" -> showForegroundNotification(call, result)
                    "consumeNotificationRoute" -> result.success(consumeNotificationRoute())
                    else -> result.notImplemented()
                }
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
            // Written under the service's lock, so a late answer for the previous credential
            // can neither undo this pairing nor stamp its outcome onto it.
            TelemetryConfigStore.locked {
                TelemetryConfigStore(this).write(TelemetryConfig(apiOrigin!!.trimEnd('/'), deviceId!!, credential))
                LocationReportStatusStore(this).resetForNewPairing()
            }
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

    /**
     * Starts the foreground service from the pairing that is already stored, once the
     * disclosure has been made and the permissions asked. The pairing screen configures;
     * the transparency screen starts. Nothing here invents a credential.
     */
    private fun startConfiguredTelemetry(result: MethodChannel.Result) {
        val config = TelemetryConfigStore(this).read()
        if (config == null) {
            result.success(mapOf<String, Any>("started" to false, "reason" to "not_configured"))
            return
        }
        if (!hasFineLocation() || !hasBackgroundLocation()) {
            result.success(mapOf<String, Any>("started" to false, "reason" to "location_permission_required"))
            return
        }
        try {
            val serviceIntent = Intent(this, ChildTelemetryService::class.java)
            ContextCompat.startForegroundService(this, serviceIntent)
            result.success(mapOf<String, Any>("started" to true, "reason" to "started"))
        } catch (_: Exception) {
            result.success(mapOf<String, Any>("started" to false, "reason" to "native_telemetry_start_failed"))
        }
    }

    private fun capabilitySnapshot(result: MethodChannel.Result) {
        // S0 spine: honest snapshot from native signals only. Dart merges in the
        // capabilities it alone can confirm (push token presence, service binding).
        result.success(NativeCapabilitySnapshot.toJson(NativeCapabilitySnapshot.snapshot(this)))
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
     * S2 resilience: the protection verdict for the Flutter mirror (D7).
     *
     * Contract: `state` is one of `fully_protected` / `degraded` / `stopped` /
     * `not_configured`. `live=false` means the service never reported in this process
     * and the verdict was derived here (paired-but-silent = down). The activity always
     * re-reads the grants itself (`backgroundLocationGranted`, `notificationsGranted`)
     * so Dart can distrust a stale verdict instead of rendering it.
     */
    private fun protectionState(result: MethodChannel.Result) {
        try {
            val state = ChildTelemetryService.lastProtectionState
            if (state == null) {
                val configured = try {
                    TelemetryConfigStore(this).read() != null
                } catch (_: Exception) {
                    false
                }
                if (!configured) {
                    result.success(mapOf("available" to true, "state" to "not_configured"))
                    return
                }
                result.success(
                    mapOf(
                        "available" to true,
                        "state" to ProtectionState.Stopped(StoppedReason.SERVICE_DOWN, 0).wire,
                        "reason" to StoppedReason.SERVICE_DOWN.wire,
                        "queueDepth" to 0,
                        "live" to false,
                        "backgroundLocationGranted" to hasBackgroundLocation(),
                        "notificationsGranted" to hasNotifications(),
                    ),
                )
                return
            }
            val answer = mutableMapOf<String, Any>(
                "available" to true,
                "state" to state.wire,
                "live" to true,
                "backgroundLocationGranted" to hasBackgroundLocation(),
                "notificationsGranted" to hasNotifications(),
            )
            when (state) {
                is ProtectionState.FullyProtected -> Unit
                is ProtectionState.Degraded -> {
                    answer["reasons"] = state.reasons.map { it.wire }
                    answer["queueDepth"] = state.queueDepth
                }
                is ProtectionState.Stopped -> {
                    answer["reason"] = state.reason.wire
                    answer["queueDepth"] = state.queueDepth
                }
            }
            result.success(answer)
        } catch (_: Exception) {
            result.error("protection_state_unreadable", "The protection state could not be read.", null)
        }
    }

    /**
     * S2 resilience: which settings door opens the battery/autostart exemption for this
     * manufacturer (guidance only - nothing is requested programmatically, §12 row 2).
     */
    private fun batteryGuidance(result: MethodChannel.Result) {
        try {
            val entry = BatteryOemMap.guidance(Build.MANUFACTURER)
            result.success(
                mapOf(
                    "available" to true,
                    "vendor" to entry.vendorWire,
                    "action" to entry.action,
                    "package" to (entry.targetPackage ?: ""),
                    "activity" to (entry.targetActivity ?: ""),
                    "stepsKey" to entry.stepsKey,
                ),
            )
        } catch (_: Exception) {
            result.error("battery_guidance_unreadable", "The battery guidance could not be read.", null)
        }
    }

    /**
     * Opens the vendor's battery/autostart settings (resolve-checked: OEM component names
     * drift, so an unresolvable door falls back to the app-details screen and reports
     * `false` rather than crashing). Returns whether a vendor door was opened.
     */
    private fun openBatterySettings(result: MethodChannel.Result) {
        try {
            val entry = BatteryOemMap.guidance(Build.MANUFACTURER)
            val vendorIntent = if (entry.targetPackage != null && entry.targetActivity != null) {
                // Vendor activities are exported inconsistently; resolve before trusting.
                Intent(entry.action).setClassName(entry.targetPackage, entry.targetActivity)
            } else {
                Intent(entry.action)
            }
            val resolved = packageManager.resolveActivity(vendorIntent, PackageManager.MATCH_DEFAULT_ONLY)
            if (resolved != null) {
                startActivity(vendorIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(mapOf("available" to true, "opened" to true, "vendor" to entry.vendorWire))
                return
            }
            val details = Intent(
                android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", packageName, null),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (packageManager.resolveActivity(details, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                startActivity(details)
            }
            result.success(mapOf("available" to true, "opened" to false, "vendor" to entry.vendorWire))
        } catch (_: Exception) {
            result.success(mapOf("available" to true, "opened" to false, "vendor" to "stock"))
        }
    }

    private fun hasNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
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

    /// The child's own balance, read with the device credential that never leaves this layer.
    /// Only the scope check and the GET happen here; the body returns exactly as the server wrote it.
    private fun proxyMinutesBalanceRequest(call: MethodCall, result: MethodChannel.Result) {
        val config = TelemetryConfigStore(this).read()
        if (config == null) {
            result.error("device_minutes_not_configured", "No paired device session is available.", null)
            return
        }
        val requestedDeviceId = call.argument<String>("deviceId")?.trim()
        if (requestedDeviceId != config.deviceId) {
            result.error("device_minutes_scope_mismatch", "The device scope does not match this paired handset.", null)
            return
        }
        chatExecutor.execute {
            try {
                val request = Request.Builder()
                    .url("${config.apiOrigin}/v1/devices/${config.deviceId}/minutes-balance")
                    .header("Authorization", "Device ${config.deviceCredential}")
                    .header("Accept", "application/json")
                    .get()
                    .build()
                val answer = chatHttpClient.newCall(request).execute().use { response ->
                    mapOf(
                        "statusCode" to response.code,
                        "body" to (response.body?.string() ?: ""),
                    )
                }
                runOnUiThread { result.success(answer) }
            } catch (_: Exception) {
                // Credentials and balance bodies are never logged.
                runOnUiThread {
                    result.error("device_minutes_unreachable", "The minutes service did not answer.", null)
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

    /**
     * Runs the two allow-listed consent operations without returning the device credential
     * to Dart: the handset records the disclosure act its screen performed, and reads what it
     * is sharing as the ledger holds it. Verbs and request paths are reconstructed here from
     * operation names; a Flutter caller cannot turn this bridge into an arbitrary
     * authenticated proxy.
     */
    private fun proxyFamilyConsentRequest(call: MethodCall, result: MethodChannel.Result) {
        val config = TelemetryConfigStore(this).read()
        if (config == null) {
            result.error("device_consent_not_configured", "No paired device session is available.", null)
            return
        }
        val requestedDeviceId = call.argument<String>("deviceId")?.trim()
        if (requestedDeviceId != null && requestedDeviceId != config.deviceId) {
            result.error("device_consent_scope_mismatch", "The device scope does not match this paired handset.", null)
            return
        }
        val operation = call.argument<String>("operation") ?: ""
        val body = call.argument<String>("body")
        val idempotencyKey = call.argument<String>("idempotencyKey")?.trim()
        val spec = when (operation) {
            "recordConsent" -> if (validJsonObject(body) && validIdempotencyKey(idempotencyKey)) {
                ConsentRequestSpec("POST", "/v1/devices/${config.deviceId}/consents", body, idempotencyKey)
            } else null
            "readLocationSharing" -> if (body == null && idempotencyKey == null) {
                ConsentRequestSpec("GET", "/v1/devices/${config.deviceId}/location-sharing", null, null)
            } else null
            else -> null
        }
        if (spec == null) {
            result.error("invalid_device_consent_request", "The consent operation is not valid for this route.", null)
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
                // Credentials and server response text are never logged.
                runOnUiThread {
                    result.error("device_consent_unreachable", "The consent service did not answer.", null)
                }
            }
        }
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

    private data class ConsentRequestSpec(
        val method: String,
        val path: String,
        val body: String?,
        val idempotencyKey: String?,
    )

    private fun showForegroundNotification(call: MethodCall, result: MethodChannel.Result) {
        val title = call.argument<String>("title")?.trim()
        val body = call.argument<String>("body")?.trim()
        val channelId = call.argument<String>("channelId")
        val route = call.argument<String>("route")?.trim()
        val notificationId = call.argument<Number>("id")?.toInt()
            ?: (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        val allowedChannels = setOf(
            FamilyOsApplication.CHANNEL_SOS,
            FamilyOsApplication.CHANNEL_GEOFENCE,
            FamilyOsApplication.CHANNEL_PROTECTION,
            FamilyOsApplication.CHANNEL_CHAT,
        )
        if (title.isNullOrEmpty() || title.length > 160 || body.isNullOrEmpty() || body.length > 240 ||
            channelId == null || channelId !in allowedChannels || !isValidNotificationRoute(route)) {
            result.success(false)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            result.success(false)
            return
        }
        if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            result.success(false)
            return
        }

        val color = when (channelId) {
            FamilyOsApplication.CHANNEL_SOS -> ContextCompat.getColor(this, R.color.familyos_sos_notification)
            FamilyOsApplication.CHANNEL_GEOFENCE -> ContextCompat.getColor(this, R.color.familyos_geofence_notification)
            FamilyOsApplication.CHANNEL_PROTECTION -> ContextCompat.getColor(this, R.color.familyos_protection_notification)
            else -> ContextCompat.getColor(this, R.color.familyos_chat_notification)
        }
        val openApp = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_NOTIFICATION_ROUTE, route)
        }
        val contentIntent = PendingIntent.getActivity(
            this,
            notificationId,
            openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = NotificationCompat.Builder(this, channelId!!)
            .setSmallIcon(R.drawable.ic_stat_family_notification)
            .setColor(color)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setCategory(NotificationCompat.CATEGORY_EVENT)
            .setPriority(
                if (channelId == FamilyOsApplication.CHANNEL_CHAT) NotificationCompat.PRIORITY_DEFAULT
                else NotificationCompat.PRIORITY_HIGH,
            )
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
        // Match legacy FCM channel behavior on pre-O devices; Android channels own this on O+.
        when (channelId) {
            FamilyOsApplication.CHANNEL_SOS, FamilyOsApplication.CHANNEL_GEOFENCE ->
                builder.setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
            FamilyOsApplication.CHANNEL_CHAT -> builder.setDefaults(NotificationCompat.DEFAULT_SOUND)
        }
        val notification = builder.build()
        try {
            NotificationManagerCompat.from(this).notify(notificationId, notification)
            result.success(true)
        } catch (_: SecurityException) {
            result.success(false)
        } catch (_: IllegalArgumentException) {
            result.success(false)
        }
    }

    private fun isValidNotificationRoute(route: String?): Boolean {
        if (route.isNullOrEmpty() || route.length > 512) return false
        val uri = try { Uri.parse(route) } catch (_: Exception) { return false }
        if (uri.scheme != null || uri.host != null || uri.fragment != null || uri.path.isNullOrEmpty()) return false
        val keys = uri.queryParameterNames
        fun exactlyOne(key: String): Boolean = uri.getQueryParameters(key).size == 1
        return when (uri.path) {
            "/scr-fat-018" -> keys == setOf("alertId", "childId") && exactlyOne("alertId") &&
                exactlyOne("childId") && validUuid(uri.getQueryParameter("alertId")) &&
                validUuid(uri.getQueryParameter("childId"))
            "/scr-fat-014" -> keys == setOf("childId") && exactlyOne("childId") &&
                validUuid(uri.getQueryParameter("childId"))
            "/scr-fat-026" -> keys == setOf("deviceId") && exactlyOne("deviceId") &&
                validUuid(uri.getQueryParameter("deviceId"))
            else -> false
        }
    }

    private fun consumeNotificationRoute(): String? {
        val route = pendingNotificationRoute ?: intent?.getStringExtra(EXTRA_NOTIFICATION_ROUTE)?.trim()
        pendingNotificationRoute = null
        intent?.removeExtra(EXTRA_NOTIFICATION_ROUTE)
        return route?.takeIf(::isValidNotificationRoute)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = intent.getStringExtra(EXTRA_NOTIFICATION_ROUTE)?.trim()
        if (!isValidNotificationRoute(route)) return
        pendingNotificationRoute = route
        notificationMethodChannel?.invokeMethod("openRoute", route, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (pendingNotificationRoute == route) pendingNotificationRoute = null
                intent.removeExtra(EXTRA_NOTIFICATION_ROUTE)
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // Dart may not have installed its handler yet; keep the route for consumeNotificationRoute.
            }

            override fun notImplemented() {
                // Dart may not have installed its handler yet; keep the route for consumeNotificationRoute.
            }
        })
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
        val notificationRoute = intent?.getStringExtra(EXTRA_NOTIFICATION_ROUTE)?.trim()
        if (!notificationRoute.isNullOrEmpty()) {
            intent?.removeExtra(EXTRA_NOTIFICATION_ROUTE)
            return notificationRoute.takeIf(::isValidNotificationRoute) ?: super.getInitialRoute()
        }
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
        private const val NOTIFICATION_CHANNEL = "com.familyos.family_os/family_notifications"
        private const val REQUEST_FOREGROUND_LOCATION = 8101
        private const val REQUEST_BACKGROUND_LOCATION = 8102
        const val EXTRA_FLUTTER_ROUTE = "flutter_route"
        const val EXTRA_FLUTTER_AUDIT = "flutter_audit"
        private const val EXTRA_NOTIFICATION_ROUTE = "family_notification_route"
    }
}
