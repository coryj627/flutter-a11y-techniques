// L4 on web. VoiceOver needs a headed browser and one worker. Guidepup
// sometimes misses a phrase or VoiceOver's cursor leaves the page, so a failed
// walk is retried.
//
// Only `python3 tool/voiceover_web.py <ID>` runs this config. Without the
// variable it sets, the guard, imported first, stops the config loading.
import './voiceover_run_guard.js';
import { defineConfig, devices } from '@playwright/test';
import { screenReaderConfig } from '@guidepup/playwright';
import { ports, webServer } from '../support/ports.js';

const port = ports().app;

export default defineConfig({
  ...screenReaderConfig,
  testDir: '.',
  reporter: 'list',
  timeout: 3 * 60 * 1000,
  retries: 2,
  use: { baseURL: `http://127.0.0.1:${port}`, headless: false },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'], headless: false } },
    { name: 'webkit', use: { ...devices['Desktop Safari'], headless: false } },
  ],
  webServer: webServer('build/web', port),
});
