// L3 (tree) and L4 (VoiceOver) for S12 Hiding content from AT on iOS.
// Spec: docs/specs/S12-hiding-content.md.
//
// Texts are found by their labels and the controls and counts by their
// test identifiers. XCUITest cannot see Flutter's keyboard focus: which
// count changed is what shows where a key went.
import XCTest

final class S12HidingContentUITests: XCTestCase, TechniqueUITest {
  static let technique = "S12"
  let app = XCUIApplication()
  private static let quote = "Walk the ridge before the sun is up."
  private static let source = "Trail guide"
  private static let quoteMark = "❝"
  private static let ornament = "✦ ✦ ✦"
  private static let inbox = "Inbox: 3 unread"
  private static let tracking = "Tracking number: 1Z 999"
  private static let show = "Show tracking"
  private static let copy = "Copy number"

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-decoration": "Ornaments hidden from AT",
    "good-badge": "Repeated count hidden from AT",
    "good-visibility": "Panel hidden from everyone",
    "bad-decoration-read": "Ornaments read aloud",
    "bad-hidden-control": "Button hidden with an ornament",
    "bad-opacity": "Panel hidden by opacity",
    "bad-maintain": "Panel hidden only from sight",
  ]

  private func title(_ slug: String) -> XCUIElement { element(labelled: Self.titles[slug]!) }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: title(slug), file: file, line: line)
  }

  /// Waits up to 5 seconds for the count `id` to say `expected`.
  private func expectCount(_ what: String, _ id: String, _ expected: String,
                           file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while element(id).label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(element(id).label, expected, what, file: file, line: line)
  }

  /// Every label on the screen, of any type, read from one snapshot.
  private func labels() -> [String] {
    app.descendants(matching: .any).allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty }
  }

  /// How many elements of any type have exactly `label`.
  private func count(labelled label: String) -> Int {
    elements(labelled: label).count
  }

  private func buttonsButBack() -> [String] {
    app.buttons.allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty && $0 != "Back" }
  }

  /// Sends Tab `tabs` times, then `key`, each once, with no modifier.
  private func tabs(_ tabs: Int, then key: String) {
    for _ in 0..<tabs {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(900_000)
    }
    app.typeKey(key, modifierFlags: [])
  }

  /// The switch's value: "0" off, "1" on.
  private func switchValue(_ slug: String) -> String {
    (element("s12-\(slug)-show").value as? String) ?? "(no value)"
  }

  func testGoodDecorationHasTheQuoteAndItsSourceAndNoOrnament() {
    open("good-decoration")
    XCTAssertEqual(count(labelled: Self.quote), 1)
    XCTAssertEqual(count(labelled: Self.source), 1)
    for label in labels() {
      XCTAssertFalse(label.contains(Self.quoteMark), label)
      XCTAssertFalse(label.contains("✦"), label)
    }
  }

  func testGoodBadgeHasTheWordsAloneAndNoElement3() {
    open("good-badge")
    XCTAssertEqual(labels().filter { $0.contains("3") }, [Self.inbox])
    XCTAssertEqual(app.images.count, 0, "the icon is no element")
  }

  func testGoodVisibilityHiddenHasNoPanelElementShownHasIt() {
    open("good-visibility")
    XCTAssertEqual(element("s12-good-visibility-show").elementType, .switch)
    XCTAssertEqual(switchValue("good-visibility"), "0")
    XCTAssertEqual(count(labelled: Self.tracking), 0, "hidden: no number")
    XCTAssertEqual(count(labelled: Self.copy), 0, "hidden: no Copy")
    XCTAssertEqual(buttonsButBack(), [], "hidden: no button but Back")
    // Positive control, in the same launch: shown, the panel is there.
    element("s12-good-visibility-show").tap()
    let deadline = Date().addingTimeInterval(5)
    while switchValue("good-visibility") != "1" && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count(labelled: Self.tracking), 1, "shown: the number")
    XCTAssertEqual(element("s12-good-visibility-copy").elementType, .button)
    XCTAssertEqual(element("s12-good-visibility-copy").label, Self.copy)
    element("s12-good-visibility-copy").tap()
    expectCount("good-visibility: a tap on Copy", "s12-good-visibility-count", "Copies: 1")
  }

  /// The probe found the first Tab on Back and each later Tab on the next
  /// control (docs/evidence/probes/s12/ios.txt), and, with the panel
  /// hidden in `Visibility(maintainState: true)`, the third Tab back on Back
  /// (p07: three Tabs and Return left the screen). Hidden, three Tabs and
  /// the key leave the screen: there is no stop between the switch and
  /// Back, so the keyboard does not reach Copy. Positive control, from a
  /// fresh launch, the same keys: shown first, three Tabs and the key copy.
  func testGoodVisibilityTheKeyboardReachesCopyOnlyOnceItIsShown() {
    for (key, name) in [("\n", "Return"), (" ", "Space")] {
      open("good-visibility")
      tabs(3, then: key)
      let deadline = Date().addingTimeInterval(5)
      while title("good-visibility").exists && Date() < deadline { usleep(100_000) }
      XCTAssertFalse(title("good-visibility").exists,
                     "hidden: three Tabs and \(name) landed on Back and left the screen")
      open("good-visibility")
      element("s12-good-visibility-show").tap()
      let shown = Date().addingTimeInterval(5)
      while switchValue("good-visibility") != "1" && Date() < shown { usleep(100_000) }
      tabs(3, then: key)
      expectCount("good-visibility shown: three Tabs then \(name)", "s12-good-visibility-count", "Copies: 1")
      XCTAssertTrue(title("good-visibility").exists, "shown: the screen is still open")
    }
  }

  func testBadDecorationReadHasEachOrnamentAsAnElement() {
    open("bad-decoration-read")
    for text in [Self.quoteMark, Self.quote, Self.source, Self.ornament] {
      XCTAssertEqual(count(labelled: text), 1, text)
    }
  }

  func testBadHiddenControlHasNoShareAndTheKeyboardRunsIt() {
    open("bad-hidden-control")
    XCTAssertEqual(count(labelled: "Share"), 0, "no element is Share")
    XCTAssertEqual(buttonsButBack(), [], "no button but Back")
    for (key, name) in [("\n", "Return"), (" ", "Space")] {
      open("bad-hidden-control")
      tabs(2, then: key)
      expectCount("bad-hidden-control: two Tabs then \(name)", "s12-bad-hidden-control-count", "Shares: 1")
      XCTAssertTrue(title("bad-hidden-control").exists, "the screen is still open")
    }
    // Positive control: one Tab and Return are on Back, and leave the screen.
    open("bad-hidden-control")
    tabs(1, then: "\n")
    let deadline = Date().addingTimeInterval(5)
    while title("bad-hidden-control").exists && Date() < deadline { usleep(100_000) }
    XCTAssertFalse(title("bad-hidden-control").exists, "one Tab and Return left the screen")
  }

  func testBadHiddenControlATapWhereShareIsDrawnShares() {
    open("bad-hidden-control")
    let quote = element(labelled: Self.quote).frame
    let count = element("s12-bad-hidden-control-count").frame
    let y = (quote.maxY + count.minY) / 2
    for fraction in [0.30, 0.40, 0.50] {
      let x = quote.minX + quote.width * fraction
      app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
      usleep(800_000)
      if element("s12-bad-hidden-control-count").label == "Shares: 1" { return }
    }
    XCTFail("no tap between the quote and the count shared")
  }

  func testBadOpacityHiddenHasNoPanelElementAndTheKeyboardAndATapCopy() {
    open("bad-opacity")
    XCTAssertEqual(count(labelled: Self.tracking), 0, "hidden: no number")
    XCTAssertEqual(count(labelled: Self.copy), 0, "hidden: no Copy")
    XCTAssertEqual(buttonsButBack(), [], "hidden: no button but Back")
    for (key, name) in [("\n", "Return"), (" ", "Space")] {
      open("bad-opacity")
      tabs(3, then: key)
      expectCount("bad-opacity hidden: three Tabs then \(name)", "s12-bad-opacity-count", "Copies: 1")
      XCTAssertEqual(switchValue("bad-opacity"), "0", "the switch is still off")
    }
    open("bad-opacity")
    let s = element("s12-bad-opacity-show").frame
    let c = element("s12-bad-opacity-count").frame
    app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: s.minX + 40, dy: c.minY - 20)).tap()
    expectCount("bad-opacity hidden: a tap where Copy is laid out", "s12-bad-opacity-count", "Copies: 1")
    XCTAssertEqual(switchValue("bad-opacity"), "0", "the switch is still off")
  }

  func testBadMaintainHiddenHasThePanelElementsAndTheKeyboardCopies() {
    open("bad-maintain")
    XCTAssertEqual(switchValue("bad-maintain"), "0")
    XCTAssertEqual(count(labelled: Self.tracking), 1, "hidden, and still there: the number")
    XCTAssertEqual(element("s12-bad-maintain-copy").elementType, .button)
    XCTAssertEqual(element("s12-bad-maintain-copy").label, Self.copy)
    open("bad-maintain")
    tabs(3, then: "\n")
    expectCount("bad-maintain hidden: three Tabs then Return", "s12-bad-maintain-count", "Copies: 1")
    XCTAssertEqual(switchValue("bad-maintain"), "0", "the switch is still off")
  }

  // L4. The whole walk, from the top of the screen to its end (C03Walk), is
  // judged against this example's own screen (S12Walk.judge): Back may come
  // first, then the screen's title as a heading, its description, a bad
  // example's defect, the "Example" heading once, and then exactly the
  // expected content. A walk that reads another screen's title cannot pass
  // for this one, even where the content is the same (good-visibility and
  // bad-opacity). Utterances are cut at 64 characters: every expected
  // content utterance is shorter, which the test checks; a defect line that
  // is longer is matched by its first 63 characters and an utterance 64
  // long.
  private static let speech: [(slug: String, content: [String])] = [
    ("good-decoration", [quote, source]),
    ("good-badge", [inbox]),
    ("good-visibility", ["\(show) Switch button off Double tap to toggle setting.", "Copies: 0"]),
    ("bad-decoration-read", [quoteMark, quote, source, ornament]),
    ("bad-hidden-control", [quote, "Shares: 0"]),
    ("bad-opacity", ["\(show) Switch button off Double tap to toggle setting.", "Copies: 0"]),
    ("bad-maintain", ["\(show) Switch button off Double tap to toggle setting.", tracking, "\(copy) Button", "Copies: 0"]),
  ]

  func testVoiceOverSpeech() throws {
    for example in Self.speech {
      for utterance in example.content {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \"\(utterance)\" is longer than the service returns")
      }
    }
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      // The whole walk is the transcript row: the screen's own stops keep
      // the walk's identity.
      print("S12VO \(example.slug) | \(walk.stops.joined(separator: " / "))\(walk.reachedEnd ? "" : " (not to the end)")")
      let verdict = S12Walk.judge(walk.stops, reachedEnd: walk.reachedEnd, slug: example.slug, content: example.content)
      XCTAssertNil(verdict, "\(example.slug): \(verdict ?? "")")
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  /// The judge on made-up walks; no VoiceOver. Each case is named.
  func testTheVoiceOverJudgeTiesAWalkToItsScreen() {
    let content = Dictionary(uniqueKeysWithValues: Self.speech.map { ($0.slug, $0.content) })
    func walk(_ slug: String) -> [String] { S12Walk.screenStops(slug) + ["Example Heading"] + content[slug]! }
    let cases: [(String, [String], Bool, String, Bool)] = [
      // (what, stops, reached the end, judged as, passes)
      ("good-visibility's own walk", walk("good-visibility"), true, "good-visibility", true),
      ("bad-opacity's own walk", walk("bad-opacity"), true, "bad-opacity", true),
      ("Back first, then the screen", ["Back Button"] + walk("bad-maintain"), true, "bad-maintain", true),
      ("a cut defect line, 64 long", walk("bad-hidden-control"), true, "bad-hidden-control", true),
      ("good-visibility's walk judged as bad-opacity", walk("good-visibility"), true, "bad-opacity", false),
      ("bad-opacity's walk judged as good-visibility", walk("bad-opacity"), true, "good-visibility", false),
      ("no title", Array(walk("good-visibility").dropFirst()), true, "good-visibility", false),
      ("no description", [walk("good-visibility")[0]] + Array(walk("good-visibility").dropFirst(2)), true,
       "good-visibility", false),
      ("an empty title", [""] + Array(walk("good-visibility").dropFirst()), true, "good-visibility", false),
      ("a title with no stop at all", [], true, "good-visibility", false),
      ("no defect on a bad screen", walk("bad-opacity").filter { !$0.hasPrefix("Defect") }, true, "bad-opacity", false),
      ("the Example heading twice", walk("good-badge") + ["Example Heading"], true, "good-badge", false),
      ("a stop before the title that is not Back", ["Probe"] + walk("good-badge"), true, "good-badge", false),
      ("the content changed", walk("good-badge").dropLast() + ["Inbox: 4 unread"], true, "good-badge", false),
      ("a stop after the content", walk("good-badge") + ["Extra"], true, "good-badge", false),
      ("the end not reached", walk("good-badge"), false, "good-badge", false),
      ("a defect line cut too short", walk("bad-hidden-control").map { $0.hasPrefix("Defect") ? String($0.prefix(40)) : $0 },
       true, "bad-hidden-control", false),
    ]
    for (what, stops, reachedEnd, slug, passes) in cases {
      let verdict = S12Walk.judge(stops, reachedEnd: reachedEnd, slug: slug, content: content[slug]!)
      XCTAssertEqual(verdict == nil, passes, "\(what): \(verdict ?? "passed")")
    }
  }
}

