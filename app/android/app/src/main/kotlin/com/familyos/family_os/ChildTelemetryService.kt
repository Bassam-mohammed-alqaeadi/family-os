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
import android.net.ConnectivityManager
import android.net.Network
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.UserManager
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
import java.util.concurrent.TimeUnit
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
    private lateinit var session: LocationSessionCoordinator<TelemetryConfig>

    /** Main-thread only: when the last reading was handed to [executor] (monotonic clock). */
    private var lastReportedElapsedMillis: Long? = null

    // -- S2 resilience state. Volatiles are read across threads; queue mutations hold --
    // -- [queueLock] inside the store. Everything here degrades to "unknown", never lies. --

    private lateinit var queueStore: EncryptedFixQueueStore
    private val queueLock = Any()
    private val scheduler = Executors.newSingleThreadScheduledExecutor()

    /** Last server-time sighting from a telemetry `Date` header (null = no knowledge yet). */
    @Volatile private var timeObservation: ServerTimeOffset.Observation? = null

    /** Monotonic reading of the last acknowledged heartbeat (null = never). */
    @Volatile private var lastHeartbeatAckElapsedMillis: Long? = null

    /** Fixes the server refused during drains since the last heartbeat (surfaced, not hidden). */
    @Volatile private var drainRefusedTotal: Long = 0L

    /** Queue-loss baseline already reported to the server (the machine is stateless). */
    @Volatile private var queueLostReportedBaseline: Long = 0L

    /** Seconds between locked boot and this start (-1 = no direct-boot marker was found). */
    @Volatile private var lockedBootGapSeconds: Long = -1L

    @Volatile private var networkAvailable: Boolean = true
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun onCreate() {
        super.onCreate()
        configStore = TelemetryConfigStore(this)
        reportStatus = LocationReportStatusStore(this)
        // S2: the encrypted retry queue, owned by the coordinator (rule 4) - never a
        // parallel pipeline. noBackupFilesDir survives app updates; Keystore holds the key.
        queueStore = EncryptedFixQueueStore(
            File(noBackupFilesDir, QUEUE_FILE_NAME),
            KeystoreFixQueueCipher(),
            queueLock,
        )
        session = LocationSessionCoordinator(configStore, reportStatus, TelemetryConfigStore.LOCK, queueStore) {
            System.currentTimeMillis()
        }
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannels()
        // Measure the direct-boot gap (if any) so the next heartbeat reports it as evidence.
        try {
            val marker = ProtectionBootReceiver.takeLockedBootAt(this)
            lockedBootGapSeconds = if (marker == null) -1L else {
                ((System.currentTimeMillis() - marker) / 1000L).coerceAtLeast(0L)
            }
        } catch (_: Exception) {
            lockedBootGapSeconds = -1L
        }
        networkAvailable = readNetworkAvailable()
        registerNetworkCallback()
        try {
            scheduler.scheduleAtFixedRate(
                { heartbeatNow() },
                HEARTBEAT_INITIAL_DELAY_MINUTES,
                HEARTBEAT_PERIOD_MINUTES,
                TimeUnit.MINUTES,
            )
        } catch (_: Exception) {
            // No scheduler = no periodic heartbeat; boot/drain heartbeats still run.
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A revoked pairing never restarts collection, even if a failed delete left its
        // credential on disk; only a new pairing clears the mark.
        session.retryForgetRevoked()
        if (!session.mayStart() || !hasFineLocationPermission()) {
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
        if (intent?.getBooleanExtra(EXTRA_BOOT_START, false) == true) {
            // S2: a boot/update/unlock start that reached here is healthy - the pacing
            // counter served its purpose. Drain what the outage queued, then heartbeat.
            try {
                ProtectionBootReceiver.setBootAttempts(this, 0)
            } catch (_: Exception) {
                // Best effort; the counter only paces retries.
            }
            val bootConfig = try {
                configStore.read()
            } catch (_: Exception) {
                null
            }
            if (bootConfig != null && session.mayReport(bootConfig)) {
                try {
                    executor.execute {
                        drainQueued(bootConfig, DRAIN_LIMIT)
                        heartbeatNow()
                    }
                } catch (_: java.util.concurrent.RejectedExecutionException) {
                    // Shutting down already; the scheduler heartbeat covers it.
                }
            }
        }
        return START_STICKY
    }

    override fun onLocationChanged(location: Location) {
        if (!location.hasAccuracy()) return
        val config = configStore.read() ?: return
        if (!session.mayReport(config)) return
        val reading = LocationFixProtocol.reportable(
            LocationFixProtocol.Reading(
                fixId = UUID.randomUUID().toString(),
                latitude = location.latitude,
                longitude = location.longitude,
                accuracyMeters = location.accuracy.toDouble(),
                // S2: upper-clamped against server time (never past now + 4 min). GPS time
                // is already true UTC so no offset is *added* (that would corrupt it); the
                // clamp only protects wall-clock-backed providers from the 5-minute rule.
                recordedAtEpochMillis = correctedStamp(location.time),
                fromMockProvider = isFromMockProvider(location),
            ),
        ) ?: return
        // GPS and network each honour the interval on their own; one gate across both keeps
        // the notification's "at most once every 5 minutes" true.
        val now = SystemClock.elapsedRealtime()
        if (!LocationFixProtocol.dueForReport(lastReportedElapsedMillis, now)) return
        lastReportedElapsedMillis = now
        val battery = readBattery()
        try {
            executor.execute { report(config, reading, battery) }
        } catch (_: java.util.concurrent.RejectedExecutionException) {
            // The service is shutting down; this reading is not sent.
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
        try {
            networkCallback?.let {
                (getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager)
                    ?.unregisterNetworkCallback(it)
            }
        } catch (_: Exception) {
            // Best effort; the process is going away.
        }
        networkCallback = null
        try {
            scheduler.shutdownNow()
        } catch (_: Exception) {
            // Best effort.
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

    /**
     * Runs on [executor]: one fix, then - only if that fix was accepted and is not a mock
     * reading - one heartbeat.
     */
    private fun report(config: TelemetryConfig, reading: LocationFixProtocol.Reading, battery: BatteryReading?) {
        // A callback queued before a revocation (or a re-pairing) must not speak with a
        // credential that is no longer the stored one.
        if (!session.mayReport(config)) return
        val fixAnswer = post(
            config,
            LocationFixProtocol.path(config.deviceId),
            LocationFixProtocol.body(reading),
            LocationFixProtocol.idempotencyKey(reading.fixId),
        )
        val fixOutcome = LocationFixProtocol.classify(fixAnswer.statusCode, fixAnswer.errorBody)
        learnDateHeader(fixAnswer.dateHeaderMillis)
        // S2: no answer / "try later" queues the exact bytes for an ordered replay instead
        // of dropping the reading. A refusal settles here and is never queued.
        if (queueWorthy(fixOutcome)) {
            val now = System.currentTimeMillis()
            session.offerToQueue(
                config,
                QueuedFix(
                    fixId = reading.fixId,
                    recordedAtEpochMillis = reading.recordedAtEpochMillis,
                    enqueuedAtEpochMillis = now,
                    attempts = 0,
                    payloadJson = LocationFixProtocol.body(reading),
                ),
                fixOutcome,
                now,
            )
        }
        if (!settle(config, fixOutcome)) return
        if (!LocationFixProtocol.legacyHeartbeatAllowed(fixOutcome, reading) || battery == null) return
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
        val heartbeatOutcome = LocationFixProtocol.classify(heartbeat.statusCode, heartbeat.errorBody)
        learnDateHeader(heartbeat.dateHeaderMillis)
        if (heartbeatOutcome.endsSession) settle(config, heartbeatOutcome)
        // S2: a healthy round-trip is the cheapest moment to replay what queued earlier.
        if (fixOutcome == LocationReportOutcome.ACCEPTED) drainQueued(config, DRAIN_PIGGYBACK_LIMIT)
    }

    /**
     * Hands one answer to [session] (see [LocationSessionCoordinator] for the rules and their
     * tests) and acts on its decision. Returns true if the caller may continue.
     */
    private fun settle(usedConfig: TelemetryConfig, outcome: LocationReportOutcome): Boolean =
        when (session.settle(usedConfig, outcome).decision) {
            SettleDecision.CONTINUE -> true
            SettleDecision.IGNORE -> false
            SettleDecision.STOP_SESSION -> {
                stopRevokedSession()
                false
            }
        }

    /**
     * The server said this credential is dead: stop collecting and tell the person holding
     * the phone, because sharing stopping is as visible as sharing starting. This happens
     * even if forgetting the credential failed (fail-closed); it is skipped only if a new
     * pairing was stored in between, which clears the revocation mark.
     */
    private fun stopRevokedSession() {
        Handler(Looper.getMainLooper()).post {
            if (!session.revocationStillStands()) return@post
            try {
                locationManager.removeUpdates(this)
            } catch (_: SecurityException) {
                // Already stopping.
            }
            isRunning = false
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
            // S2: the server's Date header is the only clock trusted for skew tolerance.
            val dateHeader = try {
                connection.getHeaderFieldDate("Date", 0L).takeIf { it > 0L }
            } catch (_: Exception) {
                null
            }
            HttpAnswer(code, errorBody, dateHeader)
        } catch (_: Exception) {
            // No HTTP answer. The next genuine location callback is the retry; nothing
            // cached or fabricated is transmitted in its place.
            HttpAnswer(null, null, null)
        } finally {
            connection?.disconnect()
        }
    }

    private fun readBounded(stream: java.io.InputStream?): String? {
        if (stream == null) return null
        return stream.bufferedReader(Charsets.UTF_8).use { reader ->
            // read() may return a short count; keep reading until the bound or the end.
            val buffer = CharArray(LocationFixProtocol.MAX_ERROR_BODY_CHARS)
            var total = 0
            while (total < buffer.size) {
                val read = reader.read(buffer, total, buffer.size - total)
                if (read < 0) break
                total += read
            }
            if (total == 0) null else String(buffer, 0, total)
        }
    }

    // -- S2 resilience: queue replay, skew-tolerant stamps, heartbeat, honest state. --
    // All entry points catch everything: resilience code must never crash the service.

    /** Upper-clamps a stamp against the best-known server time; the past passes through. */
    private fun correctedStamp(candidateMillis: Long): Long {
        return try {
            val serverNow = ServerTimeOffset.correctedNow(
                timeObservation,
                System.currentTimeMillis(),
                SystemClock.elapsedRealtime(),
            )
            ServerTimeOffset.clampRecordedAt(candidateMillis, serverNow)
        } catch (_: Exception) {
            candidateMillis // Correction must never break reporting; the server judges.
        }
    }

    private fun learnDateHeader(dateHeaderMillis: Long?) {
        try {
            ServerTimeOffset.observe(dateHeaderMillis, SystemClock.elapsedRealtime())?.let {
                timeObservation = it
            }
        } catch (_: Exception) {
            // A clock we cannot read is knowledge we do not have.
        }
    }

    /**
     * Replays queued fixes oldest-first, at most [limit]. Stops at the first answer that
     * says "not now" (the rest stay queued, still ordered); removes what the server
     * settled. Runs on [executor] - never on the main thread. Sequential by design: the
     * natural round-trip pacing stays far under the 120/minute device limit.
     */
    private fun drainQueued(config: TelemetryConfig, limit: Int) {
        val due = try {
            session.drainQueue(config, limit, System.currentTimeMillis())
        } catch (_: Exception) {
            return
        }
        for (queued in due) {
            if (!session.mayReport(config)) return
            val answer = post(
                config,
                LocationFixProtocol.path(config.deviceId),
                queued.payloadJson,
                LocationFixProtocol.idempotencyKey(queued.fixId),
            )
            learnDateHeader(answer.dateHeaderMillis)
            when (LocationFixProtocol.classify(answer.statusCode, answer.errorBody)) {
                LocationReportOutcome.ACCEPTED -> confirmOne(config, queued.fixId)
                LocationReportOutcome.REJECTED, LocationReportOutcome.ACCESS_REFUSED -> {
                    // Settled against us: remove so it is never retried, but count the loss.
                    drainRefusedTotal++
                    confirmOne(config, queued.fixId)
                }
                LocationReportOutcome.CREDENTIAL_REVOKED -> {
                    settle(config, LocationReportOutcome.CREDENTIAL_REVOKED)
                    return
                }
                LocationReportOutcome.NETWORK_UNREACHABLE, LocationReportOutcome.SERVER_UNAVAILABLE -> return
            }
        }
    }

    private fun confirmOne(config: TelemetryConfig, fixId: String) {
        try {
            session.confirmDrained(config, setOf(fixId))
        } catch (_: Exception) {
            // Unconfirmed but accepted: the idempotency key makes a re-send a no-op row.
        }
    }

    /**
     * The S2 heartbeat (D11): evaluates the protection verdict where the facts live,
     * refreshes the ongoing notification to say exactly that, and reports the snapshot
     * to the capability ledger. Service-owned by design - while the service runs, the
     * verdict is fresh; when it dies, the server-side staleness tells the truth (D8).
     */
    private fun heartbeatNow() {
        try {
            val config = try {
                configStore.read()
            } catch (_: Exception) {
                null
            } ?: return
            if (!session.mayReport(config)) return
            val state = evaluateProtection()
            lastProtectionState = state
            refreshProtectionNotification(state)
            if (reportProtectionSnapshot(config, state)) {
                lastHeartbeatAckElapsedMillis = SystemClock.elapsedRealtime()
                queueLostReportedBaseline = queueLossTotal()
                lockedBootGapSeconds = -1L // Reported once; a new boot writes a new marker.
            }
        } catch (_: Exception) {
            // Heartbeat failure is itself a signal (staleness), never a crash.
        }
    }

    private fun evaluateProtection(): ProtectionState {
        val stats = try {
            queueStore.stats(System.currentTimeMillis())
        } catch (_: Exception) {
            null
        }
        val lastAck = lastHeartbeatAckElapsedMillis
        val stale = lastAck != null &&
            SystemClock.elapsedRealtime() - lastAck > HEARTBEAT_STALE_MILLIS
        return ProtectionStateMachine.evaluate(
            ProtectionSignals(
                unlocked = isUserUnlocked(),
                // Evaluated by the running service itself: if this code runs, it runs.
                serviceRunning = true,
                backgroundLocationGranted = hasBackgroundLocationPermission(),
                notificationsGranted = hasNotificationsPermission(),
                batteryUnrestricted = isBatteryUnrestricted(),
                networkAvailable = networkAvailable,
                queueDepth = stats?.depth ?: 0,
                queueLostSinceReported = (queueLossTotal() - queueLostReportedBaseline).coerceAtLeast(0L),
                heartbeatStale = stale,
            ),
        )
    }

    /** Every loss the queue counted, plus refused drains: the number the family may audit. */
    private fun queueLossTotal(): Long {
        return try {
            val stats = queueStore.stats(System.currentTimeMillis())
            stats.evictedTotal + stats.expiredTotal + stats.corruptTotal +
                queueStore.loadFailures + drainRefusedTotal
        } catch (_: Exception) {
            drainRefusedTotal
        }
    }

    /**
     * Reports under the existing S0 keys (no new endpoints, no new keys): the ledger
     * upsert already tolerates heartbeat duplicates. Returns true on a 2xx answer.
     */
    private fun reportProtectionSnapshot(config: TelemetryConfig, state: ProtectionState): Boolean {
        val now = System.currentTimeMillis()
        val stats = try {
            queueStore.stats(now)
        } catch (_: Exception) {
            null
        }
        val body = buildString {
            append("{\"capabilities\":[")
            // Reporting at all proves the boot path re-armed: this entry says so.
            appendCapability(this, "boot_persistence", "confirmed", now, heartbeatEvidence(stats?.depth ?: 0, state.wire))
            append(',')
            val locationState = if (hasBackgroundLocationPermission()) "confirmed" else "permission_needed"
            appendCapability(this, "background_location", locationState, now, null)
            append(',')
            appendCapability(this, "battery_reporting", "confirmed", now, batteryEvidence())
            append("]}")
        }
        val answer = post(
            config,
            "/v1/devices/${config.deviceId}/capabilities",
            body,
            "protection-hb-" + UUID.randomUUID().toString(),
        )
        learnDateHeader(answer.dateHeaderMillis)
        val outcome = LocationFixProtocol.classify(answer.statusCode, answer.errorBody)
        if (outcome == LocationReportOutcome.CREDENTIAL_REVOKED) {
            settle(config, outcome)
            return false
        }
        return outcome == LocationReportOutcome.ACCEPTED
    }

    private fun appendCapability(
        out: StringBuilder,
        key: String,
        state: String,
        nowMillis: Long,
        evidence: String?,
    ) {
        out.append("{\"capabilityKey\":\"").append(key).append("\",")
        out.append("\"state\":\"").append(state).append('"')
        if (state == "confirmed") {
            // Explicit pairing (the server would default it, but the stamp is ours to state).
            out.append(",\"confirmedAt\":\"").append(LocationFixProtocol.isoInstant(nowMillis)).append('"')
        }
        if (evidence != null) out.append(",\"evidence\":\"").append(evidence).append('"')
        out.append('}')
    }

    /**
     * Compact heartbeat facts, controlled alphabet only (`[a-z0-9=+.,;_-]`), far under the
     * 512-char evidence bound: `v` schema, `oem` vendor, `ex` battery exemption (0/1),
     * `q` queue depth, `lost` cumulative queue loss, `ref` cumulative drain refusals,
     * `off` server-offset seconds (`?` = unknown), `gap` locked-boot gap seconds (-1 = none),
     * `st` the verdict wire (`fully_protected` / `degraded` / `stopped`).
     */
    private fun heartbeatEvidence(queueDepth: Int, stateWire: String): String {
        val oem = try {
            BatteryOemMap.guidance(Build.MANUFACTURER).vendorWire
        } catch (_: Exception) {
            "stock"
        }
        val exempt = if (isBatteryUnrestricted()) "1" else "0"
        val offsetSeconds = try {
            val wall = System.currentTimeMillis()
            val corrected = ServerTimeOffset.correctedNow(
                timeObservation,
                wall,
                SystemClock.elapsedRealtime(),
            )
            if (timeObservation == null) "?" else ((corrected - wall) / 1000L).toString()
        } catch (_: Exception) {
            "?"
        }
        return "v=1;oem=$oem;ex=$exempt;q=$queueDepth;lost=${queueLossTotal()};" +
            "ref=$drainRefusedTotal;off=$offsetSeconds;gap=$lockedBootGapSeconds;st=$stateWire"
    }

    private fun batteryEvidence(): String {
        val oem = try {
            BatteryOemMap.guidance(Build.MANUFACTURER).vendorWire
        } catch (_: Exception) {
            "stock"
        }
        return "oem=$oem;ex=" + if (isBatteryUnrestricted()) "1" else "0"
    }

    /** The ongoing notification always says the current verdict - or the permission gap. */
    private fun refreshProtectionNotification(state: ProtectionState) {
        try {
            val text = when (state) {
                is ProtectionState.FullyProtected ->
                    getString(R.string.location_sharing_notification_text)
                is ProtectionState.Degraded ->
                    getString(
                        R.string.protection_notification_degraded_text,
                        state.reasons.joinToString(", ") { it.wire },
                    )
                is ProtectionState.Stopped ->
                    getString(
                        R.string.protection_notification_stopped_text,
                        state.reason.wire,
                    )
            }
            NotificationManagerCompat.from(this).notify(NOTIFICATION_ID, buildOngoingNotification(text))
        } catch (_: Exception) {
            // POST_NOTIFICATIONS withdrawn mid-flight: the in-app status still says it.
        }
    }

    private fun buildOngoingNotification(text: String): Notification {
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

    private fun hasBackgroundLocationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return hasFineLocationPermission()
        return ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun hasNotificationsPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun isBatteryUnrestricted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return try {
            val power = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return false
            power.isIgnoringBatteryOptimizations(packageName)
        } catch (_: Exception) {
            false // Unreadable = restricted (fail closed: doubt is never healthy).
        }
    }

    private fun isUserUnlocked(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return true
        return try {
            val users = getSystemService(Context.USER_SERVICE) as? UserManager ?: return false
            users.isUserUnlocked
        } catch (_: Exception) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun readNetworkAvailable(): Boolean {
        return try {
            val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return false
            connectivity.activeNetworkInfo?.isConnected == true
        } catch (_: Exception) {
            false
        }
    }

    private fun registerNetworkCallback() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        try {
            val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return
            val callback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    networkAvailable = true
                    try {
                        executor.execute {
                            val config = try {
                                configStore.read()
                            } catch (_: Exception) {
                                null
                            }
                            if (config != null && session.mayReport(config)) {
                                drainQueued(config, DRAIN_LIMIT)
                                heartbeatNow()
                            }
                        }
                    } catch (_: java.util.concurrent.RejectedExecutionException) {
                        // Shutting down; the scheduler heartbeat covers it.
                    }
                }

                override fun onLost(network: Network) {
                    networkAvailable = false
                }
            }
            networkCallback = callback
            connectivity.registerDefaultNetworkCallback(callback)
        } catch (_: Exception) {
            networkCallback = null
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

    private fun foregroundNotification(): Notification =
        buildOngoingNotification(getString(R.string.location_sharing_notification_text))

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
    private data class HttpAnswer(val statusCode: Int?, val errorBody: String?, val dateHeaderMillis: Long?)

    companion object {
        const val CHANNEL_ID = "child_telemetry"
        const val STOPPED_CHANNEL_ID = "child_location_sharing_stopped"
        const val NOTIFICATION_ID = 91201
        const val STOPPED_NOTIFICATION_ID = 91202
        @Volatile var isRunning: Boolean = false

        /** Set by [ProtectionBootReceiver] on boot/update/unlock starts. */
        const val EXTRA_BOOT_START = "com.familyos.family_os.extra.BOOT_START"

        /** Last heartbeat verdict, for the Flutter mirror and the stopped screen. */
        @Volatile var lastProtectionState: ProtectionState? = null

        private const val UPDATE_INTERVAL_MILLIS = 5 * 60 * 1000L
        private const val UPDATE_DISTANCE_METERS = 50f
        private const val CONNECT_TIMEOUT_MILLIS = 15_000
        private const val READ_TIMEOUT_MILLIS = 15_000

        // S2 resilience tuning. Drains stay far under the 120/minute device limit by
        // staying small and sequential; the heartbeat is the freshness claim (D8).
        private const val QUEUE_FILE_NAME = "fix-queue.v1"
        private const val HEARTBEAT_INITIAL_DELAY_MINUTES = 1L
        private const val HEARTBEAT_PERIOD_MINUTES = 15L
        private const val HEARTBEAT_STALE_MILLIS = 30L * 60 * 1000
        private const val DRAIN_LIMIT = 20
        private const val DRAIN_PIGGYBACK_LIMIT = 5
    }
}

/**
 * What the handset last heard back, for the child's "what I share" screen and the pairing
 * screen. Outcome names and times only - never a coordinate, identifier or server message.
 */
class LocationReportStatusStore(context: Context) : ReportStatusSink {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    override fun record(outcome: LocationReportOutcome, atEpochMillis: Long) {
        val editor = preferences.edit()
            .putString(KEY_LAST_OUTCOME, outcome.wire)
            .putLong(KEY_LAST_OUTCOME_AT, atEpochMillis)
        if (outcome == LocationReportOutcome.ACCEPTED) editor.putLong(KEY_LAST_ACCEPTED_AT, atEpochMillis)
        editor.apply()
    }

    override fun markCredentialRevoked(atEpochMillis: Long) {
        preferences.edit().putLong(KEY_REVOKED_AT, atEpochMillis).apply()
    }

    override fun credentialRevoked(): Boolean = preferences.getLong(KEY_REVOKED_AT, 0L) > 0L

    /** A new pairing starts a new story; the previous one's outcome must not leak into it. */
    fun resetForNewPairing() {
        preferences.edit().clear().apply()
    }

    fun snapshot(): Map<String, Any> = mapOf(
        "lastReportOutcome" to (preferences.getString(KEY_LAST_OUTCOME, null) ?: "none"),
        "lastReportAtMillis" to preferences.getLong(KEY_LAST_OUTCOME_AT, 0L),
        "lastAcceptedAtMillis" to preferences.getLong(KEY_LAST_ACCEPTED_AT, 0L),
        "credentialRevoked" to credentialRevoked(),
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
class TelemetryConfigStore(private val context: Context) : PairingSessionStore<TelemetryConfig> {
    fun write(config: TelemetryConfig) = locked {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val payload = "${config.apiOrigin}\n${config.deviceId}\n${config.deviceCredential}".toByteArray(Charsets.UTF_8)
        val encrypted = cipher.doFinal(payload)
        val bytes = ByteBuffer.allocate(4 + cipher.iv.size + encrypted.size)
            .putInt(cipher.iv.size)
            .put(cipher.iv)
            .put(encrypted)
            .array()
        // Write a sibling file and rename it over the old one: a reader (or a crash) sees the
        // old pairing or the new one, never a half-written file.
        val target = file()
        val staging = File(target.parentFile, target.name + ".tmp")
        staging.writeBytes(bytes)
        if (!staging.renameTo(target)) {
            staging.delete()
            throw java.io.IOException("pairing could not be stored")
        }
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
    override fun forgetIfCurrent(expected: TelemetryConfig): ForgetResult = locked {
        val current = read()
        if (current != null && current != expected) return@locked ForgetResult.SUPERSEDED
        val target = file()
        if (target.delete() || !target.exists()) ForgetResult.FORGOTTEN else ForgetResult.FAILED
    }

    override fun current(): TelemetryConfig? = read()

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

        /**
         * One lock for the whole process, not per instance: the pairing screen and the
         * service each create their own store, and a per-instance lock would let a new
         * pairing be written between a revocation's check and its delete.
         */
        val LOCK = Any()

        fun <T> locked(block: () -> T): T = synchronized(LOCK, block)
    }
}
