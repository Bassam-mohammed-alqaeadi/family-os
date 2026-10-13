package com.familyos.family_os

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Behaviour of the S2 offline queue: oldest-first order, capacity ring, TTL expiry,
 * loss counters, and the strict line framing shared with the encrypted store.
 */
class ResilientFixQueueTest {
    private fun fix(
        id: String,
        recordedAt: Long,
        enqueuedAt: Long,
        attempts: Int = 0,
        payload: String = "{\"fixId\":\"$id\"}",
    ) = QueuedFix(id, recordedAt, enqueuedAt, attempts, payload)

    @Test fun `drains oldest first even when enqueued out of order`() {
        val queue = ResilientFixQueue()
        queue.enqueue(fix("c", 3_000L, 3_000L), 3_000L)
        queue.enqueue(fix("a", 1_000L, 1_000L), 3_000L)
        queue.enqueue(fix("b", 2_000L, 2_000L), 3_000L)
        assertEquals(listOf("a", "b", "c"), queue.due(10, 3_000L).map { it.fixId })
    }

    @Test fun `capacity evicts the oldest and counts the loss`() {
        val queue = ResilientFixQueue(capacity = 3)
        for (i in 1..5) queue.enqueue(fix("f$i", i * 1_000L, i * 1_000L), 9_000L)
        val due = queue.due(10, 9_000L)
        assertEquals(listOf("f3", "f4", "f5"), due.map { it.fixId })
        assertEquals(2L, queue.stats(9_000L).evictedTotal)
        assertEquals(3, queue.stats(9_000L).depth)
    }

    @Test fun `a fix older than the TTL is refused, counted, never stored`() {
        val queue = ResilientFixQueue(ttlMillis = 1_000L)
        val report = queue.enqueue(fix("old", 0L, 5_000L), 5_000L)
        assertFalse(report.accepted)
        assertTrue(report.rejectedStale)
        assertEquals(1L, queue.stats(5_000L).expiredTotal)
        assertEquals(0, queue.stats(5_000L).depth)
    }

    @Test fun `queued fixes expire at drain time`() {
        val queue = ResilientFixQueue(ttlMillis = 1_000L)
        queue.enqueue(fix("a", 0L, 0L), 0L)
        assertTrue(queue.due(10, 5_000L).isEmpty())
        assertEquals(1L, queue.stats(5_000L).expiredTotal)
    }

    @Test fun `re-enqueueing an id never duplicates its slot`() {
        val queue = ResilientFixQueue(capacity = 1)
        queue.enqueue(fix("a", 1_000L, 1_000L), 1_000L)
        val report = queue.enqueue(fix("a", 1_000L, 2_000L), 2_000L)
        assertTrue(report.accepted)
        assertTrue(report.evicted.isEmpty())
        assertEquals(1, queue.stats(2_000L).depth)
    }

    @Test fun `remove drops acknowledged fixes and reports the count`() {
        val queue = ResilientFixQueue()
        queue.enqueue(fix("a", 1_000L, 1_000L), 1_000L)
        queue.enqueue(fix("b", 2_000L, 2_000L), 2_000L)
        assertEquals(1, queue.remove(setOf("a", "missing")))
        assertEquals(listOf("b"), queue.due(10, 2_000L).map { it.fixId })
        assertEquals(0, queue.remove(emptySet()))
    }

    @Test fun `dropAll clears slots and all loss counters`() {
        val queue = ResilientFixQueue(capacity = 1)
        queue.enqueue(fix("a", 1_000L, 1_000L), 1_000L)
        queue.enqueue(fix("b", 2_000L, 2_000L), 2_000L)
        queue.loadLines(listOf("garbage"), 2_000L)
        queue.dropAll()
        val stats = queue.stats(2_000L)
        assertEquals(0, stats.depth)
        assertEquals(0L, stats.evictedTotal)
        assertEquals(0L, stats.expiredTotal)
        assertEquals(0L, stats.corruptTotal)
    }

    @Test fun `lines round-trip including hostile payload text`() {
        val queue = ResilientFixQueue()
        // Real control characters (newline, tab, U+0001), a real non-BMP-adjacent
        // snowman, literal backslashes, an embedded quote, and non-ASCII text.
        val hostile = "{\"a\":\"quote\\\" backslash\\\\ real\nline real\ttab snowman\u2603 ctrl\u0001 \u00e1rabe\"}"
        queue.enqueue(fix("a", 1_000L, 2_000L, attempts = 3, payload = hostile), 2_000L)
        val restored = ResilientFixQueue()
        assertEquals(0, restored.loadLines(queue.toLines(), 2_000L))
        val back = restored.due(10, 2_000L).single()
        assertEquals("a", back.fixId)
        assertEquals(1_000L, back.recordedAtEpochMillis)
        assertEquals(2_000L, back.enqueuedAtEpochMillis)
        assertEquals(3, back.attempts)
        assertEquals(hostile, back.payloadJson)
    }

    @Test fun `corrupt lines are dropped and counted, valid ones survive`() {
        val queue = ResilientFixQueue()
        val good = ResilientFixQueue()
        good.enqueue(fix("good", 1_000L, 1_000L), 1_000L)
        val lines = mutableListOf<String>()
        lines.addAll(good.toLines())
        lines.add("garbage")
        lines.add("")
        lines.add("{\"fixId\":\"x\"}") // Truncated: missing every other field.
        lines.add("{\"fixId\":\"\",\"recordedAt\":1,\"enqueuedAt\":1,\"attempts\":0,\"payload\":\"{}\"}") // Empty id.
        lines.add("{\"fixId\":\"x\",\"recordedAt\":-5,\"enqueuedAt\":1,\"attempts\":0,\"payload\":\"{}\"}") // Negative stamp.
        lines.add("{\"fixId\":\"x\",\"recordedAt\":1,\"enqueuedAt\":1,\"attempts\":0,\"payload\":\"\"}") // Empty payload.
        lines.add(good.toLines().single() + "trailing-junk")
        assertEquals(7, queue.loadLines(lines, 1_000L))
        assertEquals(listOf("good"), queue.due(10, 1_000L).map { it.fixId })
        assertEquals(7L, queue.stats(1_000L).corruptTotal)
    }

    @Test fun `restore expires stale fixes and evicts past capacity`() {
        val source = ResilientFixQueue()
        source.enqueue(fix("stale", 0L, 0L), 0L)
        source.enqueue(fix("a", 9_000L, 9_000L), 9_000L)
        source.enqueue(fix("b", 9_001L, 9_001L), 9_001L)
        val restored = ResilientFixQueue(capacity = 1, ttlMillis = 1_000L)
        assertEquals(0, restored.loadLines(source.toLines(), 9_500L))
        assertEquals(listOf("b"), restored.due(10, 9_500L).map { it.fixId })
        val stats = restored.stats(9_500L)
        assertEquals(1L, stats.expiredTotal)
        assertEquals(1L, stats.evictedTotal)
    }

    @Test fun `due honors a zero limit`() {
        val queue = ResilientFixQueue()
        queue.enqueue(fix("a", 1_000L, 1_000L), 1_000L)
        assertTrue(queue.due(0, 1_000L).isEmpty())
        assertTrue(queue.due(-3, 1_000L).isEmpty())
    }
}
