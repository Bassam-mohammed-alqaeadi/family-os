package com.familyos.family_os

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * S2 resilience: re-activates the child's protection after reboot, app update and unlock.
 *
 * Four gates, all checked on every wake - a wake that fails a gate stops silently or
 * tells the person holding the phone, but never starts collection it must not run:
 *
 *  1. Background location is still granted (revoked = stopping is the honest state; and
 *     Android 14+ only allows a background start of a location foreground service with
 *     this grant at all).
 *  2. A pairing is stored (Keystore readable - post-unlock only).
 *  3. The revocation mark is clear (the same SharedPreferences view the service uses).
 *  4. The crash-loop backoff ([BootBackoff]) is not exhausted; deferred attempts come
 *     back through an inexact alarm ([ACTION_BOOT_RETRY]), never a wake lock loop.
 *
 * Direct boot ([Intent.ACTION_LOCKED_BOOT_COMPLETED]) records only a marker in
 * device-protected storage: before first unlock there is no Keystore key and no pairing
 * readable, so starting - or claiming - protection there would be a lie (D3). The real
 * work runs on [Intent.ACTION_USER_UNLOCKED] / [Intent.ACTION_BOOT_COMPLETED].
 *
 * Zero-crash guarantee: the whole body is guarded - a receiver must never kill a system
 * broadcast, and every platform call that can throw (Keystore, alarms, notifications) is
 * wrapped where it happens.
 */
class ProtectionBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            when (intent?.action) {
                Intent.ACTION_LOCKED_BOOT_COMPLETED -> recordLockedBoot(context)
                ACTION_BOOT_RETRY -> tryStart(context.applicationContext, fromRetry = true)
                Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED,
                Intent.ACTION_USER_UNLOCKED -> tryStart(context.applicationContext, fromRetry = false)
                else -> Unit
            }
        } catch (_: Exception) {
            // Never propagate out of a receiver.
        }
    }

    private fun recordLockedBoot(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return // Direct boot is 24+.
        try {
            context.createDeviceProtectedStorageContext()
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putLong(KEY_LOCKED_BOOT_AT, System.currentTimeMillis())
                .apply()
        } catch (_: Exception) {
            // A missing marker only means "no measured boot gap" in the next heartbeat.
        }
    }

    private fun tryStart(app: Context, fromRetry: Boolean) {
        if (!hasBackgroundLocation(app)) return
        val config = try {
            TelemetryConfigStore(app).read()
        } catch (_: Exception) {
            null
        } ?: return
        if (config.deviceId.isBlank()) return
        try {
            if (LocationReportStatusStore(app).credentialRevoked()) return
        } catch (_: Exception) {
            return // Doubt about revocation fails closed: do not start.
        }
        val attempts = bootAttempts(app)
        if (BootBackoff.exhausted(attempts)) {
            postBootNotice(app)
            return
        }
        if (!fromRetry) {
            val delay = BootBackoff.delayMillis(attempts)
            if (delay > 0L) {
                setBootAttempts(app, attempts + 1)
                scheduleRetry(app, delay)
                return
            }
        }
        setBootAttempts(app, attempts + 1)
        try {
            ContextCompat.startForegroundService(
                app,
                Intent(app, ChildTelemetryService::class.java)
                    .putExtra(ChildTelemetryService.EXTRA_BOOT_START, true),
            )
        } catch (_: Exception) {
            // Strict OEMs/APIs can still refuse a background foreground-service start:
            // tell the person to open the app once instead of pretending it worked.
            postBootNotice(app)
        }
    }

    private fun hasBackgroundLocation(app: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return ContextCompat.checkSelfPermission(app, android.Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
        }
        return ContextCompat.checkSelfPermission(app, android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun scheduleRetry(app: Context, delayMillis: Long) {
        try {
            val alarm = app.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val retry = PendingIntent.getBroadcast(
                app,
                RETRY_REQUEST_CODE,
                Intent(app, ProtectionBootReceiver::class.java).setAction(ACTION_BOOT_RETRY),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val triggerAt = SystemClock.elapsedRealtime() + delayMillis
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarm.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, retry)
            } else {
                @Suppress("DEPRECATION")
                alarm.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, retry)
            }
        } catch (_: Exception) {
            // No alarm = this attempt is lost; the next unlock or launch retries.
        }
    }

    /** Tells the person holding the phone to open the app once; never claims more. */
    private fun postBootNotice(app: Context) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                ContextCompat.checkSelfPermission(app, android.Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            ensureStoppedChannel(app)
            val launch = app.packageManager.getLaunchIntentForPackage(app.packageName)
            val tap = launch?.let {
                PendingIntent.getActivity(
                    app,
                    0,
                    it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            }
            val notification = NotificationCompat.Builder(app, ChildTelemetryService.STOPPED_CHANNEL_ID)
                .setSmallIcon(com.familyos.family_os.R.mipmap.ic_launcher)
                .setContentTitle(app.getString(R.string.location_sharing_stopped_title))
                .setContentText(app.getString(R.string.protection_boot_exhausted_text))
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .bigText(app.getString(R.string.protection_boot_exhausted_text)),
                )
                .setContentIntent(tap)
                .setAutoCancel(true)
                .build()
            NotificationManagerCompat.from(app).notify(BOOT_NOTICE_ID, notification)
        } catch (_: Exception) {
            // Notification permission withdrawn mid-flight; the in-app status still says it.
        }
    }

    private fun ensureStoppedChannel(app: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(
                NotificationChannel(
                    ChildTelemetryService.STOPPED_CHANNEL_ID,
                    app.getString(R.string.location_sharing_stopped_channel_name),
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
        } catch (_: Exception) {
            // Channel creation failing means the notice below fails too; both are caught.
        }
    }

    companion object {
        const val ACTION_BOOT_RETRY = "com.familyos.family_os.action.BOOT_RETRY"

        private const val PREFS = "family_os_protection_boot"
        private const val KEY_ATTEMPTS = "boot_attempts"
        private const val KEY_LOCKED_BOOT_AT = "locked_boot_at"
        private const val RETRY_REQUEST_CODE = 91301
        private const val BOOT_NOTICE_ID = 91302

        private fun prefs(app: Context) =
            app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun bootAttempts(app: Context): Int = try {
            prefs(app).getInt(KEY_ATTEMPTS, 0).coerceAtLeast(0)
        } catch (_: Exception) {
            0
        }

        fun setBootAttempts(app: Context, attempts: Int) {
            try {
                prefs(app).edit().putInt(KEY_ATTEMPTS, attempts.coerceAtLeast(0)).apply()
            } catch (_: Exception) {
                // A counter that cannot persist only loses pacing, never safety.
            }
        }

        /**
         * Takes (reads + clears) the direct-boot marker, or null when there is none.
         * Called by the service on a boot start so the next heartbeat can report the
         * measured gap between locked boot and real protection - evidence, not a guess.
         */
        fun takeLockedBootAt(app: Context): Long? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null
            return try {
                val devicePrefs = app.createDeviceProtectedStorageContext()
                    .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val at = devicePrefs.getLong(KEY_LOCKED_BOOT_AT, 0L)
                devicePrefs.edit().remove(KEY_LOCKED_BOOT_AT).apply()
                if (at > 0L) at else null
            } catch (_: Exception) {
                null
            }
        }
    }
}
