import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:markdown/markdown.dart' as md;

import 'widgets.dart';

/// Renders a technique's Markdown doc (`docs/techniques/<id>.md`) with the
/// shell's own accessible widgets.
///
/// The `markdown` package is used as a parser only. A ready-made Markdown
/// widget was rejected because its headings, links, and lists were not exposed
/// correctly to assistive technology (docs/plan.md, finding K4).
///
/// Supported: headings, paragraphs, bullet and numbered lists, tables, code
/// blocks, and bold, italic, and code spans. Links are listed under the block
/// they appear in, as real links, because a link inside running text is not
/// reliably reachable on every platform.
class TechniqueDocView extends StatefulWidget {
  const TechniqueDocView({
    super.key,
    required this.techniqueId,
    this.skipSections = const {},
    this.title,
    this.headingOffset = 0,
  });

  final String techniqueId;

  /// A level-2 heading shown above the doc, only when the doc exists.
  final String? title;

  /// Added to every heading level in the doc, so the doc can sit under
  /// [title] without breaking the page outline.
  final int headingOffset;

  /// Level-2 sections to leave out because the screen already shows them.
  final Set<String> skipSections;

  static String assetPath(String id) => 'docs/techniques/$id.md';

  @override
  State<TechniqueDocView> createState() => _TechniqueDocViewState();
}

class _TechniqueDocViewState extends State<TechniqueDocView> {
  Future<String?>? _source;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _source ??= DefaultAssetBundle.of(context)
        .loadString(TechniqueDocView.assetPath(widget.techniqueId))
        .then<String?>((value) => value)
        .catchError((Object _) => null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _source,
      builder: (context, snapshot) {
        final source = snapshot.data;
        if (source == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title case final title?) SectionHeading(title),
            ..._DocBuilder(
              context,
              skipSections: widget.skipSections,
              headingOffset: widget.headingOffset,
            ).build(source),
          ],
        );
      },
    );
  }
}

/// Removes the YAML front matter that technique docs start with.
String stripFrontMatter(String source) {
  if (!source.startsWith('---')) return source;
  final end = source.indexOf('\n---', 3);
  if (end < 0) return source;
  final after = source.indexOf('\n', end + 1);
  return after < 0 ? '' : source.substring(after + 1);
}

class _DocBuilder {
  _DocBuilder(
    this.context, {
    required this.skipSections,
    required this.headingOffset,
  });

  final BuildContext context;
  final Set<String> skipSections;
  final int headingOffset;

  ThemeData get _theme => Theme.of(context);

  List<Widget> build(String source) {
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    ).parse(stripFrontMatter(source));

