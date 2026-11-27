// L3 (tree) and L4 (VoiceOver) for S16 Language of page and parts on iOS.
// Spec: docs/specs/S16-language-page-parts.md.
//
// XCUITest cannot read an element's language: neither the element's
// accessibilityLanguage nor the language attribute of its label is among
// the attributes of a snapshot (docs/evidence/probes/s16/ios.txt, the
// whole dictionary of an element). So the tree test checks the labels and
// types only, and the language is judged where VoiceOver's words show it
// (S16Walk): a button whose element is French is read with the French
// role word ("Français Bouton"), one whose element is in the app's
// English with "Button", and a label with a part in another language is
// read with a second space round the part, which an unmarked label is
// not (the probe's p08 to p16). What voice VoiceOver spoke in is not in
// the words.
import XCTest

final class S16LanguagePagePartsUITests: XCTestCase, TechniqueUITest {
  static let technique = "S16"
  let app = XCUIApplication()

  private static let lead = "The sign at the door reads:"
  private static let passage = "Bienvenue à tous nos visiteurs."
  private static let sentence = "The guide said bon voyage as we left."
  private static let languages = [("fr", "Français", "French"), ("es", "Español", "Spanish"), ("de", "Deutsch", "German")]

  override func setUp() {
    continueAfterFailure = true
  }

