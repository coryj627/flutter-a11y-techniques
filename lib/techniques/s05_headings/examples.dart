import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// #region shared
/// Body copy between headings.
class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

TextStyle? _headingStyle(BuildContext context, int level) {
  final text = Theme.of(context).textTheme;
  return switch (level) {
    <= 3 => text.titleLarge,
    4 => text.titleMedium,
    _ => text.titleSmall,
  };
}
// #endregion

// #region good-levels
/// A heading states that it is a heading and what level it is with
/// `Semantics(headingLevel:)`. Levels follow the page outline: the screen
/// title is level 1 and the "Example" section above is level 2, so this
/// content starts at level 3 and does not skip a level on the way down.
class GoodHeadingLevels extends StatelessWidget {
  const GoodHeadingLevels({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading('Profile', level: 3),
        _Body('Your name and photo are shown to other members.'),
        Heading('Contact details', level: 4),
        _Body('We use these to reach you about your account.'),
        Heading('Email preferences', level: 4),
        _Body('Choose which messages you receive.'),
        Heading('Security', level: 3),
        _Body('Manage your password and sign-in methods.'),
      ],
    );
  }
}

/// Text exposed to assistive technology as a heading of [level].
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, required this.level});

  final String text;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Semantics(
        header: true,
        headingLevel: level,
        child: Text(text, style: _headingStyle(context, level)),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// The header of a Cupertino list section is not a heading on its own, so
/// it is given one.
class GoodCupertinoSectionHeading extends StatelessWidget {
  const GoodCupertinoSectionHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: Semantics(
        header: true,
        headingLevel: 3,
        child: const Text('Notifications'),
      ),
      children: const [
        CupertinoListTile(title: Text('Order updates')),
        CupertinoListTile(title: Text('Offers')),
      ],
    );
  }
}
// #endregion

// #region bad-visual-only
class BadVisualOnlyHeading extends StatelessWidget {
  const BadVisualOnlyHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          // Defect: looks like a heading, but is plain text to assistive
          // technology.
          child: Text('Profile', style: _headingStyle(context, 3)),
        ),
        const _Body('Your name and photo are shown to other members.'),
      ],
    );
  }
}
// #endregion

// #region bad-fake-label
class BadFakeHeadingLabel extends StatelessWidget {
  const BadFakeHeadingLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Profile',
            // Defect: the word "heading" is put in the name. It sounds
            // close, but heading navigation cannot find it.
            semanticsLabel: 'Profile, heading',
            style: _headingStyle(context, 3),
          ),
        ),
        const _Body('Your name and photo are shown to other members.'),
      ],
    );
  }
}
// #endregion

// #region bad-skipped-level
class BadSkippedLevel extends StatelessWidget {
  const BadSkippedLevel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading('Profile', level: 3),
        _Body('Your name and photo are shown to other members.'),
        // Defect: level 5 directly under level 3; level 4 is skipped.
        Heading('Contact details', level: 5),
        _Body('We use these to reach you about your account.'),
      ],
    );
  }
}
// #endregion

// #region bad-header-only
class BadHeaderOnly extends StatelessWidget {
  const BadHeaderOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          // Defect (Flutter limitation): `header: true` with no level.
          child: Semantics(
            header: true,
            child: Text('Profile', style: _headingStyle(context, 3)),
          ),
        ),
        const _Body('Your name and photo are shown to other members.'),
      ],
    );
  }
}
// #endregion

// #region bad-emphasis-heading
class BadEmphasisHeading extends StatelessWidget {
  const BadEmphasisHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Heading('Delivery', level: 3),
        const _Body('Orders placed before noon leave the same day.'),
        // Defect: a sentence marked as a heading to make it stand out. It
        // introduces no section, and it clutters heading navigation.
        Semantics(
          header: true,
          headingLevel: 4,
          child: Text(
            'Please check your address before you pay.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const _Body('We cannot change an address after dispatch.'),
      ],
    );
  }
}
// #endregion

// #region bad-cupertino-section-header
class BadCupertinoSectionHeader extends StatelessWidget {
  const BadCupertinoSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      // Defect (Flutter limitation): the section header looks like a heading
      // but CupertinoListSection does not expose it as one.
      header: const Text('Notifications'),
      children: const [
        CupertinoListTile(title: Text('Order updates')),
        CupertinoListTile(title: Text('Offers')),
      ],
    );
  }
}
// #endregion
