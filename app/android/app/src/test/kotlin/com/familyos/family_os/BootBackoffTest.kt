package com.familyos.family_os

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Behaviour of the S2 boot-restart pacing: the first start is immediate, failures double
 * the wait up to a cap, and the policy can neither overflow nor loop forever.
 */
class BootBackoffTest {
    @Test fun `the first start is immediate`() {
        assertEquals(0L, BootBackoff.delayMillis(0))
        assertEquals(0L, BootBackoff.delayMillis(-2))
    }

    @Test fun `failures double the wait`() {
        assertEquals(5_000L, BootBackoff.delayMillis(1))
        assertEquals(10_000L, BootBackoff.delayMillis(2))
        assertEquals(20_000L, BootBackoff.delayMillis(3))
        assertEquals(640_000L, BootBackoff.delayMillis(8))
    }

    @Test fun `the wait caps at fifteen minutes and never overflows`() {
        assertEquals(900_000L, BootBackoff.delayMillis(9))
        assertEquals(900_000L, BootBackoff.delayMillis(100))
        assertEquals(900_000L, BootBackoff.delayMillis(Int.MAX_VALUE))
    }

    @Test fun `attempts exhaust after eight failures`() {
        assertFalse(BootBackoff.exhausted(0))
        assertFalse(BootBackoff.exhausted(7))
        assertTrue(BootBackoff.exhausted(8))
        assertTrue(BootBackoff.exhausted(9))
    }
}
