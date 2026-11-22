import '../../catalog/technique.dart';
import 'examples.dart';

/// I04 Keyboard actions and shortcuts.
/// Spec: docs/specs/I04-keyboard-actions.md.
/// Doc: docs/techniques/I04.md.
final i04KeyboardActions = Technique(
  id: 'I04',
  title: 'Keyboard actions and shortcuts',
  group: TechniqueGroup.interaction,
  summary:
      'A custom control answers the keys its kind of control uses, a text '
      'field does what its keyboard action key says when Enter is pressed, '
      'and a single-key shortcut works only while its control has focus, '
      'or can be turned off or changed.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'A single-key shortcut was not shown to take a letter typed in a '
          'field: on one emulator the input method had the letter keys '
          'first; on another the letter was lost, and why was not '
          'recorded. The on-screen '
          "keyboard's action key was not pressed by the tests; Enter on a "
          'hardware keyboard was.',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Home, End, Page Up, and Page Down could not be sent from the '
          'tests, so those keys are not verified here. The on-screen '
          "keyboard's action key was not pressed by the tests; Enter on a "
          'hardware keyboard was. Full Keyboard Access is not verified. The '
          'remapped shortcut, Control+F, was measured on iOS 27.0 only: on '
          'iOS 26.5 a Control+F sent by the tests sometimes acted as a plain '
          'F, and why is not known.',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'The browser takes some keys before the page sees them; only keys '
          'that reached the page in the tests are claimed.',
    ),
  },
  wcag: const [
    WcagCriterion('2.1.1', 'Keyboard', 'keyboard'),
    WcagCriterion(
      '2.1.4',
      'Character Key Shortcuts',
      'character-key-shortcuts',
    ),
  ],
  sources: const [
    SourceLink(
      'Android Compose: Keyboard Actions',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/KeyboardActions.md',
    ),
    SourceLink(
      'WCAG 2.2 Understanding: Character Key Shortcuts',
      'https://www.w3.org/WAI/WCAG22/Understanding/character-key-shortcuts.html',
    ),
    SourceLink(
      'ARIA APG: Toolbar pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/',
    ),
    SourceLink(
      'MDN: Keyboard-navigable JavaScript widgets',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Keyboard-navigable_JavaScript_widgets',
    ),
    SourceLink(
      'HTML: the accesskey attribute',
      'https://html.spec.whatwg.org/multipage/interaction.html#the-accesskey-attribute',
    ),
    SourceLink(
      'Flutter: Using Actions and Shortcuts',
      'https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html',
    ),
    SourceLink(
      'Flutter API: CallbackShortcuts',
      'https://api.flutter.dev/flutter/widgets/CallbackShortcuts-class.html',
    ),
    SourceLink(
      'Flutter API: Focus.onKeyEvent',
      'https://api.flutter.dev/flutter/widgets/Focus/onKeyEvent.html',
    ),
    SourceLink(
      'Flutter API: TextField.textInputAction',
      'https://api.flutter.dev/flutter/material/TextField/textInputAction.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-on-focus',
      title: 'Shortcut that works only on its control',
      variant: ExampleVariant.widgets,
      customSolution:
          'Keys built by hand for a strip of thumbnails: a Shortcuts and '
          'Actions for the arrows, Home, End, and F; no Flutter widget has '
          'them.',
      builder: (_) => const GoodOnFocus(),
    ),
    TechniqueExample.good(
      slug: 'good-turn-off',
      title: 'Shortcut that can be turned off',
      variant: ExampleVariant.cupertino,
      customSolution:
          'Keys built by hand: a CallbackShortcuts for F that a switch turns '
          'off, the strip\'s keys in Focus.onKeyEvent, and a binding that '
          'keeps F for the text field (FL-460).',
      builder: (_) => const GoodTurnOff(),
    ),
    TechniqueExample.good(
      slug: 'good-remap',
      title: 'Shortcut that can be changed to use Control',
      variant: ExampleVariant.material,
      customSolution:
          'Keys built by hand: a CallbackShortcuts for F or Control+F, and '
          'the strip\'s keys in a CallbackShortcuts (FL-460).',
      builder: (_) => const GoodRemap(),
    ),
    TechniqueExample.bad(
      slug: 'bad-page-shortcut',
      title: 'Single-key shortcut on the whole screen',
      variant: ExampleVariant.widgets,
      defect:
          'F adds the photo to the favourites wherever focus is on the '
          'screen, and nothing turns it off or changes it. So a lowercase f '
          'typed in the note adds a favourite instead, and does not appear: '
          'on the web and iOS; not shown on Android.',
      builder: (_) => const BadPageShortcut(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-arrow-keys',
      title: 'Strip of photos with no arrow keys',
      variant: ExampleVariant.widgets,
      defect:
          'Tab reaches only the thumbnail of the photo shown, and the arrow '
          'keys do nothing, so the other photos cannot be shown from the '
          'keyboard.',
      builder: (_) => const BadNoArrowKeys(),
    ),
  ],
);
