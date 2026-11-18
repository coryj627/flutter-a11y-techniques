// L3 (tree) and L4 (VoiceOver) for F06 Error identification and
// announcement on iOS. Spec: docs/specs/F06-error-identification.md.
import XCTest

private let nameError = "Enter your name."
private let emailError = "Enter an email address with an @, like name@example.com."

final class F06ErrorIdentificationUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "F06"
  static let countLabel = "Sent"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private func send(_ slug: String) {
    element("f06-\(slug)-send").tap()
  }

  private func hasKeyboardFocus(_ id: String) -> Bool {
    (element(id).value(forKey: "hasKeyboardFocus") as? Bool) ?? false
  }

  private func describe(_ id: String) -> String {
    let e = element(id)
    return "id=\(id) type=\(e.elementType.rawValue) label='\(e.label)' value='\(e.value as? String ?? "nil")'"
  }

  private let good: [(slug: String, fields: [(id: String, name: String, error: String)])] = [
    ("good-form", [("f06-good-form-name", "Name", nameError), ("f06-good-form-email", "Email", emailError)]),
    ("good-cupertino", [("f06-good-cupertino-name", "Name", nameError), ("f06-good-cupertino-email", "Email", emailError)]),
  ]

  // L3. XCUITest cannot read an element's hint or whether something is a
  // live region; the hint is checked in VoiceOver's speech below.
  func testGoodFieldsKeepTheirNameAndShowTheirErrors() {
    for example in good {
      open(example.slug)
      for field in example.fields {
        XCTAssertEqual(element(field.id).elementType, .textField, field.id)
        XCTAssertEqual(element(field.id).label, field.name, field.id)
      }
      send(example.slug)
      XCTAssertTrue(element(labelled: nameError).waitForExistence(timeout: 5), example.slug)
      for field in example.fields {
        print("F06TREE \(describe(field.id))")
        // The error is not part of the name: it is its own text.
        XCTAssertEqual(element(field.id).label, field.name, field.id)
        XCTAssertEqual(element(labelled: field.error).elementType, .staticText, field.error)
      }
      // Keyboard focus is on the first field in error.
      XCTAssertTrue(hasKeyboardFocus(example.fields[0].id), "\(example.slug): first field focused")
      XCTAssertFalse(hasKeyboardFocus(example.fields[1].id), "\(example.slug): second field not focused")
      expectCount(example.slug, 0)
    }
  }

  func testGoodFormsAreSentOnceRight() {
    for example in good {
      open(example.slug)
      let name = element(example.fields[0].id)
      let email = element(example.fields[1].id)
      name.tap()
      name.typeText("Ana")
      email.tap()
      email.typeText("ana@example.com\n")
      send(example.slug)
      expectCount(example.slug, 1)
      XCTAssertFalse(element(labelled: nameError).exists, example.slug)
      XCTAssertFalse(element(labelled: emailError).exists, example.slug)
    }
  }

  // VAL-3: each bad example is asserted to have its named defect.

  func testBadColorOnlyAddsNoText() {
    open("bad-color-only")
    let before = Set(app.staticTexts.allElementsBoundByIndex.map(\.label))
    send("bad-color-only")
    XCTAssertTrue(hasKeyboardFocus("f06-bad-color-only-email") || {
      sleep(2); return self.hasKeyboardFocus("f06-bad-color-only-email")
    }(), "the form was sent: focus went to the field")
    XCTAssertEqual(Set(app.staticTexts.allElementsBoundByIndex.map(\.label)), before)
    XCTAssertEqual(element("f06-bad-color-only-email").label, "Email")
  }

  func testBadVagueMessageSaysOnlyInvalid() {
    open("bad-vague-message")
    send("bad-vague-message")
    XCTAssertTrue(element(labelled: "Invalid.").waitForExistence(timeout: 5))
  }

  func testBadNotAnnouncedShowsTheErrorWithFocusLeftOnSend() {
    open("bad-not-announced")
    send("bad-not-announced")
    XCTAssertTrue(element(labelled: emailError).waitForExistence(timeout: 5))
    XCTAssertFalse(hasKeyboardFocus("f06-bad-not-announced-email"))
  }

  func testBadMergedErrorPutsTheErrorInTheName() {
    open("bad-merged-error")
    send("bad-merged-error")
    let id = "f06-bad-merged-error-email"
    let deadline = Date().addingTimeInterval(5)
    while element(id).label == "Email" && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(element(id).label, "Email\n\(emailError)")
    XCTAssertFalse(element(labelled: emailError).exists, "no separate error text")
  }

  // L4. For each example: the VoiceOver cursor is put on Send, Send is
  // activated with a double tap, and every new utterance is collected for
  // eight seconds. Then the cursor is moved forward once and back once,
  // which reads the element it was on. XCUIVoiceOverService gives the first
  // 64 characters of an utterance, so phrases are matched as prefixes.
  //
  // `heard`: what must be among the utterances after activation (empty for
  // nothing); `quiet`: text that must not be in any of them; `cursor`: the
  // start of what the cursor is on afterwards.
  private let speech: [(slug: String, heard: [String], quiet: [String], cursor: String)] = [
    ("good-form", ["Name Text field \(nameError)"], [], "Name Text field \(nameError)"),
    ("good-cupertino", ["Name Text field \(nameError)"], [], "Name Text field \(nameError)"),
    // Focus goes to the field, which has nothing to say about the error.
    ("bad-color-only", ["Email Text field"], ["Enter", "Invalid"], "Email Text field"),
    ("bad-vague-message", ["Email Text field Invalid."], [], "Email Text field Invalid."),
    // Nothing is said, and the cursor stays on Send.
    ("bad-not-announced", [], ["Enter an email"], "Send Button"),
    // The error is in the name and again as the hint.
    ("bad-merged-error", ["Email \(emailError)"], [], "Email Enter an email"),
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    func norm(_ s: String) -> String { VoiceOverWalk.normalized(s) }
    func current() -> String { norm((try? voiceOver.currentSpeech().utterance) ?? "") }
    func starts(_ utterance: String, _ phrase: String) -> Bool {
      // A cut utterance is a prefix of the phrase; a whole one starts with it.
      utterance.hasPrefix(phrase) || (utterance.count >= 60 && phrase.hasPrefix(utterance))
    }
    for example in speech {
      open(example.slug)
      try voiceOver.enable()
      defer { try? voiceOver.disable() }
      let sendButton = element("f06-\(example.slug)-send")
      var before = ""
      for _ in 0..<5 {
        sendButton.tap()
        let deadline = Date().addingTimeInterval(4)
        before = current()
        while before != "Send Button" && Date() < deadline { usleep(250_000); before = current() }
        if before == "Send Button" { break }
      }
      XCTAssertEqual(before, "Send Button", "\(example.slug): cursor is not on Send")
      sendButton.doubleTap()
      var heard: [String] = []
      let end = Date().addingTimeInterval(8)
      while Date() < end {
        let now = current()
        if now != (heard.last ?? before) { heard.append(now) }
        usleep(200_000)
      }
      // Send acted: the example's error text, or for bad-color-only the
      // field's red outline, is on screen. Silence cannot pass without it.
      if example.slug == "bad-color-only" {
        XCTAssertTrue(hasKeyboardFocus("f06-bad-color-only-email"), "bad-color-only: Send did not act")
      } else if example.slug == "bad-merged-error" {
        XCTAssertNotEqual(element("f06-bad-merged-error-email").label, "Email", "bad-merged-error: Send did not act")
      } else {
        let shown = example.slug == "bad-vague-message" ? "Invalid." : (example.slug == "bad-not-announced" ? emailError : nameError)
        XCTAssertTrue(element(labelled: shown).exists, "\(example.slug): Send did not act")
      }
      // Where the cursor is: one move forward and one back reads it. The
      // move also proves that speech capture is live.
      let forward = norm((try? voiceOver.moveForward().utterance) ?? "")
      let back = norm((try? voiceOver.moveBackward().utterance) ?? "")
      print("F06VO \(example.slug) | on Send: \(before) / after activation: \(heard.joined(separator: " / ")) / forward: \(forward) / back: \(back)")
      XCTAssertFalse(forward.isEmpty || back.isEmpty, "\(example.slug): capture is not live")
      for phrase in example.heard {
        XCTAssertTrue(heard.contains { starts($0, phrase) }, "\(example.slug): expected \"\(phrase)\" in \(heard)")
      }
      if example.heard.isEmpty {
        XCTAssertTrue(heard.isEmpty, "\(example.slug): expected nothing, heard \(heard)")
      }
      for phrase in example.quiet {
        XCTAssertFalse(heard.contains { $0.contains(phrase) }, "\(example.slug): did not expect \"\(phrase)\" in \(heard)")
      }
      XCTAssertTrue(starts(back, example.cursor), "\(example.slug): cursor on \"\(back)\", expected \"\(example.cursor)\"")
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
