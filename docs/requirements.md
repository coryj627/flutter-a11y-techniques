# Flutter A11Y Techniques — Requirements

Status: Draft 2 (2026-11-12). Source of truth for the plans and specs that follow.

## 1. Purpose

Demonstrate Flutter techniques for an accessible experience using live good and bad
examples that can be tested with TalkBack, VoiceOver, NVDA, and other assistive
technology (AT), and provide source-referenced documentation explaining how to
develop according to these techniques.

### Influences

- [cvs-health/ios-swiftui-accessibility-techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)
- [cvs-health/android-view-accessibility-techniques](https://github.com/cvs-health/android-view-accessibility-techniques)
- [cvs-health/android-compose-accessibility-techniques](https://github.com/cvs-health/android-compose-accessibility-techniques)

### Independence

This project draws on the CVS Health repositories above as public references. The
project, its code, and the work have no material connection to CVS Health. It is
the work of an independent developer, not a representative of the company.

## 2. Terms

| Term | Meaning |
| --- | --- |
| Technique | One catalog entry: a component or interaction, with good example(s), bad example(s), documentation, and tests. |
| Good example | An implementation that meets the mapped WCAG criteria using only documented Flutter SDK mechanisms. |
| Bad example | An implementation with a specific, named accessibility defect. May be constructed freely. |
| Limitation | A pattern that cannot be made fully accessible on a platform because of the Flutter framework. |
| Platform | Android, iOS, or Web build of the app. |

## 3. Scope

In scope for v1:

- Platforms: **Android, iOS, Web**.
- Widget libraries: **Material** as baseline, **Cupertino** variants where iOS
  behaviour differs, and widgets-layer (`Semantics`, `Focus`, `Actions`) examples
  for custom components.
- Conformance measure: WCAG 2.2 Level A and AA.

Out of scope for v1:

- Native desktop builds (macOS, Windows, Linux).
- WCAG Level AAA as a requirement (may be noted where relevant).
- Maestro test flows.
- NVDA verification. Web is verified with VoiceOver on macOS; docs state that
  NVDA is not yet verified.
- Switch Access / Switch Control and Voice Access / Voice Control verification.
- Localizing the app shell (English only). Localization and RTL are still
  covered as techniques.
- Contribution scaffolding (contribution guide, code of conduct).

## 4. Requirements

Priority follows the original brief: **Must** is required, **Should** is expected
unless a documented reason prevents it.

### 4.1 Catalog coverage

| ID | Priority | Requirement |
| --- | --- | --- |
| CAT-1 | Must | Cover every interaction and component covered by the three CVS Health techniques projects, where applicable to Flutter on the target platform. |
| CAT-2 | Must | Cover the [W3C ARIA APG patterns](https://www.w3.org/WAI/ARIA/apg/patterns/). |
| CAT-3 | Must | Cover the relevant [HTML5 elements](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements) — those with accessibility semantics or interaction a Flutter app would need to reproduce. |
| CAT-4 | Must | Each technique declares which platforms it applies to. Android-only, iOS-only, and mobile-only techniques are marked as such and are not presented as applicable elsewhere. |
| CAT-5 | Must | Maintain a coverage inventory that maps every CVS technique, APG pattern, and relevant HTML element to a catalog entry or to a recorded "not applicable" reason. |
| CAT-7 | Must | Include techniques for language of parts, text direction, and right-to-left layout. |
| CAT-6 | Should | Use [Radix UI Primitives](https://github.com/radix-ui/primitives) as the bar for web capability when judging whether a web example is good enough. |

### 4.2 Technique rules

| ID | Priority | Requirement |
| --- | --- | --- |
| TEC-1 | Must | Use [WCAG 2.2](https://www.w3.org/TR/WCAG22/) Level A and AA as the measure. Each technique lists the success criteria it addresses. |
| TEC-2 | Must | Good examples must not invent new mechanisms or methods. Every mechanism used must trace to a cited source. |
| TEC-3 | Must | Good examples use only Flutter SDK APIs. Third-party packages are permitted for tooling only (Widgetbook, testing). |
| TEC-4 | Must | Each technique has at least one good and one bad example, runnable live in the app. Bad examples may be constructed freely. |
| TEC-5 | Should | Prefer well documented methods over novel solutions. |
| TEC-6 | Should | When a pattern is not feasible because of a Flutter limitation: keep the catalog entry, show the closest achievable example, document the gap with a link to the Flutter issue, and mark status per platform. |

### 4.3 Documentation

| ID | Priority | Requirement |
| --- | --- | --- |
| DOC-1 | Must | Every source is referenced with a link to the resource. |
| DOC-2 | Must | Documentation is available in three places: Markdown in the repo (one per technique), in the app beside the live examples, and in Widgetbook beside each use case. |
| DOC-3 | Must | The three documentation surfaces are produced from a single source per technique so they cannot drift. |
| DOC-6 | Must | The README, the in-app about screen, and Widgetbook state that the project has no material connection to CVS Health and is the work of an independent developer, not a representative of the company. No CVS Health name, logo, or branding is used beyond attributing the referenced repositories. |
| DOC-7 | Must | Material taken or adapted from the CVS Health repositories is attributed and used in line with each repository's license. |
| DOC-4 | Should | Reference [MDN accessibility guides](https://developer.mozilla.org/en-US/docs/Web/Accessibility) for web guidance. |
| DOC-5 | Must | Each technique doc contains: what and why, WCAG criteria, platform applicability, good and bad code with explanation, limitations, sources, and AT verification results. |

### 4.4 Deliverables

| ID | Priority | Requirement |
| --- | --- | --- |
| APP-1 | Should | One Flutter app with a shared technique catalog, built for Android, iOS, and Web, akin to the CVS techniques apps. |
| APP-2 | Should | One Widgetbook project built for Android, iOS, and Web, exposing the same good and bad examples, with use cases filtered by platform applicability. |
| APP-3 | Must | The app itself (navigation, catalog, documentation views) meets WCAG 2.2 AA. |
| APP-4 | Must | The web build enables the semantics tree at startup using the documented `SemanticsBinding.instance.ensureSemantics()`. Flutter's default opt-in behaviour is documented as a technique. |
| APP-5 | Must | The Flutter SDK is pinned to an exact version on the stable line one behind the latest (latest stable minus one). Each upgrade is its own change that re-runs every suite and re-records evidence where behaviour changed. |
| APP-6 | Must | The repository is public with a README. The app shell is English only in v1. |

### 4.5 Validation

| ID | Priority | Requirement |
| --- | --- | --- |
| VAL-1 | Must | Every technique is validated in the Flutter stack: `flutter_test` semantics assertions and accessibility guideline checks, plus `integration_test` on each applicable platform. |
| VAL-2 | Must | Every technique is validated by platform UI automation against the platform accessibility tree: Playwright (web), XCUITest (iOS), Espresso / UI Automator (Android). |
| VAL-3 | Must | Bad examples have tests asserting that their specific defect is present, so a framework upgrade cannot silently fix a demo. |
| VAL-4 | Must | Screen reader behaviour is verified through automation rather than manual testing alone: VoiceOver scripting and AppleScript, emulator and simulator control, and agent-driven computer use (including VoiceOver with Chrome). |
| VAL-5 | Must | Spoken-output assertions are a pass/fail gate where they are deterministic. Where they are not, the run produces a recorded transcript stored with the technique as evidence. |
| VAL-6 | Must | Evidence records the AT, OS, browser, and Flutter versions and the date. |
| VAL-8 | Must | v1 screen readers are TalkBack (Android), VoiceOver (iOS), and VoiceOver on macOS with Chrome and Safari (web). |
| VAL-9 | Must | Each applicable technique is verified for keyboard operation: focus order, focus visibility, and key bindings (per APG on web). |
| VAL-10 | Must | Each applicable technique is verified for text scaling, reflow and zoom, contrast (including dark and high-contrast modes), and reduced motion. |
| VAL-11 | Must | Speech transcripts and version metadata are committed as text beside each technique. Screenshots and recordings are kept out of git and attached to CI runs or releases. |
| VAL-7 | Must | Flutter tests, Playwright, Espresso / UI Automator, and XCUITest run in GitHub Actions on every pull request. Screen reader automation runs locally on a Mac and commits its results. |

### 4.6 Delivery

| ID | Priority | Requirement |
| --- | --- | --- |
| DEL-1 | Must | Start with a vertical slice: scaffold plus a few techniques (for example button, heading, text field) taken through app, Widgetbook, docs, and every validation layer. |
| DEL-2 | Must | Scale across the catalog in batches only after the slice proves the structure and the test layers. |

## 5. Decision log

| # | Date | Decision | Alternatives rejected |
| --- | --- | --- | --- |
| D1 | 2026-11-12 | Platforms are Android, iOS, Web. | Native desktop. |
| D2 | 2026-11-12 | One app with a shared catalog; techniques declare platform applicability. | Separate app per platform; packages with thin shells. |
| D3 | 2026-11-12 | Material plus Cupertino, with widgets-layer examples for custom components. | Material only; widgets layer first. |
| D4 | 2026-11-12 | Docs live in repo Markdown, in-app, and in Widgetbook. | Published docs site. |
| D5 | 2026-11-12 | Required test tools: Flutter tests, Playwright, XCUITest, Espresso / UI Automator. | Maestro. |
| D6 | 2026-11-12 | Bad examples are asserted to fail. | Excluding or smoke-testing them. |
| D7 | 2026-11-12 | Flutter limitations keep a catalog entry with a limitation doc. | Doc only; omitting. |
| D8 | 2026-11-12 | Screen reader verification is automated (VoiceOver scripting, AppleScript, computer use, emulator control), not a manual matrix. | Manual-only recorded matrix. |
| D9 | 2026-11-12 | Spoken output gates where stable, otherwise recorded as evidence. | Hard gate everywhere; evidence only. |
| D10 | 2026-11-12 | Good examples are Flutter SDK only. | Vetted or any third-party packages. |
| D11 | 2026-11-12 | GitHub Actions for tree-level suites; screen reader automation local. | All local; all CI. |
| D12 | 2026-11-12 | Vertical slice first, then batches. | Full inventory first; platform by platform. |

| D13 | 2026-11-12 | NVDA deferred; web verified with VoiceOver on macOS in Chrome and Safari. | Windows VM; Windows CI runner. |
| D14 | 2026-11-12 | One Widgetbook project, three platform builds. | Web-only Widgetbook; separate Widgetbooks. |
| D15 | 2026-11-12 | Beyond screen readers, verify keyboard and text scaling / zoom / contrast. | Switch and voice control verification in v1. |
| D16 | 2026-11-12 | Pin an exact stable Flutter version; upgrade deliberately. | Tracking latest stable; beta canary job. |
| D17 | 2026-11-12 | Web semantics always on at startup. | Flutter default opt-in; switchable. |
| D18 | 2026-11-12 | Localization and RTL as techniques only; app shell English only. | Localized app; out of scope. |
| D19 | 2026-11-12 | Transcripts as text in repo; media as CI or release artifacts. | All in repo with LFS; artifacts only. |
| D20 | 2026-11-12 | Public repo, solo for now; contribution scaffolding later. | Contributor-ready in v1; private. |
| D21 | 2026-11-12 | Flutter pin is latest stable minus one (currently 3.47.5, with 3.50.0 just released). Fixes only in the newest stable are recorded as limitations until the pin moves. | Pinning the newest stable. |

## 5a. Status after the vertical slice (2026-11-13)

The slice built four techniques end to end. The requirements above are
unchanged. Where the slice did not meet one, the gap and a proposal are in
[slice-review.md](slice-review.md), sections 3 and 4, for the owner to decide:

| Requirement | Status after the slice |
| --- | --- |
| VAL-1 | `integration_test` not built; proposed for removal |
| VAL-2 | Met with Playwright, XCUITest, and UI Automator. Espresso cannot see Flutter content |
| VAL-5 | Speech is a gate for TalkBack, VoiceOver on iOS (focus speech), and VoiceOver on web |
| VAL-8 | Web runs use Playwright's Chromium and WebKit builds, not Chrome and Safari |
| VAL-9 | Keyboard verified in widget tests and on web; focus visibility not asserted |
| VAL-10 | Text scaling and light and dark contrast checked; zoom, high contrast, and reduced motion not |
| DOC-5 | Docs describe code but do not show it |
| TEC-6 | Limitations documented in [flutter-limitations.md](flutter-limitations.md); no Flutter issues filed or linked |
| APP-2 | Widgetbook does not filter by platform |
| CAT-1 to CAT-3 | 4 of 102 inventory entries built |

## 6. Open questions

1. **Minimum OS and browser versions.** Proposed default: the minimums supported
   by the pinned Flutter stable release, with AT verification on the current
   major OS and browser versions. To be confirmed in the plan.

## 7. Assumptions to verify

These have not been checked yet and will be confirmed during planning.

- The complete technique lists of the three CVS repos have not been inventoried.
  CAT-5 is the deliverable that does this.
- Which APG patterns and HTML elements Flutter can express on each platform is
  unknown until each is built and tested. TEC-6 covers the outcome.
- The reliability of scripted VoiceOver and TalkBack speech capture is unproven
  for this project. The vertical slice (DEL-1) is where D9's "stable" line is set.

## 8. Next documents

1. [Coverage inventory](coverage-inventory.md) (CAT-5) — drafted.
2. [Architecture and vertical-slice plan](plan.md) — drafted.
3. Specs: one per vertical-slice technique under `docs/specs/`, then per batch.
