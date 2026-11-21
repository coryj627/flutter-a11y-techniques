import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../catalog/test_id.dart';
import '../s02_informative_images/example_image.dart';

// #region shared
/// Where every link in these examples goes: this technique's own page in
/// the app.
const linkRoute = '/t/C03';

/// The link's address, for `Semantics(linkUrl:)`. On the web it becomes the
/// `href` of the link's `<a>` element. The app's web build keeps its route
/// after the `#`, so this address is the technique's page.
final linkAddress = Uri.parse('#$linkRoute');

/// The name of the links. It says where the link goes, on its own.
const linkText = 'Read about stand-alone links';

/// What TalkBack says a double tap does: "Double-tap to open link" in place
/// of "Double-tap to activate". Android has no link role, and TalkBack says
/// none for a Flutter link (docs/flutter-limitations.md, FL-220), so this is
/// what tells a TalkBack user it is a link, as the Android Compose reference
/// does with `onClickLabel`. `onTapHint` is used on Android only: iOS ignores
/// it, and the web engine does not read it.
const linkTapHint = 'open link';

/// What a tap on a link does. Off the web the app follows the link. On the
/// web the browser follows the link's `href` itself, on a click, on Enter,
/// and in a new tab on a Command- or Ctrl-click, so the app must not follow
/// it too: a click or Enter would then leave the screen as it was, and a
/// click with no pointer events would open the page twice
/// (docs/flutter-limitations.md, FL-013, and `bad-app-also-follows`).
void followLink(BuildContext context) {
  if (!kIsWeb) Navigator.of(context).pushNamed(linkRoute);
}

/// On the web, leaves Enter and Space to the browser. A Material `InkWell`
/// takes both keys, and a key it takes never reaches the link's `<a>`.
/// `DoNothingAndStopPropagationIntent` is a key binding that stops the key
/// in Flutter without handling it, so the browser does with it what it does
/// for any link: Enter follows it, Space scrolls the page. Off the web the
/// widget's own keys are left as they are.
class BrowserKeys extends StatelessWidget {
  const BrowserKeys({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.space):
            DoNothingAndStopPropagationIntent(),
      },
      child: child,
    );
  }
}

/// The look of link text: the theme's primary colour and an underline, so
/// that it is not told from other text by colour alone.
TextStyle linkStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return TextStyle(
    color: colors.primary,
    decoration: TextDecoration.underline,
    decorationColor: colors.primary,
  );
}

/// A 3 pixel ring in the colour of the page's text round [child] while
/// focus is on it or inside it, as in V14: `InkWell`'s own focus tint is
/// under 3:1 (docs/flutter-limitations.md, FL-430). The `Focus` here takes
/// no focus itself; it only hears when the link inside it gains or loses
/// focus.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.child});

  final Widget child;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
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
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _focused ? colors.onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// A Material link: `Semantics(link: true, linkUrl:)` round an `InkWell`,
/// at least 48 pixels tall. [onTap] is what a tap does; the good examples
/// pass [followLink].
class MaterialLink extends StatelessWidget {
  const MaterialLink({
    super.key,
    required this.child,
    required this.onTap,
    this.url,
    this.label,
    this.browserKeys = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final Uri? url;
  final String? label;

  /// Whether, on the web, Enter and Space go to the browser ([BrowserKeys]).
  /// Only a link with an address can be followed by the browser.
  final bool browserKeys;

  @override
  Widget build(BuildContext context) {
    final link = FocusRing(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      link: true,
      linkUrl: url,
      label: label,
      onTapHint: linkTapHint,
      child: browserKeys ? BrowserKeys(child: link) : link,
    );
  }
}

/// Makes [child], which takes the taps, a link with keyboard focus:
/// `Semantics` gives the role and the address, and `FocusableActionDetector`
/// the focus and, off the web, Enter and Space. On the web it registers no
/// action for them, so the keys go to the browser, which follows the link
/// on Enter. [FocusRing] shows the focus.
class KeyboardLink extends StatelessWidget {
  const KeyboardLink({super.key, required this.onFollow, required this.child});

  final VoidCallback onFollow;
  final Widget child;

  Object? _follow(Intent intent) {
    onFollow();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // The ring goes outside the detector: the detector's own focus node is
    // the one that takes focus, and FocusRing hears only focus on itself or
    // below it.
    return FocusRing(
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: kIsWeb
            ? const <Type, Action<Intent>>{}
            : {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: _follow,
                ),
                ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                  onInvoke: _follow,
                ),
              },
        child: Semantics(
          link: true,
          linkUrl: linkAddress,
          onTapHint: linkTapHint,
          child: child,
        ),
      ),
    );
  }
}

/// The example photo at the size of a small picture link. `sunrisePng` is
/// the small PNG from S02 (`example_image.dart`).
Widget picture({bool excludeFromSemantics = false, String? semanticLabel}) {
  return Image.memory(
    sunrisePng,
    width: 72,
    height: 48,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.none,
    excludeFromSemantics: excludeFromSemantics,
    semanticLabel: semanticLabel,
  );
}
// #endregion

