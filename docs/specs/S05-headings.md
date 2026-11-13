# Spec: S05 Headings

Status: Draft 1 (2026-11-13), written with the build. Second vertical-slice
technique ([plan](../plan.md), phase 3). Flutter pin: 3.47.5.

Screen and page titles are a separate entry (S06). This spec covers the title
only as the top of the heading outline.

## 1. Rule

Text that works as a heading is exposed to assistive technology as a heading,
with a level that matches its place in the page outline, and text that is not
a heading is not exposed as one.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Heading levels are only exposed on web. Android has one heading level, and
VoiceOver on iOS did not speak a level for any example. Three Flutter
limitations were found; see section 7.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | Structure shown by heading styling must be available programmatically |
| [2.4.6 Headings and Labels](https://www.w3.org/TR/WCAG22/#headings-and-labels) | Headings describe the topic of their section |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Heading and subheading text must be exposed as a heading, so screen reader users can move between headings | [CVS iOS Headings](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Headings.md), [CVS Compose Heading Semantics](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/HeadingSemantics.md), [CVS View Heading Semantics](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/HeadingSemantics.md) |
| R2 | Heading levels must not skip a level going down | CVS iOS Headings; [MDN heading elements](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/Heading_Elements) |
| R3 | Never fake a heading by adding the word "heading" to the name | CVS iOS, Compose, and View |
| R4 | A page has one level 1 heading, and lower levels nest under it | MDN heading elements |
| R5 | Titles of app bars, dialogs, and sheets are headings | CVS Compose and View |
| R6 | Only mark real section headings; do not use a heading to style or emphasise text | CVS Compose and View; MDN heading elements |

Flutter references for the mechanism used:

- [`SemanticsProperties.headingLevel`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/headingLevel.html)
- [`SemanticsProperties.header`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/header.html)

Radix comparison bar: Radix has no heading primitive; the bar is the native
`h1`–`h6` elements as described by MDN.

## 5. Examples

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-levels` | Material | Headings at levels 3 and 4 under the screen title (1) and the "Example" section (2) | `Semantics(header: true, headingLevel: n)` | R1, R2, R4 |
| `good-cupertino` | Cupertino | A list section header that is a heading | `CupertinoListSection(header: Semantics(header: true, headingLevel: 3, …))` | R1 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-visual-only` | Styled like a heading, plain text to assistive technology | R1 | 1.3.1 |
| `bad-fake-label` | Name is "Profile, heading"; not a heading | R3 | 1.3.1 |
| `bad-skipped-level` | Level 5 directly under level 3 | R2 | 1.3.1 |
| `bad-header-only` | `header: true` with no level (Flutter limitations FL-003, FL-004, FL-005) | R1, R2 | 1.3.1 |
| `bad-emphasis-heading` | A sentence marked as a heading to make it stand out | R6 | 1.3.1, 2.4.6 |
| `bad-cupertino-section-header` | `CupertinoListSection` header with no heading semantics (Flutter limitation FL-014) | R1 | 1.3.1 |

## 6. Assertions by layer

Elements are located by their text. Headings have no controls to identify, and
their text is the thing under test.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Header flag and `headingLevel` per example; the outline of `good-levels` in traversal order with no skipped level; exactly one level 1 heading on every screen; guidelines and 200% text for the good examples |
| L3 web | Real `h1`–`h6` elements with the expected levels; the outline of each example; one `h1` per screen |
| L3 Android | `AccessibilityNodeInfo.isHeading` per element |
| L3 iOS | Text is exposed with the expected label. XCUITest cannot read traits, so the heading itself is checked at L4 |
| L4 TalkBack | "Heading" spoken, or not, per element |
| L4 VoiceOver iOS | "… Heading" spoken, or not, per element |
| L4 VoiceOver web | "heading level n …" spoken, or not, per element |

Where a defect cannot be observed on a platform, the test asserts what is
observable and says so: `bad-skipped-level` is two ordinary headings on
Android and iOS.

## 7. What the build found (Flutter 3.47.5)

Detail is in [flutter-limitations.md](../flutter-limitations.md).

- **`headingLevel` is the only form that works everywhere.** `header: true`
  alone is not a heading for VoiceOver on iOS (FL-003), is always `<h2>` on
  web (FL-004), and is not a heading on Android unless the node is a direct
  child of a scrolling list (FL-005).
- **FL-005 was misdiagnosed in the spike.** It had been put down to a test
  identifier on the same node. The engine source shows Android sets the
  heading property from `headingLevel` only.
- **`AppBar` titles have no level.** The shell now wraps the title in
  `Semantics(headingLevel: 1)`, which gives each screen one `<h1>` and makes
  the title a heading for VoiceOver on iOS and TalkBack.
- **`CupertinoListSection` does not expose its header as a heading** (FL-014).
- **Levels are a web-only signal.** TalkBack says "Heading" with no level.
  VoiceOver on iOS said "Profile Heading" with no level for every example.

**Not done yet.** Dialog and bottom sheet titles (R5) are left to the dialog
and sheet techniques (C-group). Rotor and heading-navigation gestures are not
driven by the tests; the tests check the property those features rely on.
