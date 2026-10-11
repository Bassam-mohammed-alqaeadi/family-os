package com.familyos.family_os

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * S0 spine — honest capability snapshot built from Android-native signals only.
 *
 * This file is the SOLE AUTHORITY for capability states that Dart cannot observe
 * truthfully (PACKAGE_USAGE_STATS, SYSTEM_ALERT_WINDOW, Accessibility,
 * boot receiver, DeviceAdmin, battery optimizations, overlay). It is called from
 * MainActivity over the existing MethodChannel so the Dart client can report
 * a ledger row per capability without inventing values.
 *
 * Rule R4 — no invented values: every key returns one of the six ledger states
 * with a short `evidence` string the guardian sees. Unknown capabilities are
 * omitted; a capability the Dart caller asks about that we cannot measure
 * answers `unsupported` with evidence "not-measured-native".
 */
object NativeCapabilitySnapshot {

    // Wire names must stay in lock-step with the ledger ENUM (migration 117)
    // and with FoundationGateCapabilityKey on the Dart side.
    const val KEY_INSTANT_LOCK = "instant_lock"
    const val KEY_WEB_FILTER_VPN = "web_filter_vpn"
    const val KEY_BACKGROUND_LOCATION = "background_location"
    const val KEY_PUSH_DELIVERY = "push_delivery"
    const val KEY_BOOT_PERSISTENCE = "boot_persistence"
    const val KEY_USAGE_METERING = "usage_metering"
    const val KEY_APP_INVENTORY = "app_inventory"
    const val KEY_APP_BLOCK_OVERLAY = "app_block_overlay"
    const val KEY_ACCESSIBILITY_ENFORCEMENT = "accessibility_enforcement"
    const val KEY_BATTERY_REPORTING = "battery_reporting"
    const val KEY_TAMPER_SIGNALS = "tamper_signals"

    data class CapabilityRow(
        val capabilityKey: String,
        val state: String,
        val evidence: String? = null,
        val confirmedAtEpoch: Long? = null,
    )

