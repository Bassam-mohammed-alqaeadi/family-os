package com.familyos.family_os

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Base64
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.security.KeyStore
import java.util.Locale
import java.util.UUID
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties

/**
 * Real Android foreground service for an already-paired child device.
 *
 * It reads Android battery state and LocationManager data only after the OS has
 * granted location permission. It contains no synthetic coordinates, battery
 * values, guardian bearer tokens, or developer simulation path.
 *
 * Each genuine location callback becomes one fix on the W3 route
 * (`POST /v1/devices/{id}/location-fixes`) - the table the family's live picture and
 * history are read from - followed by the battery heartbeat on the legacy telemetry
 * route that the W2 device card still reads. The wire contract and the reading of the
 * server's answer live in [LocationFixProtocol].
 *
 * The collection rule itself is unchanged by this file: the same providers, interval,
 * distance and accuracy ceiling as before, and only while fine + background permission
 * are granted. The ongoing notification says, in the phone's language, what is shared
 * and with whom.
 */
class ChildTelemetryService : Service(), LocationListener {
    private val executor = Executors.newSingleThreadExecutor()
    private lateinit var locationManager: LocationManager
    private lateinit var configStore: TelemetryConfigStore
    private lateinit var reportStatus: LocationReportStatusStore

    override fun onCreate() {
        super.onCreate()
        configStore = TelemetryConfigStore(this)
        reportStatus = LocationReportStatusStore(this)
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val config = configStore.read()
        if (config == null || !hasFineLocationPermission()) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        startForeground(NOTIFICATION_ID, foregroundNotification())
        isRunning = true
        try {
            locationManager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                UPDATE_INTERVAL_MILLIS,
                UPDATE_DISTANCE_METERS,
                this,
                Looper.getMainLooper(),
            )
            locationManager.requestLocationUpdates(
                LocationManager.NETWORK_PROVIDER,
                UPDATE_INTERVAL_MILLIS,
                UPDATE_DISTANCE_METERS,
                this,
                Looper.getMainLooper(),
            )
        } catch (_: SecurityException) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onLocationChanged(location: Location) {
        if (!location.hasAccuracy()) return
        val config = configStore.read() ?: return
        val reading = LocationFixProtocol.reportable(
            LocationFixProtocol.Reading(
                fixId = UUID.randomUUID().toString(),
                latitude = location.latitude,
                longitude = location.longitude,
                accuracyMeters = location.accuracy.toDouble(),
                recordedAtEpochMillis = location.time,
                fromMockProvider = isFromMockProvider(location),
            ),
        ) ?: return
        val battery = readBattery()
        executor.execute { report(config, reading, battery) }
    }

    override fun onProviderDisabled(provider: String) = Unit
    override fun onProviderEnabled(provider: String) = Unit
    @Deprecated("Deprecated in Android 29")
    override fun onStatusChanged(provider: String?, status: Int, extras: android.os.Bundle?) = Unit

    override fun onDestroy() {
        isRunning = false
        try {
            locationManager.removeUpdates(this)
        } catch (_: SecurityException) {
            // Permission can be revoked while the service is stopping.
        }
        executor.shutdownNow()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun hasFineLocationPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED

    @Suppress("DEPRECATION")
    private fun isFromMockProvider(location: Location): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) location.isMock else location.isFromMockProvider

    private fun readBattery(): BatteryReading? {
        // BATTERY_STATS is a signature-only Android permission and cannot be
        // requested by a normal Play-distributed app. ACTION_BATTERY_CHANGED is
        // the supported public API for actual level and charging state.
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return null
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        if (level < 0 || scale <= 0) return null
        val percentage = ((level * 100f) / scale).toInt().coerceIn(0, 100)
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
        return BatteryReading(percentage, if (charging) "charging" else "unplugged")
    }

