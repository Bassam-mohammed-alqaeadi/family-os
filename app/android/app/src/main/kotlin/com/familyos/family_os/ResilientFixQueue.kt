package com.familyos.family_os

/**
 * S2 resilience: the offline queue for location fixes that could not be sent.
 *
 * Android-free by design, so the ring/TTL/ordering rules are proven by plain JVM tests
 * (`ResilientFixQueueTest`), not by reading the source. Persistence and encryption live in
 * [EncryptedFixQueueStore]; this class only decides *what the queue means*.
 *
 * The rules:
 *
 *  1. Bounded in both dimensions (D2): at most [DEFAULT_CAPACITY] fixes, each kept at most
 *     [DEFAULT_TTL_MILLIS] past its own `recordedAt`. No unbounded growth, ever.
 *  2. Oldest-first, always: drain order is `(enqueuedAt, recordedAt, fixId)`, so a replay
 *     reaches the server in a deterministic order and the oldest knowledge is sent first.
 *  3. Loss is counted, never silent: every eviction, expiry and corrupt line increments a
 *     counter that the protection state machine and the server evidence can read.
 *     A queue that drops fixes without counting them is a queue that lies.
 *  4. One fix, one slot: re-enqueueing an already-queued `fixId` is a no-op (the idempotency
 *     key the server sees is derived from the same id, so a duplicate slot could never
 *     become a duplicate row - but it could evict somebody else's fix).
 *  5. Payload-opaque: the queue never parses `payloadJson` (it is the exact body the
 *     protocol built, with the corrected `recordedAt` baked in). Corrupt framing drops the
 *     line; corrupt payload is the server's 400 to make, honestly.
 */
