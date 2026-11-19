import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../catalog/test_id.dart';

// #region shared
/// The photos of the trail, in order.
const _photos = ['Trailhead', 'Bridge', 'Ridge', 'Summit'];

/// What every example keeps: the photo shown, the favourites, and how many
/// notes were saved. People and tests read all three in the example.
class _Album extends ChangeNotifier {
  int _shown = 0;
  final Set<int> _favourites = {};
  int _notes = 0;

  int get shown => _shown;
  bool get isFavourite => _favourites.contains(_shown);

  void show(int index) {
    final next = index.clamp(0, _photos.length - 1);
    if (next == _shown) return;
    _shown = next;
    notifyListeners();
  }

  void toggleFavourite() {
    if (!_favourites.remove(_shown)) _favourites.add(_shown);
    notifyListeners();
  }

  /// Saves [text] as a note on the photo shown; blank text is not saved.
  void saveNote(String text) {
    if (text.trim().isEmpty) return;
    _notes++;
    notifyListeners();
  }
}

/// Lays out one example: the photo shown, what [builder] returns, then the
/// favourites and the count of notes saved, so that people and tests can
/// see what a key did.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final Widget Function(BuildContext context, _Album album) builder;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  final _album = _Album();

  @override
  void dispose() {
    _album.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.slug;
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _album,
      builder: (context, _) {
        final favourites = [
          for (var i = 0; i < _photos.length; i++)
            if (_album._favourites.contains(i)) _photos[i],
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // The photo, drawn by hand. Its text says which it is.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    Icons.landscape_outlined,
                    size: 40,
                    color: colors.onSurfaceVariant,
                  ),
                  Flexible(
                    child: Semantics(
                      key: ValueKey<String>('i04-$slug-showing'),
                      identifier: 'i04-$slug-showing',
                      child: Text(
                        'Showing: ${_photos[_album.shown]}, '
                        '${_album.shown + 1} of ${_photos.length}',
                        style: TextStyle(color: colors.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            widget.builder(context, _album),
            Semantics(
              key: ValueKey<String>('i04-$slug-favourites'),
              identifier: 'i04-$slug-favourites',
              liveRegion: true,
              child: Text(
                'Favourites: '
                '${favourites.isEmpty ? 'none' : favourites.join(', ')}',
              ),
            ),
            Semantics(
              key: ValueKey<String>('i04-$slug-count'),
              identifier: 'i04-$slug-count',
              liveRegion: true,
              child: Text('Notes saved: ${_album._notes}'),
            ),
          ],
        );
      },
    );
  }
}

/// What the strip's keys do: each shows a photo and moves focus to its
/// thumbnail.
class _Moves {
  _Moves(this._album, this._focus);

  final _Album _album;
  final void Function(int index) _focus;

  void show(int index) {
    _album.show(index);
    _focus(_album.shown);
  }

  void previous() => show(_album.shown - 1);
  void next() => show(_album.shown + 1);
  void first() => show(0);
  void last() => show(_photos.length - 1);
}

/// A thumbnail of each photo, a button that shows it. The strip is one
/// stop in the Tab order: only the thumbnail of the photo shown can be
/// reached with Tab, and the others are reached with keys that [keys]
/// adds around the strip, as in a toolbar (the roving tab stop of MDN's
/// "Keyboard-navigable JavaScript widgets"). Without them, the keyboard
/// reaches one thumbnail only. A screen reader, a tap, and a click reach
/// every one.
class _Strip extends StatefulWidget {
  const _Strip({required this.slug, required this.album, required this.keys});

  final String slug;
  final _Album album;
  final Widget Function(_Moves moves, Widget strip) keys;

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  final _nodes = [for (final photo in _photos) FocusNode(debugLabel: photo)];
  late final _moves = _Moves(widget.album, (i) => _nodes[i].requestFocus());

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shown = widget.album.shown;
    for (var i = 0; i < _photos.length; i++) {
      _nodes[i].skipTraversal = i != shown;
    }
    final strip = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _photos.length; i++)
          TestId(
            'i04-${widget.slug}-${_photos[i].toLowerCase()}',
            child: Semantics(
              selected: i == shown,
              child: OutlinedButton(
                focusNode: _nodes[i],
                onPressed: () => _moves.show(i),
                style: i == shown
                    ? OutlinedButton.styleFrom(
                        backgroundColor: colors.secondaryContainer,
                        foregroundColor: colors.onSecondaryContainer,
                        side: BorderSide(color: colors.onSurface, width: 2),
                      )
                    : null,
                child: Text(_photos[i]),
              ),
            ),
          ),
      ],
    );
    return widget.keys(_moves, strip);
  }
}

/// The keys of the strip, in words, above it, so that they are met first.
/// It is a semantics node of its own: a `Shortcuts`, `CallbackShortcuts`,
/// or `Focus` around plain text otherwise takes the text as the name of a
/// node that holds every control inside it, a group named by this line on
/// the web (docs/flutter-limitations.md, FL-464).
class _KeysHint extends StatelessWidget {
  const _KeysHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// Adds the photo shown to the favourites, or takes it out: the way to do
/// it without a shortcut. Its name says which it will do.
class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.slug, required this.album});

  final String slug;
  final _Album album;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TestId(
      'i04-$slug-favourite',
      child: IconButton(
        tooltip: album.isFavourite
            ? 'Remove from favourites'
            : 'Add to favourites',
        icon: Icon(album.isFavourite ? Icons.star : Icons.star_border),
        onPressed: album.toggleFavourite,
      ),
    ),
  );
}

