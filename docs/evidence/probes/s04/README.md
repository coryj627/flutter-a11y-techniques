# S04 probe: what images inside controls expose

Run on 2026-11-14, Flutter 3.47.5, before the S04 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app). The
picture is the PNG from S02; "labelled" means `Image(semanticLabel:)`,
"excluded" means `excludeFromSemantics: true`, and "unlabelled" means
neither.

## Web (Chromium, Playwright ARIA snapshot and the semantics DOM)

| # | Fixture | Exposed |
| --- | --- | --- |
| 01 | `IconButton`, labelled image | `button "Open one"` containing `img "Open one"`. The button has no `aria-label`; Chromium takes its name from the image |
| 02 | `IconButton`, excluded image, `tooltip` | `button "Open two"` |
| 03 | `IconButton`, unlabelled image, `tooltip` | `button "Open three"` |
| 04 | `IconButton`, unlabelled image, no `tooltip` | `button`, no name |
| 05 | `InkWell`, labelled image | an element with `tabindex="0"` and no role, containing `img "Open five"` |
| 06 | `GestureDetector`, labelled image | an element with no role and no `tabindex`, containing `img "Open six"` |
| 07 | `Semantics(button, label)`, `InkWell`, excluded image | `button "Open seven"` |
| 08 | `Semantics(link: true)`, `GestureDetector`, labelled image | `<a>` with no `href` and no `tabindex`, containing `img "Example home"` |
| 09 | `Semantics(link: true, label)`, `InkWell`, excluded image | `<a tabindex="0">` with no `href`; the ARIA snapshot shows text, not a link |
| 10 | `FilledButton.icon`, icon with no label | `button "Print"` |
| 11 | `FilledButton.icon`, icon labelled "Printer" | `button "Printer Print"` |
| 12 | `TextButton`, labelled image and text | `button "Home twelve"` (`aria-label`) containing `img "Logo"` |
| 13 | `TextButton`, excluded image and text | `button "Home thirteen"` |
| 14 | `TextButton`, unlabelled image and text | `button "Home fourteen"` |
| 15 | `Stack`: excluded image, two `Semantics(button, label)` regions with `InkWell` | `button "North trail"`, `button "South trail"` |
| 16 | `Tooltip`, `InkWell`, excluded image | `button "Open sixteen"` |
| 17 | `IconButton`, `Icon(semanticLabel: 'Search')` | `button "Search"` |
| 18 | `Semantics(button, label)`, `Ink.image`, `InkWell` | `button "Open eighteen"` |
| 19 | `InkWell`, unlabelled image | `button`, no name |

## Android (Pixel 10a emulator, Android 17, `uiautomator dump`)

```
01  Button    desc=''               clickable
    ImageView desc='Open one'       not clickable   (child of the button)
02  Button    desc='Open two'       clickable
03  ImageView desc='Open three'     clickable
04  ImageView desc=''               clickable
05  View      desc=''               clickable
    ImageView desc='Open five'      not clickable
06  View      desc=''               clickable
    ImageView desc='Open six'       not clickable
07  Button    desc='Open seven'     clickable
08  Button    desc=''               clickable
    ImageView desc='Example home'   not clickable
09  Button    desc='Example nine'   clickable
10  Button    desc='Print'          clickable
11  Button    desc='Printer\nPrint' clickable
12  Button    desc='Home twelve'    clickable
    ImageView desc='Logo'           not clickable
13  Button    desc='Home thirteen'  clickable
14  ImageView desc='Home fourteen'  clickable
15  Button    desc='North trail'    clickable
    Button    desc='South trail'    clickable
16  View      desc='Open sixteen'   clickable
17  Button    desc='Search'         clickable
18  Button    desc='Open eighteen'  clickable
19  ImageView desc=''               clickable
```

Every node listed was focusable.

## iOS (iPhone 17 simulator, iOS 27.0)

XCUITest tree (fixture captions left out):

```
01  Button ''            and Image 'Open one'
02  Button 'Open two'
03  Button 'Open three'
04  Button ''
05  Image 'Open five'
06  Image 'Open six'
07  Button 'Open seven'
08  Link ''              and Image 'Example home'
09  Link 'Example nine'
10  Button 'Print'
11  Button 'Printer\nPrint'
12  Button 'Home twelve' and Image 'Logo'
13  Button 'Home thirteen'
14  Button 'Home fourteen'
15  Button 'North trail', Button 'South trail'
16  Other 'Open sixteen'
17  Button 'Search'
18  Button 'Open eighteen'
19  Image ''
```

VoiceOver, swiping forward with `XCUIVoiceOverService`:

```
01  "Button" / "Open one Image"
02  "Open two Button"
03  "Open three Button Image"
04  "Button Image"
05  (a stop with no speech) / "Open five Image"
06  (a stop with no speech) / "Open six Image"
07  "Open seven Button"
08  "Link" / "Example home Image"
09  "Example nine Link"
10  "Print Button"
```

The walk stayed on "Print Button", the last element on the screen:
VoiceOver did not scroll to fixtures 11 to 19, so those were not heard.

## What it shows

- A labelled `Image` is always an element of its own. Inside a button it
  leaves the button with no name on Android and iOS (01, 12 on Android and
  iOS keep the name only because the button also has text). The web computes
  the button's name from the image.
- An unlabelled `Image` that is not excluded adds the image role to the
  control around it: `ImageView` in place of `Button` on Android (03, 04,
  14, 19), "Button Image" from VoiceOver on iOS (03, 04).
- An excluded `Image` in a control named by `tooltip`, by text, or by
  `Semantics(label:)` is a button and nothing else on all three platforms
  (02, 07, 13, 15, 18).
- An `Icon`'s `semanticLabel` names the button around it (17), and is added
  to the button's text when there is text (11).
- `InkWell`, `GestureDetector`, and `Tooltip` with `InkWell` give no button
  role on Android and iOS (05, 06, 16).
- `Semantics(link: true)` without `linkUrl` is not a link on the web (08,
  09). Links are left to C03.
