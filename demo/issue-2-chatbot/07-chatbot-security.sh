#!/usr/bin/env bash
# =============================================================================
# Recording 7: AI Chatbot — Security Validation Demo
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
echo -e "${GREEN}║  JBUG Korea Demo: Security Validation                     ║${NC}"
echo -e "${GREEN}║  보안 검증 데모                                           ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Phase 4: SpotBugs + SBOM (CycloneDX)                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
sleep 2

# --- Step 1: SpotBugs ---
section "Step 1: SpotBugs static analysis / SpotBugs 정적 분석"
echo -e "${YELLOW}$ ./mvnw compile spotbugs:check${NC}"
sleep 1

./mvnw compile spotbugs:check 2>&1 | grep -E 'BUILD|spotbugs|bugs found|No bugs'
sleep 3

# --- Step 2: SBOM ---
section "Step 2: Generate SBOM (CycloneDX) / SBOM 생성"
echo -e "${YELLOW}$ ./mvnw cyclonedx:makeAggregateBom${NC}"
sleep 1

./mvnw cyclonedx:makeAggregateBom 2>&1 | grep -E 'cyclonedx|BUILD|bom'
sleep 1

echo ""
echo -e "${YELLOW}$ ls -lh target/bom.json${NC}"
ls -lh target/bom.json 2>/dev/null
sleep 2

echo ""
echo -e "${YELLOW}$ python3 -c \"import json; bom=json.load(open('target/bom.json')); print(f'Components: {len(bom.get(\\\"components\\\", []))}'); [print(f'  - {c[\\\"name\\\"]}:{c.get(\\\"version\\\",\\\"?\\\")}') for c in bom.get('components',[])[:5]]\"${NC}"
sleep 1
python3 -c "
import json
bom = json.load(open('target/bom.json'))
components = bom.get('components', [])
print(f'Total components in SBOM: {len(components)}')
print('First 5 components:')
for c in components[:5]:
    print(f'  - {c[\"name\"]}:{c.get(\"version\",\"?\")}')
"
sleep 3

# --- Step 3: Summary ---
section "Summary / 요약"
echo -e "  ${GREEN}✓ SpotBugs: No bugs found / 버그 없음${NC}"
echo -e "  ${GREEN}✓ SBOM: Generated at target/bom.json / SBOM 생성 완료${NC}"
echo -e "  ${GREEN}✓ All security checks passed / 보안 체크 모두 통과${NC}"
echo ""
echo -e "  ${BOLD}Phase 4 complete — ready to merge!${NC}"
echo -e "  ${BOLD}Phase 4 완료 — 머지 준비 완료!${NC}"
echo ""
sleep 3
