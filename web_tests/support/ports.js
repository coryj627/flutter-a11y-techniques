// Which ports the Playwright runs serve the web builds on.
//
// Each worktree of the repository gets its own pair, worked out from its
// path, so runs in two worktrees never share a server (and so never test
// each other's build). FA11Y_WEB_PORT and FA11Y_WIDGETBOOK_PORT override
// them.
import { createHash, randomUUID } from 'node:crypto';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

const FIRST = 20000;
const PAIRS = 5000; // ports 20000 to 29999, an even one and the odd one after it

/** The port pair for a checkout at this path. */
export function portsFor(root) {
  const hash = createHash('sha256').update(resolve(root)).digest();
  const app = FIRST + 2 * (hash.readUInt32BE(0) % PAIRS);
  return { app, widgetbook: app + 1 };
}

function fromEnv(name, fallback, env) {
  const value = env[name];
  if (value === undefined || value === '') return fallback;
  if (!/^\d+$/.test(value) || Number(value) < 1024 || Number(value) > 65535) {
    throw new Error(`${name} must be a port number from 1024 to 65535, not "${value}".`);
  }
  return Number(value);
}

/** The ports for this checkout, with any overrides from the environment. */
export function ports(env = process.env, root = REPO_ROOT) {
  const derived = portsFor(root);
  const chosen = {
    app: fromEnv('FA11Y_WEB_PORT', derived.app, env),
    widgetbook: fromEnv('FA11Y_WIDGETBOOK_PORT', derived.widgetbook, env),
  };
  if (chosen.app === chosen.widgetbook) {
    throw new Error('FA11Y_WEB_PORT and FA11Y_WIDGETBOOK_PORT must differ.');
  }
  return chosen;
}

/** The webServer entry for a Playwright config serving `directory`. */
export function webServer(directory, port) {
  const server = resolve(dirname(fileURLToPath(import.meta.url)), 'static_server.js');
  // Only the server started here answers this address. If another run got
  // the port first, ours exits, nothing answers, and the run fails; it never
  // goes on to test the other run's build.
  const token = randomUUID();
  return {
    command: `node "${server}" "${resolve(REPO_ROOT, directory)}" ${port} ${token}`,
    url: `http://127.0.0.1:${port}/__ready/${token}`,
    // Never borrow a server that is already there: it may belong to another
    // worktree and serve a different build.
    reuseExistingServer: false,
  };
}
