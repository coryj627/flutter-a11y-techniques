// L3 (tree and keyboard) and L4 (VoiceOver) for F03 Keyboard types on iOS.
// Spec: docs/specs/F03-keyboard-types.md.
//
// Which keyboard a field gets is not a property of its element. It is read
// from the keyboard itself, which XCUITest shows while a field is being
// edited: its keys (`app.keyboards.keys`), its return key, which is a
// button named for the field's text input action ("next", "done"), and
// the QuickType bar above it, where a "Passwords" button appears for a
// field that iOS treats as a password or a username. The autofill hints of
// other fields become the field's text content type (read in the engine
// source, FlutterTextInputPlugin.mm), which no XCUITest query can read; so
// `bad-no-purpose` cannot be told apart from `good-contact`'s name field
// here.
//
// Every field is looked at in a freshly opened example, so that a keyboard
// left up by the field before cannot cover it: on iOS a tap outside a
// Flutter field does not end editing, and the number and phone pads have
// no key that does.
import XCTest

final class F03KeyboardTypesUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "F03"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  /// What a field must give the keyboard. `keys` must be among the keys and
  /// `noKeys` must not; `returnKey` is the return key's name, or nil for a
  /// keyboard with none; `passwords` whether the QuickType bar offers
  /// saved passwords.
  private struct Field {
    let slug: String
    let id: String
    let label: String
    let keys: [String]
    let noKeys: [String]
    let returnKey: String?
    var secure = false
    var passwords = false
  }

  private static let fields: [Field] = [
    // The name pad: letters, with a key to the phone pad.
    Field(slug: "good-contact", id: "f03-good-contact-name", label: "Name",
          keys: ["q", "phone pad"], noKeys: ["@"], returnKey: "next"),
    Field(slug: "good-contact", id: "f03-good-contact-email", label: "Email",
          keys: ["q", "@", "."], noKeys: [], returnKey: "next"),
    // The phone pad: digits only, and no return key at all.
    Field(slug: "good-contact", id: "f03-good-contact-phone", label: "Phone",
          keys: ["1", "0"], noKeys: ["q", "."], returnKey: nil),
    // The decimal pad: digits and a decimal point.
    Field(slug: "good-amount", id: "f03-good-amount-amount", label: "Amount",
          keys: ["1", "0", "."], noKeys: ["q"], returnKey: nil),
    Field(slug: "good-cupertino", id: "f03-good-cupertino-email", label: "Email",
          keys: ["q", "@", "."], noKeys: [], returnKey: "next"),
    Field(slug: "good-cupertino", id: "f03-good-cupertino-phone", label: "Phone",
          keys: ["1", "0"], noKeys: ["q", "."], returnKey: nil),
    Field(slug: "good-sign-in", id: "f03-good-sign-in-username", label: "Username",
          keys: ["q"], noKeys: ["@"], returnKey: "next", passwords: true),
    Field(slug: "good-sign-in", id: "f03-good-sign-in-password", label: "Password",
          keys: ["q"], noKeys: ["@"], returnKey: "done", secure: true, passwords: true),
    // Bad examples: the defect must be visible in the keys.
    // The number pad: digits only, so no letter can be typed.
    Field(slug: "bad-number-for-name", id: "f03-bad-number-for-name-name", label: "Name",
          keys: ["1", "0"], noKeys: ["q", ".", "phone pad"], returnKey: nil),
    Field(slug: "bad-default-keyboard", id: "f03-bad-default-keyboard-email", label: "Email",
          keys: ["q"], noKeys: ["@"], returnKey: "done"),
    // The same keyboard as good-contact's name field; only the purpose is
    // missing, and that cannot be read here.
    Field(slug: "bad-no-purpose", id: "f03-bad-no-purpose-name", label: "Name",
          keys: ["q", "phone pad"], noKeys: ["@"], returnKey: "done"),
    // The defect is Android's (FL-160): on iOS the email keyboard is kept.
    Field(slug: "bad-email-no-suggestions", id: "f03-bad-email-no-suggestions-email", label: "Email",
          keys: ["q", "@", "."], noKeys: [], returnKey: "done"),
  ]

  private func keyLabels() -> [String] {
    app.keyboards.firstMatch.keys.allElementsBoundByIndex.map { $0.label }
  }

  private func keyboardButtons() -> [String] {
    app.keyboards.firstMatch.buttons.allElementsBoundByIndex.map { $0.label }
  }

  /// Whether the QuickType bar has the button for saved passwords.
  private func offersPasswords() -> Bool {
    app.buttons.matching(NSPredicate(format: "label == %@", "Passwords")).count > 0
  }

  func testEveryFieldIsATextFieldWithItsName() {
    for slug in ["good-contact", "good-amount", "good-cupertino", "good-sign-in",
                 "bad-number-for-name", "bad-default-keyboard", "bad-no-purpose",
                 "bad-email-no-suggestions"] {
      open(slug)
      for field in Self.fields where field.slug == slug {
        let e = element(field.id)
        // Not being edited, an obscured field is a plain text field
        // (FL-042).
        XCTAssertEqual(e.elementType, .textField, field.id)
        XCTAssertEqual(e.label, field.label, field.id)
      }
    }
  }

  func testEveryFieldGetsItsKeyboard() {
    for field in Self.fields {
      open(field.slug)
      element(field.id).tap()
      // Wait for the keyboard, and for the keys this field asks for.
      let deadline = Date().addingTimeInterval(8)
      while Date() < deadline && !(app.keyboards.count > 0 && Set(keyLabels()).isSuperset(of: field.keys)) {
        usleep(200_000)
      }
      let keys = keyLabels()
      let buttons = keyboardButtons()
      print("F03TREE \(field.id) type=\(element(field.id).elementType.rawValue) keys=\(keys) buttons=\(buttons) passwords=\(offersPasswords())")
      XCTAssertEqual(app.keyboards.count, 1, "\(field.id): a keyboard")
      for key in field.keys { XCTAssertTrue(keys.contains(key), "\(field.id): key \"\(key)\" in \(keys)") }
      for key in field.noKeys { XCTAssertFalse(keys.contains(key), "\(field.id): no key \"\(key)\" in \(keys)") }
      // The return key is named for the text input action; a number or
      // phone pad has none.
      let returnKeys = buttons.filter { ["next", "done", "return", "go", "send", "search"].contains($0) }
      XCTAssertEqual(returnKeys, field.returnKey.map { [$0] } ?? [], "\(field.id): return key in \(buttons)")
      XCTAssertEqual(offersPasswords(), field.passwords, "\(field.id): Passwords in the QuickType bar")
      // While it is being edited an obscured field is a secure text field
      // (FL-042).
      XCTAssertEqual(element(field.id).elementType, field.secure ? .secureTextField : .textField, field.id)
      XCTAssertEqual(element(field.id).label, field.label, "\(field.id) while editing")
    }
  }

  func testAPhonePadCannotBePutAwayFromTheScreen() {
    // FL-163: the phone pad has no return key (testEveryFieldGetsItsKeyboard),
    // and a tap outside a Flutter field does not end editing on iOS. Written
    // to fail when the tap starts to put the keyboard away.
    open("good-contact")
    element("f03-good-contact-phone").tap()
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 8), "the phone pad came up")
    element(labelled: "Example").tap()
    sleep(2)
    XCTAssertEqual(app.keyboards.count, 1, "the keyboard is still up after a tap outside the field")
    XCTAssertEqual(keyboardButtons().filter { ["next", "done", "return"].contains($0) }, [])
  }

  func testThePasswordIsObscuredAndASecureFieldOnlyWhileEdited() {
    open("good-sign-in")
    let id = "f03-good-sign-in-password"
    element(id).tap()
    element(id).typeText("abc")
    expectCount("good-sign-in", 3)
    XCTAssertEqual(element(id).elementType, .secureTextField)
    XCTAssertEqual(element(id).value as? String, "•••")
    // Editing moves to the username field: the password is a plain text
    // field again, with its bullets as its value (FL-042).
    element("f03-good-sign-in-username").tap()
    let deadline = Date().addingTimeInterval(5)
    while element(id).elementType != .textField && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(element(id).elementType, .textField)
    XCTAssertEqual(element(id).value as? String, "•••")
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example
  // (VoiceOverWalk.forward). The keyboard types are not heard: a field is
  // read the same whatever keyboard it asks for.
  private static func field(_ name: String) -> String { "\(name) Text field Double tap to edit." }
  private let speech: [(slug: String, content: [String])] = [
    ("good-contact", [field("Name"), field("Email"), field("Phone")]),
    ("good-amount", [field("Amount")]),
    ("good-cupertino", [field("Email"), field("Phone")]),
    // Not being edited, the password is read as a plain text field (FL-042).
    ("good-sign-in", [field("Username"), field("Password")]),
    ("bad-number-for-name", [field("Name")]),
    ("bad-default-keyboard", [field("Email")]),
    ("bad-no-purpose", [field("Name")]),
    ("bad-email-no-suggestions", [field("Email")]),
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
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Changes:")
      let content = Self.exampleContent(spoken)
      print("F03VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    // The password while it is being edited, with "abc" typed. VoiceOver's
    // cursor starts on the field being edited; one move forward and one
    // back read it.
    open("good-sign-in")
    let id = "f03-good-sign-in-password"
    element(id).tap()
    element(id).typeText("abc")
    expectCount("good-sign-in", 3)
    try voiceOver.enable()
    var voiceOverOn = true
    defer { if voiceOverOn { try? voiceOver.disable() } }
    sleep(2)
    let next = VoiceOverWalk.normalized(try voiceOver.moveForward().utterance)
    let back = VoiceOverWalk.normalized(try voiceOver.moveBackward().utterance)
    try voiceOver.disable()
    voiceOverOn = false
    print("F03VO good-sign-in+editing | \(next) / \(back)")
    XCTAssertEqual(next, "Changes: 3", "the move forward from the password reached the count")
    // While it is being edited VoiceOver says "Secure text field", and reads
    // bullets, not what was typed (FL-042). Not being edited, the walk above
    // reads it as a plain "Text field".
    XCTAssertTrue(back.hasPrefix("Password Secure text field Is editing •••"),
                  "the move back read the password as a secure field being edited: \(back)")
    XCTAssertFalse(back.contains("abc"), "what was typed is not read: \(back)")
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
