# Spec: C03 Stand-alone link

Status: Draft 1 (2026-11-20), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

A stand-alone link is a link on its own, not inside a sentence. Links inside
text are C04 Links inline with text. What a button is, is
[C01 Button](C01-button.md); how big a link must be, V13; how its focus is
shown, V14. Image buttons are [S04 Functional images](S04-functional-images.md),
which left image links to this entry.

## 1. Rule

A link that stands on its own has the link role where the platform has one,
a name that says where it goes, and is followed once by a tap, by the
keyboard, and by a screen reader. A picture that is a link has the name on
the link.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Android has no link role that a node can declare, and TalkBack says no role
for a Flutter link; see section 7 and [FL-220](../flutter-limitations.md#fl-220).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.4.4 Link Purpose (In Context)](https://www.w3.org/TR/WCAG22/#link-purpose-in-context) | The link's name, alone or with its context, says where it goes |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The link has a name and a role that assistive technology can read |

A stand-alone link here has no programmatic context: nothing in the same
sentence, paragraph, list item, or table cell, and no heading but the
screen's "Example". So for 2.4.4 its name must say where it goes by itself.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The link's text says where it goes; "click here" and "read more" do not | [iOS Links](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Links.md) ("unique and specific label text"), [Android Compose Stand-alone Links](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/StandAloneLinks.md) ("Link text must convey its purpose"), [MDN `a`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a) (link text), [WCAG failure F84](https://www.w3.org/WAI/WCAG22/Techniques/failures/F84) |
| R2 | The element has the link role, from a native link element where there is one | [APG Link](https://www.w3.org/WAI/ARIA/apg/patterns/link/) ("strongly encouraged to use a native host language link element"), MDN `a` (an `a` without `href` has the generic role) |
| R3 | A link is not also a button | iOS Links (remove the button trait, or VoiceOver says "Button, Link") |
| R4 | Where the platform has no link role, say what the link does in another way | Android Compose Stand-alone Links (Android has no link role; the click label, such as "open in browser", or the icon's description carries it) |
| R5 | Enter follows the link; the keyboard reaches it | APG Link (Enter "executes the link"), Android Compose Stand-alone Links (visible focus) |
| R6 | A picture that is the only content of a link has a text alternative, which names the link | MDN `a` (an `img` in a link has an `alt` that says what the link does), [WCAG failure F89](https://www.w3.org/WAI/WCAG22/Techniques/failures/F89) |
| R7 | Following a link has one result: the page it points to, once | MDN `a` (a link is for "navigation to a real URL"), APG Link (navigation is the author's job when the role is added by hand) |

The visual requirements of both reference repositories (underline as well as
colour, contrast of the link colour, a target of 48 by 48, a visible focus
indicator) are met by every good example and checked by the widget tests'
guidelines and the focus ring; they are V-group entries and have no examples
here.

Flutter references for the mechanisms used:

- [`SemanticsProperties.link`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/link.html) and [`linkUrl`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/linkUrl.html)
- [`InkWell`](https://api.flutter.dev/flutter/material/InkWell-class.html), [`CupertinoListTile`](https://api.flutter.dev/flutter/cupertino/CupertinoListTile-class.html)
- [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html), [`Shortcuts`](https://api.flutter.dev/flutter/widgets/Shortcuts-class.html), [`DoNothingAndStopPropagationIntent`](https://api.flutter.dev/flutter/widgets/DoNothingAndStopPropagationIntent-class.html)
- [`Image.excludeFromSemantics`](https://api.flutter.dev/flutter/widgets/Image/excludeFromSemantics.html)

Radix comparison bar: Radix has no link primitive; the bar is the native
`<a href>` as MDN and APG describe it.

### Where the links go, and why not `url_launcher`

The SDK cannot open a URL in the browser app off the web: that needs a
plugin, and D30 rules plugins out. `url_launcher`'s `Link` widget, which
FL-013 asked about, is a plugin, and it would not give the role off the
web either: there it only builds what its builder returns, with no
`Semantics` of its own (source read: `url_launcher/lib/src/link.dart`,
`DefaultLinkDelegate`; probe fixture p12 is a button on Android and iOS).
On the web it adds `Semantics(link: true, linkUrl:)` round the builder's
widget and a platform view with an `<a>` of its own over it (source read:
`url_launcher_web/lib/src/link.dart`).

So every link here goes somewhere the SDK can reach: this technique's own
page in the app, `/t/C03`. Off the web the app opens it with `Navigator`.
On the web the link's `href` is `#/t/C03`, the app's own address for the
page, and the browser follows it itself.

What the SDK gives a link, measured in the probe:

- `Semantics(link: true)`: the link trait on iOS; a button on Android; on
  the web an `<a>` with no `href`, which HTML gives no link role, though
  VoiceOver in Chromium and WebKit still says "link".
- `linkUrl` as well: on the web a real `<a href>`, which the browser follows
  on a click, on Enter, and in a new tab on Command- or Ctrl-click; on
  Android a node that is no longer a button, with the address in a
  `URLSpan` on its content description, and no role that TalkBack says
  ([FL-220](../flutter-limitations.md#fl-220)); on iOS nothing more (the
  engine does not read it; source read).
- What it does not give: opening the address off the web, and on the web,
  keeping the app out of the way. A widget that takes Enter or runs a
  navigation of its own on a click competes with the browser
  ([FL-013](../flutter-limitations.md#fl-013)).

## 5. Examples

Every link is named "Read about stand-alone links" (but `bad-vague-text`)
and goes to the technique's page. "Follows" below means: off the web the
app pushes `/t/C03`; on the web the browser follows `href="#/t/C03"`, and
the app does nothing (`followLink`), and on the web Enter and Space are
left to the browser (`BrowserKeys`, `DoNothingAndStopPropagationIntent`).

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A text link | `Semantics(link: true, linkUrl:, onTapHint: 'open link')` round an `InkWell` with underlined text in the primary colour, at least 48 high; `BrowserKeys`; a 3 pixel focus ring (V14's, as `InkWell`'s tint is under 3:1, FL-430) | R1, R2, R4, R5, R7 |
| `good-cupertino` | Cupertino | A row that goes to another screen | `CupertinoListTile` with a chevron, inside `KeyboardLink`: `FocusableActionDetector` (Enter and Space off the web only), the focus ring, and `Semantics(link: true, linkUrl:, onTapHint:)`. The tile takes no focus on its own (FL-400) | R1, R2, R3, R4, R5, R7 |
| `good-custom` | Widgets layer | A text link with no Material | `KeyboardLink` round a `GestureDetector` | R1, R2, R4, R5, R7 |
| `good-image-link` | Material | A picture that is the whole link | As `good-material`, with `Semantics(label:)` on the link and `Image(excludeFromSemantics: true)` | R6, R2 |

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-vague-text` | The link says "Read more" | R1 |
| `bad-tap-handler` | Underlined text in a `GestureDetector`: no link role, and the keyboard cannot reach it. It opens a page of its own, `TapHandlerPage`, which nothing else in the app opens, so a keyboard user cannot reach that page at all | R2, R4, R5 |
| `bad-no-address` | `Semantics(link: true)` with no `linkUrl`: a button on Android, and on the web an `<a>` with no `href`, which HTML gives no link role | R2 |
| `bad-image-no-name` | A picture link with no name on the link or the picture | R6 |
| `bad-label-on-image` | The name is the picture's `semanticLabel`: on Android and iOS the link has no name and the picture is a second element ([FL-030](../flutter-limitations.md#fl-030)) | R6 |
| `bad-cupertino-button` | `Semantics(link: true, linkUrl:)` round a `CupertinoButton`: a link and a button at once ([FL-221](../flutter-limitations.md#fl-221)) | R3 |
| `bad-app-also-follows` | The app follows the link on the web as well as the browser: a click and Enter leave the screen as it was, and a DOM click opens the page twice under the example's address ([FL-013](../flutter-limitations.md#fl-013)). Off the web it works as the good links do | R7 |

What each fails, by platform, as the criteria are written:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-vague-text` | 2.4.4 (F84) | 2.4.4 (F84) | 2.4.4 (F84) |
| `bad-tap-handler` | 2.1.1: Tab never reaches it, and no key opens its page, which nothing else opens. 4.1.2 not settled: Android has no link role, and TalkBack says none for the good links either | 2.1.1: no key opened its page (one Tab, then Enter or Space). 4.1.2: static text, no role for a control | 2.1.1: Tab never reaches it, and no key opens its page. 4.1.2: a button, a role that does not say it is a link ([FL-006](../flutter-limitations.md#fl-006)) |
| `bad-no-address` | 4.1.2 not settled: a button, which is the stand-in the Android Compose reference itself uses where Android has no link role | none: a link | none in Chromium and WebKit, where VoiceOver says "link"; HTML gives an `a` with no `href` no role, and other browsers were not measured |
| `bad-image-no-name` | 1.1.1, 2.4.4, 4.1.2 (F89): no name, read as "Button" | 1.1.1, 2.4.4, 4.1.2 (F89): "Link Image" | 1.1.1, 2.4.4, 4.1.2 (F89): VoiceOver reads the address in place of a name |
| `bad-label-on-image` | 2.4.4, 4.1.2: the link has no name ([FL-030](../flutter-limitations.md#fl-030)) | 2.4.4, 4.1.2: "Link", with no name | none: the browser names the link from the picture |
| `bad-cupertino-button` | 4.1.2 not settled: a button, as for `bad-no-address` ([FL-221](../flutter-limitations.md#fl-221)) | 4.1.2 not settled: VoiceOver says "Button" and "Link"; the criterion does not say whether two roles identify the control | none: a link only |
| `bad-app-also-follows` | none: works as the good links do | none: works as the good links do | 2.1.1 not shown: Enter does not follow it, but the page it goes to, the technique's page, is reached by keyboard through Back ([FL-013](../flutter-limitations.md#fl-013)) |

"Not settled" means the evidence and the criterion as written do not decide
it either way; nothing is claimed.

`bad-label-on-image` has no `TestId`: its `MergeSemantics` would join the
picture to the link and hide the defect. Its nodes are found by role and
structure, and the widget tests use a plain `Key`.

There is no Material link widget and no Cupertino one. `good-material` and
`good-cupertino` are built from the closest widgets each library has
(`InkWell`; `CupertinoListTile`); `bad-cupertino-button` shows why
`CupertinoButton` is not one. Probe fixture p07 shows the same for a
Material `TextButton`, which has no example.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: guidelines in light and dark, 200% text at 320 by 640; link flag, `linkUrl`, name, no button or image flag, a tap action, the tap hint (a custom action that overrides tap), no image node; a tap and the tap action each open the technique's page, and one Back brings the example back; Tab reaches the link, and Enter and Space each follow it (off the web); in light and dark, the focus ring is drawn in the page's text colour once Tab reaches the link and is clear before and after. Bad: the name "Read more"; no link flag and never focused after four Tabs, with a tap opening `TapHandlerPage` as the positive control; Tab stops only on Back, and Enter, then Space, there open the technique's page and not `TapHandlerPage`; the link flag with no `linkUrl`; no name, with the image flag merged in and the labelled-tap-target guideline failing; the unnamed link with the named image under it; the link and button flags together; `bad-app-also-follows` followed once off the web. The tests run as Android, so the web-only code (`followLink` doing nothing, `BrowserKeys`) is not run here |
| L3 web | Good: `<a href="#/t/C03">`, role link, name, nothing inside it a button or an image; a click, a DOM click with no pointer events (what assistive technology can send), and Tab then Enter each open the technique's page once (one Back brings the example back) in this tab; Space does not follow it, with Enter in the same load as the positive control; Command- or Ctrl-click opens it in a new tab and leaves this one; the only link on the screen, and the only button Back. Bad: "Read more"; a button (FL-006) that Tab skips, with Tab reaching Back as the positive control, and a click opening `TapHandlerPage`; Tab stops only on Back, and Enter, then Space, there open the technique's page and not `TapHandlerPage`; an `<a>` with no `href` and no link role, followed by the app on a click and on Enter; a link with an empty name; a link named from the image inside it; `bad-cupertino-button` a link only; `bad-app-also-follows`: a click, and Tab then Enter, each leave the screen as it was, with the positive control that the address was seen to pass through `#/t/C03` in the same load; a DOM click opens the technique's page with the example's address left in the address bar, and one Back leaves the technique's page on screen |
| L3 Android | Good: class `android.view.View`, name, the address in a `URLSpan` on the content description, a click action labelled "open link", clickable, focusable; `ACTION_CLICK` (TalkBack's double tap), a tap, and Tab then Enter (`input keyevent`) each open the technique's page, and one Back brings the example back; one clickable node but Back. Bad: "Read more"; no address, no click label, and no focus after six Tabs, with Back focused as the positive control and the click action opening `TapHandlerPage`; Tab to Back and Enter, then Space, open the technique's page and not `TapHandlerPage`; class `Button` with no address; no name, no address, class `ImageView`; the unnamed link and the named image; class `Button` with the address; `bad-app-also-follows` followed once |
| L3 iOS | Good: element type link, label, the only link, no other button and no image; a tap, and Tab, Tab, Enter each open the technique's page once. Bad: link "Read more"; static text and no link, and a tap opening `TapHandlerPage`; one Tab and Enter, then Space, open the technique's page and not `TapHandlerPage`; a link (iOS reads the flag alone); an image with no label and no link (the image flag is merged into the link); an unnamed link and a named image; type button, no link (the link trait is heard, not seen, in the tree); `bad-app-also-follows` followed once |
| L4 TalkBack | What is read with focus on each link; for `bad-label-on-image`, on the picture only (see section 7) |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list; for each good link, what is said with the cursor on it and that a double tap opens the technique's page |
| L4 VoiceOver web | Every stop of VoiceOver's cursor after the "Example" heading to the end of the screen, compared as a whole list, in Chromium and WebKit |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c03](../evidence/probes/c03/),
with a native comparison on Android and three runs on the web of how
`bad-app-also-follows` is followed.

- **`linkUrl` is what makes a link on the web and keeps it from being a
  button on Android.** `link: true` alone is the link trait on iOS, a
  `Button` on Android ("… / Button" from TalkBack), and on the web an `<a>`
  with no `href`, which HTML gives no link role
  ([FL-032](../flutter-limitations.md#fl-032), now confirmed by
  `bad-no-address`). iOS does not read `linkUrl` (engine source read).
- **On the web the browser follows an `<a href>` by itself**: on a click,
  on Enter when no Flutter widget takes the key, and in a new tab on
  Command- or Ctrl-click. An address after the `#` opens the app's own
  route. So the good links do nothing on a tap on the web, and hand Enter
  and Space to the browser with `DoNothingAndStopPropagationIntent`
  (`BrowserKeys`), because an `InkWell` takes both. Space then does nothing,
  as for any link. `KeyboardLink` registers no key actions on the web for
  the same reason.
- **`bad-tap-handler` opens a page of its own.** Its first version went to
  the technique's page, as every link does, and Back opens that page from
  the keyboard too, so its 2.1.1 failure was not shown. It now opens
  `TapHandlerPage`, which nothing else in the app opens, and every layer
  tests that no key opens it: Tab stops only on Back (the widget tests,
  Android, the web), and Enter and Space there open the technique's page,
  which shows the key arrived, and not the tap handler's page.
- **The app and the browser both following a link is not "twice" but
  depends on how it is followed** ([FL-013](../flutter-limitations.md#fl-013),
  extended): a click and Enter end where they began, and a DOM click with
  no pointer events opens the page twice under the example's address. Five
  runs out of five each; why was not found. `bad-app-also-follows` asserts
  all three. What VoiceOver on the web sends when it activates a link was
  not measured, so the DOM click stands in for it and is named as such.
- **Android has no link role** ([FL-220](../flutter-limitations.md#fl-220)).
  TalkBack reads a Flutter link with an address by its name and "Double-tap
  to activate", and reads a native view of the same shape, a clickable
  `View` with the `URLSpan` on its content description, the same way
  (probe). The probe's other two native views are not compared: one was
  not read, and the other had no height on screen. The good links set `onTapHint: 'open link'`, so TalkBack says
  "Double-tap to open link", as the Android Compose reference does with
  `onClickLabel`. `bad-tap-handler` is then audibly different from them on
  Android ("Double-tap to activate") although neither has a role. On
  Android the address rides on the label: a link with no label of its own
  has no `URLSpan` (`bad-image-no-name`, `bad-label-on-image`), and
  `bad-image-no-name` is read as "Button".
- **There is no Material or Cupertino link widget, and a link round their
  buttons stays a button** ([FL-221](../flutter-limitations.md#fl-221)):
  VoiceOver says "Read about stand-alone links Button Link" for
  `bad-cupertino-button`, TalkBack "Button". The good Cupertino example is
  a `CupertinoListTile` made a link, with keyboard focus added (it has
  none, [FL-400](../flutter-limitations.md#fl-400)). The same for a
  Material `TextButton` was measured in the probe only (p07).
- **A name on the `Image` inside a link does not name the link on Android
  and iOS** ([FL-030](../flutter-limitations.md#fl-030), extended to links).
  VoiceOver stops twice, "Link" then "Read about stand-alone links Image";
  the web names the link from the picture.
- **VoiceOver on the web hides two defects and shows a third.** It says
  "link Read about stand-alone links" for `bad-no-address` in Chromium and
  WebKit, as the browsers' own trees call an `<a>` with no `href` a link;
  it reads the address in place of a name for `bad-image-no-name` ("link
  http://127.0.0.1:…/#/t/C03"); and for `bad-label-on-image` it says "link
  image Read about stand-alone links".
- **`bad-image-no-name` is an image to XCUITest** (the image flag is merged
  into the link by `TestId`), and VoiceOver says "Link Image": the link
  trait is there and the name is not.
- **TalkBack's speech for the unnamed link round the picture in
  `bad-label-on-image` is not checked or claimed.** A check that passes on
  silence would also pass on a lost capture, so the walk checks the picture
  only, and the tree test asserts that the link has no name.
- **`url_launcher`'s `Link` is not used**: it is a plugin (D30), and off the
  web it gives no semantics, so its `TextButton` builder is a button there
  (probe p12; source read). On the web it is a link and opened the address
  in a second tab by `launchUrl` in the probe.

Skips and what they give up, in the tests:

- The widget tests run as Android (`kIsWeb` false), so the web-only branch
  of `followLink`, `BrowserKeys`, and `KeyboardLink` runs only in the web
  tests.
- The iOS VoiceOver walk goes to the end of the screen, which it takes to
  be where moving on gives the last utterance again, twice (`C03Walk`). It
  gives up two neighbouring elements that VoiceOver reads alike, which it
  would count as one; no example has two. Its end and its content are
  tested with no device (`testWalkToTheEndSeesAnExtraStop`), including an
  extra element after the link, which must change the list.
- The web test of `bad-tap-handler`'s Tab stops leaves out stops outside
  Flutter's semantics tree (the page itself, when focus goes round,
  FL-421). It gives up nothing a key could act on in the app.
- The Android TalkBack walk moves focus to each named node and so does not
  see a stop it was not told of. The tree tests count the controls instead:
  one clickable node but Back on Android, one link on iOS, one link and
  one button (Back) on the web, for each good example.
- The TalkBack walk leaves out the link node of `bad-label-on-image`, as
  above: it gives up what TalkBack says for a link with no name round a
  named picture.
- The web test's "Space does not follow it" waits one second; Enter in the
  same load is the positive control.

**Not done yet.** Which elements a TalkBack swipe stops on (the walk moves
focus by action); what TalkBack's actions menu offers for a link; what
VoiceOver's own activation sends on the web; Space on the emulator and the
simulator (pressed in the widget tests only), and Shift+F10, which APG
calls optional; links out of the app, which the SDK cannot open off the
web; and links inside text, which are C04.
