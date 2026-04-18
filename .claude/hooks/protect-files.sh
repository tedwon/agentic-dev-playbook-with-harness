#!/usr/bin/env bash
# =============================================================================
# Protect-Files Hook for Quarkus Agentic Dev Playbook
# =============================================================================
# Called by Claude Code PreToolUse hook on Edit/Write tool calls.
# Blocks modification of harness configuration files.
#
# Exit 0 = allow (edit proceeds)
# Exit 2 = block (edit rejected)
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

[ -z "$FILE_PATH" ] && exit 0

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Normalize to relative path within project
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# If the path didn't change, it's outside the project — allow
[ "$REL_PATH" = "$FILE_PATH" ] && exit 0

# Protected files list
PROTECTED_FILES=(
    "CLAUDE.md"
    "CHECKLIST.md"
    ".claude/settings.json"
)

# Check exact matches
for pf in "${PROTECTED_FILES[@]}"; do
    if [ "$REL_PATH" = "$pf" ]; then
        cat >&2 <<MSG
HARNESS: EDIT BLOCKED
File '${REL_PATH}' is protected by the harness.
These files define the harness rules and cannot be modified by the AI agent.
If you need to change this file, ask the human operator for approval.
MSG
        exit 2
    fi
done

# Check if path is inside .claude/hooks/
if [[ "$REL_PATH" == .claude/hooks/* ]]; then
    cat >&2 <<MSG
HARNESS: EDIT BLOCKED
File '${REL_PATH}' is a harness hook script and is protected.
Hook scripts cannot be modified by the AI agent.
If you need to change this file, ask the human operator for approval.
MSG
    exit 2
fi

exit 0
