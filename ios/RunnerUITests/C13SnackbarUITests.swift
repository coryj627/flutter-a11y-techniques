// L3 (tree) and L4 (VoiceOver) for C13 Snackbar and transient messages on
// iOS. Spec: docs/specs/C13-snackbar.md.
//
// XCUITest cannot read whether an element is a live region, nor Flutter's
// keyboard focus: a Tab is shown to have reached a control by what Return
// then does there. Keys are sent with no modifier (Tab and Return), as
// modifier keys were unreliable on CI's iOS 26.5 (docs/waves/wave-4.md);
// Escape is checked in the widget tests and on the web and Android only.
import XCTest

final class C13SnackbarUITests: XCTestCase, TechniqueUITest {
  static let technique = "C13"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  static let message = [
    "good-action": "Message archived",
    "good-message": "Draft saved",
    "good-banner": "You are offline.",
    "bad-action-times-out": "Message archived",
    "bad-only-in-message": "Booked. Code: K7Q2",
    "bad-inline-banner": "You are offline.",
  ]

  static let line = [
    "good-action": ("Archived: 0", "Archived: 1"),
    "good-message": ("Drafts saved: 0", "Drafts saved: 1"),
    "good-banner": ("Status: online", "Status: offline"),
    "bad-action-times-out": ("Archived: 0", "Archived: 1"),
    "bad-only-in-message": ("Bookings: 0", "Bookings: 1"),
    "bad-inline-banner": ("Status: online", "Status: offline"),
  ]

  static let button = [
    "good-action": "Archive message",
    "good-message": "Save draft",
    "good-banner": "Go offline",
    "bad-action-times-out": "Archive message",
    "bad-only-in-message": "Book a table",
    "bad-inline-banner": "Go offline",
  ]

