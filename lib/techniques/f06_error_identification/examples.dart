import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../catalog/test_id.dart';

// #region shared
/// What each message says: what is wrong, and how to put it right.
const _nameError = 'Enter your name.';
const _emailError = 'Enter an email address with an @, like name@example.com.';

String? _validateName(String? value) =>
    (value == null || value.trim().isEmpty) ? _nameError : null;

String? _validateEmail(String? value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value ?? '')
    ? null
    : _emailError;

/// Lays out one example and counts the forms that were sent, so people and
/// tests can tell that a form with no errors goes through. A form that is
/// sent is a status message too (WCAG 4.1.3): the count is a live region,
/// which I12 found announced on Android, iOS, and the web, and it changes
/// only when a form goes through, so a send that fails announces only its
/// error.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, VoidCallback sent) builder;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        ...widget.builder(context, () => setState(() => _count++)),
        Semantics(
          key: ValueKey<String>('f06-${widget.slug}-count'),
          identifier: 'f06-${widget.slug}-count',
          liveRegion: true,
          child: Text('Forms sent: $_count'),
        ),
      ],
    );
  }
}

/// Moves focus to a field in error. Keyboard focus moves the cursor of
/// TalkBack and of VoiceOver on the web with it; VoiceOver on iOS stays
/// where it was, so the field is also sent a [FocusSemanticEvent], which
/// moves VoiceOver there.
void _focusField(FocusNode node) {
  node.requestFocus();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    node.context?.findRenderObject()?.sendSemanticsEvent(
      const FocusSemanticEvent(),
    );
  });
}

/// The button that sends a form. A `TestId` is right here: the button is
/// one node either way. The fields are not wrapped in one (see good-form).
Widget _sendButton(String slug, VoidCallback onPressed) => TestId(
  'f06-$slug-send',
  child: FilledButton(onPressed: onPressed, child: const Text('Send')),
);
// #endregion

// #region good-form
/// A Material form. `TextFormField` shows the error under the field, puts
/// it in the field's hint, and marks the field invalid; `Form.validate()`
/// announces the first error where the platform supports announcements,
/// and on Android the error text is a live region. Focus then goes to the
/// first field in error, as both reference documents ask.
class GoodForm extends StatefulWidget {
  const GoodForm({super.key});

  @override
  State<GoodForm> createState() => _GoodFormState();
}

