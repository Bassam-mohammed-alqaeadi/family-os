import http from 'node:http';

import { attachChatRealtime } from './chat-realtime.js';
import { createRuntime } from './runtime.js';

const runtime = createRuntime();
if (runtime.configurationError) {
  // Never print environment values, URLs, tokens or secrets during a configuration failure.
  console.error(JSON.stringify({ severity: 'error', event: 'configuration_invalid', code: runtime.configurationError }));
}

const server = http.createServer(runtime.app);
// The realtime hint channel rides the same HTTP server, on its own path, with the same credentials.
attachChatRealtime(server, {
  bus: runtime.chatBus,
  authVerifier: runtime.authVerifier,
  familyChat: runtime.app.locals.familyChat,
  ready: runtime.ready,
});
server.listen(runtime.port, '0.0.0.0', () => {
  console.log(JSON.stringify({ severity: 'info', event: 'server_started', port: runtime.port }));
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
