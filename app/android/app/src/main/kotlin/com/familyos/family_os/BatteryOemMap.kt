package com.familyos.family_os

/**
 * S2 resilience: where each manufacturer's battery/autostart settings live.
 *
 * Pure data plus a lookup (proven by `BatteryOemMapTest`); no Android imports. The
 * framework layer (D2) resolves every entry with `resolveActivity` before launching and
 * falls back to the app-details settings screen when the component is absent - OEM
 * component names drift between OS versions, so *no entry here is ever trusted blindly*.
 *
 * Deliberately guidance-only (plan §12 row 2: "الإرشاد بدل الطلب الآلي"): nothing here
 * requests the ignore-optimizations exemption programmatically. The map opens the right
 * settings door; the person holding the phone walks through it.
 */
object BatteryOemMap {
    // Stock Android: the system list where the user grants the exemption themselves.
    private const val ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS =
        "android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS"

    /**
     * How to open the battery/autostart door for one manufacturer.
     *
     * @param vendorWire stable identifier the guidance copy and the server evidence use.
     * @param action intent action to fire (an `android.settings.*` action or a vendor action).
     * @param targetPackage explicit component package, or null for an implicit action.
     * @param targetActivity explicit component class, or null for an implicit action.
     * @param stepsKey copy-key the Flutter guidance screen reads (l10n lands in D3).
     */
    data class OemBatteryGuidance(
        val vendorWire: String,
        val action: String,
        val targetPackage: String?,
        val targetActivity: String?,
        val stepsKey: String,
    )

    private val XIAOMI = OemBatteryGuidance(
        vendorWire = "xiaomi",
        action = "android.intent.action.MAIN",
        targetPackage = "com.miui.securitycenter",
        targetActivity = "com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity",
        stepsKey = "oem_xiaomi",
    )

    private val HUAWEI = OemBatteryGuidance(
        vendorWire = "huawei",
        action = "android.intent.action.MAIN",
        targetPackage = "com.huawei.systemmanager",
        targetActivity = "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        stepsKey = "oem_huawei",
    )

    private val OPPO = OemBatteryGuidance(
        vendorWire = "oppo",
        action = "android.intent.action.MAIN",
        targetPackage = "com.coloros.safecenter",
        targetActivity = "com.coloros.safecenter.startupapp.StartupAppListActivity",
        stepsKey = "oem_oppo",
    )

    private val VIVO = OemBatteryGuidance(
        vendorWire = "vivo",
        action = "android.intent.action.MAIN",
        targetPackage = "com.vivo.permissionmanager",
        targetActivity = "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        stepsKey = "oem_vivo",
    )

    private val SAMSUNG = OemBatteryGuidance(
        vendorWire = "samsung",
        action = ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS,
        targetPackage = null,
        targetActivity = null,
        stepsKey = "oem_samsung",
    )

    private val STOCK = OemBatteryGuidance(
        vendorWire = "stock",
        action = ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS,
        targetPackage = null,
        targetActivity = null,
        stepsKey = "oem_stock",
    )

    /**
     * Guidance for [manufacturer] (the `Build.MANUFACTURER` string, any casing, null-safe).
     * Brand aliases that share a settings app (Redmi/Poco -> Xiaomi, Honor -> Huawei,
     * Realme/OnePlus -> Oppo, iQOO -> Vivo) resolve to their platform entry; anything
     * unknown resolves to the stock settings action, never to null.
     */
    fun guidance(manufacturer: String?): OemBatteryGuidance {
        val normalized = (manufacturer ?: "").trim().lowercase()
        return when {
            normalized.contains("xiaomi") || normalized.contains("redmi") ||
                normalized.contains("poco") -> XIAOMI
            normalized.contains("huawei") || normalized.contains("honor") -> HUAWEI
            normalized.contains("oppo") || normalized.contains("realme") ||
                normalized.contains("oneplus") || normalized == "one plus" -> OPPO
            normalized.contains("vivo") || normalized.contains("iqoo") -> VIVO
            normalized.contains("samsung") -> SAMSUNG
            else -> STOCK
        }
    }
}
