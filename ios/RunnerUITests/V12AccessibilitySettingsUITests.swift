// L3 (tree) and L4 (VoiceOver) for V12 Detecting accessibility settings on
// iOS. Spec: docs/specs/V12-accessibility-settings.md.
//
// Each example's lines say which settings the app was told are on. A
// setting is changed while an example is open in one of two ways, both
// measured in the probe (docs/evidence/probes/v12/): VoiceOver, turned on
// and off through XCUIVoiceOverService, which sets accessibleNavigation;
// and the simulator's own Settings app, driven by XCUITest, for Reduce
// Motion (AccessibilityFeatures.reduceMotion, and never disableAnimations)
// and Increase Contrast (highContrast). A Settings test reads its switch
// first and, before changing anything, registers a teardown block that
// puts that value back and checks it; it then sets the switch off, checks
// it reads off, and shows the example's baseline before turning it on.
// Each turn is checked on the switch itself and, for a line that must
// change, on the line. Each reading
// after a change is waited for in a bounded loop; where a line must not
// change, the witness that the change reached the app is good-media-query
// or good-motion, opened by its address in the same running app, saying
// it.
import XCTest

final class V12AccessibilitySettingsUITests: XCTestCase, TechniqueUITest {
  static let technique = "V12"
  let app = XCUIApplication()
  let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")

  override func setUp() {
    continueAfterFailure = true
  }

  /// Each example's title and the lines above its "Example" heading, as
  /// the screen shows them (ExampleScreen in lib/app/screens.dart).
  static let screens: [String: [String]] = [
    "good-media-query": ["Settings from MediaQuery", "Good example for Detecting accessibility settings. Widgets layer."],
    "good-motion": ["Reduce motion from both flags", "Good example for Detecting accessibility settings. Widgets layer."],
    "bad-read-once": [
      "Settings read once", "Bad example for Detecting accessibility settings. Widgets layer.",
      "Defect: A setting changed while this is open is not shown.",
    ],
    "bad-animations-only": [
      "Reduce motion from one flag", "Bad example for Detecting accessibility settings. Widgets layer.",
      "Defect: On iOS, Reduce Motion is shown as off.",
    ],
  ]

  static let keys = ["navigation", "bold", "contrast", "invert", "animations", "labels", "dark", "scale"]

