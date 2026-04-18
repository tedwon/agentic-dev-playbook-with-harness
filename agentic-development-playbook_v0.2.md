# Humans steer. Agents execute. - Agentic Development Playbook

| | |
| --- | --- |
| **Version** | v0.2 |
| **Last updated** | 2026-04-22 |
| **Status** | Living document — updated through real-world practice |

> This playbook is versioned and tagged to avoid confusion across projects.
> Always check you are using the latest version before starting a new engagement.
>
> **"Humans steer. Agents execute."** — [OpenAI, Harness Engineering](https://openai.com/index/harness-engineering/)

A guide for running AI-assisted feature development on this project using Claude Code
with the superpowers plugin.

**When to use:** new features, whether the design is settled (existing ADRs) or open
(architectural decisions explored and agreed during brainstorming — the skill can generate
ADRs as part of the process). Examples:
- Adding a new REST endpoint with business logic and validation
- Integrating an external service (e.g., LLM provider, message broker)
- Redesigning a data model — design explored and agreed as part of the brainstorming

**When not to use:** small isolated fixes or bug fixes.

**Target maturity level:** This playbook is designed for teams at **Level 3 (Intentional)**
on the [AEMI (MetaCTO)](https://www.metacto.com/blogs/mapping-ai-tools-to-every-phase-of-your-sdlc)
or [ELEKS](https://eleks.com/blog/ai-sdlc-maturity-model/) maturity scales — teams with
existing CI/CD pipelines and some experience using AI coding tools. Teams at Level 1-2
should start with simpler AI-assisted workflows (copilot-style completion and chat-based
assistance) before adopting the full playbook.

**This is a human-in-the-loop workflow, not a fully autonomous one.** The agent generates
specs, plans, and code, but the human drives design decisions, provides domain knowledge,
validates against real data, catches semantic mismatches, and approves each phase before
moving forward. Multiple human corrections are typically needed during design alone, and
critical bugs have been caught only by human database inspection after all tests passed.

**Building trust incrementally.** Start agents on low-risk, well-understood tasks. Expand
scope only after measured success. Maintain the right to reduce agent autonomy when trust is
violated. Track trust signals — review rejection rate, post-merge defects in agent-generated
code, and human correction frequency per phase. The industry-wide
[trust gap](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf?hsLang=en)
(usage at 80%, trust at 29%) reflects growing sophistication, not failure — teams that have
used agents extensively are more aware of their limitations.

**This playbook is loaded automatically** via the `agentic-playbook` skill
(`.claude/skills/agentic-playbook/`). The skill triggers when starting brainstorming,
writing-plans, or executing-plans sessions, providing the agent with the full workflow,
pitfalls, and subagent trigger rules.

**Keeping this playbook updated:** this document is one of the inputs provided to the agent
during brainstorming sessions. Update it whenever a new pitfall is discovered, a new
subagent or plugin is added, or the workflow changes. Stale playbook content leads to
repeated mistakes.

---

## Table of Contents

- [Design Principles](#design-principles)
  - [1. Start simple, add complexity only when needed](#1-start-simple-add-complexity-only-when-needed)
  - [2. Workflows vs. agents — know the difference](#2-workflows-vs-agents--know-the-difference)
  - [3. Orchestration over prompt engineering](#3-orchestration-over-prompt-engineering)
  - [4. Specialize agents, don't generalize](#4-specialize-agents-dont-generalize)
  - [5. Minimal freedom principle](#5-minimal-freedom-principle)
  - [6. Reflection — the agent reviews its own work](#6-reflection--the-agent-reviews-its-own-work)
  - [7. Observability from day one](#7-observability-from-day-one)
  - [8. Developers must understand the code they approve](#8-developers-must-understand-the-code-they-approve)
- [Governance](#governance)
  - [Mandatory human review](#mandatory-human-review)
  - [Attribution](#attribution)
  - [Agent autonomy boundaries](#agent-autonomy-boundaries)
  - [Audit trail](#audit-trail)
- [Setup (one-time)](#setup-one-time)
  - [VCS CLI (GitHub or GitLab)](#vcs-cli-github-or-gitlab)
  - [Verify prerequisites](#verify-prerequisites)
- [Prerequisites per feature](#prerequisites-per-feature)
- [Phase 1: Design (one session)](#phase-1-design-one-session)
  - [Step 0 — Choose the right level of complexity](#step-0--choose-the-right-level-of-complexity)
  - [Step 1 — Brainstorming](#step-1--brainstorming)
  - [Step 2 — Plan writing](#step-2--plan-writing)
- [Phase 2: Execution (separate session)](#phase-2-execution-separate-session)
  - [Self-review before human review (Reflection pattern)](#self-review-before-human-review-reflection-pattern)
  - [Dependency graph before deletion](#dependency-graph-before-deletion)
  - [Library documentation with context7](#library-documentation-with-context7)
  - [Configuration and environment variables](#configuration-and-environment-variables)
  - [After each task](#after-each-task)
- [Phase 3: Code Review](#phase-3-code-review)
  - [Step 1 — Create the MR](#step-1--create-the-mr)
  - [Step 2 — CI automated review](#step-2--ci-automated-review)
  - [Step 3 — Review CI feedback with Claude Code](#step-3--review-ci-feedback-with-claude-code)
  - [Step 4 — Additional Claude Code review](#step-4--additional-claude-code-review)
- [Phase 4: Validation](#phase-4-validation)
  - [Security scanning](#security-scanning)
  - [Local validation with Quarkus dev mode](#local-validation-with-quarkus-dev-mode)
  - [Integration tests — include adjacent systems](#integration-tests--include-adjacent-systems)
  - [Dev deployment](#dev-deployment)
  - [Before closing the feature](#before-closing-the-feature)
- [Metrics](#metrics)
  - [What to measure](#what-to-measure)
  - [How to use](#how-to-use)
- [Continuous Improvement](#continuous-improvement)
  - [Recording sessions with asciinema](#recording-sessions-with-asciinema)
  - [Session retrospective](#session-retrospective)
  - [Improvement cycle](#improvement-cycle)
- [Key Pitfalls](#key-pitfalls)
- [Portability Note](#portability-note)
- [References](#references)
- [Revision History](#revision-history)

---

## Design Principles

This playbook is grounded in principles from Anthropic's ["Building Effective Agents"](https://www.anthropic.com/research/building-effective-agents) research, QuantumBlack's (McKinsey) agentic workflow architecture, [Andrew Ng's agentic design patterns](https://www.deeplearning.ai/courses/agentic-ai/), and cross-industry consensus on agent design. These principles inform every phase of the workflow.

### 1. Start simple, add complexity only when needed

A single LLM call with the right tools often outperforms a multi-agent system. Before
reaching for parallel subagents or complex orchestration, verify that a simpler approach
cannot solve the problem. Complexity should be justified by measurable improvement, not
assumed superiority.

### 2. Workflows vs. agents — know the difference

- **Workflows** follow predefined orchestration: the sequence of steps is fixed, and the
  LLM executes within those constraints (e.g., this playbook's Phase 1 → 2 → 3 → 4 flow).
- **Agents** make LLM-driven decisions about which steps to take and in what order.

This playbook is a **workflow with agent capabilities at specific steps** — the overall
sequence is human-defined, but the agent has autonomy within each step (brainstorming
exploration, code generation, review interpretation). This matches the Anthropic
recommendation to use workflows as the primary structure and agents only where dynamic
decision-making adds value.

### 3. Orchestration over prompt engineering

Designing how agents interact — sequencing tasks, defining handoffs, structuring inputs and
outputs — matters more than crafting individual prompts. The plan document is the primary
orchestration artifact: it defines task order, dependencies, verification gates, and model
selection hints. Invest time in plan quality over prompt wording.

### 4. Specialize agents, don't generalize

Multiple focused agents outperform one general-purpose agent. This is why the workflow uses
distinct skills (`/brainstorming`, `/writing-plans`, `/executing-plans`,
`/requesting-code-review`) rather than a single "do everything" prompt. Each skill has a
narrow scope and specific outputs.

### 5. Minimal freedom principle

Give the system the smallest amount of autonomy that still delivers the outcome. Constrain
agent behavior through explicit instructions, verification gates, and human approval points.
Unconstrained agents drift from requirements, hallucinate implementation details, and make
architectural decisions that should be human-owned.

### 6. Reflection — the agent reviews its own work

[Reflection](https://www.deeplearning.ai/courses/agentic-ai/) is one of Andrew Ng's four
agentic design patterns: the agent critiques and revises its own output iteratively,
functioning as its own reviewer. In this workflow, reflection means:

- After generating code for a task, the agent reviews its output against the spec and plan
  before presenting it for human review
- The agent checks that its implementation addresses all acceptance criteria, not just the
  ones that are easiest to implement
- Self-review catches simple errors before they consume human review time

This is distinct from the reviewer subagent (Phase 3) — reflection is the implementing agent
checking its own work within the same step.

### 7. Observability from day one

Invest in monitoring, evaluation, and feedback loops from the start — not after problems
surface. In this workflow, observability means:

- Saving specs and plans as versioned artifacts (not just conversation context)
- Running reviewer subagents at each phase transition
- Checking service logs and database state after each task, not just test results
- Tracking pitfalls in this playbook so they compound into institutional knowledge
- Saving a brief "decisions and corrections" summary at the end of each execution session —
  which plan steps required human intervention and why
- Agent conversation summaries preserved alongside specs and plans for audit

### 8. Developers must understand the code they approve

AI-assisted development makes human expertise *more* critical, not less.
[Research indicates](https://eleks.com/blog/ai-sdlc-maturity-model/) that teams treating AI
as a way to reduce engineering investment risk declining stability, growing technical debt,
and compounding security risks.

In this workflow: reviewers should be able to explain *why* the agent chose an approach, not
just whether the code compiles and tests pass. When a reviewer cannot explain the agent's
implementation, that is a signal to slow down and investigate — not to approve and move on.

---

## Governance

Governance policies for AI-generated code ensure quality and accountability as the workflow
scales. These policies apply to all phases.

### Mandatory human review

The following types of changes **must** receive explicit human review before merge, regardless
of test results:
- Authentication and authorization logic
- Cryptographic operations and secret handling
- Database migration scripts and schema changes
- API contracts and public-facing response shapes
- Configuration changes that affect production environments
- Dependency additions or version changes

### Attribution

AI-generated code is attributed in commits using the `Co-Authored-By` convention. This
creates an audit trail and makes it possible to analyze the ratio of human-written to
AI-generated code over time.

### Agent autonomy boundaries

The agent **may** autonomously:
- Generate implementation code following the approved plan
- Run tests and fix compilation errors
- Create boilerplate, configuration, and scaffolding
- Suggest refactoring within the scope of the current task

The agent **may not** autonomously:
- Modify security-critical code without human approval
- Change the scope of work beyond the approved plan
- Delete production data or run destructive database operations
- Push code or create PRs/MRs without human confirmation
- Make architectural decisions not covered by the plan or existing ADRs

### Audit trail

The following artifacts must be preserved for each feature developed through this workflow:
- Generated spec (in `docs/superpowers/specs/`)
- Generated plan (in `docs/superpowers/plans/`)
- ADRs created during the design phase
- Code review findings and their dispositions

---

## Setup (one-time)

### VCS CLI (GitHub or GitLab)

A VCS CLI is used throughout this workflow for creating PRs/MRs, checking CI status,
and fetching review comments.

**GitHub** — install and authenticate the `gh` CLI:

```bash
gh auth login
```

**GitLab** — install the `glab` CLI and create a project-scoped token:

1. Go to the repository → **Settings → Access Tokens**
2. Create a token with scopes: `api`, role: Developer
3. Configure: `glab auth login --hostname gitlab.example.com --token <your-token>`

Restricting tokens to a single repository limits the blast radius if something goes wrong
during an agentic session (unintended PR/MR creation, comment on wrong PR/MR, etc.).

### Verify prerequisites

- Claude Code + superpowers plugin installed (`/using-superpowers` at session start)
- [context7 plugin](https://claude.com/plugins/context7) enabled — fetches current library
  and framework documentation during development (Quarkus, LangChain4j, CDI, etc.)
  instead of relying on training data that may be outdated
- [frontend-design plugin](https://claude.com/plugins/frontend-design) installed if the
  feature includes any web UI work — install with `/plugin` and run `/reload-plugins` before
  starting execution. A missing plugin discovered after implementation means rework.
- **All plugins referenced in the task or plan are installed and active.** Verify at
  the start of the execution session, not at AC-check time. Run `/reload-plugins` if recently
  added.
- Maven wrapper (`mvnw`) available, or Maven installed on the system
- `AGENTS.md` current
- [Harness engineering](docs/harness-engineering-guide.md) configured — pre-commit hooks
  enforce compilation, tests, formatting, and coding conventions automatically via the
  self-correction loop

---

## Prerequisites per feature

1. **A ticket must exist.** The ticket tracks the feature and provides the `PROJ-XXXX`
   identifier used in branch names, commit messages, and MR descriptions. Create one
   before starting.

2. **Gather architectural context.** If ADRs already exist for this feature, provide them as
   input. If the design is still open, the brainstorming phase will explore options and
   generate ADRs — but discuss the resulting decisions with the team before proceeding to
   execution. The agent cannot derive domain-specific constraints from the code alone;
   architectural context (ADRs, team input, or explicit domain knowledge) is required.

3. **Real input data available.** Collect actual sample data before the design session:
   actual API messages, real data files, and example records from adjacent systems. Field
   names and shapes in real payloads frequently differ from what documentation implies.

---

## Phase 1: Design (one session)

> **Goal:** the superpowers skills generate a self-contained spec and implementation plan
> that a fresh agent can execute without the design conversation context. The plan is the
> handoff artifact between sessions.

### Step 0 — Choose the right level of complexity

Before brainstorming, decide whether this feature actually needs the full playbook. Apply
the **start-simple principle** — use the lightest approach that delivers the outcome:

| Complexity level             | When to use                                                         | Approach                                                             |
| ---------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Single LLM call + tools**  | Well-understood change, one file or module, clear requirements      | Skip this playbook. Just ask Claude Code directly.                   |
| **Workflow (this playbook)** | Multi-file feature, cross-cutting concerns, design decisions needed | Follow the full Phase 1–4 flow below.                                |
| **Parallel subagents**       | Plan has 3+ independent tasks with no shared state                  | Use `/subagent-driven-development` during execution (Phase 2).       |

Most features belong in the middle row. Resist the temptation to use parallel subagents
for tasks that share state or have sequential dependencies — the coordination overhead
outweighs the speed gain.

### Step 1 — Brainstorming

The brainstorming skill drives a structured Q&A that explores requirements, edge cases, and
design decisions before producing any artifacts. It generates the spec as its output.

```
/brainstorming
```

Provide as input:
- The ticket (`PROJ-XXXX`) and a one-paragraph feature description
- The relevant ADRs
- Real input data (payload examples, data file samples, API response examples)
- This playbook

**Establish naming conventions early.** Agree on field name patterns and terminology before
schema design. Naming inconsistencies caught late cause multiple correction rounds.

**Show real data early.** Actual data files consistently uncover issues that spec reading
does not (missing fields, unexpected formats, tool name inconsistencies).

**Domain knowledge not in the codebase must be provided explicitly.** The agent cannot infer
system-specific constraints (product taxonomy, external API response shapes, platform message
formats, auth provider specifics) from the code.

At the end of the brainstorming session, ask the agent to save the generated spec:

```
Save the spec to docs/superpowers/specs/<date>-<ticket>-<short-title>.md
```

Then dispatch an automated spec review:

```
Dispatch a reviewer subagent to audit this spec for completeness and correctness.
```

Address all reviewer findings before proceeding.

### Step 2 — Plan writing

The writing-plans skill converts the spec into a sequenced implementation plan.

```
/writing-plans
```

The plan is generated by the agent from the spec. The plan is the primary **orchestration
artifact** — it matters more than any individual prompt. Each task includes: goal, exact
files to create/modify, key code snippets, and a verification step specifying which tests
to run. Tasks are sequenced so the foundation layer (models, schemas, database) is built
before the integration layer (services, workers, API).

The plan follows a **rule-based orchestration** pattern: the agent executes tasks, but the
plan (not the agent) defines sequencing, dependencies, and verification gates. This
separation keeps the human in control of architecture while delegating implementation to
the agent.

The plan includes model selection hints per task:

- **Opus**: service/business logic, cross-service integration, complex invariants
- **Sonnet**: mechanical tasks (boilerplate, health endpoints, schema definitions, K8s manifests)

Dispatch a reviewer on the generated plan:

```
Dispatch a reviewer subagent to audit this plan for gaps, missing dependencies,
and tasks that could cause regressions in adjacent systems.
```

**Create ADRs during the conversation, not after.** When a design decision emerges, capture
it immediately using `docs/ADR/ADR-template.md`. Context is freshest during the conversation.

Commit the generated spec, plan, and any new ADRs. Claude Code can handle git operations
(branching, committing, pushing) directly — just ask it to commit and push the changes.

---

## Phase 2: Execution (separate session)

> **Rule:** start a fresh session for execution. The design session exhausts the context
> window. The generated plan is the only handoff — it must be self-contained.

```
/executing-plans docs/superpowers/plans/<date>-<ticket>-<plan-name>.md
```

For plans with independent tasks:

```
/subagent-driven-development
```

### Self-review before human review (Reflection pattern)

After generating code for each task, the agent should review its own output before
presenting it for human review:

1. **Check against spec:** Does the implementation address all acceptance criteria listed in
   the spec, not just the ones that were easiest to implement?
2. **Check against plan:** Does the code match the plan's expected files, structure, and
   approach? Were any steps skipped?
3. **Check for hallucinations:** Do all referenced APIs, methods, and configuration properties
   actually exist? Verify imports compile.
4. **Check for completeness:** Are edge cases from the spec handled? Are error paths implemented,
   not just the happy path?

This self-review catches simple errors before they consume human review time. It is not a
substitute for human review — it is a filter that raises the quality floor.

### Dependency graph before deletion

```bash
grep -rl "<removed-name>" src/
./mvnw compile -q   # verify compilation after removal
```

### Library documentation with context7

The context7 plugin fetches current documentation for libraries and frameworks used in
this project. Use it when working with Quarkus, LangChain4j, CDI, RESTEasy, Hibernate,
or any other dependency — even if you think you know the API, training data may not reflect
recent changes.

### Configuration and environment variables

Trace configuration properties across layers explicitly. For any property or env var: verify
it is set in `application.properties` and any profile-specific config files
(`application-dev.properties`, etc.).

### After each task

```bash
./mvnw test -q
```

Explicitly confirm each plan step is complete. Do not assume completion — verify that the
step's outputs exist and its verification gate passes. Track any human corrections made
during the step for the execution summary.

---

## Phase 3: Code Review

### Step 1 — Create the MR

Ask Claude Code to create the PR/MR — it uses `gh pr create` (GitHub) or `glab mr create`
(GitLab) and generates the description from the branch diff, linking to the ticket
automatically.

For large PRs/MRs (50+ commits), the description should point reviewers to the spec, plan,
and feedback document; be explicit about deployment risk; and link to the ticket.

### Step 2 — CI automated review

The CI pipeline can run an AI code review tool automatically and post inline comments
on the PR/MR.

Before pushing, ensure `AGENTS.md` is updated if the feature changes architecture,
data flow, or schema.

### Step 3 — Review CI feedback with Claude Code

Once CI completes, fetch the review comments and use Claude Code to interpret and address
them:

```bash
# GitHub — fetch review comments
gh pr view <pr-id> --comments > /tmp/pr_comments.txt

# GitLab — fetch review comments
glab mr view <mr-id> --comments > /tmp/mr_comments.txt
```

Then in Claude Code:

```text
Read /tmp/pr_comments.txt. These are the AI code review comments from the CI pipeline.
For each finding: identify if it is blocking, advisory, or a false positive.
For blocking and advisory findings, propose a fix. For false positives, explain why
and draft a comment to add to the PR/MR.
```

Use the receiving-code-review skill to process the feedback with technical rigor:

```
/receiving-code-review
```

This ensures findings are verified against the actual code before being accepted, rather
than implemented blindly.

### Step 4 — Additional Claude Code review

Run a full independent review of the branch diff:

```
/requesting-code-review
```

This dispatches the `code-reviewer` subagent, covering security, correctness, and
consistency with project conventions — complementing the CI review which focuses on
architectural constraints.

---

## Phase 4: Validation

### Security scanning

Before merging, run static analysis and dependency vulnerability scanning on the codebase.
AI-generated code has a higher rate of security issues than human-written code — [research
indicates 40% of AI-generated code contains security vulnerabilities](https://eleks.com/blog/ai-sdlc-maturity-model/).

```bash
# SEC-01: SpotBugs static analysis — detects common bug patterns
./mvnw spotbugs:check -q

# SEC-02: OWASP Dependency-Check — fails build on CVEs with CVSS >= 7
./mvnw dependency-check:check -q

# SEC-03: CycloneDX SBOM generation — produces target/bom.json
./mvnw cyclonedx:makeAggregateBom -q
```

These three checks run automatically in CI (see `.github/workflows/ci.yml`), but can
also be run locally before opening a PR. They are intentionally excluded from the
pre-commit harness to keep the agent's self-correction loop fast.

### Local validation with Quarkus dev mode

Before running integration tests or deploying, validate the application locally:

```bash
# Start in dev mode with live reload
./mvnw quarkus:dev

# In a separate terminal, verify the application is healthy
curl -s http://localhost:8080/q/health
```

Common issues: missing config properties, CDI injection failures, missing dependencies,
port conflicts.

### Integration tests — include adjacent systems

```bash
./mvnw verify -q
```

Run the full test suite, not only the tests added for this feature. Changes to shared
infrastructure (configuration, CDI beans, REST endpoints) can break components that were
nominally "not changed."

### Dev deployment

Deploy to a dev environment and exercise the feature with real services. Inspect the
application logs directly — behavioral regressions only become visible with real data and
real traffic. Use Quarkus dev services where possible for local integration testing.

### Before closing the feature

- [ ] Application starts without errors in dev mode (`./mvnw quarkus:dev`)
- [ ] All tests pass (`./mvnw verify`)
- [ ] Security scanning passes (`./mvnw spotbugs:check`, `./mvnw dependency-check:check`)
- [ ] SBOM generated (`./mvnw cyclonedx:makeAggregateBom`)
- [ ] Business logic verified end-to-end (not just at unit test boundaries)
- [ ] REST endpoints return expected responses
- [ ] No silent failures in application logs
- [ ] Reviewer can explain the agent's implementation choices (skill atrophy check)
- [ ] Execution summary saved with decisions and corrections log
- [ ] Ticket updated and linked to the merged PR/MR

---

## Metrics

Track these metrics across features to assess the effectiveness of the agentic workflow
and identify improvement areas.

### What to measure

| Metric | Description | When to capture |
|--------|-------------|-----------------|
| **Human correction rate** | Number of human corrections per phase (design, execution, review) | End of each phase |
| **Plan step rework rate** | Percentage of plan steps that required rework or deviation | End of execution |
| **Defect introduction rate** | Defects found in AI-generated code during review and testing | End of review and validation |
| **Security finding rate** | Security issues found in AI-generated code by scanning or review | End of validation |
| **Time-to-merge** | Calendar time from design start to PR/MR merge | End of feature |
| **Review rejection rate** | Percentage of review cycles that require changes | End of review |

### How to use

- Compare metrics across features to identify which task types benefit most from agentic
  workflows and which need more human involvement
- A rising human correction rate may indicate the agent is being given tasks beyond its
  current capability — reduce scope or add more context
- A falling correction rate over time signals that the team's specifications, plans, and
  agent instructions are improving
- Use defect and security finding rates to calibrate trust levels and governance policies

---

## Continuous Improvement

The playbook improves through use. Record agentic development sessions, write brief
retrospectives, and feed findings back into this document. Without deliberate capture,
the same mistakes repeat across features.

### Recording sessions with asciinema

[asciinema](https://asciinema.org/) records terminal sessions as lightweight, text-based
files — ideal for Claude Code workflows. Recordings are searchable, replayable at any
speed, and far smaller than screen recordings.

**Setup:**

```bash
# Install (macOS)
brew install asciinema

# Authenticate (optional — for uploading to asciinema.org)
asciinema auth
```

**Recording a session:**

```bash
# Start recording before launching Claude Code
asciinema rec docs/sessions/<date>-<ticket>-<phase>.cast \
  --title "PROJ-1234 Phase 2 Execution" \
  --idle-time-limit 30

# Work normally — Claude Code, git, Maven commands, etc.
# Press Ctrl+D or type 'exit' to stop recording
```

**Naming convention:** `<date>-<ticket>-<phase>.cast`

- Example: `2026-04-18-PROJ-1234-design.cast`
- Example: `2026-04-18-PROJ-1234-execution.cast`

**Storage:** save `.cast` files in `docs/sessions/`. For sharing, upload to asciinema.org
or a self-hosted instance — the upload URL is returned immediately after `asciinema upload`.

**Practical tips:**

- `--idle-time-limit 30` caps idle gaps at 30 seconds — long thinking pauses don't bloat
  playback time
- For multi-hour sessions, record per phase (design, execution, review) rather than one
  continuous recording — shorter recordings are easier to review
- Add the `docs/sessions/*.cast` pattern to `.gitignore` if recordings are large; store
  only the retrospective documents and asciinema.org links in the repository

### Session retrospective

After each feature (or each phase, for complex features), write a brief retrospective.
The retrospective is the index into the recording — it tells you *where* to look, so you
don't have to replay hours of terminal output.

**Save to:** `docs/sessions/<date>-<ticket>-retrospective.md`

**Template:**

```markdown
# Retrospective: PROJ-1234 — <feature title>

**Date:** YYYY-MM-DD
**Phases recorded:** Design / Execution / Review (link to .cast or asciinema.org URL)

## What went well
- (what the agent handled correctly without intervention)

## Human corrections needed
- (where you had to intervene, what was wrong, approximate timestamp in recording)

## Post-merge issues
- (bugs or problems discovered after merge — the most valuable section for playbook improvement)

## Playbook improvements identified
- (specific changes to make to this playbook based on the above findings)
```

**When to write:** immediately after the session, while context is fresh. A 10-minute
retrospective written today is worth more than a detailed analysis written next week.

### Improvement cycle

```text
1. Record the agentic development session (asciinema)
2. Write the retrospective (immediately after)
3. Review the retrospective — identify recurring patterns across features
4. Update this playbook:
   - New pitfall? → add to the Key Pitfalls table
   - New governance rule needed? → add to Governance section
   - Phase workflow gap? → update the relevant Phase section
   - Metric insight? → refine the Metrics section
5. Update the Revision History with what changed and why
```

The goal is a feedback loop: each feature developed through this playbook should make the
next feature smoother. Retrospectives that identify the same issue twice signal a playbook
gap — the fix belongs in the document, not in tribal knowledge.

---

## Key Pitfalls

| Pitfall | Prevention |
| ------- | ---------- |
| Old code deleted without auditing features | Audit field-by-field parity before deletion |
| Config property missing in profile-specific files | Trace config across `application.properties` and profile variants (`-dev`, `-test`, `-prod`) |
| Tests mocked at boundary hid real integration bugs | At least one `@QuarkusTest` verifies real arguments flowing through the chain |
| Shared component removal broke other CDI beans | `grep -rl` + `./mvnw compile` before removing any shared component |
| Field name reused with different semantics in new code | Read old code and Javadoc — do not assume semantic equivalence from name alone |
| Design session exhausted context window before execution | Design and execution are always separate sessions; the generated plan must be self-contained |
| Required plugin not installed at execution start | Verify all plugins listed in the task are installed and active (`/reload-plugins`) before starting execution — not at AC-check time |
| ADRs written after implementation | Write ADRs during the conversation while the design context is fresh |
| Silent startup failures in dev mode | Check Quarkus dev mode console output after every restart; watch for CDI and config errors |
| Breaking API changes not caught locally | Run `./mvnw verify` locally before pushing breaking changes to REST endpoints or response shapes |
| Fabricated metrics in comments or documentation | If production data is unavailable, say so explicitly; do not invent authoritative-looking numbers |
| Subagents invoked only when human asks | Use mandatory trigger points; a PostToolUse hook can inject reminders automatically |
| Agent given too much autonomy too early | Start with single LLM + tools; escalate to multi-agent only when measurably better (see "minimal freedom principle") |
| Prompt tweaking instead of fixing orchestration | When output quality is poor, redesign task sequencing and input structure before rewriting prompts |
| Agent generates calls to non-existent APIs | Verify that all imported classes, methods, and API calls compile after each task — do not trust the agent's confidence that an API exists |
| Agent silently skips plan steps | Track task completion explicitly with verification gates, not by assumption; review the plan checklist at the end of each session |
| Agent invents framework config properties | Verify configuration properties against context7 documentation or the framework's official reference; do not accept unfamiliar properties without checking |
| Agent produces semantically incorrect business logic | Human review must verify domain correctness, not just compilation and test passage; tests can pass while the logic is wrong if the test was also agent-generated |
| Reviewer approves code they cannot explain | If the reviewer cannot articulate why the agent chose an approach, pause and investigate before approving — this is a skill atrophy signal |

---

## Portability Note

This playbook's structure is designed to be adaptable beyond Claude Code:

**Portable elements** (tool-agnostic):
- The four-phase workflow (Design → Execute → Review → Validate)
- All eight design principles
- Governance policies and autonomy boundaries
- The pitfalls table and metrics framework
- The prerequisite requirements (tickets, ADRs, real data)

**Claude Code-specific elements** (require adaptation for other tools):
- Slash commands (`/brainstorming`, `/writing-plans`, `/executing-plans`, etc.)
- Superpowers plugin and subagent dispatch
- context7 and frontend-design plugin references
- `Co-Authored-By` commit attribution format

When adapting this playbook to a different agent tool, preserve the portable elements and
replace the tool-specific elements with equivalents for the target platform.

---

## References

**Project docs:**

- [AGENTS.md](AGENTS.md) — project conventions and coding guidelines
- [AI Agent References](docs/ai-agent-references.md) — curated research and architecture guides that inform this playbook

**Foundational research:**

- [Building Effective Agents — Anthropic](https://www.anthropic.com/research/building-effective-agents) — workflows vs. agents distinction, start-simple principle, core architecture patterns
- [Anthropic Agent Cookbook](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents) — code examples for agent patterns
- [2026 Agentic Coding Trends Report — Anthropic](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf) — data-driven look at how coding agents reshape development
- [Agentic Workflows for Software Development — QuantumBlack/McKinsey](https://medium.com/quantumblack/agentic-workflows-for-software-development-dc8e64f4a79d) — rule-based orchestration engine pattern (agents execute, workflow manages sequencing)
- [2026 Guide to Agentic Workflow Architectures — Stack AI](https://www.stackai.com/blog/the-2026-guide-to-agentic-workflow-architectures) — minimal freedom principle, four core architectures
- [Andrew Ng's Four Agentic Design Patterns — DeepLearning.AI](https://www.deeplearning.ai/courses/agentic-ai/) — Reflection, Tool Use, Planning, Multi-Agent Collaboration
- [AI-Native Development vs. AI Agentic Development Workflows — Strategic Research Report](../ai-native-vs-agentic-development-report.md) — comparative analysis informing this enhanced version

**Industry governance and adoption:**

- [Agentic AI Enterprise Adoption Guide — Deloitte](https://www.deloitte.com/us/en/what-we-do/capabilities/applied-artificial-intelligence/articles/agentic-ai-enterprise-adoption-guide.html) — phased adoption, governance, and risk management
- [AI-SDLC Maturity Model — ELEKS](https://eleks.com/blog/ai-sdlc-maturity-model/) — 5 levels: Traditional → AI-Autonomous; security risk data
- [AI Tools for Every SDLC Phase: 2026 Guide — MetaCTO](https://www.metacto.com/blogs/mapping-ai-tools-to-every-phase-of-your-sdlc) — AEMI maturity assessment framework

**Plugins:**

- [context7](https://claude.com/plugins/context7) — live library documentation (Quarkus, LangChain4j, CDI, etc.)
- [superpowers](https://claude.com/plugins/superpowers) — brainstorming, writing-plans, executing-plans, code-review skills
- [frontend-design](https://claude.com/plugins/frontend-design) — production-grade web UI generation; required for any feature with a browser-facing component

---

## Revision History

### 2026-04-12 — Enhanced version based on strategic research report review

Reviewed the playbook against the [AI-Native Development vs. AI Agentic Development Workflows
strategic research report](../ai-native-vs-agentic-development-report.md) and incorporated
findings from industry research (Anthropic, McKinsey, Deloitte, ELEKS, Andrew Ng).

**Changes:**

- **New "Governance" section** — mandatory human review categories, agent autonomy boundaries,
  attribution policy, and audit trail requirements. Driven by Deloitte's adoption guide and
  ELEKS maturity model findings on security risks.
- **New "Metrics" section** — what to measure (human correction rate, defect rate, security
  findings, time-to-merge), when to capture, and how to use. Based on MetaCTO AEMI framework
  and McKinsey productivity measurement guidance.
- **New Design Principle 6: Reflection** — incorporated Andrew Ng's fourth agentic design
  pattern. The agent self-reviews its output against the spec before human review.
- **New Design Principle 8: Developers must understand the code they approve** — addresses
  skill atrophy risk identified in the ELEKS research (40% security vulnerability rate in
  AI-generated code).
- **Enhanced introduction** — added maturity level targeting (Level 3 Intentional) using
  AEMI/ELEKS frameworks, and trust-building guidance based on the Anthropic 2026 trust gap
  data (80% usage, 29% trust).
- **New "Self-review before human review" step** in Phase 2 — operationalizes the Reflection
  principle with a four-point checklist.
- **New "Security scanning" step** in Phase 4 — SpotBugs and OWASP Dependency-Check commands,
  driven by ELEKS finding that 40% of AI-generated code contains security issues.
- **Five new pitfalls** — agent generates calls to non-existent APIs, agent silently skips
  plan steps, agent invents framework config properties, agent produces semantically incorrect
  business logic, reviewer approves code they cannot explain.
- **Enhanced closing checklist** in Phase 4 — added security scanning, skill atrophy check,
  and execution summary items.
- **New "Portability Note"** — identifies which playbook elements are tool-agnostic vs.
  Claude Code-specific, per the report's recommendation to decouple from single LLM providers.
- **Expanded References** — added Andrew Ng's design patterns, the strategic research report,
  and industry governance sources (Deloitte, ELEKS, MetaCTO).

### 2026-04-11 — Aligned playbook with Quarkus/Java project

Adapted the playbook from a Python-based, multi-service project to match the actual
Quarkus/Java tech stack.

**Changes:**

- **Setup section** — replaced GitLab-only token setup with generic VCS CLI guidance
  (GitHub `gh` and GitLab `glab`); removed standalone issue tracker CLI section
- **Prerequisites** — replaced `.pre-commit-config.yaml` with Maven wrapper; replaced
  Python library references (FastAPI, SQLAlchemy, dbt, Alembic, Pydantic) with Quarkus,
  LangChain4j, CDI, RESTEasy, Hibernate
- **Phase 2** — replaced `python -m pytest` with `./mvnw test`; replaced `dbt compile`
  with `./mvnw compile`; replaced cross-service/K8s data flow with Quarkus config property
  tracing
- **Phase 3** — added GitHub `gh` commands alongside GitLab `glab`; generalized PR/MR
  terminology
- **Phase 4** — replaced podman compose validation with Quarkus dev mode; replaced Python
  E2E test commands with `./mvnw verify`; updated closing checklist for Java/Quarkus
- **Key Pitfalls** — removed Python/dbt/K8s-specific pitfalls; added Quarkus-specific
  pitfalls (CDI injection failures, `@QuarkusTest`, config profiles, dev mode console)
- **Created** `docs/ADR/ADR-template.md` — previously referenced but missing
- **Added** Maven wrapper (`mvnw`) — previously referenced in AGENTS.md but missing

### 2026-04-10 — Research-backed principles and architecture guidance

Improved the playbook with insights from [AI Agent References](docs/ai-agent-references.md),
covering Anthropic's "Building Effective Agents" research, QuantumBlack/McKinsey's agentic
workflow architecture, and Stack AI's architecture guide.

**Changes:**

- **New "Design Principles" section** (6 principles) added before Setup:
  1. Start simple, add complexity only when needed — from Anthropic's core advice
  2. Workflows vs. agents — explains this playbook is a workflow with agent capabilities at specific steps
  3. Orchestration over prompt engineering — task sequencing matters more than prompt wording
  4. Specialize agents, don't generalize — justifies distinct skills over a single prompt
  5. Minimal freedom principle — from Stack AI's architecture guide
  6. Observability from day one — from cross-source consensus
- **New "Step 0 — Choose the right level of complexity"** in Phase 1 — decision table for picking the lightest approach (single call vs. full playbook vs. parallel subagents)
- **Enhanced plan writing guidance** — explains the plan as a rule-based orchestration artifact (from the QuantumBlack/McKinsey pattern)
- **Two new pitfalls** — agent given too much autonomy too early; prompt tweaking instead of fixing orchestration
- **Expanded References section** — added all five foundational research sources with descriptions
