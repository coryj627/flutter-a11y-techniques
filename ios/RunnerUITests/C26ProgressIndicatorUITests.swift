// L3 (tree) and L4 (VoiceOver) for C26 Progress indicator on iOS.
// Spec: docs/specs/C26-progress-indicator.md.
//
// Each example's task runs four steps of one second once its button is
// pressed. Every reading after a tap waits in a bounded loop for the state
// it expects. XCUITest cannot read traits, so a live region cannot be seen
// in the tree: whether a status line is announced is measured by the
// VoiceOver test. XCUIVoiceOverService has no activation of its own: the
// cursor is put on the button with `tap()`, and the button is pressed with
// `doubleTap()` at its place, which acts on what is under the tap (C04
// probe, round 3); VoiceOver's own activation was not measured.
import XCTest

final class C26ProgressIndicatorUITests: XCTestCase, TechniqueUITest {
  static let technique = "C26"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  static let titles = [
    "good-linear": "Material progress bar",
    "bad-no-role": "Material spinner",
    "bad-cupertino-no-role": "Cupertino spinner",
    "bad-no-label": "Progress bar with no name",
    "bad-silent-end": "Upload that ends in silence",
    "bad-adaptive": "Adaptive spinner",
    "bad-cupertino-bar": "Cupertino progress bar",
  ]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.titles[slug]!), settle: 500_000, file: file, line: line)
  }

  private func start(_ slug: String) -> XCUIElement { element("c26-\(slug)-start") }
  private func status(_ slug: String) -> XCUIElement { element("c26-\(slug)-status") }

  /// Waits up to `seconds` for `check`, reading every 100 ms.
  @discardableResult
  private func wait(_ seconds: TimeInterval, _ check: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
      if check() { return true }
      usleep(100_000)
    }
    return check()
  }

  private func expectStatus(_ slug: String, _ text: String, within seconds: TimeInterval = 3,
                            file: StaticString = #filePath, line: UInt = #line) {
    wait(seconds) { status(slug).label == text }
    XCTAssertEqual(status(slug).label, text, slug, file: file, line: line)
  }

  /// An element as one snapshot of the app has it, or nil. While a spinner
  /// turns, the app is never idle; a snapshot is read at once (the C26
  /// probe read the tree this way, docs/evidence/probes/c26/ios.txt).
  private struct Seen: Equatable {
    var type: XCUIElement.ElementType
    var label: String
    var value: String
  }

  private func seen(_ id: String) -> Seen? {
    guard let root = try? app.snapshot() else { return nil }
    func find(_ s: XCUIElementSnapshot) -> XCUIElementSnapshot? {
      if s.identifier == id { return s }
      for c in s.children { if let f = find(c) { return f } }
      return nil
    }
    return find(root).map { Seen(type: $0.elementType, label: $0.label, value: ($0.value as? String) ?? "") }
  }

  /// How many elements of one snapshot have the label `label`.
  private func snapshotCount(labelled label: String) -> Int {
    guard let root = try? app.snapshot() else { return -1 }
    func count(_ s: XCUIElementSnapshot) -> Int { (s.label == label ? 1 : 0) + s.children.map(count).reduce(0, +) }
    return count(root)
  }

  private func describe(_ e: XCUIElement) -> String {
    e.exists ? "type=\(e.elementType.rawValue) label=\(e.label.debugDescription) value=\(String(describing: e.value))" : "(none)"
  }

  func testGoodLinearIsNamedWithItsValueAtEachStep() {
    open("good-linear")
    let bar = element("c26-good-linear-bar")
    XCTAssertTrue(bar.waitForExistence(timeout: 5))
    print("C26IOS good-linear bar: \(describe(bar))")
    XCTAssertEqual(bar.label, "Report upload")
    XCTAssertEqual(bar.value as? String, "0")
    // FL-256: plain text, not a progress indicator.
    XCTAssertEqual(bar.elementType, .staticText)
    // The words above the bar are not an element of their own.
    XCTAssertEqual(elements(labelled: "Report upload").count, 1)
    start("good-linear").tap()
    var seen: [String] = []
    for value in ["25", "50", "75", "100"] {
      wait(3) { (bar.value as? String) == value }
      seen.append(bar.value as? String ?? "")
    }
    XCTAssertEqual(seen, ["25", "50", "75", "100"])
  }

  func testStatusLinesSayHowItGoesAndThatItEnded() {
    for slug in ["good-linear", "bad-no-role", "bad-cupertino-no-role"] {
      open(slug)
      let upload = slug == "good-linear"
      expectStatus(slug, upload ? "Not started" : "Inbox not loaded")
      start(slug).tap()
      if upload {
        expectStatus(slug, "Upload started", within: 1.5)
        expectStatus(slug, "Half uploaded")
        expectStatus(slug, "Upload complete")
      } else {
        expectStatus(slug, "Loading started", within: 1.5)
        expectStatus(slug, "Inbox loaded", within: 6)
      }
    }
  }

  func testBadSpinnersAreNamedWithNoValueAndNoRole() {
    for slug in ["bad-no-role", "bad-cupertino-no-role"] {
      open(slug)
      let id = "c26-\(slug)-spinner"
      XCTAssertNil(seen(id), "\(slug): no spinner before")
      start(slug).tap()
      XCTAssertTrue(wait(3) { seen(id) != nil }, "\(slug): spinner shown")
      let spinner = seen(id)
      print("C26IOS \(slug) spinner: \(String(describing: spinner))")
      // The defect (FL-256): plain text, named, with no value and no role.
      XCTAssertEqual(spinner, Seen(type: .staticText, label: "Loading inbox", value: ""), slug)
      XCTAssertEqual(snapshotCount(labelled: "Loading inbox"), 1, slug)
      XCTAssertTrue(wait(6) { seen(id) == nil }, "\(slug): spinner gone")
      expectStatus(slug, "Inbox loaded", within: 2)
    }
  }

  func testTabAndReturnStartTheTask() {
    // XCUITest cannot see Flutter's focus: that the Tab reached the button
    // is shown by Return starting the task. No key with a modifier.
    open("good-linear")
    // As C12's and C03's key tests: Return is sent as "\n", 0.9 s after each
    // Tab. In the first run, two Tabs 0.6 s apart and
    // XCUIKeyboardKey.return left the status "Not started"; which key did
    // not arrive was not found.
    for _ in 0..<2 {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(900_000)
    }
    app.typeKey("\n", modifierFlags: [])
    expectStatus("good-linear", "Upload started", within: 3)
  }

  func testBadNoLabelHasAValueAndNoName() {
    open("bad-no-label")
    let bar = element("c26-bad-no-label-bar")
    XCTAssertTrue(bar.waitForExistence(timeout: 5))
    print("C26IOS bad-no-label bar: \(describe(bar))")
    XCTAssertEqual(bar.label, "")
    XCTAssertEqual(bar.value as? String, "0")
    XCTAssertEqual(elements(labelled: "Report upload").count, 1)
    XCTAssertNotEqual(elements(labelled: "Report upload").firstMatch.identifier, "c26-bad-no-label-bar")
    open("good-linear")
    XCTAssertEqual(element("c26-good-linear-bar").label, "Report upload")
  }

  func testBadAdaptiveExposesNothingWhileBadNoRoleIsNamed() {
    open("bad-adaptive")
    start("bad-adaptive").tap()
    expectStatus("bad-adaptive", "Loading started", within: 1.5)
    // FL-257: the spinner's node has nothing in it, and no element has its
    // label. Its identifier alone is in the tree (an element of type other
    // with an empty label, as the probe's p09 was), which VoiceOver passes
    // over (the VoiceOver test).
    let spinner = seen("c26-bad-adaptive-spinner")
    print("C26IOS bad-adaptive spinner: \(String(describing: spinner))")
    XCTAssertEqual(spinner?.label ?? "", "")
    XCTAssertEqual(spinner?.value ?? "", "")
    XCTAssertEqual(snapshotCount(labelled: "Loading inbox"), 0)
    // Positive control, the same reading in the same launch: bad-no-role.
    open("bad-no-role")
    start("bad-no-role").tap()
    XCTAssertTrue(wait(3) { seen("c26-bad-no-role-spinner") != nil })
    XCTAssertEqual(seen("c26-bad-no-role-spinner")?.label, "Loading inbox")
    XCTAssertEqual(snapshotCount(labelled: "Loading inbox"), 1)
  }

  func testBadCupertinoBarExposesNothing() {
    open("bad-cupertino-bar")
    func check(_ when: String) {
      let bar = element("c26-bad-cupertino-bar-bar")
      print("C26IOS bad-cupertino-bar \(when): \(describe(bar))")
      XCTAssertTrue(!bar.exists || (bar.label.isEmpty && ((bar.value as? String) ?? "").isEmpty), when)
    }
    check("at rest")
    start("bad-cupertino-bar").tap()
    expectStatus("bad-cupertino-bar", "Half uploaded", within: 4)
    check("while running")
  }

  // L4. Three readings, each a row of the transcript:
  //
  // - `<slug>`: the walk from the top of the screen to its end, at rest,
  //   every utterance after the "Example" heading compared as a whole list
  //   (C03Walk, C03's walk: it ends where moving on gives the last
  //   utterance again, twice).
  // - `<slug>-run`: the cursor put on the button with tap(), the button
  //   pressed with doubleTap() at its place (which acts on what is under the
  //   tap; VoiceOver's own activation was not measured), and every distinct
  //   utterance currentSpeech() gives for nine seconds, in order. The status
  //   line must have reached its end, so that silence cannot mean the task
  //   did not run. For bad-silent-end nothing about the upload may be
  //   heard; then two moves forward must reach the status line and read
  //   "Upload complete", so that the silence is not an empty capture.
  // - `<slug>-loading`, for the spinners: the cursor on the button, the
  //   button pressed, and 0.8 s later one move back and three forward
  //   (`loading`, below).
  //
  // The probe measured the utterances (docs/evidence/probes/c26/ios.txt):
  // a bar is "<name> <value>" with no role and the value a bare number; a
  // named spinner is its name; an indicator with nothing is passed over.
  static let walks: [String: [String]] = [
    "good-linear": ["Upload report Button", "Report upload 0", "Not started"],
    "bad-no-role": ["Load inbox Button", "Inbox not loaded"],
    "bad-cupertino-no-role": ["Load inbox Button", "Inbox not loaded"],
    // The bar is named by nothing: its value alone.
    "bad-no-label": ["Upload report Button", "Report upload", "0", "Not started"],
    "bad-silent-end": ["Upload report Button", "Report upload 0", "Not started"],
    "bad-adaptive": ["Load inbox Button", "Inbox not loaded"],
    // The bar is not there.
    "bad-cupertino-bar": ["Upload report Button", "Report upload", "Not started"],
  ]

  /// What must be heard, in order, while each task runs.
  static let heard: [String: [String]] = [
    "good-linear": ["Upload started", "Half uploaded", "Upload complete"],
    "bad-no-role": ["Loading started", "Inbox loaded"],
    "bad-cupertino-no-role": ["Loading started", "Inbox loaded"],
    "bad-adaptive": ["Loading started", "Inbox loaded"],
    "bad-cupertino-bar": ["Upload started", "Half uploaded", "Upload complete"],
  ]

  /// The two moves forward from the button while loading.
  /// One move back and three forward while loading, with the cursor left
  /// on the button: the heading, the button, then the spinner where it has
  /// a name, or the status line where it has none. The fourth is checked
  /// apart (testVoiceOverSpeech).
  static let loading: [String: [String]] = [
    "bad-no-role": ["Example Heading", "Load inbox Button", "Loading inbox", "Loading started"],
    "bad-cupertino-no-role": ["Example Heading", "Load inbox Button", "Loading inbox", "Loading started"],
    // FL-257: the spinner is passed over.
    "bad-adaptive": ["Example Heading", "Load inbox Button", "Loading started", "Loading started"],
  ]

  static let action = [
    "good-linear": "Upload report", "bad-no-role": "Load inbox", "bad-cupertino-no-role": "Load inbox",
    "bad-no-label": "Upload report", "bad-silent-end": "Upload report", "bad-adaptive": "Load inbox",
    "bad-cupertino-bar": "Upload report",
  ]

  static let end = [
    "good-linear": "Upload complete", "bad-no-role": "Inbox loaded", "bad-cupertino-no-role": "Inbox loaded",
    "bad-no-label": "Upload complete", "bad-silent-end": "Upload complete", "bad-adaptive": "Inbox loaded",
    "bad-cupertino-bar": "Upload complete",
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    // Every read of currentSpeech() is a Poll: an error is never taken for
    // silence. With VoiceOver on it gives the last utterance, still there
    // after a quiet ten seconds; the only error measured was "No speech
    // available" (code 3) with VoiceOver off
    // (docs/evidence/probes/c26/currentSpeech.txt).
    func poll() -> C26Silence.Poll {
      do {
        return .speech(VoiceOverWalk.normalized(try voiceOver.currentSpeech().utterance))
      } catch let error as NSError {
        return .failed("\(error.domain) \(error.code)")
      }
    }
    func current() -> String {
      if case .speech(let s) = poll() { return s }
      return ""
    }
    func move() -> String {
      VoiceOverWalk.normalized((try? voiceOver.moveForward().utterance) ?? VoiceOverWalk.silent)
    }
    /// Puts the cursor on the button: tap() moves it there with VoiceOver on.
    func cursorOnButton(_ slug: String) -> String {
      let expected = "\(Self.action[slug]!) Button"
      var said = ""
      for _ in 0..<5 {
        start(slug).tap()
        let deadline = Date().addingTimeInterval(4)
        said = current()
        while said != expected && Date() < deadline {
          usleep(250_000)
          said = current()
        }
        if said == expected { break }
      }
      XCTAssertEqual(said, expected, "\(slug): the cursor is not on the button")
      return said
    }

    for slug in Self.titles.keys.sorted() {
      // At rest.
      open(slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("C26VO \(slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, Self.walks[slug], slug)

      // While the task runs.
      if slug != "bad-no-label" {
        open(slug)
        try voiceOver.enable()
        let before = cursorOnButton(slug)
        start(slug).doubleTap()
        let t0 = Date()
        var polls: [C26Silence.Poll] = []
        while Date().timeIntervalSince(t0) < 9 {
          polls.append(poll())
          usleep(200_000)
        }
        let said = C26Silence.heard(polls)
        // Every raw read, for every example: none may fail, and none may be
        // empty. With VoiceOver on, currentSpeech() gives the last utterance
        // (docs/evidence/probes/c26/currentSpeech.txt); an empty one (after
        // poll()'s whitespace normalising, a whitespace-only one too) is
        // not something it was measured to give, and is not taken for
        // silence.
        XCTAssertEqual(C26Silence.unreadable(polls), [], "\(slug): reads that failed or were empty while the task ran")
        XCTAssertEqual(status(slug).label, Self.end[slug]!, "\(slug): the task did not run to its end")
        var row = "\(before) / (tap at it) / \(said.joined(separator: " / "))"
        if slug == "bad-silent-end" {
          // Nothing may be heard but the button's own utterance, which
          // currentSpeech() gives from before the tap: no status phrase,
          // and no number from the bar (FL-254). The capture is shown live
          // through the same reading before (the button) and after (the
          // status line, reached by two moves); C26Silence.judge.
          let moves = [move(), move()]
          let after = poll()
          row += " / (forward twice) / \(moves.joined(separator: " / "))"
          let verdict = C26Silence.judge(
            button: "\(Self.action[slug]!) Button", before: before, polls: polls, after: after,
            end: "Upload complete")
          XCTAssertNil(verdict, "\(slug): \(verdict ?? "")")
          XCTAssertEqual(moves.last, "Upload complete", "\(slug): the moves forward did not reach the status line")
        } else {
          // The phrases in order, each heard.
          var rest = Self.heard[slug]!
          for s in said where s == rest.first { rest.removeFirst() }
          XCTAssertEqual(rest, [], "\(slug): not heard, in order: \(rest); heard \(said)")
        }
        print("C26VO \(slug)-run | \(row)")
        try voiceOver.disable()
      }

      // The spinner while loading.
      if let expected = Self.loading[slug] {
        open(slug)
        try voiceOver.enable()
        _ = cursorOnButton(slug)
        start(slug).doubleTap()
        // In the first two runs, two moves forward made 0.5 s, and then
        // about 1.5 s, after the tap each read "Loading started", the status
        // line, for every spinner alike, named or not
        // (docs/evidence/probes/c26/voiceover-ios-round1-fail.md.txt and
        // voiceover-ios-round2-fail.md.txt). Why was not found. So the
        // cursor's place is read first: one move back, then three forward,
        // 0.8 s after the tap; the spinner stays four. In the third run that
        // way reached the named spinners (round3-fail, failed only at
        // bad-adaptive's fourth move, below).
        usleep(800_000)
        let back = VoiceOverWalk.normalized((try? voiceOver.moveBackward().utterance) ?? VoiceOverWalk.silent)
        let moves = [back, move(), move(), move()]
        print("C26VO \(slug)-loading | \(moves.joined(separator: " / "))")
        // The first three exactly. The fourth is the status line, read as
        // it is by then: for bad-adaptive, the end of the screen, where
        // VoiceOver reads the last element again, and in the third run the
        // load had ended and it said "Inbox loaded"
        // (docs/evidence/probes/c26/voiceover-ios-round3-fail.md.txt).
        XCTAssertEqual(Array(moves.prefix(3)), Array(expected.prefix(3)), "\(slug): the moves while loading")
        XCTAssertTrue(["Loading started", "Inbox loaded"].contains(moves[3]), "\(slug): the fourth move, \(moves[3])")
        XCTAssertFalse(slug == "bad-adaptive" && moves.contains("Loading inbox"), "\(slug): the spinner was read")
        try voiceOver.disable()
      }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}

/// How C26's iOS VoiceOver test judges `bad-silent-end`'s nine seconds,
/// kept apart from the device so that it is tested on made-up readings
/// (the testSilenceJudge tests, below).
enum C26Silence {
  /// One read of `currentSpeech()`: its utterance, already whitespace-
  /// normalised by the test (`VoiceOverWalk.normalized`: runs of
  /// whitespace made one space, and none at the ends), or the error.
  enum Poll: Equatable {
    case speech(String)
    case failed(String)
  }

  /// The fewest reads the nine seconds must hold: one a second.
  static let minimumReads = 9

  /// The utterances of `polls`, each once where it repeats. For the
  /// transcript and for the order of required phrases only; never for
  /// judging silence.
  static func heard(_ polls: [Poll]) -> [String] {
    var out: [String] = []
    for p in polls {
      if case .speech(let s) = p, !s.isEmpty, s != out.last { out.append(s) }
    }
    return out
  }

  /// The reads of `polls` that read nothing usable: failed, or empty
  /// (whitespace-only included, as the test normalises it to empty).
  static func unreadable(_ polls: [Poll]) -> [Poll] {
    polls.filter { p in
      switch p {
      case .failed: return true
      case .speech(let s): return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      }
    }
  }

  /// nil when the interval is shown silent, or why not. Every raw read is
  /// judged, none filtered: the reading before the interval (`before`),
  /// each read in it, and the reading after it (`after`, once the cursor
  /// has moved to the status line) go through the same path. Each must be
  /// exactly as expected, compared as whole strings after the test's
  /// whitespace normalising, with no trimming of its own: `before` and
  /// every read the button's utterance, `after` the status line's. With
  /// VoiceOver on, currentSpeech() keeps giving the last utterance while
  /// nothing is said (measured), so silence reads as the button's
  /// utterance, every time. A failed read, an empty one, a whitespace-only
  /// one, or any other text is never silence. XCUIVoiceOverService cuts an
  /// utterance at 64 characters; both expected ones are shorter, and an
  /// expected one of 64 or more is refused.
  static func judge(button: String, before: String, polls: [Poll], after: Poll, end: String) -> String? {
    for (name, text) in [("button", button), ("end", end)] {
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "the expected \(name) utterance is empty" }
      if text.count >= 64 { return "the expected \(name) utterance is 64 characters or more" }
    }
    guard button != end else { return "the button's and the end's utterances are the same" }
    guard before == button else { return "the capture was not live before: read \"\(before)\"" }
    guard polls.count >= minimumReads else { return "only \(polls.count) reads in the interval" }
    for (i, p) in polls.enumerated() where p != .speech(button) {
      return "read \(i + 1) of \(polls.count) was \(p), not the button's utterance"
    }
    guard after == .speech(end) else { return "the capture was not live after: \(after)" }
    return nil
  }
}

// The judge on made-up readings. In the technique's own class, so that the
// iOS tree run (`evidence.py --only ios`) runs them; they need no app and
// no VoiceOver.
extension C26ProgressIndicatorUITests {
  private var button: String { "Upload report Button" }
  private var end: String { "Upload complete" }
  private var failure: C26Silence.Poll { .failed("com.apple.xctest.voiceoverservice 3") }

  /// Every shape a single read can take.
  private var shapes: [(name: String, poll: C26Silence.Poll)] {
    [("failed", failure), ("empty", .speech("")), ("whitespace", .speech("   ")),
     ("button", .speech(button)), ("other text", .speech("Report upload 50")),
     ("a number", .speech("25")), ("the end", .speech(end)),
     ("the button with a space", .speech(button + " "))]
  }

  /// Every interval shape: all reads one shape, one read of a shape among
  /// the button's at the start, the middle, and the end, and too few reads.
  private var intervals: [(name: String, polls: [C26Silence.Poll], silent: Bool)] {
    let n = 45
    var out: [(String, [C26Silence.Poll], Bool)] = []
    for (name, poll) in shapes {
      let isButton = poll == .speech(button)
      out.append(("all \(name)", Array(repeating: poll, count: n), isButton))
      for at in [0, n / 2, n - 1] {
        var polls = Array(repeating: C26Silence.Poll.speech(button), count: n)
        polls[at] = poll
        out.append(("one \(name) at \(at)", polls, isButton))
      }
    }
    out.append(("none", [], false))
    out.append(("8 of the button", Array(repeating: .speech(button), count: C26Silence.minimumReads - 1), false))
    out.append(("9 of the button", Array(repeating: .speech(button), count: C26Silence.minimumReads), true))
    return out
  }

  func testSilenceJudgeOverEveryShapeOfInput() {
    // The full cross: every `before`, every interval, every `after`. Only
    // the button's utterance before, a silent interval, and the end's
    // utterance after pass.
    var cases = 0
    for (beforeName, beforePoll) in shapes {
      let before: String
      switch beforePoll {
      case .speech(let s): before = s
      case .failed: before = ""  // what the test's current() gives on a failed read
      }
      for interval in intervals {
        for (afterName, after) in shapes {
          let verdict = C26Silence.judge(button: button, before: before, polls: interval.polls, after: after, end: end)
          let shouldPass = before == button && interval.silent && after == .speech(end)
          XCTAssertEqual(verdict == nil, shouldPass,
                         "before \(beforeName), interval \(interval.name), after \(afterName): \(verdict ?? "passed")")
          cases += 1
        }
      }
    }
    XCTAssertEqual(cases, shapes.count * intervals.count * shapes.count)
  }

  func testSilenceJudgeNamedRegressions() {
    let quiet = Array(repeating: C26Silence.Poll.speech(button), count: 45)
    XCTAssertNil(C26Silence.judge(button: button, before: button, polls: quiet, after: .speech(end), end: end))
    // Every read failed, and the moves afterwards worked (round 3's finding).
    XCTAssertNotNil(C26Silence.judge(button: button, before: button, polls: Array(repeating: failure, count: 45),
                                     after: .speech(end), end: end))
    // An entirely empty interval, one empty read, one whitespace-only read
    // (round 4's finding).
    XCTAssertNotNil(C26Silence.judge(button: button, before: button, polls: Array(repeating: .speech(""), count: 45),
                                     after: .speech(end), end: end))
    for blank in ["", "   "] {
      var polls = quiet
      polls[20] = .speech(blank)
      XCTAssertNotNil(C26Silence.judge(button: button, before: button, polls: polls, after: .speech(end), end: end),
                      "\"\(blank)\"")
    }
  }

  func testSilenceJudgeRefusesDegenerateExpectations() {
    let quiet = Array(repeating: C26Silence.Poll.speech(""), count: 45)
    // An empty expected utterance would make empty reads pass.
    XCTAssertNotNil(C26Silence.judge(button: "", before: "", polls: quiet, after: .speech(end), end: end))
    XCTAssertNotNil(C26Silence.judge(button: " ", before: " ", polls: Array(repeating: .speech(" "), count: 45),
                                     after: .speech(end), end: end))
    XCTAssertNotNil(C26Silence.judge(button: button, before: button, polls: Array(repeating: .speech(button), count: 45),
                                     after: .speech(button), end: button))
    let long = String(repeating: "x", count: 64)
    XCTAssertNotNil(C26Silence.judge(button: long, before: long, polls: Array(repeating: .speech(long), count: 45),
                                     after: .speech(end), end: end))
  }

  func testUnreadablePollsAreFailedOrBlank() {
    XCTAssertEqual(C26Silence.unreadable([.speech(button), .speech(""), .speech("  "), failure, .speech("25")]),
                   [.speech(""), .speech("  "), failure])
  }
}
