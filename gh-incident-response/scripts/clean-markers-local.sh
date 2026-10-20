#!/usr/bin/env bash
# Local signed-commit cleanup of campaign markers — complements clean-markers.sh
# (API method). No history rewrite, no ruleset lift needed: one fast-forward
# commit per ref, signed with the local key, passes malware-guard.
# Usage: clean-markers-local.sh <targets-file>   (lines: "owner/repo branch")
# Per candidate file, gated on CONTENT markers (same lib as the scanner):
#   - rider configs (postcss/tailwind/eslint/etc): rider STRIPPED in place —
#     prelude lines removed, obfuscated tail after 40+ spaces truncated — then
#     re-verified clean; a still-malicious strip ABORTS the file (manual review)
#   - .gitignore: injected bare-.bat lines stripped, file kept
#   - pure payloads (fake fonts, api.js droplet, .vscode, fonts README,
#     config.bat, dropper .env): deleted
# Verify afterwards with scan-ioc.sh (the patched version) — expect 0 BAD.
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

targets="${1:?usage: clean-markers-local.sh <targets-file> (lines of 'owner/repo branch')}"
[ -f "$targets" ] || { echo "no such file: $targets" >&2; exit 1; }

rider_path() { case "$1" in
  *.config.js|*.config.ts|*.config.mjs|*.config.cjs|*.config.mts|*.config.cts|.eslintrc*|*/.eslintrc*|.prettierrc*|*/.prettierrc*|.postcssrc*|*/.postcssrc*|.babelrc*|*/.babelrc*|.stylelintrc*|*/.stylelintrc*) return 0 ;;
  *) return 1 ;; esac; }

strip_rider() {  # $1=file — 0 = clean after strip, 1 = still malicious (abort)
  local f="$1"
  # NB: no $ anchors — campaign files use CRLF, so lines end with \r before \n
  sed -i '' -e "/^import { createRequire } from 'module';/d" \
             -e '/^var require = createRequire(import\.meta\.url);/d' \
             -e '/^var module = { exports: {} };/d' "$f"
  sed -i '' -E 's/([;}])([[:space:]]{40,})(var |\()+.*$/\1/' "$f"
  sed -i '' -E '/^[[:space:]]{40,}/d' "$f"
  ! ioc_config_rider < "$f"
}

ok=0; fail=0; nothing=0
while read -r repo br; do
  [ -z "$repo" ] && continue
  d=$(mktemp -d)
  if ! gh repo clone "$repo" "$d" -- --depth=1 --branch "$br" >/dev/null 2>&1; then
    echo "FAIL clone $repo@$br"; fail=$((fail+1)); rm -rf "$d"; continue
  fi
  act=""
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    f="$d/$p"; [ -f "$f" ] || continue
    if ! ioc_path_is_malicious "$p" < "$f"; then continue; fi
    if [ "$p" = ".gitignore" ]; then
      grep -vxE '\*\.bat|[A-Za-z0-9_.-]+\.bat' "$f" > "$f.new" && mv "$f.new" "$f" && act="$act fix:.gitignore"
    elif rider_path "$p"; then
      if strip_rider "$f"; then act="$act strip:$p"
      else echo "SKIP-RIDER-STILL-BAD $repo@$br :: $p (manual review)"; rm -f "$f.new"; fi
    else
      git -C "$d" rm -q -- "$p" && act="$act del:$p"
    fi
  done < <(cd "$d" && git ls-files | while IFS= read -r x; do [ -f "$x" ] && printf '%s %s\n' "$x" "$(wc -c < "$x" | tr -d ' ')"; done | ioc_stage1_candidates | sort -u)
  if [ -z "$act" ]; then echo "CLEAN $repo@$br (no markers)"; nothing=$((nothing+1))
  elif git -C "$d" commit -qam "chore: remove injected malware files (security cleanup)" 2>/dev/null \
    && git -C "$d" push -q origin "HEAD:$br" 2>/dev/null; then
    echo "OK   $repo@$br ->$act"; ok=$((ok+1))
  else
    echo "FAIL push $repo@$br ->$act"; fail=$((fail+1))
  fi
  rm -rf "$d"
done < "$targets"

echo "---"
echo "cleaned: $ok | already-clean: $nothing | failed: $fail"
[ "$fail" -eq 0 ]
