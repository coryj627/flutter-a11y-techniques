// L3 (tree) and L4 (VoiceOver) for C06 Disclosure on iOS.
// Spec: docs/specs/C06-disclosure.md.
//
// No example has a test identifier (TestId's MergeSemantics would take the
// open panel into the control), so the control is found by its label.
// Flutter passes no expanded state to iOS (FL-260), and none of these
// widgets sets one (FL-264, FL-265, FL-267): XCUITest shows no value for any control here, and the tests
// expect none, so that they fail when one appears. XCUITest cannot read
// traits or hints: what VoiceOver says is checked by the walk.
import XCTest

final class C06DisclosureUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "C06"
  static let countLabel = "Presses"
  let app = XCUIApplication()
  private static let title = "Details"
  private static let panelText = "Orders ship in two days."
  private static let panelAction = "Change address"

  override func setUp() {
    continueAfterFailure = true
  }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), settle: 300_000, file: file, line: line)
  }

  /// The control, closed: the element labelled with the title.
  private var control: XCUIElement { element(labelled: Self.title) }

  /// Whether the text `text` is on screen, as an element's label or part of one.
  private func shown(_ text: String) -> Bool {
    app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).count > 0
  }

  /// Waits up to 5 seconds for `condition`.
  private func waitFor(_ what: String, file: StaticString = #filePath, line: UInt = #line, _ condition: () -> Bool) {
    let deadline = Date().addingTimeInterval(5)
    while !condition() && Date() < deadline { usleep(100_000) }
    XCTAssertTrue(condition(), what, file: file, line: line)
  }

  private func value(_ e: XCUIElement) -> String { (e.value as? String) ?? "" }

  private func tab(_ times: Int) {
    for _ in 0..<times {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(700_000)
    }
  }

  /// A tap at `bad-expand-icon`'s icon, at the end of its row: only the
  /// icon takes taps, and the element's middle is over its label.
  private func iconPoint(_ e: XCUIElement) -> XCUICoordinate {
    e.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -24, dy: 0))
  }

  func testGoodMaterialIsAButtonWithNoValue() {
    open("good-material")
    XCTAssertEqual(control.elementType, .button)
    XCTAssertEqual(value(control), "", "no state (FL-260)")
    XCTAssertEqual(app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }.map(\.label), [Self.title],
                   "the control is the only button but Back")
    XCTAssertFalse(shown(Self.panelText), "a closed panel is not on screen")
  }

  func testGoodMaterialOpensByATapStraightAfterTheControl() {
    open("good-material")
    let e = control
    e.tap()
    waitFor("a tap opens it") { self.shown(Self.panelText) }
    XCTAssertEqual(value(control), "", "still no value")
    XCTAssertEqual(control.elementType, .button)
    // The panel sits under the control on screen. XCUITest's list is not
    // the reading order; the VoiceOver walk checks that.
    let top = { (label: String) in self.element(labelled: label).frame.minY }
    XCTAssertGreaterThanOrEqual(top(Self.panelText), control.frame.maxY - 1, "the text is below the control")
    XCTAssertGreaterThan(top(Self.panelAction), top(Self.panelText), "the button is below the text")
    control.tap()
    waitFor("a second tap closes it") { !self.shown(Self.panelText) }
  }

  /// XCUITest cannot see Flutter's focus (I01), so focus is shown by what
  /// the keys do: the first Tab goes to Back and the second to the
  /// control; the key then opens it, and the same key again closes it (so
  /// focus stayed on it). Had focus been on Back, the key would have left
  /// the example. Each key is sent once.
  private func opensAndClosesByKey(_ key: String, _ name: String) {
    open("good-material")
    tab(2)
    app.typeKey(key, modifierFlags: [])
    waitFor("Tab, Tab, \(name) opens it") { self.shown(Self.panelText) }
    XCTAssertTrue(countElement("good-material").exists, "\(name) stayed on the example")
    app.typeKey(key, modifierFlags: [])
    waitFor("\(name) again closes it") { !self.shown(Self.panelText) }
    XCTAssertTrue(countElement("good-material").exists, "\(name) again stayed on the example")
  }

  func testGoodMaterialIsReachedByTabAndOpenedAndClosedByEnter() { opensAndClosesByKey("\n", "Enter") }

  func testGoodMaterialIsReachedByTabAndOpenedAndClosedBySpace() {
    opensAndClosesByKey(XCUIKeyboardKey.space.rawValue, "Space")
  }

  /// Open, the next Tab goes to the panel's button: Enter, sent once,
  /// presses it.
  func testGoodMaterialOpenPanelButtonIsTheNextTabStop() {
    open("good-material")
    tab(2)
    app.typeKey("\n", modifierFlags: [])
    waitFor("Tab, Tab, Enter opens it") { self.shown(Self.panelText) }
    expectCount("good-material", 0)
    tab(1)
    app.typeKey("\n", modifierFlags: [])
    expectCount("good-material", 1)
    XCTAssertTrue(shown(Self.panelText), "the panel is still open")
  }

  // Each bad example is asserted to have its named defect.

  func testBadExpansionTileIsNotAButton() {
    open("bad-expansion-tile")
    let e = control
    XCTAssertTrue(e.exists)
    XCTAssertNotEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "")
    XCTAssertEqual(app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }.count, 0, "no button but Back")
    e.tap()
    // The positive control: the tap opened it.
    waitFor("a tap opens it") { self.shown(Self.panelText) }
    XCTAssertNotEqual(control.elementType, .button)
  }

  func testBadExpandIconIsAButtonWithNoValue() {
    open("bad-expand-icon")
    let e = control
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "")
    // A tap at the middle of the control, over its label, opens nothing;
    // a tap at its icon, in the same launch, opens it.
    e.tap()
    sleep(2)
    XCTAssertFalse(shown(Self.panelText), "a tap at the label opened nothing")
    iconPoint(control).tap()
    waitFor("a tap at the icon opens it") { self.shown(Self.panelText) }
    XCTAssertEqual(control.elementType, .button)
    XCTAssertEqual(value(control), "", "still no value")
  }

  func testBadCupertinoExpansionTileIsNoButtonAndHasNoValue() {
    open("bad-cupertino-expansion-tile")
    let e = control
    XCTAssertTrue(e.exists)
    XCTAssertNotEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "")
    e.tap()
    waitFor("a tap opens it") { self.shown(Self.panelText) }
    // Open, the panel's text joins the control (FL-265): one element whose
    // label starts with the title and holds the text, still no button.
    let merged = app.descendants(matching: .any).matching(
      NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", Self.title, Self.panelText))
    waitFor("an element holds the title and the panel's text") { merged.count > 0 }
    let holding = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", Self.panelText))
    print("C06IOS bad-cupertino-expansion-tile open: elements holding the text: \(holding.allElementsBoundByIndex.map { "\($0.elementType.rawValue) \($0.label.debugDescription)" })")
    XCTAssertEqual(merged.count, 1, "one element holds the title and the panel's text")
    print("C06IOS bad-cupertino-expansion-tile open: label \(merged.firstMatch.label.debugDescription), type \(merged.firstMatch.elementType.rawValue)")
    XCTAssertNotEqual(merged.firstMatch.elementType, .button)
    XCTAssertEqual(value(merged.firstMatch), "")
  }

  /// One, two, or three Tabs and then Enter or Space, each from a fresh
  /// launch and each key sent once: no number of Tabs puts a key on the
  /// control, so no key opens it. After a key the example has left the
  /// screen (Back took it), the positive control; on good-material the same
  /// two Tabs and key open it (the tests above).
  func testBadCupertinoExpansionTileIsOpenedByNoKey() {
    for tabs in 1...3 {
      for key in ["\n", XCUIKeyboardKey.space.rawValue] {
        let name = key == "\n" ? "Enter" : "Space"
        open("bad-cupertino-expansion-tile")
        tab(tabs)
        app.typeKey(key, modifierFlags: [])
        waitFor("\(tabs) Tab(s), \(name): the key acted, on Back") {
          !self.countElement("bad-cupertino-expansion-tile").exists
        }
        XCTAssertFalse(shown(Self.panelText), "\(tabs) Tab(s), \(name): it did not open")
      }
    }
  }

  /// Shift+Tab, as the other direction of the test above. Each launch sends
  /// one, two, or three Shift+Tabs and then Enter, each key once: none opens
  /// the tile, and Back takes the key. The positive control, in the next
  /// test: Shift+Tab, sent the same way, moves focus back onto
  /// good-material's control.
  /// Skipped below iOS 27: on CI's iOS 26.5, keys with a modifier sent by
  /// XCUITest were unreliable (I02, I04, I08), so CI gives up this check.
  func testBadCupertinoExpansionTileIsOpenedByNoKeyAfterShiftTab() throws {
    if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27 {
      throw XCTSkip("keys with a modifier were unreliable on CI's iOS 26.5 (I02, I04, I08)")
    }
    for presses in 1...3 {
      open("bad-cupertino-expansion-tile")
      for _ in 0..<presses {
        app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: .shift)
        usleep(700_000)
      }
      app.typeKey("\n", modifierFlags: [])
      waitFor("\(presses) Shift+Tab(s), Enter: the key acted, on Back") {
        !self.countElement("bad-cupertino-expansion-tile").exists
      }
      XCTAssertFalse(shown(Self.panelText), "\(presses) Shift+Tab(s), Enter: it did not open")
    }
  }

  /// The positive control for the test above: Shift+Tab, sent the same
  /// way, moves keyboard focus back onto good-material's control. Two Tabs
  /// and Enter open it; one Tab goes on to the panel's button; one
  /// Shift+Tab comes back to the control, and Enter there closes it, with
  /// the panel's button never pressed (the count stays 0) and the example
  /// still on screen. Had the Shift been lost, focus would have moved on,
  /// off the control, and Enter would not have closed the panel while the
  /// example stayed. Each key is sent once. In the first run, one
  /// Shift+Tab from launch and Enter left the example, as Enter on Back
  /// does (docs/evidence/probes/c06/ios-shift-tab-first-run.txt).
  func testGoodMaterialIsReachedByShiftTab() throws {
    if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27 {
      throw XCTSkip("keys with a modifier were unreliable on CI's iOS 26.5 (I02, I04, I08)")
    }
    open("good-material")
    tab(2)
    app.typeKey("\n", modifierFlags: [])
    waitFor("Tab, Tab, Enter opens it") { self.shown(Self.panelText) }
    tab(1)
    app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: .shift)
    usleep(700_000)
    app.typeKey("\n", modifierFlags: [])
    waitFor("Shift+Tab back to the control, Enter closes it") { !self.shown(Self.panelText) }
    expectCount("good-material", 0)
    XCTAssertTrue(countElement("good-material").exists, "Enter stayed on the example")
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end
  // of the screen (C06Walk), the count included, compared as a whole list:
  // closed, then after the control has been opened by XCUITest's double tap
  // at it with VoiceOver on. That is a tap at its place and not VoiceOver's
  // own activation: XCUIVoiceOverService has no activation (C04 probe
  // round 3, docs/evidence/probes/c04/ios_round3.txt).
  private let speech: [(slug: String, closed: [String], open: [String])] = {
    // From the probe (docs/evidence/probes/c06, ios.txt): the tiles' hint,
    // after "Button" where there is one.
    let count = "Presses: 0"
    let text = "Orders ship in two days."
    let action = "Change address Button"
    let closedHint = "Collapsed double tap to expand"
    let openHint = "Expanded double tap to collapse"
    return [
      ("good-material", ["Details Button \(closedHint)", count],
       ["Details Button \(openHint)", text, action, count]),
      // Bad examples: the defect must be audible.
      ("bad-expansion-tile", ["Details \(closedHint)", count],
       ["Details \(openHint)", text, action, count]),
      ("bad-expand-icon", ["Details Button", count],
       ["Details Button", text, action, count]),
      ("bad-cupertino-expansion-tile", ["Details \(closedHint)", count],
       // Open, the panel's text joins the control (FL-265), and the
       // utterance runs past the 64 characters XCUIVoiceOverService
       // returns: what is compared is the cut reading, as the first run
       // heard it (docs/evidence/C06/voiceover-ios.md).
       ["Details \(text) Expanded double tap to collaps", count]),
    ]
  }()

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      let closed = try C06Walk.walk(voiceOver)
      let closedContent = C06Walk.content(closed)
      print("C06VO \(example.slug) | \((closedContent ?? closed.stops).joined(separator: " / "))")
      XCTAssertNotNil(closedContent, "\(example.slug): the walk did not run from the heading to the end: \(closed)")
      XCTAssertEqual(closedContent, example.closed, example.slug)
      try doubleTapOpens(example.slug, voiceOver, cursor: example.closed[0], next: example.open[1])
      let opened = try C06Walk.walk(voiceOver)
      let openContent = C06Walk.content(opened)
      print("C06VO \(example.slug)-open | \((openContent ?? opened.stops).joined(separator: " / "))")
      XCTAssertNotNil(openContent, "\(example.slug) open: the walk did not run from the heading to the end: \(opened)")
      XCTAssertEqual(openContent, example.open, "\(example.slug) open")
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  /// C06Walk's end and content need no device. A stop after the expected
  /// ones must make the comparison fail, and a walk that does not reach the
  /// end, or never passes the heading, gives no content.
  func testWalkToTheEndSeesAnExtraStop() {
    func run(_ utterances: [String]) -> C06Walk.Result {
      var rest = utterances[...]
      return C06Walk.collect { rest.isEmpty ? "(nothing left)" : rest.removeFirst() }
    }
    let control = "Details Button Collapsed double tap to expand"
    let count = "Presses: 0"
    let normal = run(["Back Button", "Example Heading", control, count, count, count])
    XCTAssertTrue(normal.reachedEnd)
    XCTAssertEqual(C06Walk.content(normal), [control, count])
    let extra = run(["Back Button", "Example Heading", control, count, "Extra", "Extra", "Extra"])
    XCTAssertEqual(C06Walk.content(extra), [control, count, "Extra"])
    XCTAssertNotEqual(C06Walk.content(extra), [control, count])
    let endless = run((0..<40).map { "Item \($0)" })
    XCTAssertFalse(endless.reachedEnd)
    XCTAssertNil(C06Walk.content(endless))
    XCTAssertNil(C06Walk.content(run([control, count, count, count])))
    // An empty capture repeats one utterance: no heading, so no content.
    XCTAssertNil(C06Walk.content(run(["", "", ""])))
  }

  #if compiler(>=6.4)
  /// What VoiceOver must say once XCUITest's double tap has opened each
  /// example: `ExpansionTile` announces "Expanded" (on iOS after a second,
  /// its source and the widget tests); `ExpandIcon` and
  /// `CupertinoExpansionTile` were heard to say nothing more (the first
  /// transcripts), which is now judged as an absence.
  private static let onChange: [String: C06Speech.Change] = [
    "good-material": .announces("Expanded"),
    "bad-expansion-tile": .announces("Expanded"),
    "bad-expand-icon": .silent,
    "bad-cupertino-expansion-tile": .silent,
  ]

  /// Puts VoiceOver's cursor on the control (with VoiceOver on, a tap only
  /// moves it), reads what is said there (`before`), then sends XCUITest's
  /// double tap at the control's place (at the icon for `bad-expand-icon`,
  /// whose label takes no taps) and reads `currentSpeech()` eight times,
  /// half a second apart. Every read is kept raw, a failure as a failure
  /// (C06Speech.Poll), and judged whole by C06Speech: the reading before
  /// must be the control's closed utterance `cursor`, every read after
  /// must be readable, and the example's expectation (onChange) must hold.
  /// For an absence, the cursor is then moved on, and that reading must be
  /// the next stop, `next`: the liveness reading after. As C04 measured
  /// (probe round 3), the gesture acts on what is under it and is not
  /// VoiceOver's activation of what its cursor is on, which
  /// XCUIVoiceOverService cannot make; so what VoiceOver's own double tap
  /// does is not measured here. Logs every raw read, a row of the
  /// transcript.
  @available(iOS 27.0, *)
  private func doubleTapOpens(_ slug: String, _ voiceOver: XCUIVoiceOverService, cursor: String, next: String) throws {
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    func poll() -> C06Speech.Poll {
      do {
        return .speech(VoiceOverWalk.normalized(try voiceOver.currentSpeech().utterance))
      } catch let error as NSError {
        return .failed("\(error.domain) \(error.code)")
      }
    }
    let e = control
    e.tap()
    usleep(1_500_000)
    let before = poll()
    XCTAssertFalse(shown(Self.panelText), "\(slug): moving the cursor opened nothing")
    if slug == "bad-expand-icon" { iconPoint(e).doubleTap() } else { e.doubleTap() }
    var polls: [C06Speech.Poll] = []
    for _ in 0..<8 {
      usleep(500_000)
      polls.append(poll())
    }
    let opened = shown(Self.panelText)
    let change = Self.onChange[slug]!
    var after: C06Speech.Poll? = nil
    if case .silent = change {
      after = {
        do {
          return .speech(VoiceOverWalk.normalized(try voiceOver.moveForward().utterance))
        } catch let error as NSError {
          return .failed("\(error.domain) \(error.code)")
        }
      }()
    }
    let verdict = C06Speech.judge(change, cursor: cursor, before: before, polls: polls, after: after, next: next)
    let raw = polls.map(C06Speech.describe).joined(separator: " | ")
    let afterText = after.map { " / then moved on: \(C06Speech.describe($0))" } ?? ""
    print("C06VO xcuitest-double-tap-\(slug) | cursor on \(C06Speech.describe(before)) / then read \(raw)\(afterText) / \(opened ? "it opened" : "nothing opened") / \(verdict ?? "as expected")")
    XCTAssertTrue(opened, "\(slug): XCUITest's double tap at the control opens it")
    XCTAssertNil(verdict, "\(slug): what VoiceOver said on the change")
  }
  #endif
}

