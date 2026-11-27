// L3 (tree) and L4 (VoiceOver) for S10 Content group replacement on iOS.
// Spec: docs/specs/S10-content-group-replacement.md.
//
// Each replacement carries an identifier of its own, `Semantics(identifier:)`
// on the replacement node, and the add buttons theirs through `TestId`. The
// pieces of `bad-pieces` have none and are found by their labels. XCUITest
// cannot read traits or Flutter's keyboard focus.
import XCTest

final class S10ContentGroupReplacementUITests: XCTestCase, TechniqueUITest {
  static let technique = "S10"
  let app = XCUIApplication()
  private static let words = "Rating: 3.4 out of 5 stars, based on 856 reviews"
  private static let wordsAfter = "Rating: 3.4 out of 5 stars, based on 857 reviews"
  private static let pieces = "Rating:\n3.4 / 5\nReviews: 856"
  private static let pieceLabels = ["Rating:", "3.4 / 5", "Reviews: 856", "3.4", "(856)"]
  private static let add = "Add a 5-star review"

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-exclude-semantics": "Rating replaced with excludeSemantics",
    "good-hidden-pieces": "Rating merged, with every piece hidden",
    "good-stars": "Star rating replaced",
    "bad-pieces": "Star rating left as pieces",
    "bad-merged": "Rating merged, not replaced",
    "bad-not-excluded": "Label with the pieces left in",
    "bad-hides-control": "Replacement that hides a button",
    "bad-stale": "Replacement with a fixed label",
  ]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.titles[slug]!), settle: 300_000, file: file, line: line)
  }

  private func rating(_ slug: String) -> XCUIElement { element("s10-\(slug)-rating") }

  /// Every element of the screen with a label, of `type`.
  private func labelled(_ type: XCUIElement.ElementType) -> [String] {
    app.descendants(matching: type).allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty }
  }

  /// Waits up to 5 seconds for the replacement of `slug` to be labelled `label`.
  private func expectRating(_ slug: String, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while rating(slug).label != label && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(rating(slug).label, label, slug, file: file, line: line)
  }

  /// No element of the screen is labelled with a piece of the rating.
  private func expectNoPieces(_ what: String, file: StaticString = #filePath, line: UInt = #line) {
    for piece in Self.pieceLabels {
      XCTAssertEqual(elements(labelled: piece).count, 0, "\(what): an element \"\(piece)\"", file: file, line: line)
    }
  }

  func testEachGoodReplacementIsOneElementNamedByWhatTheRatingMeans() {
    for slug in ["good-exclude-semantics", "good-hidden-pieces", "good-stars"] {
      open(slug)
      let r = rating(slug)
      XCTAssertEqual(r.elementType, .staticText, slug)
      XCTAssertEqual(r.label, Self.words, slug)
      XCTAssertEqual(r.value as? String ?? "", "", "\(slug): no value")
      XCTAssertEqual(elements(labelled: Self.words).count, 1, "\(slug): one element says it")
      expectNoPieces(slug)
      let buttons = labelled(.button).filter { $0 != "Back" }
      XCTAssertEqual(buttons, slug == "good-exclude-semantics" ? [Self.add] : [], slug)
    }
  }

  func testTheReplacementFollowsTheValuesAfterATap() {
    open("good-exclude-semantics")
    expectRating("good-exclude-semantics", Self.words)
    element("s10-good-exclude-semantics-add").tap()
    expectRating("good-exclude-semantics", Self.wordsAfter)
    expectNoPieces("after the tap")
  }

  /// XCUITest cannot see Flutter's keyboard focus. The probe found the first
  /// Tab on Back and the second on the button after it
  /// (docs/evidence/probes/s10/ios.txt, p22). Each key is sent once, from a
  /// fresh launch; no modifier is used.
  func testTheReplacementFollowsTheValuesAfterTwoTabsAndEnter() {
    open("good-exclude-semantics")
    for _ in 0..<2 {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(900_000)
    }
    app.typeKey("\n", modifierFlags: [])
    expectRating("good-exclude-semantics", Self.wordsAfter)
  }

  func testBadPiecesIsTwoNumbersAndNothingForTheStars() {
    open("bad-pieces")
    XCTAssertTrue(element(labelled: "3.4").exists)
    XCTAssertTrue(element(labelled: "(856)").exists)
    for word in ["star", "Star", "out of", "review"] {
      let found = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", word))
        .allElementsBoundByIndex.map(\.label).filter { !$0.hasPrefix("Defect:") && $0 != Self.titles["bad-pieces"]! }
      XCTAssertEqual(found, [], "no element says \"\(word)\"")
    }
    XCTAssertEqual(app.images.count, 0, "no image")
  }

  func testBadMergedIsOneElementWithThePiecesAndTheValue68() {
    open("bad-merged")
    let r = rating("bad-merged")
    XCTAssertEqual(r.label, Self.pieces)
    XCTAssertEqual(r.value as? String, "68")
  }

  func testBadNotExcludedIsOneElementWithTheLabelThePiecesAndTheValue68() {
    open("bad-not-excluded")
    let r = rating("bad-not-excluded")
    XCTAssertEqual(r.label, "\(Self.words)\n\(Self.pieces)")
    XCTAssertEqual(r.value as? String, "68")
  }

  func testBadHidesControlHasNoElementForTheButtonThatTheKeyboardStillReaches() {
    open("bad-hides-control")
    XCTAssertEqual(rating("bad-hides-control").label, Self.words)
    XCTAssertEqual(elements(labelled: "Reviews").count, 0, "no element is the button")
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, [], "no button but Back")
    // Two Tabs and Return run it (the probe: the first Tab is on Back).
    for _ in 0..<2 {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(900_000)
    }
    app.typeKey("\n", modifierFlags: [])
    let opens = element("s10-bad-hides-control-opens")
    let deadline = Date().addingTimeInterval(5)
    while opens.label != "Reviews opened: 1" && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(opens.label, "Reviews opened: 1")
  }

  func testBadStaleKeepsSaying856AfterAReview() {
    open("bad-stale")
    XCTAssertEqual(rating("bad-stale").label, Self.words)
    element("s10-bad-stale-add").tap()
    // As long as good-exclude-semantics takes to follow, and the label must
    // not change.
    let deadline = Date().addingTimeInterval(2)
    while Date() < deadline {
      XCTAssertEqual(rating("bad-stale").label, Self.words)
      usleep(200_000)
    }
    XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS '857'")).count, 0)
    // Positive control: good-exclude-semantics follows the same tap.
    open("good-exclude-semantics")
    element("s10-good-exclude-semantics-add").tap()
    expectRating("good-exclude-semantics", Self.wordsAfter)
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so a stop after the
  // expected ones fails the test too. XCUIVoiceOverService gives back only
  // the first 64 characters of an utterance, so every expected utterance is
  // shorter (the test refuses a longer one), and a stop whose whole
  // utterance is longer is written as `Stop.cut`: its first 63 characters,
  // which the utterance must start with, and the utterance exactly 64
  // characters long, the service's cut. What follows the cut is not heard
  // by this test (the tree test reads the rest).
  enum Stop: Equatable {
    case whole(String)
    case cut(String)

    var expected: String {
      switch self {
      case .whole(let s), .cut(let s): return s
      }
    }

    func matches(_ utterance: String) -> Bool {
      switch self {
      case .whole(let s): return utterance == s
      case .cut(let s): return utterance.count == 64 && utterance.hasPrefix(s)
      }
    }
  }

  private static let addButton = Stop.whole("\(add) Button")
  private static let speech: [(slug: String, addFirst: Bool, content: [Stop])] = [
    ("good-exclude-semantics", false, [.whole(words), addButton]),
    // After a tap on the button, with VoiceOver off.
    ("good-exclude-semantics", true, [.whole(wordsAfter), addButton]),
    ("good-hidden-pieces", false, [.whole(words)]),
    ("good-stars", false, [.whole(words)]),
    // Bad examples: the defect must be audible where iOS shows it. The two
    // numbers, and nothing for the stars.
    ("bad-pieces", false, [.whole("3.4"), .whole("(856)")]),
    // The pieces, then the bar's value (FL-330); no role (FL-256).
    ("bad-merged", false, [.whole("Rating: 3.4 / 5 Reviews: 856 68")]),
    // The label, then the pieces again; cut at 64 characters before the 68
    // (docs/evidence/probes/s10/ios.txt, p06).
    ("bad-not-excluded", false, [.cut(String("\(words) Rating: 3.4 / 5".prefix(63)))]),
    ("bad-hides-control", false, [.whole(words), .whole("Reviews opened: 0")]),
    ("bad-stale", false, [.whole(words), addButton]),
    // After a tap on the button the row shows 857, and VoiceOver hears 856.
    ("bad-stale", true, [.whole(words), addButton]),
  ]

  func testExpectedUtterancesAreUnder64Characters() {
    for example in Self.speech {
      for stop in example.content {
        XCTAssertLessThan(stop.expected.count, 64, "\(example.slug): \"\(stop.expected)\"")
      }
    }
    // The cut row is the reading the probe measured, cut where the service
    // cuts it.
    XCTAssertEqual("\(Self.words) Rating: 3.4 / 5".count, 64)
    XCTAssertTrue(Stop.cut("abc").matches("abc" + String(repeating: "y", count: 61)))
    XCTAssertFalse(Stop.cut("abc").matches("abc"), "a short utterance is not the cut")
    XCTAssertFalse(Stop.cut("abc").matches("abd" + String(repeating: "y", count: 61)))
  }

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      for stop in example.content where stop.expected.count >= 64 {
        XCTFail("\(example.slug): an expected utterance of 64 characters or more: \"\(stop.expected)\"")
      }
      open(example.slug)
      if example.addFirst {
        // A tap with VoiceOver off; the walk then reads the screen.
        element("s10-\(example.slug)-add").tap()
        usleep(1_000_000)
      }
      let row = example.addFirst ? "\(example.slug)-after" : example.slug
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("S10VO \(row) | \((content ?? walk.stops).joined(separator: " / "))")
      guard let content else {
        XCTFail("\(row): the walk did not run from the heading to the end: \(walk)")
        continue
      }
      XCTAssertEqual(content.count, example.content.count, "\(row): \(content)")
      for (i, (said, stop)) in zip(content, example.content).enumerated() {
        XCTAssertTrue(stop.matches(said), "\(row), stop \(i + 1): \"\(said)\" where \(stop) was expected")
      }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
