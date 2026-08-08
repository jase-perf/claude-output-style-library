#!/bin/sh
# test-install.sh — smoke tests for install.sh against a throwaway CLAUDE_DIR.
#
# Runs the LOCAL checkout path only (no network). The remote path shares every
# code path except the fetch itself.
#
# The settings.json merge is the risky part: it must add keys without
# destroying a real config. That is asserted explicitly below.
#
# Usage: sh tests/test-install.sh   (from the repo root)

set -u

[ -f install.sh ] || { echo "run from the repo root"; exit 1; }

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t styleinstall)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
skip=0
check() { # check <label> <expected> <actual>
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf '  ok    %s\n' "$1"
  else fail=$((fail + 1)); printf '  FAIL  %s\n         expected: [%s]\n         actual:   [%s]\n' "$1" "$2" "$3"; fi
}
skip_case() { skip=$((skip + 1)); printf '  SKIP  %s (%s)\n' "$1" "$2"; }

# install.sh edits settings.json with python3. Where python3 is absent -- or is
# the Windows Store stub that satisfies `command -v` and then exits 9009 --
# there is nothing to assert but the honest fallback message. Skipped loudly,
# never silently: a silent pass here would hide a real regression on Linux/macOS.
HAVE_PY=0
if command -v python3 >/dev/null 2>&1 && python3 -c '' >/dev/null 2>&1; then HAVE_PY=1; fi
NO_PY_REASON="no working python3"

echo "install.sh"

# --- --list -----------------------------------------------------------------
n_disk=$(for f in output-styles/*.md; do echo "$f"; done | wc -l | tr -d " ")
n_list=$(sh install.sh --list | wc -l | tr -d ' ')
check "--list reports every style + style-maker" "$((n_disk + 1))" "$n_list"

# --- single style installs and activates ------------------------------------
D="$TMP/single"
CLAUDE_DIR="$D" sh install.sh caveman >/dev/null 2>&1
check "single style installs and exits 0" "0" "$?"
check "single style file installed" "yes" "$([ -f "$D/output-styles/caveman.md" ] && echo yes || echo no)"
if [ "$HAVE_PY" = 1 ]; then
  active=$(sed -n 's/.*"outputStyle"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$D/settings.json" 2>/dev/null | head -1)
  check "single style is activated" "Caveman" "$active"
else
  skip_case "single style is activated" "$NO_PY_REASON"
fi

# --- --all installs everything, activates nothing ---------------------------
D="$TMP/all"
CLAUDE_DIR="$D" sh install.sh --all >/dev/null 2>&1
check "--all installs every style" "$n_disk" \
  "$(n=0; for f in "$D"/output-styles/*.md; do [ -e "$f" ] && n=$((n + 1)); done; echo "$n")"
check "--all installs style-maker" "yes" "$([ -f "$D/skills/style-maker/SKILL.md" ] && echo yes || echo no)"
check "--all activates nothing" "" "$(sed -n 's/.*"outputStyle"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$D/settings.json" 2>/dev/null | head -1)"

# --- unknown style is rejected ----------------------------------------------
D="$TMP/bogus"
CLAUDE_DIR="$D" sh install.sh definitely-not-a-style >/dev/null 2>&1
check "unknown style exits non-zero" "1" "$?"

# --- the merge must not eat an existing config ------------------------------
D="$TMP/merge"
mkdir -p "$D"
cat > "$D/settings.json" <<'JSON'
{
  "permissions": { "allow": ["Bash(ls *)"], "defaultMode": "auto" },
  "hooks": {
    "SessionStart": [
      { "matcher": "startup", "hooks": [ { "type": "command", "command": "echo hi", "timeout": 5 } ] }
    ]
  },
  "effortLevel": "xhigh"
}
JSON
CLAUDE_DIR="$D" sh install.sh eli15 --enforce >/dev/null 2>&1
# The style file always installs; only the settings.json edit needs python3.
check "merge run installs the style" "yes" \
  "$([ -f "$D/output-styles/eli15.md" ] && echo yes || echo no)"

if [ "$HAVE_PY" = 1 ]; then
  for key in permissions hooks effortLevel; do
    check "merge preserves '$key'" "yes" "$(grep -q "\"$key\"" "$D/settings.json" && echo yes || echo no)"
  done
  check "merge preserves the nested SessionStart command" "yes" \
    "$(grep -q 'echo hi' "$D/settings.json" && echo yes || echo no)"
  check "merge adds UserPromptSubmit" "yes" \
    "$(grep -q 'UserPromptSubmit' "$D/settings.json" && echo yes || echo no)"

  # --- re-running must not duplicate the hook -------------------------------
  CLAUDE_DIR="$D" sh install.sh eli15 --enforce >/dev/null 2>&1
  CLAUDE_DIR="$D" sh install.sh eli15 --enforce >/dev/null 2>&1
  check "hook registered exactly once after 3 runs" "1" \
    "$(grep -c 'style-reminder.sh' "$D/settings.json" | tr -d ' ')"
else
  skip_case "settings.json merge preserves existing keys" "$NO_PY_REASON"
  skip_case "settings.json merge adds UserPromptSubmit" "$NO_PY_REASON"
  skip_case "hook registration is idempotent" "$NO_PY_REASON"
  # What CAN be asserted without python3: it must not corrupt the file or die.
  check "no-python run leaves settings.json intact" "yes" \
    "$(grep -q 'echo hi' "$D/settings.json" && echo yes || echo no)"
  check "no-python run still exits 0" "0" \
    "$(CLAUDE_DIR="$D" sh install.sh eli15 --enforce >/dev/null 2>&1; echo $?)"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$pass" "$fail" "$skip"
if [ "$skip" -gt 0 ]; then
  printf 'NOTE: %s check(s) skipped for lack of a working python3. On Linux and\n' "$skip"
  printf '      macOS CI runners python3 is present, so those checks do run there.\n'
fi
[ "$fail" -eq 0 ] || exit 1
