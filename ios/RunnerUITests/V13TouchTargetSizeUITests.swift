// L3 (tree and taps) and L4 (VoiceOver) for V13 Minimum touch target size
// on iOS.
// Spec: docs/specs/V13-touch-target-size.md.
//
// XCUITest's frames are in points, which are Flutter's logical pixels on
// iOS, and are Flutter's semantics node; a tap is taken where Flutter's hit
// test says (docs/evidence/probes/v13/README.md). Points to tap are 2 points
// inside or outside an edge, worked out after the frame has stopped moving.
import XCTest

/// The targets that fail WCAG 2.5.8 among `targets`: an undersized one
/// passes only if a circle 24 across, centred on it, meets no other target
/// and no other undersized target's circle. The same rule as
/// wcag258Failures in the widget tests.
func wcag258Failures(_ targets: [(String, CGRect)]) -> [String] {
  let minimum: CGFloat = 24
  func undersized(_ r: CGRect) -> Bool { r.width < minimum || r.height < minimum }
  var failures: [String] = []
  for (id, r) in targets where undersized(r) {
    for (other, o) in targets where other != id {
      let nx = min(max(r.midX, o.minX), o.maxX)
      let ny = min(max(r.midY, o.minY), o.maxY)
      if hypot(nx - r.midX, ny - r.midY) < minimum / 2 {
        failures.append("\(id): its circle meets \(other)")
      } else if undersized(o) && hypot(o.midX - r.midX, o.midY - r.midY) < minimum {
        failures.append("\(id): its circle meets the circle of \(other)")
      }
    }
  }
  return failures
}

