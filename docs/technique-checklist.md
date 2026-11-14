# Technique checklist

Tick every item before a technique's pull request is merged. The reasoning
behind each one is in [the technique guide](technique-guide.md).

## Before building

- [ ] Source documents read: the CVS docs, the APG pattern, and the MDN page
      for this entry in the [coverage inventory](coverage-inventory.md)
- [ ] Rough examples probed on web, Android, and iOS, and with each screen
      reader, before any assertion was written

## Examples

- [ ] At least one good and one bad example
- [ ] Good examples use SDK APIs only, and each mechanism traces to a source
- [ ] Each good example works on every platform that could be checked
- [ ] Each bad example has one defect, stated as what the user experiences
- [ ] Material, Cupertino, and widgets-layer variants are covered, or the spec
      says why one is missing
- [ ] Controls use `TestId`; no identifier is placed inside a control
- [ ] An example whose defect could not be demonstrated was dropped, and the
      spec says so

## Tests

- [ ] L1: guidelines in light and dark, and 200% text at 320 by 640, for every
      good example
- [ ] L1: the semantics that carry the technique, for good and bad examples
- [ ] L1: keyboard reach and activation, where the example is interactive
- [ ] L3 web: role, name, state, and keyboard behaviour in Chromium; the spec
      is added to the web job in `ci.yml`
- [ ] L3 Android: node properties through UI Automator
- [ ] L3 iOS: element type, label, and value through XCUITest; the file is in
      the `RunnerUITests` target
- [ ] Every bad example's defect is asserted at every layer that can see it,
      written to fail if Flutter fixes it
- [ ] Where a layer cannot observe something, the test says so in a comment

## Screen readers

- [ ] TalkBack transcript generated with `tool/talkback.py` and passing
- [ ] VoiceOver on iOS transcript generated with `tool/voiceover_ios.py` and
      passing, or the doc and catalog say iOS is not verified and why
- [ ] VoiceOver on web transcript generated with `tool/voiceover_web.py` and
      passing
- [ ] Any check for silence also proves that speech capture was working
- [ ] A surprising result was checked against a native control or plain HTML
      before being blamed on Flutter

## Documents

- [ ] Spec written from [the template](templates/spec-template.md), with
      "What the build found" filled in after the build
- [ ] Technique doc written from
      [the template](templates/technique-doc-template.md); the doc check passes
- [ ] Every limitation is in [flutter-limitations.md](flutter-limitations.md)
      with its status, and the doc links to it
- [ ] A limitation with no workaround is a `PlatformStatus.limitation` in the
      catalog; an unverified platform has a note
- [ ] Anything not done is listed under "Not yet covered" in the doc
- [ ] README's list of techniques updated

## Before merging

- [ ] `dart run tool/doc_code.dart` run after the last change to
      `examples.dart`, so the doc shows the tested code
- [ ] `dart format`, `flutter analyze`, `flutter test`, and the script tests
      pass
- [ ] All Playwright suites and the Widgetbook suite pass against fresh builds
- [ ] This technique's Android and iOS suites and its transcripts pass
      locally. The full device and transcript run is on a schedule and before
      a release (D23); CI runs every tree test on the pull request
- [ ] Codex adversarial review returns "approve"
- [ ] CI is green on the pull request's exact head commit
- [ ] Codoki's review says "Safe to merge", with every thread answered
