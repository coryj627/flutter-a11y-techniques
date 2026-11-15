# S03 probe: what decorative images expose

Run on 2026-11-14, Flutter 3.47.5, before the S03 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app).

## Web (Chromium, Playwright ARIA snapshot)

```
- text: 01 excludeFromSemantics 02 empty label
- img
- text: 03 no label
- img
- text: 04 DecorationImage 05 CircleAvatar backgroundImage 06 ExcludeSemantics labelled image 07 row icon no label + text Shipping 08 Semantics image no label
- img
- text: 09 merged unlabelled image + text
- img "Merged text"
- text: 10 icon empty label 11 ExcludeSemantics unlabelled image 12 merged excluded image + text Merged clean 13 row labelled icon + same text Shipping Shipping 14 CircleAvatar child initials + name AK Ana Kovac 15 end
```

None of the `img` elements had `aria-label` or `aria-hidden`, except
fixture 09 with `aria-label="Merged text"`.

## Android (Pixel 10a emulator, Android 17, `uiautomator dump`)

Nodes of the app that are images or have a description. The dump ended at
fixture 13; the rest was below the screen.

```
View      | desc= 01 excludeFromSemantics              | focusable
View      | desc= 02 empty label                       | focusable
ImageView | desc= (none)                               | not focusable   (02)
View      | desc= 03 no label                          | focusable
ImageView | desc= (none)                               | not focusable   (03)
(nothing for 01, 04, 05, 06)
View      | desc= Shipping                             | focusable       (07)
ImageView | desc= (none)                               | not focusable   (08)
ImageView | desc= Merged text                          | focusable       (09)
View      | desc= (none)                               | not focusable   (10)
(nothing for 11)
View      | desc= Merged clean                         | focusable       (12)
```

## iOS (iPhone 17 simulator, iOS 27.0)

XCUITest tree (fixture captions left out):

```
Image, label: ''                 (02)
Image, label: ''                 (03)
(nothing for 01, 04, 05, 06)
StaticText, label: 'Shipping'    (07)
Image, label: ''                 (08)
Image, label: 'Merged text'      (09)
(nothing for 10, 11)
StaticText, label: 'Merged clean' (12)
StaticText 'Shipping', StaticText 'Shipping'   (13)
StaticText 'AK', StaticText 'Ana Kovac'        (14)
```

VoiceOver, swiping forward, read every caption in turn and between them
only: "Shipping" (07), "Merged text Image" (09), and "Merged clean" (12).
It did not stop on the unnamed images of 02, 03, and 08. The walk stayed on
"Merged clean", the last element on the screen: VoiceOver did not scroll to
fixtures 13 to 15, so those were not heard.

## What it shows

- `Image(excludeFromSemantics: true)`, a `DecorationImage`, a `CircleAvatar`
  background image, an `Icon` with no label, and anything inside
  `ExcludeSemantics` expose nothing.
- `Image(semanticLabel: '')` is exposed like an `Image` with no label: an
  image with no name.
- An unlabelled `Image` merged with text makes the merged node an image
  named by the text.
- `Icon(semanticLabel: '')` leaves an empty node on Android and nothing on
  web and iOS.
- The unnamed image nodes are not focusable on Android, and VoiceOver on
  iOS skips them.