  /// Each example's title and the lines above its "Example" heading, as
  /// the screen shows them (ExampleScreen in lib/app/screens.dart).
  static let screens: [String: [String]] = [
    "good-passage": ["Passage in another language", "Good example for Language of page and parts. Widgets layer."],
    "good-phrase": ["Phrase in another language", "Good example for Language of page and parts. Widgets layer."],
    "good-language-menu": ["Language menu", "Good example for Language of page and parts. Material."],
    "bad-unmarked": [
      "Passage not marked", "Bad example for Language of page and parts. Widgets layer.",
      "Defect: The French passage is read as English.",
    ],
    "bad-title-in-tile": [
      "Language set inside each tile", "Bad example for Language of page and parts. Material.",
      "Defect: Each language is read as English.",
    ],
    "bad-region-tag": [
      "Language with a country", "Bad example for Language of page and parts. Widgets layer.",
      "Defect: On the web the passage is not taken as French.",
    ],
    "bad-override": [
      "Localizations.override", "Bad example for Language of page and parts. Widgets layer.",
      "Defect: The whole app becomes French, and stays French.",
    ],
  ]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: element(labelled: Self.screens[slug]![0]), file: file, line: line)
  }

  /// The labels of every element of the screen with a label, in the
  /// tree's order (one snapshot, read depth first), from the one after the
  /// "Example" heading to the end or to the "Chosen" line.
  private func exampleLabels() -> [String] {
    guard let root = try? app.snapshot() else { return ["(no snapshot)"] }
    var labels: [String] = []
    func walk(_ s: XCUIElementSnapshot) {
      if s.elementType != .window && s.elementType != .application && !s.label.isEmpty {
        labels.append(s.label)
      }
      for c in s.children { walk(c) }
    }
    walk(root)
    guard let start = labels.lastIndex(of: "Example") else { return ["(no Example heading)"] }
    return Array(labels[(start + 1)...].prefix { !$0.hasPrefix("Chosen: ") })
  }

  private func chosen(_ slug: String) -> String { element("s16-\(slug)-chosen").label }

  /// Waits up to 5 seconds for the Chosen line of `slug` to say `expected`.
  private func expectChosen(_ what: String, slug: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while chosen(slug) != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(chosen(slug), expected, what, file: file, line: line)
  }

  func testPassagesHaveTheLeadAndThePassage() {
    // On iOS the language is not in the tree XCUITest reads; these are the
    // same in every passage example. The VoiceOver walk is what differs.
    for slug in ["good-passage", "bad-unmarked", "bad-region-tag", "bad-override"] {
      open(slug)
      XCTAssertEqual(exampleLabels(), [Self.lead, Self.passage], slug)
    }
  }

  func testGoodPhraseIsOneElement() {
    open("good-phrase")
    XCTAssertEqual(exampleLabels(), [Self.sentence])
  }

  func testLanguageMenusHaveEachTileAButton() {
    for slug in ["good-language-menu", "bad-title-in-tile"] {
      open(slug)
      XCTAssertEqual(exampleLabels(), Self.languages.map { $0.1 }, slug)
      for (code, name, _) in Self.languages {
        let tile = element("s16-\(slug)-\(code)")
        XCTAssertEqual(tile.elementType, .button, "\(slug) \(name)")
        XCTAssertEqual(tile.label, name, slug)
      }
    }
  }

  func testEachTileChoosesItsLanguageByATap() {
    // In bad-title-in-tile this is the positive control: the tiles work,
    // and only their language is lost.
    for slug in ["good-language-menu", "bad-title-in-tile"] {
      for (code, _, english) in Self.languages {
        open(slug)
        expectChosen(slug, slug: slug, "Chosen: none")
        element("s16-\(slug)-\(code)").tap()
        expectChosen("\(slug) tap \(code)", slug: slug, "Chosen: \(english)")
      }
    }
  }

  /// XCUITest cannot see Flutter's keyboard focus. The first Tab goes to
  /// Back and each later Tab to the next tile, as in the widget tests, so
  /// `n + 2` Tabs reach tile `n` (from 0), and the Chosen line tells which
  /// tile the key reached. Each key is sent once, from a fresh launch; no
  /// modifier is used.
  func testEachTileChoosesItsLanguageByTabThenEnterOrSpace() {
    for slug in ["good-language-menu", "bad-title-in-tile"] {
      for (i, (_, _, english)) in Self.languages.enumerated() {
        for (key, name) in [("\n", "Enter"), (" ", "Space")] {
          open(slug)
          expectChosen(slug, slug: slug, "Chosen: none")
          for _ in 0..<(i + 2) {
            app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
            usleep(700_000)
          }
          app.typeKey(key, modifierFlags: [])
          expectChosen("\(slug), \(i + 2) Tabs then \(name)", slug: slug, "Chosen: \(english)")
        }
      }
    }
  }

  // L4. Everything VoiceOver says from the top of the screen to its end
  // (S16Walk), judged whole: the screen's own stops first, which tie the
  // walk to this example, then the example's, each compared with its runs
  // of white space made one space; and for each stop whose raw utterance
  // is given here, the raw utterance as well, where a second space round a
  // part in another language is what shows the part was marked.
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
  /// screen's lines, and the heading, each heading's role word `heading`.
  /// The walk starts on the title: the first move forward from where
  /// VoiceOver starts reads it (the first recording; Back was never a
  /// stop).
  static func screenStops(_ slug: String, heading: String = "Heading") -> [String] {
    let lines = screens[slug]!
    return ["\(lines[0]) \(heading)"] + lines.dropFirst() + ["Example \(heading)"]
  }

  static let passage2 = [lead, passage]
  static let menuGood = ["Français Bouton", "Español Botón", "Deutsch Taste", "Chosen: none"]
  static let menuBad = ["Français Button", "Español Button", "Deutsch Button", "Chosen: none"]

  static let speech: [Speech] = [
    // The words are the same in every passage example: what voice the
    // passage was read in is not in them. The lead is unmarked, and its
    // raw utterance has single spaces, as the probe's unmarked texts did.
    Speech(slug: "good-passage", screen: screenStops("good-passage"), content: passage2, raw: [0: lead, 1: passage]),
    // The phrase marked: a second space before and after it (p08, p10).
    Speech(
      slug: "good-phrase", screen: screenStops("good-phrase"), content: [sentence],
      raw: [0: "The guide said  bon voyage  as we left."]),
    // Each tile's element in its own language: its role word in it.
    Speech(slug: "good-language-menu", screen: screenStops("good-language-menu"), content: menuGood, raw: [:]),
    Speech(slug: "bad-unmarked", screen: screenStops("bad-unmarked"), content: passage2, raw: [0: lead, 1: passage]),
    // The defect: each tile's element in English, "Button" (FL-361).
    Speech(slug: "bad-title-in-tile", screen: screenStops("bad-title-in-tile"), content: menuBad, raw: [:]),
    // The defect is the web's (FL-020): iOS is given fr-FR.
    Speech(slug: "bad-region-tag", screen: screenStops("bad-region-tag"), content: passage2, raw: [0: lead, 1: passage]),
    // FL-360: the whole app French, so the role word of every element
    // with none of its own is, the English title's and heading's too.
    Speech(
      slug: "bad-override", screen: screenStops("bad-override", heading: "En-tête"),
      content: passage2, raw: [0: lead, 1: passage]),
  ]

  func testExpectedUtterancesAreShortEnough() {
    for example in Self.speech {
      for utterance in example.screen + example.content + example.raw.values {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \"\(utterance)\" is longer than VoiceOver's service returns")
      }
    }
  }

  func testTheJudgeTiesAWalkToItsScreen() {
    // Made-up walks: the judge must refuse another example's screen, a
    // missing or empty identification, a wrong or missing stop, and a raw
    // utterance whose spaces differ.
    let good = Self.speech[1]
    let right = good.screen + ["The guide said  bon voyage  as we left."]
    let cases: [(String, [String], Bool, Bool)] = [
      ("the whole screen", right, true, true),
      ("the walk did not reach the end", right, false, false),
      ("another example's screen", Self.screenStops("good-passage") + ["The guide said  bon voyage  as we left."], true, false),
      ("no title", Array(good.screen.dropFirst()) + ["The guide said  bon voyage  as we left."], true, false),
      ("an empty title", [""] + good.screen.dropFirst() + ["The guide said  bon voyage  as we left."], true, false),
      ("the title in another language's role word", ["Phrase in another language En-tête"] + good.screen.dropFirst() + ["The guide said  bon voyage  as we left."], true, false),
      ("no stops before the heading", ["Example Heading", "The guide said  bon voyage  as we left."], true, false),
      ("the phrase not marked", good.screen + ["The guide said bon voyage as we left."], true, false),
      ("a stop after the end", right + ["Extra"], true, false),
      ("nothing after the heading", good.screen, true, false),
    ]
    for (what, stops, reachedEnd, ok) in cases {
      XCTAssertEqual(S16Walk.judge(stops, reachedEnd: reachedEnd, good).isEmpty, ok, what)
    }
  }

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    for example in Self.speech {
      for utterance in example.screen + example.content where utterance.count >= 64 {
        XCTFail("\(example.slug): \"\(utterance)\" is 64 characters or more, which the service cannot return whole")
        return
      }
    }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      open(example.slug)
      let walk = try S16Walk.walk(voiceOver)
      let problems = S16Walk.judge(walk.stops, reachedEnd: walk.reachedEnd, example)
      let heading = walk.stops.map(VoiceOverWalk.normalized).lastIndex { $0.hasPrefix("Example ") }
      let shown = problems.isEmpty
        ? Array(walk.stops[(heading! + 1)...]).map(VoiceOverWalk.normalized)
        : walk.stops.map { $0.debugDescription }
      print("S16VO \(example.slug) | \(shown.joined(separator: " / "))")
      for p in problems { XCTFail("\(example.slug): \(p)") }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}

