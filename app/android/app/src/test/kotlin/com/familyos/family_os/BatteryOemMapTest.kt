package com.familyos.family_os

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Behaviour of the S2 OEM battery-guidance map: every manufacturer string resolves to
 * exactly one guidance entry, brand aliases follow their platform, and the unknown
 * falls back to the stock settings action - never to null.
 */
class BatteryOemMapTest {
    @Test fun `xiaomi family resolves to the autostart door`() {
        for (maker in listOf("Xiaomi", "XIAOMI", "  Redmi  ", "POCO", "Poco X5")) {
            val entry = BatteryOemMap.guidance(maker)
            assertEquals("xiaomi", entry.vendorWire)
            assertNotNull(entry.targetPackage)
            assertNotNull(entry.targetActivity)
            assertEquals("oem_xiaomi", entry.stepsKey)
        }
    }

    @Test fun `huawei family resolves to the startup manager`() {
        for (maker in listOf("HUAWEI", "Honor")) {
            val entry = BatteryOemMap.guidance(maker)
            assertEquals("huawei", entry.vendorWire)
            assertEquals("oem_huawei", entry.stepsKey)
        }
    }

    @Test fun `oppo family resolves to the coloros entry`() {
        for (maker in listOf("OPPO", "Realme", "OnePlus", "One Plus")) {
            val entry = BatteryOemMap.guidance(maker)
            assertEquals("oppo", entry.vendorWire)
            assertEquals("oem_oppo", entry.stepsKey)
        }
    }

    @Test fun `vivo family resolves to the background-start manager`() {
        for (maker in listOf("vivo", "iQOO")) {
            val entry = BatteryOemMap.guidance(maker)
            assertEquals("vivo", entry.vendorWire)
            assertEquals("oem_vivo", entry.stepsKey)
        }
    }

    @Test fun `samsung resolves to the system exemption list`() {
        val entry = BatteryOemMap.guidance("samsung")
        assertEquals("samsung", entry.vendorWire)
        assertEquals("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS", entry.action)
        assertNull(entry.targetPackage)
        assertEquals("oem_samsung", entry.stepsKey)
    }

    @Test fun `anything unknown resolves to stock, never null`() {
        for (maker in listOf(null, "", "   ", "Google", "Motorola", "Nothing", "Fairphone")) {
            val entry = BatteryOemMap.guidance(maker)
            assertEquals("stock", entry.vendorWire)
            assertEquals("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS", entry.action)
            assertNull(entry.targetPackage)
            assertEquals("oem_stock", entry.stepsKey)
        }
    }
}
