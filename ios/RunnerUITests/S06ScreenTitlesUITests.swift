// L3 (tree) and L4 (VoiceOver) for S06 Screen and page titles on iOS.
// Spec: docs/specs/S06-screen-titles.md.
//
// Each example is a button that opens a screen. XCUITest has no navigation
// bar or screen title to read in a Flutter app (the S06 probe,
// docs/evidence/probes/s06/ios.txt: the title is a text element), and
// cannot read traits, so whether the title is a heading is shown only by
// what VoiceOver says ("Heading"), and the VoiceOver test checks it. What
// VoiceOver says as a screen opens and closes is read from currentSpeech()
// and judged raw (S06Landing.judge).
import XCTest

final class S06ScreenTitlesUITests: XCTestCase, TechniqueUITest {
  static let technique = "S06"
  let app = XCUIApplication()
  static let text = "Three orders in the last 30 days."

  override func setUp() {
    continueAfterFailure = true
  }

  static let titles = [
    "good-material": "Material screen title",
    "good-cupertino": "Cupertino screen title",
    "bad-no-title": "Screen with no title",
    "bad-vague-title": "Screen titled Details",
    "bad-no-document-title": "Screen with no document title",
    "bad-cupertino-unnamed": "Cupertino bar that names no screen",
  ]

  static let cupertino: Set<String> = ["good-cupertino", "bad-cupertino-unnamed"]

  /// The opened screen's title text; bad-no-title's is its large text.
  static let screenTitles = [
    "good-material": "Orders", "good-cupertino": "Orders", "bad-no-title": "Orders",
    "bad-vague-title": "Details", "bad-no-document-title": "Orders", "bad-cupertino-unnamed": "Orders",
  ]