    /** Runs on [executor]: one fix, then - unless the session ended - one heartbeat. */
    private fun report(config: TelemetryConfig, reading: LocationFixProtocol.Reading, battery: BatteryReading?) {
        // A callback queued before a revocation (or a re-pairing) must not speak with a
        // credential that is no longer the stored one.
        if (configStore.read() != config) return
        val fixAnswer = post(
            config,
            LocationFixProtocol.path(config.deviceId),
            LocationFixProtocol.body(reading),
            LocationFixProtocol.idempotencyKey(reading.fixId),
        )
        val fixOutcome = LocationFixProtocol.classify(fixAnswer.statusCode, fixAnswer.errorBody)
        reportStatus.record(fixOutcome, System.currentTimeMillis())
        if (fixOutcome.endsSession) {
            endRevokedSession(config)
            return
        }
        if (battery == null) return
        // The W2 device card and children list still read battery, last-seen and this label
        // from the legacy route, so its body is unchanged. It is sent from the same genuine
        // reading, never on its own schedule. Narrowing what this route stores is a later,
        // separate change (see the task card).
        val locationLabel = String.format(
            Locale.US,
            "GPS %.5f, %.5f",
            reading.latitude,
            reading.longitude,
        )
        val heartbeat = post(
            config,
            "/v1/devices/${config.deviceId}/telemetry",
            """{"batteryLevel":${battery.level},"batteryStatus":"${battery.status}","locationLat":${reading.latitude},"locationLng":${reading.longitude},"locationLabel":"$locationLabel"}""",
            null,
        )
        if (LocationFixProtocol.classify(heartbeat.statusCode, heartbeat.errorBody).endsSession) {
            reportStatus.record(LocationReportOutcome.CREDENTIAL_REVOKED, System.currentTimeMillis())
            endRevokedSession(config)
        }
    }

    /**
     * The server said this credential is dead. Forget it - only if it is still the one that
     * was used, so a re-pairing that happened meanwhile is never undone - stop collecting,
     * and tell the person holding the phone, because sharing stopping is as visible as
     * sharing starting.
     */
    private fun endRevokedSession(usedConfig: TelemetryConfig) {
        configStore.clearIfCurrent(usedConfig)
        reportStatus.markCredentialRevoked(System.currentTimeMillis())
        Handler(Looper.getMainLooper()).post {
            try {
                locationManager.removeUpdates(this)
            } catch (_: SecurityException) {
                // Already stopping.
            }
            postSharingStoppedNotification()
            stopForegroundCompat()
            stopSelf()
        }
    }

    private fun post(config: TelemetryConfig, path: String, body: String, idempotencyKey: String?): HttpAnswer {
        var connection: HttpURLConnection? = null
        return try {
            connection = URL("${config.apiOrigin}$path").openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = CONNECT_TIMEOUT_MILLIS
            connection.readTimeout = READ_TIMEOUT_MILLIS
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("Authorization", "Device ${config.deviceCredential}")
            if (idempotencyKey != null) connection.setRequestProperty("Idempotency-Key", idempotencyKey)
            connection.outputStream.bufferedWriter(Charsets.UTF_8).use { it.write(body) }
            val code = connection.responseCode
            // Only an error envelope is read, and only its first few KB, to learn the error
            // code. Coordinates, credential and response text are never logged.
            val errorBody = if (code >= 400) readBounded(connection.errorStream) else {
                connection.inputStream?.close()
                null
            }
            HttpAnswer(code, errorBody)
        } catch (_: Exception) {
            // No HTTP answer. The next genuine location callback is the retry; nothing
            // cached or fabricated is transmitted in its place.
            HttpAnswer(null, null)
        } finally {
            connection?.disconnect()
        }
    }

    private fun readBounded(stream: java.io.InputStream?): String? {
        if (stream == null) return null
        return stream.bufferedReader(Charsets.UTF_8).use { reader ->
            val buffer = CharArray(LocationFixProtocol.MAX_ERROR_BODY_CHARS)
            val read = reader.read(buffer)
            if (read <= 0) null else String(buffer, 0, read)
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.location_sharing_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = getString(R.string.location_sharing_channel_description)
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(
                STOPPED_CHANNEL_ID,
                getString(R.string.location_sharing_stopped_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
    }

    private fun openAppIntent(): PendingIntent? {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        return PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun foregroundNotification(): Notification {
        val text = getString(R.string.location_sharing_notification_text)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(com.familyos.family_os.R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.location_sharing_notification_title))
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setContentIntent(openAppIntent())
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun postSharingStoppedNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) !=
            android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val text = getString(R.string.location_sharing_stopped_text)
        val notification = NotificationCompat.Builder(this, STOPPED_CHANNEL_ID)
            .setSmallIcon(com.familyos.family_os.R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.location_sharing_stopped_title))
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setContentIntent(openAppIntent())
            .setAutoCancel(true)
            .build()
        try {
            NotificationManagerCompat.from(this).notify(STOPPED_NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Notification permission withdrawn in the meantime; the in-app status still says it.
        }
    }

    @Suppress("DEPRECATION")
    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
    }

    private data class BatteryReading(val level: Int, val status: String)
    private data class HttpAnswer(val statusCode: Int?, val errorBody: String?)

    companion object {
        const val CHANNEL_ID = "child_telemetry"
        const val STOPPED_CHANNEL_ID = "child_location_sharing_stopped"
        const val NOTIFICATION_ID = 91201
        const val STOPPED_NOTIFICATION_ID = 91202
        @Volatile var isRunning: Boolean = false
        private const val UPDATE_INTERVAL_MILLIS = 5 * 60 * 1000L
        private const val UPDATE_DISTANCE_METERS = 50f
        private const val CONNECT_TIMEOUT_MILLIS = 15_000
        private const val READ_TIMEOUT_MILLIS = 15_000
    }
}

/**
 * What the handset last heard back, for the child's "what I share" screen and the pairing
 * screen. Outcome names and times only - never a coordinate, identifier or server message.
 */
class LocationReportStatusStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun record(outcome: LocationReportOutcome, atEpochMillis: Long) {
        val editor = preferences.edit()
            .putString(KEY_LAST_OUTCOME, outcome.wire)
            .putLong(KEY_LAST_OUTCOME_AT, atEpochMillis)
        if (outcome == LocationReportOutcome.ACCEPTED) editor.putLong(KEY_LAST_ACCEPTED_AT, atEpochMillis)
        editor.apply()
    }

