#!/usr/bin/env bash
# =============================================================================
# Recording 2: Harness Self-Correction Demo
# =============================================================================
export TERM=${TERM:-xterm-256color}
cd "$(dirname "$0")/.."

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Save originals for restoration
GOOD_RESOURCE="src/main/java/dev/tedwon/QuoteResource.java"
GOOD_RESOURCE_BAK="/tmp/good-QuoteResource.java.bak"
TEST_FILE="src/test/java/dev/tedwon/QuoteResourceTest.java"
TEST_FILE_BAK="/tmp/good-QuoteResourceTest.java.bak"

cp "$GOOD_RESOURCE" "$GOOD_RESOURCE_BAK"
cp "$TEST_FILE" "$TEST_FILE_BAK"

# Cleanup on exit
cleanup() {
    cp "$GOOD_RESOURCE_BAK" "$GOOD_RESOURCE" 2>/dev/null || true
    cp "$TEST_FILE_BAK" "$TEST_FILE" 2>/dev/null || true
    rm -f "$GOOD_RESOURCE_BAK" "$TEST_FILE_BAK" 2>/dev/null || true
}
trap cleanup EXIT

clear
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  JBUG Korea Demo: Harness Self-Correction in Action       ║${NC}"
echo -e "${GREEN}║  하네스 자기 교정 실전 데모                               ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Part 2 - AI Agent makes mistakes, Harness catches them   ║${NC}"
echo -e "${GREEN}║  파트 2 - AI 에이전트가 실수하면 하네스가 잡아낸다        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 3

# --- Step 1: Show the bad code ---
section "Step 1: AI Agent writes code with violations / AI 에이전트가 위반 코드를 작성"
echo -e "  The agent created a REST endpoint but made several mistakes:"
echo -e "  에이전트가 REST 엔드포인트를 만들었지만 여러 실수가 있습니다:"
echo ""
sleep 1

# Plant the bad file & remove test
cp demo/bad-QuoteResource.java "$GOOD_RESOURCE"
rm -f "$TEST_FILE"

echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/QuoteResource.java${NC}"
sleep 1
cat "$GOOD_RESOURCE"
sleep 3

echo ""
echo -e "  ${RED}Line 22: System.out.println  (should use Logger / Logger를 사용해야 함)${NC}"
echo -e "  ${RED}Line 33: Wrong indentation   (2 spaces, should be 4 / 들여쓰기 오류)${NC}"
echo -e "  ${RED}Missing: QuoteResourceTest.java (테스트 파일 누락)${NC}"
sleep 3

# --- Step 2: Attempt commit ---
section "Step 2: Agent attempts commit with bad message / 에이전트가 잘못된 메시지로 커밋 시도"
echo -e "${YELLOW}$ bash demo/harness-check.sh \"added quote endpoint\"${NC}"
sleep 2

bash demo/harness-check.sh "added quote endpoint" || true
sleep 5

# --- Step 3: Fix violations ---
section "Step 3: Agent reads errors, fixes ALL violations / 에이전트가 오류를 읽고 모든 위반 수정"
sleep 1

echo -e "  ${GREEN}Fix 1: Replace System.out.println with Logger / System.out을 Logger로 교체${NC}"
sleep 1
echo -e "  ${GREEN}Fix 2: Run './mvnw spotless:apply' for formatting / 코드 포맷팅 자동 수정${NC}"
sleep 1
echo -e "  ${GREEN}Fix 3: Create QuoteResourceTest.java / 테스트 파일 생성${NC}"
sleep 1
echo -e "  ${GREEN}Fix 4: Use conventional commit message format / 커밋 메시지 형식 수정${NC}"
sleep 2

# Restore good files
cp "$GOOD_RESOURCE_BAK" "$GOOD_RESOURCE"
cp "$TEST_FILE_BAK" "$TEST_FILE"

echo ""
echo -e "${YELLOW}$ # Restoring correct code...${NC}"
sleep 1

echo -e "${YELLOW}$ diff <(head -22 demo/bad-QuoteResource.java) <(head -22 src/main/java/dev/tedwon/QuoteResource.java) | head -20${NC}"
sleep 1
diff <(head -22 demo/bad-QuoteResource.java) <(head -22 "$GOOD_RESOURCE") | head -20 || true
sleep 3

# --- Step 4: Retry commit ---
section "Step 4: Agent retries with all fixes applied / 에이전트가 수정 후 재시도"
echo -e "${YELLOW}$ bash demo/harness-check.sh \"feat(quotes): add quote of the day API\"${NC}"
sleep 2

bash demo/harness-check.sh "feat(quotes): add quote of the day API"
sleep 4

echo ""
echo -e "${GREEN}  ✓ Self-correction complete! Commit would succeed.${NC}"
echo -e "${GREEN}  ✓ 자기 교정 완료! 커밋 성공.${NC}"
echo ""
echo -e "${GREEN}  ✓ No human intervention needed — the harness guided the agent.${NC}"
echo -e "${GREEN}  ✓ 사람의 개입 없이 하네스가 에이전트를 가이드했습니다.${NC}"
echo ""
sleep 3
