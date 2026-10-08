import { createHash, randomUUID } from 'node:crypto';
import express from 'express';
import { rateLimit } from 'express-rate-limit';
import { asHttpError, HttpError } from './http-error.js';
import { deviceRevocationFor } from './device-revocation.js';
import { membershipRosterFor } from './membership-roster.js';
import { safeZonesFor } from './safe-zones.js';
import { locationSurfaceFor } from './location-telemetry.js';
import { sosEmergencyFor } from './sos-emergency.js';
import { screenTimeFor } from './screen-time.js';
import { webFilterFor } from './web-filter.js';
import { tasksFor } from './tasks.js';
import { calendarFor } from './calendar.js';
import { familyChatFor } from './family-chat.js';
import { capabilityMatches } from './store/postgres-foundation-store.js';
import {
    claimDevicePairingInput,
    createChildInput,
    createDevicePairingInput,
    createFamilyInput,
    deviceTelemetryInput,
    registerFamilyChildDeviceInput,
    createGuardianTransferInput,
    createMembershipInput,
    appRuleInput,
    createSafeZoneInput,
    deviceScreenTimeReportInput,
    locationFixInput,
    lockInput,
    screenTimePolicyInput,
    timeRequestDecisionInput,
    timeRequestInput,
    timeRequestListQuery,
    sosAlertListQuery,
    sosBackupContactInput,
    sosBackupContactUpdateInput,
    sosFireInput,
    sosResolveInput,
    revokeMembershipInput,
    updateSafeZoneAlertsInput,
    requireAppId,
    requireIdempotencyKey,
    requireNoQueryParameters,
    requireUuid,
    revokeFamilyChildDeviceInput,
    webFilterPolicyInput,
    tempAllowRequestInput,
    tempAllowDecisionInput,
    protectionReportInput,
    webFilterEvaluateQuery,
    taskCreateInput,
    taskClaimInput,
    taskDecisionInput,
    eventCreateInput,
    eventUpdateInput,
    eventCancelInput,
    eventResponseInput,
    eventAttendanceInput,
    eventRangeQuery,
    chatThreadCreateInput,
    chatThreadMemberInput,
    chatMessageInput,
    chatMessageEditInput,
    chatReadInput,
    chatMessageQuery,
} from './validation.js';

function requestFingerprint({ action, principal, input }) {
    return createHash('sha256')
        .update(JSON.stringify({ action, subject: principal.subject, input }))
        .digest('hex');
}

function deviceCredentialFromAuthorization(value) {
    if (typeof value !== 'string') return null;
    const match = /^Device ([A-Za-z0-9_-]{32,128})$/.exec(value);
    return match?.[1] ?? null;
}

function safeRequestId(value) {
    if (typeof value === 'string' && /^[A-Za-z0-9_-]{8,128}$/.test(value)) {
        return value;
    }
    return randomUUID();
}

function asyncRoute(handler) {
    return (request, response, next) => {
        Promise.resolve(handler(request, response, next)).catch(next);
    };
}