/// The C06 VoiceOver walk, as C05's: from the top of the screen to its end,
/// which is where moving on gives the last element again, twice. The count
/// is the example's last element, and it is compared with the rest. A move
/// with no speech is handled as VoiceOverWalk.forward does (afterNoSpeech).
/// Two neighbouring elements that VoiceOver reads alike would count as one;
/// no C06 example has two.
enum C06Walk {
  struct Result: Equatable {
    var stops: [String]
    var reachedEnd: Bool
  }

  /// Reads utterances from `next` until the same one has come three times
  /// in a row, at most `max` reads.
  static func collect(max: Int = 30, _ next: () throws -> String) rethrows -> Result {
    var stops: [String] = []
    var repeats = 0
    for _ in 0..<max {
      let utterance = try next()
      if utterance == stops.last {
        repeats += 1
        if repeats == 2 { return Result(stops: stops, reachedEnd: true) }
      } else {
        repeats = 0
        stops.append(utterance)
      }
    }
    return Result(stops: stops, reachedEnd: false)
  }

  /// Every stop after the last "Example Heading", to the end; nil when the
  /// walk did not reach the end or never passed the heading.
  static func content(_ result: Result) -> [String]? {
    guard result.reachedEnd, let heading = result.stops.lastIndex(of: "Example Heading") else { return nil }
    return Array(result.stops[(heading + 1)...])
  }

