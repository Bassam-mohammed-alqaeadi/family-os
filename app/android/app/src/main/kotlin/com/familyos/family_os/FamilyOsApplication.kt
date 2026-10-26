package com.familyos.family_os

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Color
import android.os.Build

/** Creates the reviewed family alert channels before Firebase renders a notification. */
class FamilyOsApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channels = listOf(
            ChannelSpec(
                id = CHANNEL_SOS,
                name = getString(R.string.familyos_sos_channel_name),
                description = getString(R.string.familyos_sos_channel_description),
                color = Color.rgb(255, 90, 95),
            ),
            ChannelSpec(
                id = CHANNEL_GEOFENCE,
                name = getString(R.string.familyos_geofence_channel_name),
                description = getString(R.string.familyos_geofence_channel_description),
                color = Color.rgb(255, 181, 71),
            ),
            ChannelSpec(
                id = CHANNEL_PROTECTION,
                name = getString(R.string.familyos_protection_channel_name),
                description = getString(R.string.familyos_protection_channel_description),
                color = Color.rgb(124, 92, 230),
                importance = NotificationManager.IMPORTANCE_HIGH,
                soundEnabled = false,
                vibrationEnabled = false,
            ),
            ChannelSpec(
                id = CHANNEL_ALERTS,
                name = getString(R.string.familyos_alerts_channel_name),
                description = getString(R.string.familyos_alerts_channel_description),
                color = Color.rgb(76, 141, 246),
                importance = NotificationManager.IMPORTANCE_DEFAULT,
                vibrationEnabled = false,
            ),
            ChannelSpec(
                id = CHANNEL_CHAT,
                name = getString(R.string.familyos_chat_channel_name),
                description = getString(R.string.familyos_chat_channel_description),
                color = Color.rgb(38, 179, 169),
                importance = NotificationManager.IMPORTANCE_DEFAULT,
                vibrationEnabled = false,
            ),
        )
        channels.forEach { spec ->
            val channel = NotificationChannel(
                spec.id,
                spec.name,
                spec.importance,
            ).apply {
                description = spec.description
                enableLights(true)
                lightColor = spec.color
                enableVibration(spec.vibrationEnabled)
                if (!spec.soundEnabled) setSound(null, null)
                setShowBadge(true)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private data class ChannelSpec(
        val id: String,
        val name: String,
        val description: String,
        val color: Int,
        val importance: Int = NotificationManager.IMPORTANCE_HIGH,
        val soundEnabled: Boolean = true,
        val vibrationEnabled: Boolean = true,
    )

    companion object {
        const val CHANNEL_SOS = "familyos_sos_alerts"
        const val CHANNEL_GEOFENCE = "familyos_geofence_alerts"
        const val CHANNEL_PROTECTION = "familyos_protection_alerts"
        const val CHANNEL_CHAT = "familyos_chat_nudges"
        const val CHANNEL_ALERTS = "familyos_family_alerts"
    }
}
