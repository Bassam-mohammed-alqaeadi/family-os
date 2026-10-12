import http from 'node:http';

import { attachChatRealtime } from './chat-realtime.js';
import { createRuntime } from './runtime.js';

const runtime = createRuntime();
if (runtime.configurationError) {
  // Never print environment values, URLs, tokens or secrets during a configuration failure.
  console.error(JSON.stringify({ severity: 'error', event: 'configuration_invalid', code: runtime.configurationError }));
}

const server = http.createServer(runtime.app);
const notificationSweepInterval = setInterval(() => {
  Promise.resolve(runtime.notificationDispatcher?.sweep({ limit: 20 }))
    .catch((error) => console.error(JSON.stringify({
      severity: 'error',
      event: 'notification_periodic_sweep_failed',
      errorName: error?.name ?? 'Error',
    })));
}, 5_000);
// HTTP traffic is not a retry scheduler: keep due durable outbox work moving even when
// no guardian requests arrive. Each sweep claims only rows whose persisted backoff elapsed.
notificationSweepInterval.unref();
// The realtime hint channel rides the same HTTP server, on its own path, with the same credentials.
attachChatRealtime(server, {
  bus: runtime.chatBus,
  authVerifier: runtime.authVerifier,
  familyChat: runtime.app.locals.familyChat,
  ready: runtime.ready,
});
server.on('afterStart', () => {
  Promise.resolve(runtime.notificationDispatcher?.bootSweep())
    .catch((error) => console.error(JSON.stringify({
      severity: 'error',
      event: 'notification_boot_sweep_failed',
      errorName: error?.name ?? 'Error',
    })));
});
server.listen(runtime.port, '0.0.0.0', () => {
  console.log(JSON.stringify({ severity: 'info', event: 'server_started', port: runtime.port }));
  server.emit('afterStart');
});

async function shutdown(signal) {
  console.log(JSON.stringify({ severity: 'info', event: 'server_stopping', signal }));
  clearInterval(notificationSweepInterval);
  server.close(async () => {
    await runtime.store.close();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
