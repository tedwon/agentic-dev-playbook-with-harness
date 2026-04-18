#!/usr/bin/env bash
# =============================================================================
# Agentic Workflow Demo — Recording 2: Execute + Review + Validate (Phase 2-4)
# 에이전틱 워크플로우 데모 — 녹화 2: 실행 + 리뷰 + 검증 (2-4단계)
# =============================================================================
export TERM=${TERM:-xterm-256color}
cd "$(dirname "$0")/../.."

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Save originals for self-correction demo
GOOD_RESOURCE="src/main/java/dev/tedwon/QuoteResource.java"
GOOD_RESOURCE_BAK="/tmp/agentic-good-QuoteResource.java.bak"
TEST_FILE="src/test/java/dev/tedwon/QuoteResourceTest.java"
TEST_FILE_BAK="/tmp/agentic-good-QuoteResourceTest.java.bak"

cp "$GOOD_RESOURCE" "$GOOD_RESOURCE_BAK"
cp "$TEST_FILE" "$TEST_FILE_BAK"

cleanup() {
    cp "$GOOD_RESOURCE_BAK" "$GOOD_RESOURCE" 2>/dev/null || true
    cp "$TEST_FILE_BAK" "$TEST_FILE" 2>/dev/null || true
    rm -f "$GOOD_RESOURCE_BAK" "$TEST_FILE_BAK" 2>/dev/null || true
    kill $QUARKUS_PID 2>/dev/null || true
    wait $QUARKUS_PID 2>/dev/null || true
}
trap cleanup EXIT
QUARKUS_PID=""

clear
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Agentic Development Workflow + Harness Engineering Demo          ║${NC}"
echo -e "${GREEN}║  에이전틱 개발 워크플로우 + 하네스 엔지니어링 데모               ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║  Part 2: Execute → Review → Validate                              ║${NC}"
echo -e "${GREEN}║  파트 2: 실행 → 리뷰 → 검증                                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
sleep 4

# ===========================================================================
# PHASE 2: EXECUTION
# ===========================================================================
section "Phase 2: Execution / 실행 단계"

echo -e "  ${DIM}In a fresh Claude Code session:${NC}"
echo -e "  ${DIM}새로운 Claude Code 세션에서:${NC}"
echo ""
echo -e "  ${YELLOW}> /executing-plans docs/superpowers/plans/2026-04-18-DEMO-001-quote-api.md${NC}"
echo ""
sleep 2

echo -e "  ${WHITE}Agent follows the plan step-by-step:${NC}"
echo -e "  ${WHITE}에이전트가 계획을 단계별로 따릅니다:${NC}"
echo ""
echo -e "  ${GREEN}  ✓ Task 1: Add quarkus-rest-jackson dependency${NC}"
echo -e "  ${DIM}             Jackson 의존성 추가${NC}"
echo -e "  ${GREEN}  ✓ Task 2: Create Quote.java Record${NC}"
echo -e "  ${DIM}             Quote 레코드 DTO 생성${NC}"
echo -e "  ${GREEN}  ✓ Task 3: Create QuoteService + tests${NC}"
echo -e "  ${DIM}             QuoteService CDI 서비스 + 테스트 생성${NC}"
echo -e "  ${GREEN}  → Task 4: Create QuoteResource + tests  (in progress...)${NC}"
echo -e "  ${DIM}             QuoteResource REST 엔드포인트 + 테스트 생성 (진행 중...)${NC}"
sleep 4

# --- Show the implemented code ---
section "Phase 2: Task 4 — QuoteResource implementation / QuoteResource 구현"

echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/QuoteResource.java${NC}"
sleep 1
cat src/main/java/dev/tedwon/QuoteResource.java
sleep 3

echo ""
echo -e "  ${WHITE}Self-review (Reflection pattern):${NC}"
echo -e "  ${WHITE}자기 검토 (성찰 패턴):${NC}"
echo -e "  ${GREEN}  ✓ All 3 endpoints match the spec / 3개 엔드포인트가 명세와 일치${NC}"
echo -e "  ${GREEN}  ✓ Category filter implemented / 카테고리 필터 구현됨${NC}"
echo -e "  ${GREEN}  ✓ 404 handling for missing quotes / 없는 ID에 대한 404 처리${NC}"
echo -e "  ${GREEN}  ✓ Logger used, no System.out / Logger 사용, System.out 없음${NC}"
sleep 4

# ===========================================================================
# HARNESS SELF-CORRECTION
# ===========================================================================
section "Phase 2: Harness Self-Correction / 하네스 자기 교정"

echo -e "  ${WHITE}But what if the agent makes mistakes during implementation?${NC}"
echo -e "  ${WHITE}하지만 에이전트가 구현 중 실수를 하면 어떻게 될까요?${NC}"
echo ""
sleep 2

