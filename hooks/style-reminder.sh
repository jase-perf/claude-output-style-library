#!/bin/sh
# style-reminder — a UserPromptSubmit hook that keeps custom output styles enforced.
#
# Claude Code injects a per-turn reminder ("<Name> output style is active.
# Remember to follow the specific guidelines for this style.") ONLY for its
# built-in styles (Proactive, Explanatory, Learning). Custom styles are placed
# in the system prompt once and never reinforced, so their voice fades in long
# sessions. This hook emits the exact same reminder line for whatever custom
# style is active, closing that gap.
#
# It resolves outputStyle through Claude Code's settings precedence rather than
# reading only the user-level file. /config writes the output style to the
# PROJECT's .claude/settings.local.json, so a hook that read just
# ~/.claude/settings.json would reinforce the global style inside a project
# that had overridden it — worse than no reminder at all.
#
# Windows: use style-reminder.ps1 instead.
#
# Install: install.sh --enforce   (or copy this file and register it under
# hooks.UserPromptSubmit in ~/.claude/settings.json)
#
# Contract: this runs on EVERY prompt. It must never block a turn — every path
# exits 0.

# Verify python3 actually runs, don't just check that it is on PATH: on Windows
# `python3` is often a 0-byte Microsoft Store stub that satisfies `command -v`
# and then exits 9009.
HAVE_PY=0
if command -v python3 >/dev/null 2>&1 && python3 -c '' >/dev/null 2>&1; then
  HAVE_PY=1
fi

# Claude Code sends the hook payload as JSON on stdin; `cwd` is the project
# directory. Skip the read when attached to a terminal so running this script
# by hand cannot block waiting for input.
cwd=""
if [ ! -t 0 ]; then
  input=$(cat)
  if [ -n "$input" ]; then
    if [ "$HAVE_PY" = 1 ]; then
      cwd=$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("cwd") or "")
except Exception:
    pass' 2>/dev/null)
    else
      cwd=$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    fi
  fi
fi
[ -n "$cwd" ] || cwd=$PWD

read_style() { # read_style <settings-file>
  [ -f "$1" ] || return 0
  if [ "$HAVE_PY" = 1 ]; then
    python3 -c 'import json,sys
try:
    print(json.load(open(sys.argv[1])).get("outputStyle") or "")
except Exception:
    pass' "$1" 2>/dev/null
  else
    sed -n 's/.*"outputStyle"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
  fi
}

# Highest precedence first: local beats project beats user.
style=""
for f in "$cwd/.claude/settings.local.json" \
         "$cwd/.claude/settings.json" \
         "${CLAUDE_DIR:-$HOME/.claude}/settings.json"; do
  style=$(read_style "$f")
  [ -n "$style" ] && break
done

# Built-ins already get this reminder from Claude Code itself.
case "$style" in
  ""|default|Default|Proactive|Explanatory|Learning) exit 0 ;;
esac

echo "$style output style is active. Remember to follow the specific guidelines for this style."
