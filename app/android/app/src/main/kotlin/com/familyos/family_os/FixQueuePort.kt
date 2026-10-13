package com.familyos.family_os

/**
 * S2 resilience: the queue operations the session coordinator orchestrates.
 *
 * The coherence map forbids a queue that lives beside the coordinator ("extend
 * `LocationSessionCoordinator`, no parallel queue"): this port is how the coordinator
 * *owns* the retry path - it decides what may be queued, what may be drained, and when
 * the queue dies with its session. `EncryptedFixQueueStore` implements this port; the
 * service injects the store in D2.
 *
 * Implementations must be safe to call under the coordinator's lock (all coordinator
 * entry points hold it).
 */
interface FixQueuePort {
    /** Persists one unsent fix. See [ResilientFixQueue.enqueue] for the acceptance rules. */
    fun enqueue(fix: QueuedFix, nowMillis: Long): EnqueueReport

    /** The next fixes to send, oldest first, at most [limit]. */
    fun due(limit: Int, nowMillis: Long): List<QueuedFix>

    /** Removes fixes the server acknowledged (or definitively refused). */
    fun remove(fixIds: Set<String>)

    /** Drops everything including loss counters: revocation and re-pairing only. */
    fun dropAll()

    /** Current depth and cumulative loss counters for the state machine and evidence. */
    fun stats(nowMillis: Long): QueueStats
}

/**
 * Outcomes worth a queue slot: no answer at all, or an answer that says "try later"
 * (408/425/429/5xx - including a sleeping free-tier server). A refusal (400, a generic
 * 401/403/404, a conflict...) is *settled*, never queued: retrying a fix the server
 * judged would be arguing with the judge. Credential revocation ends the session and
 * drops the queue instead (see the coordinator).
 */
fun queueWorthy(outcome: LocationReportOutcome): Boolean =
    outcome == LocationReportOutcome.NETWORK_UNREACHABLE ||
        outcome == LocationReportOutcome.SERVER_UNAVAILABLE
