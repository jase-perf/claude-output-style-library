<h1 align="center">awesome-claude-output-styles</h1>

<p align="center">
  <strong>Make Claude talk like a human. Pick a voice, install it with one command.</strong>
</p>

<p align="center">
  17 ready-to-install output styles for Claude Code, built on named, credited methodologies —<br>
  from Simplified Technical English to the Minto Pyramid to bedtime stories.
</p>

<p align="center"><sub>MIT · one style is 18+ · every style keeps code, errors and numbers byte-exact</sub></p>

---

## Why

Claude Opus 5 got this reaction in August 2026 (Niklas Gruhn,
["Don't be a meat proxy"](https://gruhn.me/blog/2026-08-03/)):

> Reading AI output is extra effort. It's verbose, frequently contains all too
> plausible nonsense, and is increasingly jargon dense. I recently got this
> sentence from Claude:
>
> *"NATS control-plane events: stream leader election / R3 quorum re-form
> during pod churn."*
>
> Jesus. I had to lookup almost every word to make sense of this.

He's not alone — the complaint threads run hundreds of upvotes, and the word
"Claudisms" now has [its own field guide](docs/claudisms-2026.md). The model
is brilliant; the register is exhausting. An **output style** fixes this at
the right layer: it modifies the system prompt itself, and Claude Code keeps
reminding the model to follow it — unlike CLAUDE.md rules, which are injected
once and decay over a long session.

This repo is a curated hub: each style distills a real methodology by a named
author, rewritten as a correct, modern Claude Code output style with shared
safety guardrails.

## Install

One style (installs **and** activates it):

```bash
curl -fsSL https://raw.githubusercontent.com/smixs/awesome-claude-output-styles/main/install.sh | bash -s -- eli15
```

Everything (installs all 17 + the style-maker skill; activate later via `/config`):

```bash
curl -fsSL https://raw.githubusercontent.com/smixs/awesome-claude-output-styles/main/install.sh | bash -s -- --all
```

A style takes effect after restarting Claude Code or `/clear`. Switch or turn
off anytime: `/config` → **Output style**. (The old `/output-style` command
was removed in v2.1.91 — most guides online are outdated.)

## The styles

### Understand — for explaining to humans

| Style | What it does | Rooted in |
|---|---|---|
| [`plain-english`](output-styles/plain-english.md) | Simplified Technical English: ≤20-word sentences, one word one meaning | ASD-STE100 (aerospace, 1983), [SimpleEnglish](https://github.com/AminBlg/SimpleEnglish), [wait-what](https://github.com/mattpocock/skills) |
| [`eli15`](output-styles/eli15.md) | Smart-teenager explanations: one analogy, its breaking point, a line to remember | ELI5 prompt research, r/explainlikeimfive rules |
| [`analogy-engine`](output-styles/analogy-engine.md) | One sustained analogy with part-by-part mapping | IEEE ProComm, JCOM 2025, CMU metaphor checklist |
| [`feynman`](output-styles/feynman.md) | Teaches, names the hard part, checks understanding with questions | Richard Feynman's technique |
| [`thing-explainer`](output-styles/thing-explainer.md) | Only the ten hundred most common words | Randall Munroe, [Up Goer Five](https://xkcd.com/1133/) |
| [`ladder`](output-styles/ladder.md) | Every answer at 3 levels: like I'm 5 → 15 → pro | the classic r/PromptEngineering pattern |

### Business — for decision-makers

| Style | What it does | Rooted in |
|---|---|---|
| [`executive`](output-styles/executive.md) | Answer first, ≤3 reasons, evidence on request | Barbara Minto's Pyramid Principle, BLUF |
| [`smart-brevity`](output-styles/smart-brevity.md) | 6-word tease, "Why it matters:", "Go deeper:" | Smart Brevity (Axios) |
| [`coach`](output-styles/coach.md) | One note, one image, one next action — every word earns its place | Hemingway App rules, Paul Graham's "Write Like You Talk" |

### Terse — for speed

| Style | What it does | Rooted in |
|---|---|---|
| [`caveman`](output-styles/caveman.md) | Ultra-compact: same signal, all fluff dropped | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) |
| [`adhd`](output-styles/adhd.md) | Action first, numbered steps, lists ≤5, visible progress | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) |
| [`no-slop`](output-styles/no-slop.md) | A plain, specific human voice — the anti-Claudism style | the [2026 Claudisms field guide](docs/claudisms-2026.md), [humanizer](https://github.com/blader/humanizer), [avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing) |

### Fun — personas that still get it right

| Style | What it does | Note |
|---|---|---|
| [`street`](output-styles/street.md) | Sharp senior engineer in modern street slang | **18+**, profanity |
| [`gen-z`](output-styles/gen-z.md) | Brainrot wrapper, exact engineering inside | slang dated by design, and that's the joke |
| [`sportscaster`](output-styles/sportscaster.md) | Live play-by-play on your codebase | the persona rules genuinely improve explanations |
| [`yoda`](output-styles/yoda.md) | Wise mentor; inverted syntax only on the closing lesson | precision first, poetry second |
| [`bedtime-story`](output-styles/bedtime-story.md) | Concepts as tiny calming stories | five sentences, real mechanism |

## Before / after

Real Opus 5 sentence from the July 2026 complaint threads:

> Coverage-aware cost projection: ledger-derived cost figures with exact,
> lower-bound, and unavailable states

Same content through `plain-english`:

> Do not show incomplete cost totals as exact. Say "at least $X" or "unknown".

## Make your own: style-maker

Presets not fitting? Install the interview skill:

```bash
curl -fsSL https://raw.githubusercontent.com/smixs/awesome-claude-output-styles/main/install.sh | bash -s -- style-maker
```

Then tell Claude **"make my output style"**. It asks ~10 questions (audience,
length, jargon level, tone, samples of writing you like and hate), generates
a personal style file following this repo's conventions — countable specs,
positive framing, safety guardrails — shows you a live demo, and activates it.

## Shared design rules

Every style in this hub follows the same conventions
(full authoring guide: [docs/format-guide.md](docs/format-guide.md)):

- **Specs, not adjectives.** "No sentence over 20 words" is checkable;
  "be clear" is not.
- **Positive framing.** Styles describe the voice they want. Ban lists summon
  the banned patterns — so the [Claudism list](docs/claudisms-2026.md) lives
  in docs for humans, not inside prompts.
- **Byte-exact guardrails.** Code, commands, error messages, file paths, and
  numbers are never stylized. Every persona shuts off for security warnings,
  destructive-action confirmations, and order-critical instructions.
- **Cut ceremony, not reasoning.** Styles shrink the wrapper, never the
  "why".
- `keep-coding-instructions: true` everywhere — the engineering stays intact.

## The wider catalog

Original-author projects worth knowing, beyond what's adapted here:

- [mattpocock/skills](https://github.com/mattpocock/skills) — `wait-what`, the
  four-line re-pitch panic button, and `writing-for-agents`, the best
  methodology for writing agent-consumed docs. Install from his repo.
- [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — the
  original, with six intensity levels, 30+ agent integrations and real
  benchmarks.
- [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) — the top
  community answer to Opus 5 verbosity.
- [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish) —
  ASD-STE100 enforcement with a deterministic linter.
- [blader/humanizer](https://github.com/blader/humanizer) — the definitive
  AI-writing-pattern remover (33 patterns, self-audit loop).
- [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) —
  8 rules plus a 50-point scoring rubric.
- [nattergabriel/claude-code-output-styles](https://github.com/nattergabriel/claude-code-output-styles) —
  13 well-crafted styles (Socratic, Roast, Ship It…).
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) —
  the canonical Claude Code index, with an Output Styles category.

## Sister project

[**pohuy**](https://github.com/smixs/pohuy) — the Russian profanity output
style that started this collection. Same guardrails, four roots, 18+.

## Contributing

PRs welcome. One style per PR, following
[docs/format-guide.md](docs/format-guide.md): named methodology with credits,
countable specs, positive framing, the shared guardrails block, one
before/after example, a verify clause. If you're the original author of a
methodology we adapted and want changes — open an issue, you outrank us.

## License

[MIT](LICENSE). Adapted styles preserve their sources' copyright notices; see
credit lines in each style file.