final class V13TouchTargetSizeUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "V13"
  static let countLabel = "Presses"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private static let names = [("previous", "Previous"), ("play", "Play"), ("next", "Next")]
  private static let good = ["good-material", "good-cupertino", "good-custom"]
  private static let link = "good-inline-link"
  private static let bad = ["bad-shrinkwrap", "bad-zero-padding-web", "bad-cupertino-small", "bad-custom-small"]
  /// Each control's frame in points on iOS. bad-zero-padding-web is padded
  /// to 48 by 48 here by the theme; its defect is in a desktop browser
  /// (FL-412).
  private static let size: [String: CGFloat] = [
    "good-material": 48, "good-cupertino": 48, "good-custom": 48,
    "bad-shrinkwrap": 18, "bad-zero-padding-web": 48, "bad-cupertino-small": 18, "bad-custom-small": 18,
  ]

  private func ids(_ slug: String) -> [String] {
    slug == Self.link ? ["v13-\(Self.link)-rules"] : Self.names.map { "v13-\(slug)-\($0.0)" }
  }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(ids(slug)[0]), file: file, line: line)
  }

  /// The frame of `id` once it is the same on two reads 250 ms apart.
  private func settled(_ id: String, file: StaticString = #filePath, line: UInt = #line) -> CGRect {
    var r = element(id).frame
    let deadline = Date().addingTimeInterval(5)
    while Date() < deadline {
      usleep(250_000)
      let next = element(id).frame
      if next == r { return r }
      r = next
    }
    XCTFail("\(id) was still moving after 5 seconds, last at \(r)", file: file, line: line)
    return r
  }

  private func presses(_ slug: String) -> Int {
    Int(countElement(slug).label.replacingOccurrences(of: "\(Self.countLabel): ", with: "")) ?? -1
  }

  private func tapAt(_ x: CGFloat, _ y: CGFloat) {
    app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
  }

  /// Taps at a point of `id`'s frame and expects `delta` more presses.
  private func tap(_ slug: String, _ id: String, expecting delta: Int, _ why: String,
                   file: StaticString = #filePath, line: UInt = #line, at point: (CGRect) -> CGPoint) {
    let before = presses(slug)
    let p = point(settled(id))
    tapAt(p.x, p.y)
    // When nothing is to change, give a stray press time to show.
    if delta == 0 { usleep(1_500_000) }
    expectCount(slug, before + delta, file: file, line: line)
    usleep(300_000)
    XCTAssertEqual(presses(slug), before + delta, "\(id): \(why)", file: file, line: line)
  }

  /// A tap that must do nothing, checked alone, then the positive control
  /// in the same launch: a tap at the centre of `id`, which must press it.
  private func expectNothing(_ slug: String, _ id: String, _ why: String,
                             file: StaticString = #filePath, line: UInt = #line, at point: @escaping (CGRect) -> CGPoint) {
    tap(slug, id, expecting: 0, why, file: file, line: line, at: point)
    tap(slug, id, expecting: 1, "the tap at its centre after \(why)", file: file, line: line) { CGPoint(x: $0.midX, y: $0.midY) }
  }

  func testEveryControlHasItsNameTypeAndSizeInPoints() {
    for slug in Self.good + [Self.link] + Self.bad {
      open(slug)
      for id in ids(slug) {
        let control = element(id)
        XCTAssertTrue(control.isEnabled, id)
        if slug == Self.link {
          XCTAssertEqual(control.label, "trail rules", id)
          XCTAssertEqual(control.elementType, .link, id)
          continue
        }
        XCTAssertEqual(control.label, Self.names.first { id.hasSuffix("-\($0.0)") }!.1, id)
        XCTAssertEqual(control.elementType, .button, id)
        let r = settled(id)
        XCTAssertEqual(r.width, Self.size[slug]!, accuracy: 0.5, "\(id) width in points")
        XCTAssertEqual(r.height, Self.size[slug]!, accuracy: 0.5, "\(id) height in points")
      }
    }
  }

  func testGoodExamplesHaveNoTargetUnder24By24() {
    for slug in Self.good + ["bad-zero-padding-web"] {
      open(slug)
      let targets = ids(slug).map { ($0, settled($0)) }
      for (id, r) in targets {
        XCTAssertTrue(r.width >= 24 && r.height >= 24, "\(id) is \(r.size)")
      }
      XCTAssertEqual(wcag258Failures(targets), [], slug)
    }
  }

  func testBadExamplesFailEvenWithTheSpacingException() {
    for slug in Self.bad where slug != "bad-zero-padding-web" {
      open(slug)
      let targets = ids(slug).map { ($0, settled($0)) }
      XCTAssertEqual(targets[1].1.minX - targets[0].1.maxX, 4, accuracy: 0.5, "\(slug) gap 1")
      XCTAssertEqual(targets[2].1.minX - targets[1].1.maxX, 4, accuracy: 0.5, "\(slug) gap 2")
      let failing = Set(wcag258Failures(targets).map { String($0.split(separator: ":")[0]) })
      XCTAssertEqual(failing, Set(ids(slug)), slug)
    }
  }

  func testTheLinkIsUnder24High() {
    open(Self.link)
    let r = settled("v13-\(Self.link)-rules")
    XCTAssertLessThan(r.height, 24)
  }

  func testEachControlTakesATapInsideItsEdgeAndNotOutside() {
    for slug in Self.good + Self.bad {
      open(slug)
      for id in ids(slug) {
        tap(slug, id, expecting: 1, "centre") { CGPoint(x: $0.midX, y: $0.midY) }
        tap(slug, id, expecting: 1, "2 points inside its bottom edge") { CGPoint(x: $0.midX, y: $0.maxY - 2) }
        expectNothing(slug, id, "2 points below its bottom edge") { CGPoint(x: $0.midX, y: $0.maxY + 2) }
      }
      // Nothing is to the right of the last control. On the web the small
      // ones' labels take a click there (FL-411); here they do not.
      expectNothing(slug, ids(slug).last!, "2 points right of its right edge") { CGPoint(x: $0.maxX + 2, y: $0.midY) }
    }
  }

  func testTheLinkTakesATapAndNotOneJustBelowIt() {
    open(Self.link)
    let id = "v13-\(Self.link)-rules"
    tap(Self.link, id, expecting: 1, "centre") { CGPoint(x: $0.midX, y: $0.midY) }
    expectNothing(Self.link, id, "2 points below it") { CGPoint(x: $0.midX, y: $0.maxY + 2) }
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // count, the last element of every example. Size is not heard: the small
  // buttons are read as the large ones.
  private static let player = ["Previous Button", "Play Button", "Next Button"]
  // The sentence is read in its order, the link in its place (FL-413's
  // workaround in good-inline-link).
  private var speech: [(slug: String, content: [String])] {
    (Self.good + Self.bad).map { ($0, Self.player) }
      + [(Self.link, ["Read the", "trail rules Link", "before you set off."])]
  }

  func testVoiceOverSpeech() throws {
    // XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
    // older Xcode the symbol does not exist, so an availability check alone
    // would not compile; the body is compiled only where the SDK has it.
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Presses:")
      let content = Self.exampleContent(spoken)
      print("V13VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
