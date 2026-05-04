# Design: Quote AI Chatbot (Issue #2)

| | |
| --- | --- |
| **Issue** | [#2](https://github.com/tedwon/agentic-dev-playbook-with-harness/issues/2) |
| **Date** | 2026-04-28 |
| **Status** | Approved |

## Summary

Add an AI chatbot endpoint that answers natural language questions about quotes. The chatbot
uses the existing quote database as context and runs on a local Ollama LLM. No external API
or web search required.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| LLM provider | Ollama | Most popular local LLM runtime, mature LangChain4j support, Quarkus dev services |
| LLM framework | Quarkus LangChain4j Extension | Idiomatic Quarkus (CDI, config properties, dev services), minimal boilerplate |
| API shape | Simple stateless REST | `POST /api/chat` with JSON request/response. No session state, easy to test with curl |
| Context strategy | System prompt injection | 8 quotes fit easily in the context window. No RAG overhead needed |
| Default model | llama3.2 | 3B parameters, good quality/speed balance, multilingual support (Korean included) |

## Use Cases

### 1. Quote explanation

```
User: "Stay hungry, stay foolish" 이 명언 설명해줘
AI: 스티브 잡스가 2005년 스탠퍼드 졸업식에서 한 말로, ...
```

### 2. Situational application

```
User: 이걸 개발자한테 적용하면?
AI: 새로운 기술을 두려워하지 말고, 익숙한 도구에 안주하지 말라는 뜻으로 ...
```

### 3. Quote recommendation

```
User: 오늘 의욕이 없는데 힘이 되는 명언 하나 추천해줘
AI: "The only way to do great work is to love what you do." - Steve Jobs ...
```

## Architecture

### New files

```
src/main/java/dev/tedwon/
├── ChatRequest.java        — Request record: { message: String }
├── ChatResponse.java       — Response record: { response: String }
├── QuoteChatService.java   — @RegisterAiService interface (LangChain4j declarative AI service)
└── QuoteChatResource.java  — REST endpoint at /api/chat

src/test/java/dev/tedwon/
├── QuoteChatResourceTest.java  — @QuarkusTest integration test
└── QuoteChatResourceIT.java    — Native integration test (extends QuoteChatResourceTest)
```

### Unchanged files

- `Quote.java` — existing record, no changes
- `QuoteService.java` — existing service, consumed as read-only context
- `QuoteResource.java` — existing REST resource, no changes
- All existing tests — must continue to pass

### Data flow

```
Client                QuoteChatResource      QuoteChatService       Ollama
  |                         |                       |                  |
  |-- POST /api/chat ------>|                       |                  |
  |   {message: "..."}      |                       |                  |
  |                         |-- getAllQuotes() ----->|                  |
  |                         |<-- List<Quote> --------|                  |
  |                         |-- format quotes ------>|                  |
  |                         |-- chat(message, ------>|                  |
  |                         |       quotes)          |-- LLM call ---->|
  |                         |                        |<-- response ----|
  |                         |<-- String response ----|                  |
  |<-- {response: "..."} ---|                        |                  |
```

## Component Details

### ChatRequest record

```java
public record ChatRequest(String message) {}
```

### ChatResponse record

```java
public record ChatResponse(String response) {}
```

### QuoteChatService (AI service interface)

```java
@RegisterAiService
@ApplicationScoped
public interface QuoteChatService {

    @SystemMessage("""
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
        - If asked about a quote not in your list, you may share general knowledge but mention
          it is not in your curated collection
        - Keep responses conversational and engaging, not academic
        - When recommending quotes, briefly explain why the quote fits the situation
        """)
    @UserMessage("{message}")
    String chat(String message, String quotes);
}
```

### QuoteChatResource (REST endpoint)

```java
@Path("/api/chat")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class QuoteChatResource {

    private static final Logger LOG = Logger.getLogger(QuoteChatResource.class);

    @Inject
    QuoteChatService chatService;

    @Inject
    QuoteService quoteService;

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
                .map(q -> String.format("- \"%s\" — %s (category: %s)", q.text(), q.author(), q.category()))
                .collect(Collectors.joining("\n"));
    }
}
```

## Configuration

Add to `application.properties`:

```properties
# Ollama LLM configuration
quarkus.langchain4j.ollama.chat-model.model-name=llama3.2
quarkus.langchain4j.timeout=60s
```

Quarkus dev services will auto-start Ollama in dev and test mode — no manual Ollama setup
required for development.

## Dependencies

Add the Quarkus LangChain4j BOM to `dependencyManagement` (version managed by the Quarkus
platform), then add the Ollama dependency without a version:

```xml
<!-- In <dependencyManagement><dependencies>: -->
<dependency>
    <groupId>${quarkus.platform.group-id}</groupId>
    <artifactId>quarkus-langchain4j-bom</artifactId>
    <version>${quarkus.platform.version}</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>

<!-- In <dependencies>: -->
<dependency>
    <groupId>io.quarkiverse.langchain4j</groupId>
    <artifactId>quarkus-langchain4j-ollama</artifactId>
</dependency>
```

## Testing Strategy

### QuoteChatResourceTest (@QuarkusTest)

- `testChatEndpoint()` — `POST /api/chat` with valid message returns 200 with non-empty response
- `testChatEndpointEmptyMessage()` — `POST /api/chat` with blank message returns 400
- Uses Ollama dev service (auto-started by Quarkus LangChain4j in test mode)

### QuoteChatResourceIT (integration)

- Extends `QuoteChatResourceTest` — runs in packaged mode (same pattern as existing IT tests)

### What we're NOT testing

LLM response quality. Output is non-deterministic — we verify the plumbing works (request in,
response out), not the specific content of answers.

### Existing tests

All existing tests must continue to pass unchanged:
- `QuoteResourceTest` / `QuoteResourceIT`
- `QuoteServiceTest`
- `GreetingResourceTest` / `GreetingResourceIT`

## Acceptance Criteria

- [ ] `POST /api/chat` accepts a natural language question and returns an AI-generated response
- [ ] The AI uses the existing 8 quotes from `QuoteService` as context
- [ ] Responses are conversational and contextually relevant
- [ ] Works with local Ollama (no external API calls)
- [ ] Returns 400 for missing or empty messages
- [ ] All existing tests continue to pass
- [ ] New tests cover the chat endpoint (happy path + validation)

## Out of Scope

- Conversation history / multi-turn context (stateless by design)
- Streaming responses (SSE)
- RAG / vector store (8 quotes fit in system prompt)
- Web UI for the chatbot
- Adding new quotes through the chat interface
