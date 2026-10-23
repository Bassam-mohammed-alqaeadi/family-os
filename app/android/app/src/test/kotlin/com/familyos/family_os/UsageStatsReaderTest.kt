package com.familyos.family_os

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The measurement rules a family is held to, proven without a phone.
 *
 * Every case here is a way a screen-time figure becomes a lie: a negative sample, a
 * rounding that invents a minute, a cumulative counter that exceeds a day, or an order
 * that makes two identical days look different.
 */
class UsageStatsReaderTest {

    private fun sample(packageName: String, minutes: Long, category: String = "games") =
        Triple(packageName, minutes * 60_000L, category)

    @Test
    fun `zero and negative samples are dropped`() {
        val rows = UsageStatsAggregator.aggregate(
            listOf(
                Triple("com.zero.app", 0L, "games"),
                Triple("com.negative.app", -60_000L, "games"),
                sample("com.real.app", 5),
            ),
        )

        assertEquals(listOf("com.real.app"), rows.map { it.packageName })
    }

    @Test
    fun `minutes are floored and sub-minute usage is not a minute`() {
        val rows = UsageStatsAggregator.aggregate(
            listOf(
                // 59.999 s is not a minute, and must not become one.
                Triple("com.almost.app", 59_999L, "games"),
            ),
        )
        assertTrue(rows.isEmpty())

        // Two halves of a minute are one minute: rounding each half to zero would
        // under-report a child's real screen time.
        val halves = UsageStatsAggregator.aggregate(
            listOf(
                Triple("com.split.app", 30_000L, "games"),
                Triple("com.split.app", 30_000L, "games"),
            ),
        )
        assertEquals(1, halves.single().minutes)

        val floored = UsageStatsAggregator.aggregate(
            listOf(Triple("com.long.app", 5L * 60_000L + 59_999L, "social")),
        )
        assertEquals(5, floored.single().minutes)
    }

    @Test
    fun `one app cannot exceed the daily ceiling`() {
        // Ten days of foreground time on one package: a cumulative counter since boot,
        // not a day, and not something a family should ever be shown.
        val rows = UsageStatsAggregator.aggregate(
            listOf(sample("com.stuck.app", 14_400)),
        )

        assertEquals(UsageStatsAggregator.DAILY_CEILING_MINUTES, rows.single().minutes)

        val lowered = UsageStatsAggregator.aggregate(
            listOf(sample("com.stuck.app", 600)),
            limitMinutes = 60,
        )
        assertEquals(60, lowered.single().minutes)
    }

    @Test
    fun `the order is stable by minutes then package name`() {
        val rows = UsageStatsAggregator.aggregate(
            listOf(
                sample("com.zebra.app", 10),
                sample("com.alpha.app", 10),
                sample("com.middle.app", 30),
            ),
        )

        assertEquals(
            listOf("com.middle.app", "com.alpha.app", "com.zebra.app"),
            rows.map { it.packageName },
        )

        // The same day, listed in another order, must produce the same report.
        val reversed = UsageStatsAggregator.aggregate(
            listOf(
                sample("com.middle.app", 30),
                sample("com.zebra.app", 10),
                sample("com.alpha.app", 10),
            ),
        )
        assertEquals(rows, reversed)
    }

    @Test
    fun `a category is only what android says and everything else is tools`() {
        assertEquals(
            "games",
            UsageStatsAggregator.categoryFor(UsageStatsAggregator.ANDROID_CATEGORY_GAME),
        )
        assertEquals(
            "social",
            UsageStatsAggregator.categoryFor(UsageStatsAggregator.ANDROID_CATEGORY_SOCIAL),
        )
        // Undefined is the state of most apps on any phone. It must not become `edu`:
        // `edu` is not countable, so that choice would exempt a whole handset.
        assertEquals(
            "tools",
            UsageStatsAggregator.categoryFor(UsageStatsAggregator.ANDROID_CATEGORY_UNDEFINED),
        )
        assertEquals(
            "tools",
            UsageStatsAggregator.categoryFor(2),
        )
        // The server refuses any other word, so the aggregator never invents one.
        for (category in listOf(
            UsageStatsAggregator.ANDROID_CATEGORY_UNDEFINED,
            UsageStatsAggregator.ANDROID_CATEGORY_GAME,
            UsageStatsAggregator.ANDROID_CATEGORY_SOCIAL,
            1,
            2,
            6,
        )) {
            assertTrue(
                UsageStatsAggregator.categoryFor(category) in
                    setOf("games", "social", "edu", "tools"),
            )
        }
    }
}
