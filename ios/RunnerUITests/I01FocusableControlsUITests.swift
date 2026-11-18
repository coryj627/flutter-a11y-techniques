// L3 (tree, keyboard, and pointer) and L4 (VoiceOver) for I01 Focusable
// and clickable controls on iOS.
// Spec: docs/specs/I01-focusable-controls.md.
//
// The keyboard is driven with XCUIElement.typeKey, which the simulator
// delivers as a hardware keyboard's keys; Tab and Space reach Flutter's
// focus system (docs/evidence/probes/i01/README.md). Enter is typed as
// "\n": XCUIKeyboardKey.return never reached Flutter in the probe, and
// XCUIKeyboardKey.enter arrived as Control and C. XCUITest does not see
// where Flutter's keyboard focus is (hasFocus is false on every element),
// so focus is shown by what a key then does: Enter or Space activates the
// control that has focus, and on Back it leaves the screen.
import XCTest

final class I01FocusableControlsUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "I01"
  static let countLabel = "Activations"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private static let trail = "Ridge trail"
  private static let good = ["good-material", "good-cupertino", "good-custom"]
  private static let all = good + ["bad-inkwell-no-role", "bad-no-focus", "bad-no-key-action", "bad-tap-down"]
  /// Tab reaches these, and Enter and Space activate them.
  private static let keyboard = good + ["bad-inkwell-no-role", "bad-tap-down"]
  /// These act when the pointer is let go over them.
  private static let actOnRelease = good + ["bad-inkwell-no-role", "bad-no-focus", "bad-no-key-action"]

  private func trail(_ slug: String) -> XCUIElement { element("i01-\(slug)-trail") }

  private static let enter = "\n"
  private static let space = XCUIKeyboardKey.space.rawValue
  private static let tab = XCUIKeyboardKey.tab.rawValue

  private func press(_ key: String) {
    app.typeKey(key, modifierFlags: [])
    usleep(700_000)
  }

  /// Waits a second, then expects the count of `slug` still to be `n`.
  private func expectCountStays(_ slug: String, _ n: Int, file: StaticString = #filePath, line: UInt = #line) {
    sleep(1)
    expectCount(slug, n, file: file, line: line)
  }

  func testEveryControlHasItsNameAndTypeAndATapActivatesIt() {
    for slug in Self.all {
      open(slug)
      let control = trail(slug)
      XCTAssertEqual(control.label, Self.trail, slug)
      // bad-inkwell-no-role's defect: an InkWell is not a button; XCUITest
      // sees static text.
      XCTAssertEqual(control.elementType, slug == "bad-inkwell-no-role" ? .staticText : .button, slug)
      XCTAssertTrue(control.isEnabled, slug)
      XCTAssertEqual(elements(labelled: Self.trail).count, 1, slug)
      control.tap()
      expectCount(slug, 1)
      expectCountStays(slug, 1)
    }
  }

  // The example screen has two things the keyboard can reach before the
  // example: none, then Back. The first Tab puts focus on Back, and the
  // second on the control if it can take focus; if not, focus stays on
  // Back.

  func testTabReachesTheControlAndEnterAndSpaceEachActivateIt() {
    for slug in Self.keyboard {
      open(slug)
      press(Self.tab)
      press(Self.tab)
      press(Self.enter)
      expectCount(slug, 1)
      // Focus stays on the control.
      press(Self.space)
      expectCount(slug, 2)
    }
  }

  /// Waits up to 5 seconds for the example `slug` to leave the screen, as it
  /// does when Back is activated.
  private func expectScreenLeft(_ slug: String, _ why: String, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while countElement(slug).exists && Date() < deadline { usleep(100_000) }
    XCTAssertFalse(countElement(slug).exists, why, file: file, line: line)
  }

  func testBadNoFocusIsNeverReachedByTab() {
    open("bad-no-focus")
    // Two Tabs: the number at which the good examples' control has focus.
    // The card cannot take it, so the second Tab goes round to Back, and
    // Space there leaves the screen. Had the card been reached, Space would
    // have activated it and the screen would have stayed. Had no key
    // arrived, nothing would have happened and the screen would have
    // stayed too, so the test fails then as well.
    press(Self.tab)
    press(Self.tab)
    press(Self.space)
    expectScreenLeft("bad-no-focus", "Space after two Tabs did not act on Back")
  }

  private func badNoKeyActionIgnores(_ key: String, _ name: String) {
    open("bad-no-key-action")
    press(Self.tab)
    press(Self.tab)
    press(key)
    expectCountStays("bad-no-key-action", 0)
    // Still on the screen: focus was on the card, not on Back.
    XCTAssertTrue(countElement("bad-no-key-action").exists, "\(name) left the screen")
    // The control, in the same launch: Tab goes on, round to Back, and the
    // same key there leaves the screen. If keys were not arriving, the
    // screen would stay and this would fail.
    press(Self.tab)
    press(key)
    expectScreenLeft("bad-no-key-action", "\(name) on Back did nothing, so keys may not have arrived")
  }

  func testBadNoKeyActionTakesFocusAndEnterDoesNothing() {
    badNoKeyActionIgnores(Self.enter, "Enter")
  }

  func testBadNoKeyActionTakesFocusAndSpaceDoesNothing() {
    badNoKeyActionIgnores(Self.space, "Space")
  }

  func testAPressThatSlidesOffDoesNothing() {
    for slug in Self.actOnRelease {
      open(slug)
      trail(slug).press(forDuration: 0.6, thenDragTo: element(labelled: "Example"))
      expectCountStays(slug, 0)
    }
  }

  func testBadTapDownActsOnAPressThatSlidesOff() {
    open("bad-tap-down")
    trail("bad-tap-down").press(forDuration: 0.6, thenDragTo: element(labelled: "Example"))
    expectCount("bad-tap-down", 1)
    expectCountStays("bad-tap-down", 1)
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // activation count, the last element of every example. The keyboard and
  // pointer defects are not heard: those cards are read as the good ones.
  private static let button = "\(trail) Button"
  private let speech: [(slug: String, content: [String])] = [
    ("good-material", [button]),
    ("good-cupertino", [button]),
    ("good-custom", [button]),
    // The defect: nothing says the card can be activated.
    ("bad-inkwell-no-role", [trail]),
    ("bad-no-focus", [button]),
    ("bad-no-key-action", [button]),
    ("bad-tap-down", [button]),
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
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Activations:")
      let content = Self.exampleContent(spoken)
      print("I01VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
