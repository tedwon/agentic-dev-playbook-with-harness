# Development Quality Checklist

Rules enforced automatically by the harness before every commit.
When any rule fails, the commit is blocked and the agent must fix the violation.

## Build Rules

- **[BUILD-01] Compilation:** `./mvnw compile -q` must exit 0
- **[BUILD-02] Tests:** `./mvnw test` must exit 0 (all unit tests green)
- **[BUILD-03] Formatting:** `./mvnw spotless:check -q` must exit 0

## Code Quality Rules

- **[QUAL-01] No System.out:** Source files in `src/main/java/` must not contain
  `System.out.print`. Use `org.jboss.logging.Logger` instead.

  ```java
  // Wrong
  System.out.println("Hello");

  // Correct
  private static final Logger LOG = Logger.getLogger(YourClass.class);
  LOG.info("Hello");
  ```

- **[QUAL-02] No hardcoded secrets:** Source files must not contain patterns like
  `password=`, `apiKey=`, `secret=`, `token=` with literal string values.
  Use `@ConfigProperty` or environment variables instead.

## Convention Rules

- **[CONV-01] Conventional commits:** Commit messages must match the format:

  ```
  <type>(<scope>): <subject>
  ```

  Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

  Example: `feat(greeting): add personalized greeting endpoint`

- **[CONV-02] Test coverage:** Every `@Path`-annotated class in `src/main/java/`
  must have a corresponding `*Test.java` file in `src/test/java/`.

## How Violations Are Handled

```
Agent writes code
       |
       v
Agent attempts git commit
       |
       v
Pre-commit harness runs all 7 checks
       |
   ALL PASS? ---yes---> Commit proceeds (exit 0)
       |
      no
       |
       v
Commit blocked (exit 2) + detailed error message
       |
       v
Agent reads error, fixes ALL violations
       |
       v
Agent retries commit (loop back up)
```

1. The pre-commit hook runs ALL checks (does not stop at first failure)
2. Failed checks produce an error message with the rule ID and fix instructions
3. The commit is blocked (exit code 2)
4. The AI agent reads the error, fixes the code, and retries
5. The commit succeeds only when ALL rules pass

## Protected Files

These files cannot be modified by the AI agent without explicit human approval:

- `CLAUDE.md` (harness rules)
- `CHECKLIST.md` (this file)
- `.claude/settings.json` (hook configuration)
- `.claude/hooks/*` (hook scripts)
