// L3 (tree) and L4 (VoiceOver) for C12 Tooltip on iOS.
// Spec: docs/specs/C12-tooltip.md.
//
// Whether a tooltip is drawn is read from screenshots: the pixels of a band
// under the control in the colour of Material's light tooltip box, its grey
// 700 at 90% over the page, about (112, 112, 113) (`drawn`), as on Android.
// The tree was tried first: in the probe a shown tooltip's text was a text
// element of its own (t01, with nothing merging it), but in the examples,
// each inside TestId's MergeSemantics, a long press left the tree as it
// was: no second element and no change to the control's label (the first
// C12 runs; each reading is still logged, `C12IOS`). A touch held 0.8 s is
// a long press (`press(forDuration:)`). XCUITest cannot hover, so whether
// the pointer can move onto a tooltip is measured in the widget tests, on
// the web, and on Android. XCUITest cannot see Flutter's focus; the keys
// are sent once each, and what they did is read from the count. The
// VoiceOver walk is C03's (C03Walk, in C03StandAloneLinkUITests.swift).
import XCTest

final class C12TooltipUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "C12"
  static let countLabel = "Activations"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-material": "Material tooltip",
    "good-cupertino": "Tooltip on a Cupertino button",
    "good-description": "Tooltip that describes a button",
    "bad-not-hoverable": "Tooltip the pointer cannot reach",
    "bad-hover-only": "Information only on hover",
    "bad-repeats-name": "Tooltip that repeats the name",
    "bad-outside-button": "Tooltip outside its button",
  ]

  private let good = ["good-material", "good-cupertino", "good-description"]

  private static let control = [
    "good-material": "c12-good-material-delete",
    "good-cupertino": "c12-good-cupertino-delete",
    "good-description": "c12-good-description-download",
    "bad-not-hoverable": "c12-bad-not-hoverable-delete",
    "bad-hover-only": "c12-bad-hover-only-info",
    "bad-repeats-name": "c12-bad-repeats-name-download",
  ]

  private static let tip = [
    "good-material": "Delete draft",
    "good-cupertino": "Delete draft",
    "good-description": "Saves a PDF copy",
    "bad-not-hoverable": "Delete draft",
    "bad-hover-only": "At least 8 characters",
  ]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.titles[slug]!), settle: 500_000, file: file, line: line)
  }

  /// How many times [slug]'s tooltip words are in the labels of the
  /// screen's elements, logged (`C12IOS`) with the labels.
  private func tipTexts(_ slug: String) -> Int {
    let tip = Self.tip[slug]!
    let labels = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", tip))
      .allElementsBoundByIndex.compactMap { e -> String? in e.exists ? e.label : nil }
    let n = labels.reduce(0) { $0 + $1.components(separatedBy: tip).count - 1 }
    print("C12IOS \(slug) labels with \"\(tip)\": \(labels.map { $0.debugDescription })")
    return n
  }

  /// How many pixels of the band under [frame] (40 points high, 300 wide,
  /// from 10 left of it) are the light tooltip box's colour.
  private func boxPixels(under frame: CGRect) -> (count: Int, scale: CGFloat) {
    let shot = XCUIScreen.main.screenshot().image
    guard let cg = shot.cgImage else { return (0, 1) }
    let scale = CGFloat(cg.width) / shot.size.width
    let band = CGRect(x: (frame.minX - 10) * scale, y: frame.maxY * scale, width: 300 * scale, height: 40 * scale)
      .intersection(CGRect(x: 0, y: 0, width: CGFloat(cg.width), height: CGFloat(cg.height))).integral
    guard let crop = cg.cropping(to: band) else { return (0, scale) }
    let w = crop.width, h = crop.height
    var data = [UInt8](repeating: 0, count: w * h * 4)
    let drawn = data.withUnsafeMutableBytes { buffer -> Bool in
      guard let ctx = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
      ctx.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
      return true
    }
    guard drawn else { return (0, scale) }
    var n = 0
    for i in stride(from: 0, to: data.count, by: 4)
    where abs(Int(data[i]) - 112) <= 16 && abs(Int(data[i + 1]) - 112) <= 16 && abs(Int(data[i + 2]) - 113) <= 16 {
      n += 1
    }
    return (n, scale)
  }

  /// A box drawn there: more than 1000 square points of the band in its colour.
  private func isDrawn(_ slug: String) -> Bool {
    let (n, scale) = boxPixels(under: element(Self.control[slug]!).frame)
    print("C12IOS \(slug) box pixels: \(n)")
    return CGFloat(n) > 1000 * scale * scale
  }

  /// Waits up to [timeout] seconds for isDrawn to be [expected]; returns what it read last.
  private func waitDrawn(_ slug: String, _ expected: Bool, timeout: TimeInterval) -> Bool {
    let end = Date().addingTimeInterval(timeout)
    var now = isDrawn(slug)
    while now != expected && Date() < end {
      usleep(150_000)
      now = isDrawn(slug)
    }
    return now
  }

  private func longPress(_ e: XCUIElement) {
    e.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.8)
  }

  func testGoodControlsAreNamedButtons() {
    let names = [
      "good-material": "Delete draft",
      "good-cupertino": "Delete draft",
      // The tooltip joins the name, after the button's text (FL-251).
      "good-description": "Download\nSaves a PDF copy",
    ]
    for slug in good {
      open(slug)
      let e = element(Self.control[slug]!)
      XCTAssertEqual(e.elementType, .button, slug)
      XCTAssertEqual(e.label, names[slug]!, slug)
      XCTAssertEqual(app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }.count, 1,
                     "\(slug): one button but Back")
      XCTAssertEqual(tipTexts(slug), 1, "\(slug): the words once, on the control")
    }
  }

  /// A long press draws the tooltip, and it goes after the touch ends; it
  /// does not activate the control. What the tree shows meanwhile is logged.
  func testALongPressShowsTheTooltipAndItGoes() {
    for slug in good + ["bad-not-hoverable"] {
      open(slug)
      XCTAssertFalse(isDrawn(slug), "\(slug): not drawn before")
      longPress(element(Self.control[slug]!))
      XCTAssertTrue(waitDrawn(slug, true, timeout: 1.5), "\(slug): drawn")
      _ = tipTexts(slug)
      XCTAssertFalse(waitDrawn(slug, false, timeout: 4), "\(slug): gone within 4 s")
      expectCount(slug, 0)
    }
  }

  /// FL-248: written to fail when a tooltip shows on keyboard focus. One
  /// Tab goes to Back and the second to the control (the probe's t10, whose
  /// tooltip a focus listener showed, came on the second Tab); Enter there
  /// activates it, which shows the second Tab reached it. The positive
  /// control in the same launch: a long press draws the tooltip.
  func testKeyboardFocusDoesNotShowTheTooltip() {
    for slug in good {
      open(slug)
      for _ in 0..<2 {
        app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
        usleep(900_000)
      }
      usleep(1_500_000)
      XCTAssertFalse(isDrawn(slug), "\(slug): Tab drew no tooltip")
      app.typeKey("\n", modifierFlags: [])
      expectCount(slug, 1)
      XCTAssertFalse(isDrawn(slug), "\(slug): Enter drew no tooltip")
      longPress(element(Self.control[slug]!))
      XCTAssertTrue(waitDrawn(slug, true, timeout: 1.5), "\(slug): a long press draws it")
      _ = waitDrawn(slug, false, timeout: 4)
    }
  }

  func testGoodControlsActivateByATap() {
    for slug in good {
      open(slug)
      element(Self.control[slug]!).tap()
      expectCount(slug, 1)
    }
  }

  func testBadNotHoverableIsNamedByItsTooltip() {
    open("bad-not-hoverable")
    let e = element(Self.control["bad-not-hoverable"]!)
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Delete draft")
  }

  /// No key draws the rule; a long press does.
  func testBadHoverOnlyNoKeyShowsTheRule() {
    let slug = "bad-hover-only"
    open(slug)
    let info = element(Self.control[slug]!)
    XCTAssertEqual(info.label, "At least 8 characters")
    XCTAssertNotEqual(info.elementType, .button)
    XCTAssertFalse(isDrawn(slug), "before")
    // One Tab goes to Back and the second to Sign up, where Enter
    // activates it: the positive control for the keys.
    for tabs in 1...2 {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(900_000)
      XCTAssertFalse(isDrawn(slug), "after \(tabs) Tab(s)")
    }
    app.typeKey("\n", modifierFlags: [])
    expectCount(slug, 1)
    XCTAssertFalse(isDrawn(slug), "after Enter")
    longPress(info)
    XCTAssertTrue(waitDrawn(slug, true, timeout: 1.5), "a long press draws it")
  }

  func testBadRepeatsNameIsNamedTwice() {
    open("bad-repeats-name")
    let e = element(Self.control["bad-repeats-name"]!)
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Download\nDownload")
  }

  func testBadOutsideButtonHasAButtonWithNoName() {
    open("bad-outside-button")
    let outer = element("c12-bad-outside-button-tooltip")
    XCTAssertEqual(outer.label, "Delete draft")
    XCTAssertNotEqual(outer.elementType, .button)
    let buttons = app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }
    XCTAssertEqual(buttons.count, 1)
    XCTAssertEqual(buttons.first?.label, "")
  }

  private let speech: [(slug: String, content: [String])] = [
    ("good-material", ["Delete draft Button", "Drafts are kept for 30 days.", "Activations: 0"]),
    ("good-cupertino", ["Delete draft Button", "Drafts are kept for 30 days.", "Activations: 0"]),
    ("good-description", ["Download Saves a PDF copy Button", "The file is 2 MB.", "Activations: 0"]),
    ("bad-not-hoverable", ["Delete draft Button", "Drafts are kept for 30 days.", "Activations: 0"]),
    // The icon's node has only its tooltip, and VoiceOver passes over it
    // (FL-252; the probe's t07).
    ("bad-hover-only", ["Password rules", "Sign up Button", "You can change it later.", "Activations: 0"]),
    ("bad-repeats-name", ["Download Download Button", "The file is 2 MB.", "Activations: 0"]),
    // The tooltip's node is passed over too, and the button has no name
    // (the probe's t02).
    ("bad-outside-button", ["Button", "Drafts are kept for 30 days.", "Activations: 0"]),
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("C12VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