class _GoodFormState extends State<GoodForm> {
  final _form = GlobalKey<FormState>();
  final _name = GlobalKey<FormFieldState<String>>();
  final _email = GlobalKey<FormFieldState<String>>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _send(VoidCallback sent) {
    if (_form.currentState!.validate()) {
      sent();
      return;
    }
    for (final (field, focus) in [(_name, _nameFocus), (_email, _emailFocus)]) {
      if (field.currentState!.hasError) {
        _focusField(focus);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-form',
      builder: (context, sent) => [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              // Semantics(identifier:) and not TestId: TestId's
              // MergeSemantics would pull the error text into the field's
              // name, so it would be read twice (see bad-merged-error).
              Semantics(
                identifier: 'f06-good-form-name',
                child: TextFormField(
                  key: _name,
                  focusNode: _nameFocus,
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    // Room for the whole message at 200% text on a narrow phone; the
                    // default is one line, cut off with an ellipsis.
                    errorMaxLines: 8,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Semantics(
                identifier: 'f06-good-form-email',
                child: TextFormField(
                  key: _email,
                  focusNode: _emailFocus,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    errorMaxLines: 8,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        _sendButton('good-form', () => _send(sent)),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A Cupertino form. The Cupertino library has no field that does all of
/// this, so each part is given as `InputDecorator` gives it: the field is
/// named, carries the error as its hint and its validation result, and the
/// visible error is a live region only where the platform cannot announce
/// (Android). `Form.validate()` announces the first error elsewhere.
class GoodCupertino extends StatefulWidget {
  const GoodCupertino({super.key});

  @override
  State<GoodCupertino> createState() => _GoodCupertinoState();
}

class _GoodCupertinoState extends State<GoodCupertino> {
  final _form = GlobalKey<FormState>();
  final _name = GlobalKey<FormFieldState<String>>();
  final _email = GlobalKey<FormFieldState<String>>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _send(VoidCallback sent) {
    if (_form.currentState!.validate()) {
      sent();
      return;
    }
    for (final (field, focus) in [(_name, _nameFocus), (_email, _emailFocus)]) {
      if (field.currentState!.hasError) {
        _focusField(focus);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, sent) => [
        Form(
          key: _form,
          child: CupertinoFormSection.insetGrouped(
            margin: EdgeInsets.zero,
            children: [
              _CupertinoField(
                fieldKey: _name,
                id: 'f06-good-cupertino-name',
                label: 'Name',
                focusNode: _nameFocus,
                validator: _validateName,
              ),
              _CupertinoField(
                fieldKey: _email,
                id: 'f06-good-cupertino-email',
                label: 'Email',
                focusNode: _emailFocus,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TestId(
            'f06-good-cupertino-send',
            child: CupertinoButton.filled(
              onPressed: () => _send(sent),
              child: const Text('Send'),
            ),
          ),
        ),
      ],
    );
  }
}

const _errorRed = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFC4001A),
  darkColor: Color(0xFFFF8A80),
);

/// One Cupertino row: the label beside the field, the error under it.
class _CupertinoField extends StatelessWidget {
  const _CupertinoField({
    required this.fieldKey,
    required this.id,
    required this.label,
    required this.focusNode,
    required this.validator,
    this.keyboardType,
  });

  final GlobalKey<FormFieldState<String>> fieldKey;
  final String id;
  final String label;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: fieldKey,
      validator: validator,
      builder: (field) => CupertinoFormRow(
        // The field is named below; the visible label is not read twice.
        prefix: ExcludeSemantics(child: Text(label)),
        error: field.errorText == null
            ? null
            : Semantics(
                container: true,
                // As InputDecorator does: where announcements are not
                // supported, the error itself is announced when it appears.
                liveRegion: !MediaQuery.supportsAnnounceOf(context),
                child: Text(
                  field.errorText!,
                  // The row's default red is 3.5:1 on white; this is 4.5:1
                  // or more in light and dark.
                  style: TextStyle(color: _errorRed.resolveFrom(context)),
                ),
              ),
        child: Semantics(
          identifier: id,
          label: label,
          hint: field.errorText,
          validationResult: field.hasError
              ? SemanticsValidationResult.invalid
              : SemanticsValidationResult.valid,
          child: CupertinoTextField.borderless(
            focusNode: focusNode,
            keyboardType: keyboardType,
            onChanged: field.didChange,
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-color-only
class BadColorOnly extends StatefulWidget {
  const BadColorOnly({super.key});

  @override
  State<BadColorOnly> createState() => _BadColorOnlyState();
}

class _BadColorOnlyState extends State<BadColorOnly> {
  final _form = GlobalKey<FormState>();
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-color-only',
      builder: (context, sent) => [
        Form(
          key: _form,
          child: Semantics(
            identifier: 'f06-bad-color-only-email',
            child: TextFormField(
              focusNode: _focus,
              // Defect: the error has no words. The field turns red, and
              // nothing says what is wrong.
              validator: (value) => _validateEmail(value) == null ? null : '',
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        _sendButton('bad-color-only', () {
          if (_form.currentState!.validate()) {
            sent();
          } else {
            _focusField(_focus);
          }
        }),
      ],
    );
  }
}
// #endregion

// #region bad-vague-message
class BadVagueMessage extends StatefulWidget {
  const BadVagueMessage({super.key});

  @override
  State<BadVagueMessage> createState() => _BadVagueMessageState();
}

class _BadVagueMessageState extends State<BadVagueMessage> {
  final _form = GlobalKey<FormState>();
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-vague-message',
      builder: (context, sent) => [
        Form(
          key: _form,
          child: Semantics(
            identifier: 'f06-bad-vague-message-email',
            child: TextFormField(
              focusNode: _focus,
              // Defect: the message says something is wrong, not what or
              // how to put it right, though the app knows both.
              validator: (value) =>
                  _validateEmail(value) == null ? null : 'Invalid.',
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        _sendButton('bad-vague-message', () {
          if (_form.currentState!.validate()) {
            sent();
          } else {
            _focusField(_focus);
          }
        }),
      ],
    );
  }
}
// #endregion

// #region bad-not-announced
class BadNotAnnounced extends StatefulWidget {
  const BadNotAnnounced({super.key});

  @override
  State<BadNotAnnounced> createState() => _BadNotAnnouncedState();
}

class _BadNotAnnouncedState extends State<BadNotAnnounced> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-not-announced',
      builder: (context, sent) => [
        Semantics(
          identifier: 'f06-bad-not-announced-email',
          // Marked invalid as a FormField would mark it, so that the one
          // defect is the missing announcement.
          validationResult: _error == null
              ? SemanticsValidationResult.none
              : SemanticsValidationResult.invalid,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: _error,
              errorMaxLines: 8,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _sendButton('bad-not-announced', () {
          // Defect: the error is set with setState, outside a Form, and
          // focus stays on the button. Nothing announces it on iOS or the
          // web (on Android this field's error text is a live region).
          setState(() => _error = _validateEmail(_controller.text));
          if (_error == null) sent();
        }),
      ],
    );
  }
}
// #endregion

// #region bad-merged-error
class BadMergedError extends StatefulWidget {
  const BadMergedError({super.key});

  @override
  State<BadMergedError> createState() => _BadMergedErrorState();
}

class _BadMergedErrorState extends State<BadMergedError> {
  final _form = GlobalKey<FormState>();
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-merged-error',
      builder: (context, sent) => [
        Form(
          key: _form,
          // Defect: MergeSemantics around the field takes in its error
          // text as well. The error becomes part of the field's name as well
          // as its hint, and on Android the whole field is a live region.
          child: MergeSemantics(
            child: Semantics(
              identifier: 'f06-bad-merged-error-email',
              child: TextFormField(
                focusNode: _focus,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  errorMaxLines: 8,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
        _sendButton('bad-merged-error', () {
          if (_form.currentState!.validate()) {
            sent();
          } else {
            _focusField(_focus);
          }
        }),
      ],
    );
  }
}
// #endregion
