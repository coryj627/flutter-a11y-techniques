// L3 (tree) and L4 (VoiceOver) for S08 List semantics on iOS.
// Spec: docs/specs/S08-list-semantics.md.
//
// On iOS a Flutter list is a container of no particular kind, where a
// native list is a table or a collection view of cells (FL-310), so there
// is no list element to check. What is checked is that each item is an
// element of its own, in order, and what VoiceOver says. Items are found
// by their labels and the tiles of a list of tiles by their test
// identifiers.
import XCTest

final class S08ListSemanticsUITests: XCTestCase, TechniqueUITest {
  static let technique = "S08"
  let app = XCUIApplication()
  private static let groceries = ["Milk", "Eggs", "Bread"]
  private static let steps = ["1. Fork the repository", "2. Make the change", "3. Open a pull request"]

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-bulleted": "Bulleted list",
    "good-numbered": "Numbered list",
    "good-material": "List of Material list tiles",
    "good-cupertino": "Cupertino list section",
    "bad-one-text": "List in one text",
    "bad-no-list": "Lines with no list role",
    "bad-tile-in-item": "List tiles merged into their items",
    "bad-lazy-list": "Long list in a ListView",
  ]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.titles[slug]!), file: file, line: line)
  }

  /// Every element of the screen whose label is exactly `label`.
  private func count(labelled label: String) -> Int {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).count
  }

  /// The labels of every element of the screen with a label, in the
  /// tree's order (one snapshot, read depth first, as the probe read it),
  /// from the one after the "Example" heading to the end or to the
  /// "Chosen" line. Element queries listed the tiles out of that order in
  /// the first run, so one snapshot is read instead.
  private func exampleLabels() -> [String] {
    guard let root = try? app.snapshot() else { return ["(no snapshot)"] }
    var labels: [String] = []
    func walk(_ s: XCUIElementSnapshot) {
      if s.elementType != .window && s.elementType != .application && !s.label.isEmpty {
        labels.append(s.label)
      }
      for c in s.children { walk(c) }
    }
    walk(root)
    guard let start = labels.lastIndex(of: "Example") else { return ["(no Example heading)"] }
    let rest = labels[(start + 1)...]
    return Array(rest.prefix { !$0.hasPrefix("Chosen: ") })
  }

  private func chosen(_ slug: String) -> String { element("s08-\(slug)-chosen").label }

  private func expectChosen(_ slug: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
    expectChosen(slug, slug: slug, expected, file: file, line: line)
  }

  /// Waits up to 5 seconds for the Chosen line of `slug` to say `expected`.
  private func expectChosen(_ what: String, slug: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while chosen(slug) != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(chosen(slug), expected, what, file: file, line: line)
  }

  func testGoodBulletedHasEachItemAsAnElementOfItsOwn() {
    open("good-bulleted")
    XCTAssertEqual(exampleLabels(), Self.groceries)
    for g in Self.groceries { XCTAssertEqual(count(labelled: g), 1, g) }
  }

  func testGoodNumberedHasEachStepWithItsNumber() {
    open("good-numbered")
    XCTAssertEqual(exampleLabels(), Self.steps)
  }

  func testGoodMaterialHasEachTileAsAButton() {
    open("good-material")
    XCTAssertEqual(exampleLabels(), Self.groceries)
    for g in Self.groceries {
      let tile = element("s08-good-material-\(g.lowercased())")
      XCTAssertEqual(tile.elementType, .button, g)
      XCTAssertEqual(tile.label, g)
    }
  }

  func testGoodCupertinoHasTheHeaderAndEachItem() {
    open("good-cupertino")
    // The header is the list's own label, an element of its own on iOS.
    XCTAssertEqual(exampleLabels(), ["Groceries"] + Self.groceries)
    XCTAssertEqual(app.buttons.allElementsBoundByIndex.map(\.label).filter { $0 != "Back" }, [])
  }

  func testBadOneTextIsOneElement() {
    open("bad-one-text")
    XCTAssertEqual(exampleLabels(), [Self.groceries.joined(separator: "\n")])
    for g in Self.groceries { XCTAssertEqual(count(labelled: g), 0, "no element is \(g) alone") }
  }

  func testBadNoListHasEachLineAsAnElement() {
    // Flutter gives iOS no list (FL-310), so this reads as good-bulleted does: the
    // defect is on Android and the web.
    open("bad-no-list")
    XCTAssertEqual(exampleLabels(), Self.groceries)
  }

  func testBadTileInItemIsAButtonOnIOS() {
    // The defect is on the web (FL-262).
    open("bad-tile-in-item")
    XCTAssertEqual(exampleLabels(), Self.groceries)
    for g in Self.groceries {
      XCTAssertEqual(element("s08-bad-tile-in-item-\(g.lowercased())").elementType, .button, g)
    }
  }

  func testBadLazyListHoldsOnlyTheOrdersNearTheView() {
    // FL-011: the elements are the orders near the view, from order 1.
    open("bad-lazy-list")
    let labels = exampleLabels()
    XCTAssertEqual(labels.first, "Order 1")
    XCTAssertLessThan(labels.count, 30, "\(labels)")
    XCTAssertEqual(labels, (1...max(labels.count, 1)).map { "Order \($0)" })
  }

  func testEachTileOpensItsOwnItemByATap() {
    for slug in ["good-material", "bad-tile-in-item"] {
      for g in Self.groceries {
        open(slug)
        expectChosen(slug, "Chosen: none")
        element("s08-\(slug)-\(g.lowercased())").tap()
        expectChosen(slug, "Chosen: \(g)")
      }
    }
  }

  /// XCUITest cannot see Flutter's keyboard focus. The first Tab goes to
  /// Back and each later Tab to the next tile, as in the widget tests, so
  /// `n + 2` Tabs reach tile `n` (from 0), and the Chosen line tells which
  /// tile the key reached. Each key is sent once, from a fresh launch; no
  /// modifier is used.
  func testEachTileOpensItsOwnItemByTabThenEnterOrSpace() {
    for slug in ["good-material", "bad-tile-in-item"] {
      for (i, g) in Self.groceries.enumerated() {
        for (key, name) in [("\n", "Enter"), (" ", "Space")] {
          open(slug)
          expectChosen(slug, "Chosen: none")
          for _ in 0..<(i + 2) {
            app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
            usleep(700_000)
          }
          app.typeKey(key, modifierFlags: [])
          expectChosen("\(slug), \(i + 2) Tabs then \(name)", slug: slug, "Chosen: \(g)")
        }
      }
    }
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so a stop after the
  // expected ones fails the test too. Every expected utterance is under 64
  // characters, the most XCUIVoiceOverService returns
  // (testExpectedUtterancesAreShortEnough).
  private static let speech: [(slug: String, content: [String])] = [
    ("good-bulleted", groceries),
    ("good-numbered", steps),
    ("good-material", groceries.map { "\($0) Button" } + ["Chosen: none"]),
    ("good-cupertino", ["Groceries"] + groceries),
    ("bad-one-text", ["Milk Eggs Bread"]),
    ("bad-no-list", groceries),
    ("bad-tile-in-item", groceries.map { "\($0) Button" } + ["Chosen: none"]),
    // A stop with no speech where the scroll view is, then the orders in
    // view, and nothing after them: moving forward does not scroll the list
    // (FL-011; the probe's p08, docs/evidence/probes/s08/ios.txt).
    ("bad-lazy-list", [VoiceOverWalk.silent] + (1...6).map { "Order \($0)" }),
  ]

  func testExpectedUtterancesAreShortEnough() {
    for example in Self.speech {
      for utterance in example.content {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \"\(utterance)\" is longer than VoiceOver's service returns")
      }
    }
  }

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    for example in Self.speech {
      for utterance in example.content where utterance.count >= 64 {
        XCTFail("\(example.slug): \"\(utterance)\" is 64 characters or more, which the service cannot return whole")
        return
      }
    }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("S08VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