  /// The settings lines with nothing changed and `navigation` for
  /// accessible navigation.
  static func lines(navigation: String = "off", contrast: String = "off") -> [String] {
    [
      "Accessible navigation: \(navigation)", "Bold text: off", "High contrast: \(contrast)",
      "Invert colours: off", "Disable animations: off", "Switch labels: off", "Dark mode: off",
      "Text scale: 100%",
    ]
  }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.screens[slug]![0]), file: file, line: line)
  }

  /// Opens `slug` by its address in the app that is running, without
  /// starting it again: a setting it was told stays as it is.
  private func openInPlace(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    app.open(URL(string: "fluttera11y:///t/V12/\(slug)")!)
    XCTAssertTrue(element(labelled: Self.screens[slug]![0]).waitForExistence(timeout: 30),
                  "\(slug) did not open in place", file: file, line: line)
  }

  private func line(_ slug: String, _ key: String) -> String { element("v12-\(slug)-\(key)").label }

  private func lines(_ slug: String) -> [String] { Self.keys.map { line(slug, $0) } }

  /// Waits up to `seconds` for the line `key` of `slug` to say `want`.
  private func expectLine(_ slug: String, _ key: String, _ want: String, seconds: Double = 8,
                          file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(seconds)
    while self.line(slug, key) != want && Date() < deadline { usleep(200_000) }
    XCTAssertEqual(self.line(slug, key), want, "\(slug) \(key)", file: file, line: line)
  }

  /// Checks, every 200 ms for `seconds`, that the line `key` of `slug`
  /// still says `want`.
  private func expectLineStays(_ slug: String, _ key: String, _ want: String, seconds: Double = 4,
                               file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(seconds)
    repeat {
      XCTAssertEqual(self.line(slug, key), want, "\(slug) \(key)", file: file, line: line)
      usleep(200_000)
    } while Date() < deadline
  }

  // --- The simulator's Settings app ---------------------------------------

  /// Opens Settings at its top and taps through `path`.
  private func openSettings(_ path: [String]) -> Bool {
    settings.terminate()
    settings.launch()
    for item in path {
      let cell = settings.descendants(matching: .any).matching(
        NSPredicate(format: "label == %@ AND (elementType == %d OR elementType == %d)",
                    item, XCUIElement.ElementType.cell.rawValue, XCUIElement.ElementType.button.rawValue)
      ).firstMatch
      var tries = 0
      while !(cell.exists && cell.isHittable) && tries < 10 {
        settings.swipeUp()
        tries += 1
      }
      guard cell.exists else { return false }
      cell.tap()
      usleep(800_000)
    }
    return true
  }

  private func settingSwitch(_ name: String) -> XCUIElement {
    let sw = settings.switches[name]
    var tries = 0
    while !(sw.exists && sw.isHittable) && tries < 10 {
      settings.swipeUp()
      tries += 1
    }
    return sw
  }

  /// Sets the switch `name` under `path` to `on`, tapping its toggle until
  /// it reads so, at most four taps (in the probe a tap sometimes did not
  /// take); returns whether it does.
  @discardableResult
  private func setSwitch(_ path: [String], _ name: String, _ on: Bool) -> Bool {
    let want = on ? "1" : "0"
    guard openSettings(path) else { return false }
    var tries = 0
    while (settingSwitch(name).value as? String) != want && tries < 4 {
      settingSwitch(name).coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
      usleep(2_500_000)
      tries += 1
    }
    let now = settingSwitch(name).value as? String
    print("V12 switch \(name) now \(now ?? "?") after \(tries) taps")
    return now == want
  }

  static let display = ["Accessibility", "Display & Text Size"]
  static let motion = ["Accessibility", "Motion"]

  /// The value the switch `name` under `path` reads now, "1" or "0"; nil
  /// when the switch cannot be found.
  private func readSwitch(_ path: [String], _ name: String) -> String? {
    guard openSettings(path) else { return nil }
    let sw = settingSwitch(name)
    return sw.exists ? sw.value as? String : nil
  }

  /// Reads the switch `name` under `path` and keeps its value, and before
  /// anything is changed registers a teardown block that puts that value
  /// back and checks it, however the test ends. Then sets the switch to
  /// off, the baseline, and checks it reads off. Returns whether both the
  /// reading and the baseline took; the test stops checking if not.
  private func savedThenOff(_ path: [String], _ name: String) -> Bool {
    guard let original = readSwitch(path, name) else {
      XCTFail("\(name): its switch could not be read")
      return false
    }
    print("V12 switch \(name) was \(original) before the test")
    addTeardownBlock { [self] in
      let back = self.setSwitch(path, name, original == "1")
      XCTAssertTrue(back, "\(name) not put back to \(original)")
      XCTAssertEqual(self.readSwitch(path, name), original, "\(name) put back to \(original)")
      self.settings.terminate()
    }
    guard setSwitch(path, name, false) else {
      XCTFail("\(name) could not be set off for the baseline")
      return false
    }
    settings.terminate()
    return true
  }

  /// Turns the switch on and checks it reads on, then brings the app back.
  private func turnOn(_ path: [String], _ name: String) -> Bool {
    let on = setSwitch(path, name, true)
    XCTAssertTrue(on, "\(name) could not be turned on")
    app.activate()
    return on
  }

  /// Turns the switch off and checks it reads off, then brings the app back.
  private func turnOff(_ path: [String], _ name: String) {
    XCTAssertTrue(setSwitch(path, name, false), "\(name) could not be turned off")
    app.activate()
  }

  // --- L3: the tree ---------------------------------------------------------

  func testListsSayWhatTheAppWasToldWhenItOpens() {
    for slug in ["good-media-query", "bad-read-once"] {
      open(slug)
      XCTAssertEqual(lines(slug), Self.lines(), slug)
    }
    for slug in ["good-motion", "bad-animations-only"] {
      open(slug)
      XCTAssertEqual(line(slug, "motion"), "Reduce motion: off", slug)
    }
  }

  /// VoiceOver's state is read first and put back afterwards, checked, and
  /// the test starts from a checked off baseline (voiceOverOffBaseline);
  /// each turn is checked on the service's own state and on the line.
  func testVoiceOverTurnedOnReachesGoodMediaQueryAndNotBadReadOnce() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    try voiceOverOffBaseline(voiceOver)
    open("good-media-query")
    expectLine("good-media-query", "navigation", "Accessible navigation: off")
    try VoiceOverState.set(voiceOver, on: true)
    expectLine("good-media-query", "navigation", "Accessible navigation: on")
    try VoiceOverState.set(voiceOver, on: false)
    expectLine("good-media-query", "navigation", "Accessible navigation: off")
    // bad-read-once: opened with VoiceOver off, it keeps "off" with
    // VoiceOver on. The witness, in the same running app: good-media-query
    // opened by its address says "on".
    open("bad-read-once")
    expectLine("bad-read-once", "navigation", "Accessible navigation: off")
    try VoiceOverState.set(voiceOver, on: true)
    expectLineStays("bad-read-once", "navigation", "Accessible navigation: off")
    XCTAssertEqual(lines("bad-read-once"), Self.lines())
    openInPlace("good-media-query")
    expectLine("good-media-query", "navigation", "Accessible navigation: on")
    try VoiceOverState.set(voiceOver, on: false)
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  /// VoiceOver found on is put back on: turned on first, as on a device
  /// where the user has it on; the test's own baseline reads "on", sets it
  /// off, and its teardown block, which runs first, must put it back on and
  /// read it on; the outer one then puts back the state the simulator had.
  /// A walk made from the baseline (VoiceOverState.withOn) turns it on and
  /// puts it back off.
  func testVoiceOverFoundOnIsPutBackOn() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    try voiceOverOffBaseline(voiceOver)
    try VoiceOverState.set(voiceOver, on: true)
    XCTAssertTrue(try voiceOverOffBaseline(voiceOver), "found on")
    XCTAssertFalse(voiceOver.isEnabled, "the baseline")
    open("good-media-query")
    expectLine("good-media-query", "navigation", "Accessible navigation: off")
    let seen = try VoiceOverState.withOn(voiceOver) { voiceOver.isEnabled }
    XCTAssertTrue(seen, "on during the walk")
    XCTAssertFalse(voiceOver.isEnabled, "the walk put it back off")
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  /// Increase Contrast from a checked off baseline: on, and good-media-query
  /// follows (the switch reads on and the line changes); off, and it
  /// follows back. Then bad-read-once, opened at the baseline, keeps "off"
  /// with the switch on, and good-media-query, opened in the same running
  /// app, says on: the witness that the setting reached the app. The
  /// switch's value before the test is put back after it and checked.
  func testIncreaseContrastReachesGoodMediaQueryAndNotBadReadOnce() {
    let name = "Increase Contrast"
    guard savedThenOff(Self.display, name) else { return }
    open("good-media-query")
    XCTAssertEqual(lines("good-media-query"), Self.lines(), "the baseline, every line off")
    guard turnOn(Self.display, name) else { return }
    expectLine("good-media-query", "contrast", "High contrast: on")
    XCTAssertEqual(lines("good-media-query"), Self.lines(contrast: "on"))
    turnOff(Self.display, name)
    expectLine("good-media-query", "contrast", "High contrast: off")
    open("bad-read-once")
    XCTAssertEqual(lines("bad-read-once"), Self.lines(), "the baseline, every line off")
    guard turnOn(Self.display, name) else { return }
    expectLineStays("bad-read-once", "contrast", "High contrast: off")
    openInPlace("good-media-query")
    expectLine("good-media-query", "contrast", "High contrast: on")
    turnOff(Self.display, name)
    expectLine("good-media-query", "contrast", "High contrast: off")
  }

  /// bad-animations-only's defect: iOS's Reduce Motion sets reduceMotion
  /// and never disableAnimations (the engine's AccessibilityFeatures.swift,
  /// read; measured in the probe), so a line from disableAnimations alone
  /// stays off. From a checked off baseline, each example shown "off"
  /// first; then Reduce Motion on (the switch reads on): bad-animations-only
  /// stays off, and good-motion, opened in the same running app, says on,
  /// which shows the setting reached the app; then off, and good-motion
  /// follows back. The switch's value before the test is put back.
  func testReduceMotionReachesGoodMotionAndNotBadAnimationsOnly() {
    let name = "Reduce Motion"
    guard savedThenOff(Self.motion, name) else { return }
    open("good-motion")
    expectLine("good-motion", "motion", "Reduce motion: off")
    open("bad-animations-only")
    expectLine("bad-animations-only", "motion", "Reduce motion: off")
    guard turnOn(Self.motion, name) else { return }
    expectLineStays("bad-animations-only", "motion", "Reduce motion: off")
    openInPlace("good-motion")
    expectLine("good-motion", "motion", "Reduce motion: on")
    turnOff(Self.motion, name)
    expectLine("good-motion", "motion", "Reduce motion: off")
  }

  /// A switch found on before a test is put back on. The device's own value
  /// is kept first (savedThenOff, whose teardown block puts it back and
  /// runs last); then Reduce Motion is turned on, as on a device where the
  /// user has it on, and a second savedThenOff keeps "1", sets the off
  /// baseline, and good-motion shows the change from off to on and back.
  /// Its teardown block, which runs first, must put the switch back on and
  /// read it on; the outer one then puts back the device's own value.
  func testASwitchFoundOnIsPutBackOn() {
    let name = "Reduce Motion"
    guard savedThenOff(Self.motion, name) else { return }
    XCTAssertTrue(setSwitch(Self.motion, name, true), "\(name) could not be turned on")
    XCTAssertEqual(readSwitch(Self.motion, name), "1", "found on")
    guard savedThenOff(Self.motion, name) else { return }
    XCTAssertEqual(readSwitch(Self.motion, name), "0", "the baseline")
    settings.terminate()
    open("good-motion")
    expectLine("good-motion", "motion", "Reduce motion: off")
    guard turnOn(Self.motion, name) else { return }
    expectLine("good-motion", "motion", "Reduce motion: on")
    turnOff(Self.motion, name)
    expectLine("good-motion", "motion", "Reduce motion: off")
  }

  /// A setting that is on when the example opens: Reduce Motion turned on
  /// from the off baseline before the app starts. good-motion opens saying
  /// on and bad-animations-only off (its defect, at the start as well);
  /// turned off, good-motion follows. The switch's value before the test
  /// is put back.
  func testReduceMotionOnWhenTheExampleOpens() {
    let name = "Reduce Motion"
    guard savedThenOff(Self.motion, name) else { return }
    XCTAssertTrue(setSwitch(Self.motion, name, true), "\(name) could not be turned on")
    settings.terminate()
    open("bad-animations-only")
    expectLineStays("bad-animations-only", "motion", "Reduce motion: off")
    open("good-motion")
    expectLine("good-motion", "motion", "Reduce motion: on")
    turnOff(Self.motion, name)
    expectLine("good-motion", "motion", "Reduce motion: off")
  }

  // --- L4: VoiceOver --------------------------------------------------------

  // Everything VoiceOver says from the top of the screen to its end
  // (V12Walk), judged whole: the screen's own stops first, which tie the
  // walk to this example, then the example's lines. VoiceOver is turned on
  // after the screen has opened, so good-media-query, which reads its
  // settings again, says accessible navigation is on, and bad-read-once,
  // which read them once as it opened, says off.
  struct Speech {
    let slug: String
    /// What VoiceOver says above the "Example" heading.
    let screen: [String]
    /// What it says after the heading, to the end of the screen.
    let content: [String]
    /// The stops of `screen`, by index, that the service gives cut: the
    /// screen's description line, which the app writes from the
    /// technique's title ("Good example for Detecting accessibility
    /// settings. Widgets layer.", 65 characters). XCUIVoiceOverService
    /// returns the first 64 characters of an utterance, so such a stop is
    /// judged as exactly its first 64 characters; what comes after them
    /// (the good description's final full stop) is not judged. Every other
    /// expected utterance must be under 64 characters.
    var cut: Set<Int> = [1]

    /// What the service can return for stop `i` of `screen`.
    func heard(_ i: Int) -> String { cut.contains(i) ? String(screen[i].prefix(64)) : screen[i] }

    /// `screen` as the service can return it.
    var heardScreen: [String] { screen.indices.map(heard) }
  }

  /// The stops above the "Example" heading, with it: the title, the
  /// screen's lines, and the heading.
  static func screenStops(_ slug: String) -> [String] {
    let lines = screens[slug]!
    return ["\(lines[0]) Heading"] + lines.dropFirst() + ["Example Heading"]
  }

  static let speech: [Speech] = [
    Speech(slug: "good-media-query", screen: screenStops("good-media-query"), content: lines(navigation: "on")),
    Speech(slug: "good-motion", screen: screenStops("good-motion"), content: ["Reduce motion: off"]),
    Speech(slug: "bad-read-once", screen: screenStops("bad-read-once"), content: lines(navigation: "off")),
    Speech(slug: "bad-animations-only", screen: screenStops("bad-animations-only"), content: ["Reduce motion: off"]),
  ]

  func testExpectedUtterancesAreShortEnough() {
    for example in Self.speech {
      for (i, utterance) in example.screen.enumerated() where !example.cut.contains(i) {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \"\(utterance)\" is longer than VoiceOver's service returns")
      }
      for utterance in example.content {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \"\(utterance)\" is longer than VoiceOver's service returns")
      }
      // A cut stop is the description line, at most 64 characters as heard.
      XCTAssertEqual(example.cut, [1], example.slug)
      XCTAssertTrue(example.heard(1).hasSuffix("example for Detecting accessibility settings. Widgets layer")
                    || example.heard(1).hasSuffix("example for Detecting accessibility settings. Widgets layer."), example.slug)
    }
    // The good description is cut by one character, the bad one is whole.
    XCTAssertEqual(Self.speech[0].heard(1), "Good example for Detecting accessibility settings. Widgets layer")
    XCTAssertEqual(Self.speech[2].heard(1), "Bad example for Detecting accessibility settings. Widgets layer.")
  }

  func testTheJudgeRefusesALongExpectedUtterance() {
    let long = Speech(slug: "good-motion", screen: Self.screenStops("good-motion"),
                      content: [String(repeating: "x", count: 64)])
    XCTAssertFalse(V12Walk.judge(long.heardScreen + long.content, reachedEnd: true, long).isEmpty)
    // A long title, not a stop the service cuts, is refused as well.
    var title = Self.screenStops("good-motion")
    title[0] = String(repeating: "y", count: 70)
    let longTitle = Speech(slug: "good-motion", screen: title, content: ["Reduce motion: off"])
    XCTAssertFalse(V12Walk.judge(longTitle.heardScreen + longTitle.content, reachedEnd: true, longTitle).isEmpty)
  }

  func testTheJudgeTiesAWalkToItsScreen() {
    // Made-up walks: the judge must refuse another example's screen, a
    // missing or empty identification, a wrong or missing stop.
    let good = Self.speech[0]
    let right = good.heardScreen + good.content
    var offLine = good.content
    offLine[0] = "Accessible navigation: off"
    let cases: [(String, [String], Bool, Bool)] = [
      ("the whole screen", right, true, true),
      ("the walk did not reach the end", right, false, false),
      ("another example's screen", Self.speech[2].heardScreen + good.content, true, false),
      ("no title", Array(good.heardScreen.dropFirst()) + good.content, true, false),
      ("an empty title", [""] + good.heardScreen.dropFirst() + good.content, true, false),
      ("the description whole, which the service cannot give", good.screen + good.content, true, false),
      ("the description cut shorter", [good.screen[0], String(good.screen[1].prefix(60))] + good.heardScreen.dropFirst(2) + good.content, true, false),
      ("no stops before the heading", ["Example Heading"] + good.content, true, false),
      ("accessible navigation read off", good.heardScreen + offLine, true, false),
      ("a line missing", good.heardScreen + good.content.dropLast(), true, false),
      ("two lines swapped", good.heardScreen + [good.content[1], good.content[0]] + good.content.dropFirst(2), true, false),
      ("a stop after the end", right + ["Extra"], true, false),
      ("nothing after the heading", good.heardScreen, true, false),
    ]
    for (what, stops, reachedEnd, ok) in cases {
      XCTAssertEqual(V12Walk.judge(stops, reachedEnd: reachedEnd, good).isEmpty, ok, what)
    }
  }

  func testTheCollectorFailsADuplicateStopAndAnUnwitnessedEnd() {
    // Made-up walks of good-media-query's screen. `moves` is what each move
    // forward reads, `back` and `again` what the end's witness reads.
    let walk = Self.speech[0].heardScreen + Self.speech[0].content
    func run(_ moves: [String], back: String, again: String) -> V12Walk.Result {
      var i = 0
      return V12Walk.collect(
        next: { defer { i += 1 }; return i < moves.count ? moves[i] : moves.last! },
        back: { back }, forward: { again })
    }
    let last = walk.last!, before = walk[walk.count - 2]
    let cases: [(String, V12Walk.Result, Bool)] = [
      ("the whole screen, then the last twice, the witness right",
       run(walk + [last, last], back: before, again: last), true),
      ("a duplicate title read in the middle of the walk",
       run([walk[0], walk[0]] + walk.dropFirst() + [last, last], back: before, again: last), false),
      ("a duplicate stop after the heading",
       run(Array(walk.prefix(4)) + [walk[3]] + walk.dropFirst(4) + [last, last], back: before, again: last), false),
      ("stale speech at the end: the move back reads the last again",
       run(walk + [last, last], back: last, again: last), false),
      ("the end's move back reads another element",
       run(walk + [last, last], back: walk[0], again: last), false),
      ("the end's move forward again reads something else",
       run(walk + [last, last], back: before, again: "Extra"), false),
      ("a walk that runs out of moves", V12Walk.collect(max: 3, next: { "x\(Int.random(in: 0..<1_000_000))" }, back: { "" }, forward: { "" }), false),
    ]
    for (what, result, whole) in cases {
      XCTAssertEqual(result.reachedEnd && result.problem == nil, whole, "\(what): \(result)")
    }
    // The whole walk keeps every stop once, and a judged walk of it is right.
    let right = run(walk + [last, last], back: before, again: last)
    XCTAssertEqual(right.stops, walk)
    XCTAssertEqual(V12Walk.judge(right.stops, reachedEnd: right.reachedEnd, Self.speech[0]), [])
    // The duplicate title is kept, and the judge would fail it as well.
    let dup = run([walk[0], walk[0]] + walk.dropFirst() + [last, last], back: before, again: last)
    XCTAssertEqual(dup.stops, [walk[0], walk[1]])
  }

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    for example in Self.speech {
      for utterance in example.heardScreen + example.content where utterance.count > 64 {
        XCTFail("\(example.slug): \"\(utterance)\" is more than 64 characters, which the service cannot return")
        return
      }
    }
    let voiceOver = XCUIDevice.shared.voiceOverService
    // VoiceOver's state read first and put back after, checked; each walk
    // starts from the off baseline, turns it on, and puts it back off.
    try voiceOverOffBaseline(voiceOver)
    for example in Self.speech {
      open(example.slug)
      let walk = try V12Walk.walk(voiceOver)
      let problems = (walk.problem.map { [$0] } ?? []) + V12Walk.judge(walk.stops, reachedEnd: walk.reachedEnd, example)
      let heading = walk.stops.map(VoiceOverWalk.normalized).lastIndex { $0.hasPrefix("Example ") }
      let shown = problems.isEmpty
        ? Array(walk.stops[(heading! + 1)...]).map(VoiceOverWalk.normalized)
        : walk.stops.map { $0.debugDescription }
      print("V12VO \(example.slug) | \(shown.joined(separator: " / "))")
      for p in problems { XCTFail("\(example.slug): \(p)") }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}

