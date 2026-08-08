#!/bin/sh
# test-hook.sh — behavioural tests for hooks/style-reminder.sh
#
# This hook runs on EVERY user prompt. Two failure modes matter more than
# correctness of the happy path:
#   1. it must never block a turn (always exit 0), and
#   2. it must never name the WRONG style -- reinforcing the global style
#      inside a project that overrode it is worse than staying silent.
# Both are covered below.
#
# POSIX sh: runs unchanged on Ubuntu, macOS and Git Bash.
# Usage: sh tests/test-hook.sh   (from the repo root)

set -u

HOOK="hooks/style-reminder.sh"
[ -f "$HOOK" ] || { echo "run from the repo root: $HOOK not found"; exit 1; }

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t stylehook)
trap 'rm -rf "$TMP"' EXIT

PROJ="$TMP/proj"
HOME_DIR="$TMP/home/.claude"
mkdir -p "$PROJ/.claude" "$HOME_DIR"
CLAUDE_DIR="$HOME_DIR"
export CLAUDE_DIR

pass=0
fail=0

# run <stdin-payload>  -> echoes the hook's stdout
run() { printf '%s' "$1" | sh "$HOOK" 2>/dev/null; }

payload() { printf '{"cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"hi"}' "$PROJ"; }

check() { # check <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$1"
  else
    fail=$((fail + 1)); printf '  FAIL  %s\n         expected: [%s]\n         actual:   [%s]\n' "$1" "$2" "$3"
  fi
}

reminder() { printf '%s output style is active. Remember to follow the specific guidelines for this style.' "$1"; }

reset_project() { rm -f "$PROJ/.claude/settings.json" "$PROJ/.claude/settings.local.json"; }

echo "style-reminder.sh"

# --- precedence -------------------------------------------------------------
echo '{"outputStyle":"No Slop"}' > "$HOME_DIR/settings.json"
reset_project
check "user settings when project has none" "$(reminder 'No Slop')" "$(run "$(payload)")"

echo '{"outputStyle":"Caveman"}' > "$PROJ/.claude/settings.json"
check "project settings.json overrides user" "$(reminder 'Caveman')" "$(run "$(payload)")"

echo '{"outputStyle":"Executive"}' > "$PROJ/.claude/settings.local.json"
check "settings.local.json wins over both" "$(reminder 'Executive')" "$(run "$(payload)")"

echo '{"permissions":{}}' > "$PROJ/.claude/settings.local.json"
check "file without outputStyle falls through" "$(reminder 'Caveman')" "$(run "$(payload)")"

# --- must not break a turn --------------------------------------------------
printf '{BROKEN,,' > "$PROJ/.claude/settings.local.json"
check "malformed JSON falls through, no crash" "$(reminder 'Caveman')" "$(run "$(payload)")"

reset_project
check "garbage stdin still resolves user scope" "$(reminder 'No Slop')" "$(run 'not json at all')"
check "empty stdin still resolves user scope" "$(reminder 'No Slop')" "$(run '')"
check "stdin JSON without cwd key" "$(reminder 'No Slop')" "$(run '{"prompt":"hi"}')"

# --- silence where Claude Code already reminds ------------------------------
for builtin in default Default Explanatory Learning Proactive; do
  printf '{"outputStyle":"%s"}\n' "$builtin" > "$PROJ/.claude/settings.json"
  check "silent for built-in '$builtin'" "" "$(run "$(payload)")"
done

reset_project
: > "$HOME_DIR/settings.json"
check "silent when settings.json is empty" "" "$(run "$(payload)")"

rm -f "$HOME_DIR/settings.json"
check "silent when no settings.json exists" "" "$(run "$(payload)")"

# --- exit code is always 0 --------------------------------------------------
echo '{"outputStyle":"No Slop"}' > "$HOME_DIR/settings.json"
printf '%s' "$(payload)" | sh "$HOOK" >/dev/null 2>&1
check "exit 0 on the happy path" "0" "$?"

printf 'garbage' | sh "$HOOK" >/dev/null 2>&1
check "exit 0 on garbage stdin" "0" "$?"

rm -f "$HOME_DIR/settings.json"
printf '%s' "$(payload)" | sh "$HOOK" >/dev/null 2>&1
check "exit 0 with no settings at all" "0" "$?"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
