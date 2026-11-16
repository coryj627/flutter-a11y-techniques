// Runs widgetbook.spec.js against the Widgetbook web build
// (cd widgetbook && flutter build web).
import { defineConfig } from '@playwright/test';
import { ports, webServer } from './support/ports.js';

const port = ports().widgetbook;
export default defineConfig({
  testDir: '.',
  testMatch: process.env.WB_MATCH || 'widgetbook.spec.js',
  // Whatever WB_MATCH says, never a VoiceOver spec.
  testIgnore: ['vo/**', '**/*_vo.spec.js', '**/node_modules/**'],
  reporter: 'list',
  use: { baseURL: `http://127.0.0.1:${port}` },
  webServer: webServer('widgetbook/build/web', port),
});
