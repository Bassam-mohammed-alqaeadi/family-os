import { createApp } from './app.js';
import { configurationReadiness, loadConfig, loadListeningPort } from './config.js';
import { DisabledAuthVerifier, OidcAuthVerifier } from './auth/oidc-verifier.js';
import { PostgresFoundationStore } from './store/postgres-foundation-store.js';
import { UnconfiguredFoundationStore } from './store/unconfigured-foundation-store.js';

function unavailableConfig(port, error) {
  return {
    config: {
      port,
      databaseUrl: undefined,
      guardianTransferTtlHours: undefined,
      oidc: undefined,
    },
    configurationError: error?.code ?? 'invalid_configuration',
  };
}

export function createRuntime(environment = process.env) {
  // A malformed Render PORT prevents any HTTP process from binding, so it remains a startup failure.
  const port = loadListeningPort(environment);
  let loaded;
  try {
    loaded = { config: loadConfig(environment), configurationError: undefined };
  } catch (error) {
    // Other configuration failures must not hide liveness or turn into an unauditable port-scan timeout.
    loaded = unavailableConfig(port, error);
  }

  const { config, configurationError } = loaded;
  const store = config.databaseUrl
    ? new PostgresFoundationStore({
        connectionString: config.databaseUrl,
        guardianTransferTtlHours: config.guardianTransferTtlHours,
      })
    : new UnconfiguredFoundationStore();
  const authVerifier = config.oidc ? new OidcAuthVerifier(config.oidc) : new DisabledAuthVerifier();
  const readiness = () => (
    configurationError
      ? { ready: false, missing: [], reason: configurationError }
      : configurationReadiness(config)
  );

  return {
    app: createApp({ store, authVerifier, readiness }),
    configurationError,
    port: config.port,
    store,
  };
}
