# Output style format & authoring guide

How Claude Code output styles work in 2026, and the conventions every style in
this repo follows.

## The format (current as of Claude Code v2.1.178)

An output style is a markdown file with YAML frontmatter:

```markdown
---
name: ELI15
description: Explains every answer to a smart 15-year-old with one good analogy
keep-coding-instructions: true
---

(style instructions — this text is appended to the system prompt)
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

## Why an output style and not CLAUDE.md

An output style modifies the system prompt and the harness periodically reminds
the model to follow it. CLAUDE.md is injected once and decays over a long
session. If you want tone rules that hold at turn 60, the output style is the
right layer. (A one-line `UserPromptSubmit` hook pointing at the rules is the
next-strongest option.)

## Authoring conventions for styles in this repo

Every style here follows the same rules. If you contribute a style, follow them
too.

1. **`keep-coding-instructions: true`.** These styles change the voice, not the
   engineering.
2. **Specs, not adjectives.** "Clearly" is an opinion; "no sentence over 20
   words" is a spec. Every rule should be checkable: it either happened or it
   didn't.
3. **Positive framing.** Describe the voice you want and show examples of it.
   Long lists of banned words summon the banned words. One or two negative
   rules maximum, and only when there is no positive equivalent.
4. **The shared guardrails block.** Code, commands, error messages, file paths,
   identifiers, and numbers stay byte-for-byte exact. The persona switches to
   plain, complete language for security warnings, confirmations of
   destructive or irreversible actions, and multi-step instructions where
   order matters.
5. **Cut ceremony, not reasoning.** A style may shrink the wrapper, never the
   substance: the "why", the risks, and the evidence survive at full strength.
6. **Before/after examples in the body.** One or two, short. Examples steer
   models better than rules.
7. **A verify clause.** One countable self-check the model runs before
   sending ("any sentence over 20 words?", "is the analogy's breaking point
   stated?").
8. **Description by the book.** The frontmatter `description` says what the
   style does, in plain words. No self-praise, no em dashes.
