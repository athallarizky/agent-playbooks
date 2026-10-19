#!/usr/bin/env bash
# Regression test for the marker logic used by scan-ioc.sh / clean-markers.sh /
# guard/malware-guard.yml. Builds a synthetic git repo containing malicious
# samples from the campaign AND legitimate files, runs the scan loop, and
# asserts every malicious file is flagged while every legit file is not.
set -u
fail=0
t="$(mktemp -d)"
cd "$t" || exit 1
git init -q && git config user.email t@t.t && git config user.name t

# --- malicious samples (campaign classes) ---
mkdir -p .vscode public/fonts
printf '{"version":"2.0.0","tasks":[{"label":"eslint-check","type":"shell","command":"(command -v node && node ./public/fonts/x.woff)","runOptions":{"runOn":"folderOpen"}}]}' > .vscode/tasks.json
printf '{"task.allowAutomaticTasks": true, "terminal.integrated.hideOnStartup": "always"}' > .vscode/settings.json
printf '(function(x){var a=["match"](/.{1,2}/g);new TextDecoder()})(1)' > public/fonts/x.woff
printf 'AUTH_API_KEY="aHR0cHM6Ly9ldmlsLmNvbS96Lmpz"\n' > .env
printf 'node_modules\nconfig.bat\n' > .gitignore

# --- legitimate files that must NOT be flagged ---
mkdir -p src
echo 'const api = require("./client"); module.exports = api;' > src/api.js
printf 'DATABASE_URL="postgres://localhost/db"\nJWT="eyJhbGciOiJIUzI1NiJ9.x.y"\n' > src/.env
head -c 20000 /dev/urandom > public/fonts/real-big.woff
printf 'node_modules\ndist\n' > src/.gitignore
echo 'console.log(1)' > src/app.js

git add -A && git commit -qm init

verdict=""
while read -r size path; do
  [ -z "$path" ] && continue
  case "$path" in
    .vscode/tasks.json|*/.vscode/tasks.json|.vscode/settings.json|*/.vscode/settings.json) ;;
    api.js|*/api.js|.env|*/.env|config.bat|*/config.bat|.gitignore) ;;
    *.woff|*.woff2|*.ttf|*.otf|*.eot) [ "$size" -lt 10240 ] || continue ;;
    *) continue ;;
  esac
  c=$(git show "HEAD:$path" 2>/dev/null) || continue
  case "$path" in
    .vscode/tasks.json|*/.vscode/tasks.json)
      echo "$c" | grep -q folderOpen && echo "$c" | grep -qE '(node|python|perl|ruby|bash|sh|powershell) ' \
        && echo "$c" | grep -qE '\.(woff2?|ttf|otf|eot|svg)' && verdict="$verdict tasks.json:$path" ;;
    .vscode/settings.json|*/.vscode/settings.json)
      echo "$c" | grep -q '"task.allowAutomaticTasks"' && verdict="$verdict settings:$path" ;;
    api.js|*/api.js)
      echo "$c" | grep -qF '/.{1,2}/g' && echo "$c" | grep -q TextDecoder && verdict="$verdict payload-js:$path" ;;
    .env|*/.env)
      while read -r v; do d=$(printf '%s' "$v" | base64 -d 2>/dev/null) || continue
        case "$d" in http://*|https://*) verdict="$verdict env-dropper:$path"; break ;; esac
      done < <(echo "$c" | grep -oE '"[A-Za-z0-9+/=]{16,}"' | tr -d '"') ;;
    config.bat|*/config.bat) verdict="$verdict stage2:$path" ;;
    .gitignore) echo "$c" | grep -qxE 'config\.bat|\*\.bat' && verdict="$verdict gitignore:$path" ;;
    *.woff|*.woff2|*.ttf|*.otf|*.eot)
      echo "$c" | grep -qE '\(function|Function\(|require\(|eval\(|child_process' && verdict="$verdict fake-font:$path" ;;
  esac
done < <(git ls-tree -r -l HEAD | awk -F'\t' '{split($1,a," "); print a[4]" "$2}')

for expect in "tasks.json:.vscode/tasks.json" "settings:.vscode/settings.json" \
              "fake-font:public/fonts/x.woff" "env-dropper:.env" "gitignore:.gitignore"; do
  case "$verdict" in *"$expect"*) echo "PASS  terdeteksi: $expect" ;; *) echo "FAIL  tidak terdeteksi: $expect"; fail=1 ;; esac
done
for forbid in "src/api.js" "src/.env" "real-big.woff" "src/.gitignore" "src/app.js"; do
  case "$verdict" in *"$forbid"*) echo "FAIL  false positive: $forbid"; fail=1 ;; *) echo "PASS  tidak tertandai: $forbid" ;; esac
done
echo "verdict lengkap:${verdict:- clean}"
cd / && rm -rf "$t"
exit $fail
