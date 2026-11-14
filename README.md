# Flutter A11Y Techniques

Live good and bad examples of Flutter accessibility techniques that can be tested
with TalkBack, VoiceOver, and other assistive technology, with source-referenced
documentation explaining how to build each one.

Techniques are measured against [WCAG 2.2](https://www.w3.org/TR/WCAG22/) Level A
and AA.

**Status:** early scaffold. The app shell exists; the catalog is empty.

## Independence

This project draws on the following public repositories as references:

- [cvs-health/ios-swiftui-accessibility-techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques) (Apache-2.0)
- [cvs-health/android-view-accessibility-techniques](https://github.com/cvs-health/android-view-accessibility-techniques) (Apache-2.0)
- [cvs-health/android-compose-accessibility-techniques](https://github.com/cvs-health/android-compose-accessibility-techniques) (Apache-2.0)

The project, its code, and the work have no material connection to CVS Health. It
is the work of an independent developer, not a representative of the company.

## Other references

- [ARIA Authoring Practices Guide patterns](https://www.w3.org/WAI/ARIA/apg/patterns/)
- [MDN HTML elements reference](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements)
- [Flutter accessibility](https://docs.flutter.dev/ui/accessibility)

## Project documents

- [Requirements](docs/requirements.md)
- [Coverage inventory](docs/coverage-inventory.md)
- [Architecture and vertical-slice plan](docs/plan.md)
- [Specs](docs/specs/)
- [How to add a technique](docs/technique-guide.md) and the [checklist](docs/technique-checklist.md)
- [Vertical slice review](docs/slice-review.md)

## Running

The Flutter SDK is pinned in [.fvmrc](.fvmrc) (currently 3.47.5).

```bash
flutter run -d chrome
```

```bash
flutter test
```

Platforms: Android, iOS, and Web.

## Widgetbook

Every example, with its documentation, is also in a Widgetbook built from the
same catalog:

```bash
cd widgetbook && flutter run -d chrome
```

## Flutter limitations

Accessibility issues found in the Flutter framework while building the
techniques are logged, with reproduction steps and workarounds, in
[docs/flutter-limitations.md](docs/flutter-limitations.md).

## Testing a technique

Each technique is checked at several layers: widget tests, Playwright on web,
UI Automator on Android, XCUITest on iOS, and screen reader transcripts from
TalkBack and VoiceOver. The commands are in each technique's doc, for example
[C01 Button](docs/techniques/C01.md#how-it-is-tested),
[S01 Accessible names](docs/techniques/S01.md#how-it-is-tested),
[S05 Headings](docs/techniques/S05.md#how-it-is-tested),
[F01 Text fields and labels](docs/techniques/F01.md#how-it-is-tested), and
[I12 Announcements and live regions](docs/techniques/I12.md#how-it-is-tested).

## Layout

| Path | Contents |
| --- | --- |
| `lib/app/` | App shell: catalog, technique and example screens, routing |
| `lib/catalog/` | Technique model and registry |
| `lib/techniques/` | One folder per technique |
| `test/` | Widget tests, including accessibility guideline checks |
| `docs/` | Requirements, inventory, plan, specs |

Every example has a stable route: `/t/<technique id>/<example slug>`.

## License

[MIT](LICENSE)