echo -e "  ${RED}Simulating an agent that wrote code with violations:${NC}"
echo -e "  ${RED}위반 사항이 있는 코드를 작성한 에이전트를 시뮬레이션합니다:${NC}"
echo ""
sleep 1

# Plant bad code
cp demo/bad-QuoteResource.java "$GOOD_RESOURCE"
rm -f "$TEST_FILE"

echo -e "  ${RED}  • System.out.println instead of Logger${NC}"
echo -e "  ${RED}    System.out.println 사용 (Logger 대신)${NC}"
echo -e "  ${RED}  • Wrong indentation (formatting violation)${NC}"
echo -e "  ${RED}    잘못된 들여쓰기 (포맷팅 위반)${NC}"
echo -e "  ${RED}  • Missing test file${NC}"
echo -e "  ${RED}    테스트 파일 누락${NC}"
echo -e "  ${RED}  • Bad commit message: \"added quote endpoint\"${NC}"
echo -e "  ${RED}    잘못된 커밋 메시지${NC}"
sleep 3

echo ""
echo -e "  ${YELLOW}$ bash demo/harness-check.sh \"added quote endpoint\"${NC}"
sleep 2
bash demo/harness-check.sh "added quote endpoint" || true
sleep 5

echo ""
echo -e "  ${WHITE}The harness blocked the commit and told the agent exactly what to fix.${NC}"
echo -e "  ${WHITE}하네스가 커밋을 차단하고 에이전트에게 정확히 무엇을 고쳐야 하는지 알려줍니다.${NC}"
sleep 3

# --- Fix and retry ---
section "Phase 2: Agent fixes all violations / 에이전트가 모든 위반 수정"

echo -e "  ${GREEN}The agent reads the error messages and fixes ALL issues:${NC}"
echo -e "  ${GREEN}에이전트가 오류 메시지를 읽고 모든 문제를 수정합니다:${NC}"
echo ""

cp "$GOOD_RESOURCE_BAK" "$GOOD_RESOURCE"
cp "$TEST_FILE_BAK" "$TEST_FILE"

echo -e "  ${GREEN}  ✓ System.out.println → Logger / Logger로 교체${NC}"
sleep 1
echo -e "  ${GREEN}  ✓ ./mvnw spotless:apply → formatting fixed / 포맷팅 수정${NC}"
sleep 1
echo -e "  ${GREEN}  ✓ QuoteResourceTest.java created / 테스트 파일 생성${NC}"
sleep 1
echo -e "  ${GREEN}  ✓ Commit message: \"feat(quotes): add quote of the day API\"${NC}"
sleep 2

echo ""
echo -e "  ${YELLOW}$ bash demo/harness-check.sh \"feat(quotes): add quote of the day API\"${NC}"
sleep 2
bash demo/harness-check.sh "feat(quotes): add quote of the day API"
sleep 4

echo ""
echo -e "  ${BOLD}${WHITE}Agent = Model + Harness${NC}"
echo -e "  ${DIM}The harness is the safety net that enables autonomous development.${NC}"
echo -e "  ${DIM}하네스는 자율적 개발을 가능하게 하는 안전망입니다.${NC}"
sleep 3

# ===========================================================================
# PHASE 3: REVIEW
# ===========================================================================
section "Phase 3: Code Review / 코드 리뷰 단계"

echo -e "  ${DIM}In Claude Code:${NC}"
echo ""
echo -e "  ${YELLOW}> /requesting-code-review${NC}"
echo ""
sleep 1

echo -e "  ${WHITE}The code-reviewer subagent checks:${NC}"
echo -e "  ${WHITE}코드 리뷰어 서브에이전트가 검토합니다:${NC}"
echo ""
echo -e "  ${GREEN}  ✓ Security — no injection, no hardcoded secrets${NC}"
echo -e "  ${DIM}    보안 — 인젝션 없음, 하드코딩된 시크릿 없음${NC}"
echo -e "  ${GREEN}  ✓ Correctness — all spec requirements covered${NC}"
echo -e "  ${DIM}    정확성 — 모든 명세 요구사항 충족${NC}"
echo -e "  ${GREEN}  ✓ Conventions — follows CLAUDE.md and AGENTS.md${NC}"
echo -e "  ${DIM}    컨벤션 — CLAUDE.md, AGENTS.md 준수${NC}"
echo -e "  ${GREEN}  ✓ Test quality — meaningful assertions, not just 200 OK${NC}"
echo -e "  ${DIM}    테스트 품질 — 의미 있는 검증, 단순 200 OK가 아님${NC}"
echo ""
echo -e "  ${YELLOW}Human reviewer: can you explain WHY the agent chose this approach?${NC}"
echo -e "  ${YELLOW}사람 리뷰어: 에이전트가 왜 이 접근법을 선택했는지 설명할 수 있나요?${NC}"
echo -e "  ${DIM}  (Skill atrophy check — developers must understand the code)${NC}"
echo -e "  ${DIM}  (기술 퇴화 점검 — 개발자가 코드를 이해해야 합니다)${NC}"
sleep 5

