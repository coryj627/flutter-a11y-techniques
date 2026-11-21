// L3 (tree) and L4 (VoiceOver) for C03 Stand-alone link on iOS.
// Spec: docs/specs/C03-stand-alone-link.md.
//
// Every link goes to the technique's page, whose title is "Stand-alone
// link". "Followed once" is checked by one press of Back bringing the
// example back. XCUITest cannot read traits: an element that is a link and
// a button at once is shown by one type only, so roles are also checked
// through what VoiceOver says.
import XCTest

final class C03StandAloneLinkUITests: XCTestCase, TechniqueUITest {
  static let technique = "C03"
  let app = XCUIApplication()
  private static let name = "Read about stand-alone links"
  private static let destination = "Stand-alone link"
  /// The page that only bad-tap-handler opens (TapHandlerPage).
  private static let tapHandlerPage = "About stand-alone links"

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-material": "Material link",
    "good-cupertino": "Cupertino link",
    "good-custom": "Link built from Semantics",
    "good-image-link": "Picture link named on the link",
    "bad-vague-text": "Link that says \"Read more\"",
    "bad-tap-handler": "Underlined text with a tap handler",
    "bad-no-address": "Link with no address",
    "bad-image-no-name": "Picture link with no name",
    "bad-label-on-image": "Name put on the picture inside the link",
    "bad-cupertino-button": "Link round a Cupertino button",
    "bad-app-also-follows": "Link the app follows on the web too",
  ]

  private func title(_ slug: String) -> XCUIElement { element(labelled: Self.titles[slug]!) }

  /// Opens an example and waits for its title, then for the picture, which
  /// is decoded after the first frame.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: title(slug), settle: 500_000, file: file, line: line)
  }

  private let good: [(slug: String, id: String)] = [
    ("good-material", "c03-good-material-link"),
    ("good-cupertino", "c03-good-cupertino-link"),
    ("good-custom", "c03-good-custom-link"),
    ("good-image-link", "c03-good-image-link-link"),
  ]

  /// Waits up to 5 seconds for the technique's page, then presses Back once
  /// and waits for the example: the link opened one page, not two.
  private func expectFollowedOnce(_ slug: String, _ how: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(element(labelled: Self.destination).waitForExistence(timeout: 5),
                  "\(slug): \(how) opens the technique's page", file: file, line: line)
    XCTAssertFalse(title(slug).exists, "\(slug): the example is gone after \(how)", file: file, line: line)
    app.buttons["Back"].firstMatch.tap()
    XCTAssertTrue(title(slug).waitForExistence(timeout: 5),
                  "\(slug): one Back after \(how) brings the example back", file: file, line: line)
  }

  func testGoodLinksAreNamedLinks() {
    for example in good {
      open(example.slug)
      let e = element(example.id)
      XCTAssertEqual(e.elementType, .link, example.id)
      XCTAssertEqual(e.label, Self.name, example.id)
      XCTAssertTrue(e.isEnabled, example.id)
      XCTAssertTrue(app.links[Self.name].exists, "role and name query for \(example.id)")
      XCTAssertEqual(app.links.count, 1, "\(example.slug): the only link on the screen")
      XCTAssertEqual(app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }.count, 0,
                     "\(example.slug): no button but Back")
      XCTAssertEqual(app.images.count, 0, "\(example.slug): no image element")
    }
  }

  func testGoodLinksAreFollowedOnceByATap() {
    for example in good {
      open(example.slug)
      element(example.id).tap()
      expectFollowedOnce(example.slug, "a tap")
    }
  }

  /// XCUITest cannot see Flutter's focus (I01), so focus is shown by what
  /// the keys do: the first Tab goes to Back and the second to the link,
  /// the only other control on the screen; Enter (typed as "\n") then
  /// follows it. Had focus been on Back, Enter would have left the
  /// technique's page off the screen.
  func testGoodLinksAreReachedByTabAndFollowedByEnter() {
    for example in good {
      open(example.slug)
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(700_000)
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(700_000)
      app.typeKey("\n", modifierFlags: [])
      expectFollowedOnce(example.slug, "Tab, Tab, Enter")
    }
  }

  // Each bad example is asserted to have its named defect.

  func testBadVagueTextIsNamedReadMore() {
    open("bad-vague-text")
    let e = element("c03-bad-vague-text-link")
    XCTAssertEqual(e.elementType, .link)
    XCTAssertEqual(e.label, "Read more")
  }

  func testBadTapHandlerIsTextAndNotALink() {
    open("bad-tap-handler")
    let e = element("c03-bad-tap-handler-link")
    XCTAssertEqual(e.elementType, .staticText)
    XCTAssertEqual(e.label, Self.name)
    XCTAssertEqual(app.links.count, 0)
    // It still works by touch, which is what hides the defect: a tap opens
    // the page that nothing else in the app opens.
    e.tap()
    XCTAssertTrue(element(labelled: Self.tapHandlerPage).waitForExistence(timeout: 5),
                  "a tap opens the tap handler's page")
  }

  /// No key opens the tap handler's page. XCUITest cannot see Flutter's
  /// focus (I01); a probe showed where the keys go on this screen
  /// (docs/evidence/probes/c03/ios_keys.txt): the first Tab goes to Back,
  /// the only control, and a second Tab goes to Back again, as the text
  /// takes no focus. So one Tab, then Enter or Space, sent once: the example
  /// leaves the screen, which shows the key arrived and acted on Back, and
  /// the tap handler's page does not open.
  func testBadTapHandlerPageIsOpenedByNoKey() {
    for (key, name) in [("\n", "Enter"), (XCUIKeyboardKey.space.rawValue, "Space")] {
      open("bad-tap-handler")
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(700_000)
      app.typeKey(key, modifierFlags: [])
      let left = NSPredicate(format: "exists == false")
      let gone = XCTNSPredicateExpectation(predicate: left, object: title("bad-tap-handler"))
      XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 5), .completed,
                     "\(name): the key acted on Back, and the example left the screen")
      XCTAssertFalse(element(labelled: Self.tapHandlerPage).exists, "\(name): the tap handler's page did not open")
    }
  }

  func testBadNoAddressIsStillALinkOnIOS() {
    // The defect is on Android and the web. iOS reads the link flag alone.
    open("bad-no-address")
    let e = element("c03-bad-no-address-link")
    XCTAssertEqual(e.elementType, .link)
    XCTAssertEqual(e.label, Self.name)
  }

  func testBadImageNoNameIsAnImageWithNoName() {
    // The picture's image flag is merged into the link, and XCUITest shows
    // the element as an image; whether VoiceOver hears the link trait is in
    // testVoiceOverSpeech.
    open("bad-image-no-name")
    let e = element("c03-bad-image-no-name-link")
    XCTAssertEqual(e.elementType, .image)
    XCTAssertEqual(e.label, "")
    XCTAssertEqual(app.links.count, 0)
  }

  func testBadLabelOnImageLeavesTheLinkUnnamed() {
    open("bad-label-on-image")
    XCTAssertEqual(app.links.count, 1)
    XCTAssertEqual(app.links.firstMatch.label, "")
    XCTAssertFalse(app.links[Self.name].exists)
    // The name is on a second element, which is an image.
    XCTAssertEqual(app.images.count, 1)
    XCTAssertTrue(app.images[Self.name].exists)
  }

  func testBadCupertinoButtonIsAButtonInTheTree() {
    // XCUITest shows one type: button. That it is a link as well is heard
    // in testVoiceOverSpeech ("Button Link").
    open("bad-cupertino-button")
    let e = element("c03-bad-cupertino-button-link")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, Self.name)
    XCTAssertEqual(app.links.count, 0)
  }

  func testBadAppAlsoFollowsIsFollowedOnceOffTheWeb() {
    // The defect is on the web only (web_tests/c03_stand_alone_link.spec.js).
    open("bad-app-also-follows")
    let e = element("c03-bad-app-also-follows-link")
    XCTAssertEqual(e.elementType, .link)
    e.tap()
    expectFollowedOnce("bad-app-also-follows", "a tap")
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so a stop after the
  // expected link fails the test too.
  private let speech: [(slug: String, content: [String])] = [
    ("good-material", ["Read about stand-alone links Link"]),
    ("good-cupertino", ["Read about stand-alone links Link"]),
    ("good-custom", ["Read about stand-alone links Link"]),
    ("good-image-link", ["Read about stand-alone links Link"]),
    // Bad examples: the defect must be audible.
    ("bad-vague-text", ["Read more Link"]),
    ("bad-tap-handler", ["Read about stand-alone links"]),
    // iOS reads the link flag without an address: not a defect here.
    ("bad-no-address", ["Read about stand-alone links Link"]),
    ("bad-image-no-name", ["Link Image"]),
    ("bad-label-on-image", ["Link", "Read about stand-alone links Image"]),
    ("bad-cupertino-button", ["Read about stand-alone links Button Link"]),
    ("bad-app-also-follows", ["Read about stand-alone links Link"]),
  ]

  func testVoiceOverSpeech() throws {
    // XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
    // older Xcode the symbol does not exist, so an availability check alone
    // would not compile; the body is compiled only where the SDK has it.
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("C03VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    try doubleTapFollowsTheGoodLinks(voiceOver)
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  /// C03Walk's end and content need no device. The regression case: an
  /// element after the expected link must make the comparison fail.
  func testWalkToTheEndSeesAnExtraStop() {
    func run(_ utterances: [String]) -> C03Walk.Result {
      var rest = utterances[...]
      return C03Walk.collect { rest.isEmpty ? "(nothing left)" : rest.removeFirst() }
    }
    let link = "Read about stand-alone links Link"
    let normal = run(["Back Button", "Example Heading", link, link, link])
    XCTAssertTrue(normal.reachedEnd)
    XCTAssertEqual(C03Walk.content(normal), [link])
    // One more element after the link: seen, and the list no longer matches.
    let extra = run(["Back Button", "Example Heading", link, "Extra", "Extra", "Extra"])
    XCTAssertTrue(extra.reachedEnd)
    XCTAssertEqual(C03Walk.content(extra), [link, "Extra"])
    XCTAssertNotEqual(C03Walk.content(extra), [link])
    // No end within the moves allowed: no content, so the test fails.
    let endless = run((0..<40).map { "Item \($0)" })
    XCTAssertFalse(endless.reachedEnd)
    XCTAssertNil(C03Walk.content(endless))
    // No heading: no content.
    XCTAssertNil(C03Walk.content(run([link, link, link])))
  }

  #if compiler(>=6.4)
  /// VoiceOver's double tap follows each good link once: the cursor is put
  /// on the link (with VoiceOver on, a tap only moves it), what VoiceOver
  /// then says is checked to be the link, and a double tap follows it. One
  /// Back, with VoiceOver off, brings the example back. Each line printed is
  /// a row of the transcript.
  @available(iOS 27.0, *)
  private func doubleTapFollowsTheGoodLinks(_ voiceOver: XCUIVoiceOverService) throws {
    for example in good {
      open(example.slug)
      try voiceOver.enable()
      var on = true
      defer { if on { try? voiceOver.disable() } }
      let link = element(example.id)
      link.tap()
      usleep(1_500_000)
      let cursor = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
      XCTAssertEqual(cursor, "Read about stand-alone links Link", "\(example.slug): the cursor is on the link")
      XCTAssertTrue(title(example.slug).exists, "\(example.slug): moving the cursor followed nothing")
      link.doubleTap()
      let followed = element(labelled: Self.destination).waitForExistence(timeout: 5)
      print("C03VO double-tap-\(example.slug) | cursor on \(cursor) / \(followed ? "the technique's page opened" : "nothing opened")")
      XCTAssertTrue(followed, "\(example.slug): the double tap opens the technique's page")
      try voiceOver.disable()
      on = false
      app.buttons["Back"].firstMatch.tap()
      XCTAssertTrue(title(example.slug).waitForExistence(timeout: 5),
                    "\(example.slug): one Back brings the example back")
    }
  }
  #endif
}

/// The C03 VoiceOver walk: from the top of the screen to its end, which is
/// where moving on gives the last element again, twice. A move with no
/// speech is handled as VoiceOverWalk.forward does (afterNoSpeech). Two
/// neighbouring elements that VoiceOver reads alike would count as one; no
/// C03 example has two.
enum C03Walk {
  struct Result: Equatable {
    var stops: [String]
    var reachedEnd: Bool
  }

  /// Reads utterances from `next` until the same one has come three times
  /// in a row (the last element, then two moves that found nothing after
  /// it), at most `max` reads.
  static func collect(max: Int = 24, _ next: () throws -> String) rethrows -> Result {
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
    let result = try collect {
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
    return result
  }
  #endif
}