    fun markCredentialRevoked(atEpochMillis: Long) {
        preferences.edit().putLong(KEY_REVOKED_AT, atEpochMillis).apply()
    }

    /** A new pairing starts a new story; the previous one's outcome must not leak into it. */
    fun resetForNewPairing() {
        preferences.edit().clear().apply()
    }

    fun snapshot(): Map<String, Any> = mapOf(
        "lastReportOutcome" to (preferences.getString(KEY_LAST_OUTCOME, null) ?: "none"),
        "lastReportAtMillis" to preferences.getLong(KEY_LAST_OUTCOME_AT, 0L),
        "lastAcceptedAtMillis" to preferences.getLong(KEY_LAST_ACCEPTED_AT, 0L),
        "credentialRevoked" to (preferences.getLong(KEY_REVOKED_AT, 0L) > 0L),
    )

    companion object {
        private const val PREFERENCES = "family_os_location_report_status"
        private const val KEY_LAST_OUTCOME = "last_outcome"
        private const val KEY_LAST_OUTCOME_AT = "last_outcome_at"
        private const val KEY_LAST_ACCEPTED_AT = "last_accepted_at"
        private const val KEY_REVOKED_AT = "credential_revoked_at"
    }
}

data class TelemetryConfig(
    val apiOrigin: String,
    val deviceId: String,
    val deviceCredential: String,
)

/** Small encrypted-file store backed by a non-exportable Android Keystore key. */
class TelemetryConfigStore(private val context: Context) {
    fun write(config: TelemetryConfig) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val payload = "${config.apiOrigin}\n${config.deviceId}\n${config.deviceCredential}".toByteArray(Charsets.UTF_8)
        val encrypted = cipher.doFinal(payload)
        val bytes = ByteBuffer.allocate(4 + cipher.iv.size + encrypted.size)
            .putInt(cipher.iv.size)
            .put(cipher.iv)
            .put(encrypted)
            .array()
        file().writeBytes(bytes)
    }

    fun read(): TelemetryConfig? {
        return try {
            val bytes = file().readBytes()
            val buffer = ByteBuffer.wrap(bytes)
            val ivLength = buffer.int
            if (ivLength !in 12..32 || buffer.remaining() <= ivLength) null
            else {
                val iv = ByteArray(ivLength)
                buffer.get(iv)
                val encrypted = ByteArray(buffer.remaining())
                buffer.get(encrypted)
                val cipher = Cipher.getInstance(TRANSFORMATION)
                cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv))
                val pieces = String(cipher.doFinal(encrypted), Charsets.UTF_8).split('\n')
                if (pieces.size != 3 || pieces.any { it.isBlank() }) null
                else TelemetryConfig(pieces[0], pieces[1], pieces[2])
            }
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Forgets the stored pairing, but only if it is still [expected]. Used when the server
     * definitively refuses the credential; a pairing written after that request started is
     * a new session and is left alone.
     */
    @Synchronized
    fun clearIfCurrent(expected: TelemetryConfig): Boolean {
        val current = read() ?: return false
        if (current != expected) return false
        return file().delete()
    }

    private fun file(): File = File(context.noBackupFilesDir, "child-telemetry.v1")

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = store.getKey(KEY_ALIAS, null) as? SecretKey
        if (existing != null) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    companion object {
        private const val KEY_ALIAS = "family_os_child_telemetry_v1"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
    }
}
