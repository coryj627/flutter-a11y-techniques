# Spec: <ID> <Title>

Status: Draft 1 (<date>). Flutter pin: <version from .fvmrc>.

<One line on what is out of scope and which entry covers it.>

## 1. Rule

<One or two sentences. What must be true for a user of assistive technology.>

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies / Limitation / Not applicable | … | … |

<If a platform is a limitation or is not verified, say why in one line.>

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [n.n.n Name](https://www.w3.org/TR/WCAG22/#anchor) | … |

## 4. Source requirements

Read the source documents before writing this table. The coverage inventory
mapped sources by title only.

| # | Requirement | Source |
| --- | --- | --- |
| R1 | … | [CVS …](url), [APG …](url), [MDN …](url) |

Flutter references for the mechanisms used:

- [`Api.name`](https://api.flutter.dev/…)

Radix comparison bar: <the Radix primitive, or the native element if Radix has none>.

## 5. Examples

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-…` | Material / Cupertino / Widgets layer | … | SDK API only | R1 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-…` | One defect, stated as what the user experiences | R1 | n.n.n |

<If there is no Cupertino or Material example, say why.>

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | … |
| L3 web | … |
| L3 Android | … |
| L3 iOS | … |
| L4 TalkBack | … |
| L4 VoiceOver iOS | … |
| L4 VoiceOver web | … |

Where a defect cannot be observed on a platform, say so and say what is
asserted there.

## 7. What the build found (Flutter <version>)

Write this section after the build, not before. Record what each platform
actually did, what differed from the plan, which examples were dropped and
why, and every limitation with its id in
[flutter-limitations.md](../flutter-limitations.md).

**Not done yet.** <What is left, plainly.>
