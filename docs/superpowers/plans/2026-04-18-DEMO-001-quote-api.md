# Plan: Quote of the Day API

**Ticket:** DEMO-001
**Spec:** [2026-04-18-DEMO-001-quote-api.md](../specs/2026-04-18-DEMO-001-quote-api.md)
**Date:** 2026-04-18
**Model hints:** Sonnet for Tasks 1-2 (mechanical), Opus for Tasks 3-4 (logic)

## Task Sequence

### Task 1: Add Jackson dependency
- **File:** `pom.xml`
- **Action:** Add `quarkus-rest-jackson` dependency
- **Verify:** `./mvnw compile -q`

### Task 2: Create Quote Record DTO
- **File:** `src/main/java/dev/tedwon/Quote.java`
- **Action:** Create Java 21 Record with fields: `id`, `text`, `author`, `category`
- **Verify:** `./mvnw compile -q`

### Task 3: Create QuoteService CDI bean
- **Files:**
  - `src/main/java/dev/tedwon/QuoteService.java`
  - `src/main/resources/application.properties`
  - `src/test/java/dev/tedwon/QuoteServiceTest.java`
- **Action:**
  - `@ApplicationScoped` service with in-memory quote data
  - `@ConfigProperty(name = "app.quote.default-category")` injection
  - `org.jboss.logging.Logger` for all logging
  - Methods: `getAllQuotes()`, `getQuoteById(long)`, `getRandomQuote()`, `getQuotesByCategory(String)`
  - Unit tests for each method
- **Verify:** `./mvnw test -q`

### Task 4: Create QuoteResource REST endpoints
- **Files:**
  - `src/main/java/dev/tedwon/QuoteResource.java`
  - `src/test/java/dev/tedwon/QuoteResourceTest.java`
  - `src/test/java/dev/tedwon/QuoteResourceIT.java`
- **Action:**
  - `@Path("/api/quotes")` with 3 GET endpoints
  - Category query param filtering on list endpoint
  - 404 handling via `jakarta.ws.rs.core.Response`
  - `@QuarkusTest` with REST Assured for all endpoints
  - Integration test extending QuoteResourceTest
- **Verify:** `./mvnw test`

### Task 5: Final verification
- **Action:**
  - `./mvnw spotless:apply` then `./mvnw spotless:check -q`
  - `./mvnw verify`
  - Manual curl test against `./mvnw quarkus:dev`
- **Verify:** All 7 harness checks pass

## Dependencies

```
Task 1 (Jackson) ──► Task 2 (Record) ──► Task 3 (Service) ──► Task 4 (Resource) ──► Task 5 (Verify)
```

All tasks are sequential — each builds on the previous.

## Harness Integration

The pre-commit harness runs 7 automated checks on every commit:
- BUILD-01: Compilation
- BUILD-02: Tests
- BUILD-03: Code formatting (Spotless)
- QUAL-01: No System.out.println
- QUAL-02: No hardcoded secrets
- CONV-01: Conventional commit messages
- CONV-02: Test coverage for @Path classes

Any violation blocks the commit with actionable error messages.
The agent reads the errors, fixes all violations, and retries.
