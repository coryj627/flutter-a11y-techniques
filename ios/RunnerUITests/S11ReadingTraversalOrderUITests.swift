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

  // L4. The whole walk VoiceOver makes, from the top of the screen to its
  // end (S11Walk, below), judged as a whole: this example's own title, its
  // good or bad line, and a bad example's defect, right before "Example
  // Heading", then exactly the expected content to the end. The two good
  // examples have the same content, so the title is what tells their walks
  // apart. Every content utterance is under the service's 64 characters; a
  // screen line of 64 or more (a defect) is matched as the service cuts it.
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

  /// What each screen says above its "Example" heading, as VoiceOver reads
  /// it: the title (the screen's level 1 heading), the good or bad line,
  /// and a bad example's defect (ExampleScreen in lib/app/screens.dart).
  static let screens: [String: [String]] = [
    "good-columns": ["Two columns, each kept together Heading",
                     "Good example for Reading and traversal order. Material."],
    "good-sort-keys": ["Columns laid out row by row, given an order Heading",
                       "Good example for Reading and traversal order. Widgets layer."],
    "bad-columns-mixed": ["Two columns read row by row Heading",
                          "Bad example for Reading and traversal order. Material.",
                          "Defect: A screen reader reads across the two columns, mixing the route with what to bring."],
    "bad-key-missing": ["One part with no sort key Heading",
                        "Bad example for Reading and traversal order. Widgets layer.",
                        "Defect: The \"Bring\" title has no sort key, so a screen reader reads it before the route."],
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
      let walk = try S11Walk.walk(voiceOver)
      let problem = S11Walk.judge(walk, screen: Self.screens[example.slug]!, content: example.content)
      // The whole walk, from the top, is what the transcript shows.
      print("S11VO \(example.slug) | \(walk.stops.joined(separator: " / "))"
            + " [end: \(walk.reachedEnd ? "reached" : "not reached"); back from the end: \(walk.backFromEnd ?? "(nothing)")]")
      XCTAssertNil(problem, "\(example.slug): \(problem ?? "")")
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  // The judge and the collector on made-up walks: no device needed.

  private static func walkOf(_ slug: String, before: [String] = ["Back Button"]) -> S11Walk.Result {
    let content = speech.first { $0.slug == slug }!.content
    let screen = screens[slug]!.map { $0.count >= 64 ? String($0.prefix(64)).trimmingCharacters(in: .whitespaces) : $0 }
    return S11Walk.Result(stops: before + screen + ["Example Heading"] + content, reachedEnd: true,
                          backFromEnd: content[content.count - 2])
  }

  private func judged(_ walk: S11Walk.Result, as slug: String) -> String? {
    S11Walk.judge(walk, screen: Self.screens[slug]!, content: Self.speech.first { $0.slug == slug }!.content)
  }

  func testTheJudgePassesEachExamplesOwnWalk() {
    for example in Self.speech {
      XCTAssertNil(judged(Self.walkOf(example.slug), as: example.slug), example.slug)
    }
  }

  func testTheJudgeRefusesTheOtherGoodExamplesWalk() {
    // The good examples' content is the same; only the title tells them apart.
    XCTAssertNotNil(judged(Self.walkOf("good-columns"), as: "good-sort-keys"))
    XCTAssertNotNil(judged(Self.walkOf("good-sort-keys"), as: "good-columns"))
  }

  func testTheJudgeRefusesAMissingEmptyOrWrongTitle() {
    for slug in ["good-columns", "bad-columns-mixed"] {
      let right = Self.walkOf(slug)
      let title = right.stops.firstIndex(of: Self.screens[slug]![0])!
      var missing = right
      missing.stops.remove(at: title)
      XCTAssertNotNil(judged(missing, as: slug), "\(slug): no title")
      var empty = right
      empty.stops[title] = ""
      XCTAssertNotNil(judged(empty, as: slug), "\(slug): an empty title")
      var wrong = right
      wrong.stops[title] = "Two columns read row by row Heading" == right.stops[title]
        ? "Two columns, each kept together Heading" : "Two columns read row by row Heading"
      XCTAssertNotNil(judged(wrong, as: slug), "\(slug): another example's title")
      var noRole = right
      noRole.stops[title] = String(right.stops[title].dropLast(" Heading".count))
      XCTAssertNotNil(judged(noRole, as: slug), "\(slug): the title without its heading trait")
    }
  }

  func testTheJudgeRefusesAMissingOrWrongLineAboveTheHeading() {
    var noLine = Self.walkOf("good-columns")
    noLine.stops.remove(at: noLine.stops.firstIndex(of: Self.screens["good-columns"]![1])!)
    XCTAssertNotNil(judged(noLine, as: "good-columns"))
    var noDefect = Self.walkOf("bad-key-missing")
    noDefect.stops.removeAll { $0.hasPrefix("Defect:") }
    XCTAssertNotNil(judged(noDefect, as: "bad-key-missing"))
    var otherDefect = Self.walkOf("bad-key-missing")
    otherDefect.stops = otherDefect.stops.map {
      $0.hasPrefix("Defect:") ? String(Self.screens["bad-columns-mixed"]![2].prefix(64)) : $0
    }
    XCTAssertNotNil(judged(otherDefect, as: "bad-key-missing"))
  }

  func testTheJudgeMatchesALongDefectAsTheServiceCutsIt() {
    let defect = Self.screens["bad-columns-mixed"]![2]
    XCTAssertGreaterThanOrEqual(defect.count, 64)
    XCTAssertTrue(S11Walk.matches(String(defect.prefix(64)), defect))
    XCTAssertFalse(S11Walk.matches(String(defect.prefix(40)), defect), "a capture cut shorter than the service cuts")
    XCTAssertFalse(S11Walk.matches("", defect))
    XCTAssertTrue(S11Walk.matches("Water", "Water"))
    XCTAssertFalse(S11Walk.matches("Wate", "Water"), "a short stop is matched whole")
  }

  func testTheJudgeRefusesAMidWalkDuplicate() {
    var walk = Self.walkOf("good-columns")
    let water = walk.stops.firstIndex(of: "Water")!
    walk.stops.insert("Water", at: water)
    XCTAssertNotNil(judged(walk, as: "good-columns"), "a stop read twice in a row")
    var title = Self.walkOf("good-columns")
    title.stops.insert(Self.screens["good-columns"]![0], at: title.stops.firstIndex(of: Self.screens["good-columns"]![0])!)
    XCTAssertNotNil(judged(title, as: "good-columns"), "the title read twice in a row")
  }

  func testTheJudgeNeedsIndependentEvidenceOfTheEnd() {
    var notReached = Self.walkOf("good-columns")
    notReached.reachedEnd = false
    XCTAssertNotNil(judged(notReached, as: "good-columns"))
    var noBack = Self.walkOf("good-columns")
    noBack.backFromEnd = nil
    XCTAssertNotNil(judged(noBack, as: "good-columns"), "no move back from the end")
    var staleBack = Self.walkOf("good-columns")
    staleBack.backFromEnd = "List saves: 0"
    XCTAssertNotNil(judged(staleBack, as: "good-columns"), "the move back read the last stop again: stale speech")
  }

  func testTheCollectorKeepsADuplicateAndEndsOnlyOnTwoRepeats() {
    // A mid-walk duplicate is kept as a stop of its own.
    var feed = ["A", "A", "B", "C", "C", "C"].makeIterator()
    let walk = S11Walk.collect(max: 24) { feed.next()! }
    XCTAssertEqual(walk.stops, ["A", "A", "B", "C"])
    XCTAssertTrue(walk.reachedEnd)
    // A duplicate title in the middle of a real walk is kept, and fails.
    var title = ["Back Button", "T Heading", "T Heading", "Example Heading", "x", "x", "x"].makeIterator()
    let walked = S11Walk.collect(max: 24) { title.next()! }
    XCTAssertEqual(walked.stops, ["Back Button", "T Heading", "T Heading", "Example Heading", "x"])
    // Stale speech at the end: two repeats end the collection, but the end
    // still needs the move back (judge), which here is missing.
    var stale = ["A", "B", "B", "B"].makeIterator()
    let short = S11Walk.collect(max: 24) { stale.next()! }
    XCTAssertEqual(short.stops, ["A", "B"])
    XCTAssertTrue(short.reachedEnd)
    XCTAssertNil(short.backFromEnd)
    // Out of moves before two repeats: not the end.
    var endless = (1...30).map(String.init).makeIterator()
    XCTAssertFalse(S11Walk.collect(max: 24) { endless.next()! }.reachedEnd)
  }
}

