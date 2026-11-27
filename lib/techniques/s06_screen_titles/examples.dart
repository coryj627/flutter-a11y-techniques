import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Every example is a button that opens a screen of its own, the way an app
// moves from one screen to the next: a route pushed on the app's
// Navigator. The screen it opens is built from Flutter's own widgets
// through their documented parameters: Material's `Scaffold` and `AppBar`,
// Cupertino's `CupertinoPageScaffold` and `CupertinoNavigationBar`, and the
// widgets layer's `Title`, which gives the browser its document title.
// What the framework cannot do is in docs/flutter-limitations.md and is not
// built here. On the web no example is good: `Title` sets the document's
// title when a screen opens, and nothing sets it back when the screen
// closes, so after Back the browser keeps the closed screen's title
// (FL-300).

// #region shared
/// What every opened screen is about, and its title in the good examples.
const screenTitle = 'Orders';

/// The text of every opened screen.
const screenText = 'Three orders in the last 30 days.';

/// The test identifier of the opened screen's text: `s06-<slug>-text`.
String textId(String slug) => 's06-$slug-text';

/// The opened screen's text, the last thing on it.
class ScreenText extends StatelessWidget {
  const ScreenText({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        identifier: textId(slug),
        child: Text(screenText, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

/// The example: one button, `s06-<slug>-open`, that pushes the route
/// [route] builds.
class OpenScreen extends StatelessWidget {
  const OpenScreen({super.key, required this.slug, required this.route});

  final String slug;
  final Route<void> Function() route;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TestId(
        's06-$slug-open',
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(route()),
          child: const Text('Open orders'),
        ),
      ),
    );
  }
}

/// The document title the browser shows for a screen titled [title]
/// (`Title`, which `SystemChrome.setApplicationSwitcherDescription` sends
/// on). Its colour must be opaque.
Widget documentTitle(BuildContext context, String title, Widget child) => Title(
  title: title,
  color: Theme.of(context).colorScheme.primary,
  child: child,
);
// #endregion

// #region good-material
/// A Material screen: the `AppBar`'s title names the screen, and `Title`
/// gives the browser the same text. `AppBar` marks its title as the
/// route's name on Android, and as a header; `headingLevel: 1` makes it the
/// screen's level 1 heading on every platform (S05).
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (context) => documentTitle(
      context,
      screenTitle,
      Scaffold(
        appBar: AppBar(
          title: Semantics(headingLevel: 1, child: const Text(screenTitle)),
        ),
        body: const ScreenText(slug: 'good-material'),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      const OpenScreen(slug: 'good-material', route: route);
}
// #endregion

// #region good-cupertino
/// A Cupertino screen: the `CupertinoNavigationBar`'s middle names the
/// screen. The bar marks it as a header but not as the route's name, so
/// `Semantics(namesRoute: true)` says that it is
/// (docs/flutter-limitations.md, FL-301); `Title` gives the browser the
/// same text.
///
/// Not free of defects: the bar builds its own Back button, two buttons
/// whose tap target has no name (FL-303). On iOS VoiceOver lands on it as
/// the screen opens and says only "Button", which fails 4.1.2's name. On
/// the web both are named "Back" (Chromium), and on Android TalkBack reads
/// the one named "Back"; neither was shown to fail 4.1.2. Nothing in the
/// SDK names it, and the bar's button is kept.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  static Route<void> route() => CupertinoPageRoute<void>(
    builder: (context) => documentTitle(
      context,
      screenTitle,
      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Semantics(
            namesRoute: true,
            headingLevel: 1,
            child: const Text(screenTitle),
          ),
        ),
        child: const SafeArea(child: ScreenText(slug: 'good-cupertino')),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      const OpenScreen(slug: 'good-cupertino', route: route);
}
// #endregion

// #region bad-no-title
/// Defect: the screen has no title. Its name is drawn as large text in the
/// page, which is not a title: the `AppBar` has none, and there is no
/// `Title`.
class BadNoTitle extends StatelessWidget {
  const BadNoTitle({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (context) => Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              screenTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const ScreenText(slug: 'bad-no-title'),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      const OpenScreen(slug: 'bad-no-title', route: route);
}
// #endregion

// #region bad-vague-title
/// Defect: the title, "Details", does not say what the screen is about.
class BadVagueTitle extends StatelessWidget {
  const BadVagueTitle({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (context) => documentTitle(
      context,
      'Details',
      Scaffold(
        appBar: AppBar(
          title: Semantics(headingLevel: 1, child: const Text('Details')),
        ),
        body: const ScreenText(slug: 'bad-vague-title'),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      const OpenScreen(slug: 'bad-vague-title', route: route);
}
// #endregion

// #region bad-no-document-title
/// Defect: no `Title`, so the browser keeps the document title of the
/// screen before. The `AppBar`'s title is right.
class BadNoDocumentTitle extends StatelessWidget {
  const BadNoDocumentTitle({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: Semantics(headingLevel: 1, child: const Text(screenTitle)),
      ),
      body: const ScreenText(slug: 'bad-no-document-title'),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      const OpenScreen(slug: 'bad-no-document-title', route: route);
}
// #endregion

// #region bad-cupertino-unnamed
/// Defect: Cupertino's bar as it comes. Its middle is a header but not the
/// route's name (FL-301), so Android is not told the screen's name.
class BadCupertinoUnnamed extends StatelessWidget {
  const BadCupertinoUnnamed({super.key});

  static Route<void> route() => CupertinoPageRoute<void>(
    builder: (context) => documentTitle(
      context,
      screenTitle,
      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Semantics(headingLevel: 1, child: const Text(screenTitle)),
        ),
        child: const SafeArea(child: ScreenText(slug: 'bad-cupertino-unnamed')),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      const OpenScreen(slug: 'bad-cupertino-unnamed', route: route);
}
// #endregion
