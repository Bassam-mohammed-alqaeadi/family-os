package com.familyos.family_os

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Behaviour of the handset's revocation rules, with in-memory fakes for the stored pairing
 * and the report status. Credentials here are synthetic strings.
 */
class LocationSessionCoordinatorTest {
    private class FakeStore(var stored: String?) : PairingSessionStore<String> {
        var deleteFails = false
        var forgetCalls = 0
        override fun current(): String? = stored
        override fun forgetIfCurrent(expected: String): ForgetResult {
            forgetCalls++
            val now = stored
            if (now != null && now != expected) return ForgetResult.SUPERSEDED
            if (deleteFails) return ForgetResult.FAILED
            stored = null
            return ForgetResult.FORGOTTEN
        }
    }

    private class FakeStatus : ReportStatusSink {
        val outcomes = mutableListOf<LocationReportOutcome>()
        var revokedAt = 0L
        override fun record(outcome: LocationReportOutcome, atEpochMillis: Long) {
            outcomes += outcome
        }
        override fun markCredentialRevoked(atEpochMillis: Long) {
            revokedAt = atEpochMillis
        }
        override fun credentialRevoked(): Boolean = revokedAt > 0L

        /** What the pairing screen does, under the same lock, when a new pairing is stored. */
        fun resetForNewPairing() {
            outcomes.clear()
            revokedAt = 0L
        }
    }

    private val lock = Any()
    private val store = FakeStore("credential-A")
    private val status = FakeStatus()
    private val coordinator = LocationSessionCoordinator(store, status, lock) { 1_000L }

    private fun newPairing(credential: String) = synchronized(lock) {
        store.stored = credential
        status.resetForNewPairing()
    }

    @Test
    fun revocationOfTheCurrentCredentialStopsAndForgetsIt() {
        val result = coordinator.settle("credential-A", LocationReportOutcome.CREDENTIAL_REVOKED)
        assertEquals(SettleDecision.STOP_SESSION, result.decision)
        assertEquals(ForgetResult.FORGOTTEN, result.forget)
        assertNull(store.stored)
        assertTrue(status.credentialRevoked())
        assertEquals(listOf(LocationReportOutcome.CREDENTIAL_REVOKED), status.outcomes)
        assertTrue(coordinator.revocationStillStands())
        assertFalse(coordinator.mayStart())
        assertFalse(coordinator.mayReport("credential-A"))
    }

    @Test
    fun lateRevocationOfAStaleCredentialLeavesTheNewPairingAlone() {
        newPairing("credential-B")
        val result = coordinator.settle("credential-A", LocationReportOutcome.CREDENTIAL_REVOKED)
        assertEquals(SettleDecision.IGNORE, result.decision)
        assertEquals("credential-B", store.stored)
        assertEquals(0, store.forgetCalls)
        assertFalse(status.credentialRevoked())
        assertTrue(status.outcomes.isEmpty())
        assertTrue(coordinator.mayReport("credential-B"))
        assertTrue(coordinator.mayStart())
    }

    @Test
    fun failedDeleteStillStopsCollectionFailClosed() {
        store.deleteFails = true
        val result = coordinator.settle("credential-A", LocationReportOutcome.CREDENTIAL_REVOKED)
        assertEquals(SettleDecision.STOP_SESSION, result.decision)
        assertEquals(ForgetResult.FAILED, result.forget)
        // The dead credential is still on disk, and that is not mistaken for a new pairing.
        assertEquals("credential-A", store.stored)
        assertTrue(coordinator.revocationStillStands())
        assertFalse(coordinator.mayReport("credential-A"))
        assertFalse(coordinator.mayStart())
        // A second answer for the same session neither records nor stops twice.
        assertEquals(
            SettleDecision.IGNORE,
            coordinator.settle("credential-A", LocationReportOutcome.ACCEPTED).decision,
        )
        assertEquals(1, status.outcomes.size)
    }

    @Test
    fun aRetryForgetsTheLeftOverRevokedCredentialOnceDeletionWorks() {
        store.deleteFails = true
        coordinator.settle("credential-A", LocationReportOutcome.CREDENTIAL_REVOKED)
        assertEquals(ForgetResult.FAILED, coordinator.retryForgetRevoked())
        store.deleteFails = false
        assertEquals(ForgetResult.FORGOTTEN, coordinator.retryForgetRevoked())
        assertNull(store.stored)
        assertFalse(coordinator.mayStart())
    }

    @Test
    fun retryNeverTouchesAPairingWhenNothingWasRevoked() {
        assertNull(coordinator.retryForgetRevoked())
        assertEquals("credential-A", store.stored)
        assertEquals(0, store.forgetCalls)
    }

    @Test
    fun aNewPairingAfterAFailedDeleteClearsTheMarkAndCancelsThePendingStop() {
        store.deleteFails = true
        coordinator.settle("credential-A", LocationReportOutcome.CREDENTIAL_REVOKED)
        newPairing("credential-B")
        // The stop runnable checks this before stopping the service.
        assertFalse(coordinator.revocationStillStands())
        assertTrue(coordinator.mayStart())
        assertTrue(coordinator.mayReport("credential-B"))
        assertFalse(coordinator.mayReport("credential-A"))
    }

    @Test
    fun ambiguousRefusalsAreRecordedAndCollectionContinues() {
        for (outcome in LocationReportOutcome.values().filter { !it.endsSession }) {
            val result = coordinator.settle("credential-A", outcome)
            assertEquals("$outcome", SettleDecision.CONTINUE, result.decision)
            assertNull(result.forget)
        }
        assertEquals("credential-A", store.stored)
        assertEquals(0, store.forgetCalls)
        assertFalse(status.credentialRevoked())
        assertTrue(coordinator.mayReport("credential-A"))
    }

    @Test
    fun concurrentRevocationsOfOneSessionStopExactlyOnce() {
        val pool = Executors.newFixedThreadPool(8)
        val start = CountDownLatch(1)
        val decisions = java.util.Collections.synchronizedList(mutableListOf<SettleDecision>())
        repeat(32) {
            pool.execute {
                start.await()
                decisions += coordinator.settle("credential-A", LocationReportOutcome.CREDENTIAL_REVOKED).decision
            }
        }
        start.countDown()
        pool.shutdown()
        assertTrue(pool.awaitTermination(10, TimeUnit.SECONDS))
        assertEquals(1, decisions.count { it == SettleDecision.STOP_SESSION })
        assertEquals(31, decisions.count { it == SettleDecision.IGNORE })
        assertEquals(1, store.forgetCalls)
    }
}
