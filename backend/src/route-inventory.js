/**
 * The live route inventory, read from the application itself.
 *
 * Why this exists: the contract test used to compare the OpenAPI specification against a
 * hand-written list of operations inside the test file. Two hand-maintained lists will
 * always agree with each other eventually, so a route could be added to `app.js` and
 * never to the published contract - which is exactly what happened with device
 * revocation, a real route that the contract did not declare and no test complained about.
 *
 * This module removes the second list. It builds the real application and asks Express for
 * the routes it actually registered, so the comparison is between the code and the
 * contract, with nothing in between.
 *
 * Express reports paths in `:param` form; OpenAPI declares them in `{param}` form. The
 * translation is the only thing this module does to the data, and it is asserted in the
 * tests so it cannot silently mangle a path shape.
 */

/** A store stub: route registration must not depend on a database being reachable. */
function registrationOnlyStore() {
  const refuse = async () => {
    throw new Error('The route inventory must never call the store.');
  };
  return {
    configured: false,
    health: refuse,
    listMyFamilies: refuse,
    getFamily: refuse,
    listFamilyChildren: refuse,
    createFamilyChild: refuse,
    listFamilyDevices: refuse,
    registerFamilyChildDevice: refuse,
    createDevicePairing: refuse,
    claimDevicePairing: refuse,
    ingestDeviceTelemetry: refuse,
    createFamily: refuse,
    createMembershipInvitation: refuse,
    acceptMembershipInvitation: refuse,
    revokeMembership: refuse,
    createGuardianTransfer: refuse,
    acceptGuardianTransfer: refuse,
    cancelGuardianTransfer: refuse,
    listAuditEvents: refuse,
    getFamilyPermissionSnapshot: refuse,
    listFamilyAiEvents: refuse,
  };
}

/** Express `:param` becomes the OpenAPI `{param}` the specification uses. */
export function toOpenApiPath(expressPath) {
  return expressPath.replace(/:([A-Za-z0-9_]+)/g, '{$1}');
}

/**
 * Every operation the running application actually exposes.
 *
 * @returns {Promise<Array<{ method: string, path: string }>>} sorted, method uppercased,
 *   path in OpenAPI form.
 */
export async function liveRouteInventory() {
  // Imported here rather than at module load so a test that only wants the translation
  // helper does not build an application.
  const { createApp } = await import('./app.js');
  const app = createApp({
    store: registrationOnlyStore(),
    authVerifier: {
      configured: false,
      async verify() {
        throw new Error('The route inventory must never authenticate a request.');
      },
    },
    readiness: () => ({ ready: false, missing: ['route-inventory'] }),
    // Rate limiting is irrelevant to registration and must not be keyed by a real client.
    preAuthenticationRateLimit: { windowMs: 60_000, limit: 1_000 },
    protectedRateLimit: { windowMs: 60_000, limit: 1_000 },
  });

  const stack = app.router?.stack ?? app._router?.stack ?? [];
  const operations = [];
  for (const layer of stack) {
    if (!layer.route) continue;
    for (const method of Object.keys(layer.route.methods)) {
      operations.push({ method: method.toUpperCase(), path: toOpenApiPath(layer.route.path) });
    }
  }

  return operations.sort(
    (left, right) =>
      left.path.localeCompare(right.path) || left.method.localeCompare(right.method),
  );
}

/** The same inventory as a set of `METHOD /path` keys, for set comparison. */
export async function liveRouteKeys() {
  return new Set((await liveRouteInventory()).map((route) => `${route.method} ${route.path}`));
}

/** Every operation the published contract declares, as the same `METHOD /path` keys. */
export function declaredRouteKeys(specification) {
  const keys = new Set();
  for (const [path, operations] of Object.entries(specification.paths ?? {})) {
    for (const method of Object.keys(operations)) {
      keys.add(`${method.toUpperCase()} ${path}`);
    }
  }
  return keys;
}
