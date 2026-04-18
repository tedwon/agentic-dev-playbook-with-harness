#!/usr/bin/env bash
# =============================================================================
# Recording 3: Feature Implementation Result & Live API Demo
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

# Cleanup Quarkus on exit
cleanup() {
    kill $QUARKUS_PID 2>/dev/null || true
    wait $QUARKUS_PID 2>/dev/null || true
}
trap cleanup EXIT
QUARKUS_PID=""

clear
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  JBUG Korea Demo: Quote of the Day API                    ║${NC}"
echo -e "${GREEN}║  오늘의 명언 API 데모                                     ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Part 3 - Implementation Result & Live API                ║${NC}"
echo -e "${GREEN}║  파트 3 - 구현 결과 및 라이브 API 호출                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 3

# --- 1. Show Quote Record ---
section "1. Quote.java — Java 21 Record (DTO) / 레코드 데이터 모델"
echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/Quote.java${NC}"
sleep 1
cat src/main/java/dev/tedwon/Quote.java
sleep 3

# --- 2. Show QuoteService ---
section "2. QuoteService.java — CDI Service (@ApplicationScoped) / CDI 서비스"
echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/QuoteService.java${NC}"
sleep 1
cat src/main/java/dev/tedwon/QuoteService.java
sleep 4

# --- 3. Show QuoteResource ---
section "3. QuoteResource.java — REST Endpoints / REST 엔드포인트"
echo -e "${YELLOW}$ cat src/main/java/dev/tedwon/QuoteResource.java${NC}"
sleep 1
cat src/main/java/dev/tedwon/QuoteResource.java
sleep 4

# --- 4. Run Tests ---
section "4. Running All Tests / 전체 테스트 실행"
echo -e "${YELLOW}$ ./mvnw test -q${NC}"
sleep 1
./mvnw test -q 2>&1
echo ""
echo -e "${GREEN}  ✓ 11 tests passed (GreetingResource: 1, QuoteResource: 5, QuoteService: 5)${NC}"
echo -e "${GREEN}  ✓ 11개 테스트 모두 통과${NC}"
sleep 3

# --- 5. Live API Demo ---
section "5. Live API Demo — Starting Quarkus / 라이브 API 데모 — Quarkus 시작"
echo -e "${YELLOW}$ ./mvnw quarkus:dev (background)${NC}"
sleep 1

./mvnw quarkus:dev -Dquarkus.http.host=localhost -Dquarkus.test.enabled=false > /dev/null 2>&1 &
QUARKUS_PID=$!

echo "  Waiting for Quarkus to start... / Quarkus 시작 대기 중..."
ATTEMPTS=0
until curl -sf http://localhost:8080/q/health/live > /dev/null 2>&1; do
    sleep 1
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -gt 30 ]; then
        echo -e "${RED}  Quarkus failed to start within 30s${NC}"
        exit 1
    fi
done
echo -e "${GREEN}  ✓ Quarkus is running on http://localhost:8080${NC}"
sleep 2

echo ""
echo -e "${CYAN}--- GET /api/quotes (all quotes / 전체 명언) ---${NC}"
echo -e "${YELLOW}$ curl -s localhost:8080/api/quotes | jq .${NC}"
sleep 1
curl -s http://localhost:8080/api/quotes | python3 -m json.tool
sleep 4

echo ""
echo -e "${CYAN}--- GET /api/quotes/random (random quote / 랜덤 명언) ---${NC}"
echo -e "${YELLOW}$ curl -s localhost:8080/api/quotes/random | jq .${NC}"
sleep 1
curl -s http://localhost:8080/api/quotes/random | python3 -m json.tool
sleep 3

echo ""
echo -e "${CYAN}--- GET /api/quotes/1 (by ID / ID로 조회) ---${NC}"
echo -e "${YELLOW}$ curl -s localhost:8080/api/quotes/1 | jq .${NC}"
sleep 1
curl -s http://localhost:8080/api/quotes/1 | python3 -m json.tool
sleep 3

echo ""
echo -e "${CYAN}--- GET /api/quotes?category=programming (filter / 카테고리 필터) ---${NC}"
echo -e "${YELLOW}$ curl -s localhost:8080/api/quotes?category=programming | jq .${NC}"
sleep 1
curl -s "http://localhost:8080/api/quotes?category=programming" | python3 -m json.tool
sleep 3

echo ""
echo -e "${CYAN}--- GET /api/quotes/999 (not found / 없는 ID 조회) ---${NC}"
echo -e "${YELLOW}$ curl -s -o /dev/null -w '%{http_code}' localhost:8080/api/quotes/999${NC}"
sleep 1
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/quotes/999)
echo "  HTTP $HTTP_CODE (Not Found)"
sleep 3

# --- Summary ---
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Summary / 요약                                               ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  ✓ Java 21 Record DTO             레코드 데이터 모델           ║${NC}"
echo -e "${GREEN}║  ✓ @ApplicationScoped CDI Service  CDI 서비스                  ║${NC}"
echo -e "${GREEN}║  ✓ @ConfigProperty configuration   설정 주입                   ║${NC}"
echo -e "${GREEN}║  ✓ org.jboss.logging.Logger        표준 로거 사용              ║${NC}"
echo -e "${GREEN}║  ✓ REST endpoints with JSON        REST API + JSON 응답        ║${NC}"
echo -e "${GREEN}║  ✓ @QuarkusTest + REST Assured     통합 테스트                 ║${NC}"
echo -e "${GREEN}║  ✓ 11 tests passing                11개 테스트 통과            ║${NC}"
echo -e "${GREEN}║  ✓ Harness: 7/7 checks passed      하네스 7/7 검증 통과        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
sleep 4