  #if compiler(>=6.4)
  /// Switches VoiceOver on, walks to the end of the screen, and switches it
  /// off.
  @available(iOS 27.0, *)
  static func walk(_ voiceOver: XCUIVoiceOverService) throws -> Result {
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    var last: String?
    return try collect {
      let utterance: String
      do {
        utterance = VoiceOverWalk.normalized(try voiceOver.moveForward().utterance)
      } catch let error as NSError where VoiceOverWalk.isNoSpeech(error) {
        let back = VoiceOverWalk.normalized(try voiceOver.moveBackward().utterance)
        var again: String? = nil
        do {
          again = VoiceOverWalk.normalized(try voiceOver.moveForward().utterance)
        } catch let error as NSError where VoiceOverWalk.isNoSpeech(error) {}
        utterance = VoiceOverWalk.afterNoSpeech(previous: last, back: back, again: again)
      }
      last = utterance
      return utterance
    }
  }
  #endif
}


/// How C06's iOS VoiceOver test judges what is said on the change, kept
/// apart from the device so that it is tested on made-up readings (the
/// testSpeechJudge tests). Written after C26's judge (C26ProgressIndicator
/// UITests on the branch c26-progress), which measured that with VoiceOver
/// on `currentSpeech()` keeps giving the last utterance while nothing is
/// said, and that its one error, "No speech available", came with
/// VoiceOver off; C06's own first transcripts read the same (the
/// double-tap rows of docs/evidence/probes/c06/voiceover-ios-first-run.md.txt).
enum C06Speech {
  /// One read of `currentSpeech()` (or of a move): its utterance, already
  /// normalised by the test (`VoiceOverWalk.normalized`), or the error.
  enum Poll: Equatable {
    case speech(String)
    case failed(String)
  }

