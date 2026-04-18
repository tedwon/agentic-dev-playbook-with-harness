#!/usr/bin/env bash
# =============================================================================
# Post-Edit Verification Hook for Quarkus Agentic Dev Playbook
# =============================================================================
# Called by Claude Code PostToolUse hook on Edit/Write tool calls.
# Runs a quick compile check after Java file edits.
# Provides early feedback (warning only, does not block).
#
# Exit 0 always (advisory, not blocking)
# =============================================================================

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only check Java source files
if [[ "$FILE_PATH" != *.java ]]; then
    exit 0
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Quick compile check (quiet mode, timeout 30s)
if ! timeout 30 ./mvnw compile -q 2>/dev/null; then
    BASENAME=$(basename "$FILE_PATH")
    echo "HARNESS WARNING: Compilation failed after editing ${BASENAME}. Run './mvnw compile' to see errors and fix them before committing." >&2
fi

exit 0
