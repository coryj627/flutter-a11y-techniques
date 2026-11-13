// L4 on web. VoiceOver needs a headed browser and one worker. Guidepup
// sometimes misses a phrase or VoiceOver's cursor leaves the page, so a failed
// walk is retried.
import { defineConfig, devices } from '@playwright/test';
import { screenReaderConfig } from '@guidepup/playwright';

export default defineConfig({
  ...screenReaderConfig,
  testDir: '.',
  reporter: 'list',
  timeout: 3 * 60 * 1000,
  retries: 2,
  use: { baseURL: 'http://localhost:8765', headless: false },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'], headless: false } },
    { name: 'webkit', use: { ...devices['Desktop Safari'], headless: false } },
  ],
  webServer: {
    command: 'python3 -m http.server 8765 --directory ../../build/web',
    url: 'http://localhost:8765',
    reuseExistingServer: true,
  },
});