/// S16's VoiceOver walk: C03's walk (from the top of the screen to its
/// end, where moving on gives the last element again, twice), keeping each
/// utterance as the service gave it. C03Walk keeps only the normalized
/// utterance, where the doubled space round a marked part is gone.
enum S16Walk {
  /// What is wrong with a walk of `example`; empty when it is right. The
  /// walk must have reached the end; its stops up to and including the
  /// last "Example" heading must be exactly the example's screen stops,
  /// which ties it to this example's screen; and the stops after it
  /// exactly the example's content, each normalized, and for each stop
  /// with a raw utterance, exactly that.
  static func judge(_ stops: [String], reachedEnd: Bool, _ example: S16LanguagePagePartsUITests.Speech) -> [String] {
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
  /// Switches VoiceOver on, walks to the end of the screen, and switches it
  /// off. A move with no speech is handled as VoiceOverWalk.forward does.
  @available(iOS 27.0, *)
  static func walk(_ voiceOver: XCUIVoiceOverService) throws -> C03Walk.Result {
    try voiceOver.enable()
    defer { try? voiceOver.disable() }
    var stops: [String] = []
    var repeats = 0
    for _ in 0..<24 {
      var utterance: String
      do {
        utterance = try voiceOver.moveForward().utterance
      } catch let error as NSError where VoiceOverWalk.isNoSpeech(error) {
        let back = VoiceOverWalk.normalized(try voiceOver.moveBackward().utterance)
        var again: String? = nil
        do {
          again = try voiceOver.moveForward().utterance
        } catch let error as NSError where VoiceOverWalk.isNoSpeech(error) {}
        utterance = VoiceOverWalk.afterNoSpeech(
          previous: stops.last.map(VoiceOverWalk.normalized), back: back, again: again)
      }
      if VoiceOverWalk.normalized(utterance) == stops.last.map(VoiceOverWalk.normalized) {
        repeats += 1
        if repeats == 2 { return C03Walk.Result(stops: stops, reachedEnd: true) }
      } else {
        repeats = 0
        stops.append(utterance)
      }
    }
    return C03Walk.Result(stops: stops, reachedEnd: false)
  }
  #endif
}
