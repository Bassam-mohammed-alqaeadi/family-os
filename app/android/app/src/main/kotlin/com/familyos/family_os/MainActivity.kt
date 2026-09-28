package com.familyos.family_os

import io.flutter.embedding.android.FlutterActivity

/**
 * Family OS host activity.
 *
 * QA / Gemini UX agent cold-opens the SCR catalog with:
 *   adb shell am start -n com.familyos.family_os/.MainActivity \
 *     --es flutter_route /dev-screens
 *
 * [getInitialRoute] surfaces that extra as Flutter's defaultRouteName so
 * GoRouter can boot directly into DevScreenGallery.
 */
class MainActivity : FlutterActivity() {
    override fun getInitialRoute(): String? {
        val fromIntent = intent?.getStringExtra(EXTRA_FLUTTER_ROUTE)?.trim()
        if (!fromIntent.isNullOrEmpty()) {
            val audit = intent?.getStringExtra(EXTRA_FLUTTER_AUDIT)?.trim()
            if (audit == "populated" && !fromIntent.contains("audit=")) {
                val join = if (fromIntent.contains("?")) "&" else "?"
                return "$fromIntent${join}audit=populated"
            }
            return fromIntent
        }
        return super.getInitialRoute()
    }

    companion object {
        const val EXTRA_FLUTTER_ROUTE = "flutter_route"
        const val EXTRA_FLUTTER_AUDIT = "flutter_audit"
    }
}
