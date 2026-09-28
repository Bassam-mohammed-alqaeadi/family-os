import { createHash, randomUUID } from 'node:crypto';
import express from 'express';
import { asHttpError, HttpError } from './http-error.js';
import {
  createFamilyInput,
  createGuardianTransferInput,
  createMembershipInput,
  revokeMembershipInput,
  requireIdempotencyKey,
  requirePathId,
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

export function createApp({ store, authVerifier, readiness }) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '64kb', strict: true }));
  app.use((request, response, next) => {
    request.requestId = safeRequestId(request.get('X-Request-Id'));
    response.set('X-Request-Id', request.requestId);
    next();
  });

  const requirePrincipal = asyncRoute(async (request, _response, next) => {
    request.principal ??= await authVerifier.verify(request.get('Authorization'));
    next();
  });

  const requireRuntimeReady = asyncRoute(async (_request, _response, next) => {
    const configStatus = readiness();
    const databaseStatus = await store.health();
    if (!configStatus.ready || !databaseStatus.available) {
      throw new HttpError(503, 'service_not_ready', 'The service is not ready for protected operations.');
    }
    next();
  });

  app.get('/health/live', (_request, response) => {
    response.status(200).json({ status: 'live' });
  });

  app.get(
    '/health/ready',
    asyncRoute(async (_request, response) => {
      const configStatus = readiness();
      const databaseStatus = await store.health();
      if (!configStatus.ready || !databaseStatus.available) {
        response.status(503).json({
          status: 'not_ready',
          dependencies: {
            configuration: configStatus.ready ? 'ready' : 'not_configured',
            database: databaseStatus.available ? 'ready' : databaseStatus.reason,
          },
        });
        return;
      }
      response.status(200).json({ status: 'ready' });
    }),
  );

  app.use('/v1', requirePrincipal, requireRuntimeReady);

  app.post(
    '/v1/families',
    requirePrincipal,
    asyncRoute(async (request, response) => {
      const input = createFamilyInput(request.body);
      const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
      const result = await store.createFamily({
        principal: request.principal,
        ...input,
        idempotencyKey,
        requestHash: requestFingerprint({ action: 'family.create', principal: request.principal, input }),
      });
      response.status(201).json(result);
    }),
  );

  app.get(
    '/v1/families/:familyId',
    requirePrincipal,
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      response.status(200).json(await store.getFamily({ principal: request.principal, familyId }));
    }),
  );

  app.post(
    '/v1/families/:familyId/memberships',
    requirePrincipal,
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      const input = createMembershipInput(request.body);
      const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
      const result = await store.createMembershipInvitation({
        principal: request.principal,
        familyId,
        ...input,
        idempotencyKey,
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
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      const membershipId = requirePathId(request.params.membershipId, 'membershipId');
      const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
      const result = await store.acceptMembershipInvitation({
        principal: request.principal,
        familyId,
        membershipId,
        idempotencyKey,
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
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      const membershipId = requirePathId(request.params.membershipId, 'membershipId');
      const { reasonCode } = revokeMembershipInput(request.body);
      const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
      const result = await store.revokeMembership({
        principal: request.principal,
        familyId,
        membershipId,
        reasonCode,
        idempotencyKey,
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
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      const { candidateMembershipId } = createGuardianTransferInput(request.body);
      const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
      const result = await store.createGuardianTransfer({
        principal: request.principal,
        familyId,
        candidateMembershipId,
        idempotencyKey,
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
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      const transferId = requirePathId(request.params.transferId, 'transferId');
      const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
      const result = await store.acceptGuardianTransfer({
        principal: request.principal,
        familyId,
        transferId,
        idempotencyKey,
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
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      const transferId = requirePathId(request.params.transferId, 'transferId');
      const idempotencyKey = requireIdempotencyKey(request.get('Idempotency-Key'));
      const result = await store.cancelGuardianTransfer({
        principal: request.principal,
        familyId,
        transferId,
        idempotencyKey,
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
    asyncRoute(async (request, response) => {
      const familyId = requirePathId(request.params.familyId, 'familyId');
      response.status(200).json(await store.listAuditEvents({ principal: request.principal, familyId }));
    }),
  );

  app.use((_request, _response, next) => {
    next(new HttpError(404, 'route_not_found', 'Route was not found.'));
  });

  app.use((error, request, response, _next) => {
    const normalized = error?.type === 'entity.parse.failed'
      ? new HttpError(400, 'invalid_json', 'Request body must contain valid JSON.')
      : asHttpError(error);
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
