package com.familyos.family_os

/**
 * S2 resilience: restart pacing for the boot receiver, so a crashing service can never
 * hot-loop the device at startup.
 *
 * Android-free and deterministic (proven by `BootBackoffTest`): given the count of
 * consecutive failed starts, it answers how long to wait before the next attempt and
 * whether attempts are exhausted. Jitter, if ever wanted, belongs at the call site -
 * the policy itself must be exactly reproducible in a test.
 *
 * The attempt counter is persisted by the framework layer (D2); this object only maps
 * counts to delays. A successful start resets the counter to zero there.
 */
object BootBackoff {
    /** After this many consecutive failures the receiver stops trying until the next boot. */
    const val MAX_ATTEMPTS = 8

    /** Delay before the second attempt; each failure doubles it. */
    const val BASE_DELAY_MILLIS = 5_000L

    /** No wait is ever longer than this, however many failures pile up. */
    const val MAX_DELAY_MILLIS = 15L * 60 * 1000

    /**
     * How long to wait before the attempt numbered [attempt] (`0` = the first start,
     * which is immediate). Attempts past [MAX_ATTEMPTS] still return the capped delay -
     * callers check [exhausted] to decide whether to try at all.
     */
    fun delayMillis(attempt: Int): Long {
        if (attempt <= 0) return 0L
        var delay = BASE_DELAY_MILLIS
        var doublings = attempt - 1
        // Cap every step: the delay can never overflow, however large the attempt count.
        while (doublings > 0 && delay < MAX_DELAY_MILLIS) {
            delay = if (delay > MAX_DELAY_MILLIS / 2) MAX_DELAY_MILLIS else delay * 2
            doublings--
        }
        return delay
    }

    /** True once the receiver must stop trying and report `STOPPED(SERVICE_DOWN)`. */
    fun exhausted(attempt: Int): Boolean = attempt >= MAX_ATTEMPTS
}
