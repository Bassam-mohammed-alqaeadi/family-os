package com.familyos.family_os

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Plain JVM tests for the handset's half of the W3 location contract.
 *
 * The fixture is shared with the backend (`backend/test/fixtures/native-location-fix.wire.json`,
 * validated there by `native-location-fix-contract.test.js`), so a field renamed on either
 * side fails one of the two suites instead of failing silently on a child's phone.
 * All coordinates here are synthetic test values.
 */
class LocationFixProtocolTest {
    private val fixtureReading = LocationFixProtocol.Reading(
        fixId = "3f1c2a4e-8b7d-4c2a-9e1f-5a6b7c8d9e0f",
        latitude = 15.3694,
        longitude = 44.191,
        accuracyMeters = 12.5,
        recordedAtEpochMillis = 1_791_590_400_123L,
        fromMockProvider = false,
    )

    @Test
    fun bodyIsByteForByteTheSharedFixture() {
        val fixture = File(repositoryRoot(), "backend/test/fixtures/native-location-fix.wire.json")
            .readText(Charsets.UTF_8)
            .trim()
        assertEquals(fixture, LocationFixProtocol.body(fixtureReading))
    }

    @Test
    fun mockProviderReadingIsLabelledNotHidden() {
        val body = LocationFixProtocol.body(fixtureReading.copy(fromMockProvider = true))
        assertTrue(body.contains("\"integritySoftWarning\":true"))
    }

    @Test
    fun pathAndIdempotencyKeyAreScopedToTheDeviceAndTheFix() {
        assertEquals(
            "/v1/devices/0b9a7c1e-2d3f-4a5b-8c6d-7e8f9a0b1c2d/location-fixes",
            LocationFixProtocol.path("0b9a7c1e-2d3f-4a5b-8c6d-7e8f9a0b1c2d"),
        )
        val key = LocationFixProtocol.idempotencyKey(fixtureReading.fixId)
        assertEquals("location-fix-3f1c2a4e-8b7d-4c2a-9e1f-5a6b7c8d9e0f", key)
        assertTrue("the server caps Idempotency-Key at 128 characters", key.length <= 128)
    }

    @Test
    fun timestampsAreUtcWithMilliseconds() {
        assertEquals("1970-01-01T00:00:00.001Z", LocationFixProtocol.isoInstant(1L))
        assertEquals("2026-10-10T00:00:00.123Z", LocationFixProtocol.isoInstant(1_791_590_400_123L))
    }

    @Test
    fun anHonestReadingIsReportable() {
        assertNotNull(LocationFixProtocol.reportable(fixtureReading))
        assertNotNull(LocationFixProtocol.reportable(fixtureReading.copy(accuracyMeters = 200.0)))
    }

    @Test
    fun aReadingThatWouldOverstateCertaintyIsDroppedNotRepaired() {
        val dropped = listOf(
            fixtureReading.copy(accuracyMeters = 0.0),
            fixtureReading.copy(accuracyMeters = -1.0),
            fixtureReading.copy(accuracyMeters = 200.5),
            fixtureReading.copy(accuracyMeters = Double.NaN),
            fixtureReading.copy(latitude = Double.NaN),
            fixtureReading.copy(latitude = 90.0001),
            fixtureReading.copy(longitude = -180.5),
            fixtureReading.copy(longitude = Double.POSITIVE_INFINITY),
            fixtureReading.copy(recordedAtEpochMillis = 0L),
            fixtureReading.copy(fixId = "not-a-uuid"),
        )
        dropped.forEach { assertNull("should not be reported: $it", LocationFixProtocol.reportable(it)) }
    }

    @Test
    fun onlyTheServersDefinitiveRevocationEndsTheSession() {
        val revoked = LocationFixProtocol.classify(
            401,
            """{"error":{"code":"invalid_device_credential","message":"The device credential is invalid or revoked."}}""",
        )
        assertEquals(LocationReportOutcome.CREDENTIAL_REVOKED, revoked)
        assertTrue(revoked.endsSession)
        // Whitespace and field order in the envelope do not change the meaning.
        assertEquals(
            LocationReportOutcome.CREDENTIAL_REVOKED,
            LocationFixProtocol.classify(401, "{ \"error\" : { \"message\": \"x\", \"code\" : \"invalid_device_credential\" } }"),
        )
    }

