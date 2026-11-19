// L3 (tree and keyboard) and L4 (VoiceOver) for I04 Keyboard actions and
// shortcuts on iOS.
// Spec: docs/specs/I04-keyboard-actions.md.
//
// Keys are sent with XCUIElement.typeKey, which the simulator delivers as
// a hardware keyboard's (docs/evidence/probes/i01/README.md); Enter is
// typed as "\n". Letters are typed one typeKey at a time: typeText reached
// the field as text without key events, past every shortcut, like an
// on-screen keyboard (docs/evidence/probes/i04/README.md). XCUITest cannot
// see Flutter's keyboard focus, so each stop is named by what a key does
// there: an arrow on a thumbnail shows another photo, Space on the
// favourite button changes the favourites, a letter in the note is typed,
// and Space on Back leaves the screen. Home, End, Page Up, and Page Down
// sent this way never reached Flutter in the probe, so they are not tested
// here.
//
// Shift is used only where it is what a test is about (Shift+F). Typed
// text is lower case, and moves back to the strip go forward round with
// Tab; Shift+Tab is in the web and Android tests. On CI (Xcode 26.6, iOS
// 26.5, CI run 44502528898) a capital typed with typeKey("M") arrived as
// "m", in two tests; and after Tab and Shift+Tab from the strip, Left did
// nothing, as if focus had not come back to the strip. Locally, with the
// text in lower case, letters typed into bad-page-shortcut's note were now
// and then lost besides its f (see typeInNote). None of these causes was
// established. So text goes into the note through typeInNote, which waits
// for each letter.
import XCTest

