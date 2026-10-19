#!/usr/bin/env bash
# Batch visibility changes from a list file. DRY-RUN by default; --yes executes.
# Usage: apply-visibility.sh <list-file> [--yes]
#   list-file lines: "<repo> [action]"
#     action: private (default) | public | archive | unarchive
#     repo may be bare ("watch-vault") or full ("athallarizky/watch-vault")
# Consequences (worth repeating to the user before --yes):
#   - private: stars are lost PERMANENTLY; public links/clones break
#   - rulesets keep enforcing on private repos; a guardian PAT scoped to
#     "all repositories" keeps sweeping them
set -uo pipefail

yes=0
list=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) yes=1; shift ;;
    -*) echo "unknown flag: $1" >&2; exit 1 ;;
    *) list="$1"; shift ;;
  esac
done
[ -z "$list" ] || [ ! -f "$list" ] && { echo "usage: apply-visibility.sh <list-file> [--yes]" >&2; exit 1; }

owner="$(gh api user --jq .login)"
[ "$yes" -eq 0 ] && echo "DRY-RUN (pass --yes to execute) — planned changes:"

ok=0; fail=0; planned=0
while IFS=$' \t' read -r repo action; do
  [ -z "$repo" ] && continue
  case "$repo" in \#*) continue ;; esac
  case "$repo" in */*) ;; *) repo="$owner/$repo" ;; esac
  action="${action:-private}"
  case "$action" in
    private)    field=private=true ;;
    public)     field=private=false ;;
    archive)    field=archived=true ;;
    unarchive)  field=archived=false ;;
    *) echo "SKIP  $repo — unknown action '$action'"; continue ;;
  esac

  if [ "$yes" -eq 0 ]; then
    echo "PLAN  $repo -> $action (PATCH -f $field)"
    planned=$((planned+1))
    continue
  fi
  err=$(gh api -X PATCH "repos/$repo" -f "$field" 2>&1 >/dev/null) \
    && { ok=$((ok+1));    echo "OK    $repo -> $action"; } \
    || { fail=$((fail+1)); echo "FAIL  $repo :: $(echo "$err" | grep -o '"message":"[^"]*"' | head -1)"; }
done < "$list"

echo "---"
if [ "$yes" -eq 0 ]; then
  echo "planned: $planned (nothing executed)"
else
  echo "applied: $ok | failed: $fail"
  echo "public repos now (fork=false / fork=true):"
  gh repo list "$owner" --visibility public --limit 300 --json isFork \
    --jq 'group_by(.isFork) | map({fork: .[0].isFork, n: length})'
fi