  private func show(_ slug: String) -> XCUIElement { element("c13-\(slug)-show") }
  private func lineElement(_ slug: String) -> XCUIElement { element("c13-\(slug)-count") }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: show(slug), settle: 500_000, file: file, line: line)
  }

  /// Waits up to `seconds` for the line of `slug` to read `text`.
  private func expectLine(_ slug: String, _ text: String, _ seconds: TimeInterval = 5,
                          file: StaticString = #filePath, line: UInt = #line) {
    let e = lineElement(slug)
    let end = Date().addingTimeInterval(seconds)
    while e.label != text && Date() < end { usleep(100_000) }
    XCTAssertEqual(e.label, text, slug, file: file, line: line)
  }

  /// The element labelled with the example's message, which exists while
  /// it is shown.
  private func messageElement(_ slug: String) -> XCUIElement { element(labelled: Self.message[slug]!) }

  /// Taps the example's button and waits for its line and its message.
  private func press(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    show(slug).tap()
    expectLine(slug, Self.line[slug]!.1, file: file, line: line)
    XCTAssertTrue(messageElement(slug).waitForExistence(timeout: 5), "\(slug): message shown", file: file, line: line)
  }

  /// Waits until the message has gone, at most `max` seconds; how long it took, or nil.
  private func goneAfter(_ slug: String, _ max: TimeInterval) -> TimeInterval? {
    let start = Date()
    while Date().timeIntervalSince(start) < max {
      if !messageElement(slug).exists { return Date().timeIntervalSince(start) }
      usleep(100_000)
    }
    return nil
  }

  private func key(_ k: String) {
    app.typeKey(k, modifierFlags: [])
    usleep(700_000)
  }

  private static let tab = XCUIKeyboardKey.tab.rawValue
  private static let enter = "\n"

  func testEachMessageIsShownWithItsWordsAndItsButtons() {
    for slug in ["good-action", "good-message", "good-banner", "bad-action-times-out", "bad-only-in-message", "bad-inline-banner"] {
      open(slug)
      XCTAssertFalse(messageElement(slug).exists, "\(slug): no message before")
      press(slug)
      XCTAssertEqual(elements(labelled: Self.message[slug]!).count, 1, "\(slug): the message once")
    }
    open("good-action")
    press("good-action")
    for name in ["Undo", "Close"] {
      let b = app.buttons[name]
      XCTAssertTrue(b.exists, name)
    }
    open("good-banner")
    press("good-banner")
    XCTAssertTrue(app.buttons["Go online"].exists)
  }

  func testTheMessagesWithAnActionStay() {
    for slug in ["good-action", "good-banner"] {
      open(slug)
      press(slug)
      XCTAssertNil(goneAfter(slug, 10), "\(slug): still shown 10 s later")
    }
  }

  func testTimedMessagesGoAndOnlyGoodMessageLeavesItsNewsOnThePage() {
    for slug in ["good-message", "bad-action-times-out", "bad-only-in-message"] {
      open(slug)
      press(slug)
      let gone = goneAfter(slug, 12)
      XCTAssertNotNil(gone, "\(slug): gone")
      if let gone { XCTAssertLessThan(gone, 6, "\(slug): gone within 6 s of being seen") }
      XCTAssertEqual(lineElement(slug).label, Self.line[slug]!.1, slug)
    }
    // bad-action-times-out: Undo went with it.
    XCTAssertFalse(app.buttons["Undo"].exists)
    // bad-only-in-message: the code is nowhere on the screen.
    let code = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "K7Q2"))
    XCTAssertEqual(code.count, 0)
  }

  /// Tabs `n` times from where a fresh example leaves keyboard focus (on no
  /// control: the first Tab goes to Back).
  private func tabs(_ n: Int) {
    for _ in 0..<n { key(Self.tab) }
  }

  /// After the show, Tab goes Back, the page's button, Undo, Close
  /// (C13_TABS); Return on the third undoes, and on the fourth closes and
  /// undoes nothing. Return shows where each Tab went.
  func testTabReachesUndoAndCloseAndReturnActs() {
    open("good-action")
    press("good-action")
    tabs(C13Tabs.toUndo)
    key(Self.enter)
    expectLine("good-action", "Archived: 0")
    XCTAssertNotNil(goneAfter("good-action", 3), "gone after Undo")

    open("good-action")
    press("good-action")
    tabs(C13Tabs.toClose)
    key(Self.enter)
    XCTAssertNotNil(goneAfter("good-action", 3), "gone after Close")
    XCTAssertEqual(lineElement("good-action").label, "Archived: 1", "Close undoes nothing")
  }

  /// What an action did, back on the page's line, is told by a SnackBar of
  /// its own, which goes after its four seconds and leaves the line. (That
  /// it is a live region is read on Android, the web, and in the widget
  /// tests, and heard in testVoiceOverSpeech.)
  func testWhatAnActionDidIsToldAndGoes() {
    for (slug, action, said) in [
      ("good-action", "Undo", "Archive undone"),
      ("good-banner", "Go online", "You are online."),
      ("bad-action-times-out", "Undo", "Archive undone"),
      ("bad-inline-banner", "Go online", "You are online."),
    ] {
      open(slug)
      press(slug)
      app.buttons[action].tap()
      expectLine(slug, Self.line[slug]!.0)
      let told = element(labelled: said)
      XCTAssertTrue(told.waitForExistence(timeout: 5), "\(slug): \(said) shown")
      let end = Date().addingTimeInterval(8)
      while told.exists && Date() < end { usleep(100_000) }
      XCTAssertFalse(told.exists, "\(slug): \(said) gone")
      XCTAssertEqual(lineElement(slug).label, Self.line[slug]!.0, slug)
    }
  }

  func testTabReachesTheBannersGoOnline() {
    open("good-banner")
    press("good-banner")
    tabs(C13Tabs.toGoOnline)
    key(Self.enter)
    expectLine("good-banner", "Status: online")
    XCTAssertNotNil(goneAfter("good-banner", 3), "gone after Go online")
  }

  // L4. What VoiceOver says once each example's message is shown.
  //
  // With VoiceOver on, XCUIElement.tap() moves the VoiceOver cursor to the
  // button, and doubleTap() acts on what is under the tap, the button (C04
  // probe, round 3); VoiceOver's own activation, a double tap anywhere, was
  // not measured. The message must then be on screen and the line changed,
  // so that silence cannot mean the button did nothing. Then
  // currentSpeech() is read until the message is heard, or for six seconds
  // when nothing should be said; then one move back and one forward must
  // land on the button again, so that the message was announced and not
  // reached by a moved cursor. For the messages that stay, the cursor then
  // moves forward from the button until the last utterance repeats.
  private let announced: [(slug: String, said: Bool)] = [
    ("good-action", true),
    ("good-message", true),
    ("good-banner", true),
    ("bad-action-times-out", true),
    ("bad-only-in-message", true),
    // FL-295: a banner put in the page is not announced.
    ("bad-inline-banner", false),
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    func current() -> String {
      VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? "")
    }
    func waitForSpeech(_ seconds: TimeInterval, until done: (String) -> Bool) -> String {
      let deadline = Date().addingTimeInterval(seconds)
      var last = current()
      while !done(last) && Date() < deadline {
        usleep(250_000)
        last = current()
      }
      return last
    }
    for (slug, said) in announced {
      open(slug)
      try voiceOver.enable()
      defer { try? voiceOver.disable() }
      let buttonSpeech = "\(Self.button[slug]!) Button"
      var before = ""
      for _ in 0..<5 {
        show(slug).tap()
        before = waitForSpeech(4) { $0 == buttonSpeech }
        if before == buttonSpeech { break }
      }
      XCTAssertEqual(before, buttonSpeech, "\(slug): cursor is not on the button")
      show(slug).doubleTap()
      expectLine(slug, Self.line[slug]!.1)
      XCTAssertTrue(messageElement(slug).waitForExistence(timeout: 5), "\(slug): the message is shown")
      let message = Self.message[slug]!
      let after: String
      if said {
        after = waitForSpeech(8) { $0 == message }
        XCTAssertEqual(after, message, "\(slug): the message was not announced")
      } else {
        after = waitForSpeech(6) { $0 != buttonSpeech }
        XCTAssertEqual(after, buttonSpeech, "\(slug): something was announced")
      }
      _ = try? voiceOver.moveBackward()
      let returned = VoiceOverWalk.normalized((try? voiceOver.moveForward().utterance) ?? "")
      XCTAssertEqual(returned, buttonSpeech, "\(slug): the VoiceOver cursor left the button")
      var walk: [String] = []
      if let expected = C13Walks.forward[slug] {
        for _ in 0..<(expected.count + 2) {
          let s = VoiceOverWalk.normalized((try? voiceOver.moveForward().utterance) ?? VoiceOverWalk.silent)
          if walk.last == s { break }
          walk.append(s)
        }
        XCTAssertEqual(walk, expected, "\(slug): the moves forward from the button")
      }
      // What the message's action did, announced: the cursor on the action
      // with tap(), doubleTap() at it, and the SnackBar that tells it heard.
      // For bad-inline-banner this is also the positive control of its
      // silence, in the same launch.
      var done = ""
      if let (action, said) = C13Walks.done[slug] {
        let button = app.buttons[action]
        let actionSpeech = "\(action) Button"
        var on = ""
        for _ in 0..<5 {
          button.tap()
          on = waitForSpeech(4) { $0 == actionSpeech }
          if on == actionSpeech { break }
        }
        XCTAssertEqual(on, actionSpeech, "\(slug): cursor is not on \(action)")
        button.doubleTap()
        expectLine(slug, Self.line[slug]!.0)
        done = waitForSpeech(8) { $0 == said }
        XCTAssertEqual(done, said, "\(slug): \(action)'s result was not announced")
        done = " / \(on) / (tap at it) / \(done)"
      }
      print("C13VO \(slug) | \(before) / (tap at it) / \(after) / (back, forward) / \(returned)"
        + (walk.isEmpty ? "" : " / " + walk.joined(separator: " / ")) + done)
      try voiceOver.disable()
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}

/// How many Tabs, from a freshly opened example with its message shown,
/// reach each control (the C13 probe, docs/evidence/probes/c13/ios.txt).
enum C13Tabs {
  static let toUndo = 3
  static let toClose = 4
  static let toGoOnline = 2
}

/// What VoiceOver says moving forward from the example's button, once its
/// message is shown, to where the last utterance repeats.
enum C13Walks {
  static let forward: [String: [String]] = [
    "good-action": ["Archived: 1", "Message archived", "Undo Button", "Close Button"],
    "good-banner": ["Status: offline"],
    "bad-inline-banner": ["Status: offline", "You are offline.", "Go online Button"],
  ]

  /// The action pressed after the walk, and what must then be heard.
  static let done: [String: (String, String)] = [
    "good-action": ("Undo", "Archive undone"),
    "good-banner": ("Go online", "You are online."),
    "bad-inline-banner": ("Go online", "You are online."),
  ]
}
