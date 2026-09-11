#!/usr/bin/env bash
# ==============================================================================
# link-project.sh
# Connect a project's local /docs directory to a central engineering handbook
# Generates portable relative symlinks without hardcoded filesystem paths.
#
# Usage:
#   ./scripts/link-project.sh <project-name-or-path> [handbook-path]
#
# Or with environment variable:
#   HANDBOOK_DIR=/path/to/handbook ./scripts/link-project.sh <project-name-or-path>
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Argument Validation ---
if [ -z "$1" ]; then
    echo "Usage: $0 <project-name-or-path> [handbook-path]"
    echo ""
    echo "Examples:"
    echo "  $0 ../my-service"
    echo "  $0 /path/to/my-service"
    echo "  $0 my-service ../engineering-handbook"
    echo "  HANDBOOK_DIR=../engineering-handbook $0 my-service"
    exit 1
fi

INPUT_PROJECT="$1"
INPUT_HANDBOOK="$2"

# --- Resolve Target Project Path ---
if [[ "$INPUT_PROJECT" == ~* ]]; then
    EXPANDED_PROJECT="${INPUT_PROJECT/#\~/$HOME}"
else
    EXPANDED_PROJECT="$INPUT_PROJECT"
fi

if [ -d "$EXPANDED_PROJECT" ]; then
    TARGET_PROJECT="$(cd "$EXPANDED_PROJECT" && pwd)"
elif [ -d "$(pwd)/$INPUT_PROJECT" ]; then
    TARGET_PROJECT="$(cd "$(pwd)/$INPUT_PROJECT" && pwd)"
else
    # Check if target is a sibling of the current directory or workspace
    CURRENT_PARENT="$(cd "$(pwd)/.." && pwd)"
    if [ -d "$CURRENT_PARENT/$INPUT_PROJECT" ]; then
        TARGET_PROJECT="$(cd "$CURRENT_PARENT/$INPUT_PROJECT" && pwd)"
    else
        echo "❌ Error: Project directory not found at '$INPUT_PROJECT'"
        exit 1
    fi
fi

PROJECT_NAME="$(basename "$TARGET_PROJECT")"

# --- Resolve Handbook Path ---
HANDBOOK_ROOT=""

if [ -n "$INPUT_HANDBOOK" ]; then
    if [[ "$INPUT_HANDBOOK" == ~* ]]; then
        EXPANDED_HB="${INPUT_HANDBOOK/#\~/$HOME}"
    else
        EXPANDED_HB="$INPUT_HANDBOOK"
    fi
    if [ -d "$EXPANDED_HB" ]; then
        HANDBOOK_ROOT="$(cd "$EXPANDED_HB" && pwd)"
    else
        echo "❌ Error: Specified handbook path not found at '$INPUT_HANDBOOK'"
        exit 1
    fi
elif [ -n "$HANDBOOK_DIR" ]; then
    if [ -d "$HANDBOOK_DIR" ]; then
        HANDBOOK_ROOT="$(cd "$HANDBOOK_DIR" && pwd)"
    else
        echo "❌ Error: HANDBOOK_DIR environment variable points to non-existent directory: '$HANDBOOK_DIR'"
        exit 1
    fi
else
    # Auto-discovery heuristic
    PROJECT_PARENT="$(cd "$TARGET_PROJECT/.." && pwd)"
    PLAYBOOK_REPO_PARENT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

    CANDIDATES=(
        "$PROJECT_PARENT/engineering-handbook"
        "$PROJECT_PARENT/handbook"
        "$PLAYBOOK_REPO_PARENT/engineering-handbook"
        "$PLAYBOOK_REPO_PARENT/handbook"
        "$(pwd)"
    )

    for CANDIDATE in "${CANDIDATES[@]}"; do
        if [ -d "$CANDIDATE" ] && { [ -d "$CANDIDATE/projects" ] || [ "$(basename "$CANDIDATE")" = "engineering-handbook" ] || [ "$(basename "$CANDIDATE")" = "handbook" ]; }; then
            HANDBOOK_ROOT="$(cd "$CANDIDATE" && pwd)"
            break
        fi
    done
