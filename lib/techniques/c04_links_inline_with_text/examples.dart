import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../c03_stand_alone_link/examples.dart' show BrowserKeys, linkTapHint;

// #region shared
/// One link in a sentence: its text, and the app's page it goes to.
class InlineLink {
  const InlineLink(this.text, this.route);

  final String text;
  final String route;

  /// The link's address, for `Semantics(linkUrl:)`. On the web it is the
  /// `href` of the link's `<a>`, and the app keeps its route after the `#`.
  Uri get address => Uri.parse('#$route');
}

/// The two links of the sentence. Each name says where it goes: this
/// technique's page, and C03's.
const inTextLink = InlineLink('links in text', '/t/C04');
const standAloneLink = InlineLink('stand-alone links', '/t/C03');

/// What a tap does. Off the web the app follows the link. On the web the
/// browser follows the link's `href` itself, so the app must not follow it
/// as well (docs/flutter-limitations.md, FL-013; C03's
/// `bad-app-also-follows`).
void followLink(BuildContext context, InlineLink link) {
  if (!kIsWeb) Navigator.of(context).pushNamed(link.route);
}

/// The look of link text in [color]: underlined, so that it is told from
/// the text round it by more than colour (WCAG 1.4.1).
TextStyle inlineLinkStyle(Color color, {bool underline = true}) => TextStyle(
  color: color,
  decoration: underline ? TextDecoration.underline : TextDecoration.none,
  decorationColor: color,
);

/// A 2 pixel ring in the colour of the page's text round [child] while
/// focus is on it or inside it. It is drawn outside the link's box, so that
/// it does not cover the link's letters. The `Focus` here takes no focus
/// itself; it only hears when the link inside it gains or loses focus.
class InlineFocusRing extends StatefulWidget {
  const InlineFocusRing({super.key, required this.child});

  final Widget child;

  @override
  State<InlineFocusRing> createState() => _InlineFocusRingState();
}

class _InlineFocusRingState extends State<InlineFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: _focused ? colors.onSurface : Colors.transparent,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// The link's text. A `WidgetSpan` scales its widget by the text size
/// setting as a whole, so text inside it that scales as well is scaled
/// twice: at 200% it would be four times its size
/// (docs/flutter-limitations.md, FL-241). `withNoTextScaling` leaves the
/// scaling to the `WidgetSpan`, and the link stays the size of the words
/// round it.
Widget linkText(InlineLink link, TextStyle style) =>
    MediaQuery.withNoTextScaling(child: Text(link.text, style: style));

/// A Material link in a sentence: `Semantics(link: true, linkUrl:)` round an
/// `InkWell`, as C03's `good-material` without its minimum height. A link
/// inside a sentence is exempt from the target size minimum (2.5.8).
class MaterialInlineLink extends StatelessWidget {
  const MaterialInlineLink({
    super.key,
    required this.link,
    required this.style,
  });

  final InlineLink link;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      linkUrl: link.address,
      onTapHint: linkTapHint,
      child: BrowserKeys(
        child: InlineFocusRing(
          child: InkWell(
            onTap: () => followLink(context, link),
            child: linkText(link, style),
          ),
        ),
      ),
    );
  }
}

/// A link in a sentence from the widgets layer: `FocusableActionDetector`
/// gives keyboard focus and, off the web, Enter and Space; a
/// `GestureDetector` takes the taps. On the web it registers no key action,
/// so the keys go to the browser, which follows the link on Enter.
class KeyboardInlineLink extends StatelessWidget {
  const KeyboardInlineLink({
    super.key,
    required this.link,
    required this.style,
  });

  final InlineLink link;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    void follow() => followLink(context, link);
    return InlineFocusRing(
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: kIsWeb
            ? const <Type, Action<Intent>>{}
            : {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) => follow(),
                ),
                ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                  onInvoke: (_) => follow(),
                ),
              },
        child: Semantics(
          link: true,
          linkUrl: link.address,
          onTapHint: linkTapHint,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: follow,
            child: linkText(link, style),
          ),
        ),
      ),
    );
  }
}

/// A sentence of words and links: "Read about [links in text] and
/// [stand-alone links] first." Each link is a `WidgetSpan`, so that it can
/// take keyboard focus, which a `TextSpan` cannot (`bad-text-span`).
///
/// With [inOrder], the two parts of FL-413's workaround keep each link in
/// its place for screen readers (docs/flutter-limitations.md, FL-413):
///
/// - a `semanticsIdentifier` on the first words, which makes the paragraph
///   give each run of words a node of its own, with the sort keys 0, 1, 2,
///   and so on, in place of one label with no links in it;
/// - a sort key for each link between those of the runs round it: a link
///   after the first run is 0.5, after the second 1.5. Each run here is one
///   `TextSpan`. A span with an identifier is a run of its own, so a second
///   span after it would be a second run (docs/evidence/probes/c04).
///
/// Each link's node has the identifier `c04-<slug>-link-<n>`, from 1, put on
/// the container that has the sort key; `TestId` would drop the sort key.
class LinkSentence extends StatelessWidget {
  const LinkSentence({
    super.key,
    required this.slug,
    required this.linkBuilder,
    this.links = const [inTextLink, standAloneLink],
    this.inOrder = true,
  });

