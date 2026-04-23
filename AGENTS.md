# AGENTS.md

Guidelines for AI assistants working on this project.

## References

- **Claude Code usage guide:** <https://code.claude.com/docs>

## Project Overview

A Quarkus-based REST API application demonstrating AI-assisted agentic development workflows.

**Tech stack:** Java 21, Quarkus, Maven, REST/JSON

## Development

```bash
# Dev mode with live reload
./mvnw quarkus:dev

# Run tests
./mvnw test

# Build
./mvnw package

# Auto-fix code formatting
./mvnw spotless:apply

# Full verification (unit + integration tests)
./mvnw verify

# Security scanning (Phase 4 — CI-only, not in pre-commit)
./mvnw spotbugs:check              # Static analysis (bug patterns)
./mvnw dependency-check:check      # Known CVEs in dependencies
./mvnw cyclonedx:makeAggregateBom  # Generate SBOM (target/bom.json)
```

## Key Conventions

- **Java version:** 21 (use records, sealed classes, pattern matching where appropriate)
- **Build tool:** Maven (`mvnw` wrapper committed to repo)
- **Framework:** Quarkus — prefer CDI annotations, not Spring-style
- **Code style:** Follow existing patterns in the codebase
- **Logging:** Use `org.jboss.logging.Logger` (Quarkus default)
- **Config:** Use `application.properties` with `@ConfigProperty` injection
- **Testing:** JUnit 5 with `@QuarkusTest` for integration, plain JUnit for unit tests

## Agentic Development Workflow

For non-trivial feature work, follow the **[Agentic Development Playbook](agentic-development-playbook.md)**. This is a human-in-the-loop workflow with four phases:

1. **Design** — brainstorm requirements, design decisions, and trade-offs; then produce a detailed implementation plan
2. **Execute** — implement the plan step-by-step, with harness-enforced quality gates
3. **Review** — create PR/MR, run CI checks, and conduct code review
4. **Validate** — security scanning, local testing, and end-to-end verification

**When to use:** new features, API additions, architectural changes, or any multi-step work.
**When NOT to use:** small isolated fixes, typo corrections, or single-file bug fixes.

The playbook is loaded automatically via the `agentic-playbook` skill when starting brainstorming, planning, or execution sessions.

## Commit Messages

[Conventional Commits](https://www.conventionalcommits.org/) format: `<type>(<scope>): <subject>`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Project Structure

```
src/
├── main/java/          # Application code
├── main/resources/     # Config and static resources
└── test/java/          # Tests
```

---

## Harness Engineering

> **"Humans steer. Agents execute."** — [OpenAI, Harness Engineering](https://openai.com/index/harness-engineering/)

This project uses **automated harness engineering** to enable autonomous AI development
with minimal human intervention.

### Core Concept

```
Agent = Model + Harness
```

The harness is everything except the model: rules (CLAUDE.md), verification (hooks),
feedback loops (error messages), and guardrails (protected files).

### Two Types of Controls

| Type | What It Does | Files |
|------|-------------|-------|
| **Feedforward** (guides) | Prevent errors before they happen | CLAUDE.md, AGENTS.md, CHECKLIST.md |
| **Feedback** (sensors) | Detect and correct errors after they happen | .claude/hooks/*.sh, Maven checks |

### Self-Correction Loop

The agent writes code, attempts to commit, and the harness runs all checks automatically.
If any check fails, the commit is blocked with actionable error messages (rule ID + fix hint).
The agent fixes all violations and retries until every check passes.

See agent-specific config (CLAUDE.md, `.cursor/rules/`) for the detailed protocol.

### Automated Checks

See [CHECKLIST.md](CHECKLIST.md) for detailed descriptions.

| ID | Check | Command |
|----|-------|---------|
| BUILD-01 | Compilation | `./mvnw compile -q` |
| BUILD-02 | Tests | `./mvnw test` |
| BUILD-03 | Code formatting | `./mvnw spotless:check -q` |
| QUAL-01 | No System.out.println | `grep` scan of src/main/java/ |
| QUAL-02 | No hardcoded secrets | `grep` scan for password/key patterns |
| CONV-01 | Conventional commits | Regex match on commit message |
| CONV-02 | Test coverage | `@Path` class to `*Test.java` mapping |
| SEC-01 | SpotBugs static analysis | `./mvnw spotbugs:check` (CI-only) |
| SEC-02 | Dependency vulnerability scan | `./mvnw dependency-check:check` (CI-only) |
| SEC-03 | SBOM generation | `./mvnw cyclonedx:makeAggregateBom` (CI-only) |

### Harness Architecture

**Claude Code** (tested):

```
.claude/
├── settings.json                # Hook configuration + permissions
├── hooks/
│   ├── pre-commit-harness.sh   # Main pre-commit verification (7 checks)
│   ├── protect-files.sh         # Block edits to harness files
│   └── post-edit-verify.sh     # Quick compile check after edits
└── skills/
    └── agentic-playbook/       # Agentic workflow skill
```

**Cursor** (untested — install git hooks: `./scripts/install-git-hooks.sh`):

```
.cursor/
└── rules/
    ├── harness-engineering.mdc  # Harness rules (auto-loaded by Cursor)
    └── code-conventions.mdc     # Code conventions for Java files
hooks/
├── pre-commit                   # Standard git pre-commit hook (6 checks)
└── commit-msg                   # Standard git commit-msg hook (CONV-01)
scripts/
└── install-git-hooks.sh         # Symlinks hooks/ into .git/hooks/
```

### References

- OpenAI: [Harness Engineering](https://openai.com/index/harness-engineering/)
- Anthropic: [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- Anthropic: [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- Community: [Awesome Harness Engineering](https://github.com/ai-boost/awesome-harness-engineering)