    @Test
    fun ambiguousRefusalsKeepTheCredential() {
        val kept = mapOf(
            // A 401 for another reason, or with no readable envelope (a proxy, a captive portal).
            Pair(401, """{"error":{"code":"authentication_required","message":"x"}}""") to LocationReportOutcome.ACCESS_REFUSED,
            Pair(401, "<html>Unauthorized</html>") to LocationReportOutcome.ACCESS_REFUSED,
            Pair(401, null) to LocationReportOutcome.ACCESS_REFUSED,
            // The right code on the wrong status is not the server's revocation answer.
            Pair(403, """{"error":{"code":"invalid_device_credential"}}""") to LocationReportOutcome.ACCESS_REFUSED,
            Pair(403, """{"error":{"code":"family_access_denied"}}""") to LocationReportOutcome.ACCESS_REFUSED,
            Pair(404, """{"error":{"code":"device_not_found"}}""") to LocationReportOutcome.ACCESS_REFUSED,
            Pair(400, """{"error":{"code":"invalid_request"}}""") to LocationReportOutcome.REJECTED,
            Pair(409, """{"error":{"code":"idempotency_conflict"}}""") to LocationReportOutcome.REJECTED,
            Pair(413, null) to LocationReportOutcome.REJECTED,
            Pair(408, null) to LocationReportOutcome.SERVER_UNAVAILABLE,
            Pair(429, """{"error":{"code":"rate_limit_exceeded"}}""") to LocationReportOutcome.SERVER_UNAVAILABLE,
            Pair(500, null) to LocationReportOutcome.SERVER_UNAVAILABLE,
            Pair(502, "<html>Bad gateway</html>") to LocationReportOutcome.SERVER_UNAVAILABLE,
            Pair(503, """{"error":{"code":"service_not_ready"}}""") to LocationReportOutcome.SERVER_UNAVAILABLE,
            Pair(null, null) to LocationReportOutcome.NETWORK_UNREACHABLE,
        )
        kept.forEach { (answer, expected) ->
            val outcome = LocationFixProtocol.classify(answer.first, answer.second)
            assertEquals("for $answer", expected, outcome)
            assertTrue("must not end the session: $answer", !outcome.endsSession)
        }
    }

    @Test
    fun acceptedAnswersAreAccepted() {
        assertEquals(LocationReportOutcome.ACCEPTED, LocationFixProtocol.classify(201, null))
        assertEquals(LocationReportOutcome.ACCEPTED, LocationFixProtocol.classify(200, null))
    }

    @Test
    fun errorCodeReadsOnlyTheEnvelope() {
        assertEquals("invalid_request", LocationFixProtocol.errorCode("""{"error":{"code":"invalid_request"}}"""))
        assertNull(LocationFixProtocol.errorCode("""{"code":"invalid_device_credential"}"""))
        assertNull(LocationFixProtocol.errorCode(""))
        assertNull(LocationFixProtocol.errorCode(null))
        // A code past the bounded read is never seen, so a huge body cannot steer the result.
        val padded = " ".repeat(LocationFixProtocol.MAX_ERROR_BODY_CHARS) +
            """{"error":{"code":"invalid_device_credential"}}"""
        assertNull(LocationFixProtocol.errorCode(padded))
    }

    @Test
    fun outcomeWireNamesAreAClosedVocabulary() {
        assertEquals(
            listOf("accepted", "credential_revoked", "access_refused", "rejected", "server_unavailable", "network_unreachable"),
            LocationReportOutcome.values().map { it.wire },
        )
        assertEquals(listOf(LocationReportOutcome.CREDENTIAL_REVOKED), LocationReportOutcome.values().filter { it.endsSession })
    }

    @Test
    fun oneReadingPerIntervalAcrossAllProviders() {
        val interval = LocationFixProtocol.MIN_REPORT_INTERVAL_MILLIS
        assertEquals(5 * 60 * 1000L, interval)
        assertTrue(LocationFixProtocol.dueForReport(null, 10_000L))
        // A network reading right after a GPS reading is held back...
        assertTrue(!LocationFixProtocol.dueForReport(10_000L, 10_000L + 1_000L))
        assertTrue(!LocationFixProtocol.dueForReport(10_000L, 10_000L + interval - 1))
        // ...until the interval has passed.
        assertTrue(LocationFixProtocol.dueForReport(10_000L, 10_000L + interval))
    }

    @Test
    fun legacyHeartbeatOnlyFollowsAnAcceptedGenuineFix() {
        assertTrue(LocationFixProtocol.legacyHeartbeatAllowed(LocationReportOutcome.ACCEPTED, fixtureReading))
        // A mock reading never reaches the route that cannot label it.
        assertTrue(
            !LocationFixProtocol.legacyHeartbeatAllowed(
                LocationReportOutcome.ACCEPTED,
                fixtureReading.copy(fromMockProvider = true),
            ),
        )
        // A refusal on the W3 route is never bypassed through the older route.
        for (outcome in LocationReportOutcome.values().filter { it != LocationReportOutcome.ACCEPTED }) {
            assertTrue("$outcome", !LocationFixProtocol.legacyHeartbeatAllowed(outcome, fixtureReading))
        }
    }

    private fun repositoryRoot(): File {
        var directory: File? = File(System.getProperty("user.dir")).absoluteFile
        while (directory != null) {
            if (File(directory, "AGENTS.md").isFile && File(directory, "backend").isDirectory) return directory
            directory = directory.parentFile
        }
        throw IllegalStateException("Run from inside the repository; AGENTS.md was not found above user.dir.")
    }
}
