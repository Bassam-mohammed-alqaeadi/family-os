import { createApp } from './app.js';
import { configurationReadiness, loadConfig } from './config.js';
import { DisabledAuthVerifier, OidcAuthVerifier } from './auth/oidc-verifier.js';
import { PostgresFoundationStore } from './store/postgres-foundation-store.js';
import { UnconfiguredFoundationStore } from './store/unconfigured-foundation-store.js';

const config = loadConfig();
const store = config.databaseUrl
  ? new PostgresFoundationStore({ connectionString: config.databaseUrl })
  : new UnconfiguredFoundationStore();
const authVerifier = config.oidc ? new OidcAuthVerifier(config.oidc) : new DisabledAuthVerifier();
const app = createApp({
  store,
  authVerifier,
  readiness: () => configurationReadiness(config),
});

const server = app.listen(config.port, '0.0.0.0', () => {
  console.log(JSON.stringify({ severity: 'info', event: 'server_started', port: config.port }));
});

async function shutdown(signal) {
  console.log(JSON.stringify({ severity: 'info', event: 'server_stopping', signal }));
  server.close(async () => {
    await store.close();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
