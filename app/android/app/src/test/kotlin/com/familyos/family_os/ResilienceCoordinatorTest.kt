package com.familyos.family_os

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Behaviour of the S2 coordinator extension: the retry queue belongs to the session -
 * only retryable answers for the current, unrevoked pairing may enqueue or drain, and
 * the queue dies with a revoked session.
 */
class ResilienceCoordinatorTest {
    private class FakeStore(var stored: String?) : PairingSessionStore<String> {
        override fun current(): String? = stored
        override fun forgetIfCurrent(expected: String): ForgetResult {
            if (stored != null && stored != expected) return ForgetResult.SUPERSEDED
            stored = null
            return ForgetResult.FORGOTTEN
        }
    }

    private class FakeStatus : ReportStatusSink {
        var revoked = false
        var records = 0
        override fun record(outcome: LocationReportOutcome, atEpochMillis: Long) { records++ }
        override fun markCredentialRevoked(atEpochMillis: Long) { revoked = true }
        override fun credentialRevoked(): Boolean = revoked
    }

    private class FakeQueue : FixQueuePort {
        private val inner = ResilientFixQueue()
        var dropCalls = 0
        override fun enqueue(fix: QueuedFix, nowMillis: Long): EnqueueReport = inner.enqueue(fix, nowMillis)
        override fun due(limit: Int, nowMillis: Long): List<QueuedFix> = inner.due(limit, nowMillis)
        override fun remove(fixIds: Set<String>): Unit { inner.remove(fixIds) }
        override fun dropAll() { dropCalls++; inner.dropAll() }
        override fun stats(nowMillis: Long): QueueStats = inner.stats(nowMillis)
    }

    private val lock = Any()
    private fun fix(id: String) = QueuedFix(id, 1_000L, 1_000L, 0, "{\"fixId\":\"$id\"}")

    @Test fun `only no-answer and try-later outcomes are queue worthy`() {
        assertTrue(queueWorthy(LocationReportOutcome.NETWORK_UNREACHABLE))
        assertTrue(queueWorthy(LocationReportOutcome.SERVER_UNAVAILABLE))
        assertFalse(queueWorthy(LocationReportOutcome.ACCEPTED))
        assertFalse(queueWorthy(LocationReportOutcome.CREDENTIAL_REVOKED))
        assertFalse(queueWorthy(LocationReportOutcome.ACCESS_REFUSED))
        assertFalse(queueWorthy(LocationReportOutcome.REJECTED))
    }

    @Test fun `a retryable answer for the current pairing enqueues`() {
        val queue = FakeQueue()
        val coordinator = LocationSessionCoordinator(FakeStore("pair"), FakeStatus(), lock, queue) { 1_000L }
        assertTrue(coordinator.offerToQueue("pair", fix("a"), LocationReportOutcome.NETWORK_UNREACHABLE, 1_000L))
        assertEquals(listOf("a"), queue.due(10, 1_000L).map { it.fixId })
    }

    @Test fun `a refusal never touches the queue`() {
        val queue = FakeQueue()
        val coordinator = LocationSessionCoordinator(FakeStore("pair"), FakeStatus(), lock, queue) { 1_000L }
        for (outcome in listOf(
            LocationReportOutcome.ACCEPTED,
            LocationReportOutcome.REJECTED,
            LocationReportOutcome.ACCESS_REFUSED,
            LocationReportOutcome.CREDENTIAL_REVOKED,
        )) {
            assertFalse(coordinator.offerToQueue("pair", fix("a"), outcome, 1_000L))
        }
        assertTrue(queue.due(10, 1_000L).isEmpty())
    }

