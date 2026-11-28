// L3 (tree and pixels) and L4 (VoiceOver) for V01 Colour contrast on iOS.
// Spec: docs/specs/V01-colour-contrast.md.
//
// The tree. XCUITest gives each element's type, label, value, and whether
// it is selected; it cannot read traits, so it cannot tell a radio button
// from a button, a heading from other text, or a group from a list. What
// it shows of a choice is `isSelected`, and of the checkbox its value.
//
// The pixels. Every contrast is read from XCUIScreen screenshots, drawn
// into an sRGB buffer (as V14FocusIndicatorsUITests does), never from the
// theme, with the three measures of the widget tests
// (test/techniques/v01_colour_contrast_test.dart: _textContrast, _edge,
// _marks), step for step, at the simulator's own pixel ratio (3 on the
// iPhone 17). Light and dark are the simulator's own appearance
// (XCUIDevice.appearance): each test checks the app's page colour shows the
// mode took before it reads, and puts the appearance back, and checks that,
// at its end and again in tearDown.
//
// What differs from the widget tests, and why:
//
// - A text's box. The widget tests measure on the text's paragraph
//   rectangle. XCUITest gives a rectangle only for an element: a text that
//   is an element of its own ("We reply within two days.", "Harbour") is
//   measured on its element's frame, which is its paragraph's. A text
//   inside a control (a field's label or hint, a tile's title, a button's
//   text) has no element of its own, so its box is its ink: the smallest
//   rectangle holding every pixel of a search area that differs by more
//   than 12 in some channel from the area's commonest colour (inkBox). The
//   search areas are placed from the control's frame, by the geometry read
//   from the probe screenshots (docs/evidence/probes/v01/), each one
//   holding that text and nothing else drawn: no edge, no other text. The
//   text measure itself is unchanged: the colours round the text are the
//   pixels 6 above and 6 below the box. The ink's rectangle is grown by 2
//   pixels, as the spec's section 6 says, to take in the faint
//   anti-aliased pixels just outside it. The box is found at rest and kept
//   for every other state of the same control (focused, checked, chosen),
//   after checking the control's frame did not move, as the other layers
//   do: a state's overlay changes the area's commonest colour, and a text
//   cursor in it would be taken into the box.
// - The commonest text pixel, on a tie, is the colour met first, columns
//   left to right and each from the top, as the widget tests' reduce does.
// - bad-colour-only's "nothing else drawn": the widget tests leave out the
//   title's paragraph grown by 2 pixels; here the ink box (already grown by
//   2 pixels) grown by 2 points more, as the ink box is tighter than a
//   paragraph.
// - A control's parts. The checkbox's box and the radio buttons' rings have
//   no element; their place is the probe's geometry, from the tile's
//   frame: the checkbox's centre 44 points left of the tile's right edge,
//   a radio button's centre 36 points right of the tile's left edge. Each
//   edge walk checks its first pixel is the page's colour and fails
//   otherwise.
// - States. Keyboard focus is reached with Tab (XCUIElement.typeKey, no
//   modifier: keys with a modifier were unreliable on CI's iOS 26.5).
//   XCUITest does not see Flutter's keyboard focus: a text field's focus is
//   shown by its `hasKeyboardFocus`, and any other control's by what Tab
//   drew, the control's frame changed outside the text measured in it and
//   every other control's not. Each focus is shown gone again: after the
//   next Tab (after the last control, one more Tab) the control's frame is
//   as it was at rest. A focused field's text
//   cursor blinks, which does not settle: each text measured while a field
//   has focus is measured in two screenshots 600 ms apart (more than the
//   cursor's 500 ms half period), each held to the threshold, and the two
//   must agree. A held press cannot be measured:
//   XCUIElement.press(forDuration:) returns only after the finger is
//   lifted, and nothing can take a screenshot while it is down. Hover
//   cannot be: XCUITest has no pointer on iOS. good-selection's radio
//   buttons are one Tab stop (RadioGroup): Tab reaches Week, the chosen
//   one, and the next Tab goes to Back, so Day and Month are not measured
//   with focus. The checkbox checked and a choice moved to Day are each
//   put back by a tap, and checked back; every test opens its example by a
//   cold start, which begins from rest.
// - Settling. A screenshot is measured once two screenshots 400 ms apart
//   differ, by more than 2 in some channel, in no more than 0.5% of the
//   example's region (a blinking cursor is less), so that a ripple or a
//   transition fading out is waited for.
//
// Each assertion names the criterion whose threshold it applies: 1.4.3,
// 4.5:1 (no text here is large, and none is in an inactive control);
// 1.4.11, 3:1; 1.4.1, a lightness difference of 3:1.
import XCTest

final class V01ColourContrastUITests: XCTestCase, TechniqueUITest {
  static let technique = "V01"
  let app = XCUIApplication()

  /// The simulator's appearance when the test began.
  private var appearanceAtStart: XCUIDevice.Appearance = .unspecified
  /// The appearance this test set and has not yet put back.
  private var mode: XCUIDevice.Appearance?

  override func setUp() {
    super.setUp()
    continueAfterFailure = true
    appearanceAtStart = XCUIDevice.shared.appearance
    print("V01 ios appearance at the start: \(Self.name(appearanceAtStart))")
  }

  override func tearDown() {
    // A test that failed half way still leaves the simulator as it was.
    if mode != nil { restoreAppearance() }
    XCTAssertEqual(XCUIDevice.shared.appearance, appearanceAtStart, "the simulator's appearance is back")
    super.tearDown()
  }