fi

if [ -z "$HANDBOOK_ROOT" ]; then
    echo "❌ Error: Central engineering handbook directory could not be discovered automatically."
    echo ""
    echo "Please provide the handbook path as the second argument or set HANDBOOK_DIR:"
    echo "  $0 $INPUT_PROJECT /path/to/engineering-handbook"
    echo "  HANDBOOK_DIR=/path/to/engineering-handbook $0 $INPUT_PROJECT"
    exit 1
fi

HANDBOOK_PROJECT_DIR="$HANDBOOK_ROOT/projects/$PROJECT_NAME"
TARGET_DOCS="$TARGET_PROJECT/docs"

echo "============================================================"
echo "🔗 Linking Project to Engineering Handbook"
echo "Project Name : $PROJECT_NAME"
echo "Project Path : $TARGET_PROJECT"
echo "Handbook Root: $HANDBOOK_ROOT"
echo "Handbook Dir : $HANDBOOK_PROJECT_DIR"
echo "============================================================"

# Step 1: Ensure project directory exists in handbook
mkdir -p "$HANDBOOK_PROJECT_DIR"

# Step 2: Handle existing docs folder in target project
if [ -d "$TARGET_DOCS" ] && [ ! -L "$TARGET_DOCS" ]; then
    echo "📦 Moving existing docs from project to handbook..."
    cp -rn "$TARGET_DOCS/"* "$HANDBOOK_PROJECT_DIR/" 2>/dev/null || true
    rm -rf "$TARGET_DOCS"
elif [ -L "$TARGET_DOCS" ]; then
    echo "🔄 Existing symlink found, refreshing..."
    rm -f "$TARGET_DOCS"
fi

# Step 3: Compute portable relative path from target project to handbook dir
# Relative symlinks stay valid when the workspace or parent directory is moved or cloned
RELATIVE_TARGET=""
if command -v python3 >/dev/null 2>&1; then
    RELATIVE_TARGET="$(python3 -c "import os.path; print(os.path.relpath('$HANDBOOK_PROJECT_DIR', '$TARGET_PROJECT'))")"
elif command -v realpath >/dev/null 2>&1 && realpath --relative-to="/" "/" >/dev/null 2>&1; then
    RELATIVE_TARGET="$(realpath --relative-to="$TARGET_PROJECT" "$HANDBOOK_PROJECT_DIR")"
else
    # Fallback to absolute path if neither tool is available
    RELATIVE_TARGET="$HANDBOOK_PROJECT_DIR"
fi

ln -s "$RELATIVE_TARGET" "$TARGET_DOCS"
echo "✅ Portable symlink created: $TARGET_DOCS -> $RELATIVE_TARGET"

# Step 4: Ensure target project's .gitignore ignores /docs and /docs/
GITIGNORE="$TARGET_PROJECT/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -Eq "^/?docs($|/)" "$GITIGNORE"; then
        echo -e "\n# Planning & learning docs — private, synced to engineering-handbook\n/docs\n/docs/" >> "$GITIGNORE"
        echo "🛡️  Added '/docs' and '/docs/' to $GITIGNORE (Zero Leakage Rule)"
    else
        # Ensure bare /docs is present so symlinks are ignored
        if ! grep -Eq "^/?docs$" "$GITIGNORE"; then
            echo "/docs" >> "$GITIGNORE"
            echo "🛡️  Added bare '/docs' to $GITIGNORE for symlink support"
        else
            echo "🛡️  '/docs' already ignored in $GITIGNORE"
        fi
    fi
else
    echo -e "# Planning & learning docs — private, synced to engineering-handbook\n/docs\n/docs/\n" > "$GITIGNORE"
    echo "🛡️  Created $GITIGNORE with '/docs' ignored"
fi

echo ""
echo "🎉 Success! '$PROJECT_NAME' is now connected to the engineering handbook."
echo "👉 You can edit docs directly in '$TARGET_PROJECT/docs'."
echo "👉 Changes are safely stored in '$HANDBOOK_PROJECT_DIR' and won't leak to the project repo."
echo "============================================================"
