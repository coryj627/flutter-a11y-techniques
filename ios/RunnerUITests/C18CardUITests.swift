// L3 (tree) and L4 (VoiceOver) for C18 Card on iOS.
// Spec: docs/specs/C18-card.md.
//
// A card's parts are found by their labels and the controls by their test
// identifiers. XCUITest cannot read traits, so a heading is told from text
// only by what VoiceOver says ("Heading"), and the walk checks it.
import XCTest

final class C18CardUITests: XCTestCase, TechniqueUITest {
  static let technique = "C18"
  let app = XCUIApplication()
  private static let trail = "Ridge trail"
  private static let text = "A 6 km climb with a view."
  private static let picture = "Sunrise over the valley"
  private static let card = "\(trail)\n\(text)"
  private static let destination = "Card"

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-material": "Material card with separate parts",
    "good-tappable": "Material card that is one control",
    "good-cupertino": "Card in Cupertino style",
    "bad-default-container": "Card left as one container",
    "bad-heading-button": "Tappable card with a heading",
    "bad-ink-well": "Tappable card with an InkWell",
    "bad-read-more": "Card with a \"Read more\" link",
  ]

  private func title(_ slug: String) -> XCUIElement { element(labelled: Self.titles[slug]!) }

  /// Opens an example and waits for its title, then for the picture, which
  /// is decoded after the first frame.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: title(slug), settle: 500_000, file: file, line: line)
  }

  /// The number a count shows: 2 for "Saves: 2".
  private func count(_ id: String) -> Int {
    Int(element(id).label.components(separatedBy: ": ").last ?? "") ?? -1
  }

  /// Waits up to 5 seconds for every count in `expected` to show its number.
  private func expectCounts(_ what: String, _ expected: [String: Int], file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while expected.contains(where: { count($0.key) != $0.value }) && Date() < deadline { usleep(100_000) }
    for (id, n) in expected {
      XCTAssertEqual(count(id), n, "\(what): \(id)", file: file, line: line)
    }
  }

  /// The controls of each example that has any, with the count each adds to.
  private let controls: [(slug: String, id: String, count: String, all: [String])] = [
    ("good-material", "c18-good-material-save", "c18-good-material-saves", ["c18-good-material-saves", "c18-good-material-shares"]),
    ("good-material", "c18-good-material-share", "c18-good-material-shares", ["c18-good-material-saves", "c18-good-material-shares"]),
    ("good-tappable", "c18-good-tappable-card", "c18-good-tappable-opens", ["c18-good-tappable-opens"]),
  ]

  /// Every element of the screen with a label, other than the app's own.
  private func labelled(_ type: XCUIElement.ElementType) -> [String] {
    app.descendants(matching: type).allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty }
  }

  func testGoodMaterialHasEachPartAsAnElementOfItsOwn() {
    open("good-material")
    XCTAssertTrue(element(labelled: Self.trail).exists, "the heading on its own")
    XCTAssertTrue(element(labelled: Self.text).exists, "the text on its own")
    XCTAssertEqual(app.images.matching(NSPredicate(format: "label == %@", Self.picture)).count, 1, "the picture")
    XCTAssertEqual(element("c18-good-material-save").elementType, .button)
    XCTAssertEqual(element("c18-good-material-save").label, "Save \(Self.trail)")
    XCTAssertEqual(element("c18-good-material-share").elementType, .button)
    XCTAssertEqual(element("c18-good-material-share").label, "Share \(Self.trail)")
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }.sorted(), ["Save \(Self.trail)", "Share \(Self.trail)"])
    XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", Self.text)).count, 1,
                   "the text is in one element, not joined to the heading")
  }

  func testGoodTappableIsOneButtonNamedByItsText() {
    open("good-tappable")
    let card = element("c18-good-tappable-card")
    XCTAssertEqual(card.elementType, .button)
    XCTAssertEqual(card.label, Self.card)
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, [Self.card])
    XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", Self.text)).count, 1)
  }

  func testGoodCupertinoHasNoControl() {
    open("good-cupertino")
    XCTAssertTrue(element(labelled: Self.trail).exists)
    XCTAssertTrue(element(labelled: Self.text).exists)
    XCTAssertEqual(app.images.matching(NSPredicate(format: "label == %@", Self.picture)).count, 1)
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, [])
  }

  func testEachControlIsActivatedAloneByATap() {
    for c in controls {
      let zero = Dictionary(uniqueKeysWithValues: c.all.map { ($0, 0) })
      var one = zero
      one[c.count] = 1
      open(c.slug)
      expectCounts("\(c.slug) before", zero)
      element(c.id).tap()
      expectCounts("\(c.slug): a tap on \(c.id)", one)
    }
  }

  /// XCUITest cannot see Flutter's keyboard focus. The probe found the first
  /// Tab on Back and each later Tab on the next control, in order
  /// (docs/evidence/probes/c18/ios.txt): so `tabs` Tabs reach the control,
  /// and which count changed tells which control the key reached. Each key
  /// is sent once, from a fresh launch; no modifier is used.
  private let keyStops: [(slug: String, tabs: Int, count: String, all: [String])] = [
    ("good-material", 2, "c18-good-material-saves", ["c18-good-material-saves", "c18-good-material-shares"]),
    ("good-material", 3, "c18-good-material-shares", ["c18-good-material-saves", "c18-good-material-shares"]),
    ("good-tappable", 2, "c18-good-tappable-opens", ["c18-good-tappable-opens"]),
  ]

  func testEachControlIsActivatedAloneByTabThenEnterOrSpace() {
    for k in keyStops {
      for (key, name) in [("\n", "Enter"), (" ", "Space")] {
        let zero = Dictionary(uniqueKeysWithValues: k.all.map { ($0, 0) })
        var one = zero
        one[k.count] = 1
        open(k.slug)
        for _ in 0..<k.tabs {
          app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
          usleep(700_000)
        }
        app.typeKey(key, modifierFlags: [])
        expectCounts("\(k.slug): \(k.tabs) Tabs then \(name)", one)
      }
    }
  }

  func testBadDefaultContainerJoinsTheHeadingAndTheText() {
    open("bad-default-container")
    XCTAssertFalse(element(labelled: Self.trail).exists, "no element is the heading alone")
    XCTAssertFalse(element(labelled: Self.text).exists, "no element is the text alone")
    XCTAssertTrue(element(labelled: Self.card).exists, "one element has both")
    // Positive control: the button inside still works.
    element("c18-bad-default-container-save").tap()
    expectCounts("bad-default-container", ["c18-bad-default-container-saves": 1])
  }

  func testBadHeadingButtonIsAButtonOnIOS() {
    // The defect is on the web (FL-268); on iOS the heading is heard as
    // well (the VoiceOver walk).
    open("bad-heading-button")
    let card = element("c18-bad-heading-button-card")
    XCTAssertEqual(card.elementType, .button)
    XCTAssertEqual(card.label, Self.card)
    card.tap()
    expectCounts("bad-heading-button", ["c18-bad-heading-button-opens": 1])
  }

  func testBadInkWellIsNotAButton() {
    open("bad-ink-well")
    let card = element("c18-bad-ink-well-card")
    XCTAssertNotEqual(card.elementType, .button, "FL-401: no button")
    XCTAssertEqual(card.label, Self.card)
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, [], "no button but Back")
    // Everything but the role works: a tap.
    card.tap()
    expectCounts("bad-ink-well", ["c18-bad-ink-well-opens": 1])
  }

  func testBadReadMoreIsALinkNamedReadMore() {
    open("bad-read-more")
    let link = element("c18-bad-read-more-link")
    XCTAssertEqual(link.elementType, .link)
    XCTAssertEqual(link.label, "Read more")
    XCTAssertFalse(link.label.contains(Self.trail))
    XCTAssertTrue(element(labelled: Self.trail).exists, "the heading is an element of its own")
    // Positive control: it is a working link.
    link.tap()
    XCTAssertTrue(element(labelled: Self.destination).waitForExistence(timeout: 5), "the technique's page opens")
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so a stop after the
  // expected ones fails the test too. Utterances are cut at 64 characters.
  private static let heading = "\(trail) Heading"
  private static let read = "\(trail) \(text)"
  private static let speech: [(slug: String, content: [String])] = [
    // Each part on its own, then the counts.
    ("good-material", [heading, text, "\(picture) Image", "Save \(trail) Button", "Share \(trail) Button",
                       "Saves: 0", "Shares: 0"]),
    // One button, named by the title and the text.
    ("good-tappable", ["\(read) Button", "Opens: 0"]),
    ("good-cupertino", [heading, text, "\(picture) Image"]),
    // Bad examples: the defect must be audible where iOS shows it. The
    // heading and the text are one heading.
    ("bad-default-container", ["\(read) Heading", "Save \(trail) Button", "Saves: 0"]),
    // iOS keeps both roles; the defect is the web's (FL-268). In the probe
    // VoiceOver read the button trait first (docs/evidence/probes/c18/ios.txt,
    // p06, cut at 64 characters).
    ("bad-heading-button", ["\(read) Button Heading", "Opens: 0"]),
    // No role at all (FL-401).
    ("bad-ink-well", [read, "Opens: 0"]),
    // The link says only "Read more".
    ("bad-read-more", [heading, text, "Read more Link"]),
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("C18VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