  /// What must be said after the change: an announcement, said on its own
  /// as a whole utterance, or nothing.
  enum Change: Equatable {
    case announces(String)
    case silent
  }

  static func describe(_ p: Poll) -> String {
    switch p {
    case .speech(let s): return "\"\(s)\""
    case .failed(let e): return "(failed: \(e))"
    }
  }

  /// nil when the reads show what `change` says, or why not. Every raw read
  /// is judged, none filtered, compared as whole strings:
  ///
  /// - `cursor`, `next`, and an announcement must be non-empty and shorter
  ///   than the 64 characters XCUIVoiceOverService returns, and all
  ///   different, so that a stale reading cannot pass for a new one;
  /// - `before`, read with the cursor on the control before the gesture,
  ///   must be exactly `cursor` (the capture was live, and what was said
  ///   before is known);
  /// - every read after the gesture must be readable: a failed read or an
  ///   empty one fails;
  /// - for an announcement, the reads must be the control's utterance
  ///   `cursor` for a while (none at all included), then the announcement
  ///   from its first reading to the last read: a missing one, any other
  ///   text, or a return to `cursor` after it (another reading, or a stale
  ///   capture, as a quiet read keeps the last utterance) fails;
  /// - for silence, every read must be `cursor` (what `currentSpeech()`
  ///   gives while nothing is said), and `after`, read once the cursor has
  ///   moved on, must be exactly `next`: the capture was live after.
  static func judge(_ change: Change, cursor: String, before: Poll, polls: [Poll], after: Poll?, next: String) -> String? {
    var expected = [("cursor", cursor), ("next", next)]
    if case .announces(let a) = change { expected.append(("announcement", a)) }
    for (name, text) in expected {
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "the expected \(name) utterance is empty" }
      if text.count >= 64 { return "the expected \(name) utterance is 64 characters or more" }
    }
    if Set(expected.map(\.1)).count != expected.count { return "two expected utterances are the same" }
    guard before == .speech(cursor) else { return "the reading before was \(describe(before)), not the control's \"\(cursor)\"" }
    guard polls.count >= 4 else { return "only \(polls.count) reads after the gesture" }
    for (i, p) in polls.enumerated() {
      switch p {
      case .failed: return "read \(i + 1) failed: \(describe(p))"
      case .speech(let s) where s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
        return "read \(i + 1) was empty"
      default: break
      }
    }
    switch change {
    case .announces(let a):
      guard let first = polls.firstIndex(of: .speech(a)) else {
        for (i, p) in polls.enumerated() where p != .speech(cursor) {
          return "read \(i + 1) was \(describe(p)), neither the control nor \"\(a)\""
        }
        return "\"\(a)\" was never read"
      }
      for (i, p) in polls.enumerated() {
        if i < first, p != .speech(cursor) {
          return "read \(i + 1) was \(describe(p)), before \"\(a)\" only the control's utterance may be read"
        }
        if i > first, p != .speech(a) {
          return "read \(i + 1) was \(describe(p)), after \"\(a)\" every read must be \"\(a)\""
        }
      }
      return nil
    case .silent:
      for (i, p) in polls.enumerated() where p != .speech(cursor) {
        return "read \(i + 1) was \(describe(p)), not silence (the control's \"\(cursor)\")"
      }
      guard let after else { return "no reading after" }
      guard after == .speech(next) else { return "the reading after was \(describe(after)), not \"\(next)\"" }
      return nil
    }
  }
}

