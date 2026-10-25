#!/usr/bin/env bash
# Shared IOC definitions + marker checks for gh-incident-response scripts.
# Source this file: . "$(dirname "$0")/lib-ioc.sh"
#
# Detection is layered (defense in depth — never rely on one layer):
#   L1 structural : .vscode/tasks.json, .vscode/settings.json, fonts/README.md
#   L2 size       : ANY font file < FONT_SUSPECT_MAX bytes — name-agnostic
#   L3 name list  : ioc-filenames.txt known-bad patterns — ANY size; an
#                   accelerator, never a gate (payload names rotate)
#   L4 content    : marker checks arbitrate every candidate — the authority
# Files referenced by a tasks.json command are ALWAYS followed and checked,
# even when the task itself looks benign.

FONT_SUSPECT_MAX=10240
IOC_NAMES_FILE="$(cd "$(dirname "$0")" && pwd)/ioc-filenames.txt"

# Stage-1 candidate selection — zero extra API calls.
# stdin : "<path> <size>" lines from the recursive trees API response.
# stdout: paths that deserve a stage-2 content check (L1 ∪ L2 ∪ L3).
ioc_stage1_candidates() {
  local input; input=$(cat)
  printf '%s\n' "$input" | awk -v max="$FONT_SUSPECT_MAX" '
    $1 == ".vscode/tasks.json" || $1 == ".vscode/settings.json" { print $1; next }
    $1 ~ /(^|\/)fonts\/README\.md$/                               { print $1; next }
    $1 ~ /\.(woff2?|ttf|otf|eot|orc)$/ && ($2 + 0) < max          { print $1; next }
    $1 == "api.js" || $1 ~ /\/api\.js$/                           { print $1; next }
    $1 == ".env"     || $1 ~ /\/\.env$/                           { print $1; next }
    $1 == "config.bat" || $1 ~ /\/config\.bat$/                   { print $1; next }
    $1 == ".gitignore"                                             { print $1; next }
    # build-tool config files — the "config rider" class (payload appended to
    # vite/next/webpack/... configs, executes on dev/build). Content-gated.
    # Cover EVERY executable config surface: *.config.* + dotfile rc forms.
    $1 ~ /(^|\/)(vite|next|webpack|rspack|postcss|tailwind|nuxt|svelte|rollup|babel|eslint|prettier|vue|metro|react-native|capacitor|astro|remix|karma|cypress|playwright|vitest|jest|docusaurus|electron\.vite)\.(config|conf)\.(js|ts|mjs|cjs|mts|cts)$/ { print $1; next }
    $1 ~ /(^|\/)\.(eslintrc|prettierrc|postcssrc|babelrc|stylelintrc)(\.(js|cjs|mjs|json))?$/ { print $1; next }
    $1 ~ /(^|\/)\.vitepress\/config\.(js|ts)$/                     { print $1; next }
    $1 ~ /(^|\/)(gatsby-config|gatsby-node)\.(js|ts)$/             { print $1; next }
    $1 == "package.json" || $1 ~ /\/package\.json$/                { print $1 }
  '
  if [ -f "$IOC_NAMES_FILE" ]; then
    printf '%s\n' "$input" | awk '{print $1}' \
      | grep -E -f <(grep -vE '^[[:space:]]*(#|$)' "$IOC_NAMES_FILE") || true
  fi
}

ioc_name_blacklisted() {  # path in $1; exit 0 = known-bad name
  [ -f "$IOC_NAMES_FILE" ] && printf '%s\n' "$1" \
    | grep -qE -f <(grep -vE '^[[:space:]]*(#|$)' "$IOC_NAMES_FILE")
}

# Marker checks (stage-2, operate on decoded file content via stdin).
# NOTE: every multi-condition marker buffers stdin ONCE — chained `grep -q`
# reading the same stdin is unreliable (the first grep drains the pipe).
ioc_tasks_malicious()   { local c; c=$(cat); printf '%s' "$c" | grep -q 'folderOpen' && printf '%s' "$c" | grep -qE '(node|python|perl|ruby|bash|sh|powershell) ' && printf '%s' "$c" | grep -qE '\.(woff2?|ttf|otf|eot|orc|svg)'; }
ioc_settings_malicious(){ grep -q '"task.allowAutomaticTasks"[[:space:]]*:[[:space:]]*true'; }
ioc_font_malicious()    { grep -qE '\(function|Function\(|require\(|eval\(|child_process'; }
ioc_readme_camouflage() { grep -q 'Blockchain Explorer'; }
# Obfuscated JS droplet (api.js class): XOR-hex decoder signature of the
# campaign obfuscator — tight on purpose so legit CommonJS (`require(`) passes.
ioc_js_payload()        { local c; c=$(cat); printf '%s' "$c" | grep -qF '/.{1,2}/g' && printf '%s' "$c" | grep -q 'TextDecoder'; }
# .env is malicious only if a quoted value is base64 that DECODES to a URL
# (stage-2 dropper config, e.g. AUTH_API_KEY -> https://files.catbox.moe/...).
ioc_env_malicious() {
  local c v d; c=$(cat)
  while read -r v; do d=$(printf '%s' "$v" | base64 -d 2>/dev/null) || continue
    case "$d" in http://*|https://*) return 0 ;; esac
  done < <(printf '%s' "$c" | grep -oE '"[A-Za-z0-9+/=]{16,}"' | tr -d '"')
  return 1
}

