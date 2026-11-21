# C03 probe: what a stand-alone link built from the SDK exposes

Run on 2026-11-20, Flutter 3.47.5, before the C03 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: fourteen fixtures, `p01` to `p14`, one per route (`/p01` …), each
between a "Before pNN" text and a "pNN taps: N" text that counts the taps
that reached its handler. `/dest` is an in-app destination; the fixtures
with `linkUrl: '#/dest'` point at it, and opening it prints how often it
has been opened. `https://example.com/c03` is the external address of the
others.

| # | Fixture |
| --- | --- |
| p01 | `Semantics(link: true)` round a `GestureDetector`, no `linkUrl` |
| p02 | `Semantics(link: true, linkUrl: https://example.com/c03)` round a `GestureDetector` |
| p03 | as p02, with `linkUrl: '#/dest'` |
| p04 | `Semantics(link: true, linkUrl: '#/dest')` round an `InkWell` |
| p05 | `Semantics(link: true, linkUrl: '#/dest')` round a `Focus` with no actions and a `GestureDetector` |
| p06 | p04 with Enter and Space bound to `DoNothingAndStopPropagationIntent` above it (on every platform in the probe) |
| p07 | `Semantics(link: true, linkUrl:)` round a `TextButton` |
| p08 | `Semantics(link: true, linkUrl:)` round a `CupertinoButton` |
| p09 | picture link: `Semantics(link: true, linkUrl:, label:)` round an `InkWell` and an excluded `Image` |
| p10 | picture link with the name on the `Image` (`semanticLabel`) |
| p11 | picture link with no name, the `Image` not excluded |
| p12 | `url_launcher`'s `Link` with a `TextButton` builder (followed only on the web) |
| p13 | p02's link round an `InkWell`, with `onTapHint: 'open in browser'` |
| p14 | underlined text in a `GestureDetector`, no `Semantics` |

How each platform was looked at, and the raw output:

- Web: Chromium, Playwright, `c03_probe.spec.js.txt` with
  `c03probe.config.js.txt`, against `flutter build web -t lib/probe.dart`.
  For each fixture: its element in the semantics DOM, Chromium's own
  accessibility tree over the DevTools protocol, the ARIA snapshot; then,
  each from a fresh load, a mouse click, Tab to it and Enter, Tab to it and
  Space, and a Command-click. A key that did nothing was followed, in the
  same load, by a click, the positive control. `https://example.com` was
  answered with a stub page. Output: `web.txt` (the StaticText and
  InlineTextBox lines of the accessibility tree were left out).
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeC03Test.kt.txt`, run by `probe_android.py.txt` with
  `am instrument`: `probe()` dumps every node of each fixture with its
  content description's spans and its actions, then performs
  `ACTION_CLICK` on the fixture's node (`android-tree.txt`);
  `talkBackWalk()` moves TalkBack focus to each fixture with TalkBack on,
  through the project's `tool/talkback.py` (`android-talkback.md`). A native
  comparison, `ProbeNativeActivity.kt.txt` (declared for the run in the
  debug manifest), was read the same way (`android-tree-native.txt`,
  `android-talkback-native.md`).
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeC03UITests.swift.txt` run by
  `ios_probe.sh.txt`: the XCUITest tree and a tap; Tab, Tab, then Enter or
  Space from a fresh launch; and with VoiceOver on, a walk from the top and
  a double tap on the fixture. Output: `ios.txt`. XCUITest element types:
  9 button, 42 link, 43 image, 48 static text.

