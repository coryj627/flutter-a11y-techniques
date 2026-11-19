# Spec: I04 Keyboard actions and shortcuts

Status: Draft 1 (2026-11-18), written with the build. Fourth technique of
batch 5, focus and keyboard ([plan](../plan.md)), built in wave 4. Flutter
pin: 3.47.5.

This spec covers what keys do beyond Tab: the keys a custom control needs
(here the arrow keys, Home, and End), the default intents Flutter maps
keys to, the keyboard action of a text field, and single-key shortcuts.
Left to others:

| Left out | Owner |
| --- | --- |
| Whether a control takes focus at all, and Enter and Space on it | [I01 Focusable and clickable controls](I01-focusable-controls.md) |
| The order Tab and Shift+Tab move in, and what the arrow keys do to focus | [I02 Keyboard focus order](I02-focus-order.md) |
| Moving focus from code, and where focus goes after an action (FL-461) | I03 Focus management |
| Escape, `DismissIntent`, and keyboard traps | I08 Dismiss and escape |
| How focus looks | V14 Focus indicators |
| Which on-screen keyboard a field shows (`keyboardType`) | F03 Keyboard and input types |
| The full toolbar, tabs, and carousel patterns, whose keys this one strip borrows | C16 Toolbar, C07 Tabs, C17 Carousel |
| Increase and decrease for screen readers | I07 Adjustable |

## 1. Rule