/// What S12's VoiceOver walk on iOS must read before its content: each
/// screen's title (a level 1 heading, read "<title> Heading"), the line that
/// says whether it is a good or a bad example, and a bad example's defect
/// (ExampleScreen in lib/app/screens.dart, with the titles and defects of
/// lib/techniques/s12_hiding_content/s12_hiding_content.dart). The service
/// returns the first 64 characters of an utterance, so the defect lines,
/// which are longer, are kept whole here and compared cut.
enum S12Walk {
  static let screens: [String: (title: String, kind: String, defect: String?)] = [
    "good-decoration": ("Ornaments hidden from AT", "Good example for Hiding content from AT. Widgets layer.", nil),
    "good-badge": ("Repeated count hidden from AT", "Good example for Hiding content from AT. Material.", nil),
    "good-visibility": ("Panel hidden from everyone", "Good example for Hiding content from AT. Material.", nil),
    "bad-decoration-read": ("Ornaments read aloud", "Bad example for Hiding content from AT. Widgets layer.",
                            "Defect: A screen reader stops on each ornament and reads it."),
    "bad-hidden-control": ("Button hidden with an ornament", "Bad example for Hiding content from AT. Material.",
                           "Defect: A screen reader cannot find the Share button; the keyboard still reaches it."),
    "bad-opacity": ("Panel hidden by opacity", "Bad example for Hiding content from AT. Material.",
                    "Defect: While the panel is hidden, the keyboard still reaches its button, which no screen reader can find."),
    "bad-maintain": ("Panel hidden only from sight", "Bad example for Hiding content from AT. Material.",
                     "Defect: While the panel is hidden, a screen reader still reads it and the keyboard still reaches its button."),
  ]

