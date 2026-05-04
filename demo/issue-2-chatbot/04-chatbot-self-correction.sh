#!/usr/bin/env bash
# =============================================================================
# Recording 4: AI Chatbot — Harness Self-Correction Demo
# =============================================================================
export TERM=${TERM:-xterm-256color}
cd "$(dirname "$0")/../.."

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
RESOURCE="src/main/java/dev/tedwon/ChatBotResource.java"
RESOURCE_BAK="/tmp/good-ChatBotResource.java.bak"
TEST_FILE="src/test/java/dev/tedwon/ChatBotResourceTest.java"
TEST_FILE_BAK="/tmp/good-ChatBotResourceTest.java.bak"

cp "$RESOURCE" "$RESOURCE_BAK"
cp "$TEST_FILE" "$TEST_FILE_BAK"

cleanup() {
    cp "$RESOURCE_BAK" "$RESOURCE" 2>/dev/null || true
    cp "$TEST_FILE_BAK" "$TEST_FILE" 2>/dev/null || true
    rm -f "$RESOURCE_BAK" "$TEST_FILE_BAK" 2>/dev/null || true
}
trap cleanup EXIT

clear
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  JBUG Korea Demo: AI Chatbot Harness Self-Correction      ║${NC}"
echo -e "${GREEN}║  AI 챗봇 하네스 자기 교정 데모                            ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Agent writes bad code → Harness catches → Agent fixes    ║${NC}"
echo -e "${GREEN}║  에이전트가 잘못된 코드 작성 → 하네스가 잡음 → 수정      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 3

# --- Step 1: Plant bad code ---
section "Step 1: Agent writes ChatBotResource with violations / 위반 코드 작성"
echo -e "  The agent created a chat endpoint but made mistakes:"
echo -e "  에이전트가 챗봇 엔드포인트를 만들었지만 실수가 있습니다:"
echo ""
sleep 1

# Create bad version with System.out.println
cat > "$RESOURCE" << 'BADCODE'
package dev.tedwon;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/api/chat")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ChatBotResource {

    @Inject QuoteAiService quoteAiService;

    @POST
    public ChatResponse chat(ChatRequest request) {
        System.out.println("Processing chat request: " + request.message());
        String aiResponse = quoteAiService.chat(request.message());
        System.out.println("AI response: " + aiResponse);
        return new ChatResponse(aiResponse);
    }
}
BADCODE

# Remove test file to trigger CONV-02
rm -f "$TEST_FILE"

echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/ChatBotResource.java${NC}"
sleep 1
cat "$RESOURCE"
sleep 2

echo ""
echo -e "  ${RED}Line 19: System.out.println  (QUAL-01: should use Logger)${NC}"
echo -e "  ${RED}Line 21: System.out.println  (QUAL-01: Logger를 사용해야 함)${NC}"
echo -e "  ${RED}Missing: ChatBotResourceTest.java (CONV-02: 테스트 파일 누락)${NC}"
sleep 3

# --- Step 2: Attempt commit ---
section "Step 2: Agent attempts commit / 에이전트가 커밋 시도"
echo -e "${YELLOW}$ bash demo/harness-check.sh \"added chatbot\"${NC}"
sleep 2

bash demo/harness-check.sh "added chatbot" || true
sleep 4

# --- Step 3: Fix violations ---
section "Step 3: Agent reads errors, fixes ALL violations / 모든 위반 수정"
sleep 1

echo -e "  ${GREEN}Fix 1: Replace System.out.println → Logger / Logger로 교체${NC}"
sleep 1
echo -e "  ${GREEN}Fix 2: Create ChatBotResourceTest.java / 테스트 파일 생성${NC}"
sleep 1
echo -e "  ${GREEN}Fix 3: Use conventional commit message / 커밋 메시지 형식 수정${NC}"
sleep 2

# Restore good files
cp "$RESOURCE_BAK" "$RESOURCE"
cp "$TEST_FILE_BAK" "$TEST_FILE"

echo ""
echo -e "${YELLOW}$ # Agent fixes applied...${NC}"
sleep 1

echo -e "${YELLOW}$ grep -n 'LOG\.' src/main/java/dev/tedwon/ChatBotResource.java${NC}"
grep -n 'LOG\.' "$RESOURCE" || true
sleep 2

echo ""
echo -e "${YELLOW}$ ls src/test/java/dev/tedwon/ChatBot*${NC}"
ls src/test/java/dev/tedwon/ChatBot* 2>/dev/null || true
sleep 2

# --- Step 4: Retry commit ---
section "Step 4: Agent retries with fixes / 수정 후 재시도"
echo -e "${YELLOW}$ bash demo/harness-check.sh \"feat(chat): add AI chatbot endpoint with LangChain4j Ollama\"${NC}"
sleep 2

bash demo/harness-check.sh "feat(chat): add AI chatbot endpoint with LangChain4j Ollama"
sleep 3

echo ""
echo -e "${GREEN}  ✓ Self-correction complete! All 7/7 checks passed.${NC}"
echo -e "${GREEN}  ✓ 자기 교정 완료! 7개 체크 모두 통과.${NC}"
echo ""
echo -e "${GREEN}  ✓ No human intervention — harness guided the agent autonomously.${NC}"
echo -e "${GREEN}  ✓ 사람의 개입 없이 하네스가 에이전트를 자동으로 가이드.${NC}"
echo ""
sleep 3