/// S11's own VoiceOver walk and judge (C03Walk's way of moving, with what
/// review asked for added): every utterance is kept, a mid-walk duplicate
/// included; the walk ends when moving on gives the last utterance again,
/// twice, and the end then needs independent evidence: one move back must
/// read the stop before the last.
enum S11Walk {
  struct Result: Equatable {
    var stops: [String]
    var reachedEnd: Bool
    var backFromEnd: String? = nil
  }

  /// Reads utterances from `next` until the same one has come three times
  /// in a row (the last element, then two moves that found nothing after
  /// it), at most `max` reads. The two repeats at the end are left out;
  /// any other repeat is kept as a stop.
  static func collect(max: Int = 30, _ next: () throws -> String) rethrows -> Result {
    var heard: [String] = []
    for _ in 0..<max {
      heard.append(try next())
      if heard.count >= 3, heard[heard.count - 1] == heard[heard.count - 2], heard[heard.count - 2] == heard[heard.count - 3] {
        return Result(stops: Array(heard.dropLast(2)), reachedEnd: true)
      }
    }
    return Result(stops: heard, reachedEnd: false)
  }

  /// Whether `utterance` is `expected` as the service gives it: whole, or,
  /// for an expected stop of 64 characters or more, its first 64
  /// characters (white space at the cut trimmed).
  static func matches(_ utterance: String, _ expected: String) -> Bool {
    if expected.count < 64 { return utterance == expected }
    let cut = String(expected.prefix(64)).trimmingCharacters(in: .whitespaces)
    return utterance == cut || utterance == String(expected.prefix(64))
  }