  /// The stops the screen of `slug` has before its "Example" heading, as
  /// the service returns them: each cut at 64 characters.
  static func screenStops(_ slug: String) -> [String] {
    let s = screens[slug]!
    return ["\(s.title) Heading", s.kind, s.defect].compactMap { $0 }.map { String($0.prefix(64)) }
  }

  /// Whether a stop is the expected line: equal, or, for a line of 64
  /// characters or more, an utterance exactly 64 long that starts with the
  /// line's first 63.
  static func reads(_ stop: String, _ line: String) -> Bool {
    if line.count < 64 { return stop == line }
    return stop.count == 64 && stop.hasPrefix(String(line.prefix(63)))
  }

  /// Nil when the walk is this screen's whole walk; otherwise what is wrong.
  static func judge(_ stops: [String], reachedEnd: Bool, slug: String, content: [String]) -> String? {
    guard let s = screens[slug] else { return "no screen \(slug)" }
    guard reachedEnd else { return "the walk did not reach the end of the screen" }
    let lines = ["\(s.title) Heading", s.kind, s.defect].compactMap { $0 }
    var rest = stops
    if rest.first == "Back Button" { rest.removeFirst() }
    guard rest.count == lines.count + 1 + content.count else {
      return "\(rest.count) stops after Back where \(lines.count + 1 + content.count) were expected: \(stops)"
    }
    for (i, line) in lines.enumerated() where !reads(rest[i], line) {
      return "stop \(i + 1) was \"\(rest[i])\" where \"\(line)\" was expected"
    }
    guard rest[lines.count] == "Example Heading" else {
      return "\"\(rest[lines.count])\" where the Example heading was expected"
    }
    let got = Array(rest[(lines.count + 1)...])
    return got == content ? nil : "the content was \(got) where \(content) was expected"
  }
}