class ResilientFixQueue(
    val capacity: Int = DEFAULT_CAPACITY,
    val ttlMillis: Long = DEFAULT_TTL_MILLIS,
) {
    companion object {
        /** D2: at most this many unsent fixes are kept; the oldest is evicted first. */
        const val DEFAULT_CAPACITY = 2000

        /** D2: a fix older than this past its own `recordedAt` is expired, not sent. */
        const val DEFAULT_TTL_MILLIS = 48L * 60 * 60 * 1000

        private val ORDER = Comparator<QueuedFix> { a, b ->
            var order = a.enqueuedAtEpochMillis.compareTo(b.enqueuedAtEpochMillis)
            if (order != 0) return@Comparator order
            order = a.recordedAtEpochMillis.compareTo(b.recordedAtEpochMillis)
            if (order != 0) return@Comparator order
            a.fixId.compareTo(b.fixId)
        }
    }

    private val fixes = ArrayList<QueuedFix>()

    /** Fixes evicted by the capacity bound since this queue was created or cleared. */
    var evictedTotal: Long = 0
        private set

    /** Fixes that aged past the TTL (at enqueue or at drain time). */
    var expiredTotal: Long = 0
        private set

    /** Restored lines that failed framing validation (see [loadLines]). */
    var corruptTotal: Long = 0
        private set

    /**
     * Offers one fix. A fix already older than the TTL is refused (counted, not stored);
     * an already-queued id is acknowledged without duplicating the slot.
     */
    fun enqueue(fix: QueuedFix, nowMillis: Long): EnqueueReport {
        pruneExpired(nowMillis)
        if (nowMillis - fix.recordedAtEpochMillis > ttlMillis) {
            expiredTotal++
            return EnqueueReport(accepted = false, evicted = emptyList(), rejectedStale = true)
        }
        if (fixes.any { it.fixId == fix.fixId }) {
            return EnqueueReport(accepted = true, evicted = emptyList(), rejectedStale = false)
        }
        fixes.add(fix)
        fixes.sortWith(ORDER)
        val evicted = ArrayList<QueuedFix>()
        while (fixes.size > capacity) {
            evicted.add(fixes.removeAt(0))
            evictedTotal++
        }
        return EnqueueReport(accepted = true, evicted = evicted, rejectedStale = false)
    }

    /** The next fixes to send, oldest first, after expiring what aged out. */
    fun due(limit: Int, nowMillis: Long): List<QueuedFix> {
        pruneExpired(nowMillis)
        if (limit <= 0) return emptyList()
        return fixes.take(limit.coerceAtMost(fixes.size))
    }

    /** Removes acknowledged fixes; returns how many were actually present. */
    fun remove(fixIds: Set<String>): Int {
        if (fixIds.isEmpty()) return 0
        val before = fixes.size
        fixes.removeAll { fixIds.contains(it.fixId) }
        return before - fixes.size
    }

    /**
     * Drops everything including the loss counters: a new pairing means a new session and
     * new accounting. Called on revocation and on re-pairing - never on a transient error.
     */
    fun dropAll() {
        fixes.clear()
        evictedTotal = 0
        expiredTotal = 0
        corruptTotal = 0
    }

    fun stats(nowMillis: Long): QueueStats {
        pruneExpired(nowMillis)
        return QueueStats(
            depth = fixes.size,
            evictedTotal = evictedTotal,
            expiredTotal = expiredTotal,
            corruptTotal = corruptTotal,
        )
    }

    /** Serializes every slot, oldest first. See [loadLines] for the framing contract. */
    fun toLines(): List<String> = fixes.sortedWith(ORDER).map { lineFor(it) }

    /**
     * Restores slots from [lines], replacing any current content. Lines that fail framing
     * validation are dropped and counted in [corruptTotal]; the return value is that count
     * for this call. Stale fixes are expired (counted in [expiredTotal]), never revived.
     */
    fun loadLines(lines: List<String>, nowMillis: Long): Int {
        fixes.clear()
        var corrupt = 0
        for (line in lines) {
            val fix = parseLine(line)
            if (fix == null) {
                corrupt++
                continue
            }
            if (nowMillis - fix.recordedAtEpochMillis > ttlMillis) {
                expiredTotal++
                continue
            }
            if (fixes.none { it.fixId == fix.fixId }) fixes.add(fix)
        }
        fixes.sortWith(ORDER)
        while (fixes.size > capacity) {
            fixes.removeAt(0)
            evictedTotal++
        }
        corruptTotal += corrupt
        return corrupt
    }

    private fun pruneExpired(nowMillis: Long) {
        val before = fixes.size
        fixes.removeAll { nowMillis - it.recordedAtEpochMillis > ttlMillis }
        expiredTotal += (before - fixes.size)
    }

    // -- Framing: one strict JSON object per line, fixed key order. -------------------------
    // Hand-rolled (no org.json on the plain JVM): the writer and this reader are tested as
    // a pair, and anything the reader does not accept byte-for-byte is corrupt, not guessed.

    private fun lineFor(fix: QueuedFix): String = buildString {
        append("{\"fixId\":\"").append(escape(fix.fixId)).append("\",")
        append("\"recordedAt\":").append(fix.recordedAtEpochMillis).append(',')
        append("\"enqueuedAt\":").append(fix.enqueuedAtEpochMillis).append(',')
        append("\"attempts\":").append(fix.attempts).append(',')
        append("\"payload\":\"").append(escape(fix.payloadJson)).append("\"}")
    }

    private fun parseLine(line: String): QueuedFix? {
        val reader = LineReader(line)
        if (!reader.expect("{\"fixId\":\"")) return null
        val fixId = reader.quoted() ?: return null
        // quoted() consumed the closing quote; the literal resumes after it.
        if (!reader.expect(",\"recordedAt\":")) return null
        val recordedAt = reader.number() ?: return null
        if (!reader.expect(",\"enqueuedAt\":")) return null
        val enqueuedAt = reader.number() ?: return null
        if (!reader.expect(",\"attempts\":")) return null
        val attempts = reader.number() ?: return null
        if (!reader.expect(",\"payload\":\"")) return null
        val payload = reader.quoted() ?: return null
        // quoted() consumed the closing quote; only the brace remains.
        if (!reader.expect("}")) return null
        if (!reader.atEnd()) return null
        if (fixId.isEmpty() || payload.isEmpty()) return null
        if (recordedAt <= 0L || enqueuedAt < 0L || attempts < 0L) return null
        if (attempts > Int.MAX_VALUE) return null
        return QueuedFix(
            fixId = fixId,
            recordedAtEpochMillis = recordedAt,
            enqueuedAtEpochMillis = enqueuedAt,
            attempts = attempts.toInt(),
            payloadJson = payload,
        )
    }

    private fun escape(value: String): String = buildString(value.length + 8) {
        for (char in value) {
            when (char) {
                '"' -> append("\\\"")
                '\\' -> append("\\\\")
                '\n' -> append("\\n")
                '\r' -> append("\\r")
                '\t' -> append("\\t")
                else -> if (char < ' ') append("\\u%04x".format(char.code)) else append(char)
            }
        }
    }

    /** Strict cursor reader: anything unexpected returns null, never a guess. */
    private class LineReader(private val line: String) {
        private var index = 0

        fun atEnd(): Boolean = index == line.length

        fun expect(literal: String): Boolean {
            if (!line.startsWith(literal, index)) return false
            index += literal.length
            return true
        }

        fun number(): Long? {
            val start = index
            while (index < line.length && line[index] in '0'..'9') index++
            if (start == index || index - start > 19) return null
            return line.substring(start, index).toLongOrNull()
        }

        fun quoted(): String? {
            val out = StringBuilder()
            while (index < line.length) {
                val char = line[index++]
                when {
                    char == '"' -> return out.toString()
                    char != '\\' -> {
                        if (char < ' ') return null
                        out.append(char)
                    }
                    index >= line.length -> return null
                    else -> when (val escaped = line[index++]) {
                        '"', '\\', '/' -> out.append(escaped)
                        'n' -> out.append('\n')
                        'r' -> out.append('\r')
                        't' -> out.append('\t')
                        'u' -> {
                            if (index + 4 > line.length) return null
                            val code = line.substring(index, index + 4).toIntOrNull(16) ?: return null
                            index += 4
                            out.append(code.toChar())
                        }
                        else -> return null
                    }
                }
            }
            return null
        }
    }
}

/** One unsent fix. `payloadJson` is the exact protocol body, corrected `recordedAt` baked in. */
data class QueuedFix(
    val fixId: String,
    val recordedAtEpochMillis: Long,
    val enqueuedAtEpochMillis: Long,
    val attempts: Int,
    val payloadJson: String,
)

data class EnqueueReport(
    val accepted: Boolean,
    val evicted: List<QueuedFix>,
    val rejectedStale: Boolean,
)

data class QueueStats(
    val depth: Int,
    val evictedTotal: Long,
    val expiredTotal: Long,
    val corruptTotal: Long,
)