final class I04KeyboardActionsUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "I04"
  static let countLabel = "Notes saved"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private static let good = ["good-on-focus", "good-turn-off", "good-remap"]
  private static let all = good + ["bad-page-shortcut", "bad-no-arrow-keys"]
  /// The strip answers the arrow keys in these.
  private static let stripKeys = good + ["bad-page-shortcut"]
  private static let withSetting = ["good-turn-off", "good-remap"]
  private static let photos = ["Trailhead", "Bridge", "Ridge", "Summit"]

  private static let tab = XCUIKeyboardKey.tab.rawValue
  private static let space = XCUIKeyboardKey.space.rawValue
  private static let right = XCUIKeyboardKey.rightArrow.rawValue
  private static let left = XCUIKeyboardKey.leftArrow.rawValue
  private static let enter = "\n"

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: part(slug, "trailhead"), file: file, line: line)
  }

  private func part(_ slug: String, _ name: String) -> XCUIElement { element("i04-\(slug)-\(name)") }

  private func press(_ key: String, _ flags: XCUIElement.KeyModifierFlags = []) {
    app.typeKey(key, modifierFlags: flags)
    usleep(600_000)
  }

  /// Types `text` one key at a time, as a hardware keyboard does.
  private func type(_ text: String) {
    for ch in text { press(String(ch)) }
  }

  /// Types `text` into the note one key at a time, waiting after each
  /// key until the note shows it. A letter that does not appear within 2
  /// seconds is logged and sent again, at most three times in all; a
  /// letter in `lost` is the one a shortcut takes, so after it the note
  /// must stay as it was for a second, and it is never sent again. Locally
  /// a letter typed into bad-page-shortcut's note was sometimes lost
  /// besides the f (round two: "ea" for "lea", "ud" for "mud", "mudy" for
  /// "muddy"), and in no other example; the cause was not found, so the
  /// tests wait for each letter instead of reading once at the end. If
  /// focus is not on the note, nothing appears and the test fails.
  private func typeInNote(_ slug: String, _ text: String, lost: Set<Character> = [],
                          file: StaticString = #filePath, line: UInt = #line) {
    var expected = note(slug)
    for ch in text {
      if lost.contains(ch) {
        press(String(ch))
        expectStays("\(slug) note after \(ch)", expected, { self.note(slug) }, file: file, line: line)
        continue
      }
      let want = expected + String(ch)
      for attempt in 1...3 {
        press(String(ch))
        let deadline = Date().addingTimeInterval(2)
        while note(slug) != want && Date() < deadline { usleep(100_000) }
        if note(slug) == want { break }
        print("I04KEYS \(slug): \"\(ch)\" did not reach the note (attempt \(attempt)); it shows \"\(note(slug))\"")
      }
      XCTAssertEqual(note(slug), want, "\(slug): typing \"\(text)\"", file: file, line: line)
      expected = note(slug)
    }
  }

  private func waitFor(_ what: String, _ expected: String, _ read: () -> String,
                       file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(2)
    while read() != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(read(), expected, what, file: file, line: line)
  }

  private func expectShowing(_ slug: String, _ photo: String, file: StaticString = #filePath, line: UInt = #line) {
    let n = Self.photos.firstIndex(of: photo)! + 1
    waitFor("\(slug) showing", "Showing: \(photo), \(n) of 4", { self.part(slug, "showing").label }, file: file, line: line)
  }

  private func expectFavourites(_ slug: String, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
    waitFor("\(slug) favourites", "Favourites: \(text)", { self.part(slug, "favourites").label }, file: file, line: line)
  }

  private func expectStays(_ what: String, _ expected: String, _ read: () -> String,
                           file: StaticString = #filePath, line: UInt = #line) {
    sleep(1)
    XCTAssertEqual(read(), expected, what, file: file, line: line)
  }

  private func note(_ slug: String) -> String {
    let field = part(slug, "note")
    let value = field.value as? String ?? ""
    return value == field.placeholderValue ? "" : value
  }

  /// Waits up to 5 seconds for the example to leave the screen, as Back does.
  private func expectScreenLeft(_ slug: String, _ why: String, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while countElement(slug).exists && Date() < deadline { usleep(100_000) }
    XCTAssertFalse(countElement(slug).exists, why, file: file, line: line)
  }

  // On a freshly opened example the first Tab puts focus on Back and the
  // second on the strip's stop, the thumbnail of the photo shown (I02).
  private func tabToStrip() {
    press(Self.tab)
    press(Self.tab)
  }

  func testEveryPartHasItsLabelAndType() {
    for slug in Self.all {
      open(slug)
      XCTAssertEqual(part(slug, "showing").label, "Showing: Trailhead, 1 of 4", slug)
      for (i, photo) in Self.photos.enumerated() {
        let thumb = part(slug, photo.lowercased())
        XCTAssertEqual(thumb.label, photo, slug)
        XCTAssertEqual(thumb.elementType, .button, "\(slug) \(photo)")
        XCTAssertEqual(thumb.isSelected, i == 0, "\(slug) \(photo) selected")
      }
      XCTAssertEqual(part(slug, "favourite").label, "Add to favourites", slug)
      XCTAssertEqual(part(slug, "favourite").elementType, .button, slug)
      XCTAssertEqual(part(slug, "note").elementType, .textField, slug)
      XCTAssertTrue(part(slug, "note").label.contains("Note"), "\(slug): \(part(slug, "note").label)")
      XCTAssertEqual(part(slug, "favourites").label, "Favourites: none", slug)
      expectCount(slug, 0)
    }
  }

  func testATapShowsAnyPhoto() {
    for slug in Self.all {
      open(slug)
      part(slug, "ridge").tap()
      expectShowing(slug, "Ridge")
      XCTAssertTrue(part(slug, "ridge").isSelected, slug)
    }
  }

  func testTabGoesTheStripTheFavouriteButtonThenTheNote() {
    for slug in Self.all {
      open(slug)
      // Back, then the strip: an arrow there moves along it, except in
      // bad-no-arrow-keys, where F there acts instead.
      tabToStrip()
      if slug == "bad-no-arrow-keys" {
        press("f")
        expectFavourites(slug, "Trailhead")
        press("f")
        expectFavourites(slug, "none")
      } else {
        press(Self.right)
        expectShowing(slug, "Bridge")
      }
      // The favourite button: Space changes the favourites.
      press(Self.tab)
      press(Self.space)
      expectFavourites(slug, slug == "bad-no-arrow-keys" ? "Trailhead" : "Bridge")
      if Self.withSetting.contains(slug) {
        // The setting: Space changes the switch.
        let before = part(slug, "setting").value as? String
        press(Self.tab)
        press(Self.space)
        waitFor("\(slug) setting", before == "1" ? "0" : "1", { self.part(slug, "setting").value as? String ?? "" })
        press(Self.space)
      }
      // The note: a letter is typed.
      press(Self.tab)
      typeInNote(slug, "mud")
      waitFor("\(slug) note", "mud", { self.note(slug) })
    }
  }

  func testTheStripsArrowsShowAPhotoAndMoveFocusWithIt() {
    for slug in Self.stripKeys {
      open(slug)
      tabToStrip()
      for (key, photo) in [(Self.right, "Bridge"), (Self.right, "Ridge"), (Self.left, "Bridge"),
                           (Self.right, "Ridge"), (Self.right, "Summit"), (Self.right, "Summit"),
                           (Self.left, "Ridge")] {
        press(key)
        expectShowing(slug, photo)
      }
      // Focus moved with the photo: going on with Tab, round past the note
      // and Back, comes back to the strip at Ridge, where Left goes on.
      for _ in 0..<(Self.withSetting.contains(slug) ? 4 : 3) { press(Self.tab) }
      press(Self.tab)
      press(Self.left)
      expectShowing(slug, "Bridge")
    }
  }

  /// bad-no-arrow-keys, one arrow per launch. With Bridge shown (a tap),
  /// a tap on the note gives it focus: there the arrow moves the caret, so
  /// it arrives and acts. Two Tabs go on, round past Back, to the strip's
  /// stop: there F acts, so keys reach the strip, and the same arrow then
  /// does not move along it. Where focus goes after it is not asserted: an
  /// arrow the strip leaves alone is the app's default, directional focus.
  /// (A tap on a thumbnail also puts keyboard focus on it, so Tabs counted
  /// from the top would not reach the note; the note is tapped instead.)
  private func badNoArrowKeysIgnores(_ key: String, _ name: String) {
    let slug = "bad-no-arrow-keys"
    open(slug)
    part(slug, "bridge").tap()
    expectShowing(slug, "Bridge")
    part(slug, "note").tap()
    usleep(800_000)
    typeInNote(slug, "mud")
    press(Self.left)
    if key == Self.right { press(Self.right) }
    type("x")
    waitFor("\(slug) note", key == Self.right ? "mudx" : "muxd", { self.note(slug) })
    press(Self.tab)
    press(Self.tab)
    press("f")
    expectFavourites(slug, "Bridge")
    press(key)
    expectStays("\(slug) showing after \(name)", "Showing: Bridge, 2 of 4", { self.part(slug, "showing").label })
  }

  func testBadNoArrowKeysRightDoesNotMove() { badNoArrowKeysIgnores(Self.right, "Right") }
  func testBadNoArrowKeysLeftDoesNotMove() { badNoArrowKeysIgnores(Self.left, "Left") }

  func testBadNoArrowKeysTheStopAfterTheStripIsTheFavouriteButton() {
    let slug = "bad-no-arrow-keys"
    open(slug)
    // Three Tabs: Back, Trailhead, then the next stop. Space there changes
    // the favourites, so it is the favourite button and not Bridge.
    tabToStrip()
    press(Self.tab)
    press(Self.space)
    expectFavourites(slug, "Trailhead")
    expectShowing(slug, "Trailhead")
  }

  func testEnterInTheNoteSavesItAndTheNextTabStartsFromTheTop() {
    for slug in Self.all {
      open(slug)
      tabToStrip()
      press(Self.tab)
      if Self.withSetting.contains(slug) { press(Self.tab) }
      press(Self.tab)
      typeInNote(slug, "muddy")
      waitFor("\(slug) note", "muddy", { self.note(slug) })
      // iOS can still be composing the word (it autocorrected "ab" to "an"
      // on Enter in the probe); a pause lets that settle first.
      sleep(1)
      press(Self.enter)
      expectCount(slug, 1)
      waitFor("\(slug) note after Enter", "", { self.note(slug) })
      // FL-461: focus left the field for no control. A letter typed now
      // goes nowhere, though the field took "Muddy" a moment ago, and the
      // next Tab goes to Back, where Space leaves the screen.
      press("x")
      expectStays("\(slug) note after a letter", "", { self.note(slug) })
      press(Self.tab)
      press(Self.space)
      expectScreenLeft(slug, "Tab after Enter did not land on Back")
    }
  }

  func testGoodOnFocusFActsInTheStripOnly() {
    let slug = "good-on-focus"
    open(slug)
    tabToStrip()
    press("f")
    expectFavourites(slug, "Trailhead")
    press(Self.tab)
    press("f")
    expectStays("\(slug) favourites after F on the button", "Favourites: Trailhead", { self.part(slug, "favourites").label })
    // The control: Space on the same button acts.
    press(Self.space)
    expectFavourites(slug, "none")
    press(Self.tab)
    typeInNote(slug, "leafy")
    waitFor("\(slug) note", "leafy", { self.note(slug) })
    XCTAssertEqual(part(slug, "favourites").label, "Favourites: none")
  }

  func testAPageWideFActsWhereverFocusIsAndTypesInTheNote() {
    for slug in ["good-turn-off", "good-remap"] {
      open(slug)
      tabToStrip()
      press("f")
      expectFavourites(slug, "Trailhead")
      press(Self.right)
      press(Self.tab)
      press("f")
      expectFavourites(slug, "Trailhead, Bridge")
      press(Self.tab)
      press("f")
      expectFavourites(slug, "Trailhead")
      press(Self.tab)
      typeInNote(slug, "leafy")
      waitFor("\(slug) note", "leafy", { self.note(slug) })
      XCTAssertEqual(part(slug, "favourites").label, "Favourites: Trailhead", slug)
    }
  }

  func testGoodTurnOffTheSwitchTurnsFOff() {
    let slug = "good-turn-off"
    open(slug)
    XCTAssertEqual(part(slug, "setting").value as? String, "1")
    tabToStrip()
    press(Self.tab)
    press(Self.tab)
    press(Self.space)
    waitFor("switch", "0", { self.part(slug, "setting").value as? String ?? "" })
    press("f")
    expectStays("favourites after F on the switch", "Favourites: none", { self.part(slug, "favourites").label })
    // On to the strip by Tab (note, Back, then the strip), not Shift+Tab.
    for _ in 0..<3 { press(Self.tab) }
    press("f")
    expectStays("favourites after F on the strip", "Favourites: none", { self.part(slug, "favourites").label })
    // The keys arrive: the strip's own keys still act.
    press(Self.right)
    expectShowing(slug, "Bridge")
    // The control: on again, the same key acts.
    press(Self.tab)
    press(Self.tab)
    press(Self.space)
    waitFor("switch", "1", { self.part(slug, "setting").value as? String ?? "" })
    press("f")
    expectFavourites(slug, "Bridge")
  }

  func testGoodRemapTheSwitchMovesFToControlF() {
    let slug = "good-remap"
    open(slug)
    tabToStrip()
    press(Self.tab)
    press(Self.tab)
    press("f", .control)
    expectStays("favourites after Control+F while the key is F", "Favourites: none", { self.part(slug, "favourites").label })
    press(Self.space)
    waitFor("switch", "1", { self.part(slug, "setting").value as? String ?? "" })
    press("f")
    expectStays("favourites after F", "Favourites: none", { self.part(slug, "favourites").label })
    press("f", .control)
    expectFavourites(slug, "Trailhead")
  }

  func testBadPageShortcutFActsWhereverFocusIsAndTakesTheFOfTheNote() {
    let slug = "bad-page-shortcut"
    open(slug)
    tabToStrip()
    press("f")
    expectFavourites(slug, "Trailhead")
    press(Self.tab)
    press("f")
    expectFavourites(slug, "none")
    press(Self.tab)
    typeInNote(slug, "leafy", lost: ["f"])
    waitFor("\(slug) note", "leay", { self.note(slug) })
    expectFavourites(slug, "Trailhead")
    XCTAssertFalse(part(slug, "setting").exists)
  }

  // What the lost letter leaves: other keyboard ways to put an f in the
  // note, each after a plain f has been shown to be lost in the same
  // launch. Shift+F types a capital, which CharacterActivator('f') does not
  // match; an f pasted with Command+V goes in through the text field's own
  // paste; and typeText, the way an on-screen keyboard's text arrives,
  // never meets the shortcut at all (docs/evidence/probes/i04/README.md).
  private func badPageNoteLosesItsF(_ slug: String) {
    open(slug)
    tabToStrip()
    press(Self.tab)
    press(Self.tab)
    typeInNote(slug, "lea")
    press("f")
    waitFor("\(slug) note after f", "lea", { self.note(slug) })
    expectFavourites(slug, "Trailhead")
  }

  func testBadPageShortcutShiftFTypesACapitalF() {
    let slug = "bad-page-shortcut"
    badPageNoteLosesItsF(slug)
    press("f", .shift)
    waitFor("\(slug) note after Shift+F", "leaF", { self.note(slug) })
    expectFavourites(slug, "Trailhead")
  }

  func testBadPageShortcutAnFPastedWithCommandVGoesIn() {
    let slug = "bad-page-shortcut"
    UIPasteboard.general.string = "f"
    badPageNoteLosesItsF(slug)
    press("v", .command)
    // iOS may ask whether the app may paste what another app copied.
    let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow Paste"]
    if allow.waitForExistence(timeout: 2) {
      print("I04KEYS paste: iOS asked to allow the paste")
      allow.tap()
    }
    waitFor("\(slug) note after Command+V", "leaf", { self.note(slug) })
    expectFavourites(slug, "Trailhead")
  }

  func testBadPageShortcutTypeTextPutsTheFIn() {
    let slug = "bad-page-shortcut"
    badPageNoteLosesItsF(slug)
    app.typeText("f")
    waitFor("\(slug) note after typeText", "leaf", { self.note(slug) })
    expectFavourites(slug, "Trailhead")
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // count of notes saved, the last element of every example. The keys are
  // not heard: every example's strip reads the same. The API cuts each
  // utterance at 64 characters, so the expected ones are cut the same way.
  private static let hintGood = "In the photos: Left and Right arrows for the previous and next photo, Home and End for the first and last, F to add or remove a favourite."
  private static let hintPage = "In the photos: Left and Right arrows for the previous and next photo, Home and End for the first and last. Anywhere here: F to add or remove a favourite."
  private static func content(_ hint: String, setting: [String] = []) -> [String] {
    (["Showing: Trailhead, 1 of 4", hint, "selected Trailhead Button", "Bridge Button", "Ridge Button",
      "Summit Button", "Add to favourites Button"] + setting
      + ["Note Text field Double tap to edit.", "Favourites: none"]).map { String($0.prefix(64)) }
  }
  private let speech: [(slug: String, content: [String])] = [
    ("good-on-focus", content(hintGood)),
    ("good-turn-off", content(hintPage, setting: ["Single-key shortcuts Switch button on Double tap to toggle setting."])),
    ("good-remap", content(hintPage, setting: ["Use Control+F for favourites Switch button off Double tap to toggle setting."])),
    ("bad-page-shortcut", content(hintPage)),
    ("bad-no-arrow-keys", content("In the photos: F to add or remove a favourite.")),
  ]

  func testVoiceOverSpeech() throws {
    // XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
    // older Xcode the symbol does not exist, so an availability check alone
    // would not compile; the body is compiled only where the SDK has it.
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Notes saved:")
      let content = Self.exampleContent(spoken)
      print("I04VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
