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
      "Defect: Once opened, the app is French until it is restarted.",
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

  func testTheCollectorFailsADuplicateStopAndAnUnwitnessedEnd() {
    // Made-up walks of good-passage's screen. `moves` is what each move
    // forward reads, `back` and `again` what the end's witness reads.
    let walk = Self.speech[0].screen + Self.speech[0].content
    func run(_ moves: [String], back: String, again: String) -> S16Walk.Result {
      var i = 0
      return S16Walk.collect(
        next: { defer { i += 1 }; return i < moves.count ? moves[i] : moves.last! },
        back: { back }, forward: { again })
    }
    let last = walk.last!, before = walk[walk.count - 2]
    let cases: [(String, S16Walk.Result, Bool)] = [
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
      ("a walk that runs out of moves", S16Walk.collect(max: 3, next: { "x\(Int.random(in: 0..<1_000_000))" }, back: { "" }, forward: { "" }), false),
    ]
    for (what, result, whole) in cases {
      XCTAssertEqual(result.reachedEnd && result.problem == nil, whole, "\(what): \(result)")
    }
    // The whole walk keeps every stop once, and a judged walk of it is right.
    let right = run(walk + [last, last], back: before, again: last)
    XCTAssertEqual(right.stops, walk)
    XCTAssertEqual(S16Walk.judge(right.stops, reachedEnd: right.reachedEnd, Self.speech[0]), [])
    // The duplicate title is kept, and the judge would fail it as well.
    let dup = run([walk[0], walk[0]] + walk.dropFirst() + [last, last], back: before, again: last)
    XCTAssertEqual(dup.stops, [walk[0], walk[1]])
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
      let problems = (walk.problem.map { [$0] } ?? []) + S16Walk.judge(walk.stops, reachedEnd: walk.reachedEnd, example)
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

/// S16's VoiceOver walk, from the top of the screen to its end, keeping
/// each utterance as the service gave it (C03Walk keeps only the
/// normalized utterance, where the doubled space round a marked part is
/// gone), and judging how it ended.
///
/// A move that reads the same words as the stop before it is one of two
/// things: the cursor did not move, at the last element, or a second
/// element read alike (or speech the service gave again while nothing new
/// was said, as `currentSpeech()` does). The words cannot tell them apart,
/// so the collector does not count a repeat as the end by itself:
///
/// - A repeat followed by a different utterance is a stop read twice in a
///   row mid-screen, and the walk fails ("a duplicate stop"); it is never
///   dropped. No S16 screen has two neighbouring elements that read alike,
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
enum S16Walk {
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
