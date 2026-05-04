#!/usr/bin/env bash
# =============================================================================
# Recording 6: AI Chatbot — Live API Demo (requires Ollama running)
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

QUARKUS_PID=""
cleanup() {
    if [ -n "$QUARKUS_PID" ]; then
        kill "$QUARKUS_PID" 2>/dev/null || true
        wait "$QUARKUS_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

clear
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  JBUG Korea Demo: AI Chatbot Live API                     ║${NC}"
echo -e "${GREEN}║  AI 챗봇 실시간 API 데모                                  ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Powered by: Quarkus + LangChain4j + Ollama (qwen3:1.7b) ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 2

# --- Step 1: Verify Ollama ---
section "Step 1: Verify Ollama is running / Ollama 실행 확인"
echo -e "${YELLOW}$ curl -s http://localhost:11434/api/tags | python3 -m json.tool | head -8${NC}"
sleep 1
curl -s http://localhost:11434/api/tags | python3 -m json.tool | head -8
sleep 2

# --- Step 2: Start Quarkus ---
section "Step 2: Start Quarkus / Quarkus 시작"
echo -e "${YELLOW}$ ./mvnw quarkus:dev (starting in background...)${NC}"
sleep 1

./mvnw quarkus:dev -Dquarkus.test.continuous-testing=disabled > /tmp/quarkus-demo.log 2>&1 &
QUARKUS_PID=$!

echo -e "  Waiting for Quarkus to start... / 시작 대기 중..."
for i in $(seq 1 30); do
    if curl -s http://localhost:8080/q/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Quarkus started in ${i}s${NC}"
        break
    fi
    sleep 1
done
sleep 1

echo ""
echo -e "${YELLOW}$ curl -s http://localhost:8080/q/health | python3 -m json.tool | head -5${NC}"
curl -s http://localhost:8080/q/health | python3 -m json.tool | head -5
sleep 2

# --- Step 3: Existing API still works ---
section "Step 3: Existing Quote API still works / 기존 명언 API 정상 동작"
echo -e "${YELLOW}$ curl -s http://localhost:8080/api/quotes/random | python3 -m json.tool${NC}"
sleep 1
curl -s http://localhost:8080/api/quotes/random | python3 -m json.tool
sleep 2

# --- Step 4: AI Chatbot API ---
section "Step 4: AI Chatbot in action / AI 챗봇 실행"

echo -e "${BOLD}  Q1: Explain a quote / 명언 해설${NC}"
echo -e "${YELLOW}$ curl -s -X POST http://localhost:8080/api/chat \\${NC}"
echo -e "${YELLOW}    -H 'Content-Type: application/json' \\${NC}"
echo -e "${YELLOW}    -d '{\"message\": \"Explain the Linus Torvalds quote about code\"}' | python3 -m json.tool${NC}"
sleep 1
curl -s -X POST http://localhost:8080/api/chat \
    -H 'Content-Type: application/json' \
    -d '{"message": "Explain the Linus Torvalds quote about code"}' | python3 -m json.tool
sleep 4

echo ""
echo -e "${BOLD}  Q2: Korean language / 한국어 질문${NC}"
echo -e "${YELLOW}$ curl -s -X POST http://localhost:8080/api/chat \\${NC}"
echo -e "${YELLOW}    -d '{\"message\": \"Steve Jobs 명언의 의미를 설명해줘\"}' | python3 -m json.tool${NC}"
sleep 1
curl -s -X POST http://localhost:8080/api/chat \
    -H 'Content-Type: application/json' \
    -d '{"message": "Steve Jobs 명언의 의미를 설명해줘"}' | python3 -m json.tool
sleep 4

echo ""
echo -e "${BOLD}  Q3: Quote recommendation / 명언 추천${NC}"
echo -e "${YELLOW}$ curl -s -X POST http://localhost:8080/api/chat \\${NC}"
echo -e "${YELLOW}    -d '{\"message\": \"I feel stuck. Recommend a motivational quote.\"}' | python3 -m json.tool${NC}"
sleep 1
curl -s -X POST http://localhost:8080/api/chat \
    -H 'Content-Type: application/json' \
    -d '{"message": "I feel stuck on a hard problem. Recommend a motivational quote."}' | python3 -m json.tool
sleep 4

echo ""
echo -e "${GREEN}  ✓ AI Chatbot responding with context-aware answers!${NC}"
echo -e "${GREEN}  ✓ AI 챗봇이 명언 컨텍스트를 활용하여 답변합니다!${NC}"
echo ""
sleep 3
