// The tree and keyboard tests of every technique, against the app's web
// build (flutter build web): web_tests/<id>_<name>.spec.js, one per folder
// in lib/techniques/. `npx playwright test` here runs them all.
//
// This config must never select a spec in vo/ (VoiceOver takes over the
// Mac) or the Widgetbook spec, which have configs of their own. Two rules
// make sure, each enough on its own: testMatch takes only file names like
// f08_radio_group.spec.js sitting directly in this folder, and testIgnore
// drops the vo/ folder and any *_vo.spec.js. check_spec_selection.js, run in
// CI, checks what this selects.
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from '@playwright/test';
import { ports, webServer } from './support/ports.js';

const here = path.dirname(fileURLToPath(import.meta.url));
// This checkout's own port; FA11Y_WEB_PORT overrides it (support/ports.js).
const port = ports().app;
const escape = (text) => text.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');

export default defineConfig({
  testDir: '.',
  testMatch: new RegExp(`^${escape(here + path.sep)}[a-z]\\d\\d_[a-z0-9_]+\\.spec\\.js$`),
  testIgnore: [
    new RegExp(`^${escape(path.join(here, 'vo') + path.sep)}`),
    /_vo\.spec\.js$/,
    /[\\/]node_modules[\\/]/,
  ],
  reporter: 'list',
  use: { baseURL: `http://127.0.0.1:${port}` },
  webServer: webServer('build/web', port),
});
