package com.familyos.family_os

import java.io.File
import java.io.IOException

/**
 * S2 resilience: the durable, encrypted offline queue.
 *
 * Android-free (the file is injected, the cipher is injected), so the whole
 * persist/reload/drop behaviour is proven by plain JVM tests (`EncryptedFixQueueStoreTest`)
 * with a fake cipher and a temp directory. Production wires it with the queue file under
 * `noBackupFilesDir` and [KeystoreFixQueueCipher] in D2.
 *
 * Durability rules (same crash-safety as `TelemetryConfigStore`):
 *
 *  1. Atomic writes: every mutation persists through a sibling file renamed over the old
 *     one. A reader - or a crash mid-write - sees the old queue or the new one, never a
 *     half-written blob.
 *  2. Lazy load, once: the file is read on first use. An unreadable blob (tampered,
 *     pre-unlock Keystore, truncated write from an older build) counts one [loadFailures]
 *     and starts empty - the service keeps running and the state machine reports the
 *     loss honestly instead of crashing.
 *  3. Persist failures are counted ([persistFailures]), not thrown: memory keeps serving
 *     drains and the next mutation retries the write.
 *  4. Revocation deletes: [dropAll] removes the rows *and* the file (best effort), so a
 *     dead session's fixes cannot linger on disk.
 *
 * Threading: every method holds [lock]. Calls perform bounded I/O (the blob is capped by
 * queue capacity); callers must not hold other locks while calling in.
 */
class EncryptedFixQueueStore(
    private val file: File,
    private val cipher: FixQueueCipher,
    private val lock: Any = Any(),
    private val clock: () -> Long = { System.currentTimeMillis() },
    capacity: Int = ResilientFixQueue.DEFAULT_CAPACITY,
    ttlMillis: Long = ResilientFixQueue.DEFAULT_TTL_MILLIS,
) : FixQueuePort {
    private val queue = ResilientFixQueue(capacity, ttlMillis)
    private var loaded = false

    /** Blob reads that failed (counted, never thrown). See rule 2. */
    var loadFailures: Int = 0
        private set

    /** Blob writes that failed (counted, never thrown). See rule 3. */
    var persistFailures: Int = 0
        private set

    override fun enqueue(fix: QueuedFix, nowMillis: Long): EnqueueReport = synchronized(lock) {
        ensureLoaded()
        val report = queue.enqueue(fix, nowMillis)
        persist()
        report
    }

    override fun due(limit: Int, nowMillis: Long): List<QueuedFix> = synchronized(lock) {
        ensureLoaded()
        queue.due(limit, nowMillis)
    }

    override fun remove(fixIds: Set<String>): Unit = synchronized(lock) {
        ensureLoaded()
        if (queue.remove(fixIds) > 0) persist()
    }

    override fun dropAll(): Unit = synchronized(lock) {
        loaded = true // A dropped session must not resurrect the file it just deleted.
        queue.dropAll()
        try {
            if (file.exists() && !file.delete()) persistFailures++
        } catch (_: Exception) {
            persistFailures++
        }
    }

    override fun stats(nowMillis: Long): QueueStats = synchronized(lock) {
        ensureLoaded()
        queue.stats(nowMillis)
    }

    private fun ensureLoaded() {
        if (loaded) return
        loaded = true
        try {
            if (!file.exists()) return
            val blob = file.readBytes()
            if (blob.isEmpty()) return
            val plain = cipher.decrypt(blob)
            val lines = String(plain, Charsets.UTF_8).split('\n').filter { it.isNotEmpty() }
            queue.loadLines(lines, clock())
        } catch (_: Exception) {
            loadFailures++
        }
    }

    private fun persist() {
        try {
            val plain = queue.toLines().joinToString("\n").toByteArray(Charsets.UTF_8)
            atomicWrite(file, cipher.encrypt(plain))
        } catch (_: Exception) {
            persistFailures++
        }
    }

    private fun atomicWrite(target: File, bytes: ByteArray) {
        val parent = target.absoluteFile.parentFile ?: throw IOException("queue file has no parent")
        val staging = File(parent, target.name + ".tmp")
        staging.writeBytes(bytes)
        if (!staging.renameTo(target)) {
            staging.delete()
            throw IOException("queue could not be stored")
        }
    }
}
