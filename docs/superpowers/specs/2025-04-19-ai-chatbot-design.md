# AI Chatbot Design Document

**Date:** 2025-04-19  
**Feature:** AI Chatbot with Ollama Integration  
**Status:** Approved for Implementation

---

## Overview

A stateless REST API chatbot that integrates with a local Ollama instance to provide AI-powered conversational responses. The chatbot uses the existing Quarkus architecture patterns (Resource → Service → Client) and follows the project's harness engineering principles.

---

## Goals

- Provide a simple HTTP endpoint for AI chat via local Ollama LLM
- Follow existing codebase patterns (QuoteResource, QuoteService)
- Require no external API keys (runs locally via Ollama)
- Support configurable model selection
- Return clear error messages when Ollama is unavailable

---

## Non-Goals

- Persistent conversation history (stateless design)
- Streaming responses (synchronous only)
- Multi-turn conversation context
- Rate limiting or usage quotas (local deployment assumed)

---

## API Specification

### Endpoint

```
POST /api/chat
```

### Request Body

```json
{
  "message": "What is the best programming advice?",
  "model": "llama3.2"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| message | string | Yes | The user's message to the AI |
| model | string | No | Model to use (defaults to configured default) |

### Response Body

```json
{
  "response": "The best programming advice is to write code that is readable and maintainable...",
  "model": "llama3.2",
  "tokensUsed": 150
}
```

| Field | Type | Description |
|-------|------|-------------|
| response | string | The AI's generated response |
| model | string | Model used for generation |
| tokensUsed | int | Approximate tokens used (if available from Ollama) |

### Error Responses

| HTTP Status | Scenario | Error Message |
|-------------|----------|---------------|
| 400 | Invalid request (missing message) | "Message is required" |
| 400 | Invalid model specified | "Model not available: {model}" |
| 503 | Ollama not running | "Ollama service unavailable" |
| 504 | Request timeout | "Request timed out after {timeout}s" |

---

## Architecture

### Component Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   ChatResource  │────▶│   ChatService   │────▶│  OllamaClient   │
│   (REST API)    │◄────│  (Business Logic)│◄────│ (HTTP Client)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                                               │
         ▼                                               ▼
   DTOs: ChatRequest                              Ollama API
        ChatResponse                              (localhost:11434)
```

### Component Descriptions

#### ChatRequest (DTO)
- Immutable record with `message` and optional `model` fields
- Bean Validation annotations for input validation

#### ChatResponse (DTO)
- Immutable record with `response`, `model`, and `tokensUsed` fields
- Built by ChatService from Ollama API response

#### ChatResource
- JAX-RS REST endpoint at `/api/chat`
- Consumes/produces JSON
- Uses `@Inject ChatService`
- Returns 200 on success, maps exceptions to appropriate HTTP status

#### ChatService
- CDI ApplicationScoped service
- Handles prompt formatting and response processing
- Calls OllamaClient and transforms responses
- Uses `@ConfigProperty` for default model

#### OllamaClient
- CDI Singleton or ApplicationScoped
- Uses Quarkus REST Client (`@RestClient`) or JDK HttpClient
- Handles HTTP communication with Ollama
- Returns structured response objects

#### OllamaConfig
- CDI Configuration class with `@ConfigMapping`
- Properties: baseUrl, defaultModel, timeoutSeconds, maxTokens
- Or individual `@ConfigProperty` fields

---

## Ollama Integration

### API Endpoint

```
POST http://localhost:11434/api/generate
```

### Request Format

```json
{
  "model": "llama3.2",
  "prompt": "What is the best programming advice?",
  "stream": false,
  "options": {
    "temperature": 0.7,
    "num_predict": 2048
  }
}
```

### Response Format

```json
{
  "model": "llama3.2",
  "created_at": "2025-04-19T10:00:00Z",
  "response": "The best programming advice is...",
  "done": true,
  "total_duration": 2500000000,
  "load_duration": 500000000,
  "prompt_eval_count": 10,
  "eval_count": 150
}
```

### Error Responses from Ollama

- Connection refused → Map to 503 Service Unavailable
- Model not found → Map to 400 Bad Request with helpful message
- Timeout → Map to 504 Gateway Timeout

---

## Configuration

Add to `application.properties`:

```properties
# Ollama Configuration
ollama.base-url=http://localhost:11434
ollama.default-model=llama3.2
ollama.timeout-seconds=30
ollama.max-tokens=2048
ollama.temperature=0.7
```

---

## Error Handling

### Exception Hierarchy

```
ChatException (RuntimeException)
├── OllamaUnavailableException → HTTP 503
├── InvalidModelException → HTTP 400
└── ChatTimeoutException → HTTP 504
```

### Error Response Format

```json
{
  "error": "Ollama service unavailable",
  "code": "OLLAMA_UNAVAILABLE",
  "details": "Could not connect to Ollama at http://localhost:11434"
}
```

---

## Testing Strategy

### Unit Tests

- `ChatServiceTest`: Mock OllamaClient, test prompt formatting and response building
- Test error handling paths (timeout, unavailable, invalid model)
- Test configuration injection

### Integration Tests

- `ChatResourceIT`: `@QuarkusTest` with Testcontainers or WireMock
- Mock Ollama API responses
- Test HTTP status codes and response formats
- Test bean validation

### Manual Testing Prerequisites

1. Install Ollama: https://ollama.com
2. Pull model: `ollama pull llama3.2`
3. Start Ollama: `ollama serve` (or let it auto-start)
4. Test endpoint: `curl -X POST http://localhost:8080/api/chat -H "Content-Type: application/json" -d '{"message":"Hello"}'`

---

## Dependencies

Add to `pom.xml`:

```xml
<!-- Quarkus REST Client for Ollama HTTP calls -->
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-rest-client-jackson</artifactId>
</dependency>

<!-- For configuration mapping (optional) -->
<dependency>
    <groupId>io.smallrye.config</groupId>
    <artifactId>smallrye-config-common</artifactId>
</dependency>
```

---

## File Structure

```
src/main/java/dev/tedwon/
├── chat/
│   ├── ChatResource.java        # REST endpoint
│   ├── ChatService.java         # Business logic
│   ├── OllamaClient.java        # HTTP client interface
│   ├── OllamaConfig.java        # Configuration
│   ├── ChatRequest.java         # Request DTO
│   ├── ChatResponse.java        # Response DTO
│   └── exception/
│       ├── ChatException.java
│       ├── OllamaUnavailableException.java
│       └── InvalidModelException.java
```

---

## Security Considerations

- No authentication required (assumed local/development use)
- No input sanitization required (Ollama handles prompt injection locally)
- No rate limiting (local deployment assumed)
- Configuration contains no secrets (just URLs and model names)

---

## Future Enhancements (Out of Scope)

- Streaming responses with Server-Sent Events (SSE)
- Conversation history with session management
- Support for multiple LLM providers (OpenAI, Anthropic)
- Prompt templates and system prompts
- RAG (Retrieval-Augmented Generation) with quote database

---

## References

- Ollama API Docs: https://github.com/ollama/ollama/blob/main/docs/api.md
- Quarkus REST Client: https://quarkus.io/guides/rest-client
- Quarkus Configuration: https://quarkus.io/guides/config
