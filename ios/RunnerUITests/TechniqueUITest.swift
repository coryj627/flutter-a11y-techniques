// What every technique's L3 and L4 test class on iOS shares: opening an
// example, finding elements, waiting for a count, and walking an example
// with VoiceOver. A technique's class conforms to TechniqueUITest, or to
// CountedTechniqueUITest when every one of its examples ends with a count.
import XCTest

/// A technique's test class.
protocol TechniqueUITest: XCTestCase {
  /// The technique's id, as in the app's routes: "C01".
  static var technique: String { get }
  var app: XCUIApplication { get }
}

extension TechniqueUITest {
  /// The element with the test identifier `id`.
  func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  /// Every element whose label is exactly `label`.
  func elements(labelled label: String) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label))
  }

  /// The first element whose label is exactly `label`.
  func element(labelled label: String) -> XCUIElement {
    elements(labelled: label).firstMatch
  }

  /// Cold-starts the app on the example `slug` through the `fluttera11y` URL
  /// scheme and waits up to 30 seconds for `marker`, then `settle`
  /// microseconds more.
  ///
  /// On a slow simulator the first launch can come up without the example
  /// (seen once on CI: the app started but the screen never appeared), so the
  /// launch is tried up to three times before the test fails.
  func open(
    _ slug: String, waitingFor marker: @autoclosure () -> XCUIElement, settle: useconds_t = 0,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let url = URL(string: "fluttera11y:///t/\(Self.technique)/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if marker().waitForExistence(timeout: 30) {
        if settle > 0 { usleep(settle) }
        return
      }
      print("\(Self.technique) open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  /// Scrolls the screen to its end, with VoiceOver off, as a person scrolls
  /// down to an example whose lines above it push its end below the view:
  /// for a custom solution, its note (docs/custom-solutions.md). VoiceOver's
  /// moves forward stop at the last element in view, so a walk to an
  /// element below the view never reaches it. On a screen that does not
  /// scroll this moves nothing.
  func scrollToEnd() {
    app.swipeUp()
    usleep(1_000_000)
  }
}

/// A technique whose examples each end with a count: an element identified
/// `<id>-<slug>-count` whose label is "<countLabel>: <n>".
protocol CountedTechniqueUITest: TechniqueUITest {
  /// What the count counts: "Activations" or "Changes".
  static var countLabel: String { get }
}

extension CountedTechniqueUITest {
  /// The count of the example `slug`.
  func countElement(_ slug: String) -> XCUIElement {
    element("\(Self.technique.lowercased())-\(slug)-count")
  }

  /// Waits up to 5 seconds for the count of `slug` to be `n`.
  func expectCount(_ slug: String, _ n: Int, file: StaticString = #filePath, line: UInt = #line) {
    let count = countElement(slug)
    let expected = "\(Self.countLabel): \(n)"
    let deadline = Date().addingTimeInterval(5)
    while count.label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count.label, expected, slug, file: file, line: line)
  }

  /// The utterances of the example itself: those after the last "Example
  /// Heading" and before the count. Returns nil when the walk did not pass
  /// the heading or did not end on the count, so an incomplete walk cannot
  /// pass.
  static func exampleContent(_ spoken: [String]) -> [String]? {
    VoiceOverWalk.content(spoken, endingWith: "\(countLabel):")
  }
}

/// Reading what VoiceOver says. The functions that need no device are
/// tested in S04FunctionalImagesUITests.
enum VoiceOverWalk {
  /// What a walk records for a stop at which VoiceOver said nothing.
  static let silent = "(no speech)"

  /// One utterance with every run of whitespace made one space: VoiceOver
  /// separates a label and its role with other whitespace than one space.
  static func normalized(_ utterance: String) -> String {
    utterance.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
  }

  static func isNoSpeech(_ error: NSError) -> Bool {
    error.domain == "com.apple.xctest.voiceoverservice" && error.code == 3
  }

  /// What to record for a move forward that gave no speech. `previous` is
  /// the utterance before that move, `back` what one move back then said,
  /// and `again` what the move forward after that said (nil for no speech).
  ///
  /// The stop is silent only if the move back read `previous`, which shows
  /// the cursor had gone one element past it, and the second move forward
  /// was silent as well. If the second move speaks, the first was a late
  /// answer and the speech is the element. Anything else is recorded as not
  /// known, which no expected list contains.
  static func afterNoSpeech(previous: String?, back: String, again: String?) -> String {
    guard let previous, previous != silent, back == previous else {
      return "(no speech; the cursor's position is not known)"
    }
    return again ?? silent
  }

  /// The utterances after the last "Example Heading" and before the last
  /// one, which must start with `prefix`; nil when the walk did not pass
  /// the heading or did not end there.
  static func content(_ spoken: [String], endingWith prefix: String) -> [String]? {
    guard let last = spoken.last, last.hasPrefix(prefix),
          let heading = spoken.lastIndex(of: "Example Heading") else { return nil }
    return Array(spoken[(heading + 1)..<(spoken.count - 1)])
  }
}

// XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
// older Xcode the symbol does not exist, so an availability check alone
// would not compile; this is compiled only where the SDK has it.
#if compiler(>=6.4)
@available(iOS 27.0, *)
extension VoiceOverWalk {
  /// Switches VoiceOver on, swipes right until an utterance starts with
  /// `prefix` (at most 20 moves), and switches VoiceOver off; returns what
  /// was said, normalized. A move with no speech does not show that the
  /// cursor moved, so the walk steps back and forward again to find out
  /// where it is (afterNoSpeech). Any other error ends the walk, and the
  /// test, with VoiceOver switched off.
  static func forward(_ voiceOver: XCUIVoiceOverService, toUtteranceStartingWith prefix: String) throws -> [String] {
    try voiceOver.enable()
    var voiceOverOn = true
    defer { if voiceOverOn { try? voiceOver.disable() } }
    var spoken: [String] = []
    for _ in 0..<20 {
      do {
        spoken.append(normalized(try voiceOver.moveForward().utterance))
      } catch let error as NSError where isNoSpeech(error) {
        let back = normalized(try voiceOver.moveBackward().utterance)
        var again: String? = nil
        do {
          again = normalized(try voiceOver.moveForward().utterance)
        } catch let error as NSError where isNoSpeech(error) {}
        spoken.append(afterNoSpeech(previous: spoken.last, back: back, again: again))
      }
      if spoken.last!.hasPrefix(prefix) { break }
    }
    try voiceOver.disable()
    voiceOverOn = false
    return spoken
  }

  /// Switches VoiceOver on, swipes right to the end of the screen, where
  /// the last element repeats (at most 24 moves), and switches VoiceOver
  /// off; returns what was said, with line breaks made spaces. A move that
  /// fails is skipped.
  static func forwardToRepeat(_ voiceOver: XCUIVoiceOverService) throws -> [String] {
    try voiceOver.enable()
    var spoken: [String] = []
    for _ in 0..<24 {
      guard let utterance = try? voiceOver.moveForward().utterance else { continue }
      let text = utterance.replacingOccurrences(of: "\n", with: " ")
      if spoken.last == text { break }
      spoken.append(text)
    }
    try voiceOver.disable()
    return spoken
  }
}
#endif
