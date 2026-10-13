import http from 'node:http';

import { attachChatRealtime } from './chat-realtime.js';
import { createRuntime } from './runtime.js';

const runtime = createRuntime();
if (runtime.configurationError) {
  // Never print environment values, URLs, tokens or secrets during a configuration failure.
  console.error(JSON.stringify({ severity: 'error', event: 'configuration_invalid', code: runtime.configurationError }));
}

const server = http.createServer(runtime.app);
// Due notifications are swept after each HTTP response in app.js and recovered once the listener
// starts below. Do not install a periodic timer: the free service may sleep, and durable retries
// resume on the next wake/request rather than pretending the process stays alive.
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
  server.close(async () => {
    await runtime.store.close();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
