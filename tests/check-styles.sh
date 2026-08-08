#!/bin/sh
# check-styles.sh — invariants every style file must satisfy.
#
# These rules were previously held by the author's discipline alone. A style
# whose Guardrails block silently omitted the security clause would install and
# run exactly like a correct one, and nothing would notice. Now something does.
#
# POSIX sh on purpose: this runs on Ubuntu, macOS (BSD userland) and Windows
# (Git Bash) runners unchanged. No grep -P, no sed -i, no bash arrays.
#
# Usage: sh tests/check-styles.sh   (from the repo root)
# Exit 0 = all invariants hold. Exit 1 = at least one failure, all reported.

set -u

STYLE_DIR="output-styles"
MAX_BODY_CHARS=3000      # a style is a lens, not a novel -- and every byte is
                         # system prompt on every single turn
fails=0
checked=0

fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }

# frontmatter = between the 1st and 2nd '---'; body = everything after the 2nd.
frontmatter() { awk 'NR==1 && /^---$/ {infm=1; next} infm && /^---$/ {exit} infm' "$1"; }
body()        { awk 'BEGIN{d=0} /^---$/ {d++; next} d>=2' "$1"; }

field() { # field <file> <key>
  frontmatter "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1
}

# "No AI Slop" -> "no-ai-slop"
slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

printf 'Checking %s/*.md\n\n' "$STYLE_DIR"

names_seen=""
for f in "$STYLE_DIR"/*.md; do
  [ -e "$f" ] || { echo "no style files found in $STYLE_DIR"; exit 1; }
  slug=$(basename "$f" .md)
  checked=$((checked + 1))
  printf '%s\n' "$slug"

  # --- frontmatter ---------------------------------------------------------
  head -1 "$f" | grep -q '^---$' || fail "$slug: file must start with '---'"

  name=$(field "$f" name)
  desc=$(field "$f" description)
  keep=$(field "$f" keep-coding-instructions)

  [ -n "$name" ] || fail "$slug: frontmatter missing 'name:'"
  [ -n "$desc" ] || fail "$slug: frontmatter missing 'description:'"
  [ "$keep" = "true" ] || fail "$slug: 'keep-coding-instructions' must be true (got '${keep:-unset}')"

  # The name is what lands in settings.json as outputStyle, and the slug is what
  # the installer fetches. If they disagree, `install.sh <slug>` activates a
  # style the user cannot then find in /config.
  if [ -n "$name" ]; then
    expected=$(slugify "$name")
    [ "$expected" = "$slug" ] || fail "$slug: name '$name' slugifies to '$expected', not the filename"
  fi

  # Duplicate display names would make /config ambiguous.
  case " $names_seen " in
    *" $name "*) fail "$slug: display name '$name' is already used by another style" ;;
    *) names_seen="$names_seen $name" ;;
  esac

  # --- body structure ------------------------------------------------------
  b=$(body "$f")

  printf '%s' "$b" | grep -q 'You are an interactive agent that helps users with software engineering tasks' \
    || fail "$slug: body must open with the built-in identity line"

  printf '%s' "$b" | grep -q "^# .* Style Active$" \
    || fail "$slug: body must contain a '# <Name> Style Active' header"

  printf '%s' "$b" | grep -q '^## Guardrails' \
    || fail "$slug: body must contain a '## Guardrails' section"

  # --- the guardrail invariant --------------------------------------------
  # Wording is deliberately per-style; the protections are not optional.
  g=$(printf '%s' "$b" | sed -n '/^## Guardrails/,/^## /p')
  printf '%s' "$g" | grep -qi 'byte-for-byte\|byte-exact' \
    || fail "$slug: Guardrails must keep code/paths/numbers byte-exact"
  printf '%s' "$g" | grep -qi 'security' \
    || fail "$slug: Guardrails must carve out security warnings"
  printf '%s' "$g" | grep -qi 'destructive\|irreversible' \
    || fail "$slug: Guardrails must carve out destructive/irreversible actions"
  printf '%s' "$g" | grep -qi 'order' \
    || fail "$slug: Guardrails must carve out order-critical instructions"

  # --- budget --------------------------------------------------------------
  chars=$(printf '%s' "$b" | wc -c | tr -d ' ')
  if [ "$chars" -gt "$MAX_BODY_CHARS" ]; then
    fail "$slug: body is $chars chars, over the $MAX_BODY_CHARS budget (~$((chars / 4)) tokens every turn)"
  fi
done

# --- installers must agree with what is on disk -----------------------------
# Catches the drift where a style is added or removed but one installer's list
# is not updated -- the failure mode is a 404 mid-install.
printf '\nInstaller lists\n'
disk=$(for f in "$STYLE_DIR"/*.md; do basename "$f" .md; done | sort | tr '\n' ' ')

sh_list=$(sed -n '/^STYLES=(/,/^)/p' install.sh | sed '1d;$d' | tr -s ' \n' ' ' | tr ' ' '\n' | sed '/^$/d' | sort | tr '\n' ' ')
[ "$sh_list" = "$disk" ] || fail "install.sh STYLES does not match $STYLE_DIR/ (got: $sh_list)"

# commas -> newlines FIRST, then strip quotes/space; deleting commas outright
# concatenates every name into one token.
# shellcheck disable=SC2016  # $STYLES is a literal PowerShell variable in the
# pattern being matched, not a shell expansion -- single quotes are correct.
ps_list=$(sed -n '/^\$STYLES = @(/,/^)/p' install.ps1 | sed '1d;$d' | tr ',' '\n' | tr -d " '" | sed '/^$/d' | sort | tr '\n' ' ')
[ "$ps_list" = "$disk" ] || fail "install.ps1 \$STYLES does not match $STYLE_DIR/ (got: $ps_list)"

# --- every style is credited ------------------------------------------------
printf 'Attribution\n'
for f in "$STYLE_DIR"/*.md; do
  slug=$(basename "$f" .md)
  grep -q "^- \*\*$slug\*\*" docs/CREDITS.md \
    || fail "$slug: no entry in docs/CREDITS.md"
done

printf '\n%s styles checked, %s failure(s)\n' "$checked" "$fails"
[ "$fails" -eq 0 ] || exit 1