/// A note on the photo shown. Enter on a hardware keyboard, and the action
/// key of an on-screen keyboard, save it: `TextInputAction.done` names the
/// key, and `onSubmitted` runs for both. The field is then empty again.
class _NoteField extends StatefulWidget {
  const _NoteField({required this.slug, required this.album});

  final String slug;
  final _Album album;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TestId(
    'i04-${widget.slug}-note',
    child: TextField(
      controller: _text,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Note',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (text) {
        widget.album.saveNote(text);
        _text.clear();
      },
    ),
  );
}

/// Keeps a single-key shortcut out of a text field: while [active], F does
/// nothing as a shortcut inside [child] and goes on to the field as the
/// letter. A shortcut above a text field otherwise takes the key before the
/// field can type it, on the web and on iOS (docs/flutter-limitations.md,
/// FL-460).
class _TypeF extends StatelessWidget {
  const _TypeF({this.active = true, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: {
      if (active)
        const CharacterActivator('f'):
            const DoNothingAndStopPropagationIntent(),
    },
    child: child,
  );
}

/// A move along the strip: one of the [_Moves].
class _MoveIntent extends Intent {
  const _MoveIntent(this.move);

  final void Function(_Moves moves) move;
}

class _FavouriteIntent extends Intent {
  const _FavouriteIntent();
}

void _previous(_Moves moves) => moves.previous();
void _next(_Moves moves) => moves.next();
void _first(_Moves moves) => moves.first();
void _last(_Moves moves) => moves.last();

/// The strip's own keys as shortcuts: Left and Right for the previous and
/// next photo, Home and End for the first and last.
const _stripKeys = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(_previous),
  SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(_next),
  SingleActivator(LogicalKeyboardKey.home): _MoveIntent(_first),
  SingleActivator(LogicalKeyboardKey.end): _MoveIntent(_last),
};

/// [strip] with [shortcuts] and the actions for their intents. The
/// shortcuts act only while a thumbnail has focus.
Widget _withShortcuts(
  _Album album,
  _Moves moves,
  Map<ShortcutActivator, Intent> shortcuts,
  Widget strip,
) => Shortcuts(
  shortcuts: shortcuts,
  child: Actions(
    actions: {
      _MoveIntent: CallbackAction<_MoveIntent>(
        onInvoke: (intent) => intent.move(moves),
      ),
      _FavouriteIntent: CallbackAction<_FavouriteIntent>(
        onInvoke: (_) => album.toggleFavourite(),
      ),
    },
    child: strip,
  ),
);
// #endregion

// #region good-on-focus
/// The strip has keys of its own, and F is one of them: it works only
/// while a thumbnail has focus, so typing a note, or pressing F anywhere
/// else, never sets it off. `Shortcuts` maps the keys to intents and
/// `Actions` the intents to what they do.
class GoodOnFocus extends StatelessWidget {
  const GoodOnFocus({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-on-focus',
      builder: (context, album) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const _KeysHint(
            'In the photos: Left and Right arrows for the previous and next '
            'photo, Home and End for the first and last, F to add or remove '
            'a favourite.',
          ),
          _Strip(
            slug: 'good-on-focus',
            album: album,
            keys: (moves, strip) => _withShortcuts(album, moves, const {
              ..._stripKeys,
              CharacterActivator('f'): _FavouriteIntent(),
            }, strip),
          ),
          _FavouriteButton(slug: 'good-on-focus', album: album),
          _NoteField(slug: 'good-on-focus', album: album),
        ],
      ),
    );
  }
}
// #endregion

// #region good-turn-off
/// F works wherever focus is in the example, and a switch turns it off.
/// The strip's own keys are handled in `Focus.onKeyEvent`, and the note
/// field is a `CupertinoTextField` that keeps F for typing.
class GoodTurnOff extends StatefulWidget {
  const GoodTurnOff({super.key});

  @override
  State<GoodTurnOff> createState() => _GoodTurnOffState();
}

