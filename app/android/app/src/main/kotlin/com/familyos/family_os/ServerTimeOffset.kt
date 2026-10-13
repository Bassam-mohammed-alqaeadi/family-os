package com.familyos.family_os

/**
 * S2 resilience: honest timestamps under a tampered or drifting device clock.
 *
 * Android-free: the offset math is proven by plain JVM tests (`ServerTimeOffsetTest`).
 * Only `SystemClock.elapsedRealtime()` (monotonic, survives wall-clock changes) and the
 * server's HTTP `Date` header feed this object; the device wall clock is never trusted
 * for *measuring* time, only for stamping when no server knowledge exists yet.
 *
 * How it works: each observation records the server instant together with the monotonic
 * reading at that moment. The corrected "now" is then `serverAtObservation + elapsedDelta`
 * - immune to the user moving the wall clock afterwards, because the wall clock is not
 * part of the formula. A reboot resets the monotonic clock to a small value, which is
 * detectable (the new reading is smaller than the recorded one) and invalidates the
 * observation instead of producing a wildly wrong past.
 *
 * The corrected time is used for one thing only: stamping `recordedAt` on fixes and
 * heartbeats so the server's 5-minute future rule (`MAX_FIX_CLOCK_SKEW_MS`) accepts
 * genuine readings from a handset whose wall clock runs ahead. The past is never
 * rewritten: a late fix is sent with its true (old) stamp and the server stores it
 * `stored_out_of_order`, honestly unevaluated.
 */
object ServerTimeOffset {
    /**
     * A stamped instant is never pushed past `serverNow + this`. Four minutes sits strictly
     * under the server's five-minute future rejection, leaving a one-minute margin for the
     * request's own flight time.
     */
    const val MAX_FUTURE_MARGIN_MILLIS = 4L * 60 * 1000

    private const val MIN_SANE_SERVER_MILLIS = 1577836800000L // 2020-01-01T00:00:00Z
    private const val MAX_SANE_SERVER_MILLIS = 4102444800000L // 2100-01-01T00:00:00Z

    /** One server-time sighting, anchored to the monotonic clock. */
    data class Observation(val serverTimeMillis: Long, val elapsedMillis: Long)

    /**
     * Records a `Date` header value ([dateHeaderMillis], already parsed by the HTTP layer)
     * seen at monotonic [elapsedNowMillis]. Returns null when the header is absent or not
     * a sane instant (a proxy with a nonsense clock must not poison the offset).
     */
    fun observe(dateHeaderMillis: Long?, elapsedNowMillis: Long): Observation? {
        if (dateHeaderMillis == null) return null
        if (dateHeaderMillis < MIN_SANE_SERVER_MILLIS || dateHeaderMillis > MAX_SANE_SERVER_MILLIS) return null
        if (elapsedNowMillis < 0L) return null
        return Observation(serverTimeMillis = dateHeaderMillis, elapsedMillis = elapsedNowMillis)
    }

    /**
     * The best-known current server time. With no observation (or one invalidated by a
     * reboot, or a monotonic reading that went backwards), returns [deviceWallNowMillis]:
     * no knowledge means no correction, stated plainly, not a fabricated precision.
     */
    fun correctedNow(
        observation: Observation?,
        deviceWallNowMillis: Long,
        elapsedNowMillis: Long,
    ): Long {
        if (observation == null) return deviceWallNowMillis
        val delta = elapsedNowMillis - observation.elapsedMillis
        if (delta < 0L) return deviceWallNowMillis // Reboot (or a broken clock): knowledge void.
        return observation.serverTimeMillis + delta
    }

    /**
     * Clamps a stamp candidate so it can never trip the server's future rejection: at most
     * [MAX_FUTURE_MARGIN_MILLIS] ahead of [serverNowMillis]. The past passes through
     * untouched - backdating a late fix would be inventing punctuality.
     */
    fun clampRecordedAt(candidateMillis: Long, serverNowMillis: Long): Long {
        val ceiling = serverNowMillis + MAX_FUTURE_MARGIN_MILLIS
        return if (candidateMillis > ceiling) ceiling else candidateMillis
    }
}