# ===========================================================================
# PHASE 4: VALIDATION
# ===========================================================================
section "Phase 4: Validation / 검증 단계"

echo -e "  ${YELLOW}$ ./mvnw test${NC}"
sleep 1
./mvnw test -q 2>&1
echo ""
echo -e "  ${GREEN}  ✓ 11 tests passed / 11개 테스트 통과${NC}"
sleep 3

echo ""
echo -e "  ${WHITE}Starting Quarkus dev mode for live validation...${NC}"
echo -e "  ${WHITE}라이브 검증을 위해 Quarkus 개발 모드를 시작합니다...${NC}"
echo ""

./mvnw quarkus:dev -Dquarkus.http.host=localhost -Dquarkus.test.enabled=false > /dev/null 2>&1 &
QUARKUS_PID=$!

ATTEMPTS=0
until curl -sf http://localhost:8080/q/health/live > /dev/null 2>&1; do
    sleep 1
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -gt 30 ]; then
        echo -e "  ${RED}Quarkus failed to start${NC}"
        exit 1
    fi
done
echo -e "  ${GREEN}  ✓ Quarkus running on http://localhost:8080${NC}"
sleep 2

echo ""
echo -e "  ${CYAN}--- GET /api/quotes/random ---${NC}"
echo -e "  ${YELLOW}$ curl -s localhost:8080/api/quotes/random | jq .${NC}"
sleep 1
curl -s http://localhost:8080/api/quotes/random | python3 -m json.tool
sleep 3

echo ""
echo -e "  ${CYAN}--- GET /api/quotes?category=programming ---${NC}"
echo -e "  ${YELLOW}$ curl -s 'localhost:8080/api/quotes?category=programming' | jq .${NC}"
sleep 1
curl -s "http://localhost:8080/api/quotes?category=programming" | python3 -m json.tool
sleep 3

echo ""
echo -e "  ${CYAN}--- GET /api/quotes/999 → 404 ---${NC}"
echo -e "  ${YELLOW}$ curl -s -o /dev/null -w '%{http_code}' localhost:8080/api/quotes/999${NC}"
sleep 1
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/quotes/999)
echo "  HTTP $HTTP_CODE (Not Found)"
sleep 3

# ===========================================================================
# VALIDATION CHECKLIST
# ===========================================================================
section "Phase 4: Validation Checklist / 검증 체크리스트"

echo -e "  ${GREEN}  ✓${NC} Application starts without errors          ${GREEN}에러 없이 시작됨${NC}"
echo -e "  ${GREEN}  ✓${NC} All tests pass (./mvnw verify)             ${GREEN}모든 테스트 통과${NC}"
echo -e "  ${GREEN}  ✓${NC} REST endpoints return correct JSON         ${GREEN}올바른 JSON 응답${NC}"
echo -e "  ${GREEN}  ✓${NC} 404 for missing resources                  ${GREEN}없는 리소스에 404${NC}"
echo -e "  ${GREEN}  ✓${NC} No System.out in production code           ${GREEN}프로덕션 코드에 System.out 없음${NC}"
echo -e "  ${GREEN}  ✓${NC} Harness: 7/7 checks passed                ${GREEN}하네스 7/7 검증 통과${NC}"
echo -e "  ${GREEN}  ✓${NC} Reviewer can explain the implementation    ${GREEN}리뷰어가 구현을 설명 가능${NC}"
echo -e "  ${GREEN}  ✓${NC} Spec + Plan saved as audit trail           ${GREEN}명세 + 계획 감사 추적 저장${NC}"
sleep 5

# ===========================================================================
# SUMMARY
# ===========================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Agentic Development Workflow — Complete / 전체 워크플로우 완료   ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║  Phase 1: Design    Spec + Plan created        설계: 명세+계획     ║${NC}"
echo -e "${GREEN}║  Phase 2: Execute   Code + Harness loop        실행: 코드+하네스   ║${NC}"
echo -e "${GREEN}║  Phase 3: Review    AI + Human review          리뷰: AI+사람 검토  ║${NC}"
echo -e "${GREEN}║  Phase 4: Validate  Tests + Live verification  검증: 테스트+실행   ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║  ${BOLD}Human-in-the-loop: AI generates, Human decides${NC}${GREEN}                  ║${NC}"
echo -e "${GREEN}║  ${BOLD}사람이 참여: AI가 생성하고, 사람이 결정합니다${NC}${GREEN}                    ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
sleep 5
