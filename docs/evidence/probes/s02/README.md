# S02 probe: what images expose

Run on 2026-11-14, Flutter 3.47.5, before the S02 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app).
Fixtures 02, 05, and 12 had no `Semantics` wrapper in the run recorded here.

## Web (Chromium, Playwright ARIA snapshot)

```
- text: 01 image with label
- img "Sunrise over hills"
- text: 02 image no label
- img
- text: 03 image excluded 04 icon with label Delivered 05 icon no label 06 custom paint image+label
- img "Bar chart rising"
- text: 07 custom paint label only Bar chart no flag 08 merged icon no label + text Order delivered 09 group description Sunrise at 6:35 am 10 role in label
- img "Image of a sunrise"
- text: 11 merged labelled icon + text Delivered Order 1234 12 custom paint no semantics
```

## Android (Pixel 10a emulator, Android 17, `uiautomator dump`)

Only nodes with an identifier, text, or a description were listed, so a node
with none of them would not show here.

```
ImageView | desc= Sunrise over hills            (01)
(nothing listed for 02, 03, 05, 12)
p-icon-label | View | desc= Delivered           (04)
p-paint-image | ImageView | desc= Bar chart rising   (06)
p-paint-label | View | desc= Bar chart no flag  (07)
View | desc= Order delivered                    (08)
p-group | View | desc= Sunrise at 6:35 am       (09)
ImageView | desc= Image of a sunrise            (10)
View | desc= Delivered\nOrder 1234              (11)
```

## iOS (iPhone 17 simulator, iOS 27.0)

XCUITest tree:

```
Image, label: 'Sunrise over hills'              (01)
Image (no label)                                (02)
(nothing for 03, 05, 12)
StaticText, identifier: 'p-icon-label', label: 'Delivered'   (04)
Image, identifier: 'p-paint-image', label: 'Bar chart rising' (06)
StaticText, identifier: 'p-paint-label', label: 'Bar chart no flag' (07)
StaticText, label: 'Order delivered'            (08)
StaticText, identifier: 'p-group', label: 'Sunrise at 6:35 am' (09)
Image, label: 'Image of a sunrise'              (10)
StaticText, label: 'Delivered\nOrder 1234'      (11)
```

VoiceOver, swiping forward (fixture captions left out):

```
Sunrise over hills   Image
(02: skipped)
Delivered
Bar chart rising   Image
Bar chart no flag
Order delivered
Sunrise at 6:35 am
Image of a sunrise   Image
```

## What it shows

- `Image(semanticLabel:)` and `Semantics(image: true, label:)` are an image
  with a name on all three platforms.
- An `Image` with no label is an unnamed `img` on web and an unlabelled image
  element on iOS that VoiceOver skips.
- `Icon(semanticLabel:)` is exposed as text, not as an image.
- `Image(excludeFromSemantics: true)`, an `Icon` with no label, and a
  `CustomPaint` with no `Semantics` expose nothing.
