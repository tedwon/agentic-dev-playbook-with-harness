# Quote AI Chatbot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `POST /api/chat` endpoint that answers natural language questions about quotes using a local Ollama LLM via Quarkus LangChain4j.

**Architecture:** Stateless REST endpoint backed by a declarative `@RegisterAiService` interface. All 8 existing quotes are injected into the LLM system prompt as context. No RAG, no conversation history. Quarkus dev services auto-start Ollama in dev/test mode.

**Tech Stack:** Java 21, Quarkus 3.34.3, Quarkus LangChain4j (Ollama), JUnit 5, REST-assured

**Spec:** `docs/superpowers/specs/2026-04-28-issue-2-quote-ai-chatbot-design.md`

---

### Task 1: Add Maven Dependencies and Configuration

**Files:**
- Modify: `pom.xml`
- Modify: `src/main/resources/application.properties`

- [ ] **Step 1: Add LangChain4j BOM to dependencyManagement**

In `pom.xml`, add the `quarkus-langchain4j-bom` inside the existing `<dependencyManagement><dependencies>` block, after the existing `quarkus-bom` entry:

```xml
<dependency>
    <groupId>${quarkus.platform.group-id}</groupId>
    <artifactId>quarkus-langchain4j-bom</artifactId>
    <version>${quarkus.platform.version}</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
```

- [ ] **Step 2: Add Ollama dependency**

In `pom.xml`, add inside `<dependencies>` (after the existing `quarkus-arc` dependency):

```xml
<dependency>
    <groupId>io.quarkiverse.langchain4j</groupId>
    <artifactId>quarkus-langchain4j-ollama</artifactId>
</dependency>
```

No version — managed by the BOM added in Step 1.

- [ ] **Step 3: Add Ollama configuration**

Append to `src/main/resources/application.properties`:

```properties

# Ollama LLM configuration
quarkus.langchain4j.ollama.chat-model.model-name=llama3.2
quarkus.langchain4j.timeout=60s
```

- [ ] **Step 4: Verify compilation**

Run: `./mvnw compile -q`

Expected: BUILD SUCCESS (dependencies resolve, no compilation errors)

- [ ] **Step 5: Commit**

```bash
git add pom.xml src/main/resources/application.properties
git commit -m "feat(chat): add Quarkus LangChain4j Ollama dependencies and config"
```

---

### Task 2: Create Data Model Records

**Files:**
- Create: `src/main/java/dev/tedwon/ChatRequest.java`
- Create: `src/main/java/dev/tedwon/ChatResponse.java`

- [ ] **Step 1: Create ChatRequest record**

Create `src/main/java/dev/tedwon/ChatRequest.java`:

```java
package dev.tedwon;

public record ChatRequest(String message) {}
```

- [ ] **Step 2: Create ChatResponse record**

Create `src/main/java/dev/tedwon/ChatResponse.java`:

```java
package dev.tedwon;

public record ChatResponse(String response) {}
```

- [ ] **Step 3: Verify compilation**

Run: `./mvnw compile -q`

Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add src/main/java/dev/tedwon/ChatRequest.java src/main/java/dev/tedwon/ChatResponse.java
git commit -m "feat(chat): add ChatRequest and ChatResponse records"
```

---

### Task 3: Create QuoteChatService AI Service Interface

**Files:**
- Create: `src/main/java/dev/tedwon/QuoteChatService.java`

- [ ] **Step 1: Create the AI service interface**

Create `src/main/java/dev/tedwon/QuoteChatService.java`:

```java
package dev.tedwon;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import io.quarkiverse.langchain4j.RegisterAiService;
import jakarta.enterprise.context.ApplicationScoped;

@RegisterAiService
@ApplicationScoped
public interface QuoteChatService {

    @SystemMessage(
            """
            You are a wise and friendly quote expert assistant.
            You help people understand, appreciate, and apply famous quotes in their daily lives.

            Your capabilities:
            - Explain the meaning and historical background of quotes
            - Suggest how quotes apply to specific situations (especially for developers and professionals)
            - Recommend quotes based on the user's mood or situation
            - Respond naturally in the same language the user uses (Korean or English)

            Here are the quotes you know about:
            {quotes}

            Guidelines:
            - Use the provided quotes as your primary knowledge base
            - If asked about a quote not in your list, you may share general knowledge but mention it is not in your curated collection
            - Keep responses conversational and engaging, not academic
            - When recommending quotes, briefly explain why the quote fits the situation
            """)
    @UserMessage("{message}")
    String chat(String message, String quotes);
}
```

- [ ] **Step 2: Verify compilation**

Run: `./mvnw compile -q`

Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add src/main/java/dev/tedwon/QuoteChatService.java
git commit -m "feat(chat): add QuoteChatService AI service interface"
```