    final widgets = <Widget>[];
    var skipping = false;
    for (final node in nodes) {
      if (node is! md.Element) continue;
      if (node.tag == 'h2') {
        skipping = skipSections.contains(node.textContent.trim());
      }
      // The screen title already names the technique.
      if (skipping || node.tag == 'h1') continue;
      widgets.addAll(_block(node));
    }
    return widgets;
  }

  List<Widget> _block(md.Element e) {
    switch (e.tag) {
      case 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        return [
          SectionHeading(
            e.textContent,
            level: (int.parse(e.tag[1]) + headingOffset).clamp(2, 6),
          ),
        ];
      case 'p':
        return [_paragraph(e), ..._links(e)];
      case 'ul' || 'ol':
        return [_list(e)];
      case 'table':
        return _table(e);
      case 'pre':
        return [_code(e)];
      case 'blockquote':
        return [
          for (final child in e.children ?? const <md.Node>[])
            if (child is md.Element) ..._block(child),
        ];
      default:
        return e.textContent.trim().isEmpty ? [] : [BodyText(e.textContent)];
    }
  }

  Widget _paragraph(md.Element e) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text.rich(
        TextSpan(children: _spans(e.children)),
        style: _theme.textTheme.bodyLarge,
      ),
    );
  }

  List<InlineSpan> _spans(List<md.Node>? nodes, [TextStyle? style]) {
    return [
      for (final node in nodes ?? const <md.Node>[])
        if (node is md.Element)
          switch (node.tag) {
            'strong' => TextSpan(
              children: _spans(
                node.children,
                (style ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            'em' => TextSpan(
              children: _spans(
                node.children,
                (style ?? const TextStyle()).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            'code' => TextSpan(
              text: node.textContent,
              style: (style ?? const TextStyle()).copyWith(
                fontFamily: 'monospace',
              ),
            ),
            'br' => const TextSpan(text: '\n'),
            // Link text stays in the sentence; the link itself is listed
            // under the block by _links.
            _ => TextSpan(children: _spans(node.children, style)),
          }
        else
          TextSpan(text: node.textContent.replaceAll('\n', ' '), style: style),
    ];
  }

  /// Every link inside [e], once each, as real links.
  List<Widget> _links(md.Element e) {
    final found = <String, String>{};
    void visit(md.Node node) {
      if (node is! md.Element) return;
      final href = node.attributes['href'];
      if (node.tag == 'a' && href != null) {
        final uri = _resolve(href);
        if (uri != null) {
          found.putIfAbsent(uri.toString(), () => node.textContent);
        }
      }
      node.children?.forEach(visit);
    }

    visit(e);
    return [
      for (final MapEntry(key: url, value: title) in found.entries)
        ExternalLink(title: title, uri: Uri.parse(url)),
    ];
  }

  /// Web links are kept. Links to files in the repository point at the
  /// repository. Links within the page are dropped.
  Uri? _resolve(String href) {
    if (href.startsWith('#')) return null;
    final uri = Uri.tryParse(href);
    if (uri == null) return null;
    if (uri.hasScheme) return uri.scheme == 'https' ? uri : null;
    return Uri.parse('${repoBlobUrl}docs/techniques/').resolveUri(uri);
  }

  Widget _list(md.Element e) {
    final ordered = e.tag == 'ol';
    final items = [
      for (final child in e.children ?? const <md.Node>[])
        if (child is md.Element && child.tag == 'li') child,
    ];
    return Semantics(
      role: SemanticsRole.list,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in items.indexed)
            Semantics(
              role: SemanticsRole.listItem,
              explicitChildNodes: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The list role already says this is a list item.
                        ExcludeSemantics(
                          child: SizedBox(
                            width: 28,
                            child: Text(
                              ordered ? '${index + 1}.' : '•',
                              style: _theme.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: _spans(item.children)),
                            style: _theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._links(item),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A table is shown as one block per row, each cell on its own line with
  /// its column header in front. This reflows on a phone at large text sizes
  /// and reads in a sensible order without table navigation.
  List<Widget> _table(md.Element table) {
    List<md.Element> cells(md.Element row) => [
      for (final c in row.children ?? const <md.Node>[])
        if (c is md.Element) c,
    ];
    final rows = <md.Element>[];
    void collect(md.Node node) {
      if (node is! md.Element) return;
      if (node.tag == 'tr') {
        rows.add(node);
      } else {
        node.children?.forEach(collect);
      }
    }

    collect(table);
    if (rows.isEmpty) return [];
    final headers = [for (final c in cells(rows.first)) c.textContent.trim()];
    final bold = const TextStyle(fontWeight: FontWeight.bold);
    return [
      for (final row in rows.skip(1))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: _theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, cell) in cells(row).indexed) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (index < headers.length &&
                                headers[index].isNotEmpty)
                              TextSpan(
                                text: '${headers[index]}: ',
                                style: bold,
                              ),
                            ..._spans(cell.children),
                          ],
                        ),
                        style: _theme.textTheme.bodyLarge,
                      ),
                    ),
                    ..._links(cell),
                  ],
                ],
              ),
            ),
          ),
        ),
    ];
  }

  Widget _code(md.Element e) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          // Wraps instead of scrolling sideways, so it reflows (WCAG 1.4.10).
          child: Text(
            e.textContent.trimRight(),
            style: _theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              color: _theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
