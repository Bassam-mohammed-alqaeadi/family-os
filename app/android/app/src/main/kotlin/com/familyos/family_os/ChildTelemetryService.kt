package com.familyos.family_os

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Base64
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.security.KeyStore
import java.util.Locale
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
 */
class ChildTelemetryService : Service(), LocationListener {
    private val executor = Executors.newSingleThreadExecutor()
    private lateinit var locationManager: LocationManager
    private lateinit var configStore: TelemetryConfigStore

    override fun onCreate() {
        super.onCreate()
        configStore = TelemetryConfigStore(this)
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannel()
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
        if (!location.hasAccuracy() || location.accuracy > MAX_LOCATION_ACCURACY_METERS) return
        val config = configStore.read() ?: return
        val battery = readBattery() ?: return
        val locationLabel = String.format(
            Locale.US,
            "GPS %.5f, %.5f",
            location.latitude,
            location.longitude,
        )
        executor.execute {
            sendTelemetry(config, battery, location.latitude, location.longitude, locationLabel)
        }
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

    private fun sendTelemetry(
        config: TelemetryConfig,
        battery: BatteryReading,
        latitude: Double,
        longitude: Double,
        locationLabel: String,
    ) {
        var connection: HttpURLConnection? = null
        try {
            connection = URL("${config.apiOrigin}/v1/devices/${config.deviceId}/telemetry")
                .openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = CONNECT_TIMEOUT_MILLIS
            connection.readTimeout = READ_TIMEOUT_MILLIS
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("Authorization", "Device ${config.deviceCredential}")
            val body = """{"batteryLevel":${battery.level},"batteryStatus":"${battery.status}","locationLat":$latitude,"locationLng":$longitude,"locationLabel":"$locationLabel"}"""
            connection.outputStream.bufferedWriter(Charsets.UTF_8).use { it.write(body) }
            // Consume the response to release the connection. Coordinates and
            // credential are intentionally never logged.
            connection.inputStream?.close()
        } catch (_: Exception) {
            // Connectivity failures are retried by the next genuine location
            // callback. No fabricated cached observation is transmitted.
        } finally {
            connection?.disconnect()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Child location telemetry",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows when Child Mode is collecting real device telemetry."
            },
        )
    }

    private fun foregroundNotification(): Notification = NotificationCompat.Builder(this, CHANNEL_ID)
        .setSmallIcon(com.familyos.family_os.R.mipmap.ic_launcher)
        .setContentTitle("Child Mode active")
        .setContentText("Sharing real battery and location telemetry with the linked family.")
        .setOngoing(true)
        .build()

    private data class BatteryReading(val level: Int, val status: String)

    companion object {
        const val CHANNEL_ID = "child_telemetry"
        const val NOTIFICATION_ID = 91201
        @Volatile var isRunning: Boolean = false
        private const val UPDATE_INTERVAL_MILLIS = 5 * 60 * 1000L
        private const val UPDATE_DISTANCE_METERS = 50f
        private const val MAX_LOCATION_ACCURACY_METERS = 200f
        private const val CONNECT_TIMEOUT_MILLIS = 15_000
        private const val READ_TIMEOUT_MILLIS = 15_000
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
            if (ivLength !in 12..32 || buffer.remaining() <= ivLength) return null
            val iv = ByteArray(ivLength)
            buffer.get(iv)
            val encrypted = ByteArray(buffer.remaining())
            buffer.get(encrypted)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv))
            val pieces = String(cipher.doFinal(encrypted), Charsets.UTF_8).split('\n')
            if (pieces.size != 3 || pieces.any { it.isBlank() }) null
            else TelemetryConfig(pieces[0], pieces[1], pieces[2])
        } catch (_: Exception) {
            null
        }
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
