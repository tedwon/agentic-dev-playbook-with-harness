#!/usr/bin/env bash
# =============================================================================
# Agentic Workflow Demo — Recording 1: Design Phase (Phase 1-2)
# 에이전틱 워크플로우 데모 — 녹화 1: 설계 단계 (1-2단계)
# =============================================================================
export TERM=${TERM:-xterm-256color}
cd "$(dirname "$0")/../.."

CYAN='\033[0;36m'
GREEN='\033[0;32m'
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

clear
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Agentic Development Workflow + Harness Engineering Demo          ║${NC}"
echo -e "${GREEN}║  에이전틱 개발 워크플로우 + 하네스 엔지니어링 데모               ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║  Part 1: Design Phase (Brainstorm → Plan)                         ║${NC}"
echo -e "${GREEN}║  파트 1: 설계 단계 (브레인스토밍 → 계획 작성)                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
sleep 4

# --- 1. Playbook Overview ---
section "1. Agentic Development Playbook — 4-Phase Workflow / 4단계 워크플로우"

echo -e "  ${WHITE}The playbook defines a human-in-the-loop workflow:${NC}"
echo -e "  ${WHITE}플레이북은 사람이 참여하는(human-in-the-loop) 워크플로우를 정의합니다:${NC}"
echo ""
echo -e "  ┌────────────────────────────────────────────────────────────────┐"
echo -e "  │                                                                │"
echo -e "  │   ${BOLD}Phase 1: Design${NC}        Brainstorm → Spec → Plan            │"
echo -e "  │   ${DIM}설계 단계${NC}              브레인스토밍 → 명세 → 계획            │"
echo -e "  │                          ↓                                     │"
echo -e "  │   ${BOLD}Phase 2: Execute${NC}       Implement plan step-by-step         │"
echo -e "  │   ${DIM}실행 단계${NC}              계획을 단계별로 구현                   │"
echo -e "  │                          ↓                                     │"
echo -e "  │   ${BOLD}Phase 3: Review${NC}        Code review + CI feedback           │"
echo -e "  │   ${DIM}리뷰 단계${NC}              코드 리뷰 + CI 피드백                 │"
echo -e "  │                          ↓                                     │"
echo -e "  │   ${BOLD}Phase 4: Validate${NC}      Tests + security + deploy           │"
echo -e "  │   ${DIM}검증 단계${NC}              테스트 + 보안 + 배포                   │"
echo -e "  │                                                                │"
echo -e "  │   ${YELLOW}Human reviews and approves at each phase transition${NC}        │"
echo -e "  │   ${YELLOW}사람이 각 단계 전환 시 검토하고 승인합니다${NC}                  │"
echo -e "  │                                                                │"
echo -e "  └────────────────────────────────────────────────────────────────┘"
sleep 6

# --- 2. Design Principles ---
section "2. Key Design Principles / 핵심 설계 원칙"

echo -e "  ${WHITE}1. Start simple, add complexity only when needed${NC}"
echo -e "  ${DIM}   단순하게 시작하고, 필요할 때만 복잡성을 추가${NC}"
echo ""
echo -e "  ${WHITE}2. Workflows vs. Agents — know the difference${NC}"
echo -e "  ${DIM}   워크플로우 vs. 에이전트 — 차이를 이해${NC}"
echo ""
echo -e "  ${WHITE}3. Orchestration over prompt engineering${NC}"
echo -e "  ${DIM}   프롬프트 엔지니어링보다 오케스트레이션이 중요${NC}"
echo ""
echo -e "  ${WHITE}4. Minimal freedom principle${NC}"
echo -e "  ${DIM}   최소 자유 원칙 — 결과를 달성하는 최소한의 자율성 부여${NC}"
echo ""
echo -e "  ${WHITE}5. Reflection — agent reviews its own work${NC}"
echo -e "  ${DIM}   자기 성찰 — 에이전트가 자신의 결과물을 스스로 검토${NC}"
echo ""
echo -e "  ${WHITE}6. Developers must understand the code they approve${NC}"
echo -e "  ${DIM}   개발자는 승인하는 코드를 반드시 이해해야 한다${NC}"
sleep 6

# --- 3. Phase 1: Brainstorming → Spec ---
section "3. Phase 1: Brainstorming → Spec / 브레인스토밍 → 명세서"

echo -e "  ${DIM}In Claude Code, the developer starts with:${NC}"
echo -e "  ${DIM}Claude Code에서 개발자가 다음 명령으로 시작:${NC}"
echo ""
echo -e "  ${YELLOW}> /brainstorming${NC}"
echo -e "  ${YELLOW}> Add a Quote of the Day REST API with list, random, and ID lookup.${NC}"
echo ""
sleep 2

