#!/usr/bin/env bash
# =============================================================================
# Recording 6: AI Chatbot — Live API Demo (Quarkus must already be running)
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
echo -e "${GREEN}║  JBUG Korea Demo: AI Chatbot Live API                     ║${NC}"
echo -e "${GREEN}║  AI 챗봇 실시간 API 데모                                  ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Powered by: Quarkus + LangChain4j + Ollama (qwen3:1.7b) ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 2

# --- Step 1: Health check ---
section "Step 1: Quarkus health check / 헬스체크"
echo -e "${YELLOW}$ curl -s http://localhost:8080/q/health | python3 -m json.tool${NC}"
sleep 1
curl -s http://localhost:8080/q/health | python3 -m json.tool
sleep 2

# --- Step 2: Existing API ---
section "Step 2: Existing Quote API / 기존 명언 API"
echo -e "${YELLOW}$ curl -s http://localhost:8080/api/quotes/random | python3 -m json.tool${NC}"
sleep 1
curl -s http://localhost:8080/api/quotes/random | python3 -m json.tool
sleep 2

# --- Step 3: AI Chatbot ---
section "Step 3: AI Chatbot — Quote Explanation / 명언 해설"
echo -e "${YELLOW}$ curl -s -X POST http://localhost:8080/api/chat \\${NC}"
echo -e "${YELLOW}    -H 'Content-Type: application/json' \\${NC}"
echo -e "${YELLOW}    -d '{\"message\": \"Explain the Linus Torvalds quote about code\"}'${NC}"
sleep 1
echo ""
RESP=$(curl -s -X POST http://localhost:8080/api/chat \
    -H 'Content-Type: application/json' \
    -d '{"message": "Explain the Linus Torvalds quote about code"}')
echo "$RESP" | python3 -m json.tool --no-ensure-ascii
sleep 3

section "Step 4: AI Chatbot — Korean / 한국어 질문"
echo -e "${YELLOW}$ curl -s -X POST http://localhost:8080/api/chat \\${NC}"
echo -e "${YELLOW}    -d '{\"message\": \"Steve Jobs 명언의 의미를 설명해줘\"}'${NC}"
sleep 1
echo ""
RESP=$(curl -s -X POST http://localhost:8080/api/chat \
    -H 'Content-Type: application/json' \
    -d '{"message": "Steve Jobs 명언의 의미를 설명해줘"}')
echo "$RESP" | python3 -m json.tool --no-ensure-ascii
sleep 3

section "Step 5: AI Chatbot — Recommendation / 명언 추천"
echo -e "${YELLOW}$ curl -s -X POST http://localhost:8080/api/chat \\${NC}"
echo -e "${YELLOW}    -d '{\"message\": \"I feel stuck. Recommend a quote.\"}'${NC}"
sleep 1
echo ""
RESP=$(curl -s -X POST http://localhost:8080/api/chat \
    -H 'Content-Type: application/json' \
    -d '{"message": "I feel stuck on a hard problem. Recommend a motivational quote."}')
echo "$RESP" | python3 -m json.tool --no-ensure-ascii
sleep 3

echo ""
echo -e "${GREEN}  ✓ AI Chatbot responds with context-aware answers!${NC}"
echo -e "${GREEN}  ✓ AI 챗봇이 명언 컨텍스트를 활용하여 답변합니다!${NC}"
echo ""
echo -e "${GREEN}  Tech stack: Quarkus 3.34.3 + LangChain4j + Ollama (qwen3:1.7b)${NC}"
echo ""
sleep 3
