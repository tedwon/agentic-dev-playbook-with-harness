# Spec: Issue #2 — Quote AI Chatbot

| Field | Value |
|-------|-------|
| Ticket | [#2 명언 AI 챗봇 기능 추가](https://github.com/tedwon/agentic-dev-playbook-with-harness/issues/2) |
| Status | Approved |
| Date | 2026-04-29 |
| Author | Ted Won (human) + Claude Code (agent) |

---

## Summary

사용자가 명언에 대해 자유롭게 질문하면 AI가 대화로 답변하는 챗봇 REST API를 추가합니다.
Quarkus LangChain4j와 Ollama(qwen3:1.7b)를 사용하여 로컬 LLM 기반으로 동작합니다.

## Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-01 | POST /api/chat 엔드포인트: JSON 요청 `{"message": "..."}` → JSON 응답 `{"response": "..."}` |
| FR-02 | 기존 인메모리 명언 데이터(8개)를 AI 컨텍스트로 활용 |
| FR-03 | 명언 해설, 상황별 적용, 명언 추천 등 자연어 질문에 대응 |
| FR-04 | 사용자 질문 언어와 동일한 언어로 응답 (한국어 질문 → 한국어 답변) |

## Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | 로깅: org.jboss.logging.Logger 사용 (System.out 금지) |
| NFR-02 | JSON 직렬화: quarkus-rest-jackson (기존 의존성 재사용) |
| NFR-03 | 테스트: @QuarkusTest + @InjectMock (CI에서 Ollama 불필요) |
| NFR-04 | Conventional Commits 형식 준수 |
| NFR-05 | 모든 @Path 클래스에 대응하는 *Test.java 존재 |
| NFR-06 | Ollama 응답 타임아웃: 60초 |

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| AI 프레임워크 | Quarkus LangChain4j Ollama | Quarkus CDI 네이티브 통합, @RegisterAiService 패턴 |
| LLM 모델 | qwen3:1.7b (Ollama) | 로컬 실행, 외부 API 불필요, 다국어 지원 |
| 컨텍스트 주입 | @SystemMessage에 8개 명언 포함 | 8개뿐이므로 RAG/벡터스토어 불필요 |
| 요청/응답 모델 | Java 21 Record (ChatRequest, ChatResponse) | 기존 Quote.java 패턴 일관성 |
| 테스트 전략 | @InjectMock QuoteAiService | CI에서 Ollama 없이 결정적 테스트 |
| 엔드포인트 경로 | POST /api/chat | 기존 GET /api/quotes와 분리 |

## API Contract

### POST /api/chat

**Request:**
```json
{
  "message": "Linus Torvalds 명언을 설명해줘"
}
```

**Response (200 OK):**
```json
{
  "response": "Linus Torvalds의 'Talk is cheap. Show me the code.'는 ..."
}
```

## Acceptance Criteria

- [ ] POST /api/chat가 200 OK와 JSON 응답을 반환
- [ ] AI가 명언 컨텍스트를 활용하여 관련 답변 생성
- [ ] 한국어 질문에 한국어로 답변
- [ ] `./mvnw test` — 전체 테스트 통과
- [ ] `./mvnw spotless:check` — 포맷 통과
- [ ] System.out.println 없음 (QUAL-01)
- [ ] 하드코딩된 시크릿 없음 (QUAL-02)
- [ ] Conventional Commit 메시지 사용 (CONV-01)
- [ ] ChatBotResource에 대응하는 ChatBotResourceTest 존재 (CONV-02)

## Existing Code to Reuse

| Component | File | What to Reuse |
|-----------|------|---------------|
| Quote record | `src/main/java/dev/tedwon/Quote.java` | DTO 패턴 참조 |
| QuoteService | `src/main/java/dev/tedwon/QuoteService.java` | 명언 데이터 8개 |
| QuoteResource | `src/main/java/dev/tedwon/QuoteResource.java` | REST 엔드포인트 패턴, Logger 패턴 |
| QuoteResourceTest | `src/test/java/dev/tedwon/QuoteResourceTest.java` | @QuarkusTest + REST Assured 패턴 |
