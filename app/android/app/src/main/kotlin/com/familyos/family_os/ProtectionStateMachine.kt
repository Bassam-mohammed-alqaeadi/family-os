package com.familyos.family_os

/**
 * S2 resilience: the single, deterministic answer to "is this phone protected?".
 *
 * Android-free: every transition is proven by plain JVM tests (`ProtectionStateMachineTest`).
 * The handset computes this where the facts live (service state, permission grants, battery
 * exemption, network, queue counters, heartbeat freshness); the Flutter layer mirrors the
 * verdict through one channel method and renders it - it never re-derives protection from
 * a toggle or a cached guess (D7).
 *
 * Design rules:
 *
 *  1. Three verdicts only: [ProtectionState.FullyProtected], [ProtectionState.Degraded]
 *     (with machine-readable reasons), [ProtectionState.Stopped] (with one reason).
 *  2. Stopped reasons are ordered and exclusive: the first matching rule wins, so the
 *     verdict is deterministic for any signal combination - no priority ambiguity.
 *  3. Degraded reasons accumulate: every true limitation is reported, not just the first.
 *  4. Unknown inputs fail closed: a signal the handset could not read is passed as its
 *     negative value by the caller (unreadable permission = not granted). This machine
 *     trusts its inputs and documents that contract; it does not second-guess them.
 */
object ProtectionStateMachine {
    /**
     * Evaluates [signals] into the current verdict. Pure and total: every combination of
     * inputs maps to exactly one state.
     */
    fun evaluate(signals: ProtectionSignals): ProtectionState {
        if (!signals.unlocked) {
            return ProtectionState.Stopped(StoppedReason.AWAITING_UNLOCK, signals.queueDepth)
        }
        if (!signals.serviceRunning) {
            return ProtectionState.Stopped(StoppedReason.SERVICE_DOWN, signals.queueDepth)
        }
        if (!signals.backgroundLocationGranted) {
            return ProtectionState.Stopped(StoppedReason.PERMISSION_REVOKED, signals.queueDepth)
        }
        val reasons = LinkedHashSet<DegradedReason>()
        if (!signals.notificationsGranted) reasons.add(DegradedReason.NOTIFICATIONS_DENIED)
        if (!signals.batteryUnrestricted) reasons.add(DegradedReason.BATTERY_RESTRICTED)
        if (!signals.networkAvailable) reasons.add(DegradedReason.OFFLINE)
        if (signals.queueLostSinceReported > 0L) reasons.add(DegradedReason.QUEUE_OVERFLOW_LOST)
        if (signals.heartbeatStale) reasons.add(DegradedReason.HEARTBEAT_STALE)
        if (reasons.isEmpty()) return ProtectionState.FullyProtected
        return ProtectionState.Degraded(reasons, signals.queueDepth)
    }
}

/**
 * Everything the verdict needs, read by the framework layer just before evaluation.
 * A signal that could not be read must be passed as `false` / stale - doubt is never
 * resolved as healthy (rule 4).
 *
 * @param queueLostSinceReported evicted + expired + corrupt losses since the last report
 * to the server; the reporter resets its own baseline after a successful report. The
 * machine is stateless - staleness of this counter is the caller's honesty to keep.
 */
data class ProtectionSignals(
    val unlocked: Boolean,
    val serviceRunning: Boolean,
    val backgroundLocationGranted: Boolean,
    val notificationsGranted: Boolean,
    val batteryUnrestricted: Boolean,
    val networkAvailable: Boolean,
    val queueDepth: Int,
    val queueLostSinceReported: Long,
    val heartbeatStale: Boolean,
)

sealed interface ProtectionState {
    /** The wire word the Flutter mirror and the server evidence read. */
    val wire: String

    /** Everything runs: service, permissions, battery exemption, network, fresh heartbeat. */
    object FullyProtected : ProtectionState {
        override val wire: String = "fully_protected"
    }

    /** Protection runs with stated limitations. Every true limitation is listed. */
    data class Degraded(val reasons: Set<DegradedReason>, val queueDepth: Int) : ProtectionState {
        override val wire: String = "degraded"
    }

    /** Protection is not running. Exactly one reason: the first matching stop rule. */
    data class Stopped(val reason: StoppedReason, val queueDepth: Int) : ProtectionState {
        override val wire: String = "stopped"
    }
}

/** Why protection is stopped. Ordered: the evaluator returns the first that matches. */
enum class StoppedReason(val wire: String) {
    /** Direct boot: the user has not unlocked since startup, so no key and no credential. */
    AWAITING_UNLOCK("awaiting_unlock"),

    /** The telemetry service is not running (crash loop exhausted, force stop, killed). */
    SERVICE_DOWN("service_down"),

    /** Background location (or fine location) was revoked: collection is unlawful to run. */
    PERMISSION_REVOKED("permission_revoked"),
}

/** Stated limitations while protection still runs. All true ones are reported. */
enum class DegradedReason(val wire: String) {
    /** The persistent notification cannot be shown; the person holding the phone is blind. */
    NOTIFICATIONS_DENIED("notifications_denied"),

    /** Battery optimizations apply: Doze and buckets may delay or pause collection. */
    BATTERY_RESTRICTED("battery_restricted"),

    /** No network: fixes queue locally instead of reaching the family. */
    OFFLINE("offline"),

    /** Queue losses (evicted/expired/corrupt) happened since the last server report. */
    QUEUE_OVERFLOW_LOST("queue_overflow_lost"),

    /** The last heartbeat was not acknowledged recently enough to claim freshness. */
    HEARTBEAT_STALE("heartbeat_stale"),
}
