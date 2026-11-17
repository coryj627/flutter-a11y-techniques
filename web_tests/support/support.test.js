// Run: node --test support/   (in web_tests/)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileFor, serve } from './static_server.js';
import { ports, portsFor, webServer } from './ports.js';

function site() {
  const outer = mkdtempSync(join(tmpdir(), 'fa11y-static-'));
  const root = join(outer, 'web');
  mkdirSync(join(root, 'assets'), { recursive: true });
  writeFileSync(join(root, 'index.html'), '<title>app</title>');
  writeFileSync(join(root, 'main.dart.js'), 'main();');
  writeFileSync(join(root, 'assets', 'data.json'), '{}');
  writeFileSync(join(outer, 'secret.txt'), 'outside');
  return { outer, root };
}

test('serves files, the index for a folder, and 404 for anything else', async (t) => {
  const { outer, root } = site();
  const server = await serve(root, 0);
  t.after(() => { server.close(); rmSync(outer, { recursive: true }); });
  const base = `http://127.0.0.1:${server.address().port}`;

  const index = await fetch(`${base}/`);
  assert.equal(index.status, 200);
  assert.match(index.headers.get('content-type'), /^text\/html/);
  assert.equal(await index.text(), '<title>app</title>');

  const script = await fetch(`${base}/main.dart.js?v=1`);
  assert.match(script.headers.get('content-type'), /^text\/javascript/);
  assert.equal(await script.text(), 'main();');
  assert.equal((await fetch(`${base}/assets/data.json`)).headers.get('content-type'), 'application/json');

  assert.equal((await fetch(`${base}/missing.js`)).status, 404);
  assert.equal((await fetch(`${base}/assets/`)).status, 404); // a folder with no index
  assert.equal((await fetch(`${base}/`, { method: 'POST' })).status, 405);
  const head = await fetch(`${base}/`, { method: 'HEAD' });
  assert.equal(head.status, 200);
  assert.equal(await head.text(), '');
});

test('never serves a file outside the folder', () => {
  const { outer, root } = site();
  try {
    assert.equal(fileFor(root, '/../secret.txt'), null);
    assert.equal(fileFor(root, '/%2e%2e/secret.txt'), null);
    assert.equal(fileFor(root, '/assets/../../secret.txt'), null);
    assert.equal(fileFor(root, '/%E0%A4%A'), null); // not valid encoding
    assert.equal(fileFor(root, '/index.html%00.js'), null);
    assert.equal(fileFor(root, '/assets/../index.html'), join(root, 'index.html'));
  } finally {
    rmSync(outer, { recursive: true });
  }
});

test('refuses to start with no build to serve', async () => {
  const empty = mkdtempSync(join(tmpdir(), 'fa11y-static-'));
  try {
    await assert.rejects(async () => serve(empty, 0), /has no index\.html/);
  } finally {
    rmSync(empty, { recursive: true });
  }
});

test('a port in use is an error, not a shared server', async (t) => {
  const { outer, root } = site();
  const first = await serve(root, 0);
  t.after(() => { first.close(); rmSync(outer, { recursive: true }); });
  await assert.rejects(serve(root, first.address().port), { code: 'EADDRINUSE' });
});

test('each checkout path gets its own stable pair of ports', () => {
  const a = portsFor('/work/repo');
  assert.deepEqual(a, portsFor('/work/repo'));
  assert.deepEqual(a, portsFor('/work/repo/'));
  assert.equal(a.widgetbook, a.app + 1);
  assert.ok(a.app >= 20000 && a.widgetbook <= 29999);
  const seen = new Set();
  for (let i = 0; i < 40; i++) seen.add(portsFor(`/work/repo/.claude/worktrees/wave-${i}`).app);
  assert.ok(seen.size >= 39, 'forty worktree paths should not share ports');
});

test('the environment overrides the ports, and bad values are refused', () => {
  const root = '/work/repo';
  assert.deepEqual(ports({}, root), portsFor(root));
  assert.deepEqual(ports({ FA11Y_WEB_PORT: '', FA11Y_WIDGETBOOK_PORT: '' }, root), portsFor(root));
  assert.deepEqual(ports({ FA11Y_WEB_PORT: '8765', FA11Y_WIDGETBOOK_PORT: '8766' }, root),
    { app: 8765, widgetbook: 8766 });
  assert.equal(ports({ FA11Y_WEB_PORT: '8765' }, root).widgetbook, portsFor(root).widgetbook);
  assert.throws(() => ports({ FA11Y_WEB_PORT: 'abc' }, root), /FA11Y_WEB_PORT must be a port/);
  assert.throws(() => ports({ FA11Y_WEB_PORT: '80' }, root), /must be a port/);
  assert.throws(() => ports({ FA11Y_WIDGETBOOK_PORT: '70000' }, root), /must be a port/);
  assert.throws(() => ports({ FA11Y_WEB_PORT: '9000', FA11Y_WIDGETBOOK_PORT: '9000' }, root), /must differ/);
});

test('the Playwright web server entry never reuses a running server', () => {
  const entry = webServer('build/web', 21000);
  assert.equal(entry.reuseExistingServer, false);
  const token = entry.url.match(/^http:\/\/127\.0\.0\.1:21000\/__ready\/([\w-]{20,})$/)?.[1];
  assert.ok(token, entry.url);
  assert.ok(entry.command.endsWith(` 21000 ${token}`));
  assert.match(entry.command, /^node ".*static_server\.js" ".*build\/web" 21000 /);
  assert.notEqual(webServer('build/web', 21000).url, entry.url, 'a new token for every run');
});

test('only the server that was started with a token answers its ready address', async (t) => {
  const { outer, root } = site();
  const first = await serve(root, 0, 'token-of-the-first');
  t.after(() => { first.close(); rmSync(outer, { recursive: true }); });
  const port = first.address().port;
  const base = `http://127.0.0.1:${port}`;
  assert.equal((await fetch(`${base}/__ready/token-of-the-first`)).status, 200);
  // A second run on the same port fails to start, and the first server
  // does not answer for it: its wait can never succeed against this build.
  await assert.rejects(serve(root, port, 'token-of-the-second'), { code: 'EADDRINUSE' });
  assert.equal((await fetch(`${base}/__ready/token-of-the-second`)).status, 404);
  assert.equal((await fetch(`${base}/__ready/`)).status, 404);
  // Without a token there is no ready address at all.
  const plain = await serve(root, 0);
  t.after(() => plain.close());
  assert.equal((await fetch(`http://127.0.0.1:${plain.address().port}/__ready/undefined`)).status, 404);
});
