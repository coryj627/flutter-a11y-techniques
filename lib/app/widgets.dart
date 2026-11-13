import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const appName = 'Flutter A11Y Techniques';

/// Where relative links in bundled docs point.
const repoBlobUrl =
    'https://github.com/coryj627/flutter-a11y-techniques/blob/main/';

/// A screen with a title that is exposed as the page title (WCAG 2.4.2) and
/// a scrolling body that reflows within a readable width.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: title == appName ? appName : '$title - $appName',
      color: Theme.of(context).colorScheme.primary,
      child: Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              // Not a ListView: a lazy list only builds, and only exposes to
              // assistive technology, what is near the viewport, so headings
              // and links further down would be missing from a screen
              // reader's lists (docs/flutter-limitations.md, FL-011).
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section heading, exposed to assistive technology as a heading.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.level = 2});

  final String text;

  /// Heading level, 2 to 6. The screen title is the level above.
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      // headingLevel, not only header: see docs/flutter-limitations.md,
      // FL-003 and FL-004.
      child: Semantics(
        header: true,
        headingLevel: level,
        child: Text(
          text,
          style: level <= 2 ? theme.titleLarge : theme.titleMedium,
        ),
      ),
    );
  }
}

class BodyText extends StatelessWidget {
  const BodyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

/// A link to an external resource, exposed with the link role.
class ExternalLink extends StatelessWidget {
  const ExternalLink({super.key, required this.title, required this.uri});

  final String title;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      link: true,
      linkUrl: uri,
      child: InkWell(
        // On web `linkUrl` makes this a real <a href>, which the browser
        // follows in this tab when it is clicked. A key press does not reach
        // the anchor (Flutter handles Enter itself), so the tap must navigate
        // too. Both therefore target this tab: opening a new tab here would
        // give a click two destinations, one in each tab. Elsewhere the link
        // opens in the browser app.
        onTap: () => launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: kIsWeb ? '_self' : null,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: Icon(
                    // "Opens elsewhere" on mobile; on web the link opens in
                    // the same tab, so the new-window icon would mislead.
                    kIsWeb ? Icons.arrow_outward : Icons.open_in_new,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
