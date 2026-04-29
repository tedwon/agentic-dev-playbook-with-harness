# Plan: Issue #2 — Quote AI Chatbot

| Field | Value |
|-------|-------|
| Ticket | [#2](https://github.com/tedwon/agentic-dev-playbook-with-harness/issues/2) |
| Spec | [specs/2026-04-29-issue-2-quote-ai-chatbot.md](../specs/2026-04-29-issue-2-quote-ai-chatbot.md) |
| Date | 2026-04-29 |

---

## Task Sequence (Sequential)

### Task 1: Add Quarkus LangChain4j Ollama dependency

**Files:** `pom.xml`

**Actions:**
1. Add property: `<quarkus-langchain4j.version>` in `<properties>`
2. Add dependency: `quarkus-langchain4j-ollama` with version property
3. Add test dependency: `quarkus-junit5-mockito` (managed by quarkus-bom)

**Verify:** `./mvnw compile`

---

### Task 2: Create request/response DTO records

**Files (new):**
- `src/main/java/dev/tedwon/ChatRequest.java`
- `src/main/java/dev/tedwon/ChatResponse.java`

**Actions:**
```java
public record ChatRequest(String message) {}
public record ChatResponse(String response) {}
```

**Verify:** `./mvnw compile`

---

### Task 3: Create QuoteAiService AI service interface

**Files (new):** `src/main/java/dev/tedwon/QuoteAiService.java`

**Actions:**
- `@RegisterAiService` interface
- `@SystemMessage` with all 8 quotes as context
- `String chat(@UserMessage String message)` method

**Verify:** `./mvnw compile`

---

### Task 4: Configure Ollama in application.properties

**Files:** `src/main/resources/application.properties`

**Actions:** Append Ollama config:
```properties
quarkus.langchain4j.ollama.chat-model.model-name=qwen3:1.7b
quarkus.langchain4j.ollama.chat-model.temperature=0.7
quarkus.langchain4j.timeout=60s
```

**Verify:** `./mvnw compile`

---

### Task 5: Create ChatBotResource REST endpoint

**Files (new):** `src/main/java/dev/tedwon/ChatBotResource.java`

**Actions:**
- `@Path("/api/chat")`, `@POST`
- `@Inject QuoteAiService`
- Logger (org.jboss.logging.Logger)
- Input: `ChatRequest` → Output: `ChatResponse`

**Verify:** `./mvnw compile`

---

### Task 6: Create tests

**Files (new):**
- `src/test/java/dev/tedwon/ChatBotResourceTest.java`
- `src/test/java/dev/tedwon/ChatBotResourceIT.java`

**Actions:**
- `@QuarkusTest` + `@InjectMock QuoteAiService`
- Test: POST /api/chat returns 200 with JSON response
- Test: Empty message handled gracefully
- IT: `@QuarkusIntegrationTest extends ChatBotResourceTest`

**Verify:** `./mvnw test`

---

### Task 7: Final verification and commit

**Actions:**
1. `./mvnw spotless:apply`
2. `./mvnw verify`
3. Commit: `feat(chat): add AI chatbot endpoint with LangChain4j Ollama integration`

**Verify:** All 7 harness checks pass (BUILD-01~CONV-02)

---

## Dependencies

```
Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6 → Task 7
```

## Harness Integration

Pre-commit harness runs 7 checks automatically on commit:
- BUILD-01: Compilation
- BUILD-02: Tests
- BUILD-03: Code formatting (Spotless)
- QUAL-01: No System.out.println
- QUAL-02: No hardcoded secrets
- CONV-01: Conventional commit message
- CONV-02: Test coverage for @Path classes