A custom control answers the keys a control of its kind uses, so that
everything it does with a tap can be done from the keyboard. A text
field's Enter does what its keyboard action key says. A shortcut made of
one character key (a letter, number, punctuation, or symbol) works only
while the control it acts on has focus, or can be turned off, or can be
changed to include a key such as Control; and it never takes a key that
someone is typing into a text field.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Android and iOS: a hardware keyboard. Web: the browser's keyboard. On iOS,
Home, End, Page Up, and Page Down could not be sent from XCUITest, so
those keys are not verified there (section 7). The on-screen keyboard's
action key could not be pressed on any device (section 7).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.1.1 Keyboard](https://www.w3.org/TR/WCAG22/#keyboard) | Every photo can be shown, and a note saved, from the keyboard: the strip of photos is one stop in the Tab order and its arrow keys reach the rest |
| [2.1.4 Character Key Shortcuts](https://www.w3.org/TR/WCAG22/#character-key-shortcuts) | Each example has a shortcut made of one letter key, F, to add a favourite |

2.1.4, as written: if a keyboard shortcut uses only letter, punctuation,
number, or symbol characters, then at least one of: a mechanism turns it
off; a mechanism remaps it to include a non-printable key such as Control
or Alt; or, for a shortcut of a user interface component, it is active
only while that component has focus. The three good examples take one way
each. [Understanding 2.1.4](https://www.w3.org/WAI/WCAG22/Understanding/character-key-shortcuts.html)
counts a listbox's letter keys as active only on focus; the strip of
photos is a component of the same kind, a group of buttons with one Tab
stop, and its F works only while one of its thumbnails has focus. The
same document counts access keys, which use modifier keys, as outside the
criterion.

How the bad examples fail, as the criteria are written:

- `bad-page-shortcut` fails 2.1.4 on every platform: F acts wherever focus
  is in the example, not only on the strip it acts on, and nothing turns
  it off or remaps it. What follows from it in the note field is the
  harm 2.1.4 is about, not a second failure: a lowercase f typed there is
  taken by the shortcut, adds a favourite, and does not appear, on the web
  and iOS ([FL-460](../flutter-limitations.md#fl-460)); on Android it
  depended on the device (section 7). It does not fail 2.1.1: other keys
  still put an f in the note. Measured on the web: Shift+F types a
  capital F, and an f pasted with Control or Command+V goes in. On iOS:
  Shift+F types a capital F, an f pasted with Command+V goes in (iOS
  first asks whether the app may paste what another app copied, and the
  test allows it), and an f sent the way an on-screen keyboard's text
  arrives (`typeText`) goes in ([test outcomes](../evidence/probes/i04/review_evidence_run.txt)).
  Each was checked after a plain f had been lost in the same launch. On Android no alternative was needed on the
  local emulator, and none was measured on CI's.
- `bad-no-arrow-keys` fails 2.1.1 on every platform: Tab reaches only the
  thumbnail of the photo shown, and nothing moves along the strip from
  there, so three of the four photos cannot be shown from the keyboard.
  A tap, a click, and a screen reader still reach them. 2.1.1 has an
  exception only for input that depends on the path of the movement;
  showing a photo does not.

The good examples fail neither. Each keeps a button for the favourite, so
the shortcut is an alternative, as the criterion's definition of a
keyboard shortcut has it.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A text field sets the action its on-screen keyboard shows from its purpose or its place in a form, and handles that action | [Android Compose: Keyboard Actions](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/KeyboardActions.md) (`imeAction` and `KeyboardActions`; Done for the last field of a form) |
| R2 | Enter on a hardware keyboard does what the keyboard action does | Android Compose: Keyboard Actions (the example's own Enter handler, "do the same thing as the imeAction when Enter is pressed") |
| R3 | A custom control that is one stop in the Tab order moves among its parts with the arrow keys, and to its first and last with Home and End | [MDN: Keyboard-navigable JavaScript widgets](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Keyboard-navigable_JavaScript_widgets) (managing focus inside groups, the roving `tabindex`), [APG: Toolbar](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/) (keyboard interaction) |
| R4 | A single-character shortcut can be turned off, or remapped to include a non-printable key, or is active only while its component has focus | [WCAG 2.2: 2.1.4](https://www.w3.org/TR/WCAG22/#character-key-shortcuts), [Understanding 2.1.4](https://www.w3.org/WAI/WCAG22/Understanding/character-key-shortcuts.html) |
| R5 | A shortcut is an alternative: what it does can be done without it | WCAG 2.2 glossary, "keyboard shortcut": an alternative means of triggering an action |
| R6 | A shortcut never takes a key that is being typed into a text field | Understanding 2.1.4 (accidental activation); `EditableText`'s documentation on shortcuts and text input |

The reference repositories have one document for this entry, the Android
Compose one, and it is about R1 and R2 only. It also names the keyboard
trap of a default text field (2.1.2), which is I08's.

The HTML counterpart in the inventory, `accesskey`, is not a single-key
shortcut: the HTML standard has the author give one character, and the
user agent decide the keys that trigger it, usually with modifiers
([HTML: the accesskey attribute](https://html.spec.whatwg.org/multipage/interaction.html#the-accesskey-attribute)).
Flutter has nothing like it; the nearest is a `SingleActivator` with a
modifier, as `good-remap`'s Control+F, chosen by the app and not by the
platform.

Flutter references for the mechanisms used:

- [Using Actions and Shortcuts](https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts) and [Understanding Flutter's keyboard focus system](https://docs.flutter.dev/ui/interactivity/focus)
- [`Shortcuts`](https://api.flutter.dev/flutter/widgets/Shortcuts-class.html), [`Actions`](https://api.flutter.dev/flutter/widgets/Actions-class.html), [`CallbackShortcuts`](https://api.flutter.dev/flutter/widgets/CallbackShortcuts-class.html), [`Focus.onKeyEvent`](https://api.flutter.dev/flutter/widgets/Focus/onKeyEvent.html), [`FocusNode.skipTraversal`](https://api.flutter.dev/flutter/widgets/FocusNode/skipTraversal.html)
- [`SingleActivator`](https://api.flutter.dev/flutter/widgets/SingleActivator-class.html), [`CharacterActivator`](https://api.flutter.dev/flutter/widgets/CharacterActivator-class.html), [`DoNothingAndStopPropagationIntent`](https://api.flutter.dev/flutter/widgets/DoNothingAndStopPropagationIntent-class.html)
- [`WidgetsApp.defaultShortcuts`](https://api.flutter.dev/flutter/widgets/WidgetsApp/defaultShortcuts.html): the default intents
- [`TextField.textInputAction`](https://api.flutter.dev/flutter/material/TextField/textInputAction.html), [`TextField.onSubmitted`](https://api.flutter.dev/flutter/material/TextField/onSubmitted.html), [`CupertinoTextField.onSubmitted`](https://api.flutter.dev/flutter/cupertino/CupertinoTextField/onSubmitted.html)

Comparison bar: an HTML toolbar of buttons with a roving `tabindex` and a
`keydown` handler for the arrows, Home, and End (MDN, the APG); a text
input in a form, whose Enter submits it (implicit submission, HTML
standard); and a `keydown` handler for a letter that checks where focus
is before it acts. Radix's Toolbar primitive is one Tab stop whose arrow keys move focus
to the next or previous item and whose Home and End go to the first and
last ([Radix: Toolbar](https://www.radix-ui.com/primitives/docs/components/toolbar)).
The APG toolbar makes Home and End optional and lets Tab return to the
control that had focus last; here the strip's stop is the photo shown.

## 5. Examples

Every example is the same screen: a photo of a trail with its name
("Showing: Trailhead, 1 of 4"), the keys in words, a strip of four
thumbnail buttons that show a photo (Trailhead, Bridge, Ridge, Summit), a
button that adds the photo shown to the favourites or takes it out, a
note field whose Enter saves the note, and two lines at the end, the
favourites and the count of notes saved.

The strip is one stop in the Tab order: only the thumbnail of the photo
shown can be reached with Tab (the others have `skipTraversal`), and the
arrow keys move along the strip, showing each photo as focus reaches it.
The strip moves focus with `FocusNode.requestFocus` and then scrolls the
thumbnail into view with `Scrollable.ensureVisible`; a tap on a
thumbnail moves focus to it the same way.
That is the roving tab stop of a toolbar, and it is why the strip needs
keys of its own: without them the keyboard reaches one thumbnail only.

F adds the photo shown to the favourites, or takes it out. The favourite
button does the same, so the shortcut is an alternative.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-on-focus` | Widgets layer | F is one of the strip's own keys, so it works only while a thumbnail has focus | `Shortcuts` mapping Left, Right, Home, End, and `CharacterActivator('f')` to intents, and `Actions` for them, around the strip; a `TextField` with `textInputAction: done` and `onSubmitted` | R1 to R6 |
| `good-turn-off` | Cupertino | F works wherever focus is in the example; a switch, "Single-key shortcuts", turns it off | `CallbackShortcuts` around the example, its binding there only while the switch is on; the strip's keys in a `Focus(onKeyEvent:)` that takes no focus itself; a `CupertinoSwitch` in a `CupertinoListTile`, merged as F09 does; a `CupertinoTextField` named as F01 does, inside a `Shortcuts` that maps F to `DoNothingAndStopPropagationIntent` | R1 to R6 |
| `good-remap` | Material | F works wherever focus is; a switch, "Use Control+F for favourites", changes it to Control+F | `CallbackShortcuts` around the example, bound to `CharacterActivator('f')` or to `SingleActivator(keyF, control: true)`; the strip's keys in a `CallbackShortcuts`; a `SwitchListTile`; the note field keeps F while the shortcut is F | R1 to R6 |

The three examples use three of Flutter's ways to handle keys:
`Shortcuts` and `Actions`, `CallbackShortcuts`, and `Focus.onKeyEvent`.
The favourite button (an `IconButton`) and the thumbnails (each an
`OutlinedButton` with `Semantics(selected:)`) are the same Material
widgets in all of them, so that the examples differ only in what the
technique is about.

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-page-shortcut` | `good-on-focus` with F taken off the strip and put in a `CallbackShortcuts` around the whole example. F acts wherever focus is, and nothing turns it off or changes it. As a result, on the web and iOS typing "Leafy" in the note gives "Leay" and a favourite ([FL-460](../flutter-limitations.md#fl-460)); a capital F, a pasted f, and an on-screen keyboard's f still go in | R4, R6 | 2.1.4 |
| `bad-no-arrow-keys` | `good-on-focus` without the arrow keys, Home, and End. Tab reaches only the thumbnail of the photo shown, and the arrow keys do nothing there, so the other photos cannot be shown from the keyboard | R3 | 2.1.1 |

Not built:

- **A text field whose Enter does not save.** In every probe of a
  single-line field, Enter on a hardware keyboard arrived as the field's
  action and ran `onSubmitted`, on all three platforms (section 7), so a
  field with an action and `onSubmitted` cannot be built with that
  defect; and one without `onSubmitted` saves nothing for anyone, which
  is not a keyboard failure. A multi-line field adds a line on Enter on
  Android and iOS; one with a non-newline action on the web submits
  instead (probe fixture `q18`). Its defect would differ by platform and
  depends on whether a save button is there, so it was left in the probe.
- **A control that takes focus and acts on nothing but its own keys,
  `Focus.onKeyEvent` returning `handled` for every key**: Tab could never
  leave it, a keyboard trap, which is I08's.
- **An adjustable control (`onIncrease`, `onDecrease`) for the photos.**
  Tried first: on the web it has no accessible name
  ([FL-028](../flutter-limitations.md#fl-028)), so a good example built on
  it would fail 4.1.2 there; and with no keys, End still moved it a step
  through the browser (probe fixture `q16`).
- **A `PageView` as the strip.** It takes no focus at all
  ([FL-463](../flutter-limitations.md#fl-463)).

## 6. Assertions by layer

Where focus is, is read stop by stop: by the node whose semantics say it
has focus (widget tests, Android), by `document.activeElement` (web), or by
what a key does there (iOS, where XCUITest cannot see focus). Each test
that says a key does nothing presses that key alone, in a launch of its
own, and then shows in the same launch that keys arrive and act: F on the
strip, an arrow moving the caret in the note, or the switch turned back
on.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: guidelines in light and dark, no overflow at 200% text at 320 by 640. On a 320 by 640 screen, each thumbnail the strip's keys reach is in view. Every example: "Showing: Trailhead, 1 of 4"; four thumbnails named for their photos, buttons, Trailhead alone selected, none focused; "Add to favourites", a button; the note, a text field named "Note"; a tap and the semantics tap show any photo; the favourite button adds and removes and its name says which; the note's action key is Done (the text input configuration), the action saves the note, empties the field, and leaves no control with focus (FL-461), and a blank note is not saved; Tab goes Back, Trailhead, the favourite button, the setting where there is one, the note, round to Back, and with Ridge shown, Shift+Tab from the favourite button reaches Ridge and then Back. The strip's keys: Right, Right, Left, End, Right (stays), Home, Left (stays) each show the photo and put focus on its thumbnail, and a repeated Right goes on. Down leaves the strip. `bad-no-arrow-keys`: Right, Left, End, and Home, each alone from Bridge, leave Bridge shown and reach no other thumbnail; F then acts there and Down moves focus down out of the strip; ten Tabs and ten Shift+Tabs never reach Bridge, Ridge, or Summit. F: `good-on-focus` acts on the strip only and is not handled in the note; `good-turn-off` and `good-remap` act on the strip, the favourite button, and the setting, and not in the note; `good-turn-off`'s switch off stops it on the switch and the strip while the strip's arrows still work, and on again it acts; `good-remap`'s Control+F does nothing until the switch is on, then F does nothing and Control+F acts, in the note too; `bad-page-shortcut`'s F acts on the strip, the button, and in the note, and the screen has no setting |
| L3 web | Every example: the thumbnails are buttons with their names, `aria-current` true on Trailhead alone (the engine's attribute for a selected button), `tabindex="0"`; the favourite button and the note's name; a click and a click event show any photo; Tab order as above, and Shift+Tab back to Ridge; Enter in the note saves "Muddy", empties the field, leaves no element of the example with focus, and the next Tab goes to Back. The strip's keys as in L1. `bad-no-arrow-keys`: Right, Left, End, and Home alone, from Bridge, change nothing; then F acts there, and in the note Left moves the caret ("Mud", Left, "x" gives "Muxd"); six Tabs and six Shift+Tabs never reach the other thumbnails. F as in L1, with "Leafy" typed in the note: whole in the good examples, "Leay" with a favourite added in `bad-page-shortcut`; there, after a plain f has been lost in the same page, Shift+F types a capital F, and an f pasted with Control or Command+V goes in |
| L3 Android | Every stop is read after the key once the tree names a new one (polled for up to 2 seconds), and every value once two reads 500 ms apart agree, since on a 320 by 640 screen a read straight after a key could show the old stop while the screen scrolled. The same parts, by class (`Button`, `EditText`), name, `isSelected`, and `isFocused`; the click action shows any photo; Tab order and Shift+Tab to Ridge; the D-pad Right and Left, Home (`MOVE_HOME`), and End (`MOVE_END`) on the strip; `bad-no-arrow-keys`, each key alone, then F and Down; Tab and Shift+Tab never reach the other thumbnails; Enter in the note saves and empties it, a letter typed then goes nowhere, and the next Tab goes to Back; F as in L1, with Control+F as four key events; and in `bad-page-shortcut`, for each of `sendStringSync` and `input keyevent` in its own launch: once the note and the favourites have settled, either the note got the f and no favourite was added or the shortcut took it and one was, whichever happened is logged, and then the same way of sending an f on the favourite button changes the favourites |
| L3 iOS | The thumbnails (buttons, `isSelected` on Trailhead), the favourite button, the note (a text field labelled "Note"); a tap shows any photo; Tab order, each stop named by what a key does there (an arrow on the strip, Space on the favourite button and the switch, a letter in the note); Right and Left along the strip, and Tab on round to it again, where Left goes on from the photo shown; `bad-no-arrow-keys`, Right and Left alone, each in a launch where the same arrow first moves the caret in the note and F then acts on the strip; the stop after the strip is the favourite button; Enter in the note saves, a letter typed then goes nowhere, and the next Tab goes to Back (Space leaves the screen); F as in L1, typed one key at a time, with "Leay" in `bad-page-shortcut`; there, after a plain f has been lost in the same launch, Shift+F types a capital F, Command+V pastes an f, and `typeText` puts an f in. Home and End are not sent: they never reached Flutter from XCUITest. Shift is sent only for Shift+F, typed text is lower case, and the way back to the strip is Tab round, not Shift+Tab: on CI (Xcode 26.6, iOS 26.5, CI run 44502528898, [log lines](../evidence/probes/i04/ci_ios_44502528898.txt)) a capital typed with `typeKey` arrived in lower case in two tests, and after Tab and Shift+Tab from the strip Left did nothing, as if focus had not come back to it. Locally, with lower-case text, a typed letter was now and then lost: in three runs of the suite, three times in `bad-page-shortcut`'s note besides its f ("ea" for "lea", "ud" for "mud", "mudy" for "muddy"); in three more, with the checked typing below, once in `bad-no-arrow-keys`' note, the first letter after the note was tapped, which was sent again and typed ([output](../evidence/probes/i04/ios_three_runs_after_typing_fix.txt)). The cause was not found. So the tests type into the note one key at a time and wait for each letter to show; a letter that does not show is logged and sent again, at most three times. An f, the shortcut's letter, is sent once in every example: where a shortcut takes it, it is checked to stay out for a second; where the note should get it, it must show from that one press. Shift+Tab is tested on the web and Android |
| L4 TalkBack | Each thumbnail: its name and "Button", and "selected" for Trailhead alone; "Add to favourites" and "Button"; the setting: its label, "Switch", and "on" or "off" (never the other); the note: "Note" and "Edit box". The walk puts TalkBack's focus on each part, so it records speech, not order |
| L4 VoiceOver iOS | Everything between the "Example" heading and the count, in VoiceOver's own swipe order |
| L4 VoiceOver web | The same with VoiceOver's cursor; and, with VoiceOver on, keys pressed through the system on `bad-page-shortcut`: Right moves along the strip, F adds a favourite, and "Leafy" typed in the note gives "Leay" |

The keys are not heard: a screen reader reads every example's strip
alike, and activates any thumbnail with its own gesture. The screen
reader layers record that the bad examples read like the good ones.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/i04](../evidence/probes/i04/README.md), with the raw output
of each platform.

- **A shortcut above a text field takes its letter on the web and on
  iOS, and on Android it depends on the device**
  ([FL-460](../flutter-limitations.md#fl-460)). Flutter gives each key to
  the framework before the platform's text input, as `EditableText`'s
  documentation says. On the local Android emulator (Android 17, Gboard, a
  hardware keyboard in its settings) the input method had the letter keys
  first while a field was being edited, so the shortcut never ran there
  and the field got every letter. On CI's emulator (API 35, the
  `google_apis` image, no hardware keyboard in its settings) the same
  test, typing with `Instrumentation.sendStringSync`, got "Leay": the f
  did not reach the note (CI run 44472632084,
  [the lines kept](../evidence/probes/i04/ci_android_44472632084.txt)).
  The favourites line was not recorded in that run, so that the shortcut
  took the f is inferred and was not seen.
  The local emulator kept every f in every later run, with
  `sendStringSync` and with `input keyevent`, and also with its on-screen
  keyboard shown beside the hardware one (a setting turned on for one run
  and put back); the CI result was not reproduced, since the local
  emulator's hardware keyboard setting was not changed
  ([output](../evidence/probes/i04/android_review_after_wait_fix.txt)). The Android tests now accept either
  result, require the two to be consistent (an f either typed or taken,
  never both or neither), and log which, for each way of sending keys
  (section 6). The lost letter is the
  consequence of the 2.1.4 failure; other keys still enter an f on the web
  (Shift+F, a paste) and iOS (an on-screen keyboard's text). `DoNothingAndStopPropagationIntent` for the key, in a
  `Shortcuts` around the field, gives the key back to the field on all
  three. A shortcut put on the control it acts on never meets a field at
  all, which is why `good-on-focus` needs no such guard.
- **Moving focus from code does not scroll.** `FocusNode.requestFocus`
  leaves a control out of sight if it is; Tab and the arrow keys' default
  moves scroll it into view. On CI's Android screen, 320 by 640 at 160
  dpi, the strip wraps onto two rows and `bad-page-shortcut`'s longer
  defect text put the second row below the screen: Right from Bridge
  showed Ridge with focus out of view (the I04 Android test, twice, before
  the fix). The strip now calls `Scrollable.ensureVisible` after each
  move, and a widget test at that size checks that each thumbnail the
  keys reach is in view, which fails without it. Where focus goes after
  code moves it is I03's subject.
- **A key a control does not handle goes on to Flutter's defaults**,
  which differ by platform (`WidgetsApp.defaultShortcuts`, read in the
  source, and measured): Enter, Space, and the numeric keypad's Enter are
  `ActivateIntent` (Enter is `ButtonActivateIntent` on the web,
  [FL-002](../flutter-limitations.md#fl-002)); Escape is `DismissIntent`
  (I08); Tab and Shift+Tab move focus (I02); the arrow keys move focus by
  position on Android and iOS and scroll on the web; Page Up and Page Down
  scroll; Control and an arrow scroll on Android, Command and an arrow in
  the source for iOS. On the web Space on a control with no activate
  action scrolls a page, and End and Home, unhandled, scrolled the probe's
  page to its end and its top. So a control's own keys must be handled
  where focus is, or the defaults take them: in `bad-no-arrow-keys` Down
  from a thumbnail moves focus out of the strip on Android and iOS.
- **Enter on a hardware keyboard in a single-line field is the field's
  action, on every platform**: `onSubmitted` ran for the done, search,
  and next actions, and the next action moved focus to the next field.
  Enter arrives at the framework as a key first; nothing in the app's
  shortcuts handles it, so it goes on to the platform's text input, which
  turns it into the action. A field inside a control with activate
  actions still submitted (probe `q13`).
- **The done action takes focus from the field and gives it to no
  control** ([FL-461](../flutter-limitations.md#fl-461)): the next Tab
  starts again from Back. Android's own text field keeps focus for the
  done action, and a plain HTML form's input kept focus in Chromium. The
  examples keep Flutter's default, which is also what hides the
  on-screen keyboard; where focus should go is I03's. On Android the
  field's node still reported `isFocused` after Enter while a letter typed
  then reached nothing (the I04 Android test's first run), so the Android
  and iOS tests show the loss of focus by what the keys do, and the widget
  and web tests by the node and the element that have focus.
- **The on-screen keyboard's action key was not pressed on a device.** The
  emulator and the simulator have hardware keyboards, which hide the
  on-screen one; changing that is a device setting the tests do not touch.
  The widget tests send the action itself, and Flutter's source sends the
  same action for both.
- **With a screen reader running, the keys still arrived**: with TalkBack
  on, Tab, the D-pad keys, and F; with VoiceOver on iOS (through
  `XCUIVoiceOverService`), every `typeKey` key, and F still took the f
  from a field. VoiceOver on the web: see the transcript's
  `keys-bad-page-shortcut` row. Real keyboards with Quick Nav were not
  tried.
- **iOS**: XCUITest's Home, End, Page Up, and Page Down reached nothing,
  so those keys are not verified on iOS. Option+F gives the character
  "ƒ", so a `CharacterActivator('f', alt: true)` does not match it and a
  `SingleActivator(keyF, alt: true)` does: the activators differ exactly
  as their documentation says.
- **On the web the thumbnails' selected state is `aria-current`**, not
  `aria-selected` (read in the DOM); every thumbnail has `tabindex="0"`,
  and Flutter's own Tab handling is what keeps the strip one stop.
- **A shortcut around plain text renames what a screen reader hears**
  ([FL-464](../flutter-limitations.md#fl-464)). `Shortcuts`,
  `CallbackShortcuts`, and `Focus` each add a semantics node, which takes
  the plain text inside it as its name and holds the controls inside it.
  In the first recordings, the three examples with a `CallbackShortcuts`
  around the whole example were a group named by the line of keys on the
  web ([first web transcript](../evidence/probes/i04/voiceover-web-first-run.md.txt)),
  and VoiceOver on iOS read that line before the strip it was written
  under ([first iOS transcript](../evidence/probes/i04/voiceover-ios-first-run.md.txt)).
  The line is now a node of its own (`Semantics(container: true)`) and
  above the strip in every example, where it is met before the keys it
  describes.
- **Found on the way**: an adjustable control has no accessible name on
  the web ([FL-028](../flutter-limitations.md#fl-028)), which is why the
  strip is made of buttons; a `PageView` takes no focus
  ([FL-463](../flutter-limitations.md#fl-463)). A
  `CupertinoSlidingSegmentedControl` was looked at as a way to choose the
  shortcut and has no keyboard gap: in a widget test, as Android and as
  iOS, it is one Tab stop, the arrow keys select the next or previous
  segment and go round at the ends, and Space on the segment already
  selected changes nothing, as in a radio group (the SDK builds it on
  `RadioGroup`) ([probe output](../evidence/probes/i04/probe_segmented.txt)).
  `good-turn-off` uses a switch because turning a shortcut off is a
  yes-or-no choice.

**Not done yet.** The on-screen keyboard's action key on a device; Full
Keyboard Access on iOS; Home and End on iOS; what a browser keeps for
itself (Playwright's keys bypass the browser's own shortcuts, so whether
Control+F reaches the page in a person's browser is not established); a
hardware keyboard's own keys with VoiceOver's Quick Nav on; other Android
input methods than Gboard; shortcuts with more than one key in sequence;
and a shortcut list or a way to discover shortcuts beyond the line of
text above the strip.

## 8. Handed on

- **I03 Focus management**: FL-461, where focus should go after a text
  field's action; the strip's `requestFocus` after an arrow is the
  pattern for moving focus with selection.
- **I07 Adjustable**: an adjustable custom control has no name on the web
  (FL-028), so a control that is adjusted with the arrows may be better
  built as buttons, as here.
- **I08 Dismiss and escape**: `DismissIntent`, Escape, and a
  `Focus.onKeyEvent` that handles every key and so traps Tab.
- **I14 Scrolling regions and C17 Carousel**: FL-463, a `PageView` with
  no focus or keys; and the web's arrow, Page, Home, and End keys, which
  scroll the page when a control leaves them unhandled.
- **C16 Toolbar and C07 Tabs**: the roving tab stop and its arrow keys,
  which this technique uses for one strip; the full patterns (wrapping,
  `aria-orientation`, the tab roles) are theirs.
- **F03 Keyboard and input types**: the on-screen keyboard's action key,
  which no test here could press.
