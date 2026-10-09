import { createApp } from './app.js';
import { configurationReadiness, loadConfig, loadListeningPort } from './config.js';
import { DisabledAuthVerifier, OidcAuthVerifier } from './auth/oidc-verifier.js';
import { PostgresFoundationStore } from './store/postgres-foundation-store.js';
import { createChatEventBus } from './chat-realtime.js';
import { LocalDiskChatMediaStore } from './chat-media-store.js';
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

  // Fail fast on a relative media directory: a silently ignored storage setting is worse than a
  // refused start. The error names the variable only, never its value.
  const chatMediaStore = config.chatMediaDirectory
    ? new LocalDiskChatMediaStore({ root: config.chatMediaDirectory })
    : null;
  const chatBus = createChatEventBus();
  const app = createApp({ store, authVerifier, readiness, chatMediaStore, chatBus });

  // What the realtime gateway needs: the same verifier, the same store-backed readiness, and the
  // same bus the routes publish to.
  const ready = async () => {
    const configStatus = readiness();
    if (!configStatus.ready) return false;
    const databaseStatus = await store.health();
    return databaseStatus.available === true;
  };

  return {
    app,
    authVerifier,
    chatBus,
    ready,
    configurationError,
    port: config.port,
    store,
  };
}
