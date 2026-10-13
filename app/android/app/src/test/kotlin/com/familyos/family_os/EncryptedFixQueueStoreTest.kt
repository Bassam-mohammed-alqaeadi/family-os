package com.familyos.family_os

import java.io.File
import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Behaviour of the S2 durable queue with a fake cipher and temp directories: atomic
 * persist/reload, counted (never thrown) failures, and revocation that deletes the file.
 * The production Keystore cipher is Android-only and stays out of these tests by design -
 * what is proven here is the store's crash-safety and honesty around *any* cipher.
 */
class EncryptedFixQueueStoreTest {
    /** Reversible scrambling with a magic prefix, so garbage blobs fail loudly. */
    private class FakeCipher : FixQueueCipher {
        override fun encrypt(plain: ByteArray): ByteArray =
            ("Q1" + String(plain, Charsets.UTF_8)).map { (it.code xor 0x5A).toChar() }
                .joinToString("").toByteArray(Charsets.UTF_8)

        override fun decrypt(blob: ByteArray): ByteArray {
            val unscrambled = String(blob, Charsets.UTF_8).map { (it.code xor 0x5A).toChar() }
                .joinToString("")
            check(unscrambled.startsWith("Q1")) { "not a queue blob" }
            return unscrambled.substring(2).toByteArray(Charsets.UTF_8)
        }
    }

    private class FailingCipher : FixQueueCipher {
        override fun encrypt(plain: ByteArray): ByteArray = throw IllegalStateException("no key")
        override fun decrypt(blob: ByteArray): ByteArray = throw IllegalStateException("no key")
    }

    private fun withTempDir(block: (File) -> Unit) {
        val dir = Files.createTempDirectory("s2-queue-test").toFile()
        try {
            block(dir)
        } finally {
            dir.deleteRecursively()
        }
    }

    private fun fix(id: String, recordedAt: Long, enqueuedAt: Long) =
        QueuedFix(id, recordedAt, enqueuedAt, 0, "{\"fixId\":\"$id\"}")

    @Test fun `enqueued fixes survive a store restart in order`() {
        withTempDir { dir ->
            val file = File(dir, "fix-queue.v1")
            val first = EncryptedFixQueueStore(file, FakeCipher(), clock = { 10_000L })
            first.enqueue(fix("b", 2_000L, 2_000L), 10_000L)
            first.enqueue(fix("a", 1_000L, 1_000L), 10_000L)
            assertTrue(file.exists())

            val second = EncryptedFixQueueStore(file, FakeCipher(), clock = { 10_000L })
            assertEquals(listOf("a", "b"), second.due(10, 10_000L).map { it.fixId })
            assertEquals(0, second.loadFailures)
            assertEquals(0, second.persistFailures)
        }
    }

    @Test fun `a missing file starts empty without a failure`() {
        withTempDir { dir ->
            val store = EncryptedFixQueueStore(File(dir, "fix-queue.v1"), FakeCipher())
            assertTrue(store.due(10, 1_000L).isEmpty())
            assertEquals(0, store.loadFailures)
        }
    }

    @Test fun `a garbage blob counts one load failure and starts empty`() {
        withTempDir { dir ->
            val file = File(dir, "fix-queue.v1")
            file.writeBytes("not a queue blob at all".toByteArray(Charsets.UTF_8))
            val store = EncryptedFixQueueStore(file, FakeCipher(), clock = { 1_000L })
            assertTrue(store.due(10, 1_000L).isEmpty())
            assertEquals(1, store.loadFailures)
            // And the service keeps working: new fixes queue in memory.
            store.enqueue(fix("a", 1_000L, 1_000L), 1_000L)
            assertEquals(1, store.due(10, 1_000L).size)
        }
    }

    @Test fun `a failing cipher counts persist failures but memory keeps serving`() {
        withTempDir { dir ->
            val store = EncryptedFixQueueStore(File(dir, "fix-queue.v1"), FailingCipher())
            store.enqueue(fix("a", 1_000L, 1_000L), 1_000L)
            assertEquals(1, store.persistFailures)
            // Nothing was thrown and the in-memory queue still drains.
            assertEquals(listOf("a"), store.due(10, 1_000L).map { it.fixId })
        }
    }

    @Test fun `removals persist across restarts`() {
        withTempDir { dir ->
            val file = File(dir, "fix-queue.v1")
            val first = EncryptedFixQueueStore(file, FakeCipher(), clock = { 10_000L })
            first.enqueue(fix("a", 1_000L, 1_000L), 10_000L)
            first.enqueue(fix("b", 2_000L, 2_000L), 10_000L)
            first.remove(setOf("a"))
            val second = EncryptedFixQueueStore(file, FakeCipher(), clock = { 10_000L })
            assertEquals(listOf("b"), second.due(10, 10_000L).map { it.fixId })
        }
    }

    @Test fun `dropAll clears memory and deletes the file`() {
        withTempDir { dir ->
            val file = File(dir, "fix-queue.v1")
            val store = EncryptedFixQueueStore(file, FakeCipher(), clock = { 10_000L })
            store.enqueue(fix("a", 1_000L, 1_000L), 10_000L)
            assertTrue(file.exists())
            store.dropAll()
            assertFalse(file.exists())
            assertTrue(store.due(10, 10_000L).isEmpty())
            // A later store on the same path finds nothing to resurrect.
            val later = EncryptedFixQueueStore(file, FakeCipher(), clock = { 10_000L })
            assertTrue(later.due(10, 10_000L).isEmpty())
            assertEquals(0, later.loadFailures)
        }
    }

    @Test fun `stale fixes are refused through the store`() {
        withTempDir { dir ->
            val store = EncryptedFixQueueStore(
                File(dir, "fix-queue.v1"),
                FakeCipher(),
                ttlMillis = 1_000L,
            )
            val report = store.enqueue(fix("old", 0L, 5_000L), 5_000L)
            assertFalse(report.accepted)
            assertEquals(1L, store.stats(5_000L).expiredTotal)
        }
    }
}
