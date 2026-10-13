package com.familyos.family_os

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Behaviour of the S2 clock-skew tolerance: sane `Date` headers anchor the offset to the
 * monotonic clock, wall-clock jumps are ignored, and a reboot voids the knowledge.
 */
class ServerTimeOffsetTest {
    // 2026-10-14T12:00:00Z and a monotonic reading - both fixed, no wall clock in tests.
    private val serverNoon = 1_791_979_200_000L
    private val elapsedAtNoon = 72_000_000L

    @Test fun `a sane Date header is observed`() {
        assertNotNull(ServerTimeOffset.observe(serverNoon, elapsedAtNoon))
    }

    @Test fun `absent or insane headers are refused`() {
        assertNull(ServerTimeOffset.observe(null, elapsedAtNoon))
        assertNull(ServerTimeOffset.observe(1_000L, elapsedAtNoon)) // 1970: nonsense.
        assertNull(ServerTimeOffset.observe(1_000_000_000_000L, elapsedAtNoon)) // 2001: too old.
        assertNull(ServerTimeOffset.observe(5_000_000_000_000L, elapsedAtNoon)) // 2128: too far.
        assertNull(ServerTimeOffset.observe(serverNoon, -1L)) // Monotonic readings are never negative.
    }

    @Test fun `corrected time advances with the monotonic clock only`() {
        val observation = ServerTimeOffset.observe(serverNoon, elapsedAtNoon)!!
        // Ten real minutes pass; the device wall clock is an hour ahead (tampered).
        val corrected = ServerTimeOffset.correctedNow(observation, serverNoon + 3_600_000L, elapsedAtNoon + 600_000L)
        assertEquals(serverNoon + 600_000L, corrected)
    }

    @Test fun `moving the wall clock never moves the corrected time`() {
        val observation = ServerTimeOffset.observe(serverNoon, elapsedAtNoon)!!
        val before = ServerTimeOffset.correctedNow(observation, serverNoon, elapsedAtNoon + 1_000L)
        // The user drags the clock a year forward at the same monotonic instant.
        val after = ServerTimeOffset.correctedNow(
            observation,
            serverNoon + 31_536_000_000L,
            elapsedAtNoon + 1_000L,
        )
        assertEquals(before, after)
    }

    @Test fun `a reboot voids the observation`() {
        val observation = ServerTimeOffset.observe(serverNoon, elapsedAtNoon)!!
        // After a reboot the monotonic clock restarts near zero: smaller than recorded.
        val wallAfterReboot = serverNoon + 3_600_000L
        assertEquals(
            wallAfterReboot,
            ServerTimeOffset.correctedNow(observation, wallAfterReboot, 60_000L),
        )
    }

    @Test fun `no observation means no correction`() {
        assertEquals(123_456_789L, ServerTimeOffset.correctedNow(null, 123_456_789L, 999L))
    }

    @Test fun `clamping caps the future and never touches the past`() {
        val serverNow = serverNoon
        val ceiling = serverNow + ServerTimeOffset.MAX_FUTURE_MARGIN_MILLIS
        // A wall clock an hour ahead is pulled down to the four-minute margin.
        assertEquals(ceiling, ServerTimeOffset.clampRecordedAt(serverNow + 3_600_000L, serverNow))
        // The margin boundary itself passes through.
        assertEquals(ceiling, ServerTimeOffset.clampRecordedAt(ceiling, serverNow))
        // The past - however old - is stamped honestly, never rewritten.
        assertEquals(1_000L, ServerTimeOffset.clampRecordedAt(1_000L, serverNow))
        assertEquals(serverNow - 1L, ServerTimeOffset.clampRecordedAt(serverNow - 1L, serverNow))
    }
}