  /// What is wrong with a walk, or nil for a right one: it must have
  /// reached the end, with a move back from it that read the stop before
  /// the last; no stop may be read twice in a row; the stops right before
  /// the last "Example Heading" must be `screen` (title, line, defect), and
  /// the stops after it exactly `content`.
  static func judge(_ walk: Result, screen: [String], content: [String]) -> String? {
    guard walk.reachedEnd else { return "the walk did not reach the end" }
    let s = walk.stops
    for i in 1..<max(s.count, 1) where s[i] == s[i - 1] {
      return "stop \(i + 1), \"\(s[i])\", was read twice in a row"
    }
    guard let heading = s.lastIndex(of: "Example Heading") else { return "no \"Example Heading\"" }
    guard heading >= screen.count else { return "the walk has too few stops before the heading" }
    let above = Array(s[(heading - screen.count)..<heading])
    for (got, want) in zip(above, screen) where !matches(got, want) {
      return "above the heading, \"\(got)\" where \"\(want)\" was expected (all: \(above))"
    }
    let after = Array(s[(heading + 1)...])
    guard after == content else { return "after the heading: \(after), expected \(content)" }
    guard content.count >= 2, walk.backFromEnd == content[content.count - 2] else {
      return "one move back from the end read \"\(walk.backFromEnd ?? "nothing")\", not \"\(content.dropLast().last ?? "")\""
    }
    return nil
  }

  #if compiler(>=6.4)
  /// Switches VoiceOver on, walks to the end of the screen (a move with no
  /// speech handled as C03Walk does), makes one move back from the end, and
  /// switches VoiceOver off.
  @available(iOS 27.0, *)
  static func walk(_ voiceOver: XCUIVoiceOverService) throws -> Result {
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    var last: String?
    var result = try collect {
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
    if result.reachedEnd {
      result.backFromEnd = try? VoiceOverWalk.normalized(voiceOver.moveBackward().utterance)
    }
    return result
  }
  #endif
}