  private func openButton(_ slug: String) -> XCUIElement { element("s06-\(slug)-open") }
  private func screenText(_ slug: String) -> XCUIElement { element("s06-\(slug)-text") }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: openButton(slug), settle: 500_000, file: file, line: line)
  }

  /// The buttons of the screen shown, by label.
  private func buttonLabels() -> [String] {
    app.buttons.allElementsBoundByIndex.map { $0.label }
  }

  func testTheButtonOpensTheScreenAndBackClosesIt() {
    for slug in Self.titles.keys.sorted() {
      open(slug)
      XCTAssertEqual(openButton(slug).elementType, .button, slug)
      XCTAssertEqual(openButton(slug).label, "Open orders", slug)
      openButton(slug).tap()
      XCTAssertTrue(screenText(slug).waitForExistence(timeout: 10), "\(slug): the screen opened")
      XCTAssertEqual(screenText(slug).label, Self.text, slug)
      // The title is a text element, and there is no navigation bar.
      XCTAssertTrue(element(labelled: Self.screenTitles[slug]!).exists, "\(slug): the title")
      XCTAssertEqual(app.navigationBars.count, 0, "\(slug): no navigation bar")
      // Nothing of the example screen is left in the tree.
      XCTAssertFalse(openButton(slug).exists, "\(slug): the example screen is covered")
      let back = element(labelled: "Back")
      XCTAssertTrue(back.exists, "\(slug): Back")
      back.tap()
      XCTAssertTrue(openButton(slug).waitForExistence(timeout: 10), "\(slug): Back closed the screen")
      XCTAssertFalse(screenText(slug).exists, "\(slug): the screen is gone")
    }
  }

  func testCupertinosBackButtonIsTwoButtonsOneWithNoName() {
    // FL-303. Material's Back is the positive control, in the same launch.
    for slug in ["good-material", "good-cupertino", "bad-cupertino-unnamed"] {
      open(slug)
      openButton(slug).tap()
      XCTAssertTrue(screenText(slug).waitForExistence(timeout: 10), "\(slug): the screen opened")
      let labels = buttonLabels()
      print("S06 \(slug) buttons: \(labels)")
      if Self.cupertino.contains(slug) {
        XCTAssertEqual(labels.sorted(), ["", "Back"], "\(slug): an unnamed button and one named Back")
      } else {
        XCTAssertEqual(labels, ["Back"], "\(slug): one button, named Back")
      }
    }
  }

  // L4. Three readings for each example, each a row of the transcript:
  //
  // - `<slug>-opened`: the cursor walked to the button, the button pressed
  //   with doubleTap() at its place (which acts on what is under the tap;
  //   VoiceOver's own activation was not measured), and currentSpeech()
  //   read every 0.15 s for six seconds, every read judged
  //   (S06Landing.judge): the button's utterance, then only where the
  //   cursor lands, which is the screen's first control. In the probe the
  //   title was never among the reads, with or without namesRoute
  //   (docs/evidence/probes/s06/ios.txt, p01 to p09).
  // - `<slug>-screen`: from there, moves forward to the end of the screen,
  //   where moving on gives the last utterance again: the whole list.
  // - `<slug>-closed`: Back pressed with doubleTap() at its place, and six
  //   seconds of reads judged the same way: the last utterance, then the
  //   example's button, where the cursor comes back.
  static let landing = [
    "good-material": "Back Button", "good-cupertino": "Button", "bad-no-title": "Back Button",
    "bad-vague-title": "Back Button", "bad-no-document-title": "Back Button", "bad-cupertino-unnamed": "Button",
  ]

  static let screens: [String: [String]] = [
    "good-material": ["Orders Heading", text],
    "good-cupertino": ["Back Button", "Orders Heading", text],
    // The large text is plain text.
    "bad-no-title": ["Orders", text],
    "bad-vague-title": ["Details Heading", text],
    "bad-no-document-title": ["Orders Heading", text],
    "bad-cupertino-unnamed": ["Back Button", "Orders Heading", text],
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    func poll() -> S06Landing.Poll {
      do {
        return .speech(VoiceOverWalk.normalized(try voiceOver.currentSpeech().utterance))
      } catch let error as NSError {
        return .failed("\(error.domain) \(error.code)")
      }
    }
    func listen() -> [S06Landing.Poll] {
      var polls: [S06Landing.Poll] = []
      let t0 = Date()
      while Date().timeIntervalSince(t0) < 6 {
        polls.append(poll())
        usleep(150_000)
      }
      return polls
    }
    func move() -> String {
      VoiceOverWalk.normalized((try? voiceOver.moveForward().utterance) ?? VoiceOverWalk.silent)
    }
    let button = "Open orders Button"

    for slug in Self.titles.keys.sorted() {
      open(slug)
      try voiceOver.enable()
      var walk: [String] = []
      for _ in 0..<10 {
        walk.append(move())
        if walk.last == button { break }
      }
      XCTAssertEqual(walk.last, button, "\(slug): the cursor did not reach the button: \(walk)")
      let before = poll()
      openButton(slug).doubleTap()
      let opened = listen()
      let landing = Self.landing[slug]!
      let openedVerdict = S06Landing.judge(before: before, polls: opened, from: button, to: landing)
      print("S06VO \(slug)-opened | \(S06Landing.heard([before] + opened).joined(separator: " / "))")
      XCTAssertNil(openedVerdict, "\(slug) opened: \(openedVerdict ?? "")")
      XCTAssertTrue(screenText(slug).exists, "\(slug): the screen opened")

      // The screen, from where the cursor landed, to its end.
      var stops: [String] = []
      for _ in 0..<8 {
        let s = move()
        if s == stops.last { break }
        stops.append(s)
      }
      // The end repeats the last utterance; a walk that never repeated did
      // not reach it.
      print("S06VO \(slug)-screen | \(stops.joined(separator: " / "))")
      XCTAssertEqual(stops, Self.screens[slug], "\(slug): the opened screen")

      // Closing it.
      let back = element(labelled: "Back")
      let beforeBack = poll()
      back.doubleTap()
      let closed = listen()
      let closedVerdict = S06Landing.judge(
        before: beforeBack, polls: closed, from: Self.screens[slug]!.last!, to: button)
      print("S06VO \(slug)-closed | \(S06Landing.heard([beforeBack] + closed).joined(separator: " / "))")
      XCTAssertNil(closedVerdict, "\(slug) closed: \(closedVerdict ?? "")")
      XCTAssertTrue(openButton(slug).waitForExistence(timeout: 5), "\(slug): Back closed the screen")
      try voiceOver.disable()
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}

/// How S06's iOS VoiceOver test judges what is said as a screen opens or
/// closes, kept apart from the device so that it is tested on made-up
/// readings (testLandingJudge, below).
enum S06Landing {
  /// One read of `currentSpeech()`: its utterance, whitespace-normalised by
  /// the test, or the error.
  enum Poll: Equatable {
    case speech(String)
    case failed(String)
  }

  /// The fewest reads the six seconds must hold.
  static let minimumReads = 20

  /// Each utterance of `polls` once where it repeats, for the transcript.
  static func heard(_ polls: [Poll]) -> [String] {
    var out: [String] = []
    for p in polls {
      let s: String
      switch p {
      case .speech(let t): s = t
      case .failed(let e): s = "(read failed: \(e))"
      }
      if s != out.last { out.append(s) }
    }
    return out
  }

  /// nil when the reads show the cursor going from `from` to `to` and
  /// nothing else, or why not. `before` is the read just before the
  /// action, and must be `from`, so that the capture is live before it.
  /// Every read is judged, none filtered: each is `from` until the first
  /// that is `to`, and every one after that is `to`. currentSpeech() keeps
  /// giving the last utterance while nothing is said, so a read of `from`
  /// after `to` is a return to the old one, a failure, not silence; any
  /// other text is a wrong reading; a failed or empty read is not a
  /// reading; and reads that never reach `to` are a stale capture.
  /// XCUIVoiceOverService gives only the first 64 characters of an
  /// utterance, so an expected one of 64 or more is refused.
  static func judge(before: Poll, polls: [Poll], from: String, to: String) -> String? {
    for (name, text) in [("from", from), ("to", to)] {
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "the expected \(name) utterance is empty" }
      if text.count >= 64 { return "the expected \(name) utterance is 64 characters or more" }
    }
    guard from != to else { return "the from and to utterances are the same" }
    guard before == .speech(from) else { return "the capture was not live before: \(before)" }
    guard polls.count >= minimumReads else { return "only \(polls.count) reads" }
    var arrived = false
    for (i, p) in polls.enumerated() {
      guard case .speech(let s) = p, !s.isEmpty else { return "read \(i + 1) was \(p)" }
      if s == to {
        arrived = true
      } else if s == from {
        if arrived { return "read \(i + 1) went back to \"\(from)\" after \"\(to)\"" }
      } else {
        return "read \(i + 1) was \"\(s)\", neither \"\(from)\" nor \"\(to)\""
      }
    }
    return arrived ? nil : "\"\(to)\" was never read: a stale capture"
  }
}