// #region good-material
/// A link that says where it goes. `link: true` gives the link role on iOS.
/// `linkUrl` is needed as well: without it the link is a button on Android
/// and has no `href` on the web (docs/flutter-limitations.md, FL-032). With
/// it, the web has a real `<a href>`, and Android a node with no role, for
/// which `onTapHint` says it is a link (FL-220).
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-good-material-link',
      child: MaterialLink(
        url: linkAddress,
        onTap: () => followLink(context),
        child: Text(linkText, style: linkStyle(context)),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// Cupertino has no link widget. The row it has for going to another screen
/// is `CupertinoListTile` with a chevron, which has no link role and takes
/// no keyboard focus (docs/flutter-limitations.md, FL-400). [KeyboardLink]
/// gives it both. A `CupertinoButton` would not do: it is always a button,
/// and a link round it is both (`bad-cupertino-button`).
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-good-cupertino-link',
      child: KeyboardLink(
        onFollow: () => followLink(context),
        child: CupertinoListTile(
          // The tile cuts its title to one line with an ellipsis, through a
          // DefaultTextStyle with maxLines: 1. A DefaultTextStyle of the
          // title's own, with no line limit, lets the whole name wrap and
          // the row grow at large text sizes.
          title: Builder(
            builder: (context) {
              final tile = DefaultTextStyle.of(context);
              return DefaultTextStyle(
                style: tile.style,
                textAlign: tile.textAlign,
                child: const Text(linkText),
              );
            },
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => followLink(context),
        ),
      ),
    );
  }
}
// #endregion

// #region good-custom
/// A link built from the widgets layer, with no Material: [KeyboardLink]
/// round a `GestureDetector` that takes the taps.
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-good-custom-link',
      child: KeyboardLink(
        onFollow: () => followLink(context),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => followLink(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            alignment: AlignmentDirectional.centerStart,
            child: Text(linkText, style: linkStyle(context)),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-image-link
/// A picture that is the whole link. The name is on the link and says where
/// it goes; the picture is excluded, as in S04's picture buttons.
class GoodImageLink extends StatelessWidget {
  const GoodImageLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-good-image-link-link',
      child: MaterialLink(
        url: linkAddress,
        label: linkText,
        onTap: () => followLink(context),
        child: picture(excludeFromSemantics: true),
      ),
    );
  }
}
// #endregion

// #region bad-vague-text
class BadVagueText extends StatelessWidget {
  const BadVagueText({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-bad-vague-text-link',
      child: MaterialLink(
        url: linkAddress,
        onTap: () => followLink(context),
        // Defect: the text does not say where the link goes.
        child: Text('Read more', style: linkStyle(context)),
      ),
    );
  }
}
// #endregion

// #region bad-tap-handler
class BadTapHandler extends StatelessWidget {
  const BadTapHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-bad-tap-handler-link',
      // Defect: underlined text with a tap handler is not a link. It has no
      // link role and takes no keyboard focus.
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const TapHandlerPage())),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: Text(linkText, style: linkStyle(context)),
          ),
        ),
      ),
    );
  }
}

/// The page that `bad-tap-handler` opens. Nothing else in the app opens it,
/// so a keyboard that cannot reach the text cannot reach this page either.
class TapHandlerPage extends StatelessWidget {
  const TapHandlerPage({super.key});

  static const title = 'About stand-alone links';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(headingLevel: 1, child: const Text(title)),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Only the underlined text on the last screen opens this.'),
      ),
    );
  }
}
// #endregion

// #region bad-no-address
class BadNoAddress extends StatelessWidget {
  const BadNoAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-bad-no-address-link',
      child: MaterialLink(
        // Defect: no linkUrl. On Android the link is a button, and on the
        // web an <a> with no href, which has no link role. With no address
        // the app must follow it on the web as well, Enter included.
        browserKeys: false,
        onTap: () => Navigator.of(context).pushNamed(linkRoute),
        child: Text(linkText, style: linkStyle(context)),
      ),
    );
  }
}
// #endregion

// #region bad-image-no-name
class BadImageNoName extends StatelessWidget {
  const BadImageNoName({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-bad-image-no-name-link',
      child: MaterialLink(
        url: linkAddress,
        onTap: () => followLink(context),
        // Defect: no label on the link, and none on the picture.
        child: picture(),
      ),
    );
  }
}
// #endregion

// #region bad-label-on-image
class BadLabelOnImage extends StatelessWidget {
  const BadLabelOnImage({super.key});

  @override
  Widget build(BuildContext context) {
    // No TestId here: its MergeSemantics would join the picture to the link
    // and hide the defect. The key is only for the widget tests.
    return MaterialLink(
      key: const ValueKey<String>('c03-bad-label-on-image-link'),
      url: linkAddress,
      onTap: () => followLink(context),
      // Defect: the name is on the picture, not on the link. A labelled
      // Image is always an element of its own.
      child: picture(semanticLabel: linkText),
    );
  }
}
// #endregion

// #region bad-cupertino-button
class BadCupertinoButton extends StatelessWidget {
  const BadCupertinoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-bad-cupertino-button-link',
      // Defect: a CupertinoButton is always a button, so the link round it
      // is a link and a button at once.
      child: Semantics(
        link: true,
        linkUrl: linkAddress,
        child: CupertinoButton(
          onPressed: () => followLink(context),
          child: const Text(linkText),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-app-also-follows
class BadAppAlsoFollows extends StatelessWidget {
  const BadAppAlsoFollows({super.key});

  @override
  Widget build(BuildContext context) {
    return TestId(
      'c03-bad-app-also-follows-link',
      child: MaterialLink(
        url: linkAddress,
        // Defect: the app follows the link on the web too, where the
        // browser already follows its href.
        onTap: () => Navigator.of(context).pushNamed(linkRoute),
        child: Text(linkText, style: linkStyle(context)),
      ),
    );
  }
}
// #endregion