    /**
     * Build an honest snapshot for every S0 capability this platform can evaluate.
     *
     * Dart-side defaults (push_delivery from FCM token, instant_lock service binding)
     * are *merged in* by the MethodChannel handler after this returns — the native
     * side never claims a capability it cannot see from Android APIs.
     */
    fun snapshot(context: Context): List<CapabilityRow> {
        val now = System.currentTimeMillis()
        val rows = mutableListOf<CapabilityRow>()

        // background_location — truth from Android runtime permissions.
        rows += if (ContextCompat.checkSelfPermission(
                context, android.Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            CapabilityRow(KEY_BACKGROUND_LOCATION, "permission_needed", "ACCESS_FINE_LOCATION not granted")
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(
                context, android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            CapabilityRow(KEY_BACKGROUND_LOCATION, "permission_needed", "ACCESS_BACKGROUND_LOCATION not granted")
        } else {
            CapabilityRow(KEY_BACKGROUND_LOCATION, "confirmed", "runtime permissions granted", now)
        }

        // app_block_overlay — SYSTEM_ALERT_WINDOW.
        rows += if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Settings.canDrawOverlays(context)) {
                CapabilityRow(KEY_APP_BLOCK_OVERLAY, "confirmed", "canDrawOverlays=true", now)
            } else {
                CapabilityRow(KEY_APP_BLOCK_OVERLAY, "permission_needed", "SYSTEM_ALERT_WINDOW denied")
            }
        } else {
            // Pre-M overlays are implicit; mark confirmed.
            CapabilityRow(KEY_APP_BLOCK_OVERLAY, "confirmed", "legacy overlay available", now)
        }

        // usage_metering — PACKAGE_USAGE_STATS via AppOpsManager.
        rows += run {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName,
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName,
                )
            }
            if (mode == AppOpsManager.MODE_ALLOWED) {
                CapabilityRow(KEY_USAGE_METERING, "confirmed", "USAGE_STATS allowed", now)
            } else {
                CapabilityRow(KEY_USAGE_METERING, "permission_needed", "USAGE_STATS denied")
            }
        }

        // accessibility_enforcement — is our AccessibilityService enabled?
        rows += run {
            val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
            val enabled = am.getEnabledAccessibilityServiceList(
                AccessibilityServiceInfo.FEEDBACK_GENERIC
            ).any { it.resolveInfo.serviceInfo.packageName == context.packageName }
            if (enabled) {
                CapabilityRow(KEY_ACCESSIBILITY_ENFORCEMENT, "confirmed", "AccessibilityService enabled", now)
            } else {
                CapabilityRow(KEY_ACCESSIBILITY_ENFORCEMENT, "awaiting_setup", "AccessibilityService not enabled")
            }
        }

        // boot_persistence — can we receive BOOT_COMPLETED? We probe by querying the
        // package manager for a receiver class declared in this package; if no such
        // component exists yet the answer is `unsupported` rather than a lie.
        rows += run {
            val pm = context.packageManager
            val receiverClass = "com.familyos.family_os.FamilyOsBootReceiver"
            val cn = ComponentName(context.packageName, receiverClass)
            val enabled = try {
                val info = pm.getReceiverInfo(cn, 0)
                info != null && pm.getComponentEnabledSetting(cn) != PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
            if (enabled) {
                CapabilityRow(KEY_BOOT_PERSISTENCE, "confirmed", "BOOT_COMPLETED receiver enabled", now)
            } else {
                CapabilityRow(KEY_BOOT_PERSISTENCE, "unsupported", "boot receiver not yet declared")
            }
        }

        // battery_reporting — do we have a live battery intent source? This is
        // always available to an installed app unless the vendor force-stopped us,
        // which Android signals via package restart. We mark confirmed as soon as
        // the telemetry service reports having received at least one sticky broadcast.
        rows += CapabilityRow(
            KEY_BATTERY_REPORTING,
            "unknown",
            "native snapshot cannot confirm the sticky broadcast has been received; Dart fills from TelemetryService",
        )

        // app_inventory — QUERY_ALL_PACKAGES on R+ or normal package queries on older.
        rows += run {
            val canQuery = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.packageManager.canRequestPackageInstalls() ||
                    (context.applicationInfo.targetSdkVersion < 30)
            } else {
                true
            }
            // Even without QUERY_ALL_PACKAGES we can still get the running task list
            // via UsageStats; mark confirmed only when usage metering is granted and
            // inventory is queryable. Otherwise await setup.
            val usageGranted = rows.lastOrNull { it.capabilityKey == KEY_USAGE_METERING }?.state == "confirmed"
            if (canQuery && usageGranted) {
                CapabilityRow(KEY_APP_INVENTORY, "confirmed", "package visibility + usage stats available", now)
            } else {
                CapabilityRow(KEY_APP_INVENTORY, "awaiting_setup", "grant USAGE_STATS first")
            }
        }

        // tamper_signals (developer options / USB debug / test-only build checks) —
        // always reported; guardian sees evidence.
        rows += run {
            val devOn = try {
                // `development_settings_enabled` has been a stable Global setting since
                // API 17 and replaces the hidden DEVELOPMENT_OPTIONS_ON.
                Settings.Global.getInt(context.contentResolver, "development_settings_enabled", 0) == 1
            } catch (_: Throwable) { false }
            val adbOn = try {
                Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
            } catch (_: Throwable) { false }
            val evidence = buildString {
                if (devOn) append("developer_options=on;")
                if (adbOn) append("adb=on;")
                if (isEmpty()) append("no-tamper-indicators")
            }
            // Tamper reporting itself is always 'confirmed' (we *are* reporting),
            // evidence carries the signal — the ledger state reflects ability to
            // report, not the absence of tampering.
            CapabilityRow(KEY_TAMPER_SIGNALS, "confirmed", evidence, now)
        }

        // web_filter_vpn — S11 slice: return unsupported for S0 so we never claim
        // a VPN that is not built yet.
        rows += CapabilityRow(KEY_WEB_FILTER_VPN, "unsupported", "VPN filter not built in S0")

        // instant_lock — depends on Accessibility + BIND_DEVICE_ADMIN + overlay.
        // DeviceAdmin receiver class is registered at S1; until then the native answer
        // is `unsupported` (the admin component doesn't exist, so any "confirmed"
        // would be a fabrication).
        rows += run {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
            val pm = context.packageManager
            val adminClass = "com.familyos.family_os.FamilyOsDeviceAdminReceiver"
            val adminCn = ComponentName(context.packageName, adminClass)
            val adminExists = try {
                pm.getReceiverInfo(adminCn, 0) != null
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
            val adminActive = adminExists && dpm?.isAdminActive(adminCn) == true
            val overlay = rows.first { it.capabilityKey == KEY_APP_BLOCK_OVERLAY }.state == "confirmed"
            val a11y = rows.first { it.capabilityKey == KEY_ACCESSIBILITY_ENFORCEMENT }.state == "confirmed"
            when {
                !adminExists ->
                    CapabilityRow(KEY_INSTANT_LOCK, "unsupported", "DeviceAdmin receiver not yet declared (S1)")
                adminActive && overlay && a11y ->
                    CapabilityRow(KEY_INSTANT_LOCK, "confirmed", "admin+overlay+a11y", now)
                !adminActive ->
                    CapabilityRow(KEY_INSTANT_LOCK, "awaiting_setup", "DeviceAdmin not active")
                !overlay ->
                    CapabilityRow(KEY_INSTANT_LOCK, "permission_needed", "SYSTEM_ALERT_WINDOW denied")
                else ->
                    CapabilityRow(KEY_INSTANT_LOCK, "awaiting_setup", "AccessibilityService not enabled")
            }
        }

        return rows
    }

    /** Serialize to the JSON shape the Dart MethodChannel handler expects. */
    fun toJson(rows: List<CapabilityRow>): String {
        val arr = JSONArray()
        for (row in rows) {
            val o = JSONObject()
            o.put("capabilityKey", row.capabilityKey)
            o.put("state", row.state)
            if (row.evidence != null) o.put("evidence", row.evidence)
            if (row.confirmedAtEpoch != null) o.put("confirmedAtEpoch", row.confirmedAtEpoch)
            arr.put(o)
        }
        return arr.toString()
    }
}