// The judge on made-up readings. In the technique's own class, so that the
// iOS tree run (`evidence.py --only ios`) runs them; they need no app and
// no VoiceOver.
extension S06ScreenTitlesUITests {
  func testLandingJudge() {
    let from = "Open orders Button", to = "Back Button"
    let f = S06Landing.Poll.speech(from), t = S06Landing.Poll.speech(to)
    func reads(_ head: [S06Landing.Poll], _ n: Int = 30) -> [S06Landing.Poll] {
      head + Array(repeating: t, count: max(0, n - head.count))
    }
    // Right: the old utterance, then the new one for good.
    XCTAssertNil(S06Landing.judge(before: f, polls: reads([f, f, t]), from: from, to: to))
    XCTAssertNil(S06Landing.judge(before: f, polls: reads([]), from: from, to: to))
    // Wrong: a return to the old one, another utterance, a failed or
    // empty read, no live read before, never arriving, too few reads.
    XCTAssertNotNil(S06Landing.judge(before: f, polls: reads([f, t, f]), from: from, to: to))
    XCTAssertNotNil(S06Landing.judge(before: f, polls: reads([f, .speech("Orders"), t]), from: from, to: to))
    XCTAssertNotNil(S06Landing.judge(before: f, polls: reads([f, .failed("x 3")]), from: from, to: to))
    XCTAssertNotNil(S06Landing.judge(before: f, polls: reads([f, .speech("")]), from: from, to: to))
    XCTAssertNotNil(S06Landing.judge(before: .failed("x 3"), polls: reads([]), from: from, to: to))
    XCTAssertNotNil(S06Landing.judge(before: t, polls: reads([]), from: from, to: to))
    XCTAssertNotNil(S06Landing.judge(before: f, polls: Array(repeating: f, count: 30), from: from, to: to))
    XCTAssertNotNil(S06Landing.judge(before: f, polls: Array(repeating: t, count: 5), from: from, to: to))
    // Refused: an expected utterance of 64 characters or more, an empty
    // one, or the same twice.
    let long = String(repeating: "a", count: 64)
    XCTAssertNotNil(S06Landing.judge(before: f, polls: reads([]), from: from, to: long))
    XCTAssertNotNil(S06Landing.judge(before: .speech(""), polls: reads([]), from: "", to: to))
    XCTAssertNotNil(S06Landing.judge(before: t, polls: Array(repeating: t, count: 30), from: to, to: to))
  }
}
