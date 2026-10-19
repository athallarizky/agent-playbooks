#!/usr/bin/env bash
# Shared IOC definitions + marker checks for gh-incident-response scripts.
# Source this file: . "$(dirname "$0")/lib-ioc.sh"
# Extend IOC_* here as new campaign markers are discovered.

# Stage-1: suspicious paths in a recursive tree listing (fast, no content fetch)
IOC_PATH_REGEX='^\.vscode/tasks\.json$|^\.vscode/settings\.json$|fa-brand-[0-9][^/]*\.(woff|woff2|ttf|otf)$|fonts/README\.md$'

# Marker checks (stage-2, operate on decoded file content via stdin)
ioc_tasks_malicious()   { grep -q 'folderOpen' && grep -qE '(node|python|perl|ruby|bash|sh|powershell) ' && grep -qE '\.(woff2?|ttf|otf|eot|svg)'; }
ioc_settings_malicious(){ grep -q '"task.allowAutomaticTasks"[[:space:]]*:[[:space:]]*true'; }
ioc_font_malicious()    { grep -qE '\(function|Function\(|require\(|eval\(|child_process'; }
ioc_readme_camouflage() { grep -q 'Blockchain Explorer'; }

# Extract asset paths referenced by a malicious tasks.json (stdin) — payload
# fonts are named in the task command; return them one per line.
ioc_assets_from_tasks() { grep -oE '[^"'"'"' ]+\.(woff2?|ttf|otf|eot)' | sort -u; }

# Per-path verdict: args = path, decoded-content-on-stdin; exit 0 = malicious
ioc_path_is_malicious() {
  local p="$1"
  case "$p" in
    */.vscode/tasks.json|.vscode/tasks.json)     ioc_tasks_malicious ;;
    */.vscode/settings.json|.vscode/settings.json) ioc_settings_malicious ;;
    */fonts/README.md|fonts/README.md)           ioc_readme_camouflage ;;
    *.woff|*.woff2|*.ttf|*.otf)                  ioc_font_malicious ;;
    *) return 1 ;;
  esac
}
