// THROWAWAY: spike K5 diagnosis. Why does activating the browser time out?
import { execFile } from 'node:child_process';
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';

const osa = (script) =>
  new Promise((resolve) => {
    const t = Date.now();
    execFile('/usr/bin/osascript', ['-e', script], { timeout: 20000 }, (err, out, errOut) =>
      resolve(`${Date.now() - t}ms ${err ? 'ERR ' + (errOut || err.message).trim() : 'OK ' + out.trim()}`));
  });

test('diagnose activation and walk without it', async ({ page, voiceOver }) => {
  const id = 'com.google.chrome.for.testing';
  await page.goto('/#/t/X00/fixture', { waitUntil: 'load' });
  await expect(page.getByRole('button', { name: 'Save copy' })).toBeVisible();
  console.log('DIAG plain activate:', await osa(`tell application id "${id}" to activate`));
  console.log('DIAG transaction activate:', await osa(`tell application id "${id}"\nwith transaction\nactivate\nend transaction\nend tell`));
  console.log('DIAG frontmost app:', await osa('tell application "System Events" to get name of first process whose frontmost is true'));
  await page.bringToFront();
  await page.getByText('Good example for Spike fixture').click();
  const phrases = [];
  for (let i = 0; i < 20; i++) {
    await voiceOver.next();
    phrases.push(await voiceOver.lastSpokenPhrase());
  }
  console.log(`DIAG WALK ${JSON.stringify(phrases)}`);
});
