#!/usr/bin/env bash
# Purge EVERY .vscode path from remote branches — policy: none allowed on remote.
# Usage: purge-vscode.sh <targets-file>
#   targets-file: lines of "owner/repo branch" (refs without .vscode are NOVS-skipped)
# Method: per ref — clone depth-1, `git rm` all (^|/)\.vscode/ paths (null-delimited:
# paths may contain spaces, .vscode may be nested), signed commit (local signing
# config), fast-forward push. Passes malware-guard (signed, no force) WITHOUT
# lifting rulesets. Archived repos: unarchived for the push, re-archived after.
# 2026-10-20: cleaned 66 refs across personal + The-Aetheris with this method.
# Verify afterwards by re-scanning trees for (^|/)\.vscode/ — expect zero.
set -uo pipefail

targets="${1:?usage: purge-vscode.sh <targets-file> (lines of 'owner/repo branch')}"
[ -f "$targets" ] || { echo "no such file: $targets" >&2; exit 1; }

repos=$(awk '{print $1}' "$targets" | sort -u)
ok=0; fail=0
for repo in $repos; do
  archived=$(gh api "repos/$repo" --jq '.archived' 2>/dev/null)
  [ "$archived" = "true" ] && { gh api -X PATCH "repos/$repo" -f archived=false --silent && echo "unarchived $repo"; }

  while read -r br; do
    [ -z "$br" ] && continue
    d=$(mktemp -d)
    if ! gh repo clone "$repo" "$d" -- --depth=1 --branch "$br" >/dev/null 2>&1; then
      echo "FAIL clone $repo@$br"; fail=$((fail+1)); rm -rf "$d"; continue
    fi
    if ! git -C "$d" ls-files -z | grep -zE '(^|/)\.vscode/' | xargs -0 -r git -C "$d" rm -q -- 2>/dev/null; then
      echo "FAIL rm $repo@$br"; fail=$((fail+1)); rm -rf "$d"; continue
    fi
    if ! git -C "$d" commit -qm "chore: remove .vscode from remote" 2>/dev/null; then
      echo "NOVS $repo@$br"; rm -rf "$d"; continue
    fi
    if git -C "$d" push -q origin "HEAD:$br" 2>/dev/null; then
      echo "OK   $repo@$br"; ok=$((ok+1))
    else
      echo "FAIL push $repo@$br"; fail=$((fail+1))
    fi
    rm -rf "$d"
  done < <(awk -v r="$repo" '$1 == r {print $2}' "$targets")

  [ "$archived" = "true" ] && { gh api -X PATCH "repos/$repo" -f archived=true --silent && echo "re-archived $repo"; }
done

echo "---"
echo "purged: $ok | failed: $fail"
[ "$fail" -eq 0 ]