After the examples were built, `web_twice.spec.js.txt` (run with the
same config against the app's own build) followed
`/t/C03/bad-app-also-follows` five times each by a mouse click
(`web_twice.txt`), by Tab and Enter (`web_twice_enter.txt`), and by a DOM
click with no pointer events (`web_twice_dispatch.txt`), with
`good-material` once each as the comparison: the address, the page's
level 1 heading and `history.length` over two and a half seconds, then
what the app's Back does.

## Web

| # | Element | Chromium's role and name | Click | Enter | Space |
| --- | --- | --- | --- | --- | --- |
| p01 | `<a>`, no `href`, no `tabindex` | link "p01 link only"; Playwright's snapshot: text | `onTap` | not reached by Tab | not reached |
| p02 | `<a href="https://…">`, no `tabindex` | link, `url` set | the browser follows the `href` | reached by the second Tab; the browser follows it | nothing |
| p03 | `<a href="#/dest">` | link | the browser follows it, and the app opens `/dest` | the same | nothing |
| p04 | `<a href="#/dest" tabindex="0">` | link | the browser follows it | `onTap` only; not followed | `onTap` only |
| p05 | `<a href="#/dest" tabindex="0">` | link | followed | followed | nothing |
| p06 | `<a href="#/dest" tabindex="0">` | link | followed | followed | nothing |
| p07 | `<a href>` holding a `role="button"` | link holding button | followed | the button's `onPressed` only | `onPressed` only |
| p08 | one `<a href tabindex="0">` | link | followed | followed | `onPressed` only |
| p09 | `<a href>` with the label | link "p09 image link" | followed | `onTap` only | `onTap` only |
| p10 | `<a href>` holding `role="img"` with the label | link named from the image | followed | (the probe tabbed to the image, which takes no focus) | |
| p11 | `<a href>` holding an unnamed `role="button"` | link, no name | (no element found by name) | | |
| p12 | `<a href tabindex="0">` | link | `onPressed`, and a second tab opened by `launchUrl` | `onPressed`, and the second tab | `onPressed`, and the second tab |
| p13 | `<a href tabindex="0">` | link; the tap hint is not in the page | followed | `onTap` only | `onTap` only |
| p14 | `role="button"`, no `tabindex` | button | `onTap` | not reached | not reached |

A Command-click on every fixture with an `href` that the probe found (all
but p11) opened it in a second tab, and ran the fixture's `onTap` in the
first.

## Android

From `android-tree.txt` and `android-talkback.md`:

| # | Class | Address in the description | TalkBack, focus moved to it |
| --- | --- | --- | --- |
| p01 | `Button` | none | "p01 link only / Button / Double-tap to activate" |
| p02, p03, p04, p05, p06 | `View` | `URLSpan` with the address | "pNN … / Double-tap to activate" |
| p07 | an unnamed `View` with no address round a `Button` | none | the button: "p07 text button / Button / Double-tap to activate" |
| p08 | `Button` | `URLSpan` | "p08 cupertino button / Button / Double-tap to activate" |
| p09 | `View` | `URLSpan` | "p09 image link / Double-tap to activate" |
| p10 | a clickable `View` with no name and no address, round an `ImageView` with the name | none | the image: "p10 image label / Image" |
| p11 | `ImageView`, clickable, no name | none | "Button / Double-tap to activate" |
| p12 | `Button` | none | "p12 url launcher link / Button / Double-tap to activate" |
| p13 | `View`, click action labelled "open in browser" | `URLSpan` | "p13 link tap hint / Double-tap to open in browser" |
| p14 | `View` | none | "p14 looks like a link / Double-tap to activate" |

`ACTION_CLICK` ran the fixture's handler on every fixture but p10, where
the node found was the picture, which takes no click. No fixture opened
`/dest` or the browser: off the web nothing follows the address.

Native comparison, the same way (`android-tree-native.txt`,
`android-talkback-native.md`):

| # | Native view | TalkBack |
| --- | --- | --- |
| n01 | `TextView` whose whole text is a `URLSpan`, with `LinkMovementMethod`, no click listener | nothing in the 6 seconds after focus moved to it; why was not found |
| n02 | clickable `View` whose content description has the `URLSpan`, the shape of Flutter's node | "n02 native link description / Double-tap to activate" |
| n03 | clickable `TextView` whose text is a `URLSpan` | "n03 native clickable link text / Double-tap to activate. Actions available, use Tap with 3 fingers to view" |

So TalkBack says no role for a native link either, as the Android Compose
reference says; a link in a native view's text is offered among TalkBack's
actions, and the address in a content description, where Flutter puts it,
is not. What the actions menu lists was not looked at.

## iOS

From `ios.txt`:

| # | XCUITest | VoiceOver | Tab, Tab, Enter / Space |
| --- | --- | --- | --- |
| p01, p02, p03 | link | "pNN … Link" | nothing / nothing |
| p04 | link | "p04 inkwell dest Link" | `onTap` / `onTap` |
| p05 | link | "p05 focus dest Link" | nothing / nothing |
| p06 | link | "p06 … Link" | nothing / nothing (its keys go nowhere off the web too) |
| p07 | a link with no label holding a button | one stop: "p07 text Button" | `onPressed` / `onPressed` |
| p08 | button | "p08 cupertino Button Link" | `onPressed` / `onPressed` |
| p09 | link | "p09 image link Link" | `onTap` / `onTap` |
| p10 | a link with no label and an image with the label | "Link", then "p10 image label Image" | `onTap` / `onTap` |
| p11 | a link with no label and an image with none | "Image" | `onTap` / `onTap` |
| p12 | button | "p12 url launcher link Button" | `onPressed` / `onPressed` |
| p13 | link | "p13 link tap hint Link" (no hint heard) | `onTap` / `onTap` |
| p14 | static text | "p14 looks like a link" | nothing / nothing |

A tap and VoiceOver's double tap ran the handler on every fixture the probe
found by its label (all but p11); neither opened `/dest`, whatever the
`linkUrl`.

## What it shows

- **The web needs `linkUrl`, and then the browser does the following.**
  `link: true` alone is an `<a>` with no `href`, which HTML gives no link
  role, though Chromium's own tree calls it a link (p01). With `linkUrl` it
  is a real `<a href>` (p02 to p13): the browser follows it on a click, on
  Enter when no Flutter widget takes the key, and in a new tab on
  Command-click, and it is reached by Tab even with no `Focus` widget. An
  in-app address after the `#` opens the app's route (p03 to p06).
- **Enter reaches the anchor only if no widget takes it.** `InkWell`,
  `TextButton`, and picture links built on `InkWell` take it (p04, p07,
  p09, p13); `Focus`, `GestureDetector`, and `CupertinoButton` (FL-002) do
  not (p03, p05, p08). Binding Enter to `DoNothingAndStopPropagationIntent`
  above an `InkWell` hands it to the browser (p06).
- **Android has no link role in speech.** With `linkUrl` the node is a
  `View` with the address in a `URLSpan`, and TalkBack says the name and
  "Double-tap to activate", no role (p02 to p06, p09), as it does for the
  native views (n02, n03). Without it, a `Button` (p01). `onTapHint`
  changes "activate" to the hint (p13), as the Android Compose reference
  does with `onClickLabel`. FL-220.
- **On Android the address rides on the label.** A link node with no label
  of its own has no `URLSpan` (p07, p10, p11).
- **iOS reads `link: true`, not `linkUrl`.** Every link fixture is a link
  with or without an address; nothing follows the address.
- **A link round a Material or Cupertino button is a button** (p07, p08):
  VoiceOver says "Button Link" for the Cupertino one, and TalkBack
  "Button" for both. FL-221.
- **A name on the `Image` inside a link does not name the link** on
  Android and iOS (p10), as FL-030 found for buttons; the web names the
  link from the image.
- **`url_launcher`'s `Link` is a button off the web** (p12): it adds no
  semantics there. On the web it is a link, and in the probe a click and
  Enter opened the address in a second tab by `launchUrl`.
- **A tap hint is Android only** (p13): VoiceOver said none, and the web
  page has none.
