#!/usr/bin/env bash
# Permanently strip malicious blobs from git history — content-based, name-agnostic.
# Usage: purge-history.sh <targets-file>   (lines: "owner/repo branch")
# Per repo:
#   1. mirror-clone (all refs)
#   2. enumerate every blob in history; marker-check candidates (same lib-ioc
#      logic as the scanners) and collect BAD BLOB IDs
#   3. git filter-repo --strip-blobs-with-ids <bad-ids>   (name-agnostic,
#      zero collateral to the user's own legit files)
#   4. force-push all branches + tags back, re-verify by scanning the new tip
# Skips: repos with no malicious blobs (already clean/unreachable) and repos
# whose pre-cleanup tip is older than MIN_ACTIVE (default ~18 months = dead).
# Requires: git-filter-repo on PATH, gh authenticated.
# WARNINGS: rewrite changes every SHA and strips historical commit signatures;
# breaks PR/issue SHA references; local clones must re-fetch. Run BEFORE
# enabling required-signatures rulesets (protect-repos.sh) or the push of the
# rewritten history will itself be rejected.
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

targets="${1:?usage: purge-history.sh <targets-file>}"
MIN_ACTIVE="${MIN_ACTIVE:-$(date -v-18m +%Y-%m-%d 2>/dev/null || date -d '18 months ago' +%Y-%m-%d)}"
work="$(mktemp -d)"

echo "== purge start $(date '+%F %T') | dead-cutoff: $MIN_ACTIVE | work: $work =="
while read -r repo br; do
  [ -z "$repo" ] && continue
  # dead-repo detection: walk commits until past our cleanup commits
  pretip=$(gh api "repos/$repo/commits?per_page=15" --jq 'first(.[] | select((.commit.message | startswith("chore: remove injected malware files") or startswith("chore: drop injected gitignore")) | not) | .commit.author.date) // ""' 2>/dev/null)
  if [ -n "$pretip" ] && [ "${pretip%%T*}" \< "$MIN_ACTIVE" ]; then
    echo "SKIP-dead  $repo (pre-cleanup tip $pretip)"; continue
  fi
  dir="$work/${repo//\//__}"
  git -c 'credential.helper=!gh auth git-credential' clone --quiet --mirror "https://github.com/$repo.git" "$dir" 2>/dev/null || { echo "SKIP-clone $repo"; continue; }
  # enumerate candidate blobs via the SAME layered selector as the scanners
  # (structural + small fonts + name blacklist + api.js/.env class).
  # .gitignore is excluded: its fingerprint is EDITED at tips, never blob-purged.
  badids="$work/bad_${repo//\//__}.txt"; : > "$badids"
  git -C "$dir" rev-list --objects --all | awk 'NF==2 {print $2" "$1}' \
  | while read -r path oid; do
      [ "$path" = ".gitignore" ] && continue
      size=$(git -C "$dir" cat-file -s "$oid" 2>/dev/null) || continue
      [ -n "$(printf '%s %s\n' "$path" "$size" | ioc_stage1_candidates)" ] || continue
      if git -C "$dir" cat-file blob "$oid" 2>/dev/null | ioc_path_is_malicious "$path"; then
        echo "$oid"
      fi
    done >> "$badids"
  n=$(sort -u "$badids" | wc -l | tr -d ' ')
  if [ "$n" -eq 0 ]; then echo "CLEAN      $repo (no malicious blobs in history)"; continue; fi
  git -C "$dir" filter-repo --force --strip-blobs-with-ids <(sort -u "$badids") >/dev/null 2>&1 \
    || { echo "FAIL-filter $repo"; continue; }
  git -C "$dir" remote add origin "https://github.com/$repo.git"
  if git -C "$dir" -c credential.helper='!gh auth git-credential' push --force --all origin >/dev/null 2>&1 \
     && git -C "$dir" -c credential.helper='!gh auth git-credential' push --force --tags origin >/dev/null 2>&1; then
    echo "PURGED     $repo ($n blob dihapus dari history, semua branch+tag di-push ulang)"
  else
    echo "FAIL-push  $repo ($n blob — mirror tersimpan di $dir untuk push manual)"
  fi
done < "$targets"
echo "== purge selesai $(date '+%F %T') =="
