// L3 (tree, keyboard, and pixels) and L4 (VoiceOver) for V14 Focus
// indicators on iOS.
// Spec: docs/specs/V14-focus-indicators.md.
//
// The keyboard is driven with XCUIElement.typeKey, which the simulator
// delivers as a hardware keyboard's keys, and which turns Flutter's focus
// highlights on (docs/evidence/probes/v14/README.md). XCUITest does not see
// where Flutter's keyboard focus is, so each stop is shown by what Space
// then does: it uses the control with focus, and the example says which
// control was used last.
//
// What focus draws is read from XCUIScreen screenshots, drawn into an sRGB
// buffer: one before Tab reaches a control and two after, 700 ms apart once
// the screen has stopped changing. The pixels round the control that
// changed in both and agree are what focus drew, and their contrast is taken
// against the colours next to them in the focused screenshot (compare,
// below), never from the theme. The simulator is in light mode; dark
// mode is measured in the widget tests and the probe.
import XCTest

final class V14FocusIndicatorsUITests: XCTestCase, TechniqueUITest {
  static let technique = "V14"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private func count(_ slug: String) -> XCUIElement { element("v14-\(slug)-count") }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: count(slug), settle: 1_000_000, file: file, line: line)
  }

  private func control(_ slug: String, _ c: String) -> XCUIElement { element("v14-\(slug)-\(c)") }

  private static let space = XCUIKeyboardKey.space.rawValue
  private static let tab = XCUIKeyboardKey.tab.rawValue

  private func press(_ key: String) {
    app.typeKey(key, modifierFlags: [])
    usleep(700_000)
  }

  /// Presses Space and expects the example to say `name` was used: the stop
  /// was that control.
  private func expectStop(_ slug: String, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
    press(Self.space)
    let expected = "Last used: \(name)"
    let deadline = Date().addingTimeInterval(5)
    while count(slug).label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count(slug).label, expected, "Space on the stop", file: file, line: line)
  }

  // The controls outside a scrolling list, in Tab order after Back:
  // identifier, label, and what XCUITest sees (a Flutter checkbox is a
  // switch on iOS, FL-035).
  private static let controls: [String: [(String, String, XCUIElement.ElementType)]] = [
    "good-material": [("alerts", "Weather alerts", .switch), ("save", "Save", .button)],
    "good-cupertino": [("alerts", "Weather alerts", .switch), ("save", "Save", .button)],
    "good-widgets": [("trail", "Ridge trail", .button)],
    "bad-indicator-removed": [("save", "Save", .button)],
    "bad-checked-checkbox": [("alerts", "Weather alerts", .switch)],
    "bad-cupertino-ring": [("save", "Save", .button)],
  ]
  private static let trails = ["Ridge trail", "Lake loop", "Summit path", "Forest walk", "River run", "Canyon climb"]

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

  private static func channelDiff(_ a: UInt32, _ b: UInt32) -> Int {
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

  private static func hex(_ c: UInt32) -> String { String(format: "#%06X", c) }
  private static let threshold = 12
  /// Two colours are one flat colour if no channel differs by more than this.
  private static let flat = 4

  /// One colour of what focus drew, and where: on the page (where the page
  /// was before focus) or on the control.
  struct Band: CustomStringConvertible {
    let colour: UInt32
    let onPage: Bool
    let pixels: Int
    let contrast: Double
    let against: [UInt32]
    var description: String {
      "\(pixels) px \(V14FocusIndicatorsUITests.hex(colour)) \(onPage ? "on the page" : "on the control") "
        + "\(String(format: "%.2f", contrast)) against \(against.map { V14FocusIndicatorsUITests.hex($0) }.joined(separator: ", "))"
    }
  }

  struct Indicator: CustomStringConvertible {
    var changed = 0, unstable = 0, swapped = 0, strong = 0
    var page: UInt32 = 0
    var bands: [Band] = []
    /// Every changed pixel, whatever it replaced.
    var indicator: Int { changed }
    /// The drawing moved rather than focus adding to it: half or more of
    /// the colours the changed pixels took were there before, among them.
    var moved: Bool { changed > 0 && swapped * 2 >= changed }
    /// The largest band's contrast, or 1 if nothing was drawn.
    var ratio: Double { bands.first?.contrast ?? 1 }
    var description: String {
      "changed \(changed), unstable \(unstable), swapped \(swapped), indicator \(changed), "
        + "3:1 or more: \(strong), page \(V14FocusIndicatorsUITests.hex(page)); "
        + bands.prefix(3).map { $0.description }.joined(separator: "; ")
    }
  }

  /// What focus drew in `region` (in pixels), given the screenshot before
  /// focus and two after.
  ///
  /// A pixel has changed if it differs from `u` in both and `f1` and `f2`
  /// agree. Every changed pixel is part of the indicator, whatever it
  /// replaced: Understanding 1.4.11 does not compare the focused and
  /// unfocused states. (What replaced what is used once, to tell a drawing
  /// that moved from one that focus added to: `Indicator.moved`.) The
  /// indicator is split into bands, one per flat colour (pixels that share
  /// their colour with a horizontal and a vertical neighbour; anti-aliased
  /// edges are left out), and each band is taken against the colours
  /// adjacent to it in `f1`, read across at most four pixels of anti-aliased
  /// edge. A band drawn where the page was, outside the control, must
  /// contrast with the page; a band drawn on the control, inside it or on
  /// its border, must contrast with every colour that makes up a fifth or
  /// more of what is next to it (with the page, if nothing does). The page's
  /// colour is the commonest along the region's edge in `u`.
  static func compare(_ u: Shot, _ f1: Shot, _ f2: Shot, _ region: CGRect) -> Indicator {
    let l = max(0, Int(region.minX)), t = max(0, Int(region.minY))
    let r = min(u.width, Int(region.maxX.rounded(.up))), b = min(u.height, Int(region.maxY.rounded(.up)))
    func inside(_ x: Int, _ y: Int) -> Bool { x >= l && x < r && y >= t && y < b }
    var edge: [UInt32: Int] = [:]
    for x in l..<r { for y in [t, t + 1, b - 2, b - 1] { edge[u.at(x, y), default: 0] += 1 } }
    var result = Indicator()
    let page = edge.max { $0.value < $1.value }!.key
    result.page = page
    func same(_ x: Int, _ y: Int, _ c: UInt32) -> Bool { inside(x, y) && channelDiff(f1.at(x, y), c) <= flat }
    func solid(_ x: Int, _ y: Int) -> Bool {
      let c = f1.at(x, y)
      return (same(x - 1, y, c) || same(x + 1, y, c)) && (same(x, y - 1, c) || same(x, y + 1, c))
    }
    func across(_ x0: Int, _ y0: Int, _ dx: Int, _ dy: Int, _ colour: UInt32) -> UInt32? {
      var x = x0, y = y0
      while same(x + dx, y + dy, colour) { x += dx; y += dy }
      for _ in 0..<4 {
        x += dx; y += dy
        if !inside(x, y) { return nil }
        let c = f1.at(x, y)
        if channelDiff(c, colour) > threshold && solid(x, y) { return c }
      }
      return nil
    }
    struct Key: Hashable { let colour: UInt32; let onPage: Bool }
    var groups: [Key: [(Int, Int)]] = [:]
    var newColours: [UInt32: Int] = [:], oldColours: [UInt32: Int] = [:]
    for y in t..<b {
      for x in l..<r {
        let a = u.at(x, y), p = f1.at(x, y), q = f2.at(x, y)
        let d1 = channelDiff(a, p) > threshold, d2 = channelDiff(a, q) > threshold
        if d1 && d2 && channelDiff(p, q) <= threshold {
          result.changed += 1
          newColours[p, default: 0] += 1
          oldColours[a, default: 0] += 1
          if !solid(x, y) { continue }
          groups[Key(colour: p, onPage: channelDiff(a, page) <= threshold), default: []].append((x, y))
        } else if d1 || d2 {
          result.unstable += 1
        }
      }
    }
    for (key, pixels) in groups {
      var next: [UInt32: Int] = [:]
      for (x, y) in pixels {
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
          if let c = across(x, y, dx, dy, key.colour) { next[c, default: 0] += 1 }
        }
      }
      let total = next.values.reduce(0, +)
      var against = [page]
      if !key.onPage && total > 0 {
        let major = next.filter { $0.value * 5 >= total }.map { $0.key }
        if !major.isEmpty { against = major }
      }
      let contrast = against.map { ratio(key.colour, $0) }.min()!
      if contrast >= 3 { result.strong += pixels.count }
      result.bands.append(Band(colour: key.colour, onPage: key.onPage, pixels: pixels.count, contrast: contrast, against: against))
    }
    result.bands.sort { $0.pixels > $1.pixels }
    result.swapped = newColours.reduce(0) { $0 + min($1.value, oldColours[$1.key] ?? 0) }
    return result
  }

  /// A frame, 8 points larger on every side, in pixels.
  private func region(_ f: CGRect, _ scale: CGFloat) -> CGRect {
    let g = f.insetBy(dx: -8, dy: -8)
    return CGRect(x: g.minX * scale, y: g.minY * scale, width: g.width * scale, height: g.height * scale)
  }

  /// Waits, at most 3 s, for two screenshots 300 ms apart that differ in no
  /// more than 1% of `e`'s region. Returns the last.
  private func settled(_ e: XCUIElement) -> Shot {
    var last = shot()
    for _ in 0..<10 {
      usleep(300_000)
      let next = shot()
      let area = region(e.frame, next.scale)
      let c = Self.compare(last, next, next, area)
      last = next
      if Double(c.changed + c.unstable) <= Double(area.width * area.height) * 0.01 { return last }
    }
    XCTFail("the screen did not settle")
    return last
  }

  /// Presses Tab and measures what changed round `e` against `before`. The
  /// element must be wholly on the screen and must not move: one that moved
  /// (scrolled into view by Tab, say) would show its own drawing moved as a
  /// change, so the test fails instead, and so it does if what changed is a
  /// drawing that moved.
  private func tabAndMeasure(_ e: XCUIElement, _ before: Shot, file: StaticString = #filePath, line: UInt = #line) -> Indicator {
    let where_ = e.frame
    XCTAssertTrue(app.frame.contains(where_), "\(e.identifier) is wholly on the screen", file: file, line: line)
    press(Self.tab)
    XCTAssertEqual(e.frame, where_, "\(e.identifier) did not move", file: file, line: line)
    let f1 = settled(e)
    usleep(700_000)
    let f2 = shot()
    let ind = Self.compare(before, f1, f2, region(where_, f1.scale))
    XCTAssertFalse(ind.moved, "the drawing moved: \(ind)", file: file, line: line)
    return ind
  }

  // MARK: Tests

  func testContrastRatioIsWCAGs() {
    XCTAssertEqual(Self.ratio(0xFFFFFF, 0x000000), 21, accuracy: 0.001)
    XCTAssertEqual(Self.ratio(0x767676, 0xFFFFFF), 4.54, accuracy: 0.01)
  }

  func testEveryControlHasItsLabelAndType() {
    for (slug, controls) in Self.controls {
      open(slug)
      for (c, label, type) in controls {
        XCTAssertEqual(control(slug, c).label, label, "\(slug) \(c)")
        XCTAssertEqual(control(slug, c).elementType, type, "\(slug) \(c)")
      }
    }
    for slug in ["good-notice-below", "bad-notice-over-list"] {
      open(slug)
      for (i, trail) in Self.trails.enumerated() {
        XCTAssertEqual(control(slug, "trail\(i + 1)").label, trail, slug)
        XCTAssertEqual(control(slug, "trail\(i + 1)").elementType, .button, slug)
      }
    }
  }

  /// For each good control: Tab draws an indicator of 3:1 or more; Space
  /// shows the stop was that control, and a second Space puts a switch or a
  /// checkbox back as it was; and when Tab moves on, with no Shift, the
  /// control's region is as it was before it had focus. Every control is
  /// measured against one screenshot, taken with focus on Back.
  func testGoodControlsDrawAnIndicatorOf3To1WhichGoesWhenFocusMovesOn() {
    for slug in ["good-material", "good-cupertino", "good-widgets"] {
      open(slug)
      press(Self.tab)  // Back
      let controls = Self.controls[slug]!
      let base = settled(control(slug, controls[0].0))
      var previous: (String, XCUIElement)?
      func expectGone(_ c: String, _ e: XCUIElement) {
        let off = settled(e)
        let gone = Self.compare(base, off, off, region(e.frame, off.scale))
        print("V14 ios \(slug) \(c) after focus left: \(gone)")
        XCTAssertEqual(gone.changed, 0, "\(slug) \(c) after focus left: \(gone)")
      }
      for (c, name, _) in controls {
        let e = control(slug, c)
        let ind = tabAndMeasure(e, base)
        print("V14 ios \(slug) \(c): \(ind)")
        XCTAssertGreaterThan(Double(ind.strong), 150 * base.scale * base.scale, "\(slug) \(c): \(ind)")
        if let (pc, pe) = previous { expectGone(pc, pe) }
        expectStop(slug, name)
        press(Self.space)
        previous = (c, e)
      }
      press(Self.tab)
      if let (pc, pe) = previous { expectGone(pc, pe) }
    }
  }

  func testBadIndicatorRemovedDrawsNothingAndBackDoes() {
    let slug = "bad-indicator-removed"
    open(slug)
    let save = control(slug, "save")
    let backButton = element(labelled: "Back")
    let before = settled(save)
    // The positive control: Tab to Back, the first stop, changes pixels
    // round it, through the same measure.
    let onBack = tabAndMeasure(backButton, before)
    print("V14 ios \(slug) back: \(onBack)")
    XCTAssertGreaterThan(Double(onBack.indicator), 100 * before.scale * before.scale, "Back: \(onBack)")
    let onSave = tabAndMeasure(save, before)
    print("V14 ios \(slug) save: \(onSave)")
    // Written to fail if a FilledButton starts to show focus some other way.
    XCTAssertEqual(onSave.changed, 0, "Save: \(onSave)")
    XCTAssertEqual(onSave.unstable, 0, "Save: \(onSave)")
    expectStop(slug, "Save")
  }

  func testBadCheckedCheckboxHaloIsUnder3To1() {
    let slug = "bad-checked-checkbox"
    open(slug)
    press(Self.tab)  // Back
    let e = control(slug, "alerts")
    let ind = tabAndMeasure(e, settled(e))
    print("V14 ios \(slug): \(ind)")
    XCTAssertGreaterThan(Double(ind.indicator), 500, "\(ind)")
    XCTAssertEqual(ind.bands.first?.onPage, true, "the halo is on the page: \(ind)")
    // Written to fail if Flutter makes the halo stand out, or adds anything
    // else at 3:1.
    XCTAssertLessThan(ind.ratio, 1.5, "\(ind)")
    XCTAssertLessThan(Double(ind.strong), Double(ind.indicator) * 0.02, "\(ind)")
    expectStop(slug, "Weather alerts")
  }

  func testBadCupertinoRingIsUnder3To1() {
    let slug = "bad-cupertino-ring"
    open(slug)
    press(Self.tab)  // Back
    let e = control(slug, "save")
    let ind = tabAndMeasure(e, settled(e))
    print("V14 ios \(slug): \(ind)")
    XCTAssertGreaterThan(Double(ind.indicator), 500, "\(ind)")
    XCTAssertEqual(ind.bands.first?.onPage, true, "the ring is on the page: \(ind)")
    // Written to fail if Flutter darkens the ring, or adds anything else at
    // 3:1.
    XCTAssertLessThan(ind.ratio, 3, "\(ind)")
    XCTAssertLessThan(Double(ind.strong), Double(ind.indicator) * 0.02, "\(ind)")
    expectStop(slug, "Save")
  }

  /// How much of trail `i` is in sight: inside the screen and the list's
  /// box, and not under the notice, as a fraction of its height.
  private func visible(_ slug: String, _ i: Int) -> CGFloat {
    let t = control(slug, "trail\(i)").frame
    let box = element("v14-\(slug)-list").frame
    let notice = element("v14-\(slug)-notice").frame
    let screen = app.frame
    let top = max(t.minY, box.minY, screen.minY), bottom = min(t.maxY, box.maxY, screen.maxY)
    if bottom <= top { return 0 }
    let hidden = max(0, min(bottom, notice.maxY) - max(top, notice.minY))
    return (bottom - top - hidden) / t.height
  }

  private func walkTrails(_ slug: String) -> [CGFloat] {
    open(slug)
    press(Self.tab)  // Back
    var seen: [CGFloat] = []
    for (i, trail) in Self.trails.enumerated() {
      press(Self.tab)
      seen.append(visible(slug, i + 1))
      expectStop(slug, trail)
    }
    print("V14 ios \(slug) visible: \(seen.map { String(format: "%.2f", $0) }.joined(separator: " "))")
    return seen
  }

  func testGoodNoticeBelowKeepsEveryFocusedTrailInSight() {
    for (i, v) in walkTrails("good-notice-below").enumerated() {
      XCTAssertEqual(v, 1, accuracy: 0.02, "trail\(i + 1)")
    }
  }

  func testBadNoticeOverListHidesTrailsFourToSix() {
    let seen = walkTrails("bad-notice-over-list")
    guard seen.count == 6 else { return XCTFail("walk incomplete") }
    // The positive control, through the same measure.
    XCTAssertEqual(seen[0], 1, accuracy: 0.02)
    XCTAssertEqual(seen[1], 1, accuracy: 0.02)
    // Written to fail if Flutter starts to scroll a focused control out
    // from under what is drawn over its view.
    for i in [4, 5, 6] { XCTAssertEqual(seen[i - 1], 0, "trail\(i)") }
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // "Last used" line, the last element of every example. Focus indicators
  // are not heard; this records what each control is to VoiceOver.
  private let speech: [(slug: String, content: [String])] = [
    ("good-material", ["Weather alerts Switch button off Double tap to toggle setting.", "Save Button"]),
    ("good-cupertino", ["Weather alerts Switch button off Double tap to toggle setting.", "Save Button"]),
    ("good-widgets", ["Ridge trail Button"]),
    // Swiping stops once, silently, before the first trail (the walk
    // checks the stop is real: VoiceOverWalk.afterNoSpeech), and goes from
    // the last trail in the box's view to the notice: the trails scrolled
    // out of the box are not reached by swiping. Not V14's subject; the
    // spec hands it on.
    ("good-notice-below", [VoiceOverWalk.silent, "Ridge trail Button", "Lake loop Button", "Summit path Button", "Trail conditions are updated every morning."]),
    ("bad-indicator-removed", ["Save Button"]),
    ("bad-checked-checkbox", ["Weather alerts Switch button on Double tap to toggle setting."]),
    ("bad-cupertino-ring", ["Save Button"]),
    // A trail under the notice is read like any other; only Canyon climb,
    // scrolled out of the box, is not reached.
    ("bad-notice-over-list", [VoiceOverWalk.silent, "Ridge trail Button", "Lake loop Button", "Summit path Button", "Forest walk Button", "River run Button", "Trail conditions are updated every morning."]),
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
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Last used:")
      let content = VoiceOverWalk.content(spoken, endingWith: "Last used:")
      print("V14VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the last line: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
