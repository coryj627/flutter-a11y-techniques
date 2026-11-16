// A static file server for the Playwright runs.
//
// Usage: node support/static_server.js <directory> <port>
//
// It replaces `python3 -m http.server`, which on some Macs binds its port and
// then spends half a minute or more on a host name lookup before it listens
// (http.server calls socket.getfqdn() at start-up). This one listens on
// 127.0.0.1 as soon as it starts and looks nothing up.
import { createServer } from 'node:http';
import { createReadStream, statSync } from 'node:fs';
import { extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.symbols': 'application/octet-stream',
  '.bin': 'application/octet-stream',
};

/** The file a request path names under root, or null if there is none. */
export function fileFor(root, urlPath) {
  let path;
  try {
    path = decodeURIComponent(urlPath.split('?')[0].split('#')[0]);
  } catch {
    return null;
  }
  if (path.includes('\0')) return null;
  const base = resolve(root);
  let file = resolve(join(base, path));
  // Nothing outside the served folder, whatever the path says.
  if (file !== base && !file.startsWith(base + sep)) return null;
  try {
    if (statSync(file).isDirectory()) file = join(file, 'index.html');
    return statSync(file).isFile() ? file : null;
  } catch {
    return null;
  }
}

export function serve(root, port) {
  // Fail at start, not on the first request, if there is no build to serve.
  if (!fileFor(root, '/')) {
    throw new Error(`${resolve(root)} has no index.html. Build it first (flutter build web).`);
  }
  const server = createServer((request, response) => {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      response.writeHead(405).end();
      return;
    }
    const file = fileFor(root, request.url ?? '/');
    if (!file) {
      response.writeHead(404, { 'content-type': 'text/plain' }).end('Not found');
      return;
    }
    response.writeHead(200, {
      'content-type': TYPES[extname(file).toLowerCase()] ?? 'application/octet-stream',
      'cache-control': 'no-store',
    });
    if (request.method === 'HEAD') {
      response.end();
      return;
    }
    createReadStream(file).on('error', () => response.destroy()).pipe(response);
  });
  return new Promise((done, failed) => {
    server.once('error', failed);
    server.listen(port, '127.0.0.1', () => done(server));
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [root, port] = process.argv.slice(2);
  if (!root || !/^\d+$/.test(port ?? '')) {
    console.error('Usage: node support/static_server.js <directory> <port>');
    process.exit(2);
  }
  serve(root, Number(port)).then(
    () => console.log(`Serving ${resolve(root)} on http://127.0.0.1:${port}`),
    (error) => {
      console.error(error.code === 'EADDRINUSE'
        ? `Port ${port} is in use. Another run may be serving a different build; `
          + 'stop it, or set a different port (see docs/parallel-work.md).'
        : String(error.message ?? error));
      process.exit(1);
    },
  );
}