/// V12's VoiceOver walk: S16Walk (S16LanguagePagePartsUITests.swift),
/// copied whole, with V12's judge. From the top of the screen to its end,
/// keeping each utterance as the service gave it, and judging how it ended.
///
/// A move that reads the same words as the stop before it is one of two
/// things: the cursor did not move, at the last element, or a second
/// element read alike (or speech the service gave again while nothing new
/// was said, as `currentSpeech()` does). The words cannot tell them apart,
/// so the collector does not count a repeat as the end by itself:
///
/// - A repeat followed by a different utterance is a stop read twice in a
///   row mid-screen, and the walk fails ("a duplicate stop"); it is never
///   dropped. No V12 screen has two neighbouring elements that read alike,
///   so a real screen never needs one.
/// - Two repeats in a row end the walk only with a witness that the cursor
///   is on the last element: one move back must read the stop before the
///   last, and one move forward again the last. A second element that
///   reads like the last, or speech given again with the cursor elsewhere,
///   reads something else there, and the walk fails ("the end is not
///   shown"). What the witness cannot show: that the move forward from the
///   last element did not go past it to an element the service reads with
///   no speech; that case is the no-speech error, handled as
///   VoiceOverWalk.forward does (afterNoSpeech), which records it as a stop.
/// - A walk that runs out of moves is not at its end.
enum V12Walk {
  struct Result: Equatable {
    var stops: [String]
    var reachedEnd: Bool
    /// Why the walk is not a whole walk to the end, or nil.
    var problem: String?
  }

