# Claudisms, 2026 field guide

A reader's reference for the writing patterns Claude Opus 4.8/5 became
infamous for in mid-2026. This list exists for humans — reviewers, editors,
people wondering "is it just me?". It is deliberately NOT pasted into any
style file in this repo: a banlist this long would spend system-prompt budget
in every session to state negatively what a style can state positively in a
fraction of the space. The `plain-prose` style displaces these patterns by
describing the opposite voice. (An earlier version of this note claimed
instruction-tuned models reproduce tokens you mention even inside a ban. That
does not hold for frontier models — see
[design-decisions.md](design-decisions.md#1-no-banned-word-lists--but-not-for-the-reason-everyone-gives).)

Documented across GitHub issue anthropics/claude-code#77136, the July–August
2026 Reddit threads, HN discussions, and the "Claudish" essay (slhck.info).

## Vocabulary tells

| Claudism | What it usually means |
|---|---|
| load-bearing | important, critical |
| smoking gun | the cause |
| hand-waving | vague reasoning |
| reflexive hedging | too many qualifiers |
| honest framing / worth stating plainly / worth naming precisely | (filler before a claim) |
| the real tension | the trade-off |
| carry the argument | be convincing |
| "move" as a noun ("the right move") | decision, option |
| invariants (in casual prose) | things that stay true |
| quintile / decile as casual counters | groups of five / ten |
| heterogeneous (for ordinary variety) | varied, mixed |

## Structural tells

- **Negative parallelism, sentence-initial**: "It is not X. It is Y." —
  the single most-reported pattern.
- **Fake aphorisms**: "instrumentation is the unlock", "a report is what
  leaves the room" — sounds like wisdom, carries no information.
- **Density mistaken for concision**: asked to "be concise", the model
  produces shorter but *more cryptic* text ("They're tightening,
  term-locking, and having the counter-probe answer loaded").
- **Argumentative framing**: "here's where I'd push back", "here's where I'd
  hold the line" — combat metaphors for ordinary statements.
- **Diff-narration**: describing version 2 of a document as a change-log
  against version 1, unreadable to a fresh reader.
- **Copula avoidance**: "serves as", "stands as", "functions as" — for "is".
- **Compliment-sandwich openers**: "You're right to push back, and that's
  on me."

## The canonical real-world example

From r/ClaudeCode, July 2026 — Claude's original sentence:

> Coverage-aware cost projection: ledger-derived cost figures with exact,
> lower-bound, and unavailable states

The same model, asked to say it plainly:

> Don't show incomplete cost totals as exact — say "at least $X" or
> "unknown".

That gap is what this repo exists to close.
