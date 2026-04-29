# Demo History: Issue #2 — Quote AI Chatbot

**Date:** 2026-04-29
**Event:** JBUG Korea Meetup
**Speaker:** Ted Won
**Agent:** [Claude Code](https://claude.com/claude-code) (Opus 4.6, 1M context)
**Playbook:** [Agentic Development Playbook](../agentic-development-playbook.md)
**Walkthrough:** [Issue #2 따라하기 가이드](../walkthrough-issue-2-quote-ai-chatbot.md)
**Repository:** [tedwon/agentic-dev-playbook-with-harness](https://github.com/tedwon/agentic-dev-playbook-with-harness)
**PR:** [#3](https://github.com/tedwon/agentic-dev-playbook-with-harness/pull/3)
**Issue:** [#2](https://github.com/tedwon/agentic-dev-playbook-with-harness/issues/2)
**asciinema profile:** [asciinema.org/~tedwon](https://asciinema.org/~tedwon/recordings)

---

## Demo Recordings (asciinema.org)

| Recording | URL | Description |
|-----------|-----|-------------|
| Self-Correction | [asciinema.org/a/sTBXXYwopuDvrs8L](https://asciinema.org/a/sTBXXYwopuDvrs8L) | 하네스가 위반 코드를 잡고 → 에이전트 수정 → 7/7 통과 |
| Build & Test | [asciinema.org/a/6J2ezRTcZ07BG51J](https://asciinema.org/a/6J2ezRTcZ07BG51J) | 13개 테스트 통과 + 하네스 7/7 체크 |
| Live API | [asciinema.org/a/ePPwlvwvvtdyR9O9](https://asciinema.org/a/ePPwlvwvvtdyR9O9) | Ollama(qwen3:1.7b) 실시간 한국어 AI 응답 |
| Security | [asciinema.org/a/i8CY0RCBRMKeEREx](https://asciinema.org/a/i8CY0RCBRMKeEREx) | SpotBugs 정적 분석 + CycloneDX SBOM 생성 |

---

## Phase 1: Design

### Step 1 — Feature branch 생성

```bash
git checkout -b feat/issue-2-quote-ai-chatbot
```

### Step 2 — 브레인스토밍 & 스펙 생성

Claude Code에서 `/brainstorming` 스킬을 사용하여 요구사항 탐색.
Issue #2의 요구사항, 기존 코드 구조, 기술 스택을 입력으로 제공.

**핵심 설계 결정:**

| 결정 | 선택 | 근거 |
|------|------|------|
| AI 프레임워크 | [Quarkus LangChain4j](https://docs.quarkiverse.io/quarkus-langchain4j/dev/index.html) Ollama | Quarkus CDI 네이티브 통합, @RegisterAiService 패턴 |
| LLM 모델 | [qwen3:1.7b](https://ollama.com/library/qwen3:1.7b) ([Ollama](https://ollama.com/)) | 로컬 실행, 외부 API 불필요, 다국어 지원 |
| 컨텍스트 주입 | @SystemMessage에 8개 명언 직접 포함 | 8개뿐이므로 RAG/벡터스토어 불필요 |
| 요청/응답 모델 | Java 21 Record (ChatRequest, ChatResponse) | 기존 Quote.java 패턴과 일관성 |
| 테스트 전략 | @InjectMock QuoteAiService | CI에서 Ollama 없이 결정적 테스트 가능 |
| 엔드포인트 | POST /api/chat | 기존 GET /api/quotes와 분리 |

**산출물:**
- [docs/superpowers/specs/2026-04-29-issue-2-quote-ai-chatbot.md](../superpowers/specs/2026-04-29-issue-2-quote-ai-chatbot.md)
- [docs/superpowers/plans/2026-04-29-issue-2-quote-ai-chatbot-plan.md](../superpowers/plans/2026-04-29-issue-2-quote-ai-chatbot-plan.md)

### Step 3 — 설계 산출물 커밋

```bash
git add docs/superpowers/
git commit -m "docs(design): add spec and plan for issue-2 quote AI chatbot"
# HARNESS: ALL 7/7 CHECKS PASSED
```

---

## Phase 2: Execution

### Task 1: pom.xml — LangChain4j 의존성 추가

**파일:** `pom.xml`

```xml
<quarkus-langchain4j.version>1.9.1</quarkus-langchain4j.version>

<dependency>
    <groupId>io.quarkiverse.langchain4j</groupId>
    <artifactId>quarkus-langchain4j-ollama</artifactId>
    <version>${quarkus-langchain4j.version}</version>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-junit-mockito</artifactId>
    <scope>test</scope>
</dependency>
```

**검증:** `./mvnw compile` → BUILD SUCCESS (1:20 min, 의존성 최초 다운로드)

**이슈 해결:**
- `quarkus-junit5-mockito` → `quarkus-junit-mockito`로 수정 (Quarkus 3.34.x에서 artifact명 변경)
- `io.quarkus.test.junit.mockito.InjectMock` → `io.quarkus.test.InjectMock`으로 import 경로 변경

### Task 2: DTO 레코드 생성

**새 파일:**
- `src/main/java/dev/tedwon/ChatRequest.java` — `record ChatRequest(String message) {}`
- `src/main/java/dev/tedwon/ChatResponse.java` — `record ChatResponse(String response) {}`

**검증:** `./mvnw compile` → BUILD SUCCESS

### Task 3: QuoteAiService — AI 서비스 인터페이스

**새 파일:** `src/main/java/dev/tedwon/QuoteAiService.java`

```java
@RegisterAiService
public interface QuoteAiService {
    @SystemMessage("""
        You are a helpful quotes expert assistant.
        ...8개 명언 목록...
        IMPORTANT: You MUST answer in the SAME language as the user's question.
        If the user writes in Korean, you MUST respond entirely in Korean.
        """)
    String chat(@UserMessage String message);
}
```

**검증:** `./mvnw compile` → BUILD SUCCESS

**이슈 해결:**
- 한국어 질문에 영어로 답변하는 문제 → 시스템 메시지를 "Answer in the same language"에서 "IMPORTANT: You MUST answer in the SAME language... If the user writes in Korean, you MUST respond entirely in Korean."으로 강화

### Task 4: application.properties — Ollama 설정

```properties
quarkus.langchain4j.ollama.chat-model.model-name=qwen3:1.7b
quarkus.langchain4j.ollama.chat-model.temperature=0.7
quarkus.langchain4j.timeout=60s
```

### Task 5: ChatBotResource — REST 엔드포인트

**새 파일:** `src/main/java/dev/tedwon/ChatBotResource.java`

- `@Path("/api/chat")`, `@POST`
- `@Inject QuoteAiService` + `org.jboss.logging.Logger` (QUAL-01 준수)
- `ChatRequest` → `quoteAiService.chat()` → `ChatResponse`

### Task 6: 테스트 생성

**ChatBotResourceTest.java** — `@QuarkusTest` + `@InjectMock`:
- `testChatEndpoint()` — 200 응답, JSON 구조 검증
- `testChatEndpointWithEmptyMessage()` — 빈 메시지 처리

**ChatBotResourceIT.java** — `@QuarkusIntegrationTest` (독립 클래스, ChatBotResourceTest 미상속):
- IT에서는 `@InjectMock` 미지원 → 실제 Ollama 연동 테스트로 변경

**이슈 해결:**
- `ChatBotResourceIT extends ChatBotResourceTest` → `@InjectMock`이 `@QuarkusIntegrationTest`에서 NPE 발생
- 해결: IT를 독립 클래스로 변경, 실제 Ollama와 연동하여 테스트

### Task 7: 최종 검증

```
./mvnw spotless:apply → BUILD SUCCESS
./mvnw test           → Tests run: 13, Failures: 0, Errors: 0 — BUILD SUCCESS
./mvnw verify         → Tests run: 7 (IT), Failures: 0 — BUILD SUCCESS (AI response 508 chars)
```

**커밋:**
```bash
git commit -m "feat(chat): add AI chatbot endpoint with LangChain4j Ollama integration"
# HARNESS: ALL 7/7 CHECKS PASSED
```

---

## Phase 3: Code Review

### PR 생성

```bash
git push -u origin feat/issue-2-quote-ai-chatbot
gh pr create --title "feat(chat): add AI chatbot with LangChain4j Ollama" --body "..."
```

**PR:** [#3](https://github.com/tedwon/agentic-dev-playbook-with-harness/pull/3)

---

## Phase 4: Validation

### 보안 스캔

```bash
./mvnw compile spotbugs:check    # BUILD SUCCESS — 버그 없음
./mvnw cyclonedx:makeAggregateBom # SBOM 생성 (target/bom.json, 397K)
```

### 로컬 검증 (Ollama 연동)

```bash
./mvnw quarkus:dev  # Quarkus 시작 (11초)

# 헬스체크
curl -s http://localhost:8080/q/health  # {"status": "UP"}

# 기존 API 정상 동작
curl -s http://localhost:8080/api/quotes/random

# 챗봇 API — 영어 질문
curl -s -X POST http://localhost:8080/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "Explain the Linus Torvalds quote about code"}'
# → 영어로 명언 해설 응답

# 챗봇 API — 한국어 질문
curl -s -X POST http://localhost:8080/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "Steve Jobs 명언의 의미를 설명해줘"}'
# → 한국어로 명언 해설 응답

# 챗봇 API — 명언 추천
curl -s -X POST http://localhost:8080/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "I feel stuck on a hard problem. Recommend a quote."}'
# → Albert Einstein 명언 추천
```

---

## Demo Scripts & Recordings

### 데모 스크립트 (4개)

| 스크립트 | 설명 |
|---------|------|
| `demo/issue-2-chatbot/04-chatbot-self-correction.sh` | 의도적 위반 → 하네스 블록 → 수정 → 통과 |
| `demo/issue-2-chatbot/05-chatbot-build-test.sh` | 새 파일 구조 표시, 테스트 실행, 하네스 체크 |
| `demo/issue-2-chatbot/06-chatbot-live-api-curl.sh` | Quarkus + Ollama 실시간 API 테스트 |
| `demo/issue-2-chatbot/07-chatbot-security.sh` | SpotBugs + CycloneDX SBOM |

### 녹화 방법

```bash
# Quarkus 시작 (Live API 녹화 전 필수)
./mvnw quarkus:dev -Dquarkus.test.continuous-testing=disabled &

# 각 스크립트를 asciinema로 녹화
asciinema rec demo/issue-2-chatbot/recordings/04-chatbot-self-correction.cast \
  --title "Issue #2: AI Chatbot Harness Self-Correction" \
  --idle-time-limit 10 \
  --command "bash demo/issue-2-chatbot/04-chatbot-self-correction.sh"

# asciinema.org에 업로드
asciinema upload demo/issue-2-chatbot/recordings/04-chatbot-self-correction.cast
```

### 재생

```bash
asciinema play -s 2 demo/issue-2-chatbot/recordings/04-chatbot-self-correction.cast
asciinema play -s 2 demo/issue-2-chatbot/recordings/05-chatbot-build-test.cast
asciinema play -s 2 demo/issue-2-chatbot/recordings/06-chatbot-live-api.cast
asciinema play -s 2 demo/issue-2-chatbot/recordings/07-chatbot-security.cast
```

---

## Issues Encountered & Resolved

| Issue | Root Cause | Resolution |
|-------|-----------|------------|
| `InjectMock` import 오류 | Quarkus 3.34.x에서 패키지 변경 | `io.quarkus.test.InjectMock`으로 수정 |
| `quarkus-junit5-mockito` artifact 없음 | Quarkus 3.34.x에서 artifact명 변경 | `quarkus-junit-mockito`로 수정 |
| ChatBotResourceIT NPE | `@InjectMock`이 `@QuarkusIntegrationTest`에서 미지원 | IT를 독립 클래스로 변경, 실제 Ollama 연동 |
| 한국어 유니코드 이스케이프 (`의`) | `python3 -m json.tool` 기본 동작 | `--no-ensure-ascii` 옵션 추가 |
| 한국어 질문에 영어 답변 | LLM 시스템 메시지가 약함 | "MUST answer in the SAME language" 강화 |
| 데모 스크립트 `No such file or directory` | `cd "$(dirname "$0")/.."` 경로 오류 | `cd "$(dirname "$0")/../.."` 수정 (한 단계 더 상위) |
| `harness-check.sh` 미발견 | 위와 동일한 cd 경로 문제 | 동일하게 수정 |
| Rebase 충돌 (pom.xml, properties) | 리모트에 이전 push 존재 | 수동 충돌 해결 후 continue |

---

## File Changes Summary

### New Files (6)

| File | Purpose |
|------|---------|
| [`src/main/java/dev/tedwon/ChatRequest.java`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/src/main/java/dev/tedwon/ChatRequest.java) | 요청 DTO (Java 21 Record) |
| [`src/main/java/dev/tedwon/ChatResponse.java`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/src/main/java/dev/tedwon/ChatResponse.java) | 응답 DTO (Java 21 Record) |
| [`src/main/java/dev/tedwon/QuoteAiService.java`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/src/main/java/dev/tedwon/QuoteAiService.java) | @RegisterAiService AI 서비스 인터페이스 |
| [`src/main/java/dev/tedwon/ChatBotResource.java`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/src/main/java/dev/tedwon/ChatBotResource.java) | POST /api/chat REST 엔드포인트 |
| [`src/test/java/dev/tedwon/ChatBotResourceTest.java`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/src/test/java/dev/tedwon/ChatBotResourceTest.java) | @QuarkusTest + @InjectMock 단위 테스트 |
| [`src/test/java/dev/tedwon/ChatBotResourceIT.java`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/src/test/java/dev/tedwon/ChatBotResourceIT.java) | @QuarkusIntegrationTest 통합 테스트 |

### Modified Files (3)

| File | Changes |
|------|---------|
| [`pom.xml`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/pom.xml) | quarkus-langchain4j-ollama + quarkus-junit-mockito 의존성 추가 |
| [`src/main/resources/application.properties`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/src/main/resources/application.properties) | Ollama LLM 설정 추가 |
| [`demo/harness-check.sh`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/demo/harness-check.sh) | Maven -q 플래그 제거 |

### Design Artifacts (2)

| File | Content |
|------|---------|
| [`docs/superpowers/specs/2026-04-29-issue-2-quote-ai-chatbot.md`](../superpowers/specs/2026-04-29-issue-2-quote-ai-chatbot.md) | 기능 스펙 |
| [`docs/superpowers/plans/2026-04-29-issue-2-quote-ai-chatbot-plan.md`](../superpowers/plans/2026-04-29-issue-2-quote-ai-chatbot-plan.md) | 구현 플랜 (7 tasks) |

### Demo Artifacts (9)

| File | Content |
|------|---------|
| [`demo/issue-2-chatbot/04-chatbot-self-correction.sh`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/demo/issue-2-chatbot/04-chatbot-self-correction.sh) | Self-correction 데모 스크립트 |
| [`demo/issue-2-chatbot/05-chatbot-build-test.sh`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/demo/issue-2-chatbot/05-chatbot-build-test.sh) | Build & test 데모 스크립트 |
| [`demo/issue-2-chatbot/06-chatbot-live-api.sh`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/demo/issue-2-chatbot/06-chatbot-live-api.sh) | Live API 데모 (Quarkus 시작 포함) |
| [`demo/issue-2-chatbot/06-chatbot-live-api-curl.sh`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/demo/issue-2-chatbot/06-chatbot-live-api-curl.sh) | Live API 데모 (curl only) |
| [`demo/issue-2-chatbot/07-chatbot-security.sh`](https://github.com/tedwon/agentic-dev-playbook-with-harness/blob/feat/issue-2-quote-ai-chatbot/demo/issue-2-chatbot/07-chatbot-security.sh) | Security 데모 스크립트 |
| `demo/issue-2-chatbot/recordings/*.cast` | asciinema 녹화 4개 |

---

## Git Commits

```
57f13f8 docs(design): add spec and plan for issue-2 quote AI chatbot
7aca7a1 feat(chat): add AI chatbot endpoint with LangChain4j Ollama integration
093a773 docs(demo): add issue-2 chatbot demo scripts and asciinema recordings
```

All commits passed HARNESS 7/7 checks (BUILD-01~CONV-02).
