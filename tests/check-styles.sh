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
MAX_BODY_CHARS=3500      # A guard against bloat, not a research finding. Every
                         # byte here is system prompt on every turn, so a style
                         # that grows should grow deliberately. Raise the number
                         # when a rule earns the room -- do not cut a rule that
                         # earns its place to satisfy it.
fails=0
checked=0

fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }

# frontmatter = between the 1st and 2nd '---'; body = everything after the 2nd.
frontmatter() { awk 'NR==1 && /^---$/ {infm=1; next} infm && /^---$/ {exit} infm' "$1"; }
body()        { awk 'BEGIN{d=0} /^---$/ {d++; next} d>=2' "$1"; }

field() { # field <file> <key>
  frontmatter "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1
}

# "Plain English" -> "plain-english"
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

  # These files are increasingly written by agents that return the whole file as
  # a string, and an agent's own tool-call framing can ride along on the end of
  # that string. It happened: plain-english.md shipped with '</full_file_content>'
  # and '</invoke>' as its last two lines, and every structural check above still
  # passed, because trailing junk breaks no heading and busts no byte ceiling.
  # The body is a system prompt, so anything that is not an instruction is a bug.
  if printf '%s' "$b" | grep -q '</invoke>\|<invoke \|</function_calls>\|<function_calls>\|<parameter name=\|full_file_content\|</antml'; then
    fail "$slug: body contains agent tool-call markup. Strip it -- this text goes into the system prompt verbatim."
  fi

  # --- the guardrail invariant --------------------------------------------
  # Wording is deliberately per-style; the protections are not optional.
  g=$(printf '%s' "$b" | sed -n '/^## Guardrails/,/^## /p')

  # The extraction runs to the next '## ' heading, so a layout that puts
  # Guardrails above the rules WITHOUT giving the rules their own heading makes
  # this region swallow them -- and then the four keyword checks below can be
  # satisfied by rule text instead of by the guardrails. That silently guts the
  # only safety check in this file, so bound the region explicitly.
  gchars=$(printf '%s' "$g" | wc -c | tr -d ' ')
  if [ "$gchars" -gt 1000 ]; then
    fail "$slug: Guardrails section is $gchars chars -- it has swallowed another section. Give the following section its own '## ' heading."
  fi
  if printf '%s' "$g" | grep -qE '^[0-9]+\.|^In every response'; then
    fail "$slug: numbered rules are inside the Guardrails section. Give them their own '## ' heading so the guardrail checks cannot be satisfied by rule text."
  fi
  printf '%s' "$g" | grep -qi 'byte-for-byte\|byte-exact' \
    || fail "$slug: Guardrails must keep code/paths/numbers byte-exact"
  printf '%s' "$g" | grep -qi 'security' \
    || fail "$slug: Guardrails must carve out security warnings"
  printf '%s' "$g" | grep -qi 'destructive\|irreversible' \
    || fail "$slug: Guardrails must carve out destructive/irreversible actions"
  printf '%s' "$g" | grep -qi 'order' \
    || fail "$slug: Guardrails must carve out order-critical instructions"

  # A voice instruction must not change what the agent DOES. Without this check
  # the clause was free to drift: executive.md and caveman.md carried it as a
  # numbered rule rather than a guardrail, and nothing noticed. Match operative
  # content, not a slogan, so a paraphrase in the style's own register passes.
  printf '%s' "$g" | grep -qi 'stop to ask\|question asked before\|asked before act' \
    || fail "$slug: Guardrails must state that the style changes prose only, not tool use, edits, or when you stop to ask"

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

# tr -d '\r' is required, not defensive: .gitattributes checks install.ps1 out
# as CRLF on every platform, and GNU sed (unlike Git Bash's) leaves the CR in
# place -- so each name would carry a trailing CR, fail the comparison, and
# then mangle the error message by returning the cursor to column 0.
sh_list=$(sed -n '/^STYLES=(/,/^)/p' install.sh | sed '1d;$d' | tr -d '\r' | tr -s ' \n' ' ' | tr ' ' '\n' | sed '/^$/d' | sort | tr '\n' ' ')
[ "$sh_list" = "$disk" ] || fail "install.sh STYLES does not match $STYLE_DIR/ (got: $sh_list)"

# commas -> newlines FIRST, then strip quotes/space; deleting commas outright
# concatenates every name into one token.
# shellcheck disable=SC2016  # $STYLES is a literal PowerShell variable in the
# pattern being matched, not a shell expansion -- single quotes are correct.
ps_list=$(sed -n '/^\$STYLES = @(/,/^)/p' install.ps1 | sed '1d;$d' | tr -d '\r' | tr ',' '\n' | tr -d " '" | sed '/^$/d' | sort | tr '\n' ' ')
[ "$ps_list" = "$disk" ] || fail "install.ps1 \$STYLES does not match $STYLE_DIR/ (got: $ps_list)"

# --- every style is credited ------------------------------------------------
printf 'Attribution\n'
for f in "$STYLE_DIR"/*.md; do
  slug=$(basename "$f" .md)
  grep -q "^- \*\*$slug\*\*" docs/CREDITS.md \
    || fail "$slug: no entry in docs/CREDITS.md"
done

# --- the README table tracks what actually ships ----------------------------
# Twice now the README has shipped stale: once advertising descriptions the
# files no longer had, once linking styles that had been renamed or deleted.
# CI passed both times, because nothing compared prose to disk. Now it does.
printf 'README\n'
for f in "$STYLE_DIR"/*.md; do
  slug=$(basename "$f" .md)
  grep -q "(output-styles/$slug\.md)" README.md \
    || fail "$slug: ships but has no row in the README table"
done
readme_links=$(sed -n 's|.*(output-styles/\([a-z0-9-]*\)\.md).*|\1|p' README.md | sort -u)
for slug in $readme_links; do
  [ -f "$STYLE_DIR/$slug.md" ] \
    || fail "README links output-styles/$slug.md, which does not exist"
done

printf '\n%s styles checked, %s failure(s)\n' "$checked" "$fails"
[ "$fails" -eq 0 ] || exit 1
