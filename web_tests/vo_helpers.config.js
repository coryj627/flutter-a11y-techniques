// Runs vo_helpers.spec.js, the checks of the VoiceOver helpers that need
// neither VoiceOver nor a browser (macOS only, for osascript):
// npx playwright test -c vo_helpers.config.js
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: '.',
  testMatch: 'vo_helpers.spec.js',
  testIgnore: ['vo/**', '**/node_modules/**'],
  reporter: 'list',
});
