package com.familyos.family_os

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import java.util.Calendar

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
