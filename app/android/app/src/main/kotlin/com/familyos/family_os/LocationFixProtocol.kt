package com.familyos.family_os

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * The wire contract between the child's handset and `POST /v1/devices/{id}/location-fixes`.
 *
 * Deliberately free of Android imports so the exact bytes the handset sends, and the exact
 * way it reads the server's answer, are proven by plain JVM tests
 * (`app/android/app/src/test/.../LocationFixProtocolTest.kt`) against the same fixture the
 * backend validates (`backend/test/fixtures/native-location-fix.wire.json`).
 *
 * Two rules live here because getting either wrong is expensive for a family:
 *
 *  1. Nothing is invented. A reading without a stated accuracy, with a non-finite or
 *     out-of-range coordinate, or with no timestamp is not sent at all - the server would
 *     show a family a certainty nobody measured. A reading from a mock provider (developer
 *     options) is sent with `integritySoftWarning: true`, so a test position is never
 *     presented as a real one.
 *  2. Only one answer ends the device's session: HTTP 401 whose error code is
 *     `invalid_device_credential`, which the server returns exactly when the credential is
 *     revoked or does not match the device. Every other refusal - a generic 401 or 403, a
 *     404, a proxy page, a 5xx - leaves the stored credential alone, because wiping a
 *     pairing on an ambiguous answer would silently cut a child off from their family.
 */
object LocationFixProtocol {
    /** Readings worse than this are not reported; unchanged from the collection rule before. */
    const val MAX_REPORTED_ACCURACY_METERS = 200.0

    /**
     * The shortest gap between two reported readings, across every provider together.
     * Android applies `minTime` per provider, so GPS and network each alone could deliver
     * one reading per interval; this gate is what makes "at most once every 5 minutes" in
     * the ongoing notification true.
     */
    const val MIN_REPORT_INTERVAL_MILLIS = 5 * 60 * 1000L

    /** The single server error code that means "this credential is dead". */
    const val REVOKED_CREDENTIAL_CODE = "invalid_device_credential"

    /** The server answers with `{"error":{"code":"..."}}`; only this much of a body is read. */
    const val MAX_ERROR_BODY_CHARS = 4096

    private val ERROR_CODE = Regex("\"error\"\\s*:\\s*\\{[^{}]*?\"code\"\\s*:\\s*\"([a-z0-9_]{1,64})\"")
    private val UUID = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")

    data class Reading(
        val fixId: String,
        val latitude: Double,
        val longitude: Double,
        val accuracyMeters: Double,
        val recordedAtEpochMillis: Long,
        val fromMockProvider: Boolean,
    )

    fun path(deviceId: String): String = "/v1/devices/$deviceId/location-fixes"

    /** One key per fix: a retry of the same reading can never become a second row. */
    fun idempotencyKey(fixId: String): String = "location-fix-$fixId"

    /**
     * Returns the reading if it can be reported honestly, or null if it must be dropped.
     * Dropping is not an error: the next genuine callback is the retry.
     */
    fun reportable(reading: Reading): Reading? {
        if (!UUID.matches(reading.fixId)) return null
        if (!reading.latitude.isFinite() || reading.latitude < -90.0 || reading.latitude > 90.0) return null
        if (!reading.longitude.isFinite() || reading.longitude < -180.0 || reading.longitude > 180.0) return null
        if (!reading.accuracyMeters.isFinite() || reading.accuracyMeters <= 0.0) return null
        if (reading.accuracyMeters > MAX_REPORTED_ACCURACY_METERS) return null
        if (reading.recordedAtEpochMillis <= 0L) return null
        return reading
    }

    /**
     * Whether a reading taken at [nowElapsedMillis] (monotonic clock) may be reported, given
     * when the last one was handed to the network ([lastReportedElapsedMillis], null if none
     * yet in this session). A clock that went backwards never blocks reporting for long:
     * it is treated as a new session.
     */
    fun dueForReport(lastReportedElapsedMillis: Long?, nowElapsedMillis: Long): Boolean {
        if (lastReportedElapsedMillis == null) return true
        val gap = nowElapsedMillis - lastReportedElapsedMillis
        return gap < 0L || gap >= MIN_REPORT_INTERVAL_MILLIS
    }

