// L3 (tree) and L4 (VoiceOver) for C06 Disclosure on iOS.
// Spec: docs/specs/C06-disclosure.md.
//
// No example has a test identifier (TestId's MergeSemantics would take the
// open panel into the control), so the control is found by its label. No
// Flutter widget for a disclosure gives iOS an expanded state (FL-260,
// FL-264): XCUITest shows no value for any control here, and the tests
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
    // Open, the panel's text joins the control (FL-265).
    XCTAssertTrue(element(labelled: "\(Self.title)\n\(Self.panelText)").exists)
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
       ["Details \(text) \(openHint)", count]),
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
      try doubleTapOpens(example.slug, voiceOver)
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
  /// Puts VoiceOver's cursor on the control (with VoiceOver on, a tap only
  /// moves it), checks what is said there, then sends XCUITest's double tap
  /// at the control's place (at the icon for `bad-expand-icon`, whose label
  /// takes no taps) and checks it opened. As C04 measured (probe round 3),
  /// that gesture acts on what is under it and is not VoiceOver's
  /// activation of what its cursor is on, which XCUIVoiceOverService cannot
  /// make; so what VoiceOver's own double tap does is not measured here.
  /// Logs what VoiceOver said after the gesture, a row of the transcript.
  @available(iOS 27.0, *)
  private func doubleTapOpens(_ slug: String, _ voiceOver: XCUIVoiceOverService) throws {
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    let e = control
    e.tap()
    usleep(1_500_000)
    let cursor = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
    XCTAssertTrue(cursor.hasPrefix(Self.title), "\(slug): the cursor is on the control: \(cursor)")
    XCTAssertFalse(shown(Self.panelText), "\(slug): moving the cursor opened nothing")
    if slug == "bad-expand-icon" { iconPoint(e).doubleTap() } else { e.doubleTap() }
    var heard: [String] = []
    for _ in 0..<8 {
      usleep(500_000)
      let s = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
      if heard.last != s { heard.append(s) }
    }
    let opened = shown(Self.panelText)
    print("C06VO xcuitest-double-tap-\(slug) | cursor on \(cursor) / then heard \(heard.joined(separator: " | ")) / \(opened ? "it opened" : "nothing opened")")
    XCTAssertTrue(opened, "\(slug): XCUITest's double tap at the control opens it")
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