class _GoodTurnOffState extends State<GoodTurnOff> {
  bool _shortcuts = true;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// The strip's own keys. Down and repeat both act, so holding an arrow
  /// goes on along the strip; any other key is left for the shortcuts
  /// above and for Tab.
  KeyEventResult _stripKey(_Moves moves, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final move = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => moves.previous,
      LogicalKeyboardKey.arrowRight => moves.next,
      LogicalKeyboardKey.home => moves.first,
      LogicalKeyboardKey.end => moves.last,
      _ => null,
    };
    if (move == null) return KeyEventResult.ignored;
    move();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-turn-off',
      builder: (context, album) => CallbackShortcuts(
        bindings: {
          if (_shortcuts) const CharacterActivator('f'): album.toggleFavourite,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _KeysHint(
              'In the photos: Left and Right arrows for the previous and '
              'next photo, Home and End for the first and last. '
              '${_shortcuts ? 'Anywhere here: F to add or remove a favourite.' : 'Single-key shortcuts are off.'}',
            ),
            _Strip(
              slug: 'good-turn-off',
              album: album,
              // A focus node of its own that takes no focus: it hears the
              // keys pressed on any thumbnail inside it.
              keys: (moves, strip) => Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (_, event) => _stripKey(moves, event),
                child: strip,
              ),
            ),
            _FavouriteButton(slug: 'good-turn-off', album: album),
            TestId(
              'i04-good-turn-off-setting',
              child: MergeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: CupertinoListTile(
                    padding: EdgeInsets.zero,
                    title: const Text('Single-key shortcuts'),
                    trailing: CupertinoSwitch(
                      value: _shortcuts,
                      onChanged: (value) => setState(() => _shortcuts = value),
                    ),
                    onTap: () => setState(() => _shortcuts = !_shortcuts),
                  ),
                ),
              ),
            ),
            CupertinoFormRow(
              padding: EdgeInsets.zero,
              prefix: const ExcludeSemantics(child: Text('Note  ')),
              child: TestId(
                'i04-good-turn-off-note',
                child: Semantics(
                  label: 'Note',
                  child: _TypeF(
                    active: _shortcuts,
                    child: CupertinoTextField(
                      controller: _note,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (text) {
                        album.saveNote(text);
                        _note.clear();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region good-remap
/// F works wherever focus is in the example, and a switch changes it to
/// Control+F. The strip's own keys are a `CallbackShortcuts`. While the
/// shortcut is F, the note field keeps F for typing.
class GoodRemap extends StatefulWidget {
  const GoodRemap({super.key});

  @override
  State<GoodRemap> createState() => _GoodRemapState();
}

class _GoodRemapState extends State<GoodRemap> {
  bool _control = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-remap',
      builder: (context, album) => CallbackShortcuts(
        bindings: {
          _control
              ? const SingleActivator(LogicalKeyboardKey.keyF, control: true)
              : const CharacterActivator('f'): album
              .toggleFavourite,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _KeysHint(
              'In the photos: Left and Right arrows for the previous and '
              'next photo, Home and End for the first and last. Anywhere '
              'here: ${_control ? 'Control+F' : 'F'} to add or remove a '
              'favourite.',
            ),
            _Strip(
              slug: 'good-remap',
              album: album,
              keys: (moves, strip) => CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowLeft):
                      moves.previous,
                  const SingleActivator(LogicalKeyboardKey.arrowRight):
                      moves.next,
                  const SingleActivator(LogicalKeyboardKey.home): moves.first,
                  const SingleActivator(LogicalKeyboardKey.end): moves.last,
                },
                child: strip,
              ),
            ),
            _FavouriteButton(slug: 'good-remap', album: album),
            TestId(
              'i04-good-remap-setting',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Control+F for favourites'),
                value: _control,
                onChanged: (value) => setState(() => _control = value),
              ),
            ),
            _TypeF(
              active: !_control,
              child: _NoteField(slug: 'good-remap', album: album),
            ),
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region bad-page-shortcut
/// `good-on-focus` with F taken off the strip and put around the whole
/// example.
class BadPageShortcut extends StatelessWidget {
  const BadPageShortcut({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-page-shortcut',
      // Defect: F is a shortcut wherever focus is in the example, even in
      // the note field, and nothing turns it off or changes it.
      builder: (context, album) => CallbackShortcuts(
        bindings: {const CharacterActivator('f'): album.toggleFavourite},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            const _KeysHint(
              'In the photos: Left and Right arrows for the previous and '
              'next photo, Home and End for the first and last. Anywhere '
              'here: F to add or remove a favourite.',
            ),
            _Strip(
              slug: 'bad-page-shortcut',
              album: album,
              keys: (moves, strip) =>
                  _withShortcuts(album, moves, _stripKeys, strip),
            ),
            _FavouriteButton(slug: 'bad-page-shortcut', album: album),
            _NoteField(slug: 'bad-page-shortcut', album: album),
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region bad-no-arrow-keys
/// `good-on-focus` without the strip's arrow keys, Home, and End.
class BadNoArrowKeys extends StatelessWidget {
  const BadNoArrowKeys({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-arrow-keys',
      builder: (context, album) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const _KeysHint('In the photos: F to add or remove a favourite.'),
          _Strip(
            slug: 'bad-no-arrow-keys',
            album: album,
            // Defect: Tab reaches only the thumbnail of the photo shown,
            // and nothing moves along the strip from there, so the other
            // photos cannot be reached from the keyboard.
            keys: (moves, strip) => _withShortcuts(album, moves, const {
              CharacterActivator('f'): _FavouriteIntent(),
            }, strip),
          ),
          _FavouriteButton(slug: 'bad-no-arrow-keys', album: album),
          _NoteField(slug: 'bad-no-arrow-keys', album: album),
        ],
      ),
    );
  }
}
// #endregion