  /// Collects a walk from `next` (one move forward, its raw utterance),
  /// with `back` and `forward` (one move back, one move forward, each its
  /// raw utterance) as the end's witness; at most `max` moves.
  static func collect(
    max: Int = 24, next: () throws -> String, back: () throws -> String, forward: () throws -> String
  ) rethrows -> Result {
    var stops: [String] = []
    var repeats = 0
    for _ in 0..<max {
      let utterance = try next()
      let said = VoiceOverWalk.normalized(utterance)
      let last = stops.last.map(VoiceOverWalk.normalized)
      if said == last {
        repeats += 1
        guard repeats == 2 else { continue }
        guard stops.count >= 2 else {
          return Result(stops: stops, reachedEnd: false, problem: "the end is not shown: the walk read one stop only")
        }
        let before = VoiceOverWalk.normalized(stops[stops.count - 2])
        let movedBack = VoiceOverWalk.normalized(try back())
        let movedOn = VoiceOverWalk.normalized(try forward())
        if movedBack == before && movedOn == said {
          return Result(stops: stops, reachedEnd: true, problem: nil)
        }
        return Result(
          stops: stops, reachedEnd: false,
          problem: "the end is not shown: \"\(said)\" came again, but a move back read \"\(movedBack)\" and a move forward \"\(movedOn)\", where \"\(before)\" and \"\(said)\" were expected")
      }
      if repeats == 1, let last {
        return Result(
          stops: stops + [utterance], reachedEnd: false,
          problem: "a duplicate stop: \"\(last)\" was read twice in a row, then \"\(said)\"")
      }
      repeats = 0
      stops.append(utterance)
    }
    return Result(stops: stops, reachedEnd: false, problem: "the walk ran out of moves")
  }

