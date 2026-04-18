# Spec: Quote of the Day API

**Ticket:** DEMO-001
**Date:** 2026-04-18
**Status:** Approved

## Summary

Add a "Quote of the Day" REST API to the Quarkus application, providing
endpoints to list, retrieve, and randomly select motivational quotes.

## Requirements

### Functional Requirements

1. `GET /api/quotes` — return all quotes, optionally filtered by `?category=`
2. `GET /api/quotes/random` — return a single random quote
3. `GET /api/quotes/{id}` — return a quote by ID, or 404 if not found
4. Quotes are stored in-memory (no database required for this iteration)
5. Each quote has: `id`, `text`, `author`, `category`

### Non-Functional Requirements

- JSON responses via Jackson serialization
- Logging via `org.jboss.logging.Logger` (no System.out)
- Configuration via `@ConfigProperty` for default category
- Full test coverage with `@QuarkusTest` and REST Assured

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data model | Java 21 Record | Immutable, concise, auto-serializes with Jackson |
| Storage | In-memory List | Simplicity; no DB dependency for demo |
| DI pattern | CDI @ApplicationScoped | Quarkus standard; singleton service |
| Error handling | HTTP 404 Response | Standard REST semantics for missing resources |

## Acceptance Criteria

- [ ] All 3 endpoints return correct JSON responses
- [ ] Category filtering works correctly
- [ ] Non-existent ID returns HTTP 404
- [ ] No System.out.println in production code
- [ ] All tests pass (`./mvnw test`)
- [ ] Code formatting passes (`./mvnw spotless:check`)
- [ ] Conventional commit messages used

## Sample Data

8 quotes covering two categories:
- `programming` (4): Linus Torvalds, Harold Abelson, Martin Fowler, John Johnson
- `inspiration` (4): Alan Kay, Austin Freeman, Steve Jobs, Albert Einstein