export function createApp({
    store,
    authVerifier,
    readiness,
    // Revocation is data-accessed through the store's own transaction helpers, so
    // the server has a working operation without the shared store file being
    // edited. A test injects its own port; production uses this one.
    deviceRevocation = deviceRevocationFor(store),
    // Same reasoning as revocation: the membership roster reads through the store's
    // published transaction and membership helpers, so the read surface costs one
    // route and no edit inside a shared write path.
    membershipRoster = membershipRosterFor(store),
    // W3. The zone definitions and the location surface reach the database through the
    // same published store helpers, so both cost route lines here and nothing inside a
    // file another session is editing.
    safeZones = safeZonesFor(store),
    location = locationSurfaceFor(store, { credentialMatches: capabilityMatches }),
    // W4. The emergency surface reaches the database through the same published helpers,
    // and its credential check is the one the device routes already use.
    sos = sosEmergencyFor(store, { credentialMatches: capabilityMatches }),
    // W5. The minutes a child has, the apps they belong to, and the instant lock. Same
    // arrangement as the surfaces before it: data access through the store's published
    // helpers, and the one credential check every device route already uses.
    screenTime = screenTimeFor(store, { credentialMatches: capabilityMatches }),
    webFilter = webFilterFor(store, { credentialMatches: capabilityMatches }),
    // W7. Family tasks and points: the junction of protection and upbringing. Same
    // arrangement as every wave before it - one credential check, data access through the
    // store's published helpers, and no decision in the route layer.
    tasks = tasksFor(store, { credentialMatches: capabilityMatches }),
    // W8. The family calendar. Same arrangement as every wave before it, and the same one
    // law that matters here: what a phone may claim about a person is decided in the module,
    // not in a route - attendance is recorded by a guardian after the fact, never inferred.
    calendar = calendarFor(store, { credentialMatches: capabilityMatches }),
    // W9. The family chat - the one surface where a family writes things down. Same
    // arrangement as every wave before it (one credential check, data access through the
    // store's published helpers, no decision in the route layer), and one law that only this
    // wave has: the room is the permission. Nothing in this file decides who may read a
    // thread; a caller with no member row reads `chat_thread_not_found`, from the module.
    familyChat = familyChatFor(store, { credentialMatches: capabilityMatches }),
    preAuthenticationRateLimit = {},
    protectedRateLimit = {},
}) {
    const app = express();

    app.set('trust proxy', 1);
    app.disable('x-powered-by');
    app.use((_request, response, next) => {
        // Family, identity and audit responses must not be stored by shared browsers, proxies or intermediaries.
        response.set({
            'Cache-Control': 'no-store',
            'X-Content-Type-Options': 'nosniff',
            'Referrer-Policy': 'no-referrer',
            'X-Frame-Options': 'DENY',
        });
        next();
    });
    app.use((request, response, next) => {
        request.requestId = safeRequestId(request.get('X-Request-Id'));
        request.correlationId = randomUUID();
        response.set('X-Request-Id', request.requestId);
        response.set('X-Correlation-Id', request.correlationId);
        next();
    });
    app.use(express.json({ limit: '64kb', strict: true }));

    const requirePrincipal = asyncRoute(async(request, _response, next) => {
        request.principal ??= await authVerifier.verify(request.get('Authorization'));
        next();
    });

    const requireTelemetryActor = asyncRoute(async(request, _response, next) => {
        const deviceCredential = deviceCredentialFromAuthorization(request.get('Authorization'));
        if (deviceCredential != null) {
            request.deviceCredential = deviceCredential;
            next();
            return;
        }
        request.principal ??= await authVerifier.verify(request.get('Authorization'));
        next();
    });

    const requireRuntimeReady = asyncRoute(async(_request, _response, next) => {
        const configStatus = readiness();
        const databaseStatus = await store.health();
        if (!configStatus.ready || !databaseStatus.available) {
            throw new HttpError(503, 'service_not_ready', 'The service is not ready for protected operations.');
        }
        next();
    });

    const protectedApiRateLimit = rateLimit({
        windowMs: protectedRateLimit.windowMs ?? 60_000,
        limit: protectedRateLimit.limit ?? 120,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        validate: { xForwardedForHeader: false },

        // Identity has already been signature-verified. A subject-scoped limit avoids
        // conflating all users behind a trusted hosting proxy and cannot be evaded by
        // a client-controlled forwarding header.
        keyGenerator: (request) => request.principal.subject,
        handler: (_request, _response, next) => {
            next(new HttpError(429, 'rate_limit_exceeded', 'Too many protected API requests. Try again later.'));
        },
    });

    const deviceTelemetryRateLimit = rateLimit({
        windowMs: protectedRateLimit.windowMs ?? 60_000,
        limit: protectedRateLimit.limit ?? 120,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        validate: { xForwardedForHeader: false },
        keyGenerator: (request) => {
            if (request.deviceCredential) {
                return `device:${createHash('sha256').update(request.deviceCredential).digest('hex')}`;
            }
            return `guardian:${request.principal?.subject ?? 'unauthenticated'}`;
        },
        handler: (_request, _response, next) => {
            next(new HttpError(429, 'rate_limit_exceeded', 'Too many telemetry updates. Try again later.'));
        },
    });

    const pairingClaimRateLimit = rateLimit({
        windowMs: 60_000,
        limit: 12,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        validate: { xForwardedForHeader: false },
        handler: (_request, _response, next) => {
            next(new HttpError(429, 'rate_limit_exceeded', 'Too many pairing attempts. Try again later.'));
        },
    });

    // This limit deliberately runs before token verification: malformed or
    // unauthorized traffic must not be able to exhaust identity or database work.
    // It uses Express's direct peer address rather than a client-supplied forwarding
    // header; the stricter subject limit below protects verified principals.
    app.use('/v1', rateLimit({
        windowMs: preAuthenticationRateLimit.windowMs ?? 60_000,
        limit: preAuthenticationRateLimit.limit ?? 600,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        validate: { xForwardedForHeader: false },

        handler: (_request, _response, next) => {
            next(new HttpError(429, 'rate_limit_exceeded', 'Too many API requests. Try again later.'));
        },
    }));

    app.get('/health/live', (_request, response) => {
        response.status(200).json({ status: 'live' });
    });

    app.get(
        '/health/ready',
        asyncRoute(async(_request, response) => {
            const configStatus = readiness();
            const databaseStatus = await store.health();
            if (!configStatus.ready || !databaseStatus.available) {
                response.status(503).json({
                    status: 'not_ready',
                    dependencies: {
                        configuration: configStatus.ready ? 'ready' : (configStatus.reason ?? 'not_configured'),
                        database: databaseStatus.available ? 'ready' : databaseStatus.reason,
                    },
                });
                return;
            }
            response.status(200).json({ status: 'ready' });
        }),
    );

    app.get(
        '/v1/me/families',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            requireNoQueryParameters(request.query);
            response.status(200).json(await store.listMyFamilies({ principal: request.principal }));
        }),
    );

    app.post(
        '/v1/families',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const input = createFamilyInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.createFamily({
                principal: request.principal,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({ action: 'family.create', principal: request.principal, input }),
            });
            response.status(201).json(result);
        }),
    );

    app.get(
        '/v1/families/:familyId',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            response.status(200).json(await store.getFamily({ principal: request.principal, familyId }));
        }),
    );

    app.get(
        '/v1/families/:familyId/children',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            response.status(200).json(await store.listFamilyChildren({
                principal: request.principal,
                familyId,
            }));
        }),
    );

    app.post(
        '/v1/families/:familyId/children',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const input = createChildInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.createFamilyChild({
                principal: request.principal,
                familyId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family_child.create',
                    principal: request.principal,
                    input: { familyId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.get(
        '/v1/families/:familyId/devices',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            response.status(200).json(await store.listFamilyDevices({
                principal: request.principal,
                familyId,
            }));
        }),
    );

    // Revoking a child device. This is the write half of the lifecycle contract:
    // the read side already refused a revoked credential with 401, but nothing
    // could set the revocation, so a lost handset stayed trusted forever. The
    // request is idempotent, primary-guardian-only, and answers with the device's
    // new condition so the client needs no second round trip.
    app.post(
        '/v1/families/:familyId/children/:childId/devices/:deviceId/revocation',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const input = revokeFamilyChildDeviceInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await deviceRevocation({
                principal: request.principal,
                familyId,
                childId,
                deviceId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family_child_device.revoke',
                    principal: request.principal,
                    input: { familyId, childId, deviceId, ...input },
                }),
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/children/:childId/device-pairings',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const input = createDevicePairingInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.createDevicePairing({
                principal: request.principal,
                familyId,
                childId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family_device_pairing.create',
                    principal: request.principal,
                    input: { familyId, childId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.post(
        '/v1/device-pairings/claim',
        pairingClaimRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const input = claimDevicePairingInput(request.body);
            response.status(201).json(await store.claimDevicePairing({
                ...input,
                correlationId: request.correlationId,
            }));
        }),
    );

    app.post(
        '/v1/families/:familyId/children/:childId/devices',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const input = registerFamilyChildDeviceInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.registerFamilyChildDevice({
                principal: request.principal,
                familyId,
                childId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family_child_device.register',
                    principal: request.principal,
                    input: { familyId, childId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.post(
        '/v1/devices/:deviceId/telemetry',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const input = deviceTelemetryInput(request.body);
            const result = await store.ingestDeviceTelemetry({
                principal: request.principal,
                deviceCredential: request.deviceCredential,
                deviceId,
                ...input,
                correlationId: request.correlationId,
            });
            response.status(200).json(result);
        }),
    );

    // ── W3 Location & Safe Zones ────────────────────────────────────────────────
    //
    // The zones a family defines. Reading is open to every active member (a child lives
    // inside the boundary and is entitled to see it); writing is the guardians' act.
    app.get(
        '/v1/families/:familyId/safe-zones',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const result = await safeZones.list({
                principal: request.principal,
                familyId,
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/safe-zones',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const input = createSafeZoneInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await safeZones.create({
                principal: request.principal,
                familyId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'safe_zone.create',
                    principal: request.principal,
                    input: { familyId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // Which transitions a zone announces. Separate from creation on purpose: this is the
    // switch a family reaches for at night, and it must not be able to move the boundary
    // or reassign it while doing so.
    app.patch(
        '/v1/families/:familyId/safe-zones/:zoneId',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const zoneId = requireUuid(request.params.zoneId, 'zoneId');
            requireNoQueryParameters(request.query);
            const input = updateSafeZoneAlertsInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await safeZones.updateAlerts({
                principal: request.principal,
                familyId,
                zoneId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'safe_zone.alerts',
                    principal: request.principal,
                    input: { familyId, zoneId, ...input },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The live picture: every child, every linked device, and where each child stands
    // relative to each zone. One rule for every member of the family - including the
    // child - because a surface only the parents can read is where covert tracking grows.
    app.get(
        '/v1/families/:familyId/location',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const result = await location.familyLocation({
                principal: request.principal,
                familyId,
            });
            response.status(200).json(result);
        }),
    );

    // The arrival and departure feed the alerts are read from.
    app.get(
        '/v1/families/:familyId/geofence-events',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const result = await location.geofenceEvents({
                principal: request.principal,
                familyId,
            });
            response.status(200).json(result);
        }),
    );

    // The trail a family can read back, under the same one-rule-for-everyone promise as the
    // live picture.
    app.get(
        '/v1/families/:familyId/children/:childId/location-history',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const result = await location.locationHistory({
                principal: request.principal,
                familyId,
                childId,
            });
            response.status(200).json(result);
        }),
    );

    // One reported position from a child's device. The device proves itself with the
    // credential it was issued once; a primary guardian may still report on its behalf
    // while native collection is finished, exactly as the telemetry route allows.
    app.post(
        '/v1/devices/:deviceId/location-fixes',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const fix = locationFixInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await location.ingestFix({
                principal: request.principal,
                deviceCredential: request.deviceCredential,
                deviceId,
                fix,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'location.fix',
                    principal: request.principal ?? { subject: `device:${deviceId}` },
                    input: { deviceId, ...fix },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // ── W4 SOS ──────────────────────────────────────────────────────────────────
    //
    // The child's button, the ladder it climbs, and what each recipient was actually
    // told. Reading is open to every active member of the family - the child whose
    // incident it is sees exactly what a parent sees - and acting is the guardians' part,
    // except that a handset may close its own child's incident as a false alarm.
    app.get(
        '/v1/families/:familyId/sos-alerts',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const status = sosAlertListQuery(request.query);
            const result = await sos.list({
                principal: request.principal,
                familyId,
                status,
            });
            response.status(200).json(result);
        }),
    );

    app.get(
        '/v1/families/:familyId/sos-alerts/:alertId',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const alertId = requireUuid(request.params.alertId, 'alertId');
            requireNoQueryParameters(request.query);
            const result = await sos.read({
                principal: request.principal,
                familyId,
                alertId,
            });
            response.status(200).json(result);
        }),
    );

    // A guardian raising an incident for a child whose handset is not the one in use.
    app.post(
        '/v1/families/:familyId/children/:childId/sos-alerts',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const input = sosFireInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await sos.fire({
                principal: request.principal,
                familyId,
                childId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'sos.fire',
                    principal: request.principal,
                    input: { familyId, childId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // The button on the child's own handset. The device proves itself with the credential
    // it was issued once; a primary guardian may still report on its behalf while native
    // collection is finished, exactly as the telemetry and location routes allow.
    app.post(
        '/v1/devices/:deviceId/sos-alerts',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const input = sosFireInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await sos.fire({
                principal: request.principal,
                deviceCredential: request.deviceCredential,
                deviceId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'sos.fire',
                    principal: request.principal ?? { subject: `device:${deviceId}` },
                    input: { deviceId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // "I have seen this." Not the same as closing it, and the two are separate acts.
    app.post(
        '/v1/families/:familyId/sos-alerts/:alertId/acknowledge',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const alertId = requireUuid(request.params.alertId, 'alertId');
            requireNoQueryParameters(request.query);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await sos.acknowledge({
                principal: request.principal,
                familyId,
                alertId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'sos.acknowledge',
                    principal: request.principal,
                    input: { familyId, alertId },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // Climbing the family's own ladder. Only verified contacts are used, and the answer
    // says how many were skipped for being unverified.
    app.post(
        '/v1/families/:familyId/sos-alerts/:alertId/escalate',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const alertId = requireUuid(request.params.alertId, 'alertId');
            requireNoQueryParameters(request.query);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await sos.escalate({
                principal: request.principal,
                familyId,
                alertId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'sos.escalate',
                    principal: request.principal,
                    input: { familyId, alertId },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // Closing it. A guardian states why, from an account.
    app.post(
        '/v1/families/:familyId/sos-alerts/:alertId/resolve',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const alertId = requireUuid(request.params.alertId, 'alertId');
            requireNoQueryParameters(request.query);
            const input = sosResolveInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await sos.resolve({
                principal: request.principal,
                familyId,
                alertId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'sos.resolve',
                    principal: request.principal,
                    input: { familyId, alertId, ...input },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // Closing it from the handset that raised it, and only as a false alarm. The device
    // proves itself with its credential, so "is this your incident?" has an answer that
    // does not depend on a client being honest about who it is.
    app.post(
        '/v1/devices/:deviceId/sos-alerts/:alertId/resolve',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const alertId = requireUuid(request.params.alertId, 'alertId');
            const input = sosResolveInput(request.body);
            const result = await sos.resolve({
                principal: request.principal,
                deviceCredential: request.deviceCredential,
                deviceId,
                familyId: null,
                alertId,
                ...input,
                correlationId: request.correlationId,
            });
            response.status(200).json(result);
        }),
    );

    // The ladder the family builds for itself, rung 2 and below. Rung 1 is its guardians
    // and is derived from the roster, never from a list a client sends.
    app.get(
        '/v1/families/:familyId/sos-backup-contacts',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const result = await sos.listBackupContacts({
                principal: request.principal,
                familyId,
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/sos-backup-contacts',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const contact = sosBackupContactInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await sos.createBackupContact({
                principal: request.principal,
                familyId,
                contact,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'sos.backup_contact.create',
                    principal: request.principal,
                    input: { familyId, ...contact },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.patch(
        '/v1/families/:familyId/sos-backup-contacts/:contactId',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const contactId = requireUuid(request.params.contactId, 'contactId');
            requireNoQueryParameters(request.query);
            const patch = sosBackupContactUpdateInput(request.body);
            const result = await sos.updateBackupContact({
                principal: request.principal,
                familyId,
                contactId,
                patch,
                correlationId: request.correlationId,
            });
            response.status(200).json(result);
        }),
    );

    // ── W5 SCREEN TIME ──────────────────────────────────────────────────────────
    //
    // Guardians set the policy, the apps, the lock and the answers; the child's own
    // handset reads and reports through the credential it was issued at pairing, which is
    // what proves WHICH child it is. There is no child id on the device routes, and there
    // must never be one: a parameter a client can choose is not proof of anything.
    app.get(
        '/v1/families/:familyId/children/:childId/screen-time',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const result = await screenTime.read({
                principal: request.principal,
                familyId,
                childId,
            });
            response.status(200).json(result);
        }),
    );

    app.patch(
        '/v1/families/:familyId/children/:childId/screen-time',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const { policy, expectedVersion } = screenTimePolicyInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await screenTime.updatePolicy({
                principal: request.principal,
                familyId,
                childId,
                policy,
                expectedVersion,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'screen_time.policy.update',
                    principal: request.principal,
                    input: { familyId, childId, policy, expectedVersion },
                }),
            });
            response.status(200).json(result);
        }),
    );

    app.get(
        '/v1/families/:familyId/children/:childId/apps',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const result = await screenTime.listApps({
                principal: request.principal,
                familyId,
                childId,
            });
            response.status(200).json(result);
        }),
    );

    app.put(
        '/v1/families/:familyId/children/:childId/apps/:appId/rule',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const appId = requireAppId(request.params.appId);
            requireNoQueryParameters(request.query);
            const rule = appRuleInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await screenTime.updateAppRule({
                principal: request.principal,
                familyId,
                childId,
                appId,
                rule,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'screen_time.app_rule.update',
                    principal: request.principal,
                    input: { familyId, childId, appId, rule },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // "This phone is off now." A decision with an author and a reason, not a duration -
    // the parent who locks it is the one who releases it, and "until 18:00" is a rule the
    // policy already expresses.
    app.post(
        '/v1/families/:familyId/children/:childId/screen-time/lock',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const { reasonCode } = lockInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await screenTime.lock({
                principal: request.principal,
                familyId,
                childId,
                reasonCode,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'screen_time.lock',
                    principal: request.principal,
                    input: { familyId, childId, reasonCode },
                }),
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/children/:childId/screen-time/unlock',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await screenTime.unlock({
                principal: request.principal,
                familyId,
                childId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'screen_time.unlock',
                    principal: request.principal,
                    input: { familyId, childId },
                }),
            });
            response.status(200).json(result);
        }),
    );

    app.get(
        '/v1/families/:familyId/children/:childId/time-requests',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const status = timeRequestListQuery(request.query);
            const result = await screenTime.listTimeRequests({
                principal: request.principal,
                familyId,
                childId,
                status,
            });
            response.status(200).json(result);
        }),
    );

    // A guardian asking on a child's behalf: the spoken request, recorded the same way as
    // the one the child's own handset sends.
    app.post(
        '/v1/families/:familyId/children/:childId/time-requests',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const input = timeRequestInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await screenTime.createTimeRequest({
                principal: request.principal,
                familyId,
                childId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'screen_time.request.create',
                    principal: request.principal,
                    input: { familyId, childId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/children/:childId/time-requests/:requestId/decision',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const requestId = requireUuid(request.params.requestId, 'requestId');
            requireNoQueryParameters(request.query);
            const input = timeRequestDecisionInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await screenTime.decideTimeRequest({
                principal: request.principal,
                familyId,
                childId,
                requestId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'screen_time.request.decide',
                    principal: request.principal,
                    input: { familyId, childId, requestId, ...input },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The child's own device: what it measured, what is installed, and what it wants - and
    // the same state block a guardian reads back, computed from the same rows.
    app.post(
        '/v1/devices/:deviceId/screen-time',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const { usage, apps, request: ask } = deviceScreenTimeReportInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await screenTime.reportFromDevice({
                deviceCredential: request.deviceCredential,
                deviceId,
                usage,
                apps,
                requestMinutes: ask?.requestedMinutes ?? null,
                requestReasonCode: ask?.reasonCode ?? null,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'screen_time.device.report',
                    principal: request.principal ?? { subject: `device:${deviceId}` },
                    input: { deviceId, usage, apps, request: ask },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.get(
        '/v1/devices/:deviceId/screen-time',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            requireNoQueryParameters(request.query);
            const result = await screenTime.readFromDevice({
                deviceCredential: request.deviceCredential,
                deviceId,
            });
            response.status(200).json(result);
        }),
    );

    // ── W6 WEB FILTER ───────────────────────────────────────────────────────────
    //
    // Guardians state the policy and answer the questions; the child's handset reads the
    // policy it must apply and testifies about its own protection plane. The handset
    // routes carry no child id for the reason screen time's do not: the device credential
    // is the proof of which child is speaking, and a parameter a client can choose proves
    // nothing.
    app.get(
        '/v1/families/:familyId/children/:childId/web-filter',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const result = await webFilter.readPolicy({
                principal: request.principal,
                familyId,
                childId,
            });
            response.status(200).json(result);
        }),
    );

    app.patch(
        '/v1/families/:familyId/children/:childId/web-filter',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const { change, expectedVersion } = webFilterPolicyInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await webFilter.updatePolicy({
                principal: request.principal,
                familyId,
                childId,
                change,
                expectedVersion,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'web_filter.policy.update',
                    principal: request.principal,
                    input: { familyId, childId, change, expectedVersion },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The father's preview: "what would my child get if they opened this?" answered by the
    // same rules the handset applies, so the preview cannot quietly disagree with the
    // filter. It is a read - it decides nothing and stores nothing.
    app.get(
        '/v1/families/:familyId/children/:childId/web-filter/evaluate',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const { host } = webFilterEvaluateQuery(request.query);
            const result = await webFilter.evaluate({
                principal: request.principal,
                familyId,
                childId,
                host,
            });
            response.status(200).json(result);
        }),
    );

    app.get(
        '/v1/families/:familyId/children/:childId/web-filter/temp-allows',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const result = await webFilter.listTempAllows({
                principal: request.principal,
                familyId,
                childId,
            });
            response.status(200).json(result);
        }),
    );

    // A question may be asked by a guardian on a child's behalf — a child who speaks rather
    // than taps still gets a record — and by the handset itself.
    app.post(
        '/v1/families/:familyId/children/:childId/web-filter/temp-allows',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const { host, minutes, reason } = tempAllowRequestInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await webFilter.requestTempAllow({
                principal: request.principal,
                familyId,
                childId,
                host,
                minutes,
                reason,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'web_filter.temp_allow.request',
                    principal: request.principal,
                    input: { familyId, childId, host, minutes, reason },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/children/:childId/web-filter/temp-allows/:requestId/decision',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const requestId = requireUuid(request.params.requestId, 'requestId');
            requireNoQueryParameters(request.query);
            const { decision, grantedMinutes } = tempAllowDecisionInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await webFilter.decideTempAllow({
                principal: request.principal,
                familyId,
                childId,
                requestId,
                decision,
                grantedMinutes,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'web_filter.temp_allow.decide',
                    principal: request.principal,
                    input: { familyId, childId, requestId, decision, grantedMinutes },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The handset asks for its own door. The device credential is the asker, which is why
    // there is no child id in this path.
    app.post(
        '/v1/devices/:deviceId/web-filter/temp-allow-requests',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            requireNoQueryParameters(request.query);
            const { host, minutes, reason } = tempAllowRequestInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await webFilter.requestTempAllow({
                principal: request.principal ?? { subject: `device:${deviceId}` },
                deviceId,
                deviceCredential: request.deviceCredential,
                host,
                minutes,
                reason,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'web_filter.temp_allow.device_request',
                    principal: { subject: `device:${deviceId}` },
                    input: { deviceId, host, minutes, reason },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // The policy the handset must apply. Read through the credential, so a device can only
    // ever fetch the policy of the child it was paired with.
    app.get(
        '/v1/devices/:deviceId/web-filter',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            requireNoQueryParameters(request.query);
            const result = await webFilter.readPolicyForDevice({
                deviceId,
                deviceCredential: request.deviceCredential,
            });
            response.status(200).json(result);
        }),
    );

    // A handset testifies about its own protection plane. Append-only: the server keeps
    // every report and derives what the family is told, so "protection was on all along"
    // is not a sentence this system can say.
    app.post(
        '/v1/devices/:deviceId/protection-reports',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            requireNoQueryParameters(request.query);
            const { observedState, signals, detail, observedAt } = protectionReportInput(request.body);
            const result = await webFilter.reportProtection({
                deviceId,
                deviceCredential: request.deviceCredential,
                observedState,
                signals,
                detail,
                observedAt,
                correlationId: request.correlationId,
            });
            response.status(201).json(result);
        }),
    );

    // What the family is shown. Every device in the family, each one carrying the state
    // computed from its newest report and the clock - and `unverified` where the honest
    // answer is that nobody has said anything lately.
    app.get(
        '/v1/families/:familyId/protection',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const result = await webFilter.readProtection({
                principal: request.principal,
                familyId,
            });
            response.status(200).json(result);
        }),
    );

    // ── W7 — family tasks and points ───────────────────────────────────────────────────
    //
    // The junction of protection and upbringing. These routes carry the one law a reward
    // system exists or dies by: a claim is not an achievement, and between the two stands a
    // person. No request body here can name a number of points, and no read here returns a
    // stored balance - the balance is a sum over an append-only ledger.

    // What this child has to do, each task with the cycle currently open on it.
    app.get(
        '/v1/families/:familyId/children/:childId/tasks',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const result = await tasks.listTasks({
                principal: request.principal,
                familyId,
                childId,
            });
            response.status(200).json(result);
        }),
    );

    // A guardian states a task. The points live on the task from this moment on, so the
    // confirmation later can only copy a number that was already agreed.
    app.post(
        '/v1/families/:familyId/children/:childId/tasks',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const { title, note, points } = taskCreateInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await tasks.createTask({
                principal: request.principal,
                familyId,
                childId,
                title,
                note,
                points,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'task.create',
                    principal: request.principal,
                    input: { familyId, childId, title, note, points },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // "I did it" for a child who spoke to a guardian instead of tapping their own phone.
    app.post(
        '/v1/families/:familyId/children/:childId/tasks/:taskId/claim',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const taskId = requireUuid(request.params.taskId, 'taskId');
            requireNoQueryParameters(request.query);
            const { note } = taskClaimInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await tasks.claimTask({
                principal: request.principal,
                familyId,
                childId,
                taskId,
                note,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'task.claim',
                    principal: request.principal,
                    input: { familyId, childId, taskId, note },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // The guardian's word. `confirm` makes the points real; `decline` awards nothing at all
    // and leaves the task open, so a child can try again rather than be closed out.
    app.post(
        '/v1/families/:familyId/children/:childId/tasks/:taskId/decision',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const taskId = requireUuid(request.params.taskId, 'taskId');
            requireNoQueryParameters(request.query);
            const { decision, note } = taskDecisionInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await tasks.decideTask({
                principal: request.principal,
                familyId,
                childId,
                taskId,
                decision,
                note,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'task.decision',
                    principal: request.principal,
                    input: { familyId, childId, taskId, decision, note },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The balance and the entries that produced it. Never a stored number.
    app.get(
        '/v1/families/:familyId/children/:childId/points',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            requireNoQueryParameters(request.query);
            const result = await tasks.readPoints({
                principal: request.principal,
                familyId,
                childId,
            });
            response.status(200).json(result);
        }),
    );

    // The child's own handset: its tasks, its balance, and the cycles on them - one read,
    // because on that phone it is one screen. No child id in the URL: the credential issued
    // at pairing is what proves which child is asking.
    app.get(
        '/v1/devices/:deviceId/tasks',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            requireNoQueryParameters(request.query);
            const result = await tasks.readTasksForDevice({
                deviceId,
                deviceCredential: request.deviceCredential,
            });
            response.status(200).json(result);
        }),
    );

    // "I did it", from the handset itself.
    app.post(
        '/v1/devices/:deviceId/tasks/:taskId/claim',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const taskId = requireUuid(request.params.taskId, 'taskId');
            requireNoQueryParameters(request.query);
            const { note } = taskClaimInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await tasks.claimTask({
                deviceId,
                deviceCredential: request.deviceCredential,
                taskId,
                note,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'task.claim.device',
                    principal: request.principal ?? { subject: deviceId },
                    input: { deviceId, taskId, note },
                }),
            });
            response.status(201).json(result);
        }),
    );


    // ── W8 — the family calendar ────────────────────────────────────────────────────────
    //
    // The first wave whose subject is not protection but attendance, and therefore the first
    // one where the product could start recording people instead of devices. Three rules are
    // visible in the routes themselves: events are cancelled rather than deleted, an edit
    // states the version it read, and attendance is written by a guardian rather than
    // inferred from a device. A reminder here is a preference a family recorded; nothing in
    // this surface claims a notification was delivered.

    // What the family agreed to do together, inside a window. Cancelled events are included
    // with their reason: a calendar that hid them would leave a child waiting.
    app.get(
        '/v1/families/:familyId/events',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const { from, to } = eventRangeQuery(request.query);
            const result = await calendar.listEvents({
                principal: request.principal,
                familyId,
                from,
                to,
            });
            response.status(200).json(result);
        }),
    );

    // A guardian states an event. The audience is part of the same request, because an event
    // nobody is invited to is a note rather than a plan.
    app.post(
        '/v1/families/:familyId/events',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const input = eventCreateInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await calendar.createEvent({
                principal: request.principal,
                familyId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.event.create',
                    principal: request.principal,
                    input: { familyId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // A guardian changes a plan - and states the version they read, so two guardians editing
    // the same evening collide loudly instead of silently overwriting each other.
    app.patch(
        '/v1/families/:familyId/events/:eventId',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const eventId = requireUuid(request.params.eventId, 'eventId');
            requireNoQueryParameters(request.query);
            const { version, changes } = eventUpdateInput(request.body);
            const result = await calendar.updateEvent({
                principal: request.principal,
                familyId,
                eventId,
                version,
                changes,
                correlationId: request.correlationId,
            });
            response.status(200).json(result);
        }),
    );

    // Calling an event off. A cancellation is an act with an author and a reason, not a row
    // that disappeared: the plan, its audience and its answers all remain readable.
    app.post(
        '/v1/families/:familyId/events/:eventId/cancel',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const eventId = requireUuid(request.params.eventId, 'eventId');
            requireNoQueryParameters(request.query);
            const { reason } = eventCancelInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await calendar.cancelEvent({
                principal: request.principal,
                familyId,
                eventId,
                reason,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.event.cancel',
                    principal: request.principal,
                    input: { familyId, eventId, reason },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // What actually happened, recorded by a guardian after the event started. Before it has
    // started there is nothing to record - only something to promise, and this surface does
    // not store promises about people.
    app.post(
        '/v1/families/:familyId/events/:eventId/attendance',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const eventId = requireUuid(request.params.eventId, 'eventId');
            requireNoQueryParameters(request.query);
            const { childId, attended, note } = eventAttendanceInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await calendar.recordAttendance({
                principal: request.principal,
                familyId,
                eventId,
                childId,
                attended,
                note,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.event.attendance',
                    principal: request.principal,
                    input: { familyId, eventId, childId, attended, note },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // A guardian records the answer a child gave in words. The author of this row is the
    // guardian, and the response body cannot say otherwise - the schema holds exactly one
    // author per answer.
    app.post(
        '/v1/families/:familyId/children/:childId/events/:eventId/response',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const childId = requireUuid(request.params.childId, 'childId');
            const eventId = requireUuid(request.params.eventId, 'eventId');
            requireNoQueryParameters(request.query);
            const { response: answer, note } = eventResponseInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await calendar.respondToEvent({
                principal: request.principal,
                familyId,
                childId,
                eventId,
                response: answer,
                note,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.event.response',
                    principal: request.principal,
                    input: { familyId, childId, eventId, response: answer, note },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The child's own handset: what they are invited to. No child id in the URL - the
    // credential issued at pairing is what proves which child is asking.
    app.get(
        '/v1/devices/:deviceId/events',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const { from, to } = eventRangeQuery(request.query);
            const result = await calendar.readEventsForDevice({
                deviceId,
                deviceCredential: request.deviceCredential,
                from,
                to,
            });
            response.status(200).json(result);
        }),
    );

    // The child's own answer, from their own handset. It cannot answer for a sibling: the
    // child is read from the device row, and the audience row must exist for that child.
    app.post(
        '/v1/devices/:deviceId/events/:eventId/response',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const eventId = requireUuid(request.params.eventId, 'eventId');
            requireNoQueryParameters(request.query);
            const { response: answer, note } = eventResponseInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await calendar.respondToEvent({
                deviceId,
                deviceCredential: request.deviceCredential,
                eventId,
                response: answer,
                note,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.event.response.device',
                    principal: request.principal ?? { subject: deviceId },
                    input: { deviceId, eventId, response: answer, note },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // ── W9 — the family chat ────────────────────────────────────────────────────────────
    //
    // The wave the master plan calls the biggest security risk in the domain, and every route
    // below shows why the risk is not the text: the room is the permission, the author comes
    // from how the request arrived rather than from a field in it, the sequence number is the
    // server's, an edit states the revision it read, and a deletion keeps the trace while
    // losing the text. The only receipt stated here is `readCount`, computed from participants'
    // own read marks - there is no delivery claim, because there is no transport to prove one.

    // The rooms the caller is in. A guardian sees the conversations they were added to and no
    // others: the module joins on the member row, so "not in the room" is not a filter that
    // could be forgotten - it is a row that does not exist.
    app.get(
        '/v1/families/:familyId/chat/threads',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const result = await familyChat.listThreads({
                principal: request.principal,
                familyId,
            });
            response.status(200).json(result);
        }),
    );

    // Opening a conversation. The participants are written by the same transaction as the room,
    // because a room that exists for a moment with nobody in it is not something any reader
    // should ever be able to observe.
    app.post(
        '/v1/families/:familyId/chat/threads',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            const input = chatThreadCreateInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.createThread({
                principal: request.principal,
                familyId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.thread.create',
                    principal: request.principal,
                    input: { familyId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // Adding one participant - the act that decides who can be reached. The guardian changing a
    // room must be in it, and only people of this family can be added: a chat that can reach
    // outside the family is the thing doc 40 forbids by name.
    app.post(
        '/v1/families/:familyId/chat/threads/:threadId/members',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            requireNoQueryParameters(request.query);
            const input = chatThreadMemberInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.addThreadMember({
                principal: request.principal,
                familyId,
                threadId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.member.add',
                    principal: request.principal,
                    input: { familyId, threadId, ...input },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // What was said, from the caller's own point of view. `afterSeq` is the incremental read:
    // without a push transport, a client asks for what it has not seen. A caller with no member
    // row on this thread is answered exactly as if the thread did not exist.
    app.get(
        '/v1/families/:familyId/chat/threads/:threadId/messages',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            const { afterSeq, limit } = chatMessageQuery(request.query);
            const result = await familyChat.listMessages({
                principal: request.principal,
                familyId,
                threadId,
                afterSeq,
                limit,
            });
            response.status(200).json(result);
        }),
    );

    // Saying something. The author is the caller's own membership - no field in the body can
    // name anybody - and the sequence is taken from the thread's own counter inside this
    // transaction, so ordering belongs to the server.
    app.post(
        '/v1/families/:familyId/chat/threads/:threadId/messages',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            requireNoQueryParameters(request.query);
            const { body, clientMessageId } = chatMessageInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.sendMessage({
                principal: request.principal,
                familyId,
                threadId,
                body,
                clientMessageId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.message.send',
                    principal: request.principal,
                    input: { familyId, threadId, body, clientMessageId },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // An edit states the revision it read and keeps the body it replaced, so a message that
    // changed is visible as changed. Only the author edits their own words.
    app.patch(
        '/v1/families/:familyId/chat/threads/:threadId/messages/:messageId',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            const messageId = requireUuid(request.params.messageId, 'messageId');
            requireNoQueryParameters(request.query);
            const { body, revision } = chatMessageEditInput(request.body);
            const result = await familyChat.editMessage({
                principal: request.principal,
                familyId,
                threadId,
                messageId,
                body,
                revision,
                correlationId: request.correlationId,
            });
            response.status(200).json(result);
        }),
    );

    // Deleting your own message: the text and the stored earlier versions go, the row, the
    // sequence and the trace stay. Nobody deletes somebody else's words here - not even a
    // guardian, which is the whole point.
    app.post(
        '/v1/families/:familyId/chat/threads/:threadId/messages/:messageId/deletion',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            const messageId = requireUuid(request.params.messageId, 'messageId');
            requireNoQueryParameters(request.query);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.deleteMessage({
                principal: request.principal,
                familyId,
                threadId,
                messageId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.message.delete',
                    principal: request.principal,
                    input: { familyId, threadId, messageId },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // "I have read up to here" - the participant's own statement about themselves, which is the
    // only kind of receipt this surface accepts. It cannot run past the newest message, and it
    // only ever moves forward.
    app.post(
        '/v1/families/:familyId/chat/threads/:threadId/reads',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            requireNoQueryParameters(request.query);
            const { readSeq } = chatReadInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.markThreadRead({
                principal: request.principal,
                familyId,
                threadId,
                readSeq,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.read',
                    principal: request.principal,
                    input: { familyId, threadId, readSeq },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The child's own handset: the rooms their child is in. No child id in the URL - the
    // credential issued at pairing is what proves which child is asking, the same decision
    // W5, W6, W7 and W8 each recorded for their own surface.
    app.get(
        '/v1/devices/:deviceId/chat/threads',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            requireNoQueryParameters(request.query);
            const result = await familyChat.listThreadsForDevice({
                deviceId,
                deviceCredential: request.deviceCredential,
            });
            response.status(200).json(result);
        }),
    );

    // The child reads their own conversation. The member row that must exist is the child's own,
    // so a handset cannot read a sibling's room even if it guessed the thread id.
    app.get(
        '/v1/devices/:deviceId/chat/threads/:threadId/messages',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            const { afterSeq, limit } = chatMessageQuery(request.query);
            const result = await familyChat.listMessages({
                deviceId,
                deviceCredential: request.deviceCredential,
                threadId,
                afterSeq,
                limit,
            });
            response.status(200).json(result);
        }),
    );

    // The child speaks. The author is the child the credential proves, never a child id typed
    // into a body, and the room must already name them.
    app.post(
        '/v1/devices/:deviceId/chat/threads/:threadId/messages',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            requireNoQueryParameters(request.query);
            const { body, clientMessageId } = chatMessageInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.sendMessage({
                deviceId,
                deviceCredential: request.deviceCredential,
                threadId,
                body,
                clientMessageId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.message.send.device',
                    principal: request.principal ?? { subject: deviceId },
                    input: { deviceId, threadId, body, clientMessageId },
                }),
            });
            response.status(201).json(result);
        }),
    );

    // The child changes or removes their OWN words, from their own handset. Same law as the
    // guardian surface and the same author check: the handset writes as its child, so a message
    // somebody else wrote is refused with `chat_not_author` however the request arrives.
    app.patch(
        '/v1/devices/:deviceId/chat/threads/:threadId/messages/:messageId',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            const messageId = requireUuid(request.params.messageId, 'messageId');
            requireNoQueryParameters(request.query);
            const { body, revision } = chatMessageEditInput(request.body);
            const result = await familyChat.editMessage({
                deviceId,
                deviceCredential: request.deviceCredential,
                threadId,
                messageId,
                body,
                revision,
                correlationId: request.correlationId,
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/devices/:deviceId/chat/threads/:threadId/messages/:messageId/deletion',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            const messageId = requireUuid(request.params.messageId, 'messageId');
            requireNoQueryParameters(request.query);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.deleteMessage({
                deviceId,
                deviceCredential: request.deviceCredential,
                threadId,
                messageId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.message.delete.device',
                    principal: request.principal ?? { subject: deviceId },
                    input: { deviceId, threadId, messageId },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The child's own read mark, from their own handset.
    app.post(
        '/v1/devices/:deviceId/chat/threads/:threadId/reads',
        requireTelemetryActor,
        deviceTelemetryRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const threadId = requireUuid(request.params.threadId, 'threadId');
            requireNoQueryParameters(request.query);
            const { readSeq } = chatReadInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await familyChat.markThreadRead({
                deviceId,
                deviceCredential: request.deviceCredential,
                threadId,
                readSeq,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'family.chat.read.device',
                    principal: request.principal ?? { subject: deviceId },
                    input: { deviceId, threadId, readSeq },
                }),
            });
            response.status(200).json(result);
        }),
    );

    // The roster read the Family Members screen is built on. Every membership the caller
    // is allowed to see, with `isSelf` decided here against the authenticated principal
    // rather than guessed by the client from an identifier the server never promised.
    app.get(
        '/v1/families/:familyId/memberships',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const result = await membershipRoster({
                principal: request.principal,
                familyId,
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/memberships',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const input = createMembershipInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.createMembershipInvitation({
                principal: request.principal,
                familyId,
                ...input,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'membership.create',
                    principal: request.principal,
                    input: { familyId, ...input },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/memberships/:membershipId/accept',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const membershipId = requireUuid(request.params.membershipId, 'membershipId');
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.acceptMembershipInvitation({
                principal: request.principal,
                familyId,
                membershipId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'membership.accept',
                    principal: request.principal,
                    input: { familyId, membershipId },
                }),
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/memberships/:membershipId/revoke',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const membershipId = requireUuid(request.params.membershipId, 'membershipId');
            const { reasonCode } = revokeMembershipInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.revokeMembership({
                principal: request.principal,
                familyId,
                membershipId,
                reasonCode,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'membership.revoke',
                    principal: request.principal,
                    input: { familyId, membershipId, reasonCode },
                }),
            });
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/guardian-transfers',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const { candidateMembershipId } = createGuardianTransferInput(request.body);
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.createGuardianTransfer({
                principal: request.principal,
                familyId,
                candidateMembershipId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'guardian_transfer.create',
                    principal: request.principal,
                    input: { familyId, candidateMembershipId },
                }),
            });
            response.status(201).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/guardian-transfers/:transferId/accept',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const transferId = requireUuid(request.params.transferId, 'transferId');
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.acceptGuardianTransfer({
                principal: request.principal,
                familyId,
                transferId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'guardian_transfer.accept',
                    principal: request.principal,
                    input: { familyId, transferId },
                }),
            });
            if (result.expired) {
                throw new HttpError(409, 'guardian_transfer_expired', 'Guardian transfer expired before acceptance.');
            }
            response.status(200).json(result);
        }),
    );

    app.post(
        '/v1/families/:familyId/guardian-transfers/:transferId/cancel',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            const transferId = requireUuid(request.params.transferId, 'transferId');
            const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
            const result = await store.cancelGuardianTransfer({
                principal: request.principal,
                familyId,
                transferId,
                idempotencyKey,
                correlationId: request.correlationId,
                requestHash: requestFingerprint({
                    action: 'guardian_transfer.cancel',
                    principal: request.principal,
                    input: { familyId, transferId },
                }),
            });
            response.status(200).json(result);
        }),
    );

    app.get(
        '/v1/families/:familyId/audit-events',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            response.status(200).json(await store.listAuditEvents({ principal: request.principal, familyId }));
        }),
    );

    // Server-owned permission explanation. It grants nothing: the role is
    // re-resolved from the durable membership on every call, and every
    // protected route re-checks authorization independently.
    app.get(
        '/v1/families/:familyId/permission-snapshot',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            response.status(200).json(await store.getFamilyPermissionSnapshot({
                principal: request.principal,
                familyId,
            }));
        }),
    );

    // AiEvent v1 read surface for the emitted fact history. Identifier-only and
    // guardian-scoped; it exposes no payload, token or provider material.
    app.get(
        '/v1/families/:familyId/ai-events',
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const familyId = requireUuid(request.params.familyId, 'familyId');
            requireNoQueryParameters(request.query);
            response.status(200).json(await store.listFamilyAiEvents({
                principal: request.principal,
                familyId,
            }));
        }),
    );

    app.use((_request, _response, next) => {
        next(new HttpError(404, 'route_not_found', 'Route was not found.'));
    });

    app.use((error, request, response, _next) => {
        const normalized = error ?.type === 'entity.parse.failed' ?
            new HttpError(400, 'invalid_json', 'Request body must contain valid JSON.') :
            asHttpError(error);
        const expectedUnavailableState = new Set([
            'identity_provider_not_configured',
            'database_not_configured',
            'service_not_ready',
        ]).has(normalized.code);
        if (normalized.status >= 500 && !expectedUnavailableState) {
            // Do not log request bodies, tokens, subjects, locations, or event payloads.
            console.error(JSON.stringify({
                severity: 'error',
                requestId: request.requestId,
                correlationId: request.correlationId,
                code: normalized.code,
                status: normalized.status,
            }));
        }
        const body = { error: { code: normalized.code, message: normalized.message } };
        if (normalized.details !== undefined) {
            body.error.details = normalized.details;
        }
        response.status(normalized.status).json(body);
    });

    return app;
}