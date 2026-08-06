#!/usr/bin/env bash
# awesome-claude-output-styles installer
#
# Install one style (and make it active):
#   curl -fsSL https://raw.githubusercontent.com/smixs/awesome-claude-output-styles/main/install.sh | bash -s -- eli15
#
# Install everything (nothing is activated, pick later via /config):
#   curl -fsSL https://raw.githubusercontent.com/smixs/awesome-claude-output-styles/main/install.sh | bash -s -- --all
#
# List available styles:
#   curl -fsSL https://raw.githubusercontent.com/smixs/awesome-claude-output-styles/main/install.sh | bash -s -- --list
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
RAW="${RAW:-https://raw.githubusercontent.com/smixs/awesome-claude-output-styles/main}"

STYLES=(
  wait-what plain-english eli15 analogy-engine feynman thing-explainer ladder
  executive smart-brevity coach
  caveman adhd no-slop no-ai-slop
  street gen-z sportscaster yoda bedtime-story
)

usage() {
  echo "Usage: install.sh <style> [<style>...] | --all | --list"
  echo "Styles: ${STYLES[*]} style-maker"
}

fetch() { # fetch <remote-path> <local-path>
  if [ -f "$SELF_DIR/$1" ]; then
    mkdir -p "$(dirname "$2")"
    cp "$SELF_DIR/$1" "$2"
  else
    curl -fsSL "$RAW/$1" -o "$2"
  fi
}

install_style() { # install_style <name>
  mkdir -p "$CLAUDE_DIR/output-styles"
  fetch "output-styles/$1.md" "$CLAUDE_DIR/output-styles/$1.md"
  echo "installed: output-styles/$1.md"
}

install_style_maker() {
  mkdir -p "$CLAUDE_DIR/skills/style-maker"
  fetch "skills/style-maker/SKILL.md" "$CLAUDE_DIR/skills/style-maker/SKILL.md"
  echo "installed: skills/style-maker (run it by asking Claude to \"make my output style\")"
}

activate() { # activate <style-file>
  local file="$CLAUDE_DIR/output-styles/$1.md"
  local style_name
  style_name=$(sed -n 's/^name:[[:space:]]*//p' "$file" | head -1)
  [ -n "$style_name" ] || { echo "warning: no name in frontmatter, skipping activation"; return; }
  local settings="$CLAUDE_DIR/settings.json"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$settings" "$style_name" <<'PY'
import json, os, sys
path, name = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
data["outputStyle"] = name
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    echo "active style: $style_name (written to $settings)"
    echo "Restart Claude Code (or /clear) to apply."
  else
    echo "python3 not found. Activate manually: /config -> Output style -> $style_name"
  fi
}

# When run from a local checkout, install from local files instead of curl.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-/dev/null}")" 2>/dev/null && pwd || echo /nonexistent)"
[ -f "$SELF_DIR/output-styles/${STYLES[0]}.md" ] || SELF_DIR=/nonexistent

[ $# -ge 1 ] || { usage; exit 1; }

case "$1" in
  --list)
    printf '%s\n' "${STYLES[@]}" style-maker
    exit 0
    ;;
  --all)
    for s in "${STYLES[@]}"; do install_style "$s"; done
    install_style_maker
    echo
    echo "All styles installed. Pick one: /config -> Output style (takes effect after restart or /clear)."
    exit 0
    ;;
  -h|--help)
    usage
    exit 0
    ;;
esac

requested=("$@")
for s in "${requested[@]}"; do
  if [ "$s" = "style-maker" ]; then
    install_style_maker
    continue
  fi
  found=0
  for known in "${STYLES[@]}"; do
    [ "$s" = "$known" ] && found=1 && break
  done
  [ "$found" = 1 ] || { echo "unknown style: $s"; usage; exit 1; }
  install_style "$s"
done

# Exactly one style requested -> make it the active style.
if [ ${#requested[@]} -eq 1 ] && [ "${requested[0]}" != "style-maker" ]; then
  activate "${requested[0]}"
else
  echo
  echo "Pick a style: /config -> Output style (takes effect after restart or /clear)."
fi
