import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const appName = 'Flutter A11Y Techniques';

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
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: children,
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
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      // headingLevel, not only header: on Flutter 3.47.5 `header: true` alone
      // is not announced as a heading by VoiceOver on iOS and is always an
      // <h2> on web (docs/plan.md, headings finding).
      child: Semantics(
        header: true,
        headingLevel: 2,
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
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
        onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
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
                    Icons.open_in_new,
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
