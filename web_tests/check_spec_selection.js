// Checks which specs each Playwright config selects, and that the VoiceOver
// specs cannot load outside a VoiceOver run. Nothing here runs a test:
// `playwright test --list` only collects them.
//
// Run in web_tests/: node --test check_spec_selection.js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// The JSON listing of the default config passed execFileSync's 1 MiB default
// (ENOBUFS) once the suite reached about 1.05 MB of listing.
const LISTING_BUFFER = 64 * 1024 * 1024;

const here = path.dirname(fileURLToPath(import.meta.url));
const voDir = path.join(here, 'vo');
const GUARD = 'FLUTTER_A11Y_VOICEOVER_RUN';
const REFUSAL = /Refusing to load a VoiceOver spec/;
// Output is read, not shown; an error still carries it.
const QUIET = ['ignore', 'pipe', 'pipe'];

// The variable is never passed on to the commands below, so a check can
// never start a VoiceOver run, whatever the shell that runs it has set.
const environment = () => {
  const env = { ...process.env };
  delete env[GUARD];
  return env;
};

/** The spec files a config selects, relative to web_tests/, sorted. */
function listed(config) {
  const args = ['playwright', 'test', '--list', '--reporter=json', ...(config ? ['-c', config] : [])];
  const out = execFileSync('npx', args, { cwd: here, env: environment(), encoding: 'utf8', stdio: QUIET, maxBuffer: LISTING_BUFFER });
  const report = JSON.parse(out);
  assert.deepEqual(report.errors, [], `errors while listing ${config ?? 'the default config'}`);
  const root = report.config.rootDir;
  return [...new Set(report.suites.map((s) => path.relative(here, path.join(root, s.file))))].sort();
}

test('the default config selects exactly one tree spec per technique folder', () => {
  const techniques = fs.readdirSync(path.join(here, '..', 'lib', 'techniques'), { withFileTypes: true })
    .filter((e) => e.isDirectory()).map((e) => `${e.name}.spec.js`).sort();
  assert.ok(techniques.length > 0);
  for (const spec of techniques) {
    assert.ok(fs.existsSync(path.join(here, spec)), `every technique has a tree spec: ${spec}`);
  }
  const selected = listed(null);
  assert.deepEqual(selected, techniques);
  for (const file of selected) {
    assert.ok(!file.includes(path.sep), `${file} is not in a subfolder`);
    assert.ok(!file.endsWith('_vo.spec.js') && file !== 'widgetbook.spec.js', file);
  }
});

test('naming a VoiceOver or Widgetbook spec selects nothing with the default config', () => {
  for (const filter of ['vo/', '_vo', 'widgetbook', 'vo_helpers']) {
    const args = ['playwright', 'test', '--list', '--reporter=json', filter];
    let out;
    try {
      out = execFileSync('npx', args, { cwd: here, env: environment(), encoding: 'utf8', stdio: QUIET, maxBuffer: LISTING_BUFFER });
    } catch (error) {
      out = error.stdout; // "No tests found" exits non-zero
    }
    assert.deepEqual(JSON.parse(out).suites, [], filter);
  }
});

test('the Widgetbook and helper configs select only their own spec', () => {
  assert.deepEqual(listed('widgetbook.config.js'), ['widgetbook.spec.js']);
  assert.deepEqual(listed('vo_helpers.config.js'), ['vo_helpers.spec.js']);
});

test('every spec in vo/ imports vo_helpers.js, and vo_helpers.js imports the guard first', () => {
  const specs = fs.readdirSync(voDir).filter((f) => f.endsWith('.spec.js'));
  assert.ok(specs.length > 0);
  for (const spec of specs) {
    assert.match(spec, /^[a-z]\d\d_[a-z0-9_]+_vo\.spec\.js$/, `${spec} is named <id>_<name>_vo.spec.js`);
    const source = fs.readFileSync(path.join(voDir, spec), 'utf8');
    assert.match(source, /^import \{[^}]*\} from '\.\/vo_helpers\.js';$/m, `${spec} imports ./vo_helpers.js`);
  }
  for (const file of ['vo_helpers.js', 'playwright.config.js']) {
    const firstImport = fs.readFileSync(path.join(voDir, file), 'utf8').match(/^import .*$/m)[0];
    assert.equal(firstImport, "import './voiceover_run_guard.js';", `${file}: the guard is the first import`);
  }
});

// Each import below runs in a child node process with no Playwright and no
// VoiceOver: it loads the module and nothing else.
const importIn = (file, env) => {
  const script = `import(${JSON.stringify(path.join(voDir, file))})` +
    '.then(() => console.log("LOADED"), (e) => { console.log(e.message); process.exit(3); })';
  try {
    return execFileSync(process.execPath, ['-e', script], { env, encoding: 'utf8', stdio: QUIET });
  } catch (error) {
    return error.stdout;
  }
};

test('without the variable the VoiceOver helpers and config refuse to load', () => {
  assert.match(importIn('vo_helpers.js', environment()), REFUSAL);
  assert.match(importIn('playwright.config.js', environment()), REFUSAL);
  assert.match(importIn('vo_helpers.js', { ...environment(), [GUARD]: 'yes' }), REFUSAL);
});

test('with the variable the VoiceOver helpers load', () => {
  assert.match(importIn('vo_helpers.js', { ...environment(), [GUARD]: '1' }), /^LOADED$/m);
});