    @Test fun `a revoked or replaced pairing cannot enqueue`() {
        val queue = FakeQueue()
        val store = FakeStore("pair")
        val coordinator = LocationSessionCoordinator(store, FakeStatus(), lock, queue) { 1_000L }
        assertFalse(coordinator.offerToQueue("other", fix("a"), LocationReportOutcome.NETWORK_UNREACHABLE, 1_000L))
        store.stored = "new-pair"
        assertFalse(coordinator.offerToQueue("pair", fix("a"), LocationReportOutcome.NETWORK_UNREACHABLE, 1_000L))
        coordinator.settle("new-pair", LocationReportOutcome.CREDENTIAL_REVOKED)
        assertFalse(coordinator.offerToQueue("new-pair", fix("a"), LocationReportOutcome.NETWORK_UNREACHABLE, 1_000L))
        assertTrue(queue.due(10, 1_000L).isEmpty())
    }

    @Test fun `no wired queue means safe no-ops`() {
        val coordinator = LocationSessionCoordinator(FakeStore("pair"), FakeStatus(), lock) { 1_000L }
        assertFalse(coordinator.offerToQueue("pair", fix("a"), LocationReportOutcome.NETWORK_UNREACHABLE, 1_000L))
        assertTrue(coordinator.drainQueue("pair", 10, 1_000L).isEmpty())
        coordinator.confirmDrained("pair", setOf("a"))
        coordinator.dropQueue()
    }

    @Test fun `only the current unrevoked pairing drains`() {
        val queue = FakeQueue()
        queue.enqueue(fix("a"), 1_000L)
        val store = FakeStore("pair")
        val coordinator = LocationSessionCoordinator(store, FakeStatus(), lock, queue) { 1_000L }
        assertEquals(listOf("a"), coordinator.drainQueue("pair", 10, 1_000L).map { it.fixId })
        assertTrue(coordinator.drainQueue("other", 10, 1_000L).isEmpty())
        store.stored = "new-pair"
        assertTrue(coordinator.drainQueue("pair", 10, 1_000L).isEmpty())
    }

    @Test fun `confirm removes only for the stored pairing`() {
        val queue = FakeQueue()
        queue.enqueue(fix("a"), 1_000L)
        queue.enqueue(fix("b"), 1_000L)
        val store = FakeStore("pair")
        val coordinator = LocationSessionCoordinator(store, FakeStatus(), lock, queue) { 1_000L }
        coordinator.confirmDrained("pair", setOf("a"))
        assertEquals(listOf("b"), queue.due(10, 1_000L).map { it.fixId })
        store.stored = "new-pair"
        coordinator.confirmDrained("pair", setOf("b")) // Stale confirm: left for dropQueue.
        assertEquals(listOf("b"), queue.due(10, 1_000L).map { it.fixId })
    }

    @Test fun `revocation drops the queue with the credential`() {
        val queue = FakeQueue()
        queue.enqueue(fix("a"), 1_000L)
        val coordinator = LocationSessionCoordinator(FakeStore("pair"), FakeStatus(), lock, queue) { 1_000L }
        val settlement = coordinator.settle("pair", LocationReportOutcome.CREDENTIAL_REVOKED)
        assertEquals(SettleDecision.STOP_SESSION, settlement.decision)
        assertEquals(1, queue.dropCalls)
        assertTrue(queue.due(10, 1_000L).isEmpty())
    }

    @Test fun `an accepted answer leaves the queue alone`() {
        val queue = FakeQueue()
        queue.enqueue(fix("a"), 1_000L)
        val coordinator = LocationSessionCoordinator(FakeStore("pair"), FakeStatus(), lock, queue) { 1_000L }
        val settlement = coordinator.settle("pair", LocationReportOutcome.ACCEPTED)
        assertEquals(SettleDecision.CONTINUE, settlement.decision)
        assertEquals(0, queue.dropCalls)
        assertEquals(listOf("a"), queue.due(10, 1_000L).map { it.fixId })
    }

    @Test fun `dropQueue clears the session queue for re-pairing`() {
        val queue = FakeQueue()
        queue.enqueue(fix("a"), 1_000L)
        val coordinator = LocationSessionCoordinator(FakeStore("pair"), FakeStatus(), lock, queue) { 1_000L }
        coordinator.dropQueue()
        assertEquals(1, queue.dropCalls)
        assertTrue(queue.due(10, 1_000L).isEmpty())
    }
}