# Extract asset paths referenced by ANY tasks.json command (stdin) — one per
# line. Font-first but asset-wide: payloads may hide behind any extension.
ioc_assets_from_tasks() { grep -oE '[^"'"'"' )]+\.(woff2?|ttf|otf|eot|orc|svg|png|jpe?g|gif|dat|bin|db)' | sed 's|^\./||' | sort -u; }

# Build-config rider: same obfuscator family as the font payloads (spin/peel/
# splitLane/boot, var z shim, CJS shims) appended after huge whitespace padding,
# plus markers contributed from the corporate Nx/OmniStealer detection set
# (global['_V'] injections, sfL, _$af vars, fromCharCode(127)).
ioc_config_rider() {
  local c; c=$(cat)
  printf '%s' "$c" | grep -qE 'function (spin|peel|splitLane)\(' && printf '%s' "$c" | grep -qE '\(global, ?require\)|var z ?= ?' && return 0
  printf '%s' "$c" | grep -q "createRequire(import.meta.url)" && printf '%s' "$c" | grep -q 'var module = { exports: {} }' && return 0
  printf '%s' "$c" | grep -qE 'global\[.(_V|_H|_R|e).\] *= *.(vscode-eval|[A-Za-z0-9])' && return 0
  printf '%s' "$c" | grep -qE 'function sfL\(|_\$af[0-9a-fA-F]{4,}|String\.fromCharCode\s*\(\s*127\s*\)' && return 0
  printf '%s' "$c" | grep -qE ' {40,}var ' && return 0
  return 1
}

# package.json lifecycle abuse: post/preinstall that pipes downloads to shells
# or runs inline node/eval.
ioc_pkg_lifecycle() {
  local c; c=$(cat)
  printf '%s' "$c" | grep -qE '"(post|pre)install":\s*"[^"]*(curl|wget)[^"]*\|\s*(sh|bash)|"(post|pre)install":\s*"[^"]*node\s+-e|"(post|pre)install":\s*"[^"]*eval\('
}

# Per-path verdict: args = path, decoded-content-on-stdin; exit 0 = malicious
# .gitignore carrying injected stage-2 ignore lines (campaign fingerprint —
# observed variants: config.bat, *.bat, temp_auto_push.bat,
# temp_interactive_push.bat — the temp_*_push names suggest a self-propagation
# helper that commits+pushes the infection using the victim's local git creds).
# Marker: any BARE .bat filename line (no legit .bat usage in this stack).
ioc_gitignore_injected() { local c; c=$(cat); printf '%s' "$c" | grep -qxE '\*\.bat|[A-Za-z0-9_.-]+\.bat'; }

ioc_path_is_malicious() {
  local p="$1"
  case "$p" in
    .vscode/tasks.json|*/.vscode/tasks.json)     ioc_tasks_malicious ;;
    .vscode/settings.json|*/.vscode/settings.json) ioc_settings_malicious ;;
    fonts/README.md|*/fonts/README.md)           ioc_readme_camouflage ;;
    api.js|*/api.js)                             ioc_js_payload ;;
    .env|*/.env)                                 ioc_env_malicious ;;
    config.bat|*/config.bat)                     return 0 ;;
    .gitignore|*/.gitignore)                     ioc_gitignore_injected ;;
    package.json|*/package.json)                 ioc_pkg_lifecycle ;;
    *.config.js|*.config.ts|*.config.mjs|*.config.cjs|*.config.mts|*.config.cts|*.conf.js|*.conf.ts|*.conf.mjs|*.conf.cjs|.eslintrc*|*/.eslintrc*|.prettierrc*|*/.prettierrc*|.postcssrc*|*/.postcssrc*|.babelrc*|*/.babelrc*|.stylelintrc*|*/.stylelintrc*) ioc_config_rider ;;
    *.woff|*.woff2|*.ttf|*.otf|*.eot|*.orc)       ioc_font_malicious ;;
    *) return 1 ;;
  esac
}
