package com.familyos.family_os

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Behaviour of the S2 protection verdict: deterministic stop priority, accumulating
 * degraded reasons, and the queue depth carried on every non-healthy state.
 */
class ProtectionStateMachineTest {
    private fun healthy() = ProtectionSignals(
        unlocked = true,
        serviceRunning = true,
        backgroundLocationGranted = true,
        notificationsGranted = true,
        batteryUnrestricted = true,
        networkAvailable = true,
        queueDepth = 0,
        queueLostSinceReported = 0L,
        heartbeatStale = false,
    )

    @Test fun `all healthy is fully protected`() {
        assertEquals(ProtectionState.FullyProtected, ProtectionStateMachine.evaluate(healthy()))
        assertEquals("fully_protected", ProtectionState.FullyProtected.wire)
    }

    @Test fun `a locked device stops before any other rule`() {
        val signals = healthy().copy(
            unlocked = false,
            serviceRunning = false,
            backgroundLocationGranted = false,
        )
        val state = ProtectionStateMachine.evaluate(signals)
        assertTrue(state is ProtectionState.Stopped)
        assertEquals(StoppedReason.AWAITING_UNLOCK, (state as ProtectionState.Stopped).reason)
        assertEquals("awaiting_unlock", state.reason.wire)
    }

    @Test fun `a dead service beats a revoked permission`() {
        val state = ProtectionStateMachine.evaluate(
            healthy().copy(serviceRunning = false, backgroundLocationGranted = false),
        )
        assertTrue(state is ProtectionState.Stopped)
        assertEquals(StoppedReason.SERVICE_DOWN, (state as ProtectionState.Stopped).reason)
    }

    @Test fun `a revoked background permission stops a running service`() {
        val state = ProtectionStateMachine.evaluate(healthy().copy(backgroundLocationGranted = false))
        assertTrue(state is ProtectionState.Stopped)
        assertEquals(StoppedReason.PERMISSION_REVOKED, (state as ProtectionState.Stopped).reason)
    }

    @Test fun `each limitation degrades on its own`() {
        val cases = listOf(
            healthy().copy(notificationsGranted = false) to DegradedReason.NOTIFICATIONS_DENIED,
            healthy().copy(batteryUnrestricted = false) to DegradedReason.BATTERY_RESTRICTED,
            healthy().copy(networkAvailable = false) to DegradedReason.OFFLINE,
            healthy().copy(queueLostSinceReported = 1L) to DegradedReason.QUEUE_OVERFLOW_LOST,
            healthy().copy(heartbeatStale = true) to DegradedReason.HEARTBEAT_STALE,
        )
        for ((signals, reason) in cases) {
            val state = ProtectionStateMachine.evaluate(signals)
            assertTrue("expected degraded for $reason", state is ProtectionState.Degraded)
            assertEquals(setOf(reason), (state as ProtectionState.Degraded).reasons)
            assertEquals("degraded", state.wire)
        }
    }

    @Test fun `degraded reasons accumulate`() {
        val state = ProtectionStateMachine.evaluate(
            healthy().copy(
                batteryUnrestricted = false,
                networkAvailable = false,
                heartbeatStale = true,
            ),
        )
        assertTrue(state is ProtectionState.Degraded)
        assertEquals(
            setOf(
                DegradedReason.BATTERY_RESTRICTED,
                DegradedReason.OFFLINE,
                DegradedReason.HEARTBEAT_STALE,
            ),
            (state as ProtectionState.Degraded).reasons,
        )
    }

    @Test fun `reason wires are stable`() {
        assertEquals("notifications_denied", DegradedReason.NOTIFICATIONS_DENIED.wire)
        assertEquals("battery_restricted", DegradedReason.BATTERY_RESTRICTED.wire)
        assertEquals("offline", DegradedReason.OFFLINE.wire)
        assertEquals("queue_overflow_lost", DegradedReason.QUEUE_OVERFLOW_LOST.wire)
        assertEquals("heartbeat_stale", DegradedReason.HEARTBEAT_STALE.wire)
        assertEquals("service_down", StoppedReason.SERVICE_DOWN.wire)
        assertEquals("permission_revoked", StoppedReason.PERMISSION_REVOKED.wire)
    }

    @Test fun `queue depth rides on degraded and stopped states`() {
        val degraded = ProtectionStateMachine.evaluate(
            healthy().copy(networkAvailable = false, queueDepth = 7),
        ) as ProtectionState.Degraded
        assertEquals(7, degraded.queueDepth)
        val stopped = ProtectionStateMachine.evaluate(
            healthy().copy(serviceRunning = false, queueDepth = 7),
        ) as ProtectionState.Stopped
        assertEquals(7, stopped.queueDepth)
    }

    @Test fun `zero lost fixes is not a limitation`() {
        assertEquals(ProtectionState.FullyProtected, ProtectionStateMachine.evaluate(healthy()))
    }
}