  /// Each example's title and the lines above its "Example" heading, as
  /// the screen shows them (ExampleScreen in lib/app/screens.dart).
  static let screens: [String: [String]] = [
    "good-material": ["Material form at the theme's defaults", "Good example for Colour contrast. Material."],
    "good-cupertino": ["Cupertino field with stronger greys", "Good example for Colour contrast. Cupertino."],
    "good-caption": ["Caption on a bar of its own", "Good example for Colour contrast. Material."],
    "good-selection": ["Choice shown by a shape", "Good example for Colour contrast. Material."],
    "bad-cupertino-placeholder": [
      "Default Cupertino placeholder", "Bad example for Colour contrast. Cupertino.",
      "Defect: The placeholder is too faint to read.",
    ],
    "bad-caption": [
      "Caption straight on the picture", "Bad example for Colour contrast. Material.",
      "Defect: The caption fades into the pale part of the picture.",
    ],
    "bad-colour-only": [
      "Choice shown by colour alone", "Bad example for Colour contrast. Material.",
      "Defect: The chosen view differs from the others only by colour.",
    ],
    "bad-faint-edge": [
      "Field with a faint edge", "Bad example for Colour contrast. Material.",
      "Defect: The field's edge is too faint to see where it is.",
    ],
  ]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.screens[slug]![0]), settle: 1_000_000, file: file, line: line)
  }

  private func id(_ slug: String, _ part: String) -> XCUIElement { element("v01-\(slug)-\(part)") }

  // MARK: The tree

  struct Seen: Equatable, CustomStringConvertible {
    let type: XCUIElement.ElementType
    let label: String
    let identifier: String
    var description: String { "\(type.rawValue) \(label.debugDescription) \(identifier)" }
  }

  /// Every element of the screen with a label, after the "Example" heading,
  /// in the tree's order (one snapshot, read depth first).
  private func exampleElements() -> [Seen] {
    guard let root = try? app.snapshot() else { return [] }
    var seen: [Seen] = []
    func walk(_ s: XCUIElementSnapshot) {
      if s.elementType != .window && s.elementType != .application && !s.label.isEmpty {
        seen.append(Seen(type: s.elementType, label: s.label, identifier: s.identifier))
      }
      for c in s.children { walk(c) }
    }
    walk(root)
    guard let start = seen.lastIndex(where: { $0.label == "Example" }) else { return [] }
    return Array(seen[(start + 1)...])
  }

  private static func seen(_ type: XCUIElement.ElementType, _ label: String, _ id: String = "") -> Seen {
    Seen(type: type, label: label, identifier: id)
  }

  /// What XCUITest shows of each example after its heading (the probe's
  /// dump). A Flutter checkbox is a switch to XCUITest (FL-035), and a
  /// radio button a button. The Material field's hint is not in its label,
  /// value, or placeholder; the Cupertino field's placeholder is in its
  /// label, after a line break.
  static let tree: [String: [Seen]] = [
    "good-material": [
      seen(.staticText, "We reply within two days."),
      seen(.textField, "Email", "v01-good-material-email"),
      seen(.switch, "Send me updates", "v01-good-material-updates"),
      seen(.button, "Send", "v01-good-material-send"),
    ],
    "good-cupertino": [
      seen(.textField, "Email\nRequired", "v01-good-cupertino-email"),
      seen(.button, "Send", "v01-good-cupertino-send"),
    ],
    "good-caption": [seen(.staticText, "Harbour")],
    // The line above the radio buttons is the label of an element that
    // holds them.
    "good-selection": [
      seen(.other, "Calendar view"),
      seen(.button, "Day", "v01-good-selection-day"),
      seen(.button, "Week", "v01-good-selection-week"),
      seen(.button, "Month", "v01-good-selection-month"),
    ],
    "bad-cupertino-placeholder": [seen(.textField, "Email\nRequired", "v01-bad-cupertino-placeholder-email")],
    "bad-caption": [seen(.staticText, "Harbour")],
    "bad-colour-only": [
      seen(.staticText, "Calendar view"),
      seen(.button, "Day", "v01-bad-colour-only-day"),
      seen(.button, "Week", "v01-bad-colour-only-week"),
      seen(.button, "Month", "v01-bad-colour-only-month"),
    ],
    "bad-faint-edge": [seen(.textField, "Email", "v01-bad-faint-edge-email")],
  ]

  func testEachExampleHasItsElements() {
    for (slug, expected) in Self.tree.sorted(by: { $0.key < $1.key }) {
      open(slug)
      let got = exampleElements()
      print("V01 ios tree \(slug): \(got)")
      XCTAssertEqual(got, expected, slug)
    }
    open("good-material")
    XCTAssertEqual(id("good-material", "email").value as? String, "")
    XCTAssertEqual(id("good-material", "email").placeholderValue ?? "", "")
    XCTAssertEqual(id("good-material", "updates").value as? String, "0")
  }

  /// Waits up to 5 seconds for `slug`'s chosen view to be `chosen` alone,
  /// as XCUITest shows it (isSelected).
  private func expectChosen(_ slug: String, _ chosen: String, file: StaticString = #filePath, line: UInt = #line) {
    let views = ["day", "week", "month"]
    func selected() -> [Bool] { views.map { id(slug, $0).isSelected } }
    let want = views.map { $0 == chosen }
    let deadline = Date().addingTimeInterval(5)
    while selected() != want && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(selected(), want, "\(slug): \(chosen) alone selected", file: file, line: line)
  }

  func testATapOnDayMovesTheChoice() {
    // In bad-colour-only the state reaches the tree; its defect is what is
    // drawn (the pixel tests).
    for slug in ["good-selection", "bad-colour-only"] {
      open(slug)
      expectChosen(slug, "week")
      id(slug, "day").tap()
      expectChosen(slug, "day")
      id(slug, "week").tap()
      expectChosen(slug, "week")
    }
  }

  // MARK: Pixels

  struct Shot {
    let width: Int
    let height: Int
    let data: [UInt8]
    /// Pixels per point.
    let scale: CGFloat

    func at(_ x: Int, _ y: Int) -> UInt32 {
      let o = (y * width + x) * 4
      return UInt32(data[o]) << 16 | UInt32(data[o + 1]) << 8 | UInt32(data[o + 2])
    }

    /// A rectangle in points, in pixels.
    func px(_ r: CGRect) -> CGRect {
      CGRect(x: r.minX * scale, y: r.minY * scale, width: r.width * scale, height: r.height * scale)
    }
  }

  private func shot() -> Shot {
    let image = XCUIScreen.main.screenshot().image
    let cg = image.cgImage!
    let w = cg.width, h = cg.height
    var data = [UInt8](repeating: 0, count: w * h * 4)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    data.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
      context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    }
    return Shot(width: w, height: h, data: data, scale: CGFloat(w) / image.size.width)
  }

  static func channelDiff(_ a: UInt32, _ b: UInt32) -> Int {
    max(abs(Int((a >> 16) & 255) - Int((b >> 16) & 255)),
        abs(Int((a >> 8) & 255) - Int((b >> 8) & 255)),
        abs(Int(a & 255) - Int(b & 255)))
  }

  private static func luminance(_ c: UInt32) -> Double {
    func lin(_ v: UInt32) -> Double {
      let s = Double(v) / 255
      return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * lin((c >> 16) & 255) + 0.7152 * lin((c >> 8) & 255) + 0.0722 * lin(c & 255)
  }

  /// WCAG's contrast ratio between two colours.
  static func ratio(_ a: UInt32, _ b: UInt32) -> Double {
    let x = luminance(a), y = luminance(b)
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)
  }

  static func hex(_ c: UInt32) -> String { String(format: "#%06X", c) }
  private static func fixed(_ v: Double) -> String { String(format: "%.2f", v) }

  /// The pixels of `region` (in pixels), outside every rectangle of
  /// `excluding`, that differ by more than `over` in some channel between
  /// two screenshots.
  private static func changed(
    _ a: Shot, _ b: Shot, _ region: CGRect, over: Int = 12, excluding: [CGRect] = []
  ) -> Int {
    let l = max(0, Int(region.minX)), t = max(0, Int(region.minY))
    let r = min(a.width, Int(region.maxX.rounded(.up))), bt = min(a.height, Int(region.maxY.rounded(.up)))
    guard l < r, t < bt else { return 0 }
    var n = 0
    for y in t..<bt {
      for x in l..<r where channelDiff(a.at(x, y), b.at(x, y)) > over {
        let p = CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5)
        if !excluding.contains(where: { $0.contains(p) }) { n += 1 }
      }
    }
    return n
  }

  /// What the text measure found.
  struct TextMeasure: CustomStringConvertible {
    /// The text's colour: the commonest colour of its pixels.
    let colour: UInt32
    /// The lowest contrast of `colour` against what is above or below the
    /// text in any column the text is in, and that colour.
    let lowest: Double
    let under: UInt32
    /// Pixels that differ from what is round the text, and how many of them
    /// are exactly `colour`.
    let textPixels: Int
    let core: Int
    var description: String {
      "text \(V01ColourContrastUITests.hex(colour)), lowest \(V01ColourContrastUITests.fixed(lowest)):1 over "
        + "\(V01ColourContrastUITests.hex(under)) (\(core) of \(textPixels) pixels the text colour)"
    }
  }

  /// The text measure (the spec, section 6, item 1; the widget tests'
  /// _textContrast, step for step). `box` is the text's box in pixels. For
  /// each column the colours round the text are the pixels 6 above the box
  /// and 6 below it; a pixel of the box that differs from both by more than
  /// 12 in some channel is a text pixel; the text's colour is the commonest
  /// text pixel; and the contrast is the lowest, over every column with a
  /// pixel of exactly that colour, of the text's colour against either
  /// colour round it there. Nil if the box is off the screen or holds 20
  /// text pixels or fewer.
  static func textContrast(_ s: Shot, _ box: CGRect) -> TextMeasure? {
    let l = Int(box.minX.rounded(.down)), r = Int(box.maxX.rounded(.up)) - 1
    let t = Int(box.minY.rounded(.down)), b = Int(box.maxY.rounded(.up)) - 1
    let above = t - 6, below = b + 6
    guard l >= 0, r < s.width, l <= r, t <= b, above >= 0, below < s.height else { return nil }
    var counts: [UInt32: Int] = [:]
    // The colours in the order they were first met, for the tie rule.
    var order: [UInt32] = []
    var textPixels = 0
    for x in l...r {
      let up = s.at(x, above), down = s.at(x, below)
      for y in t...b {
        let c = s.at(x, y)
        if channelDiff(c, up) > 12 && channelDiff(c, down) > 12 {
          textPixels += 1
          if counts[c] == nil { order.append(c) }
          counts[c, default: 0] += 1
        }
      }
    }
    guard textPixels > 20 else { return nil }
    // As the widget tests' reduce: the commonest; on a tie the colour met
    // first is kept.
    var colour: UInt32 = 0, most = -1
    for c in order where counts[c]! > most { colour = c; most = counts[c]! }
    var lowest = Double.infinity
    var under: UInt32 = 0
    for x in l...r {
      guard (t...b).contains(where: { s.at(x, $0) == colour }) else { continue }
      for c in [s.at(x, above), s.at(x, below)] {
        let q = ratio(colour, c)
        if q < lowest { lowest = q; under = c }
      }
    }
    return TextMeasure(colour: colour, lowest: lowest, under: under, textPixels: textPixels, core: most)
  }

  /// A text's box when it has no element of its own: the smallest rectangle
  /// (in pixels) holding every pixel of `area` (in points) that differs by
  /// more than 12 in some channel from the area's commonest colour, grown by
  /// 2 pixels (the spec, section 6). Nil if there is none.
  static func inkBox(_ s: Shot, _ area: CGRect) -> CGRect? {
    let a = s.px(area)
    let l = max(0, Int(a.minX)), t = max(0, Int(a.minY))
    let r = min(s.width, Int(a.maxX.rounded(.up))), b = min(s.height, Int(a.maxY.rounded(.up)))
    guard l < r, t < b else { return nil }
    var counts: [UInt32: Int] = [:]
    for y in t..<b { for x in l..<r { counts[s.at(x, y), default: 0] += 1 } }
    var ground: UInt32 = 0, most = -1
    for (c, n) in counts where n > most || (n == most && c < ground) { ground = c; most = n }
    var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
    for y in t..<b {
      for x in l..<r where channelDiff(s.at(x, y), ground) > 12 {
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
      }
    }
    guard maxX >= 0 else { return nil }
    return CGRect(x: minX - 2, y: minY - 2, width: maxX - minX + 5, height: maxY - minY + 5)
  }

  /// What the edge measure found.
  struct Edge: CustomStringConvertible {
    let start: UInt32, edge: UInt32, end: UInt32
    /// The edge against where the walk began (outside the control) and
    /// against where it ended (inside).
    var outside: Double { V01ColourContrastUITests.ratio(edge, start) }
    var inside: Double { V01ColourContrastUITests.ratio(edge, end) }
    var description: String {
      "edge \(V01ColourContrastUITests.hex(edge)): \(V01ColourContrastUITests.fixed(outside)):1 against "
        + "\(V01ColourContrastUITests.hex(start)), \(V01ColourContrastUITests.fixed(inside)):1 against "
        + V01ColourContrastUITests.hex(end)
    }
  }

  /// The edge measure (section 6, item 2; the widget tests' _edge): from
  /// the pixel (x0, y0), outside the control, `steps` pixels in the
  /// direction (dx, dy); the edge is the pixel on the way that contrasts
  /// most with the first, and it is taken against the first and against
  /// the last.
  static func edge(_ s: Shot, _ x0: Int, _ y0: Int, _ dx: Int, _ dy: Int, _ steps: Int) -> Edge {
    let start = s.at(x0, y0)
    var edge = start
    for i in 1...steps {
      let c = s.at(x0 + dx * i, y0 + dy * i)
      if ratio(c, start) > ratio(edge, start) { edge = c }
    }
    return Edge(start: start, edge: edge, end: s.at(x0 + dx * steps, y0 + dy * steps))
  }

  /// The pixels of `area` (in pixels) that are 3:1 or more against
  /// `against`: the marks a control draws there (section 6, item 3).
  static func marks(_ s: Shot, _ area: CGRect, _ against: UInt32) -> Int {
    var n = 0
    for y in Int(area.minY.rounded(.down))..<Int(area.maxY.rounded(.up)) {
      for x in Int(area.minX.rounded(.down))..<Int(area.maxX.rounded(.up)) where ratio(s.at(x, y), against) >= 3 {
        n += 1
      }
    }
    return n
  }

  // MARK: Light and dark

  /// The app's page colour (the scaffold's, `surface`) in each mode, as
  /// the widget tests and the probe measured it.
  private static let page: [XCUIDevice.Appearance: UInt32] = [.light: 0xFBF8FF, .dark: 0x121318]

  private static func name(_ a: XCUIDevice.Appearance) -> String {
    switch a {
    case .light: return "light"
    case .dark: return "dark"
    default: return "unspecified (\(a.rawValue))"
    }
  }

  /// The page's colour in `s`: the pixel 2 points from the screen's left
  /// edge, level with the "Example" heading, where nothing is drawn.
  private func pageColour(_ s: Shot) -> UInt32 {
    let heading = element(labelled: "Example").frame
    return s.at(Int(2 * s.scale), Int(heading.midY * s.scale))
  }

  /// Sets the simulator's appearance, waits, at most 10 s, for it to read
  /// back, and 2 s more for the system to draw it. The setting reading back
  /// does not show the app was given it (it read back while the app stayed
  /// light, on a simulator that drew no dark mode at all): `expectPage` is
  /// the witness.
  private func setAppearance(_ a: XCUIDevice.Appearance, file: StaticString = #filePath, line: UInt = #line) {
    XCUIDevice.shared.appearance = a
    let deadline = Date().addingTimeInterval(10)
    while XCUIDevice.shared.appearance != a && Date() < deadline { usleep(200_000) }
    XCTAssertEqual(XCUIDevice.shared.appearance, a, "the simulator's appearance took", file: file, line: line)
    usleep(2_000_000)
  }

  /// Waits, at most 10 s, for the app's page to be the colour of
  /// `appearance`; fails, and returns false, if it is not.
  @discardableResult
  private func expectPage(_ appearance: XCUIDevice.Appearance, file: StaticString = #filePath, line: UInt = #line) -> Bool {
    var s = shot()
    guard let want = Self.page[appearance] else { return true }
    let deadline = Date().addingTimeInterval(10)
    while Self.channelDiff(pageColour(s), want) > 2 && Date() < deadline {
      usleep(300_000)
      s = shot()
    }
    let got = pageColour(s)
    print("V01 ios page in \(Self.name(appearance)): \(Self.hex(got))")
    XCTAssertLessThanOrEqual(
      Self.channelDiff(got, want), 2,
      "the app's page is \(Self.hex(got)), not \(Self.name(appearance))'s \(Self.hex(want))", file: file, line: line)
    return Self.channelDiff(got, want) <= 2
  }

  /// Puts the simulator's appearance back as it was when the test began,
  /// checks it reads back, and checks the app's page shows it.
  private func restoreAppearance(file: StaticString = #filePath, line: UInt = #line) {
    setAppearance(appearanceAtStart, file: file, line: line)
    mode = nil
    guard Self.page[appearanceAtStart] != nil else {
      print("V01 ios appearance put back to \(Self.name(appearanceAtStart)); the page colour is not checked")
      return
    }
    open("good-material")
    expectPage(appearanceAtStart, file: file, line: line)
    print("V01 ios appearance put back to \(Self.name(appearanceAtStart))")
  }

  /// Runs `body` in light mode and then in dark, by the simulator's own
  /// appearance, then puts the appearance back. `body` is given the mode's
  /// name; it opens its example with `openIn`.
  private func inEachMode(_ body: (String) -> Void) {
    for a in [XCUIDevice.Appearance.light, .dark] {
      // Set before the appearance changes, so that tearDown puts it back
      // even if the test stops while it is being set.
      mode = a
      setAppearance(a)
      body(Self.name(a))
    }
    restoreAppearance()
  }

  /// Opens `slug` in the current mode, checks the page shows the mode, and
  /// returns a screenshot once the example has stopped changing; nil, after
  /// a failure, if the page does not show the mode, so that nothing is
  /// measured in the wrong one.
  private func openIn(_ slug: String, file: StaticString = #filePath, line: UInt = #line) -> Shot? {
    open(slug, file: file, line: line)
    guard expectPage(mode ?? appearanceAtStart, file: file, line: line) else { return nil }
    return settled()
  }

  /// The part of the screen the examples are drawn in.
  private func exampleRegion(_ s: Shot) -> CGRect {
    let heading = element(labelled: "Example").frame
    return s.px(CGRect(x: 0, y: heading.maxY, width: app.frame.width, height: 280))
  }

  /// Waits, at most 4 s, for two screenshots 400 ms apart that differ, by
  /// more than 2 in some channel, in no more than 0.5% of the example's
  /// region. Returns the last.
  private func settled(file: StaticString = #filePath, line: UInt = #line) -> Shot {
    var last = shot()
    for _ in 0..<10 {
      usleep(400_000)
      let next = shot()
      let area = exampleRegion(next)
      let n = Self.changed(last, next, area, over: 2)
      last = next
      if Double(n) <= Double(area.width * area.height) * 0.005 { return last }
    }
    XCTFail("the screen did not settle", file: file, line: line)
    return last
  }

  // MARK: Measuring

  /// 1.4.3's threshold for text that is not large: no text here is large.
  private static let text143 = 4.5
  /// 1.4.11's threshold for a component's boundary, mark, or state.
  private static let nonText1411 = 3.0
  /// 1.4.1's lightness difference that counts as a means besides hue.
  private static let lightness141 = 3.0

  /// Measures a text and logs it: `box` in pixels, nil when no box was
  /// found. Fails if the text was not found; with `meets143`, fails if it
  /// is under 1.4.3's 4.5:1.
  @discardableResult
  private func text(
    _ tag: String, _ what: String, _ s: Shot, _ box: CGRect?, meets143: Bool = false,
    file: StaticString = #filePath, line: UInt = #line
  ) -> TextMeasure? {
    guard let box, let m = Self.textContrast(s, box) else {
      XCTFail("\(tag) \"\(what)\": no text found (box \(String(describing: box)))", file: file, line: line)
      return nil
    }
    print("V01 ios \(tag) \"\(what)\": \(m)")
    if meets143 {
      XCTAssertGreaterThanOrEqual(
        m.lowest, Self.text143, "\(tag) \"\(what)\": 1.4.3 needs 4.5:1; \(m)", file: file, line: line)
    }
    return m
  }

  /// A text measured while a field has focus, whose cursor blinks and so
  /// never settles: measured in `first` and in a screenshot 600 ms later
  /// (more than the cursor's 500 ms half period), each held to 1.4.3's
  /// 4.5:1, and the two must agree on the text's colour and its ratio.
  private func textWhileCursorBlinks(
    _ tag: String, _ what: String, _ first: Shot, _ box: CGRect?,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let a = text("\(tag) (1 of 2)", what, first, box, meets143: true, file: file, line: line)
    usleep(600_000)
    let b = text("\(tag) (2 of 2)", what, shot(), box, meets143: true, file: file, line: line)
    guard let a, let b else { return }
    XCTAssertEqual(Self.hex(a.colour), Self.hex(b.colour), "\(tag) \"\(what)\": the two samples' colour", file: file, line: line)
    XCTAssertEqual(a.lowest, b.lowest, accuracy: 0.01, "\(tag) \"\(what)\": the two samples' ratio", file: file, line: line)
  }

  /// Fails unless `e`'s frame is still `frame`: a box found at rest is kept
  /// for another state only if its control did not move.
  private func expectStill(
    _ tag: String, _ e: XCUIElement, _ frame: CGRect, file: StaticString = #filePath, line: UInt = #line
  ) {
    XCTAssertEqual(e.frame, frame, "\(tag): \(e.identifier) moved since rest", file: file, line: line)
  }

  /// A text that is an element of its own: its frame is its paragraph.
  private func frameBox(_ s: Shot, _ e: XCUIElement) -> CGRect { s.px(e.frame) }

  /// The edge measure from (x, y) in points, `steps` points in the
  /// direction (dx, dy), logged; fails if the walk does not start on the
  /// page's colour.
  private func edge(
    _ tag: String, _ what: String, _ s: Shot, page: UInt32, _ x: CGFloat, _ y: CGFloat, _ dx: Int, _ dy: Int,
    _ points: CGFloat, file: StaticString = #filePath, line: UInt = #line
  ) -> Edge {
    let e = Self.edge(s, Int(x * s.scale), Int(y * s.scale), dx, dy, Int(points * s.scale))
    print("V01 ios \(tag) \(what): \(e)")
    XCTAssertLessThanOrEqual(
      Self.channelDiff(e.start, page), 2,
      "\(tag) \(what): the walk started on \(Self.hex(e.start)), not the page \(Self.hex(page))", file: file, line: line)
    return e
  }

  // Where each text is looked for, from the probe's screenshots, in points
  // from the control's frame. Each holds its text and nothing else drawn.

  /// A Material field's floating label: on the field's top edge, in the
  /// gap the edge leaves for it (12 to 52 points from the field's left).
  private static func floatingLabelArea(_ field: CGRect) -> CGRect {
    CGRect(x: field.minX + 14, y: field.minY - 8, width: 36, height: 16)
  }

  /// A field's hint or placeholder: inside its edge, below the label.
  private static func insideArea(_ field: CGRect) -> CGRect { field.insetBy(dx: 8, dy: 8) }

  /// The label "Email" above a Cupertino field.
  private static func labelAboveArea(_ field: CGRect) -> CGRect {
    CGRect(x: field.minX, y: field.minY - 24, width: 60, height: 20)
  }

  /// A button's text: inside its outline or fill.
  private static func buttonTextArea(_ button: CGRect) -> CGRect { button.insetBy(dx: 6, dy: 12) }

  /// A tile's title, right of a leading radio button (none in
  /// bad-colour-only, whose tiles are measured from their own left).
  private static func titleArea(_ tile: CGRect, leading: CGFloat) -> CGRect {
    CGRect(x: tile.minX + leading, y: tile.minY + 6, width: 120, height: tile.height - 12)
  }

  /// The checkbox tile's title, left of the trailing checkbox.
  private static func checkboxTitleArea(_ tile: CGRect) -> CGRect {
    CGRect(x: tile.minX + 6, y: tile.minY + 6, width: tile.width - 72, height: tile.height - 12)
  }

  /// The checkbox's centre: 44 points left of its tile's right edge.
  private static func checkboxCentre(_ tile: CGRect) -> CGPoint { CGPoint(x: tile.maxX - 44, y: tile.midY) }

  /// A radio button's centre: 36 points right of its tile's left edge.
  private static func radioCentre(_ tile: CGRect) -> CGPoint { CGPoint(x: tile.minX + 36, y: tile.midY) }

  // MARK: Focus

  private func tab() {
    app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
    usleep(700_000)
  }

  private func hasKeyboardFocus(_ e: XCUIElement) -> Bool {
    (e.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
  }

  /// Waits, at most 5 s, for the text field `e` to have keyboard focus.
  private func expectKeyboardFocus(_ e: XCUIElement, _ on: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while hasKeyboardFocus(e) != on && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(hasKeyboardFocus(e), on, "\(e.identifier) has keyboard focus: \(on)", file: file, line: line)
  }

  /// The witness that Tab put focus on `target`: in `now`, against the
  /// example at rest, `target`'s frame changed in more than 1000 pixels
  /// outside `excluding` (the boxes of the texts measured in it, so that
  /// the witness is not the pixels measured) and none of `others`' frames
  /// changed at all.
  private func expectFocusDrawn(
    _ tag: String, on target: XCUIElement, excluding: [CGRect] = [], others: [XCUIElement], rest: Shot, now: Shot,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let drawn = Self.changed(rest, now, now.px(target.frame), excluding: excluding)
    let elsewhere = others.map { Self.changed(rest, now, now.px($0.frame)) }
    print("V01 ios \(tag) focus on \(target.label.debugDescription): \(drawn) pixels changed outside its texts; elsewhere \(elsewhere)")
    XCTAssertGreaterThan(drawn, 1000, "\(tag): Tab drew nothing on \(target.label)", file: file, line: line)
    XCTAssertEqual(elsewhere, others.map { _ in 0 }, "\(tag): Tab changed another control", file: file, line: line)
  }

  /// The witness that focus left `target`: in `now`, its frame is as it
  /// was at rest.
  private func expectFocusGone(
    _ tag: String, from target: XCUIElement, rest: Shot, now: Shot, file: StaticString = #filePath, line: UInt = #line
  ) {
    let left = Self.changed(rest, now, now.px(target.frame))
    print("V01 ios \(tag) focus gone from \(target.label.debugDescription): \(left) pixels differ from rest")
    XCTAssertEqual(left, 0, "\(tag): \(target.label) is not back as it was at rest", file: file, line: line)
  }

  // MARK: Tests

  func testContrastRatioIsWCAGs() {
    XCTAssertEqual(Self.ratio(0x000000, 0xFFFFFF), 21, accuracy: 0.01)
    XCTAssertEqual(Self.ratio(0x767676, 0xFFFFFF), 4.54, accuracy: 0.01)
    XCTAssertEqual(Self.ratio(0x949494, 0xFFFFFF), 3.03, accuracy: 0.01)
    XCTAssertEqual(Self.ratio(0xFFFFFF, 0xFFFFFF), 1)
  }

  /// Waits up to 5 seconds for `e`'s value to be `value`.
  private func expectValue(
    _ e: XCUIElement, _ value: String, _ what: String, file: StaticString = #filePath, line: UInt = #line
  ) {
    let deadline = Date().addingTimeInterval(5)
    while (e.value as? String) != value && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(e.value as? String, value, what, file: file, line: line)
  }

  func testGoodMaterialAtRest() {
    let slug = "good-material"
    inEachMode { m in
      guard let s = openIn(slug) else { return }
      let tag = "\(slug) rest \(m)"
      let page = pageColour(s)
      let field = id(slug, "email").frame, tile = id(slug, "updates").frame, send = id(slug, "send").frame
      text(tag, "We reply within two days.", s, frameBox(s, element(labelled: "We reply within two days.")), meets143: true)
      text(tag, "Email", s, Self.inkBox(s, Self.floatingLabelArea(field)), meets143: true)
      text(tag, "Required", s, Self.inkBox(s, Self.insideArea(field)), meets143: true)
      text(tag, "Send me updates", s, Self.inkBox(s, Self.checkboxTitleArea(tile)), meets143: true)
      text(tag, "Send", s, Self.inkBox(s, Self.buttonTextArea(send)), meets143: true)
      // The walks of the widget tests: 12 pixels (4 points) left of the
      // field for 30 pixels (10 points); from 3 pixels inside the
      // checkbox's render box (19 points right of its centre) 22 points
      // left; 6 pixels (2 points) left of the button for 10 points.
      let fieldEdge = edge(tag, "field edge", s, page: page, field.minX - 4, field.midY, 1, 0, 10)
      XCTAssertGreaterThanOrEqual(fieldEdge.outside, Self.nonText1411, "\(tag) field: 1.4.11 needs 3:1; \(fieldEdge)")
      let box = Self.checkboxCentre(tile)
      let boxEdge = edge(tag, "checkbox border", s, page: page, box.x + 19, box.y, -1, 0, 22)
      XCTAssertGreaterThanOrEqual(boxEdge.outside, Self.nonText1411, "\(tag) checkbox: 1.4.11 needs 3:1; \(boxEdge)")
      // A button with text needs no boundary (the spec, section 3): the
      // outline is held to 1.4.11's 3:1 as the widget tests hold it, and no
      // verdict rests on it.
      let outline = edge(tag, "button outline", s, page: page, send.minX - 2, send.midY, 1, 0, 10)
      XCTAssertGreaterThanOrEqual(outline.outside, Self.nonText1411, "\(tag) outline: 1.4.11's 3:1; \(outline)")
    }
  }

  func testGoodMaterialCheckboxChecked() {
    let slug = "good-material"
    inEachMode { m in
      guard let rest = openIn(slug) else { return }
      let tag = "\(slug) checked \(m)"
      let updates = id(slug, "updates")
      let tile = updates.frame
      let title = Self.inkBox(rest, Self.checkboxTitleArea(tile))
      XCTAssertEqual(updates.value as? String, "0", "\(tag): the box is not checked at rest")
      updates.tap()
      expectValue(updates, "1", "\(tag): the tap checked the box")
      let s = settled()
      expectStill(tag, updates, tile)
      let page = pageColour(s)
      let box = Self.checkboxCentre(tile)
      let fill = edge(tag, "checkbox fill", s, page: page, box.x + 19, box.y, -1, 0, 22)
      XCTAssertGreaterThanOrEqual(fill.outside, Self.nonText1411, "\(tag) fill: 1.4.11 needs 3:1; \(fill)")
      // The mark: the middle of the box, 5 points each way.
      let inner = s.px(CGRect(x: box.x - 5, y: box.y - 5, width: 10, height: 10))
      let mark = Self.marks(s, inner, fill.edge)
      print("V01 ios \(tag) mark: \(mark) pixels 3:1 or more against the fill")
      XCTAssertGreaterThan(mark, 30, "\(tag): no mark 1.4.11's 3:1 on the fill")
      text(tag, "Send me updates", s, title, meets143: true)
      // Put back: a second tap unchecks the box.
      updates.tap()
      expectValue(updates, "0", "\(tag): a second tap unchecked the box")
    }
  }

  func testGoodMaterialTextsWithFocus() {
    let slug = "good-material"
    inEachMode { m in
      guard let rest = openIn(slug) else { return }
      let tag = "\(slug) focused \(m)"
      let email = id(slug, "email"), updates = id(slug, "updates"), send = id(slug, "send")
      let emailFrame = email.frame, updatesFrame = updates.frame, sendFrame = send.frame
      // Each text's box, found at rest.
      let label = Self.inkBox(rest, Self.floatingLabelArea(emailFrame))
      let hint = Self.inkBox(rest, Self.insideArea(emailFrame))
      let title = Self.inkBox(rest, Self.checkboxTitleArea(updatesFrame))
      let sendText = Self.inkBox(rest, Self.buttonTextArea(sendFrame))
      tab()  // Back
      tab()
      expectKeyboardFocus(email)
      var s = settled()
      expectStill(tag, email, emailFrame)
      textWhileCursorBlinks(tag, "Email", s, label)
      textWhileCursorBlinks(tag, "Required", s, hint)
      tab()
      expectKeyboardFocus(email, false)
      s = settled()
      expectStill(tag, updates, updatesFrame)
      expectFocusDrawn(tag, on: updates, excluding: [title].compactMap { $0 }, others: [email, send], rest: rest, now: s)
      text(tag, "Send me updates", s, title, meets143: true)
      tab()
      s = settled()
      expectStill(tag, send, sendFrame)
      expectFocusDrawn(tag, on: send, excluding: [sendText].compactMap { $0 }, others: [email, updates], rest: rest, now: s)
      text(tag, "Send", s, sendText, meets143: true)
      // One more Tab takes focus off Send: it is as it was at rest.
      tab()
      expectFocusGone(tag, from: send, rest: rest, now: settled())
    }
  }

  func testGoodCupertinoAtRest() {
    let slug = "good-cupertino"
    inEachMode { m in
      guard let s = openIn(slug) else { return }
      let tag = "\(slug) rest \(m)"
      let field = id(slug, "email").frame, send = id(slug, "send").frame
      text(tag, "Email", s, Self.inkBox(s, Self.labelAboveArea(field)), meets143: true)
      text(tag, "Required", s, Self.inkBox(s, Self.insideArea(field)), meets143: true)
      text(tag, "Send", s, Self.inkBox(s, Self.buttonTextArea(send)), meets143: true)
      // The widget tests' walk: 6 pixels (2 points) left of the field for
      // 18 pixels (6 points).
      let fieldEdge = edge(tag, "field edge", s, page: pageColour(s), field.minX - 2, field.midY, 1, 0, 6)
      XCTAssertGreaterThanOrEqual(fieldEdge.outside, Self.nonText1411, "\(tag): 1.4.11 needs 3:1 against the page; \(fieldEdge)")
      XCTAssertGreaterThanOrEqual(fieldEdge.inside, Self.nonText1411, "\(tag): 1.4.11 needs 3:1 against the field; \(fieldEdge)")
    }
  }

  func testGoodCupertinoTextsWithFocus() {
    let slug = "good-cupertino"
    inEachMode { m in
      guard let rest = openIn(slug) else { return }
      let tag = "\(slug) focused \(m)"
      let email = id(slug, "email"), send = id(slug, "send")
      let emailFrame = email.frame, sendFrame = send.frame
      // Each text's box, found at rest.
      let label = Self.inkBox(rest, Self.labelAboveArea(emailFrame))
      let placeholder = Self.inkBox(rest, Self.insideArea(emailFrame))
      let sendText = Self.inkBox(rest, Self.buttonTextArea(sendFrame))
      tab()  // Back
      tab()
      expectKeyboardFocus(email)
      var s = settled()
      expectStill(tag, email, emailFrame)
      textWhileCursorBlinks(tag, "Email", s, label)
      textWhileCursorBlinks(tag, "Required", s, placeholder)
      tab()
      expectKeyboardFocus(email, false)
      s = settled()
      expectStill(tag, send, sendFrame)
      expectFocusDrawn(tag, on: send, excluding: [sendText].compactMap { $0 }, others: [email], rest: rest, now: s)
      text(tag, "Send", s, sendText, meets143: true)
      // One more Tab takes focus off Send: it is as it was at rest.
      tab()
      expectFocusGone(tag, from: send, rest: rest, now: settled())
    }
  }

  func testGoodCaption() {
    let slug = "good-caption"
    inEachMode { m in
      guard let s = openIn(slug) else { return }
      text("\(slug) \(m)", "Harbour", s, frameBox(s, element(labelled: "Harbour")), meets143: true)
    }
  }

  func testGoodSelection() {
    let slug = "good-selection"
    let views = [("day", "Day"), ("week", "Week"), ("month", "Month")]
    inEachMode { m in
      guard let rest = openIn(slug) else { return }
      // Each tile's frame and its title's box, found at rest.
      var frames: [String: CGRect] = [:], boxes: [String: CGRect] = [:]
      for (v, _) in views {
        frames[v] = id(slug, v).frame
        boxes[v] = Self.inkBox(rest, Self.titleArea(frames[v]!, leading: 72))
      }
      // Each title 4.5:1 or more and each ring 3:1 or more; returns how many
      // pixels of each radio button's middle, 4 points each way, are 3:1 or
      // more against the page: its dot.
      func dots(_ tag: String) -> [String: Int] {
        let s = settled()
        let page = pageColour(s)
        var out: [String: Int] = [:]
        for (v, title) in views {
          let tile = frames[v]!
          expectStill(tag, id(slug, v), tile)
          let c = Self.radioCentre(tile)
          // From 1 point inside the radio's 40 point box, to its centre.
          let ring = edge(tag, "\(v) ring", s, page: page, c.x - 19, c.y, 1, 0, 19)
          XCTAssertGreaterThanOrEqual(ring.outside, Self.nonText1411, "\(tag) \(v) ring: 1.4.11 needs 3:1; \(ring)")
          text(tag, title, s, boxes[v], meets143: true)
          out[v] = Self.marks(s, s.px(CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)), page)
        }
        print("V01 ios \(tag) dots: \(out.sorted { $0.key < $1.key })")
        return out
      }
      // The dot is the chosen state's mark: its pixels are those 1.4.11's
      // 3:1 or more against the page.
      let before = dots("\(slug) rest \(m)")
      XCTAssertGreaterThan(before["week"] ?? 0, 100, "a dot in Week's radio button: \(before)")
      XCTAssertEqual(before["day"], 0, "no dot in Day's: \(before)")
      XCTAssertEqual(before["month"], 0, "no dot in Month's: \(before)")
      id(slug, "day").tap()
      expectChosen(slug, "day")
      let after = dots("\(slug) after a tap on Day \(m)")
      XCTAssertGreaterThan(after["day"] ?? 0, 100, "a dot in Day's radio button: \(after)")
      XCTAssertEqual(after["week"], 0, "no dot in Week's: \(after)")
      XCTAssertEqual(after["month"], 0, "no dot in Month's: \(after)")
      // Put back: a tap on Week chooses it again.
      id(slug, "week").tap()
      expectChosen(slug, "week")
    }
  }

  func testGoodSelectionTextWithFocus() {
    let slug = "good-selection"
    inEachMode { m in
      guard let rest = openIn(slug) else { return }
      let tag = "\(slug) focused \(m)"
      let day = id(slug, "day"), week = id(slug, "week"), month = id(slug, "month")
      let weekFrame = week.frame
      let title = Self.inkBox(rest, Self.titleArea(weekFrame, leading: 72))
      tab()  // Back
      tab()
      var s = settled()
      // The group's one Tab stop is the chosen radio button, Week.
      expectStill(tag, week, weekFrame)
      expectFocusDrawn(tag, on: week, excluding: [title].compactMap { $0 }, others: [day, month], rest: rest, now: s)
      text(tag, "Week", s, title, meets143: true)
      // The next Tab leaves the group, for Back: neither Day nor Month is
      // a Tab stop, and Week is as it was at rest.
      tab()
      s = settled()
      expectFocusDrawn(tag, on: element(labelled: "Back"), others: [day, week, month], rest: rest, now: s)
    }
  }

  // Bad examples: each defect, measured, written to fail if Flutter draws
  // it otherwise, with a lower bound that shows it was drawn and found.

  func testBadCupertinoPlaceholderIsUnder4_5To1() {
    let slug = "bad-cupertino-placeholder"
    inEachMode { m in
      guard let s = openIn(slug) else { return }
      let tag = "\(slug) \(m)"
      let field = id(slug, "email").frame
      if let p = text(tag, "Required", s, Self.inkBox(s, Self.insideArea(field))) {
        XCTAssertLessThan(p.lowest, Self.text143, "\(tag): FL-510, the placeholder under 1.4.3's 4.5:1: \(p)")
        XCTAssertGreaterThan(p.lowest, 1.2, "\(tag): the placeholder is drawn: \(p)")
      }
      text(tag, "Email", s, Self.inkBox(s, Self.labelAboveArea(field)), meets143: true)
      let fieldEdge = edge(tag, "field edge", s, page: pageColour(s), field.minX - 2, field.midY, 1, 0, 6)
      XCTAssertGreaterThanOrEqual(fieldEdge.outside, Self.nonText1411, "\(tag): 1.4.11 needs 3:1; \(fieldEdge)")
    }
  }

  func testBadCaptionIsUnder4_5To1OverThePalePart() {
    let slug = "bad-caption"
    inEachMode { m in
      guard let s = openIn(slug) else { return }
      let tag = "\(slug) \(m)"
      let caption = element(labelled: "Harbour").frame
      guard let whole = text(tag, "Harbour", s, frameBox(s, element(labelled: "Harbour"))) else { return }
      XCTAssertLessThan(whole.lowest, Self.text143, "\(tag): FL-512, the caption under 1.4.3's 4.5:1: \(whole)")
      XCTAssertGreaterThan(whole.lowest, 1, "\(tag): the caption is drawn: \(whole)")
      // The caption's colour would be 4.5:1 or more over the dark end of the
      // picture, 4 pixels in from the bar's right end (the bar ends 16
      // points, its padding, right of the caption's box): what fails is
      // where it is drawn.
      let dark = s.at(Int((caption.maxX + 16) * s.scale) - 4, Int(caption.midY * s.scale))
      let q = Self.ratio(whole.colour, dark)
      print("V01 ios \(tag): the caption's colour against the dark end \(Self.hex(dark)) \(Self.fixed(q)):1")
      XCTAssertGreaterThanOrEqual(q, Self.text143, "\(tag): the caption's colour meets 1.4.3's 4.5:1 over the dark end")
    }
  }

  func testBadColourOnlyShowsTheChoiceByColourAlone() {
    let slug = "bad-colour-only"
    let views = [("day", "Day"), ("week", "Week"), ("month", "Month")]
    inEachMode { m in
      guard let rest = openIn(slug) else { return }
      // Each tile's frame and its title's box, found at rest.
      var frames: [String: CGRect] = [:], boxes: [String: CGRect] = [:]
      for (v, _) in views {
        frames[v] = id(slug, v).frame
        boxes[v] = Self.inkBox(rest, Self.titleArea(frames[v]!, leading: 4))
      }
      func titles(_ tag: String) -> [String: TextMeasure] {
        let s = settled()
        var out: [String: TextMeasure] = [:]
        for (v, title) in views {
          let tile = frames[v]!
          expectStill(tag, id(slug, v), tile)
          guard let t = text(tag, title, s, boxes[v], meets143: true), let box = boxes[v] else { continue }
          out[title] = t
          // Nothing but the title is drawn on the tile: every pixel of the
          // tile outside the title's box, grown by 2 points for the
          // anti-aliasing outside the ink, is within 2 of the page's colour
          // (the tile's own, 1 pixel in from its corner).
          let p = s.px(tile)
          let around = box.insetBy(dx: -2 * s.scale, dy: -2 * s.scale)
          let page = s.at(Int(p.minX) + 1, Int(p.minY) + 1)
          var other = 0
          for y in Int(p.minY.rounded(.up))..<Int(p.maxY.rounded(.down)) {
            for x in Int(p.minX.rounded(.up))..<Int(p.maxX.rounded(.down))
            where !around.contains(CGPoint(x: x, y: y)) && Self.channelDiff(s.at(x, y), page) > 2 {
              other += 1
            }
          }
          XCTAssertEqual(other, 0, "\(tag) \(title): \(other) pixels besides the title")
        }
        return out
      }
      let before = titles("\(slug) rest \(m)")
      guard let chosen = before["Week"]?.colour else { return XCTFail("\(m): no Week") }
      for v in ["Day", "Month"] {
        guard let other = before[v]?.colour else { continue }
        let q = Self.ratio(chosen, other)
        print("V01 ios \(slug) \(m): Week \(Self.hex(chosen)) against \(v) \(Self.hex(other)) \(Self.fixed(q)):1")
        XCTAssertNotEqual(other, chosen, "\(m) \(v)")
        XCTAssertLessThan(q, Self.lightness141, "\(m): FL-513, Week against \(v) under 1.4.1's lightness difference of 3:1")
        XCTAssertGreaterThan(q, 1, "\(m): Week's colour is not \(v)'s")
      }
      id(slug, "day").tap()
      expectChosen(slug, "day")
      let after = titles("\(slug) after a tap on Day \(m)")
      // As the widget tests: the colours change places exactly.
      if let day = after["Day"]?.colour {
        XCTAssertEqual(Self.hex(day), Self.hex(chosen), "\(m): the colour moved to Day")
      }
      if let week = after["Week"]?.colour, let oldDay = before["Day"]?.colour {
        XCTAssertEqual(Self.hex(week), Self.hex(oldDay), "\(m): Week has Day's old colour")
      }
      // Put back: a tap on Week chooses it again.
      id(slug, "week").tap()
      expectChosen(slug, "week")
    }
  }

  func testBadFaintEdgeIsUnder3To1AndPrimaryWithFocus() {
    let slug = "bad-faint-edge"
    inEachMode { m in
      guard var s = openIn(slug) else { return }
      let tag = "\(slug) \(m)"
      let email = id(slug, "email")
      let field = email.frame
      let page = pageColour(s)
      let rest = edge(tag, "field edge at rest", s, page: page, field.minX - 4, field.midY, 1, 0, 10)
      XCTAssertLessThan(rest.outside, Self.nonText1411, "\(tag): the field's edge under 1.4.11's 3:1 at rest: \(rest)")
      XCTAssertGreaterThan(rest.outside, 1.2, "\(tag): the edge is drawn: \(rest)")
      text(tag, "Email", s, Self.inkBox(s, Self.floatingLabelArea(field)), meets143: true)
      // The positive control: the same walk finds the edge with focus.
      tab()  // Back
      tab()
      expectKeyboardFocus(email)
      s = settled()
      expectStill(tag, email, field)
      let focused = edge(tag, "field edge with focus", s, page: page, field.minX - 4, field.midY, 1, 0, 10)
      XCTAssertGreaterThanOrEqual(focused.outside, Self.nonText1411, "\(tag): 1.4.11's 3:1 with focus: \(focused)")
      // Put back: Tab leaves the field, and its edge is as at rest.
      tab()
      expectKeyboardFocus(email, false)
      s = settled()
      let after = edge(tag, "field edge after focus left", s, page: page, field.minX - 4, field.midY, 1, 0, 10)
      XCTAssertEqual(Self.hex(after.edge), Self.hex(rest.edge), "\(tag): the edge is back as it was at rest")
    }
  }

  // MARK: VoiceOver

  // L4. Everything VoiceOver says from the top of the screen to its end
  // (V01Walk), judged whole: the screen's own stops first, which tie the
  // walk to this example (its title, its description and, for a bad
  // example, its defect, then the "Example" heading), then the example's,
  // each compared with its runs of white space made one space. A colour is
  // not spoken: no defect of V01 is heard. The rows record what each
  // example's texts and controls say.
  struct Speech {
    let slug: String
    /// What VoiceOver says above the "Example" heading.
    let screen: [String]
    /// What it says after the heading, to the end of the screen.
    let content: [String]
    /// For some stops of `content`, by index, the utterance exactly as the
    /// service gave it.
    let raw: [Int: String]
  }

  /// The stops above the "Example" heading, with it: the title, the
  /// screen's lines, and the heading.
  static func screenStops(_ slug: String) -> [String] {
    let lines = screens[slug]!
    return ["\(lines[0]) Heading"] + lines.dropFirst() + ["Example Heading"]
  }

  // Written from what VoiceOver said (the first recording, run1 of the
  // layer's raw logs), not predicted.
  static let materialField = "Email Text field Double tap to edit."
  /// The Cupertino field: its name and its placeholder, with the line break
  /// between them that the tree shows (testEachExampleHasItsElements).
  static let cupertinoField = "Email Required Text field Double tap to edit."
  static let cupertinoFieldRaw = "Email\nRequired Text field Double tap to edit."

  static let speech: [Speech] = [
    // The Material field's hint, "Required", is not said.
    Speech(
      slug: "good-material", screen: screenStops("good-material"),
      content: [
        "We reply within two days.", materialField,
        "Send me updates Switch button off Double tap to toggle setting.", "Send Button",
      ],
      raw: [:]),
    Speech(
      slug: "good-cupertino", screen: screenStops("good-cupertino"), content: [cupertinoField, "Send Button"],
      raw: [0: cupertinoFieldRaw]),
    Speech(slug: "good-caption", screen: screenStops("good-caption"), content: ["Harbour"], raw: [:]),
    // Each radio button is read as a button, with its state: the chosen one
    // "selected", before its name, and the others "Not selected".
    Speech(
      slug: "good-selection", screen: screenStops("good-selection"),
      content: ["Calendar view", "Day Button Not selected", "selected Week Button", "Month Button Not selected"],
      raw: [:]),
    // The same words as good-cupertino's field: the placeholder's colour is
    // not heard.
    Speech(
      slug: "bad-cupertino-placeholder", screen: screenStops("bad-cupertino-placeholder"), content: [cupertinoField],
      raw: [0: cupertinoFieldRaw]),
    Speech(slug: "bad-caption", screen: screenStops("bad-caption"), content: ["Harbour"], raw: [:]),
    // The chosen tile is "selected" to VoiceOver: the state reaches it; the
    // defect is that the screen shows it by colour alone. The others are
    // read with no state.
    Speech(
      slug: "bad-colour-only", screen: screenStops("bad-colour-only"),
      content: ["Calendar view", "Day Button", "selected Week Button", "Month Button"], raw: [:]),
    Speech(slug: "bad-faint-edge", screen: screenStops("bad-faint-edge"), content: [materialField], raw: [:]),
  ]

  func testExpectedUtterancesAreShortEnough() {
    // Every example is walked, once.
    XCTAssertEqual(Self.speech.map { $0.slug }.sorted(), Self.screens.keys.sorted())
    for example in Self.speech {
      for utterance in example.screen + example.content + example.raw.values {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \"\(utterance)\" is longer than VoiceOver's service returns")
      }
    }
  }

  func testTheJudgeTiesAWalkToItsScreen() {
    // Made-up walks of bad-colour-only: the judge must refuse another
    // example's screen, a missing, empty or wrong title, description or
    // defect, a missing heading, a wrong, missing, swapped or extra stop
    // after it, and a walk that did not reach the end.
    let bad = Self.speech.first { $0.slug == "bad-colour-only" }!
    let other = Self.speech.first { $0.slug == "good-selection" }!
    let screen = bad.screen, content = bad.content
    let right = screen + content
    let swapped = content.count >= 2 ? [content[1], content[0]] + content.dropFirst(2) : content + ["Extra"]
    var cases: [(String, [String], Bool, Bool)] = [
      ("the whole screen", right, true, true),
      ("the walk did not reach the end", right, false, false),
      ("another example's screen, the same content", other.screen + content, true, false),
      ("no title", Array(screen.dropFirst()) + content, true, false),
      ("an empty title", [""] + screen.dropFirst() + content, true, false),
      ("the title with no role word", [Self.screens["bad-colour-only"]![0]] + screen.dropFirst() + content, true, false),
      ("another example's title", [other.screen[0]] + screen.dropFirst() + content, true, false),
      ("no description", [screen[0]] + screen.dropFirst(2) + content, true, false),
      ("a good example's description", [screen[0], other.screen[1]] + screen.dropFirst(2) + content, true, false),
      ("no defect", Array(screen.prefix(2)) + screen.dropFirst(3) + content, true, false),
      ("another example's defect",
       Array(screen.prefix(2)) + [Self.screens["bad-faint-edge"]![2]] + screen.dropFirst(3) + content, true, false),
      ("no stops before the heading", ["Example Heading"] + content, true, false),
      ("the title read twice", [screen[0]] + screen + content, true, false),
      ("two content stops swapped", screen + swapped, true, false),
      ("a stop after the end", right + ["Extra"], true, false),
      ("nothing after the heading", screen, true, false),
    ]
    if !content.isEmpty {
      cases.append(("the last stop missing", screen + content.dropLast(), true, false))
      cases.append(("a stop with another word", screen + [content[0] + " selected"] + content.dropFirst(), true, false))
    }
    for (what, stops, reachedEnd, ok) in cases {
      XCTAssertEqual(V01Walk.judge(stops, reachedEnd: reachedEnd, bad).isEmpty, ok, what)
    }
    // A raw utterance: the Cupertino field's name and placeholder must come
    // with the line break between them.
    let field = Self.speech.first { $0.slug == "good-cupertino" }!
    XCTAssertEqual(V01Walk.judge(field.screen + [Self.cupertinoFieldRaw, "Send Button"], reachedEnd: true, field), [])
    XCTAssertFalse(
      V01Walk.judge(field.screen + [Self.cupertinoField, "Send Button"], reachedEnd: true, field).isEmpty,
      "the field read with a space for the line break")
  }

  func testTheCollectorFailsADuplicateStopAndAnUnwitnessedEnd() {
    // Made-up walks of good-material's screen. `moves` is what each move
    // forward reads, `back` and `again` what the end's witness reads.
    let walk = Self.speech[0].screen + Self.speech[0].content
    func run(_ moves: [String], back: String, again: String) -> V01Walk.Result {
      var i = 0
      return V01Walk.collect(
        next: { defer { i += 1 }; return i < moves.count ? moves[i] : moves.last! },
        back: { back }, forward: { again })
    }
    let last = walk.last!, before = walk[walk.count - 2]
    let cases: [(String, V01Walk.Result, Bool)] = [
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
      ("a walk that runs out of moves", V01Walk.collect(max: 3, next: { "x\(Int.random(in: 0..<1_000_000))" }, back: { "" }, forward: { "" }), false),
    ]
    for (what, result, whole) in cases {
      XCTAssertEqual(result.reachedEnd && result.problem == nil, whole, "\(what): \(result)")
    }
    // The whole walk keeps every stop once, and a judged walk of it is right.
    let right = run(walk + [last, last], back: before, again: last)
    XCTAssertEqual(right.stops, walk)
    XCTAssertEqual(V01Walk.judge(right.stops, reachedEnd: right.reachedEnd, Self.speech[0]), [])
    // The duplicate title is kept, and the judge would fail it as well.
    let dup = run([walk[0], walk[0]] + walk.dropFirst() + [last, last], back: before, again: last)
    XCTAssertEqual(dup.stops, [walk[0], walk[1]])
  }

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    for example in Self.speech {
      for utterance in example.screen + example.content + example.raw.values where utterance.count >= 64 {
        XCTFail("\(example.slug): \"\(utterance)\" is 64 characters or more, which the service cannot return whole")
        return
      }
    }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      open(example.slug)
      let walk = try V01Walk.walk(voiceOver)
      let problems = (walk.problem.map { [$0] } ?? []) + V01Walk.judge(walk.stops, reachedEnd: walk.reachedEnd, example)
      let heading = walk.stops.map(VoiceOverWalk.normalized).lastIndex(of: "Example Heading")
      let shown = problems.isEmpty
        ? Array(walk.stops[(heading! + 1)...]).map(VoiceOverWalk.normalized)
        : walk.stops.map { $0.debugDescription }
      print("V01VO \(example.slug) | \(shown.joined(separator: " / "))")
      for p in problems { XCTFail("\(example.slug): \(p)") }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}