  /// What is wrong with a walk of `example`; empty when it is right. The
  /// walk must have reached the end; its stops up to and including the
  /// last "Example" heading must be exactly the example's screen stops,
  /// which ties it to this example's screen; and the stops after it
  /// exactly the example's content, each normalized. An expected utterance
  /// of 64 characters or more is refused: the service returns no more.
  static func judge(_ stops: [String], reachedEnd: Bool, _ example: V12AccessibilitySettingsUITests.Speech) -> [String] {
    var problems: [String] = []
    for (i, utterance) in example.screen.enumerated() where !example.cut.contains(i) && utterance.count >= 64 {
      problems.append("\"\(utterance)\" is 64 characters or more, which the service cannot return whole")
    }
    for utterance in example.content where utterance.count >= 64 {
      problems.append("\"\(utterance)\" is 64 characters or more, which the service cannot return whole")
    }
    if !reachedEnd { problems.append("the walk did not reach the end of the screen") }
    let normal = stops.map(VoiceOverWalk.normalized)
    let lastHeading = example.screen.last!
    guard let heading = normal.lastIndex(of: lastHeading) else {
      return problems + ["no \"\(lastHeading)\" stop: \(normal)"]
    }
    let screen = Array(normal[...heading])
    if screen != example.heardScreen {
      problems.append("the screen's own stops were \(screen), not \(example.heardScreen): not this example's screen")
    }
    let content = Array(normal[(heading + 1)...])
    if content != example.content {
      problems.append("after the heading: \(content), where \(example.content) was expected")
    }
    return problems
  }

