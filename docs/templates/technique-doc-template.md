---
id: <ID>
title: <Title, identical to the registered technique>
group: <First word of the group title: Semantics, Visual, Interaction, Forms, Components>
platforms:
  android: applies
  ios: applies
  web: applies
wcag: ["n.n.n"]
flutter: <version from .fvmrc>
---

# <ID> <Title>

<The rule, in one or two sentences.>

Code: [`lib/techniques/<folder>/examples.dart`](../../lib/techniques/<folder>/examples.dart).
Spec: [`docs/specs/<ID>-<name>.md`](../specs/<ID>-<name>.md).
In the app: `/t/<ID>`, and each example at `/t/<ID>/<slug>`.

## Why it matters

<Who is affected and what goes wrong for them. Plain language, no jargon.>

## WCAG 2.2

- [n.n.n Name](https://www.w3.org/TR/WCAG22/#anchor): <why>.

## Good examples

| Example | How | Source |
| --- | --- | --- |
| `good-…` | The code that does it, and what it gives the user. | [Source](url) |

## Bad examples

Each has one defect, and the tests assert that the defect is present.

| Example | Defect | Fails |
| --- | --- | --- |
| `bad-…` | … | n.n.n |

## What each platform exposes

Measured on Flutter <version>.

| | Web | Android | iOS |
| --- | --- | --- | --- |
| … | … | … | … |

<Platform differences in the bad examples. "Not verified" where that is the truth.>

## Flutter limitations

Found on Flutter <version>. Full detail is in the
[limitations log](../flutter-limitations.md).

- [FL-nnn](../flutter-limitations.md#fl-nnn): <one line>.

## How it is tested

| Layer | Where | Run |
| --- | --- | --- |
| Widget tests | `test/techniques/<name>_test.dart` | `flutter test` |
| Web tree | `web_tests/<name>.spec.js` | … |
| Android tree | `android/app/src/androidTest/.../<Name>Test.kt` | … |
| TalkBack speech | same test class, `talkBackWalk` | `python3 tool/talkback.py <ID>` |
| iOS tree | `ios/RunnerUITests/<Name>UITests.swift` | … |
| VoiceOver speech (iOS) | same test class, `testVoiceOverSpeech` | `python3 tool/voiceover_ios.py <ID>` |
| VoiceOver speech (web) | `web_tests/vo/<name>_vo.spec.js` | `python3 tool/voiceover_web.py <ID>` |

Transcripts: [TalkBack](../evidence/<ID>/talkback-android.md), …

Not yet covered: <what is left, plainly>.
