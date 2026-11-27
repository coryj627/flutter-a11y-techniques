// L3 (tree) and L4 (VoiceOver) for S11 Reading and traversal order on iOS.
// Spec: docs/specs/S11-reading-traversal-order.md.
//
// The texts and headings are found by their labels, the buttons by their
// test identifiers. XCUITest gives the elements in the order of the
// accessibility elements, but lists an element's children after the
// elements beside it, so the order is checked in the VoiceOver walk, which
// moves as VoiceOver does (the probe, docs/evidence/probes/s11/, measured
// both). XCUITest cannot read traits either, so the headings are checked in
// the walk too, and it cannot see Flutter's focus, so a Tab stop is named
// by which count Space adds to there.
import XCTest

final class S11ReadingTraversalOrderUITests: XCTestCase, TechniqueUITest {
  static let technique = "S11"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-columns": "Two columns, each kept together",
    "good-sort-keys": "Columns laid out row by row, given an order",
    "bad-columns-mixed": "Two columns read row by row",
    "bad-key-missing": "One part with no sort key",
  ]
  private static let slugs = ["good-columns", "good-sort-keys", "bad-columns-mixed", "bad-key-missing"]

  private static let route = ["Route", "Park at the gate.", "Climb the ridge.", "Walk back.", "Save route"]
  private static let bring = ["Bring", "Water", "A map", "Save list"]
  private static let counts = ["Route saves: 0", "List saves: 0"]
  /// The order meant: the route column, then the bring column, then the counts.
  private static let meant = route + bring + counts

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.titles[slug]!), settle: 500_000, file: file, line: line)
  }

  private func id(_ slug: String, _ name: String) -> String { "s11-\(slug)-\(name)" }

  /// The number a count shows: 2 for "Route saves: 2".
  private func count(_ slug: String, _ name: String) -> Int {
    Int(element(id(slug, name)).label.components(separatedBy: ": ").last ?? "") ?? -1
  }

  /// Waits up to 5 seconds for the two counts to be `route` and `list`.
  private func expectCounts(_ what: String, _ slug: String, route: Int, list: Int,
                            file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while (count(slug, "route-saves") != route || count(slug, "list-saves") != list) && Date() < deadline {
      usleep(100_000)
    }
    XCTAssertEqual(count(slug, "route-saves"), route, "\(what): route saves", file: file, line: line)
    XCTAssertEqual(count(slug, "list-saves"), list, "\(what): list saves", file: file, line: line)
  }

  /// Every part of every example is an element of its own with its own
  /// label, once, and the two buttons are buttons. The order is not
  /// checked here: XCUITest lists an element's children after the
  /// elements beside it, so its order is not VoiceOver's once a column is
  /// a container (probe fixtures r11 to r13 and r15 to r20, docs/evidence/probes/s11/ios.txt);
  /// the VoiceOver walk below checks the order.
  func testEveryPartIsAnElementOfItsOwn() {
    for slug in Self.slugs {
      open(slug)
      for label in Self.meant {
        XCTAssertEqual(elements(labelled: label).count, 1, "\(slug): \(label)")
      }
      XCTAssertEqual(element(id(slug, "save-route")).elementType, .button, slug)
      XCTAssertEqual(element(id(slug, "save-route")).label, "Save route", slug)
      XCTAssertEqual(element(id(slug, "save-list")).elementType, .button, slug)
      XCTAssertEqual(element(id(slug, "save-list")).label, "Save list", slug)
      XCTAssertEqual(app.buttons.allElementsBoundByIndex.map(\.label).filter { $0 != "Back" }.sorted(),
                     ["Save list", "Save route"], "\(slug): no other button but Back")
    }
  }

  func testEachButtonIsActivatedAloneByATap() {
    for slug in Self.slugs {
      for (name, route, list) in [("save-route", 1, 0), ("save-list", 0, 1)] {
        open(slug)
        expectCounts("\(slug) before", slug, route: 0, list: 0)
        element(id(slug, name)).tap()
        expectCounts("\(slug): a tap on \(name)", slug, route: route, list: list)
      }
    }
  }

  /// Tab, then Space, from a fresh launch: the first Tab is on Back, the
  /// second on Save route, the third on Save list, in every example. Each
  /// key is sent once; which count changed shows where Tab was. Shift+Tab
  /// is not sent: on CI's iOS 26.5 keys with a modifier were unreliable
  /// (wave 4), and the backwards order is tested on the web and Android.
  func testTabReachesTheButtonsInTheirOrder() {
    for slug in Self.slugs {
      for (tabs, route, list) in [(2, 1, 0), (3, 0, 1)] {
        open(slug)
        for _ in 0..<tabs {
          app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
          usleep(900_000)
        }
        app.typeKey(" ", modifierFlags: [])
        expectCounts("\(slug): \(tabs) Tabs then Space", slug, route: route, list: list)
      }
    }
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so every stop is judged
  // and a stop after the expected ones fails the test too. Utterances are
  // cut at 64 characters; every expected one is shorter.
  private static let routeSpoken = ["Route Heading", "Park at the gate.", "Climb the ridge.", "Walk back.", "Save route Button"]
  private static let bringSpoken = ["Bring Heading", "Water", "A map", "Save list Button"]
  static let speech: [(slug: String, content: [String])] = [
    ("good-columns", routeSpoken + bringSpoken + counts),
    ("good-sort-keys", routeSpoken + bringSpoken + counts),
    // Bad examples: the defect must be audible. Across the columns, both
    // headings first.
    ("bad-columns-mixed", [routeSpoken[0], bringSpoken[0], routeSpoken[1], bringSpoken[1], routeSpoken[2],
                           bringSpoken[2], routeSpoken[3], routeSpoken[4], bringSpoken[3]] + counts),
    // The Bring heading second, before the route.
    ("bad-key-missing", [routeSpoken[0], bringSpoken[0]] + routeSpoken.dropFirst() + bringSpoken.dropFirst() + counts),
  ]

  func testExpectedUtterancesAreShorterThanTheServiceLimit() {
    for example in Self.speech {
      for utterance in example.content {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \(utterance)")
      }
    }
  }

  func testVoiceOverSpeech() throws {
    for example in Self.speech {
      for utterance in example.content where utterance.count >= 64 {
        XCTFail("\(example.slug): \"\(utterance)\" is 64 characters or more, which the service cuts")
        return
      }
    }
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("S11VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