  final String slug;
  final List<InlineLink> links;
  final Widget Function(InlineLink link, TextStyle style) linkBuilder;
  final bool inOrder;

  /// The words before, between, and after the links.
  List<String> get words => links.length == 1
      ? const ['Read about ', ' first.']
      : const ['Read about ', ' and ', ' first.'];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge!;
    final spans = <InlineSpan>[
      TextSpan(
        text: words.first,
        semanticsIdentifier: inOrder ? 'c04-$slug-sentence' : null,
      ),
    ];
    for (var i = 0; i < links.length; i++) {
      spans
        ..add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Semantics(
              key: ValueKey<String>('c04-$slug-link-${i + 1}'),
              container: true,
              identifier: 'c04-$slug-link-${i + 1}',
              // Between run i (key i) and run i + 1.
              sortKey: inOrder ? OrdinalSortKey(i + 0.5) : null,
              child: linkBuilder(links[i], style),
            ),
          ),
        )
        ..add(TextSpan(text: words[i + 1]));
    }
    // The links' text takes this style too; a WidgetSpan's widget does not
    // inherit the sentence's spans.
    return DefaultTextStyle.merge(
      style: style,
      child: Text.rich(TextSpan(children: spans)),
    );
  }
}
// #endregion

// #region good-material
/// Links in the theme's primary colour, underlined.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LinkSentence(
      slug: 'good-material',
      linkBuilder: (link, style) => MaterialInlineLink(
        link: link,
        style: style.merge(inlineLinkStyle(color)),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// Cupertino has no link widget either; the links are the widgets-layer
/// ones, in Cupertino's blue. `CupertinoColors.link` and `systemBlue` are
/// 4.02:1 on white, under the 4.5:1 that text needs
/// (docs/flutter-limitations.md, FL-242), so these links take the
/// high-contrast variant of `systemBlue`, in light and dark.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark
        ? CupertinoColors.systemBlue.darkHighContrastColor
        : CupertinoColors.systemBlue.highContrastColor;
    return LinkSentence(
      slug: 'good-cupertino',
      linkBuilder: (link, style) => KeyboardInlineLink(
        link: link,
        style: style.merge(inlineLinkStyle(color)),
      ),
    );
  }
}
// #endregion

// #region good-custom
/// The widgets-layer links, in the theme's primary colour.
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LinkSentence(
      slug: 'good-custom',
      linkBuilder: (link, style) => KeyboardInlineLink(
        link: link,
        style: style.merge(inlineLinkStyle(color)),
      ),
    );
  }
}
// #endregion

// #region bad-text-span
class BadTextSpan extends StatefulWidget {
  const BadTextSpan({super.key});

  @override
  State<BadTextSpan> createState() => _BadTextSpanState();
}

class _BadTextSpanState extends State<BadTextSpan> {
  late final _recognizer = TapGestureRecognizer()
    ..onTap = () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const TextSpanPage()));

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Read about '),
          // Defect: a TextSpan with a tap recognizer, the SDK's own link in
          // text, takes no keyboard focus, and has no address.
          TextSpan(
            text: inTextLink.text,
            semanticsIdentifier: 'c04-bad-text-span-link-1',
            style: inlineLinkStyle(color),
            recognizer: _recognizer,
          ),
          const TextSpan(text: ' first.'),
        ],
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

/// The page that `bad-text-span`'s link opens. Nothing else in the app
/// opens it, so a keyboard that cannot reach the link cannot reach this
/// page either.
class TextSpanPage extends StatelessWidget {
  const TextSpanPage({super.key});

  static const title = 'About links in text';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(headingLevel: 1, child: const Text(title)),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Only the link on the last screen opens this.'),
      ),
    );
  }
}
// #endregion

// #region bad-out-of-order
class BadOutOfOrder extends StatelessWidget {
  const BadOutOfOrder({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LinkSentence(
      slug: 'bad-out-of-order',
      // Defect: without FL-413's workaround the sentence is one label with
      // the links left out, and the links are read after it.
      inOrder: false,
      linkBuilder: (link, style) => MaterialInlineLink(
        link: link,
        style: style.merge(inlineLinkStyle(color)),
      ),
    );
  }
}
// #endregion

// #region bad-colour-only
class BadColourOnly extends StatelessWidget {
  const BadColourOnly({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LinkSentence(
      slug: 'bad-colour-only',
      linkBuilder: (link, style) => MaterialInlineLink(
        link: link,
        // Defect: no underline. Only the colour tells the links from the
        // words round them, and it is under 3:1 against them.
        style: style.merge(inlineLinkStyle(color, underline: false)),
      ),
    );
  }
}
// #endregion

// #region bad-merged
class BadMerged extends StatelessWidget {
  const BadMerged({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    // Defect: MergeSemantics round the sentence, which TestId also is, makes
    // the sentence and both links one element.
    return MergeSemantics(
      child: Semantics(
        identifier: 'c04-bad-merged-sentence',
        child: LinkSentence(
          slug: 'bad-merged',
          linkBuilder: (link, style) => MaterialInlineLink(
            link: link,
            style: style.merge(inlineLinkStyle(color)),
          ),
        ),
      ),
    );
  }
}
// #endregion
