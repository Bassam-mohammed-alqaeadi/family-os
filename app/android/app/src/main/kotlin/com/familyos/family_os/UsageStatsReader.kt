package com.familyos.family_os

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import java.util.Calendar

/**
 * What one app cost today, in whole minutes.
 *
 * `categoryName` is already the server's own vocabulary (`games`, `social`, `edu`, `tools`)
 * and not Android's: the server refuses any other string (`validation.js` →
 * `APP_CATEGORY_VALUES`), so translating here is what keeps a report acceptable instead of
 * a 400 the family never sees.
 */
data class AppUsage(
    val packageName: String,
    val categoryName: String,
    val minutes: Int,
)

/**
 * The measurable half of screen time: no Context, no clock, no system service.
 *
 * Everything here is a pure function of its arguments, which is why a plain JVM test can
 * hold it to account without a phone. The Android-facing half is [UsageStatsReader].
 */
object UsageStatsAggregator {
    /** The server's own per-app ceiling (`MAX_USAGE_MINUTES_PER_APP`). */
    const val DAILY_CEILING_MINUTES: Int = 1440

    private const val MILLIS_PER_MINUTE: Long = 60_000L

    /**
     * Folds raw per-package foreground time into the rows a handset reports.
     *
     * Four decisions, each one a rule the family can be held to:
     *
     *   * a sample with no positive foreground time is not a measurement, so it is dropped;
     *   * minutes are whole and rounded **down**, because a phone must never claim a minute
     *     a child did not spend;
     *   * one app cannot exceed a day, whatever the device claims — `totalTimeInForeground`
     *     is cumulative since boot on some builds, and a figure that large would erase the
     *     whole allowance at once; and
     *   * the order is fixed (minutes descending, then package name) so the same day always
     *     produces the same report and a diff means a real change.
     *
     * Samples for the same package are summed before rounding, not after: two half-minutes
     * are one minute of screen time, and rounding each half to zero would under-report.
     */
    fun aggregate(
        samples: List<Triple<String, Long, String>>,
        limitMinutes: Int = DAILY_CEILING_MINUTES,
    ): List<AppUsage> {
        val ceiling = limitMinutes.coerceIn(0, DAILY_CEILING_MINUTES)
        val millisByPackage = LinkedHashMap<String, Long>()
        val categoryByPackage = HashMap<String, String>()

        for ((packageName, foregroundMillis, categoryName) in samples) {
            val name = packageName.trim()
            if (name.isEmpty() || foregroundMillis <= 0L) continue
            val previous = millisByPackage[name] ?: 0L
            millisByPackage[name] =
                if (previous > Long.MAX_VALUE - foregroundMillis) Long.MAX_VALUE
                else previous + foregroundMillis
            categoryByPackage.getOrPut(name) { categoryName }
        }

        val rows = ArrayList<AppUsage>(millisByPackage.size)
        for ((name, millis) in millisByPackage) {
            val minutes = (millis / MILLIS_PER_MINUTE)
                .coerceAtMost(ceiling.toLong())
                .toInt()
            if (minutes <= 0) continue
            rows.add(AppUsage(name, categoryByPackage[name].orEmpty(), minutes))
        }

        return rows.sortedWith(
            compareByDescending<AppUsage> { it.minutes }.thenBy { it.packageName },
        )
    }

    /**
     * Android's category as the server's word.
     *
     * The two countable buckets are named as themselves. Everything else is `tools` — the
     * third countable bucket — and the reason is not convenience: mapping an unknown app to
     * `edu` would make it non-countable, and since most apps on any phone are
     * `CATEGORY_UNDEFINED`, that choice would silently exempt an entire handset from every
     * limit it was given. Counting an app the family considers educational is a wrong the
     * family can see and fix on the app screen; exempting all of them is a wrong nobody can
     * see at all.
     */
    fun categoryFor(androidCategory: Int): String = when (androidCategory) {
        ANDROID_CATEGORY_GAME -> "games"
        ANDROID_CATEGORY_SOCIAL -> "social"
        else -> "tools"
    }

    /**
     * `ApplicationInfo.CATEGORY_*` values, written as numbers.
     *
     * Named here rather than imported so this object stays a pure function of its argument:
     * a JVM test can then call it without Android's mockable jar, where those constants are
     * not guaranteed to carry their real values.
     */
    const val ANDROID_CATEGORY_UNDEFINED: Int = -1
    const val ANDROID_CATEGORY_GAME: Int = 0
    const val ANDROID_CATEGORY_SOCIAL: Int = 8
}

/** The Android-facing half: reads what the phone measured, and nothing it guessed. */
object UsageStatsReader {
    /** True when the family granted "Usage access" to this app. */
    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        val mode = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
            }
        } catch (_: Exception) {
            return false
        }
        if (mode == AppOpsManager.MODE_ALLOWED) return true
        // Some manufacturer builds report MODE_DEFAULT for an access the person really
        // granted. The service is the only honest tie-breaker: if it answers with anything
        // at all, the access exists.
        if (mode != AppOpsManager.MODE_DEFAULT) return false
        return querySince(context, System.currentTimeMillis() - 7L * 24 * 60 * 60 * 1000)
            .isNotEmpty()
    }

    /**
     * Today's usage, in the device's own day.
     *
     * The start of the day is computed here rather than asked of the server because a phone
     * can be offline for a whole day, and a child's allowance must not wait for a network
     * call to know when its day began. The server still decides which day the report
     * belongs to (`usage_date`), so a handset with a wrong clock cannot invent a day.
     */
    fun readToday(context: Context, now: Long): List<AppUsage> {
        if (!hasUsageAccess(context)) return emptyList()
        val start = startOfDay(now)
        val samples = querySince(context, start, now)
        return UsageStatsAggregator.aggregate(samples)
    }

    private fun querySince(context: Context, start: Long, end: Long = System.currentTimeMillis()): List<Triple<String, Long, String>> {
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()
        val stats = try {
            manager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
        } catch (_: Exception) {
            return emptyList()
        } ?: return emptyList()
        val packageManager = context.packageManager
        val samples = ArrayList<Triple<String, Long, String>>(stats.size)
        for (entry in stats) {
            val name = entry?.packageName ?: continue
            samples.add(
                Triple(name, entry.totalTimeInForeground, categoryOf(packageManager, name)),
            )
        }
        return samples
    }

    private fun categoryOf(packageManager: PackageManager, packageName: String): String {
        val category = try {
            packageManager.getApplicationInfo(packageName, 0).category
        } catch (_: Exception) {
            UsageStatsAggregator.ANDROID_CATEGORY_UNDEFINED
        }
        return UsageStatsAggregator.categoryFor(category)
    }

    /** Midnight before [now], in this device's zone. */
    fun startOfDay(now: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = now
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}