// The judge on made-up readings. In the technique's own class, so that the
// iOS tree run (`evidence.py --only ios`) runs them; they need no app and
// no VoiceOver.
extension C06DisclosureUITests {
  private static let cursorText = "Details Button Collapsed double tap to expand"
  private static let nextText = "Orders ship in two days."
  private static let failure = C06Speech.Poll.failed("com.apple.xctest.voiceoverservice 3")

  private func announced(_ before: C06Speech.Poll, _ polls: [C06Speech.Poll]) -> String? {
    C06Speech.judge(.announces("Expanded"), cursor: Self.cursorText, before: before, polls: polls, after: nil,
                    next: Self.nextText)
  }

  private func silent(_ before: C06Speech.Poll, _ polls: [C06Speech.Poll], _ after: C06Speech.Poll?) -> String? {
    C06Speech.judge(.silent, cursor: Self.cursorText, before: before, polls: polls, after: after, next: Self.nextText)
  }

  func testSpeechJudgeNamedCases() {
    let c = C06Speech.Poll.speech(Self.cursorText)
    let x = C06Speech.Poll.speech("Expanded")
    let n = C06Speech.Poll.speech(Self.nextText)
    // An announcement: heard as recorded (the cursor, then "Expanded"),
    // with the first reading anywhere.
    XCTAssertNil(announced(c, [c, x, x, x, x, x, x, x]))
    XCTAssertNil(announced(c, [c, c, x, x, x, x, x, x]))
    XCTAssertNil(announced(c, [x, x, x, x, x, x, x, x]))
    XCTAssertNil(announced(c, [c, c, c, c, c, c, c, x]))
    // A return to the control's utterance after "Expanded", midway or on
    // the last read: another reading, or a stale capture.
    XCTAssertNotNil(announced(c, [c, x, x, c, x, x, x, x]))
    XCTAssertNotNil(announced(c, [c, x, x, x, x, x, x, c]))
    XCTAssertNotNil(announced(c, [x, c, c, c, c, c, c, c]))
    // Missing with the panel open: the cursor's reading all along.
    XCTAssertNotNil(announced(c, Array(repeating: c, count: 8)))
    // A wrong announcement, alone or beside the right one.
    XCTAssertNotNil(announced(c, [c, .speech("Collapsed"), .speech("Collapsed"), c, c, c, c, c]))
    XCTAssertNotNil(announced(c, [c, x, .speech("Collapsed"), x, x, x, x, x]))
    // A failed read, or an empty one, anywhere fails, even beside the
    // announcement.
    XCTAssertNotNil(announced(c, [c, x, Self.failure, x, x, x, x, x]))
    XCTAssertNotNil(announced(c, [c, x, .speech(""), x, x, x, x, x]))
    XCTAssertNotNil(announced(c, Array(repeating: Self.failure, count: 8)))
    // Stale: the announcement read before the gesture cannot count.
    XCTAssertNotNil(announced(x, Array(repeating: x, count: 8)))
    XCTAssertNotNil(announced(.speech(""), [c, x, x, x, x, x, x, x]))
    XCTAssertNotNil(announced(Self.failure, [c, x, x, x, x, x, x, x]))
    // Too few reads.
    XCTAssertNotNil(announced(c, [x, x]))
    // Silence: the cursor all along, then the next stop.
    XCTAssertNil(silent(c, Array(repeating: c, count: 8), n))
    // Silence with no liveness after, or a wrong one, or a stale one.
    XCTAssertNotNil(silent(c, Array(repeating: c, count: 8), nil))
    XCTAssertNotNil(silent(c, Array(repeating: c, count: 8), Self.failure))
    XCTAssertNotNil(silent(c, Array(repeating: c, count: 8), c))
    XCTAssertNotNil(silent(c, Array(repeating: c, count: 8), .speech("")))
    // Silence that was not: an announcement, or a failed or empty read.
    XCTAssertNotNil(silent(c, [c, c, x, x, x, x, x, x], n))
    XCTAssertNotNil(silent(c, [c, c, Self.failure, c, c, c, c, c], n))
    XCTAssertNotNil(silent(c, [c, c, .speech(""), c, c, c, c, c], n))
    // Silence judged with a dead capture before.
    XCTAssertNotNil(silent(Self.failure, Array(repeating: c, count: 8), n))
  }

