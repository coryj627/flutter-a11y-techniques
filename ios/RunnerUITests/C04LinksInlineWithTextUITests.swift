// L3 (tree) and L4 (VoiceOver) for C04 Links inline with text on iOS.
// Spec: docs/specs/C04-links-inline-with-text.md.
//
// Each sentence has two links, to C04's page ("Links inline with text") and
// to C03's ("Stand-alone link"). "Followed once" is checked by one press of
// Back bringing the example back. XCUITest cannot read traits, and it gives
// no order for elements, so the order of a sentence is checked through what
// VoiceOver says, which is the order it moves in. The VoiceOver walk is C03's
// (C03Walk, in C03StandAloneLinkUITests.swift).
//
// The colour and underline of a link are drawn, not exposed, so this layer
// cannot see bad-colour-only's defect; the widget tests assert it.
import XCTest

final class C04LinksInlineWithTextUITests: XCTestCase, TechniqueUITest {
  static let technique = "C04"
  let app = XCUIApplication()

  private struct Link {
    let name: String
    let page: String
  }

  private static let links = [
    Link(name: "links in text", page: "Links inline with text"),
    Link(name: "stand-alone links", page: "Stand-alone link"),
  ]
  /// The page that only bad-text-span opens (TextSpanPage).
  private static let textSpanPage = "About links in text"

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-material": "Material links in a sentence",
    "good-cupertino": "Cupertino links in a sentence",
    "good-custom": "Widgets-layer links in a sentence",
    "bad-text-span": "Link in a text span",
    "bad-out-of-order": "Links read after their sentence",
    "bad-colour-only": "Links shown by colour alone",
    "bad-merged": "Sentence and links as one element",
  ]

  private let good = ["good-material", "good-cupertino", "good-custom"]

  private func title(_ slug: String) -> XCUIElement { element(labelled: Self.titles[slug]!) }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: title(slug), settle: 300_000, file: file, line: line)
  }

  private func linkId(_ slug: String, _ n: Int) -> String { "c04-\(slug)-link-\(n)" }

  /// Waits up to 5 seconds for [link]'s page, then presses Back once and
  /// waits for the example: the link opened one page, not two.
  private func expectFollowedOnce(_ slug: String, _ link: Link, _ how: String,
                                  file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(element(labelled: link.page).waitForExistence(timeout: 5),
                  "\(slug): \(how) opens \(link.page)", file: file, line: line)
    XCTAssertFalse(title(slug).exists, "\(slug): the example is gone after \(how)", file: file, line: line)
    app.buttons["Back"].firstMatch.tap()
    XCTAssertTrue(title(slug).waitForExistence(timeout: 5),
                  "\(slug): one Back after \(how) brings the example back", file: file, line: line)
  }

  func testGoodLinksAreNamedLinks() {
    for slug in good {
      open(slug)
      for (i, link) in Self.links.enumerated() {
        let e = element(linkId(slug, i + 1))
        XCTAssertEqual(e.elementType, .link, "\(slug) link \(i + 1)")
        XCTAssertEqual(e.label, link.name, "\(slug) link \(i + 1)")
        XCTAssertTrue(app.links[link.name].exists, "\(slug): role and name query for \(link.name)")
      }
      XCTAssertEqual(app.links.count, 2, "\(slug): the two links, and no other")
      XCTAssertEqual(app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }.count, 0,
                     "\(slug): no button but Back")
      // The words round the links are text of their own, with the spaces
      // round them in their labels ("Read about ", " and ", " first.").
      let texts = app.staticTexts.allElementsBoundByIndex.map {
        $0.label.trimmingCharacters(in: .whitespaces)
      }
      for words in ["Read about", "and", "first."] {
        XCTAssertEqual(texts.filter { $0 == words }.count, 1, "\(slug): the words \"\(words)\" in \(texts)")
      }
    }
  }

  func testGoodLinksAreFollowedOnceByATap() {
    for slug in good {
      for (i, link) in Self.links.enumerated() {
        open(slug)
        element(linkId(slug, i + 1)).tap()
        expectFollowedOnce(slug, link, "a tap on link \(i + 1)")
      }
    }
  }

  /// XCUITest cannot see Flutter's focus (I01), so focus is shown by what
  /// the keys do: the first Tab goes to Back, the second to the first link,
  /// the third to the second link; Enter (typed as "\n") then follows the
  /// link it is on. Each key is sent once.
  func testGoodLinksAreReachedByTabInOrderAndFollowedByEnter() {
    for slug in good {
      for (i, link) in Self.links.enumerated() {
        open(slug)
        for _ in 0..<(i + 2) {
          app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
          usleep(700_000)
        }
        app.typeKey("\n", modifierFlags: [])
        expectFollowedOnce(slug, link, "\(i + 2) Tabs and Enter")
      }
    }
  }

  // Each bad example is asserted to have its named defect.

  func testBadTextSpanIsALinkThatWorksByTouch() {
    open("bad-text-span")
    let e = element("c04-bad-text-span-link-1")
    XCTAssertEqual(e.elementType, .link)
    XCTAssertEqual(e.label, Self.links[0].name)
    // It works by touch, which is what hides the defect: a tap opens the
    // page that nothing else in the app opens.
    e.tap()
    XCTAssertTrue(element(labelled: Self.textSpanPage).waitForExistence(timeout: 5),
                  "a tap opens the text span's page")
  }

  /// No key opens the text span's page. XCUITest cannot see Flutter's
  /// focus; on this screen Back is the only control that takes it (the
  /// widget tests, Android, the web; in the probe one to three Tabs and
  /// Enter never ran a text span link's handler,
  /// docs/evidence/probes/c04/ios.txt). So one Tab, then Enter or Space,
  /// each from a fresh launch and each key sent once: the example leaves
  /// the screen, which shows the key arrived and acted on Back, and the text
  /// span's page does not open.
  func testBadTextSpanPageIsOpenedByNoKey() {
    for (key, name) in [("\n", "Enter"), (XCUIKeyboardKey.space.rawValue, "Space")] {
      open("bad-text-span")
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(700_000)
      app.typeKey(key, modifierFlags: [])
      let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                           object: title("bad-text-span"))
      XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 5), .completed,
                     "\(name): the key acted on Back, and the example left the screen")
      XCTAssertFalse(element(labelled: Self.textSpanPage).exists,
                     "\(name): the text span's page did not open")
    }
  }

  func testBadMergedIsOneLink() {
    open("bad-merged")
    let e = element("c04-bad-merged-sentence")
    XCTAssertEqual(e.elementType, .link)
    XCTAssertTrue(e.label.hasPrefix("Read about"), e.label)
    XCTAssertTrue(e.label.contains(Self.links[1].name), e.label)
    XCTAssertEqual(app.links.count, 1)
    XCTAssertFalse(app.links[Self.links[1].name].exists)
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so every stop is judged
  // and a stop out of place fails the test.
  private static let inOrder = ["Read about", "links in text Link", "and", "stand-alone links Link", "first."]
  private let speech: [(slug: String, content: [String])] = [
    ("good-material", inOrder),
    ("good-cupertino", inOrder),
    ("good-custom", inOrder),
    // Bad examples: the defect must be audible where iOS shows it. The text
    // span is a link in its place on iOS; its defect is the keyboard.
    ("bad-text-span", ["Read about", "links in text Link", "first."]),
    // The sentence without its links, then the links (FL-413).
    ("bad-out-of-order", ["Read about and first.", "links in text Link", "stand-alone links Link"]),
    // The defect is in what is drawn.
    ("bad-colour-only", inOrder),
    // One link, the whole sentence.
    ("bad-merged", ["Read about links in text and stand-alone links first. Link"]),
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("C04VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    try doubleTapFollowsTheGoodLinks(voiceOver)
    try touchOnALinkFindsTheLastWords(voiceOver)
    try doubleTapOnTheMergedSentence(voiceOver)
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  #if compiler(>=6.4)
  /// Moves VoiceOver's cursor forward from where it is until it says
  /// `want`, at most 14 moves, and returns what it last said.
  @available(iOS 27.0, *)
  private func moveTo(_ want: String, _ voiceOver: XCUIVoiceOverService) -> String {
    var said = ""
    for _ in 0..<14 {
      said = VoiceOverWalk.normalized((try? voiceOver.moveForward().utterance) ?? "")
      if said == want { break }
    }
    return said
  }

  /// VoiceOver's double tap follows each good link once: the cursor is
  /// moved forward to the link, what VoiceOver then says is checked to be
  /// the link, and a double tap on the link follows it. One Back, with
  /// VoiceOver off, brings the example back. The cursor is moved by moving
  /// forward, not by a tap on the link, because a tap there puts it on the
  /// last words (FL-246, `touchOnALinkFindsTheLastWords`). Each line
  /// printed is a row of the transcript.
  @available(iOS 27.0, *)
  private func doubleTapFollowsTheGoodLinks(_ voiceOver: XCUIVoiceOverService) throws {
    for slug in good {
      for (i, link) in Self.links.enumerated() {
        open(slug)
        try voiceOver.enable()
        var on = true
        defer { if on { try? voiceOver.disable() } }
        _ = moveTo("\(link.name) Link", voiceOver)
        let cursor = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
        XCTAssertEqual(cursor, "\(link.name) Link", "\(slug): the cursor is on link \(i + 1)")
        XCTAssertTrue(title(slug).exists, "\(slug): moving the cursor followed nothing")
        element(linkId(slug, i + 1)).doubleTap()
        let followed = element(labelled: link.page).waitForExistence(timeout: 5)
        print("C04VO double-tap-\(slug)-link-\(i + 1) | cursor on \(cursor) / \(followed ? "\(link.page) opened" : "nothing opened")")
        XCTAssertTrue(followed, "\(slug): the double tap opens \(link.page)")
        try voiceOver.disable()
        on = false
        app.buttons["Back"].firstMatch.tap()
        XCTAssertTrue(title(slug).waitForExistence(timeout: 5), "\(slug): one Back brings the example back")
      }
    }
  }

  /// FL-246: with VoiceOver on, a tap at the centre of either link of
  /// good-material puts the cursor on the sentence's last words, " first.",
  /// whose node covers both of the sentence's lines on this screen
  /// (docs/evidence/probes/c04/ios_round2.txt). Written to fail when the
  /// cursor lands on the link. The positive control in the same launch: one
  /// move back from there lands on the second link, so the cursor was read.
  @available(iOS 27.0, *)
  private func touchOnALinkFindsTheLastWords(_ voiceOver: XCUIVoiceOverService) throws {
    for i in 0..<Self.links.count {
      open("good-material")
      try voiceOver.enable()
      defer { try? voiceOver.disable() }
      let e = element(linkId("good-material", i + 1))
      e.tap()
      usleep(1_500_000)
      let cursor = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
      let back = VoiceOverWalk.normalized((try? voiceOver.moveBackward().utterance) ?? "")
      print("C04VO touch-good-material-link-\(i + 1) | cursor on \(cursor) / one move back: \(back)")
      XCTAssertEqual(cursor, "first.", "a tap at link \(i + 1)'s centre, frame \(e.frame)")
      XCTAssertEqual(back, "stand-alone links Link", "one move back from the last words")
      try voiceOver.disable()
    }
  }

  /// bad-merged: the cursor is moved forward to the one element and a
  /// double tap is made on it. What opened is printed for the transcript
  /// and not asserted: in the round 2 probe it opened no page, where the
  /// widget tests' tap action and Android's click action follow the first
  /// link, and why was not found. A claim that it does nothing would need a
  /// positive control on the same element, which has no other action.
  @available(iOS 27.0, *)
  private func doubleTapOnTheMergedSentence(_ voiceOver: XCUIVoiceOverService) throws {
    open("bad-merged")
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    let whole = "Read about links in text and stand-alone links first. Link"
    _ = moveTo(whole, voiceOver)
    let cursor = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
    XCTAssertEqual(cursor, whole, "bad-merged: the cursor is on the sentence")
    element("c04-bad-merged-sentence").doubleTap()
    sleep(3)
    let opened = Self.links.map { $0.page }.filter { element(labelled: $0).exists }
    let what = opened.isEmpty ? "no page opened" : opened.joined(separator: ", ") + " opened"
    print("C04VO double-tap-bad-merged | cursor on \(cursor) / \(what) (recorded, not asserted)")
  }
  #endif
}