    /**
     * Whether the legacy heartbeat (battery + the coordinates the W2 device card reads) may
     * follow a fix. Only after the W3 route accepted that same fix - a refusal there (for
     * example a future consent pause) must never be bypassed by writing the coordinates to
     * the older route - and never for a mock-provider reading, because the legacy route has
     * no field to say "test position" and would show it as a real one.
     */
    fun legacyHeartbeatAllowed(fixOutcome: LocationReportOutcome, reading: Reading): Boolean =
        fixOutcome == LocationReportOutcome.ACCEPTED && !reading.fromMockProvider

    /** The JSON body, field for field what `locationFixInput` in the backend accepts. */
    fun body(reading: Reading): String = buildString {
        append('{')
        append("\"fixId\":\"").append(reading.fixId.lowercase(Locale.ROOT)).append("\",")
        append("\"acquisition\":\"located\",")
        append("\"latitude\":").append(number(reading.latitude)).append(',')
        append("\"longitude\":").append(number(reading.longitude)).append(',')
        append("\"accuracyMeters\":").append(number(reading.accuracyMeters)).append(',')
        append("\"integritySoftWarning\":").append(reading.fromMockProvider).append(',')
        append("\"recordedAt\":\"").append(isoInstant(reading.recordedAtEpochMillis)).append('"')
        append('}')
    }

    /** UTC, millisecond precision, `Z` suffix - parseable by `new Date()` on the server. */
    fun isoInstant(epochMillis: Long): String {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.format(Date(epochMillis))
    }

    /** Pulls `error.code` out of a server error envelope, or null for anything else. */
    fun errorCode(body: String?): String? {
        if (body.isNullOrEmpty()) return null
        return ERROR_CODE.find(body.take(MAX_ERROR_BODY_CHARS))?.groupValues?.get(1)
    }

    /**
     * How the handset reads one answer. [statusCode] is null when no HTTP answer arrived
     * (no network, DNS, TLS, timeout).
     */
    fun classify(statusCode: Int?, body: String?): LocationReportOutcome = when {
        statusCode == null -> LocationReportOutcome.NETWORK_UNREACHABLE
        statusCode in 200..299 -> LocationReportOutcome.ACCEPTED
        statusCode == 401 && errorCode(body) == REVOKED_CREDENTIAL_CODE ->
            LocationReportOutcome.CREDENTIAL_REVOKED
        statusCode == 401 || statusCode == 403 || statusCode == 404 ->
            LocationReportOutcome.ACCESS_REFUSED
        statusCode == 408 || statusCode == 425 || statusCode == 429 || statusCode >= 500 ->
            LocationReportOutcome.SERVER_UNAVAILABLE
        else -> LocationReportOutcome.REJECTED
    }

    /** Plain decimal or exponent form; both are valid JSON numbers. Callers pass finite values. */
    private fun number(value: Double): String = value.toString()
}

/**
 * What happened to the last report. The wire names are what the Flutter layer reads through
 * the `status` method; they carry no coordinates, identifiers or server text.
 */
enum class LocationReportOutcome(val wire: String, val endsSession: Boolean) {
    /** The server stored the fix (201), or the legacy heartbeat was accepted (200). */
    ACCEPTED("accepted", false),

    /** 401 `invalid_device_credential`: the guardian cut this phone off, or it was re-paired. */
    CREDENTIAL_REVOKED("credential_revoked", true),

    /** A refusal that is not a definitive revocation. The credential is kept. */
    ACCESS_REFUSED("access_refused", false),

    /** The server did not accept this one fix (400, 409, 413...). It is not retried. */
    REJECTED("rejected", false),

    /** 408, 425, 429 or 5xx - including a sleeping free-tier server. */
    SERVER_UNAVAILABLE("server_unavailable", false),

    /** No HTTP answer at all. */
    NETWORK_UNREACHABLE("network_unreachable", false),
}
