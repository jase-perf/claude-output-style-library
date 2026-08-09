# The enforce hook

`--enforce` (bash) / `-Enforce` (PowerShell) installs a `UserPromptSubmit` hook
that re-states your active output style on every turn. It is optional, and the
[README](../README.md#make-it-stick---enforce) explains when to want it. This
file covers how it behaves.

macOS and Linux get [`style-reminder.sh`](../hooks/style-reminder.sh); Windows
gets [`style-reminder.ps1`](../hooks/style-reminder.ps1).

## Why it exists

A custom style is part of the system prompt, read once at session start. Claude
Code re-states its *built-in* styles every turn; a custom style gets no such
reinforcement, which is why a custom voice can drift out of a long conversation.

The evidence here conflicts, which is why the hook ships opt-in rather than by
default. Claude Code's [output styles
docs](https://code.claude.com/docs/en/output-styles) say "**All** output styles
trigger reminders for Claude to adhere to the output style instructions during
the conversation," which would make this hook redundant. Against that: reading
the shipped binary shows the reminder consumer looking up a built-ins-only table
and returning nothing for a custom style, and no such reminder has been observed
in practice.

We have not run a controlled test, so we are not claiming the docs are wrong.
Turn the hook on if you notice your style fading in long conversations, which is
the symptom either way.

## Settings precedence

The hook resolves the active style through the same chain Claude Code does,
taking the project directory from the hook's own stdin payload:

```
<cwd>/.claude/settings.local.json  →  <cwd>/.claude/settings.json  →  ~/.claude/settings.json
```

This matters because `/config` writes your output style to the **project's**
`settings.local.json`, not the user-level file. A hook that read only
`~/.claude/settings.json` would sit inside a project that had overridden the
style and cheerfully reinforce the global one every turn — worse than no
reminder at all.

## Behaviour

- **Silent for built-in styles** (`Explanatory`, `Learning`, `Proactive`) and
  for `default`, so you never get a doubled reminder.
- **Every code path exits 0.** A missing, empty, half-written, or malformed
  settings file falls through to the next file in the chain rather than breaking
  a turn. This runs on every prompt you submit, so failing loudly would be worse
  than failing quietly.
- **Costs roughly 17 tokens per turn.** The reminder names the active style; it
  does not re-inject the style body, which already lives in the system prompt.
- **Registers once.** Re-running the installer does not add a second copy.

## Removing it

Delete the entry from `~/.claude/settings.json` → `hooks.UserPromptSubmit`. The
hook script itself lives at `~/.claude/hooks/style-reminder.sh` (or `.ps1`) and
can be deleted too.

## Tests

[`tests/test-hook.sh`](../tests/test-hook.sh) and
[`tests/Test-Hook.ps1`](../tests/Test-Hook.ps1) cover the full precedence chain,
fall-through on missing/empty/malformed settings, silence for each built-in
style, and that every path exits 0. Both run in CI on Ubuntu, macOS and Windows.
