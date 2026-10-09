import { readdirSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const sourceDirectories = [
  ['src', '.js'],
  ['src/auth', '.js'],
  ['src/store', '.js'],
  ['scripts', '.mjs'],
];

for (const [directory, extension] of sourceDirectories) {
  const files = readdirSync(directory)
    .filter((file) => file.endsWith(extension))
    .sort();
  for (const file of files) {
    const result = spawnSync(process.execPath, ['--check', join(directory, file)], { stdio: 'inherit' });
    if (result.status !== 0) {
      process.exit(result.status ?? 1);
    }
  }
}
