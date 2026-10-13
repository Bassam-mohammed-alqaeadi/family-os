package com.familyos.family_os

/**
 * Decides, for the child's handset, whether a report may be sent with a given pairing and
 * what one server answer does to that pairing. Android-free, so the revocation rules are
 * proven by plain JVM tests (`LocationSessionCoordinatorTest`), not by reading the source.
 *
 * The rules:
 *
 *  1. A definitive revocation is **fail-closed**. The "revoked" mark is written first, and
 *     from then on no report is sent and no collection is (re)started with that pairing -
 *     even if forgetting the stored credential fails. A failed delete can leave the dead
 *     credential on disk; it can never leave collection running.
 *  2. A late answer for a credential that is **no longer the stored one** changes nothing.
 *     Re-pairing revokes the old credential on the server, so that late 401 is expected.
 *  3. Only a new pairing clears the mark. It writes the new credential and resets the
 *     status under the same [lock], so "the revoked pairing is still on disk" and "a new
 *     pairing arrived" can never be confused: the mark tells them apart, not the file.
 *  4. The offline queue belongs to the session, not beside it (S2, coherence §5). Only a
 *     retryable answer for the *current* pairing may enqueue; only the current pairing
 *     may drain; revocation drops the queue with the credential; re-pairing must call
 *     [dropQueue] before the new session starts, so the old pairing's fixes are never
 *     sent as the new one's.
 */
class LocationSessionCoordinator<C : Any>(
    private val store: PairingSessionStore<C>,
    private val status: ReportStatusSink,
    private val lock: Any,
    private val queue: FixQueuePort? = null,
    private val clock: () -> Long,
) {
    /** Whether collection may start (or restart after the OS recreated the service). */
    fun mayStart(): Boolean = synchronized(lock) {
        store.current() != null && !status.credentialRevoked()
    }

    /** Whether a report prepared with [config] may still be sent now. */
    fun mayReport(config: C): Boolean = synchronized(lock) {
        !status.credentialRevoked() && store.current() == config
    }

    /** Records [outcome] for the session that used [used] and says what happens next. */
    fun settle(used: C, outcome: LocationReportOutcome): Settlement = synchronized(lock) {
        // Already revoked (another report got there first) or superseded by a new pairing:
        // this answer belongs to a session that is over.
        if (status.credentialRevoked() || store.current() != used) {
            return@synchronized Settlement(SettleDecision.IGNORE, null)
        }
        status.record(outcome, clock())
        if (!outcome.endsSession) return@synchronized Settlement(SettleDecision.CONTINUE, null)
        // Mark first: from here on nothing speaks with this pairing, whatever the delete does.
        status.markCredentialRevoked(clock())
        // The queue dies with its session (rule 4): a dead pairing's fixes must neither be
        // sent nor linger. The port is safe under this lock by contract.
        queue?.dropAll()
        Settlement(SettleDecision.STOP_SESSION, store.forgetIfCurrent(used))
    }

    /**
     * Checked again just before the service actually stops: true while the revocation
     * still stands, false if a new pairing was stored in between (that pairing owns the
     * service now and must not be stopped).
     */
    fun revocationStillStands(): Boolean = synchronized(lock) { status.credentialRevoked() }

    /**
     * Retries forgetting a revoked pairing that a failed delete left behind. Does nothing
     * unless the revocation still stands.
     */
    fun retryForgetRevoked(): ForgetResult? = synchronized(lock) {
        if (!status.credentialRevoked()) return@synchronized null
        val leftOver = store.current() ?: return@synchronized ForgetResult.FORGOTTEN
        store.forgetIfCurrent(leftOver)
    }

    /**
     * Queues [fix] when [outcome] is retryable (see [queueWorthy]) and [config] is still
     * the current, unrevoked pairing. Anything else - a refusal, a revoked mark, a
     * superseded pairing, no queue wired - refuses without touching the queue.
     */
    fun offerToQueue(config: C, fix: QueuedFix, outcome: LocationReportOutcome, nowMillis: Long): Boolean =
        synchronized(lock) {
            val port = queue ?: return@synchronized false
            if (status.credentialRevoked() || store.current() != config) return@synchronized false
            if (!queueWorthy(outcome)) return@synchronized false
            port.enqueue(fix, nowMillis)
            true
        }

    /**
     * The next queued fixes for [config], oldest first, at most [limit]. Only the current,
     * unrevoked pairing may drain; the caller removes what the server acknowledges via
     * [confirmDrained] (a crash between drain and confirm re-sends, and the per-fix
     * idempotency key makes the re-send a no-op row, not a duplicate).
     */
    fun drainQueue(config: C, limit: Int, nowMillis: Long): List<QueuedFix> = synchronized(lock) {
        val port = queue ?: return@synchronized emptyList()
        if (status.credentialRevoked() || store.current() != config) return@synchronized emptyList()
        port.due(limit, nowMillis)
    }

    /**
     * Removes drained fixes the server settled. Refuses silently unless [config] is still
     * the stored pairing: a replaced pairing's leftovers are dropped by [dropQueue] on the
     * pairing path, never confirmed away piecemeal.
     */
    fun confirmDrained(config: C, fixIds: Set<String>) {
        synchronized(lock) {
            val port = queue ?: return@synchronized
            if (store.current() != config) return@synchronized
            port.remove(fixIds)
        }
    }

    /**
     * Drops the queue with its loss counters. Called on the re-pairing path *before* the
     * new session starts (rule 4); revocation drops through [settle] instead.
     */
    fun dropQueue() {
        synchronized(lock) {
            queue?.dropAll()
        }
    }
}

data class Settlement(val decision: SettleDecision, val forget: ForgetResult?)

enum class SettleDecision {
    /** Keep collecting; the answer was recorded. */
    CONTINUE,

    /** Stop collecting now and tell the person holding the phone. */
    STOP_SESSION,

    /** The answer belongs to a session that is already over; do nothing. */
    IGNORE,
}

enum class ForgetResult {
    /** The stored credential is gone. */
    FORGOTTEN,

    /** A different pairing is stored; it was left alone. */
    SUPERSEDED,

    /** The credential could not be removed. Collection still stops (rule 1). */
    FAILED,
}

/** The stored pairing. Implementations must be safe to call under the coordinator's lock. */
interface PairingSessionStore<C : Any> {
    fun current(): C?
    fun forgetIfCurrent(expected: C): ForgetResult
}

/** What the handset remembers about its last report; reset only by a new pairing. */
interface ReportStatusSink {
    fun record(outcome: LocationReportOutcome, atEpochMillis: Long)
    fun markCredentialRevoked(atEpochMillis: Long)
    fun credentialRevoked(): Boolean
}
