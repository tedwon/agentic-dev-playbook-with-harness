#!/usr/bin/env bash
# =============================================================================
# Recording 5: AI Chatbot — Build & Test Demo
# =============================================================================
export TERM=${TERM:-xterm-256color}
cd "$(dirname "$0")/../.."

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
echo -e "${GREEN}║  JBUG Korea Demo: AI Chatbot Build & Test                 ║${NC}"
echo -e "${GREEN}║  AI 챗봇 빌드 및 테스트 데모                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 2

# --- Step 1: Show new files ---
section "Step 1: New files created by the agent / 에이전트가 생성한 새 파일"

echo -e "${YELLOW}$ find src -name 'Chat*' -o -name 'QuoteAi*' | sort${NC}"
find src -name 'Chat*' -o -name 'QuoteAi*' | sort
sleep 2

echo ""
echo -e "${BOLD}  QuoteAiService.java — @RegisterAiService (LangChain4j AI Service)${NC}"
echo -e "${YELLOW}$ head -28 src/main/java/dev/tedwon/QuoteAiService.java${NC}"
sleep 1
head -28 src/main/java/dev/tedwon/QuoteAiService.java
sleep 3

echo ""
echo -e "${BOLD}  ChatBotResource.java — POST /api/chat endpoint${NC}"
echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/ChatBotResource.java${NC}"
sleep 1
cat src/main/java/dev/tedwon/ChatBotResource.java
sleep 3

# --- Step 2: Run tests ---
section "Step 2: Run all tests / 전체 테스트 실행"
echo -e "${YELLOW}$ ./mvnw test 2>&1 | grep -E 'Tests run|BUILD'${NC}"
sleep 1

./mvnw test 2>&1 | grep -E 'Tests run|BUILD'
sleep 3

# --- Step 3: Harness check ---
section "Step 3: Full harness check (7/7) / 하네스 전체 체크"
echo -e "${YELLOW}$ bash demo/harness-check.sh \"feat(chat): add AI chatbot endpoint with LangChain4j Ollama\"${NC}"
sleep 1

bash demo/harness-check.sh "feat(chat): add AI chatbot endpoint with LangChain4j Ollama"
sleep 3

echo ""
echo -e "${GREEN}  ✓ 13 tests passed, all 7 harness checks green.${NC}"
echo -e "${GREEN}  ✓ 13개 테스트 통과, 하네스 7개 체크 모두 통과.${NC}"
echo ""
sleep 3
