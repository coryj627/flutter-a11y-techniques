// L3 (tree) and L4 (VoiceOver) for C05 Accordion on iOS.
// Spec: docs/specs/C05-accordion.md.
//
// Flutter passes no expanded state to iOS (FL-260), so the good examples put
// the state in the header's value on iOS, which XCUITest reads. XCUITest
// cannot read traits: that a header is a heading is checked through what
// VoiceOver says.
import XCTest

final class C05AccordionUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "C05"
  static let countLabel = "Presses"
  let app = XCUIApplication()
  private static let shipping = "Shipping"
  private static let returns = "Returns"
  private static let shippingText = "Orders ship in two days."
  private static let shippingAction = "Track a parcel"

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-material": "Material accordion",
    "good-cupertino": "Cupertino accordion",
    "good-custom": "Accordion built from Semantics",
    "bad-no-state": "Headers with no state",
    "bad-heading-on-button": "Heading on the button",
    "bad-no-heading": "Headers that are not headings",
    "bad-hidden-panel": "Closed sections kept hidden",
    "bad-expansion-tile": "Material ExpansionTile",
    "bad-cupertino-expansion-tile": "CupertinoExpansionTile",
  ]

  private let good = ["good-material", "good-cupertino", "good-custom"]

  private func title(_ slug: String) -> XCUIElement { element(labelled: Self.titles[slug]!) }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), settle: 300_000, file: file, line: line)
  }

  private func header(_ slug: String, _ key: String) -> XCUIElement { element("c05-\(slug)-\(key)") }

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

  func testGoodHeadersAreButtonsWithTheirStateInTheValue() {
    for slug in good {
      open(slug)
      for (key, name) in [("shipping", Self.shipping), ("returns", Self.returns)] {
        let e = header(slug, key)
        XCTAssertEqual(e.elementType, .button, "\(slug) \(key)")
        XCTAssertEqual(e.label, name, "\(slug) \(key)")
        XCTAssertEqual(value(e), "collapsed", "\(slug) \(key)")
      }
      XCTAssertEqual(app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }.count, 2,
                     "\(slug): the two headers are the only buttons but Back")
      XCTAssertFalse(shown(Self.shippingText), "\(slug): a closed panel is not on screen")
    }
  }

  func testGoodHeadersOpenByATapStraightAfterTheHeader() {
    for slug in good {
      open(slug)
      let e = header(slug, "shipping")
      e.tap()
      waitFor("\(slug): a tap opens Shipping") { self.shown(Self.shippingText) }
      waitFor("\(slug): the value says expanded") { self.value(e) == "expanded" }
      XCTAssertEqual(value(header(slug, "returns")), "collapsed", slug)
      // The panel sits between its header and the next one on screen.
      // XCUITest lists a panel's elements after the next header (its
      // descendants come after their parent's siblings), so the list is not
      // the reading order; the VoiceOver walk checks that.
      let top = { (label: String) in self.element(labelled: label).frame.minY }
      XCTAssertGreaterThanOrEqual(top(Self.shippingText), e.frame.maxY - 1, "\(slug): the text is below Shipping")
      XCTAssertGreaterThan(top(Self.shippingAction), top(Self.shippingText), "\(slug): the button is below the text")
      XCTAssertGreaterThan(top(Self.returns), top(Self.shippingAction), "\(slug): Returns is below the panel")
      e.tap()
      waitFor("\(slug): a second tap closes it") { !self.shown(Self.shippingText) }
      waitFor("\(slug): the value says collapsed") { self.value(e) == "collapsed" }
    }
  }

  /// XCUITest cannot see Flutter's focus (I01), so focus is shown by what
  /// the keys do: the first Tab goes to Back and the second to Shipping;
  /// Enter (typed as "\n") or Space then opens it. Had focus been on Back,
  /// the key would have left the example. Each key is sent once.
  func testGoodHeadersAreReachedByTabAndOpenedByEnterAndBySpace() {
    for slug in good {
      for key in ["\n", XCUIKeyboardKey.space.rawValue] {
        let name = key == "\n" ? "Enter" : "Space"
        open(slug)
        app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
        usleep(700_000)
        app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
        usleep(700_000)
        app.typeKey(key, modifierFlags: [])
        waitFor("\(slug): Tab, Tab, \(name) opens Shipping") { self.shown(Self.shippingText) }
        XCTAssertTrue(title(slug).exists, "\(slug): \(name) stayed on the example")
      }
    }
  }

  // Each bad example is asserted to have its named defect.

  func testBadNoStateHasNoValueBeforeOrAfter() {
    open("bad-no-state")
    let e = header("bad-no-state", "shipping")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "")
    e.tap()
    // The positive control: the tap opened the section.
    waitFor("a tap opens Shipping") { self.shown(Self.shippingText) }
    XCTAssertEqual(value(e), "")
  }

  func testBadHeadingOnButtonIsAButtonWithItsStateOnIOS() {
    // The defect is on the web only (web_tests/c05_accordion.spec.js).
    open("bad-heading-on-button")
    let e = header("bad-heading-on-button", "shipping")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "collapsed")
  }

  func testBadNoHeadingIsAButtonWithItsState() {
    // That it is no heading is heard, not seen, in the tree (the VoiceOver
    // walk).
    open("bad-no-heading")
    let e = header("bad-no-heading", "shipping")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "collapsed")
  }

  func testBadHiddenPanelIsNotOnScreenWhileClosed() {
    open("bad-hidden-panel")
    XCTAssertFalse(shown(Self.shippingText))
    XCTAssertFalse(shown(Self.shippingAction))
  }

  /// XCUITest cannot see Flutter's focus, so where Tab goes is shown by
  /// what Enter does. Four Tabs pass Back, Shipping, and Returns, and land
  /// on Shipping's hidden button, as in the widget tests; Enter, sent once,
  /// then presses it: the count goes up while every section stays closed.
  /// Three Tabs and Enter open Returns instead, the positive control that
  /// the third stop is the last header.
  func testBadHiddenPanelTabGoesToAHiddenButton() {
    open("bad-hidden-panel")
    for _ in 0..<4 {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(700_000)
    }
    app.typeKey("\n", modifierFlags: [])
    expectCount("bad-hidden-panel", 1)
    XCTAssertFalse(shown(Self.shippingText), "Shipping stays closed")
    XCTAssertFalse(shown("Return items within 30 days."), "Returns stays closed")

    open("bad-hidden-panel")
    for _ in 0..<3 {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(700_000)
    }
    app.typeKey("\n", modifierFlags: [])
    waitFor("three Tabs and Enter open Returns") { self.shown("Return items within 30 days.") }
    expectCount("bad-hidden-panel", 0)
  }

  func testBadExpansionTileHeaderIsNoButtonAndHasNoValue() {
    open("bad-expansion-tile")
    let e = element(labelled: Self.shipping)
    XCTAssertTrue(e.exists)
    XCTAssertNotEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "")
    XCTAssertEqual(app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }.count, 0, "no button but Back")
    e.tap()
    waitFor("a tap opens Shipping") { self.shown(Self.shippingText) }
  }

  func testBadCupertinoExpansionTileHeaderIsNoButtonAndHasNoValue() {
    open("bad-cupertino-expansion-tile")
    let e = element(labelled: Self.shipping)
    XCTAssertTrue(e.exists)
    XCTAssertNotEqual(e.elementType, .button)
    XCTAssertEqual(value(e), "")
    e.tap()
    waitFor("a tap opens Shipping") { self.shown(Self.shippingText) }
  }

  /// One, two, or three Tabs and then Enter or Space, each from a fresh
  /// launch and each key sent once: no number of Tabs puts a key on a
  /// header, so no key opens a section. After a key, the example has left
  /// the screen (Back took it), the positive control; with good-custom the
  /// same two Tabs and key open Shipping (the test above).
  func testBadCupertinoExpansionTileIsOpenedByNoKey() {
    for tabs in 1...3 {
      for key in ["\n", XCUIKeyboardKey.space.rawValue] {
        let name = key == "\n" ? "Enter" : "Space"
        open("bad-cupertino-expansion-tile")
        for _ in 0..<tabs {
          app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
          usleep(700_000)
        }
        app.typeKey(key, modifierFlags: [])
        sleep(2)
        XCTAssertFalse(shown(Self.shippingText), "\(tabs) Tab(s), \(name): no section opened")
        XCTAssertFalse(countElement("bad-cupertino-expansion-tile").exists,
                       "\(tabs) Tab(s), \(name): the key acted, on Back")
      }
    }
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end
  // of the screen (C05Walk), the count included, compared as a whole list:
  // closed, then after
  // Shipping has been opened by a double tap with VoiceOver on.
  private let speech: [(slug: String, closed: [String], open: [String])] = {
    // From the probe (docs/evidence/probes/c05, ios.txt): VoiceOver reads
    // a value before the traits ("p12 Shipping collapsed Button") and a
    // heading after "Button" ("p08 Shipping Button Heading"). Flutter's
    // `expanded` adds nothing on iOS (FL-260).
    let count = "Presses: 0"
    let text = "Orders ship in two days."
    let action = "Track a parcel Button"
    func header(_ name: String, _ state: String) -> String { "\(name) \(state) Button Heading" }
    let good = (
      closed: [header("Shipping", "collapsed"), header("Returns", "collapsed"), count],
      open: [header("Shipping", "expanded"), text, action, header("Returns", "collapsed"), count])
    // The SDK tiles' hint, as the probe read it (p01, p06).
    let closedHint = "Collapsed double tap to expand"
    let openHint = "Expanded double tap to collapse"
    return [
      ("good-material", good.closed, good.open),
      ("good-cupertino", good.closed, good.open),
      ("good-custom", good.closed, good.open),
      // Bad examples: the defect must be audible.
      ("bad-no-state", ["Shipping Button Heading", "Returns Button Heading", count],
       ["Shipping Button Heading", text, action, "Returns Button Heading", count]),
      // The defect is on the web only.
      ("bad-heading-on-button", good.closed, good.open),
      ("bad-no-heading", ["Shipping collapsed Button", "Returns collapsed Button", count],
       ["Shipping expanded Button", text, action, "Returns collapsed Button", count]),
      ("bad-expansion-tile", ["Shipping \(closedHint)", "Returns \(closedHint)", count],
       ["Shipping \(openHint)", text, "Returns \(closedHint)", count]),
      // Open, the panel's text joins the header (FL-265), and the utterance
      // runs past the 64 characters XCUIVoiceOverService returns. It is cut
      // before its line breaks are made spaces here, so what is compared is
      // the cut reading as two runs heard it.
      ("bad-cupertino-expansion-tile", ["Shipping \(closedHint)", "Returns \(closedHint)", count],
       ["Shipping \(text) Expanded double tap to collap", "Returns \(closedHint)", count]),
    ]
  }()

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      let closed = try C05Walk.walk(voiceOver)
      let closedContent = C05Walk.content(closed)
      print("C05VO \(example.slug) | \((closedContent ?? closed.stops).joined(separator: " / "))")
      XCTAssertNotNil(closedContent, "\(example.slug): the walk did not run from the heading to the end: \(closed)")
      XCTAssertEqual(closedContent, example.closed, example.slug)
      try doubleTapOpens(example.slug, voiceOver)
      let opened = try C05Walk.walk(voiceOver)
      let openContent = C05Walk.content(opened)
      print("C05VO \(example.slug)-open | \((openContent ?? opened.stops).joined(separator: " / "))")
      XCTAssertNotNil(openContent, "\(example.slug) open: the walk did not run from the heading to the end: \(opened)")
      XCTAssertEqual(openContent, example.open, "\(example.slug) open")
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  /// C05Walk's end and content need no device. A stop after the expected
  /// ones must make the comparison fail, and a walk that does not reach the
  /// end, or never passes the heading, gives no content.
  func testWalkToTheEndSeesAnExtraStop() {
    func run(_ utterances: [String]) -> C05Walk.Result {
      var rest = utterances[...]
      return C05Walk.collect { rest.isEmpty ? "(nothing left)" : rest.removeFirst() }
    }
    let header = "Shipping Heading Button"
    let count = "Presses: 0"
    let normal = run(["Back Button", "Example Heading", header, count, count, count])
    XCTAssertTrue(normal.reachedEnd)
    XCTAssertEqual(C05Walk.content(normal), [header, count])
    let extra = run(["Back Button", "Example Heading", header, count, "Extra", "Extra", "Extra"])
    XCTAssertEqual(C05Walk.content(extra), [header, count, "Extra"])
    XCTAssertNotEqual(C05Walk.content(extra), [header, count])
    let endless = run((0..<40).map { "Item \($0)" })
    XCTAssertFalse(endless.reachedEnd)
    XCTAssertNil(C05Walk.content(endless))
    XCTAssertNil(C05Walk.content(run([header, count, count, count])))
    // An empty capture repeats one utterance: no heading, so no content.
    XCTAssertNil(C05Walk.content(run(["", "", ""])))
  }

  #if compiler(>=6.4)
  /// Puts VoiceOver's cursor on Shipping's header (with VoiceOver on, a tap
  /// only moves it), checks what is said there, then double taps it and
  /// checks the section opened. Logs what VoiceOver said after the double
  /// tap, a row of the transcript.
  @available(iOS 27.0, *)
  private func doubleTapOpens(_ slug: String, _ voiceOver: XCUIVoiceOverService) throws {
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    let e = slug.hasSuffix("expansion-tile") ? element(labelled: Self.shipping) : header(slug, "shipping")
    e.tap()
    usleep(1_500_000)
    let cursor = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
    XCTAssertTrue(cursor.hasPrefix(Self.shipping), "\(slug): the cursor is on Shipping: \(cursor)")
    XCTAssertFalse(shown(Self.shippingText), "\(slug): moving the cursor opened nothing")
    e.doubleTap()
    var heard: [String] = []
    for _ in 0..<6 {
      usleep(500_000)
      let s = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
      if heard.last != s { heard.append(s) }
    }
    let opened = shown(Self.shippingText)
    print("C05VO double-tap-\(slug) | cursor on \(cursor) / then heard \(heard.joined(separator: " | ")) / \(opened ? "Shipping opened" : "nothing opened")")
    XCTAssertTrue(opened, "\(slug): the double tap opens Shipping")
  }
  #endif
}

/// The C05 VoiceOver walk, as C03's: from the top of the screen to its end,
/// which is where moving on gives the last element again, twice. The count
/// is the example's last element, and it is compared with the rest. A move
/// with no speech is handled as VoiceOverWalk.forward does (afterNoSpeech).
/// Two neighbouring elements that VoiceOver reads alike would count as one;
/// no C05 example has two.
enum C05Walk {
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