  /// Every shape of reading before, crossed with every shape of one read
  /// put among seven right ones, at the first, a middle, and the last read,
  /// for both kinds of change. Whether each
  /// passes is worked out here from the rules, separately from the judge.
  func testSpeechJudgeOverEveryShapeOfInput() {
    let c = C06Speech.Poll.speech(Self.cursorText)
    let x = C06Speech.Poll.speech("Expanded")
    let n = C06Speech.Poll.speech(Self.nextText)
    let shapes: [(String, C06Speech.Poll)] = [
      ("cursor", c), ("announcement", x), ("next", n), ("failed", Self.failure), ("empty", .speech("")),
      ("whitespace", .speech("  ")), ("other text", .speech("Collapsed")), ("cursor with a space", .speech(Self.cursorText + " ")),
    ]
    func readable(_ p: C06Speech.Poll) -> Bool {
      if case .speech(let s) = p { return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      return false
    }
    for (beforeName, before) in shapes {
      for (oddName, odd) in shapes {
        for at in [0, 3, 7] {
          // Announcement: seven reads of "Expanded" and one odd one.
          var polls = Array(repeating: x, count: 8)
          polls[at] = odd
          // The cursor's utterance is allowed only before the first
          // "Expanded": here, only as the first read.
          let announceOK = before == c && readable(odd) && (odd == x || (odd == c && at == 0))
          XCTAssertEqual(announced(before, polls) == nil, announceOK,
                         "announces: before \(beforeName), read \(at + 1) \(oddName)")
          // Silence: seven reads of the cursor and one odd one; then the next stop.
          var quiet = Array(repeating: c, count: 8)
          quiet[at] = odd
          let silentOK = before == c && odd == c
          XCTAssertEqual(silent(before, quiet, n) == nil, silentOK,
                         "silent: before \(beforeName), read \(at + 1) \(oddName)")
          // The reading after, in every shape.
          XCTAssertEqual(silent(c, Array(repeating: c, count: 8), odd) == nil, odd == n,
                         "silent: after \(oddName)")
        }
      }
    }
  }

  func testSpeechJudgeRefusesDegenerateExpectations() {
    let c = C06Speech.Poll.speech(Self.cursorText)
    XCTAssertNotNil(C06Speech.judge(.announces(""), cursor: Self.cursorText, before: c,
                                    polls: Array(repeating: c, count: 8), after: nil, next: Self.nextText))
    XCTAssertNotNil(C06Speech.judge(.announces(Self.cursorText), cursor: Self.cursorText, before: c,
                                    polls: Array(repeating: c, count: 8), after: nil, next: Self.nextText))
    XCTAssertNotNil(C06Speech.judge(.silent, cursor: Self.cursorText, before: c,
                                    polls: Array(repeating: c, count: 8), after: c, next: Self.cursorText))
    let long = String(repeating: "a", count: 64)
    XCTAssertNotNil(C06Speech.judge(.silent, cursor: long, before: .speech(long),
                                    polls: Array(repeating: .speech(long), count: 8),
                                    after: .speech(Self.nextText), next: Self.nextText))
  }
}