/// V01's VoiceOver walk, from the top of the screen to its end, keeping
/// each utterance as the service gave it, and judging how it ended: S16's
/// S16Walk (S16LanguagePagePartsUITests.swift), copied whole, with only its
/// names changed. C03Walk, shared, is not used.
///
/// A move that reads the same words as the stop before it is one of two
/// things: the cursor did not move, at the last element, or a second
/// element read alike (or speech the service gave again while nothing new
/// was said, as `currentSpeech()` does). The words cannot tell them apart,
/// so the collector does not count a repeat as the end by itself:
///
/// - A repeat followed by a different utterance is a stop read twice in a
///   row mid-screen, and the walk fails ("a duplicate stop"); it is never
///   dropped. No V01 screen has two neighbouring elements that read alike,
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
enum V01Walk {
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
  /// exactly the example's content, each normalized, and for each stop
  /// with a raw utterance, exactly that.
  static func judge(_ stops: [String], reachedEnd: Bool, _ example: V01ColourContrastUITests.Speech) -> [String] {
    var problems: [String] = []
    if !reachedEnd { problems.append("the walk did not reach the end of the screen") }
    let normal = stops.map(VoiceOverWalk.normalized)
    let lastHeading = example.screen.last!
    guard let heading = normal.lastIndex(of: lastHeading) else {
      return problems + ["no \"\(lastHeading)\" stop: \(normal)"]
    }
    let screen = Array(normal[...heading])
    if screen != example.screen {
      problems.append("the screen's own stops were \(screen), not \(example.screen): not this example's screen")
    }
    let content = Array(normal[(heading + 1)...])
    if content != example.content {
      problems.append("after the heading: \(content), where \(example.content) was expected")
    }
    for (i, raw) in example.raw.sorted(by: { $0.key < $1.key }) {
      let got = heading + 1 + i < stops.count ? stops[heading + 1 + i] : "(no stop)"
      if got != raw { problems.append("stop \(i + 1) after the heading was \(got.debugDescription), not \(raw.debugDescription)") }
    }
    return problems
  }

  #if compiler(>=6.4)
  /// Switches VoiceOver on, walks to the end of the screen (collect), and
  /// switches it off. A move with no speech is handled as
  /// VoiceOverWalk.forward does (afterNoSpeech).
  @available(iOS 27.0, *)
  static func walk(_ voiceOver: XCUIVoiceOverService) throws -> Result {
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
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
