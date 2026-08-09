# Output style format & authoring guide

How Claude Code output styles work in 2026, and the conventions every style in
this repo follows.

## The format (current as of Claude Code v2.1.223)

An output style is a markdown file with YAML frontmatter:

```markdown
---
name: ELI15
description: Explains every answer to a smart 15-year-old with one good analogy
keep-coding-instructions: true
---

(style instructions — this text is injected into the system prompt verbatim)
```

Frontmatter fields:

| Field | Purpose | Default |
|---|---|---|
| `name` | Style name shown in the picker and used as the `outputStyle` value | filename |
| `description` | One line shown in the `/config` picker | none |
| `keep-coding-instructions` | Keep Claude Code's built-in software-engineering instructions | `false` |
| `force-for-plugin` | Plugin-only: apply automatically while the plugin is enabled | `false` |

Install locations: `~/.claude/output-styles/` (user), `.claude/output-styles/`
(project). On name collision the file closest to cwd wins.

## Activating a style

The old `/output-style` command was removed in v2.1.91. Today:

- `/config` → **Output style** → pick one, or
- set `"outputStyle": "<Name>"` in a settings file (our installer writes
  `~/.claude/settings.json`).

A style is part of the system prompt, read once at session start — it takes
effect after you restart Claude Code or run `/clear`.

## Why the format below works

An active style is injected into the system prompt verbatim, in the same slot
where Claude Code keeps its own built-in styles (Explanatory, Learning,
Proactive). Styles written in the built-ins' exact shape — an identity line,
a `# <Name> Style Active` marker, procedural condition→action rules — read
as native to the harness; styles written like documentation get treated like
documentation. Two practical consequences:

- Every byte of the body is a byte of system prompt. Credits, links, and
  commentary for humans dilute the instructions — they belong in the README,
  not in the style.
- The harness reinforces its built-in styles every turn; a custom style is
  injected once per session, which is why custom voices fade in long
  conversations. The installer's enforce flag closes the gap: it registers
  [style-reminder.sh](../hooks/style-reminder.sh) (macOS/Linux) or
  [style-reminder.ps1](../hooks/style-reminder.ps1) (Windows) as a
  `UserPromptSubmit` hook that gives the active custom style the same
  per-turn reinforcement.

## Why an output style and not CLAUDE.md

An output style modifies the system prompt itself and reframes the agent's
identity around it — CLAUDE.md is context injected alongside everything else.
For tone rules, the style is the stronger layer; with the `--enforce` hook it
also gets the per-turn reinforcement that built-in styles enjoy.

## Authoring conventions for styles in this repo

Every style here follows the same rules. If you contribute a style, follow them
too.

1. **Mirror the built-in structure.** Body starts with the identity line —
   "You are an interactive agent that helps users with software engineering
   tasks. In addition to completing those tasks, you must …" — followed by a
   `# <Name> Style Active` header, then the rules. Claude Code reads this
   shape as one of its own.
2. **`keep-coding-instructions: true`.** These styles change the voice, not
   the engineering.
3. **Specs, not adjectives.** "Clearly" is an opinion; "no sentence over 20
   words" is a spec. Every rule should be checkable: it either happened or it
   didn't. Frame rules as triggers where possible: "In every response…",
   "When challenged, …".
4. **Positive framing — for a reason that survives checking.** Describe the
   voice you want and show an example of it. Anthropic's own prompting
   guidance says so directly, under the heading *Control the format of
   responses*: "**Tell Claude what to do instead of what not to do**" — with a
   worked example that is itself a style rule ("Do not use markdown in your
   response" → "Your response should be composed of smoothly flowing prose
   paragraphs"). Output styles are formatting and voice instructions, which is
   exactly the slot that guidance sits in.

   **What this guide used to say, and why it was wrong.** It claimed "long
   lists of banned words summon the banned words", and capped negative rules
   at "one or two maximum". The cap had no source. The claim has been measured
   once, in Castricato et al., *Suppressing Pink Elephants with Direct
   Principle Feedback* ([arXiv:2402.07896](https://arxiv.org/abs/2402.07896)),
   Table 1 — rate of mentioning the forbidden topic, base → with prohibition:

   | Model | Base | Prohibited | Effect |
   |---|---|---|---|
   | OpenHermes-7B | 0.33 | 0.36 | backfires, +3pp |
   | OpenHermes-13B | 0.34 | 0.34 | none |
   | Llama-2-13B-Chat | 0.33 | 0.25 | helps |
   | GPT-4 | 0.33 | 0.13 | helps most, −61% relative |

   *If you check that table against the paper:* its caption ("Rate at which
   the model talks about the Pink Elephant, lower is better") and the bullet
   defining the same column ("proportion of examples where the model
   successfully refrained") point in opposite directions. The caption, the
   narrative text, and the signed deltas in both Table 1 and the appendix all
   agree with each other, so the reading above is the right one — but the
   contradiction is in the source, not in this summary.

   The effect exists only in the weakest model tested and reverses with
   capability. Prefer positive framing because it is first-party guidance and
   because a described target is more directly actionable than a list of
   things to avoid — not because prohibitions backfire on a frontier model.
   They do not. Keep a prohibition wherever it states the constraint most
   exactly, and keep every safety prohibition unconditionally.

   When flipping a rule to positive, hold force and specificity constant:
   "no sentence over 20 words" → "every sentence stays under 20 words", not
   "prefer short sentences". Losing the number is a downgrade; losing the
   "never" is not.
5b. **Guardrails first, and give the rules their own `## Rules` heading.**
   Instruction adherence shows a measured primacy bias — earlier instructions
   are followed better — and the guardrails are the rules whose silent omission
   costs most. Putting `## Guardrails` above the rules therefore helps, but
   *only* if the rules then start their own `## ` section: otherwise the
   guardrails section runs on until the next heading and swallows them, and
   `tests/check-styles.sh` can no longer tell whether its four required clauses
   came from the guardrails or from a rule. The test now rejects that layout.

5. **The shared guardrails block.** Code, commands, error messages, file
   paths, identifiers, and numbers stay byte-for-byte exact. The persona
   switches to plain, complete language for security warnings, confirmations
   of destructive or irreversible actions, and multi-step instructions where
   order matters.
6. **Cut ceremony, not reasoning.** A style may shrink the wrapper, never the
   substance: the "why", the risks, and the evidence survive at full strength.
7. **One positive example in the body.** Show the target voice only — a
   "before" block would inject the exact prose you're displacing into the
   system prompt of every session. Before/after contrasts live in the README,
   for humans.
8. **A verify clause — format only, never correctness.** One or two countable
   self-checks on the *shape* of the draft ("any sentence over 20 words?", "is
   the analogy's breaking point stated?"). Never generic re-checking
   ("double-check your answer", "re-verify before responding"): Anthropic's
   Claude Opus 5 guidance says explicit verification instructions cause
   over-verification and should be removed, and it is talking about
   correctness. A format self-check is a different thing and earns its place,
   because the measured dominant failure mode is *silent omission* of a rule —
   which is exactly what a shape check catches.
9. **Zero human-facing content in the body.** No credits, no links, no
   meta-commentary about the style's history or design. Attribution lives in
   [CREDITS.md](CREDITS.md) and the README tables.
10. **Description by the book.** The frontmatter `description` says what the
    style does, in plain words. No self-praise, no em dashes.
