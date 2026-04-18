#!/usr/bin/env bash
# =============================================================================
# Install Git Hooks for Harness Engineering
# =============================================================================
# Enables the 7 automated quality checks for any git client
# (Cursor, Copilot, VS Code, manual git, etc.)
#
# Usage: ./scripts/install-git-hooks.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOKS_DIR="${PROJECT_ROOT}/.git/hooks"

if [ ! -d "${PROJECT_ROOT}/.git" ]; then
    echo "Error: Not a git repository. Run this script from the project root." >&2
    exit 1
fi

echo "Installing git hooks for harness engineering..."
echo ""

# Install pre-commit hook (BUILD-01..02, BUILD-03, QUAL-01..02, CONV-02)
ln -sf "../../hooks/pre-commit" "${GIT_HOOKS_DIR}/pre-commit"
chmod +x "${PROJECT_ROOT}/hooks/pre-commit"
echo "  Installed: pre-commit (6 checks: BUILD-01, BUILD-02, BUILD-03, QUAL-01, QUAL-02, CONV-02)"

# Install commit-msg hook (CONV-01)
ln -sf "../../hooks/commit-msg" "${GIT_HOOKS_DIR}/commit-msg"
chmod +x "${PROJECT_ROOT}/hooks/commit-msg"
echo "  Installed: commit-msg (1 check: CONV-01 conventional commits)"

echo ""
echo "All 7 harness checks are now active on every commit."
echo ""
echo "To uninstall:"
echo "  rm .git/hooks/pre-commit .git/hooks/commit-msg"
