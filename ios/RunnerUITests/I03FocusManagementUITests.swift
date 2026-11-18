// L3 (tree and keyboard) and L4 (VoiceOver) for I03 Focus management on
// iOS.
// Spec: docs/specs/I03-focus-management.md.
//
// The keyboard is driven with XCUIElement.typeKey; Tab and Space reach
// Flutter, and Enter is typed as "\n" (docs/evidence/probes/i01/README.md).
// XCUITest does not see where Flutter's keyboard focus is, so every stop is
// named by what Space does there: on a Remove button it asks about that
// trail ("Remove Lake loop?" appears), on Cancel it closes the question
// with the count unchanged, on the question's Remove it removes the trail
// (the count goes down), and on Back it leaves the screen.
import XCTest

final class I03FocusManagementUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "I03"
  static let countLabel = "Saved"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = false
  }

  private static let good = ["good-material", "good-cupertino", "good-widgets"]
  private static let all = good + ["bad-focus-left-behind", "bad-opens-on-focus"]
  /// The examples whose question is opened by pressing a Remove button.
  private static let pressToAsk = good + ["bad-focus-left-behind"]
  private static let trails = [
    ("remove-ridge", "Ridge trail"), ("remove-lake", "Lake loop"), ("remove-summit", "Summit path"),
  ]
  /// Tabs from where Enter on Remove Lake loop leaves focus to the
  /// question's Cancel. The Material dialog and the action sheet put focus
  /// on their own scope, so Tab goes to their first control: Cancel in the
  /// dialog, Remove and then Cancel in the sheet. The general dialog puts
  /// focus on Cancel itself.
  private static let tabsToCancel = ["good-material": 1, "good-cupertino": 2, "good-widgets": 0]
  /// The same to the question's Remove.
  private static let tabsToConfirm = ["good-material": 2, "good-cupertino": 1, "good-widgets": 1]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private func control(_ slug: String, _ part: String) -> XCUIElement { element("i03-\(slug)-\(part)") }

  private func question(_ name: String) -> XCUIElement { element(labelled: "Remove \(name)?") }

  /// Whether any question is on the screen.
  private func asking() -> Bool {
    app.descendants(matching: .any).matching(NSPredicate(format: "label ENDSWITH '?'")).count > 0
  }

  private static let enter = "\n"
  private static let space = XCUIKeyboardKey.space.rawValue
  private static let tab = XCUIKeyboardKey.tab.rawValue

  private func press(_ key: String, times: Int = 1) {
    for _ in 0..<times {
      app.typeKey(key, modifierFlags: [])
      usleep(700_000)
    }
  }

  private func expectQuestion(
    _ name: String, _ shown: Bool = true, _ context: String,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let predicate = NSPredicate(format: shown ? "exists == true" : "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: question(name))
    XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                   "\(context): \"Remove \(name)?\" \(shown ? "did not appear" : "did not go")",
                   file: file, line: line)
  }

  /// Expects focus to be on Back: Space there leaves the screen.
  private func expectBack(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    press(Self.space)
    let gone = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: gone, object: countElement(slug))
    XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                   "\(slug): Space did not leave the screen, so focus was not on Back", file: file, line: line)
  }

  /// Opens `slug` and presses Tab `n` times: Back, then the Remove buttons
  /// in order.
  private func openAndTab(_ slug: String, _ n: Int) {
    open(slug)
    press(Self.tab, times: n)
  }

  func testEveryExampleHasItsButtonsAndCount() {
    for slug in Self.all {
      open(slug)
      for (part, name) in Self.trails {
        XCTAssertEqual(control(slug, part).label, "Remove \(name)", "\(slug) \(part)")
        XCTAssertEqual(control(slug, part).elementType, .button, "\(slug) \(part)")
      }
      expectCount(slug, 3)
    }
  }

  // 3.2.1. For each Remove button: Tab to it asks nothing, and Space there
  // asks about that trail, which names the stop and is the positive control.
  func testTabOntoEachRemoveButtonAsksNothing() {
    for slug in Self.pressToAsk {
      for (index, (_, name)) in Self.trails.enumerated() {
        openAndTab(slug, index + 2)
        sleep(1)
        XCTAssertFalse(asking(), "\(slug): Tab onto Remove \(name) asked")
        press(Self.space)
        expectQuestion(name, true, "\(slug): Space on the stop")
      }
    }
  }

  // The defect. Written to fail when focus no longer opens the question.
  func testBadOpensOnFocusAsksWhenTabReachesAButton() {
    let slug = "bad-opens-on-focus"
    openAndTab(slug, 1)
    sleep(1)
    XCTAssertFalse(asking(), "Tab onto Back asked")
    press(Self.tab)
    expectQuestion("Ridge trail", true, "Tab onto Remove Ridge trail, no other key")
    // The question's first control is Cancel: Space closes it, count unchanged.
    press(Self.tab)
    press(Self.space)
    expectQuestion("Ridge trail", false, "Space on Cancel")
    expectCount(slug, 3)
    // Focus is back on Remove Ridge trail, which does not ask again; Tab
    // to the next button asks about it.
    sleep(1)
    XCTAssertFalse(asking(), "focus coming back asked again")
    press(Self.tab)
    expectQuestion("Lake loop", true, "Tab onto Remove Lake loop")
  }

  /// Opens `slug`, tabs to Remove Lake loop, and presses Enter.
  private func askAboutLake(_ slug: String) {
    openAndTab(slug, 3)
    press(Self.enter)
    expectQuestion("Lake loop", true, "\(slug): Enter on Remove Lake loop")
  }

  func testCancelPutsFocusBackOnTheButton() {
    for slug in Self.good {
      askAboutLake(slug)
      press(Self.tab, times: Self.tabsToCancel[slug]!)
      press(Self.space)
      expectQuestion("Lake loop", false, "\(slug): Space on Cancel")
      expectCount(slug, 3)
      // Space asks about Lake loop again: focus is back on its button.
      press(Self.space)
      expectQuestion("Lake loop", true, "\(slug): Space after Cancel")
    }
  }

  func testRemovePutsFocusOnTheNextButton() {
    for slug in Self.good {
      askAboutLake(slug)
      press(Self.tab, times: Self.tabsToConfirm[slug]!)
      press(Self.space)
      expectCount(slug, 2)
      XCTAssertFalse(control(slug, "remove-lake").exists, slug)
      // Space asks about Summit path: focus is on its button.
      press(Self.space)
      expectQuestion("Summit path", true, "\(slug): Space after Remove")
    }
  }

  // The defect. Focus stays on Remove Lake loop behind the question; the
  // first Tab goes to Remove Summit path behind it, which Space there shows.
  // Written to fail when the question starts to take focus.
  func testBadFocusLeftBehindTabGoesBehindTheQuestion() {
    let slug = "bad-focus-left-behind"
    askAboutLake(slug)
    press(Self.tab)
    press(Self.space)
    expectQuestion("Summit path", true, "Space after one Tab")
  }

  // The same defect on the way out: Cancel is reached only by Tab past the
  // end of the screen, and then focus does not come back. Space after
  // Cancel does nothing, and the next Tab is Back. Written to fail when
  // focus comes back to Remove Lake loop.
  func testBadFocusLeftBehindCancelLeavesFocusOnNoControl() {
    let slug = "bad-focus-left-behind"
    askAboutLake(slug)
    // Remove Summit path behind the question, then Cancel.
    press(Self.tab, times: 2)
    press(Self.space)
    expectQuestion("Lake loop", false, "Space on Cancel")
    expectCount(slug, 3)
    press(Self.space)
    sleep(1)
    XCTAssertFalse(asking(), "Space after Cancel asked: focus was on a Remove button")
    press(Self.tab)
    expectBack(slug)
  }

  // L4. With VoiceOver on, tap() moves its cursor and doubleTap()
  // activates, as a person does. After each activation the test reads what
  // VoiceOver said (currentSpeech()) and where its cursor is: one move back
  // and one forward again, which must land where it was. The cursor is
  // never put anywhere by the test after an activation, so where it is was
  // VoiceOver's own move, or the app's.
  #if compiler(>=6.4)
  @available(iOS 27.0, *)
  private func said(_ voiceOver: XCUIVoiceOverService) -> String {
    VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? VoiceOverWalk.silent)
  }

  /// What VoiceOver reads one move back, and then one move forward again.
  @available(iOS 27.0, *)
  private func around(_ voiceOver: XCUIVoiceOverService) -> (String, String) {
    let back = VoiceOverWalk.normalized((try? voiceOver.moveBackward().utterance) ?? VoiceOverWalk.silent)
    let again = VoiceOverWalk.normalized((try? voiceOver.moveForward().utterance) ?? VoiceOverWalk.silent)
    return (back, again)
  }

  /// Polls currentSpeech() for up to `seconds` until it starts with `prefix`.
  @available(iOS 27.0, *)
  private func waitForSpeech(_ voiceOver: XCUIVoiceOverService, startingWith prefix: String, _ seconds: Double = 6) -> String {
    let deadline = Date().addingTimeInterval(seconds)
    var now = said(voiceOver)
    while !now.hasPrefix(prefix) && Date() < deadline {
      usleep(250_000)
      now = said(voiceOver)
    }
    return now
  }

  @available(iOS 27.0, *)
  private func activate(_ element: XCUIElement) {
    element.tap()
    sleep(2)
    element.doubleTap()
  }
  #endif

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for slug in Self.pressToAsk {
      open(slug)
      try voiceOver.enable()
      defer { try? voiceOver.disable() }
      sleep(2)
      activate(control(slug, "remove-lake"))
      let opened = waitForSpeech(voiceOver, startingWith: "Remove Lake loop?")
      activate(control(slug, "cancel"))
      let cancelled = waitForSpeech(voiceOver, startingWith: "Remove Lake loop Button")
      let (beforeLake, lakeAgain) = around(voiceOver)
      activate(control(slug, "remove-lake"))
      _ = waitForSpeech(voiceOver, startingWith: "Remove Lake loop?")
      activate(control(slug, "confirm"))
      let removed = waitForSpeech(voiceOver, startingWith: "Remove Summit path Button")
      let (beforeSummit, summitAgain) = around(voiceOver)
      try voiceOver.disable()
      print("I03VO \(slug) | opened: \(opened) / cancelled: \(cancelled) (back: \(beforeLake), forward: \(lakeAgain)) / removed: \(removed) (back: \(beforeSummit), forward: \(summitAgain))")
      // Into the question: its title, or its message if VoiceOver starts
      // there.
      XCTAssertTrue(opened.hasPrefix("Remove Lake loop?") || opened.hasPrefix("It goes from your saved trails"),
                    "\(slug): VoiceOver did not go into the question: \(opened)")
      XCTAssertEqual(cancelled, "Remove Lake loop Button", "\(slug): after Cancel")
      XCTAssertEqual(beforeLake, "Remove Ridge trail Button", "\(slug): the cursor is not on Remove Lake loop")
      XCTAssertEqual(lakeAgain, "Remove Lake loop Button", slug)
      XCTAssertEqual(removed, "Remove Summit path Button", "\(slug): after Remove")
      XCTAssertEqual(beforeSummit, "Remove Ridge trail Button", "\(slug): the cursor is not on Remove Summit path")
      XCTAssertEqual(summitAgain, "Remove Summit path Button", slug)
    }
    // VoiceOver's cursor is not keyboard focus: putting it on a Remove
    // button of bad-opens-on-focus asks nothing.
    let slug = "bad-opens-on-focus"
    open(slug)
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    sleep(2)
    control(slug, "remove-ridge").tap()
    let ridge = waitForSpeech(voiceOver, startingWith: "Remove Ridge trail")
    sleep(2)
    let asked = asking()
    try voiceOver.disable()
    print("I03VO \(slug) | cursor on Remove Ridge trail: \(ridge) / asked: \(asked)")
    XCTAssertEqual(ridge, "Remove Ridge trail Button", slug)
    XCTAssertFalse(asked, "\(slug): VoiceOver's cursor on Remove Ridge trail asked")
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