---

### Task 4: Create QuoteChatResource REST Endpoint with Tests

Note: The pre-commit harness (BUILD-02) runs all tests on every commit. Tests and
implementation must be committed together so the harness passes.

**Files:**
- Create: `src/main/java/dev/tedwon/QuoteChatResource.java`
- Create: `src/test/java/dev/tedwon/QuoteChatResourceTest.java`
- Create: `src/test/java/dev/tedwon/QuoteChatResourceIT.java`

- [ ] **Step 1: Create the REST resource**

Create `src/main/java/dev/tedwon/QuoteChatResource.java`:

```java
package dev.tedwon;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.stream.Collectors;
import org.jboss.logging.Logger;

@Path("/api/chat")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class QuoteChatResource {

    private static final Logger LOG = Logger.getLogger(QuoteChatResource.class);

    @Inject QuoteChatService chatService;

    @Inject QuoteService quoteService;

    @POST
    public ChatResponse chat(ChatRequest request) {
        if (request == null || request.message() == null || request.message().isBlank()) {
            throw new WebApplicationException("Message is required", Response.Status.BAD_REQUEST);
        }
        LOG.infof("Chat request: %s", request.message());
        String quotes = formatQuotes(quoteService.getAllQuotes());
        String response = chatService.chat(request.message(), quotes);
        return new ChatResponse(response);
    }

    private String formatQuotes(List<Quote> quotes) {
        return quotes.stream()
                .map(
                        q ->
                                String.format(
                                        "- \"%s\" — %s (category: %s)",
                                        q.text(), q.author(), q.category()))
                .collect(Collectors.joining("\n"));
    }
}
```

- [ ] **Step 2: Write the test class**

Create `src/test/java/dev/tedwon/QuoteChatResourceTest.java`:

```java
package dev.tedwon;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.emptyString;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

@QuarkusTest
class QuoteChatResourceTest {

    @Test
    void testChatEndpoint() {
        given().contentType(ContentType.JSON)
                .body("{\"message\": \"Tell me about the quote by Linus Torvalds\"}")
                .when()
                .post("/api/chat")
                .then()
                .statusCode(200)
                .body("response", notNullValue())
                .body("response", not(emptyString()));
    }

    @Test
    void testChatEndpointEmptyMessage() {
        given().contentType(ContentType.JSON)
                .body("{\"message\": \"\"}")
                .when()
                .post("/api/chat")
                .then()
                .statusCode(400);
    }
}
```

- [ ] **Step 3: Create integration test**

Create `src/test/java/dev/tedwon/QuoteChatResourceIT.java`:

```java
package dev.tedwon;

import io.quarkus.test.junit.QuarkusIntegrationTest;

@QuarkusIntegrationTest
class QuoteChatResourceIT extends QuoteChatResourceTest {}
```

- [ ] **Step 4: Run the chat tests**

Run: `./mvnw test -Dtest=QuoteChatResourceTest`

Expected: BUILD SUCCESS — both `testChatEndpoint` and `testChatEndpointEmptyMessage` pass.

Note: The Quarkus LangChain4j dev service will auto-start an Ollama container. First run
may take a few minutes to pull the container image and model. If the test times out, increase
the timeout in `application.properties`: `quarkus.langchain4j.timeout=120s`

- [ ] **Step 5: Commit**

```bash
git add src/main/java/dev/tedwon/QuoteChatResource.java src/test/java/dev/tedwon/QuoteChatResourceTest.java src/test/java/dev/tedwon/QuoteChatResourceIT.java
git commit -m "feat(chat): add QuoteChatResource endpoint with tests"
```

---

### Task 5: Run Full Test Suite and Final Verification

**Files:**
- No new files — verification only

- [ ] **Step 1: Run all unit tests**

Run: `./mvnw test`

Expected: BUILD SUCCESS — all tests pass, including existing `QuoteResourceTest`,
`QuoteServiceTest`, and `GreetingResourceTest`.

- [ ] **Step 2: Run code formatting**

Run: `./mvnw spotless:apply`

Then check if any files were reformatted:

Run: `git diff --name-only`

If any files changed, stage them.

- [ ] **Step 3: Run formatting check**

Run: `./mvnw spotless:check -q`

Expected: BUILD SUCCESS (no formatting violations)

- [ ] **Step 4: Commit any formatting fixes**

If spotless:apply changed any files:

```bash
git add -A
git commit -m "chore: apply spotless formatting"
```

If no changes, skip this step.

- [ ] **Step 5: Verify full build**

Run: `./mvnw verify`

Expected: BUILD SUCCESS — unit tests and integration tests all pass.