echo -e "  ${WHITE}The AI agent explores requirements through Q&A:${NC}"
echo -e "  ${WHITE}AI 에이전트가 Q&A를 통해 요구사항을 탐색합니다:${NC}"
echo ""
echo -e "  ${DIM}  Q: Should we use a database or in-memory storage?${NC}"
echo -e "  ${DIM}     데이터베이스를 사용할까요, 인메모리 저장소를 사용할까요?${NC}"
echo -e "  ${GREEN}  A: In-memory for now. Keep it simple.${NC}"
echo -e "  ${GREEN}     지금은 인메모리로. 단순하게 유지.${NC}"
echo ""
echo -e "  ${DIM}  Q: What data model? Record or POJO?${NC}"
echo -e "  ${DIM}     데이터 모델은? Record? POJO?${NC}"
echo -e "  ${GREEN}  A: Java 21 Record — immutable, concise.${NC}"
echo -e "  ${GREEN}     Java 21 Record — 불변, 간결.${NC}"
echo ""
echo -e "  ${DIM}  Q: Categories for the quotes?${NC}"
echo -e "  ${DIM}     명언 카테고리는?${NC}"
echo -e "  ${GREEN}  A: programming, inspiration — configurable default.${NC}"
echo -e "  ${GREEN}     programming, inspiration — 기본값은 설정 가능.${NC}"
sleep 5

echo ""
echo -e "  ${WHITE}→ AI generates the spec:${NC}"
echo -e "  ${WHITE}→ AI가 명세서를 생성합니다:${NC}"
echo ""
echo -e "  ${YELLOW}$ cat docs/superpowers/specs/2026-04-18-DEMO-001-quote-api.md${NC}"
sleep 1
head -30 docs/superpowers/specs/2026-04-18-DEMO-001-quote-api.md
sleep 4

echo ""
echo -e "  ${GREEN}✓ Human reviews and approves the spec${NC}"
echo -e "  ${GREEN}✓ 사람이 명세서를 검토하고 승인합니다${NC}"
sleep 3

# --- 4. Phase 1: Plan Writing ---
section "4. Phase 1 (cont): Spec → Plan / 명세서 → 구현 계획"

echo -e "  ${DIM}In Claude Code:${NC}"
echo ""
echo -e "  ${YELLOW}> /writing-plans${NC}"
echo -e "  ${YELLOW}> Create implementation plan from the approved spec.${NC}"
echo ""
sleep 2

echo -e "  ${WHITE}→ AI generates the implementation plan:${NC}"
echo -e "  ${WHITE}→ AI가 구현 계획을 생성합니다:${NC}"
echo ""
echo -e "  ${YELLOW}$ cat docs/superpowers/plans/2026-04-18-DEMO-001-quote-api.md${NC}"
sleep 1
cat docs/superpowers/plans/2026-04-18-DEMO-001-quote-api.md
sleep 5

echo ""
echo -e "  ${GREEN}✓ Human reviews task sequence and dependencies${NC}"
echo -e "  ${GREEN}✓ 사람이 작업 순서와 의존성을 검토합니다${NC}"
echo ""
echo -e "  ${GREEN}✓ Plan saved as versioned artifact (audit trail)${NC}"
echo -e "  ${GREEN}✓ 계획이 버전 관리 산출물로 저장됩니다 (감사 추적)${NC}"
sleep 3

# --- 5. Handoff ---
section "5. Design → Execution Handoff / 설계 → 실행 전달"

echo ""
echo -e "  ┌────────────────────────────────────────────────────────────────┐"
echo -e "  │                                                                │"
echo -e "  │  ${BOLD}Key insight / 핵심 포인트:${NC}                                   │"
echo -e "  │                                                                │"
echo -e "  │  Design and execution happen in ${BOLD}separate sessions${NC}.           │"
echo -e "  │  설계와 실행은 ${BOLD}별도의 세션${NC}에서 수행합니다.                     │"
echo -e "  │                                                                │"
echo -e "  │  The ${BOLD}plan document${NC} is the only handoff artifact.              │"
echo -e "  │  ${BOLD}계획 문서${NC}가 유일한 전달 산출물입니다.                         │"
echo -e "  │                                                                │"
echo -e "  │  A fresh agent can execute without the design context.         │"
echo -e "  │  새 에이전트가 설계 맥락 없이도 실행할 수 있습니다.            │"
echo -e "  │                                                                │"
echo -e "  │  ${YELLOW}Spec + Plan = Self-contained handoff${NC}                        │"
echo -e "  │  ${YELLOW}명세 + 계획 = 자기완결적 전달${NC}                               │"
echo -e "  │                                                                │"
echo -e "  └────────────────────────────────────────────────────────────────┘"
sleep 5

echo ""
echo -e "${GREEN}  ✓ Design phase complete. Next: Execution + Harness${NC}"
echo -e "${GREEN}  ✓ 설계 단계 완료. 다음: 실행 + 하네스${NC}"
echo ""
sleep 3
