# How the Harness Works

A comprehensive guide to the harness engineering implementation in this project:
how each component works, how they connect, and how to use the system with examples.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Component Deep Dive](#component-deep-dive)
   - [Feedforward Controls](#feedforward-controls-guides)
   - [Feedback Controls](#feedback-controls-sensors)
4. [Hook System Internals](#hook-system-internals)
   - [Pre-Commit Harness](#1-pre-commit-harness)
   - [File Protection](#2-file-protection)
   - [Post-Edit Verification](#3-post-edit-verification)
5. [The 7 Automated Checks](#the-7-automated-checks)
6. [Self-Correction Loop](#self-correction-loop)
7. [Usage Examples](#usage-examples)
   - [Example 1: Adding a New REST Endpoint](#example-1-adding-a-new-rest-endpoint-happy-path)
   - [Example 2: Harness Catches and Corrects Violations](#example-2-harness-catches-and-corrects-violations)
   - [Example 3: Protected File Guardrail](#example-3-protected-file-guardrail)
8. [Customization Guide](#customization-guide)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This project implements **harness engineering** — the discipline of designing the
scaffolding around AI agents that makes them reliable and autonomous.

**Core principle:**

```
Agent = Model + Harness
```

The AI model (Claude, GPT, etc.) generates code. The harness verifies quality,
blocks bad commits, provides actionable feedback, and lets the agent self-correct
without human intervention.

**What this means in practice:** When an AI agent writes code and tries to commit,
the harness automatically runs 7 quality checks. If any check fails, the commit is
blocked and the agent receives a detailed error message explaining exactly what to
fix. The agent fixes the issues and retries. This loop continues until all checks
pass — no human needed.

---

## Architecture

```text
┌──────────────────────────────────────────────────────────────────────┐
│                         HARNESS ARCHITECTURE                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  FEEDFORWARD CONTROLS (prevent errors)                              │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐                │
│  │  CLAUDE.md   │  │  AGENTS.md  │  │ CHECKLIST.md │                │
│  │ Harness rules│  │ Dev guide + │  │ 7 check rules│                │
│  │ Self-correct │  │ harness eng │  │ with rule IDs│                │
│  │ protocol     │  │ section     │  │              │                │
│  └─────────────┘  └─────────────┘  └──────────────┘                │
│                                                                      │
│  FEEDBACK CONTROLS (detect + correct)                               │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  .claude/settings.json (hook wiring)                      │       │
│  │                                                           │       │
│  │  PreToolUse: Bash  ─────> pre-commit-harness.sh          │       │
│  │  PreToolUse: Edit  ─────> protect-files.sh               │       │
│  │  PostToolUse: Edit ─────> post-edit-verify.sh            │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                      │
│  BUILD TOOLS                                                        │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  pom.xml: Spotless Maven Plugin (Google Java Format AOSP) │       │
│  │  Maven Surefire: Unit tests                               │       │
│  │  Maven Compiler: Java 21 compilation                      │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Component Deep Dive

### Feedforward Controls (Guides)

These files are loaded into the AI agent's context at the start of every session.
They guide the agent's behavior **before** it writes code, reducing errors proactively.

#### CLAUDE.md — Harness Rules

**Location:** Project root

**When loaded:** Automatically by Claude Code at session start

**What it contains:**
- The 7 mandatory rules with their IDs (BUILD-01 through CONV-02)
- The **self-correction protocol** — step-by-step instructions for what the agent
  should do when a commit is blocked
- List of protected files the agent must not modify
- Build commands for quick reference
- Code conventions (Java 21, Quarkus, logging, testing)

**Why it matters:** CLAUDE.md is the highest-leverage file in the harness. It enters
every conversation and shapes every action the agent takes. Because the agent reads
these rules before writing code, many violations are prevented entirely.

#### AGENTS.md — Development Guidelines

**Location:** Project root

**What it adds:** The "Harness Engineering" section at the bottom explains:
- The `Agent = Model + Harness` concept
- Feedforward vs Feedback control types
- The self-correction loop with all 7 steps
- A table mapping each check ID to its command

**Why it matters:** AGENTS.md provides deeper context that helps the agent understand
*why* the rules exist, not just what they are. This understanding helps the agent
make better decisions in edge cases.

#### CHECKLIST.md — Verification Rules

**Location:** Project root

**What it contains:**
- All 7 rules with IDs, descriptions, and pass criteria
- Code examples showing correct vs incorrect patterns
- The violation handling flowchart
- Protected files list

**Why it matters:** This is the single source of truth for what "passing" means.
Both humans and AI agents reference this to understand the quality bar.

### Feedback Controls (Sensors)

These are executable scripts triggered by Claude Code's hook system. They run
automatically at specific points in the development workflow.

#### .claude/settings.json — Hook Wiring

This file connects Claude Code's lifecycle events to the hook scripts:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/pre-commit-harness.sh\""
        }]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.sh\""
        }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/post-edit-verify.sh\""
        }]
      }
    ]
  }
}
```

**How the matcher works:**
- `"Bash"` — fires on every Bash tool call (the script filters for `git commit`)
- `"Edit|Write"` — fires on every file edit or write operation

**How exit codes work:**
- `exit 0` — allow the operation to proceed
- `exit 2` — block the operation and show the error message to the agent

---

## Hook System Internals

### 1. Pre-Commit Harness

**File:** `.claude/hooks/pre-commit-harness.sh`

**Trigger:** PreToolUse on Bash tool (filtered to `git commit` commands only)

**How it works step by step:**

```text
Step 1: Read JSON input from Claude Code via stdin
        ┌─────────────────────────────────────────────────────┐
        │ {"tool_input":{"command":"git commit -m \"...\" "}} │
        └─────────────────────────────────────────────────────┘
                              │
Step 2: Extract the bash command using python3 JSON parser
                              │
Step 3: Guard clause — is this a "git commit" command?
        ├── No  → exit 0 immediately (allow non-commit commands)
        └── Yes → continue to checks
                              │
Step 4: Extract commit message from the -m flag
        Handles: -m "msg", -m 'msg', and heredoc patterns
                              │
Step 5: Run all 7 checks, collecting ALL failures
        ├── BUILD-01: ./mvnw compile -q
        ├── BUILD-02: ./mvnw test -q
        ├── BUILD-03: ./mvnw spotless:check -q
        ├── QUAL-01:  grep for System.out.print
        ├── QUAL-02:  grep for hardcoded secrets
        ├── CONV-01:  regex match on commit message
        └── CONV-02:  @Path classes vs *Test.java files
                              │
Step 6: Report results
        ├── All pass → exit 0 (commit proceeds)
        └── Any fail → exit 2 (commit blocked + error report)
```

**Key design decision — collect all failures:** The script does NOT stop at the
first failure. It runs every check and reports all failures at once. This means the
agent can fix everything in one pass instead of discovering failures one at a time
through repeated commit attempts.

**Key design decision — LLM-optimized error messages:** Each failure includes:
- The rule ID (e.g., `[FAIL] QUAL-01`)
- What went wrong (e.g., `System.out.println found in: TimeResource.java`)
- Exactly how to fix it (e.g., `Replace with org.jboss.logging.Logger`)
- A concrete code example

### 2. File Protection

**File:** `.claude/hooks/protect-files.sh`

**Trigger:** PreToolUse on Edit/Write tools

**How it works:**

```text
Step 1: Read JSON input, extract file_path from tool_input
Step 2: Normalize to a relative path within the project
Step 3: Check against the protected files list:
        - CLAUDE.md
        - CHECKLIST.md
        - .claude/settings.json
        - .claude/hooks/* (any file in the hooks directory)
Step 4: If match → exit 2 (block edit with explanation)
        If no match → exit 0 (allow edit)
```

**Why this matters:** Without file protection, an AI agent could "solve" a failing
check by modifying the harness rules themselves — removing the rule that blocks its
commit. The protection hook prevents this, ensuring the harness remains intact.

### 3. Post-Edit Verification

**File:** `.claude/hooks/post-edit-verify.sh`

**Trigger:** PostToolUse on Edit/Write tools

**How it works:**

```text
Step 1: Read JSON input, extract file_path
Step 2: Check if the edited file is a .java file
        ├── Not Java → exit 0 (skip)
        └── Java → continue
Step 3: Run ./mvnw compile -q (with 30s timeout)
Step 4: If compilation fails → print warning to stderr
        (advisory only — does not block the edit)
Step 5: exit 0 always
```

**Why this matters:** This provides **early feedback**. Instead of discovering
compilation errors only at commit time (after the agent has made multiple edits),
the agent gets a warning immediately after each Java file edit. This helps the agent
catch and fix issues incrementally.

---

## The 7 Automated Checks

### Build Rules

| ID | Check | Command | What It Catches |
|----|-------|---------|-----------------|
| BUILD-01 | Compilation | `./mvnw compile -q` | Syntax errors, missing imports, type mismatches, unresolved references |
| BUILD-02 | Tests | `./mvnw test` | Test failures, assertion errors, runtime exceptions, regression bugs |
| BUILD-03 | Formatting | `./mvnw spotless:check -q` | Inconsistent indentation, import ordering, code style violations |

### Code Quality Rules

| ID | Check | Detection Method | What It Catches |
|----|-------|-----------------|-----------------|
| QUAL-01 | No System.out | `grep -rl "System\.out\.print" src/main/java/` | Debug print statements that should use Logger |
| QUAL-02 | No secrets | `grep -rEl` with password/key patterns | Hardcoded passwords, API keys, tokens in source code |

### Convention Rules

| ID | Check | Detection Method | What It Catches |
|----|-------|-----------------|-----------------|
| CONV-01 | Commit format | Regex: `^(feat\|fix\|docs\|refactor\|test\|chore)(\(.+\))?: .+` | Non-standard commit messages like "added stuff" or "fix" |
| CONV-02 | Test coverage | Compare `@Path` classes to `*Test.java` files | REST endpoints without corresponding test files |

---

## Self-Correction Loop

This is the core innovation of the harness — a closed feedback loop that enables
autonomous development without human intervention.

```text
┌─────────────────────────────────────────────────────────────┐
│                    SELF-CORRECTION LOOP                      │
│                                                             │
│  ┌──────────────────────┐                                   │
│  │ 1. Agent writes code │                                   │
│  │    following CLAUDE.md│                                   │
│  │    conventions       │                                   │
│  └──────────┬───────────┘                                   │
│             │                                               │
│             v                                               │
│  ┌──────────────────────┐                                   │
│  │ 2. Agent runs        │                                   │
│  │    git commit -m "..." │                                 │
│  └──────────┬───────────┘                                   │
│             │                                               │
│             v                                               │
│  ┌──────────────────────┐                                   │
│  │ 3. PreToolUse hook   │                                   │
│  │    fires             │                                   │
│  │    pre-commit-harness│                                   │
│  │    runs 7 checks     │                                   │
│  └──────────┬───────────┘                                   │
│             │                                               │
│        ALL PASS?                                            │
│        /        \                                           │
│      Yes         No                                         │
│       │           │                                         │
│       v           v                                         │
│  ┌─────────┐ ┌──────────────────────┐                      │
│  │ exit 0  │ │ exit 2               │                      │
│  │ Commit  │ │ Commit BLOCKED       │                      │
│  │ proceeds│ │                      │                      │
│  │         │ │ Detailed error report │                      │
│  └─────────┘ │ with rule IDs and    │                      │
│              │ fix instructions     │                      │
│              └──────────┬───────────┘                      │
│                         │                                   │
│                         v                                   │
│              ┌──────────────────────┐                      │
│              │ 4. Agent reads error │                      │
│              │    and fixes ALL     │                      │
│              │    violations        │                      │
│              └──────────┬───────────┘                      │
│                         │                                   │
│                         └──────── back to step 2 ──────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Typical flow:**
- **Best case:** Agent follows CLAUDE.md rules, writes clean code, all 7 checks
  pass on first attempt. Commit goes through immediately.
- **Common case:** 1-2 checks fail (e.g., formatting + missing test). Agent fixes
  both issues and commits successfully on the second attempt.
- **Worst case:** Multiple issues. Agent may need 2-3 iterations, but the harness
  always provides the specific fixes needed.

---

## Usage Examples

### Example 1: Adding a New REST Endpoint (Happy Path)

This example shows the harness allowing a clean commit on the first attempt.

**User prompt to the AI agent:**

```
Add a /time endpoint that returns the current server time in ISO 8601 format.
```

**What the agent does (guided by CLAUDE.md):**

1. Creates `src/main/java/dev/tedwon/TimeResource.java`:

```java
package dev.tedwon;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import java.time.Instant;

import org.jboss.logging.Logger;

@Path("/time")
public class TimeResource {

    private static final Logger LOG = Logger.getLogger(TimeResource.class);

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String currentTime() {
        String now = Instant.now().toString();
        LOG.infof("Time requested: %s", now);
        return now;
    }
}
```

2. Creates `src/test/java/dev/tedwon/TimeResourceTest.java`:

```java
package dev.tedwon;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.RestAssured;
import org.junit.jupiter.api.Test;

import static org.hamcrest.CoreMatchers.notNullValue;

@QuarkusTest
class TimeResourceTest {

    @Test
    void testTimeEndpoint() {
        RestAssured.given()
                .when().get("/time")
                .then()
                .statusCode(200)
                .body(notNullValue());
    }
}
```

3. Runs `./mvnw spotless:apply` to format the code

4. Stages and commits:

```bash
git add src/main/java/dev/tedwon/TimeResource.java
git add src/test/java/dev/tedwon/TimeResourceTest.java
git commit -m "feat(time): add server time endpoint with ISO 8601 format"
```

**Harness output (all checks pass):**

```
HARNESS: Running BUILD-01 (compilation)...
HARNESS: Running BUILD-02 (tests)...
HARNESS: Running BUILD-03 (formatting)...
HARNESS: Running QUAL-01 (no System.out)...
HARNESS: Running QUAL-02 (no hardcoded secrets)...
HARNESS: Running CONV-01 (conventional commits)...
HARNESS: Running CONV-02 (test coverage)...

========================================
HARNESS: ALL 7/7 CHECKS PASSED
Commit allowed.
========================================
```

The commit proceeds. No human intervention needed.

---

### Example 2: Harness Catches and Corrects Violations

This example shows the self-correction loop in action — the harness blocks a bad
commit and the agent fixes the issues automatically.

**User prompt:**

```
Add a /greeting endpoint that takes a name parameter and returns a greeting.
```

**Agent's first attempt (with violations):**

`src/main/java/dev/tedwon/GreetingEndpoint.java`:

```java
package dev.tedwon;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/greeting")
public class GreetingEndpoint {

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String greet(@QueryParam("name") String name) {
        System.out.println("Greeting request for: " + name);  // VIOLATION: QUAL-01
        return "Hello, " + (name != null ? name : "World") + "!";
    }
}
```

The agent forgets to create a test file, uses System.out, and writes a bad commit message:

```bash
git commit -m "added greeting endpoint"
```

**Harness output (3 checks fail):**

```
HARNESS: Running BUILD-01 (compilation)...
HARNESS: Running BUILD-02 (tests)...
HARNESS: Running BUILD-03 (formatting)...
HARNESS: Running QUAL-01 (no System.out)...
HARNESS: Running QUAL-02 (no hardcoded secrets)...
HARNESS: Running CONV-01 (conventional commits)...
HARNESS: Running CONV-02 (test coverage)...

========================================
HARNESS: COMMIT BLOCKED
4/7 checks passed, 3 failed
========================================

[FAIL] QUAL-01: System.out.println found in: src/main/java/dev/tedwon/GreetingEndpoint.java
  -> Replace with org.jboss.logging.Logger.
  -> Example:
     private static final Logger LOG = Logger.getLogger(YourClass.class);
     LOG.info("your message");

[FAIL] CONV-01: Commit message 'added greeting endpoint' does not follow Conventional Commits format.
  -> Required: <type>(<scope>): <subject>
  -> Types: feat, fix, docs, refactor, test, chore
  -> Example: feat(greeting): add personalized greeting endpoint

[FAIL] CONV-02: Missing test files for REST endpoints: GreetingEndpoint
  -> Create corresponding *Test.java files with @QuarkusTest annotation.
  -> Example: src/test/java/dev/tedwon/TimeResourceTest.java

----------------------------------------
ACTION REQUIRED: Fix ALL [FAIL] items above, then retry the commit.
- For BUILD-03 (formatting): run './mvnw spotless:apply' then 'git add .'
- For QUAL-01 (System.out): replace with org.jboss.logging.Logger
- For CONV-01 (commit message): use format 'type(scope): subject'
========================================
```

**Agent self-corrects (guided by the error messages):**

1. Replaces `System.out.println` with Logger:

```java
import org.jboss.logging.Logger;

@Path("/greeting")
public class GreetingEndpoint {

    private static final Logger LOG = Logger.getLogger(GreetingEndpoint.class);

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String greet(@QueryParam("name") String name) {
        LOG.infof("Greeting request for: %s", name);
        return "Hello, " + (name != null ? name : "World") + "!";
    }
}
```

2. Creates `src/test/java/dev/tedwon/GreetingEndpointTest.java`:

```java
package dev.tedwon;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.RestAssured;
import org.junit.jupiter.api.Test;

import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
class GreetingEndpointTest {

    @Test
    void testGreetWithName() {
        RestAssured.given()
                .queryParam("name", "JBUG")
                .when().get("/greeting")
                .then()
                .statusCode(200)
                .body(is("Hello, JBUG!"));
    }

    @Test
    void testGreetWithoutName() {
        RestAssured.given()
                .when().get("/greeting")
                .then()
                .statusCode(200)
                .body(is("Hello, World!"));
    }
}
```

3. Retries with a proper commit message:

```bash
git add -A
git commit -m "feat(greeting): add personalized greeting endpoint"
```

**Harness output (all checks pass on second attempt):**

```
========================================
HARNESS: ALL 7/7 CHECKS PASSED
Commit allowed.
========================================
```

The commit proceeds. The agent self-corrected all 3 violations without human intervention.

---

### Example 3: Protected File Guardrail

This example shows the harness preventing the agent from modifying its own rules.

**Scenario:** The agent encounters a QUAL-01 failure and considers removing the rule
from CLAUDE.md instead of fixing the actual code.

**Agent tries to edit CLAUDE.md:**

```
Edit CLAUDE.md to remove the QUAL-01 rule about System.out
```

**Harness output (edit blocked):**

```
HARNESS: EDIT BLOCKED
File 'CLAUDE.md' is protected by the harness.
These files define the harness rules and cannot be modified by the AI agent.
If you need to change this file, ask the human operator for approval.
```

The edit is rejected. The agent must fix the actual code violation instead.

**Same protection applies to:**
- `CHECKLIST.md` — the agent cannot remove checks from the checklist
- `.claude/settings.json` — the agent cannot disable hooks
- `.claude/hooks/*` — the agent cannot modify hook scripts

---

## Customization Guide

### Adding a New Check

To add an 8th verification check:

1. **Define the rule in CHECKLIST.md** with a new ID (e.g., `[QUAL-03]`)

2. **Add the check to `.claude/hooks/pre-commit-harness.sh`:**

```bash
# =============================================================================
# CHECK 8: QUAL-03 — Your New Check
# =============================================================================
echo "HARNESS: Running QUAL-03 (your check)..." >&2
if your_check_command_here; then
    pass
else
    fail "QUAL-03" "Description of what failed.
  -> How to fix it.
  -> Example of correct code."
fi
```

3. **Update TOTAL_CHECKS** from 7 to 8:

```bash
TOTAL_CHECKS=8
```

4. **Add the rule to CLAUDE.md** so the agent knows about it proactively

### Adding a New Protected File

Edit `.claude/hooks/protect-files.sh` and add the filename to the `PROTECTED_FILES`
array:

```bash
PROTECTED_FILES=(
    "CLAUDE.md"
    "CHECKLIST.md"
    ".claude/settings.json"
    "your-new-protected-file.md"    # added
)
```

### Adjusting Check Strictness

Each check can be made stricter or more lenient:

- **BUILD-02 (Tests):** Change `./mvnw test -q` to `./mvnw verify -q` to include
  integration tests
- **QUAL-02 (Secrets):** Modify the `SECRET_PATTERNS` regex to catch more patterns
- **CONV-02 (Test coverage):** Extend to check `@RequestMapping` or other
  annotations beyond `@Path`

---

## Troubleshooting

### Hook Not Firing

**Symptom:** Commits go through without harness checks.

**Check:**
1. Verify `.claude/settings.json` has the `hooks` section
2. Verify hook scripts are executable: `ls -la .claude/hooks/*.sh`
3. Verify `python3` is available: `which python3`

### Hook Timeout

**Symptom:** First run takes too long.

**Fix:** Run `./mvnw compile` once manually to populate the Maven dependency cache.
Subsequent runs are fast (~10-15 seconds for all 7 checks).

### False Positives in QUAL-02

**Symptom:** QUAL-02 flags test data or configuration examples as hardcoded secrets.

**Fix:** The check scans `src/main/java/` and `src/main/resources/`. Test data in
`src/test/` is not scanned. If you need to exclude specific patterns, modify the
`SECRET_PATTERNS` regex in `pre-commit-harness.sh`.

### CONV-01 Fails with Heredoc Commit Messages

**Symptom:** Commit message extraction fails for complex heredoc patterns.

**Fix:** Use the simple `-m "message"` format for commit messages. The heredoc
parser handles basic cases but may not cover all variations.

---

## How It Connects to the Agentic Development Playbook

The harness engineering layer enhances the existing
[Agentic Development Playbook](../agentic-development-playbook.md) by
automating the **Execute phase** (Phase 2):

| Playbook Phase | Without Harness | With Harness |
|----------------|----------------|--------------|
| Phase 1: Design | Human-driven brainstorming | Same (no change) |
| Phase 2: Execute | Human reviews each step | Agent self-corrects via harness loop |
| Phase 3: Review | Human + CI review | Same, but fewer issues reach review |
| Phase 4: Validate | Manual testing | Same, but build/test issues caught earlier |

The harness doesn't replace human judgment for design decisions, architecture, or
security-critical code. It automates the mechanical quality checks that would
otherwise require human intervention at every commit.

---

## References

- [OpenAI — Harness Engineering](https://openai.com/index/harness-engineering/)
- [OpenAI — Unlocking the Codex Harness](https://openai.com/index/unlocking-the-codex-harness/)
- [Anthropic — Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Anthropic — Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Awesome Harness Engineering](https://github.com/ai-boost/awesome-harness-engineering)
- [Claude Code Hooks Documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
