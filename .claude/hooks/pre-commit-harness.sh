#!/usr/bin/env bash
# =============================================================================
# Pre-Commit Harness for Quarkus Agentic Dev Playbook
# =============================================================================
# Called by Claude Code PreToolUse hook on Bash tool calls.
# Only intercepts "git commit" commands. All other commands pass through.
#
# Exit 0 = allow (commit proceeds)
# Exit 2 = block (commit rejected, agent must fix and retry)
#
# Design: collects ALL failures before exiting so the agent can fix
# everything in one pass. Error messages are formatted for LLM consumption.
# =============================================================================

# --- Read stdin JSON from Claude Code ---
INPUT=$(cat)

HOOK_CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")

# --- Guard clause: only intercept git commit commands ---
if ! echo "$HOOK_CMD" | grep -q "git commit"; then
    exit 0
fi

# --- Setup ---
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=""
PASS_COUNT=0
TOTAL_CHECKS=7

fail() {
    local rule_id="$1"
    local message="$2"
    ERRORS="${ERRORS}
[FAIL] ${rule_id}: ${message}"
}

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
}

# --- Extract commit message from -m flag ---
COMMIT_MSG=$(python3 -c "
import re, sys
cmd = sys.argv[1]
# Match -m with double-quoted string
m = re.search(r'-m\s+\"(.*?)\"', cmd, re.DOTALL)
if m:
    print(m.group(1).split(chr(10))[0].strip())
else:
    # Match -m with single-quoted string
    m = re.search(r\"-m\s+'(.*?)'\", cmd, re.DOTALL)
    if m:
        print(m.group(1).split(chr(10))[0].strip())
    else:
        # Heredoc: extract first non-empty line after EOF marker
        m = re.search(r'cat <<.*?EOF.*?\n(.*?)\n', cmd, re.DOTALL)
        if m:
            print(m.group(1).strip().split(chr(10))[0].strip())
        else:
            print('')
" "$HOOK_CMD" 2>/dev/null || echo "")

# =============================================================================
# CHECK 1: BUILD-01 — Compilation
# =============================================================================
echo "HARNESS: Running BUILD-01 (compilation)..." >&2
if ./mvnw compile -q 2>&1; then
    pass
else
    fail "BUILD-01" "Compilation failed.
  -> Run './mvnw compile' to see the full error output.
  -> Fix all compilation errors before committing."
fi

# =============================================================================
# CHECK 2: BUILD-02 — Tests
# =============================================================================
echo "HARNESS: Running BUILD-02 (tests)..." >&2
if ./mvnw test -q 2>&1; then
    pass
else
    fail "BUILD-02" "Tests failed.
  -> Run './mvnw test' to see which tests failed.
  -> Fix all failing tests before committing."
fi

# =============================================================================
# CHECK 3: BUILD-03 — Code Formatting (Spotless)
# =============================================================================
echo "HARNESS: Running BUILD-03 (formatting)..." >&2
if ./mvnw spotless:check -q 2>&1; then
    pass
else
    fail "BUILD-03" "Code formatting violations found.
  -> Run './mvnw spotless:apply' to auto-fix formatting.
  -> Then stage the reformatted files with 'git add'."
fi

# =============================================================================
# CHECK 4: QUAL-01 — No System.out.println
# =============================================================================
echo "HARNESS: Running QUAL-01 (no System.out)..." >&2
SYSOUT_FILES=$(grep -rl "System\.out\.print" src/main/java/ 2>/dev/null || true)
if [ -z "$SYSOUT_FILES" ]; then
    pass
else
    fail "QUAL-01" "System.out.println found in: ${SYSOUT_FILES}
  -> Replace with org.jboss.logging.Logger.
  -> Example:
     private static final Logger LOG = Logger.getLogger(YourClass.class);
     LOG.info(\"your message\");"
fi

# =============================================================================
# CHECK 5: QUAL-02 — No Hardcoded Secrets
# =============================================================================
echo "HARNESS: Running QUAL-02 (no hardcoded secrets)..." >&2
SECRET_PATTERNS='(password|apiKey|api_key|secret|token)\s*=\s*"[^"$]+'
SECRET_FILES=$(grep -rEl "$SECRET_PATTERNS" src/main/java/ src/main/resources/ 2>/dev/null || true)
if [ -z "$SECRET_FILES" ]; then
    pass
else
    fail "QUAL-02" "Possible hardcoded secrets in: ${SECRET_FILES}
  -> Use @ConfigProperty or environment variables instead.
  -> Example:
     @ConfigProperty(name = \"app.api-key\")
     String apiKey;"
fi

# =============================================================================
# CHECK 6: CONV-01 — Conventional Commits
# =============================================================================
echo "HARNESS: Running CONV-01 (conventional commits)..." >&2
if [ -n "$COMMIT_MSG" ]; then
    if echo "$COMMIT_MSG" | grep -qE "^(feat|fix|docs|refactor|test|chore)(\(.+\))?: .+"; then
        pass
    else
        fail "CONV-01" "Commit message '${COMMIT_MSG}' does not follow Conventional Commits format.
  -> Required: <type>(<scope>): <subject>
  -> Types: feat, fix, docs, refactor, test, chore
  -> Example: feat(greeting): add personalized greeting endpoint"
    fi
else
    fail "CONV-01" "Could not extract commit message. Use -m flag with Conventional Commits format.
  -> Required: <type>(<scope>): <subject>
  -> Example: git commit -m \"feat(time): add server time endpoint\""
fi

# =============================================================================
# CHECK 7: CONV-02 — Test Coverage for REST Endpoints
# =============================================================================
echo "HARNESS: Running CONV-02 (test coverage)..." >&2
MISSING_TESTS=""
while IFS= read -r resource; do
    [ -z "$resource" ] && continue
    classname=$(basename "$resource" .java)
    rel_path="${resource#src/main/java/}"
    test_dir="src/test/java/$(dirname "$rel_path")"
    testfile="${test_dir}/${classname}Test.java"
    if [ ! -f "$testfile" ]; then
        MISSING_TESTS="${MISSING_TESTS} ${classname}"
    fi
done < <(find src/main/java -name "*.java" -exec grep -l "@Path" {} \; 2>/dev/null)

if [ -z "$MISSING_TESTS" ]; then
    pass
else
    fail "CONV-02" "Missing test files for REST endpoints:${MISSING_TESTS}
  -> Create corresponding *Test.java files with @QuarkusTest annotation.
  -> Example: src/test/java/dev/tedwon/TimeResourceTest.java"
fi

# =============================================================================
# REPORT
# =============================================================================
if [ -z "$ERRORS" ]; then
    echo "" >&2
    echo "========================================" >&2
    echo "HARNESS: ALL ${TOTAL_CHECKS}/${TOTAL_CHECKS} CHECKS PASSED" >&2
    echo "Commit allowed." >&2
    echo "========================================" >&2
    exit 0
else
    FAIL_COUNT=$((TOTAL_CHECKS - PASS_COUNT))
    cat >&2 <<REPORT

========================================
HARNESS: COMMIT BLOCKED
${PASS_COUNT}/${TOTAL_CHECKS} checks passed, ${FAIL_COUNT} failed
========================================
${ERRORS}

----------------------------------------
ACTION REQUIRED: Fix ALL [FAIL] items above, then retry the commit.
- For BUILD-03 (formatting): run './mvnw spotless:apply' then 'git add .'
- For QUAL-01 (System.out): replace with org.jboss.logging.Logger
- For CONV-01 (commit message): use format 'type(scope): subject'
========================================
REPORT
    exit 2
fi
