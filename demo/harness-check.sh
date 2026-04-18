#!/usr/bin/env bash
# =============================================================================
# Standalone Harness Check (CLI version)
# =============================================================================
# Replicates the 7 checks from .claude/hooks/pre-commit-harness.sh
# but accepts commit message as a command-line argument instead of JSON stdin.
#
# Usage: bash demo/harness-check.sh "feat(quotes): add quote API"
# =============================================================================

COMMIT_MSG="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
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
    local rule_id="$1"
    echo "  [PASS] ${rule_id}"
    PASS_COUNT=$((PASS_COUNT + 1))
}

echo ""
echo "========================================"
echo "  HARNESS: Running ${TOTAL_CHECKS} pre-commit checks..."
echo "========================================"
echo ""

# CHECK 1: BUILD-01 — Compilation
echo "  CHECK 1/7: BUILD-01 (compilation)..."
if ./mvnw compile -q 2>&1 > /dev/null; then
    pass "BUILD-01"
else
    fail "BUILD-01" "Compilation failed.
  -> Run './mvnw compile' to see the full error output.
  -> Fix all compilation errors before committing."
fi

# CHECK 2: BUILD-02 — Tests
echo "  CHECK 2/7: BUILD-02 (tests)..."
if ./mvnw test -q 2>&1 > /dev/null; then
    pass "BUILD-02"
else
    fail "BUILD-02" "Tests failed.
  -> Run './mvnw test' to see which tests failed.
  -> Fix all failing tests before committing."
fi

# CHECK 3: BUILD-03 — Code Formatting (Spotless)
echo "  CHECK 3/7: BUILD-03 (formatting)..."
if ./mvnw spotless:check -q 2>&1 > /dev/null; then
    pass "BUILD-03"
else
    fail "BUILD-03" "Code formatting violations found.
  -> Run './mvnw spotless:apply' to auto-fix formatting.
  -> Then stage the reformatted files with 'git add'."
fi

# CHECK 4: QUAL-01 — No System.out.println
echo "  CHECK 4/7: QUAL-01 (no System.out)..."
SYSOUT_FILES=$(grep -rl "System\.out\.print" src/main/java/ 2>/dev/null || true)
if [ -z "$SYSOUT_FILES" ]; then
    pass "QUAL-01"
else
    fail "QUAL-01" "System.out.println found in: ${SYSOUT_FILES}
  -> Replace with org.jboss.logging.Logger.
  -> Example:
     private static final Logger LOG = Logger.getLogger(YourClass.class);
     LOG.info(\"your message\");"
fi

# CHECK 5: QUAL-02 — No Hardcoded Secrets
echo "  CHECK 5/7: QUAL-02 (no hardcoded secrets)..."
SECRET_PATTERNS='(password|apiKey|api_key|secret|token)\s*=\s*"[^"$]+'
SECRET_FILES=$(grep -rEl "$SECRET_PATTERNS" src/main/java/ src/main/resources/ 2>/dev/null || true)
if [ -z "$SECRET_FILES" ]; then
    pass "QUAL-02"
else
    fail "QUAL-02" "Possible hardcoded secrets in: ${SECRET_FILES}
  -> Use @ConfigProperty or environment variables instead."
fi

# CHECK 6: CONV-01 — Conventional Commits
echo "  CHECK 6/7: CONV-01 (conventional commits)..."
if [ -n "$COMMIT_MSG" ]; then
    if echo "$COMMIT_MSG" | grep -qE "^(feat|fix|docs|refactor|test|chore)(\(.+\))?: .+"; then
        pass "CONV-01"
    else
        fail "CONV-01" "Commit message '${COMMIT_MSG}' does not follow Conventional Commits format.
  -> Required: <type>(<scope>): <subject>
  -> Types: feat, fix, docs, refactor, test, chore
  -> Example: feat(greeting): add personalized greeting endpoint"
    fi
else
    fail "CONV-01" "No commit message provided.
  -> Usage: bash demo/harness-check.sh \"feat(scope): subject\""
fi

# CHECK 7: CONV-02 — Test Coverage for REST Endpoints
echo "  CHECK 7/7: CONV-02 (test coverage)..."
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
    pass "CONV-02"
else
    fail "CONV-02" "Missing test files for REST endpoints:${MISSING_TESTS}
  -> Create corresponding *Test.java files with @QuarkusTest annotation."
fi

# REPORT
echo ""
if [ -z "$ERRORS" ]; then
    echo "========================================"
    echo "  HARNESS: ALL ${TOTAL_CHECKS}/${TOTAL_CHECKS} CHECKS PASSED"
    echo "  Commit allowed."
    echo "========================================"
else
    FAIL_COUNT=$((TOTAL_CHECKS - PASS_COUNT))
    echo "========================================"
    echo "  HARNESS: COMMIT BLOCKED"
    echo "  ${PASS_COUNT}/${TOTAL_CHECKS} checks passed, ${FAIL_COUNT} failed"
    echo "========================================"
    echo "${ERRORS}"
    echo ""
    echo "----------------------------------------"
    echo "ACTION REQUIRED: Fix ALL [FAIL] items above, then retry."
    echo "========================================"
fi
