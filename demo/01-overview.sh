#!/usr/bin/env bash
# =============================================================================
# Recording 1: Project Structure & Harness Overview
# =============================================================================
export TERM=${TERM:-xterm-256color}
cd "$(dirname "$0")/.."

CYAN='\033[0;36m'
GREEN='\033[0;32m'
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

clear
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  JBUG Korea Demo: Harness Engineering for AI Agents       ║${NC}"
echo -e "${GREEN}║  AI 에이전트를 위한 하네스 엔지니어링 데모                ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Part 1 - Project Structure & Harness Overview            ║${NC}"
echo -e "${GREEN}║  파트 1 - 프로젝트 구조 및 하네스 개요                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 3

# --- 1. Project Structure ---
section "1. Project Structure / 프로젝트 구조"
echo -e "${YELLOW}$ tree -L 2 -I 'target|.git|.mvn' --dirsfirst${NC}"
sleep 1
tree -L 2 -I 'target|.git|.mvn|docs' --dirsfirst
sleep 4

# --- 2. CLAUDE.md Rules ---
section "2. CLAUDE.md - AI Agent Rules (Feedforward Control) / AI 에이전트 규칙 (피드포워드 제어)"
echo -e "${YELLOW}$ head -25 CLAUDE.md${NC}"
sleep 1
head -25 CLAUDE.md
sleep 4

# --- 3. Harness Checks ---
section "3. Pre-Commit Harness - 7 Automated Checks (Feedback Control) / 사전 커밋 하네스 - 7개 자동 검증 (피드백 제어)"
echo -e "${YELLOW}$ grep -n 'CHECK [1-7]' .claude/hooks/pre-commit-harness.sh${NC}"
sleep 1
grep -n "CHECK [1-7]" .claude/hooks/pre-commit-harness.sh
sleep 4

# --- 4. Current Source Code ---
section "4. Current Source Code (starting point) / 현재 소스 코드 (시작점)"
echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/GreetingResource.java${NC}"
sleep 1
cat src/main/java/dev/tedwon/GreetingResource.java
sleep 3

echo ""
echo -e "${YELLOW}$ cat src/test/java/dev/tedwon/GreetingResourceTest.java${NC}"
sleep 1
cat src/test/java/dev/tedwon/GreetingResourceTest.java
sleep 3

# --- 5. Self-Correction Loop ---
section "5. Self-Correction Loop / 자기 교정 루프"
echo ""
echo "  Agent = Model + Harness"
echo "  에이전트 = 모델 + 하네스"
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  1. Agent writes code (CLAUDE.md rules)                  │"
echo "  │     에이전트가 코드 작성 (CLAUDE.md 규칙 따름)           │"
echo "  │  2. Agent tries to commit / 커밋 시도                    │"
echo "  │  3. Harness runs 7 checks / 하네스가 7개 검증 실행       │"
echo "  │  4. If ANY fails → commit blocked                        │"
echo "  │     하나라도 실패 → 커밋 차단                            │"
echo "  │  5. Agent reads error, fixes violations                  │"
echo "  │     에이전트가 오류를 읽고 위반 수정                     │"
echo "  │  6. Agent retries commit / 커밋 재시도                   │"
echo "  │  7. Loop until all 7 pass / 7개 모두 통과할 때까지 반복  │"
echo "  │  8. Commit succeeds ✓ / 커밋 성공 ✓                     │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
echo "  Feedforward (guides / 가이드): CLAUDE.md, AGENTS.md"
echo "  Feedback (sensors / 센서):     pre-commit hooks, Maven checks"
sleep 5

echo ""
echo -e "${GREEN}  ✓ Overview complete. Next: Self-Correction Demo${NC}"
echo -e "${GREEN}  ✓ 개요 완료. 다음: 자기 교정 데모${NC}"
echo ""
sleep 2
