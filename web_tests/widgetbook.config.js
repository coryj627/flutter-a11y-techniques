// Runs widgetbook.spec.js against the Widgetbook web build
// (cd widgetbook && flutter build web).
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: '.',
  testMatch: process.env.WB_MATCH || 'widgetbook.spec.js',
  reporter: 'list',
  use: { baseURL: 'http://localhost:8766' },
  webServer: {
    command: 'python3 -m http.server 8766 --directory ../widgetbook/build/web',
    url: 'http://localhost:8766',
    reuseExistingServer: true,
  },
});
