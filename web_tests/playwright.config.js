import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: '.',
  reporter: 'list',
  use: { baseURL: 'http://localhost:8765' },
  webServer: {
    command: 'python3 -m http.server 8765 --directory ../build/web',
    url: 'http://localhost:8765',
    reuseExistingServer: true,
  },
});