  #if compiler(>=6.4)
  /// Switches VoiceOver on, walks to the end of the screen (collect), and
  /// puts back the state it found, checked (VoiceOverState.withOn): a
  /// failed restore fails the walk, whether the walk itself passed or not.
  /// A move with no speech is handled as VoiceOverWalk.forward does
  /// (afterNoSpeech).
  @available(iOS 27.0, *)
  static func walk(_ voiceOver: XCUIVoiceOverService) throws -> Result {
    try VoiceOverState.withOn(voiceOver) { try walkOn(voiceOver) }
  }

  @available(iOS 27.0, *)
  private static func walkOn(_ voiceOver: XCUIVoiceOverService) throws -> Result {
    var previous: String? = nil
    return try collect(
      next: {
        let utterance: String
        do {
          utterance = try voiceOver.moveForward().utterance
        } catch let error as NSError where VoiceOverWalk.isNoSpeech(error) {
          let back = VoiceOverWalk.normalized(try voiceOver.moveBackward().utterance)
          var again: String? = nil
          do {
            again = try voiceOver.moveForward().utterance
          } catch let error as NSError where VoiceOverWalk.isNoSpeech(error) {}
          utterance = VoiceOverWalk.afterNoSpeech(
            previous: previous.map(VoiceOverWalk.normalized), back: back, again: again)
        }
        previous = utterance
        return utterance
      },
      back: { try voiceOver.moveBackward().utterance },
      forward: { try voiceOver.moveForward().utterance })
  }
  #endif
}
