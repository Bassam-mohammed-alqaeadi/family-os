package com.familyos.family_os

import org.json.JSONObject
import java.io.Reader
import java.net.HttpURLConnection
import java.net.URL

private const val MAX_DEVICE_STATUS_BYTES = 64 * 1024

/**
 * Reads only this installation's server record with its Keystore-backed
 * capability. The credential is deliberately consumed only by native code and
 * is never included in the sanitized map returned over the Flutter channel.
 */
internal class ChildDeviceStatusClient {
    fun fetch(config: TelemetryConfig): ChildDeviceSnapshot {
        val connection = (URL("${config.apiOrigin}/v1/devices/${config.deviceId}").openConnection()
            as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 15_000
            readTimeout = 15_000
            useCaches = false
            setRequestProperty("Authorization", "Device ${config.deviceCredential}")
            setRequestProperty("Accept", "application/json")
        }

        try {
            val responseCode = connection.responseCode
            if (responseCode !in 200..299) {
                throw ChildDeviceStatusException("Device status request was rejected")
            }
            val payload = connection.inputStream.bufferedReader(Charsets.UTF_8).use(::readBounded)
            return parseSnapshot(payload, config.deviceId)
        } catch (error: ChildDeviceStatusException) {
            throw error
        } catch (error: Exception) {
            throw ChildDeviceStatusException("Device status is temporarily unavailable", error)
        } finally {
            connection.disconnect()
        }
    }

    private fun parseSnapshot(payload: String, expectedDeviceId: String): ChildDeviceSnapshot {
        try {
            val device = JSONObject(payload).getJSONObject("device")
            val id = device.getString("id").trim()
            val label = device.getString("deviceLabel").trim()
            if (id != expectedDeviceId || label.isEmpty() || label.length > 80) {
                throw ChildDeviceStatusException("Device status response did not match this installation")
            }

            val batteryLevel = nullableInt(device, "batteryLevel")
            if (batteryLevel != null && batteryLevel !in 0..100) {
                throw ChildDeviceStatusException("Device status response contained an invalid battery level")
            }
            val batteryStatus = nullableString(device, "batteryStatus")
            if (batteryStatus != null && batteryStatus != "charging" && batteryStatus != "unplugged") {
                throw ChildDeviceStatusException("Device status response contained an invalid battery state")
            }
            val lastSeenAt = nullableString(device, "lastSeenAt")
            if (lastSeenAt != null && lastSeenAt.length > 64) {
                throw ChildDeviceStatusException("Device status response contained an invalid timestamp")
            }

            return ChildDeviceSnapshot(
                id = id,
                label = label,
                batteryLevel = batteryLevel,
                batteryStatus = batteryStatus,
                lastSeenAt = lastSeenAt,
            )
        } catch (error: ChildDeviceStatusException) {
            throw error
        } catch (error: Exception) {
            throw ChildDeviceStatusException("Device status response was invalid", error)
        }
    }

    private fun nullableInt(source: JSONObject, key: String): Int? =
        if (source.isNull(key)) null else source.getInt(key)

    private fun nullableString(source: JSONObject, key: String): String? =
        if (source.isNull(key)) null else source.getString(key).trim().ifEmpty { null }
}

internal data class ChildDeviceSnapshot(
    val id: String,
    val label: String,
    val batteryLevel: Int?,
    val batteryStatus: String?,
    val lastSeenAt: String?,
) {
    fun toChannelMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "label" to label,
        "batteryLevel" to batteryLevel,
        "batteryStatus" to batteryStatus,
        "lastSeenAt" to lastSeenAt,
    )
}

internal class ChildDeviceStatusException(message: String, cause: Throwable? = null) :
    Exception(message, cause)

private fun readBounded(reader: Reader): String {
    val output = StringBuilder()
    val buffer = CharArray(4096)
    while (true) {
        val read = reader.read(buffer)
        if (read < 0) return output.toString()
        if (output.length + read > MAX_DEVICE_STATUS_BYTES) {
            throw ChildDeviceStatusException("Device status response was too large")
        }
        output.append(buffer, 0, read)
    }
}
