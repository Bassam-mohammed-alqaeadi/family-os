import { createHash, randomUUID } from 'node:crypto';
import express from 'express';
import { rateLimit } from 'express-rate-limit';
import { asHttpError, HttpError } from './http-error.js';
import {
    createChildInput,
    createFamilyInput,
    deviceTelemetryInput,
    registerFamilyChildDeviceInput,
    createGuardianTransferInput,
    createMembershipInput,
    revokeMembershipInput,
    requireIdempotencyKey,
    requireNoQueryParameters,
    requireUuid,
} from './validation.js';

function requestFingerprint({ action, principal, input }) {
    return createHash('sha256')
        .update(JSON.stringify({ action, subject: principal.subject, input }))
        .digest('hex');
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
        request.principal ? ? = await authVerifier.verify(request.get('Authorization'));
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
        windowMs: protectedRateLimit.windowMs ? ? 60 _000,
        limit: protectedRateLimit.limit ? ? 120,
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

    // This limit deliberately runs before token verification: malformed or
    // unauthorized traffic must not be able to exhaust identity or database work.
    // It uses Express's direct peer address rather than a client-supplied forwarding
    // header; the stricter subject limit below protects verified principals.
    app.use('/v1', rateLimit({
        windowMs: preAuthenticationRateLimit.windowMs ? ? ,
        limit: preAuthenticationRateLimit.limit ? ? 600,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        validate: { xForwardedForHeader: false },

        handler: (_request, _response, next) => {
            next(new HttpError(429, 'rate_limit_exceeded', 'Too many API requests. Try again later.'));
        },
    }));
    ن
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
                        configuration: configStatus.ready ? 'ready' : (configStatus.reason ? ? 'not_configured'),
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
        requirePrincipal,
        protectedApiRateLimit,
        requireRuntimeReady,
        asyncRoute(async(request, response) => {
            const deviceId = requireUuid(request.params.deviceId, 'deviceId');
            const input = deviceTelemetryInput(request.body);
            const result = await store.ingestDeviceTelemetry({
                principal: request.principal,
                deviceId,
                ...input,
                correlationId: request.correlationId,
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

    app.use((_request, _response, next) => {
        next(new HttpError(404, 'route_not_found', 'Route was not found.'));
    });

    app.use((error, request, response, _next) => {
        const normalized = error ? .type === 'entity.parse.failed' ?
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