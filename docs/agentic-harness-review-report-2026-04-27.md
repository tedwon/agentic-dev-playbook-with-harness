# Agentic Development + Harness Engineering Review

**Review date:** 2026-04-27  
**Analysis performed by:** Codex  
**Presentation context:** JBUG Korea online meetup, 2026-04-29 21:00, Korean talk  
**Scope:** repository structure, `agentic-development-playbook.md`, Claude/Cursor rules, hooks, CI, Maven verification, demo readiness  
**Remediation status:** Findings 1-3 were fixed after this review on 2026-04-27.

## Executive Verdict

이 프로젝트는 **AI-assisted Agentic Development with Harness Engineering**을 데모/교육 목적으로는 충분히 구현하고 있다. 핵심 구성요소가 실제로 존재한다.

- Human-in-the-loop 4단계 workflow: Design -> Execute -> Review -> Validate
- Agent handoff artifacts: spec + implementation plan
- Feedforward controls: `AGENTS.md`, `CLAUDE.md`, `CHECKLIST.md`, Cursor rules
- Feedback controls: Claude hooks, standard git hooks, CI jobs, Maven checks
- Self-correction loop: commit attempt -> automated checks -> actionable failures -> retry
- Quarkus demo application and tests

다만 발표에서 “완전 자율 개발”처럼 말하면 과장으로 들릴 수 있다. 더 정확한 표현은:

> 이 프로젝트는 **human-approved workflow 안에서 agent가 execution loop를 self-correcting 방식으로 수행하도록 만든 harness demo**다.

발표 전에 몇 가지 불일치와 demo-critical issue를 정리하면 훨씬 설득력이 좋아진다.

## Verification Performed

Passed:

- `./mvnw test -q` passed: 11 Surefire tests.
- `./mvnw spotless:check -q` passed.
- `./mvnw verify -q` passed after remediation and now runs Failsafe integration tests by default.
- `./mvnw -DskipITs=false verify -q` passed before remediation: 6 Failsafe integration tests.
- `bash demo/harness-check.sh "docs(review): dry run harness"` passed 7/7.
- Claude hook dry run with `git commit -m "docs(review): dry run harness"` passed 7/7.
- `./mvnw spotbugs:check -q` passed.
- `./mvnw cyclonedx:makeAggregateBom -q` passed and generated `target/bom.json` / `target/bom.xml`.
- `hooks/commit-msg` blocks invalid commit messages and passes valid Conventional Commit messages.

Not run:

- `./mvnw dependency-check:check` was not run because it is CI-oriented, NVD/API-key dependent, and can be slow or flaky without the configured cache/key.

Environment note:

- The current checkout does **not** have `hooks/pre-commit` or `hooks/commit-msg` installed into `.git/hooks`; only Git sample hooks are present. The hook scripts are available in the repository, but this checkout needs `./scripts/install-git-hooks.sh` before relying on native git hook enforcement.

## What Works Well

1. **The conceptual architecture is strong.** The repo clearly demonstrates `Agent = Model + Harness`: rules and documentation guide behavior, while hooks and CI provide feedback.

2. **The playbook flow is mostly natural for humans.** It starts with a ticket, real data, ADR/design context, branch creation, brainstorming, spec, plan, execution, review, and validation. That is understandable for a meetup audience.

3. **The execution harness is real, not only documentation.** The Claude hook and demo harness both run compilation, tests, formatting, no-`System.out`, secret scan, commit-message validation, and REST test-file mapping.

4. **The demo feature maps well to the playbook.** `docs/superpowers/specs/2026-04-18-DEMO-001-quote-api.md` and `docs/superpowers/plans/2026-04-18-DEMO-001-quote-api.md` are good artifacts to show Design -> Plan -> Execute.

5. **Security validation exists.** SpotBugs, Dependency-Check, and CycloneDX are configured and CI-only placement is reasonable for fast local iteration.

## Findings

### 1. High: Worktree flow can fail because the same feature branch is already checked out

**Status:** Fixed on 2026-04-27. The playbook now tells the user to switch the primary checkout
back to `main` before creating the execution worktree, and to clean up with
`git worktree remove <path>`.

**Original evidence:** `agentic-development-playbook.md` told the human to create and stay on `feat/PROJ-1234-short-description` during Phase 1, then said Phase 2 creates a worktree “on the feature branch.”

**Why it matters:** Git normally does not allow the same branch to be checked out in two worktrees at once. If the main checkout is still on the feature branch after design, `git worktree add ../worktree feat/PROJ-1234-short-description` will fail.

**Resolution:** The playbook now clarifies this flow:

- After committing design artifacts, switch the main checkout back to `main`, then create the execution worktree on the feature branch.
- Remove worktrees with `git worktree remove <path>` to avoid stale worktree metadata.

### 2. High: Documentation says `./mvnw verify` is full verification, but integration tests are skipped by default

**Status:** Fixed on 2026-04-27. The Maven default now sets `skipITs=false`, so
`./mvnw verify` runs the Failsafe `*IT` tests.

**Original evidence:** `pom.xml` set `<skipITs>true</skipITs>`. The docs described `./mvnw verify` as unit + integration verification, but `./mvnw -DskipITs=false verify -q` was required to run `GreetingResourceIT` and `QuoteResourceIT`.

**Why it matters:** In a harness engineering talk, “validation gate” accuracy matters. If the audience checks the repo and sees `verify` skips `*IT`, trust drops.

**Resolution:** `pom.xml` now sets `<skipITs>false</skipITs>`, so `./mvnw verify` runs integration tests by default. CI should still add an explicit full verification job if the project wants CI to cover Failsafe `*IT` tests, not just `./mvnw test`.

### 3. High: `demo/harness-check.sh` reports “COMMIT BLOCKED” but exits with status 0

**Status:** Fixed on 2026-04-27. The demo harness now exits `0` when all checks pass and
`2` when it reports a blocked commit.

**Original evidence:** Running `bash demo/harness-check.sh` without a commit message printed a CONV-01 failure and “HARNESS: COMMIT BLOCKED”, but returned `exit_status=0`.

**Why it matters:** For a demo harness, a blocked check should fail at the process level. Otherwise scripts, CI, or live demonstrations can accidentally treat a failure as success.

**Resolution:** The script now exits `0` in the success branch and `2` in the failure branch, matching the Claude hook behavior.

### 4. Medium: Local portable git hooks exist but are not installed in this checkout

**Evidence:** `.git/hooks` currently contains only sample hooks. `scripts/install-git-hooks.sh` exists and symlinks `hooks/pre-commit` and `hooks/commit-msg`, but it has not been run in this checkout.

**Why it matters:** During a live demo, a normal `git commit` may not trigger the portable git hooks unless the installer was run first. Claude Code hooks may still work in Claude, but the “any git client” story depends on installation.

**Recommendation:** Before the meetup, run:

```bash
./scripts/install-git-hooks.sh
```

Then verify:

```bash
ls -l .git/hooks/pre-commit .git/hooks/commit-msg
```

### 5. Medium: Secret scan misses common unquoted `.properties` secrets

**Evidence:** The QUAL-02 regex requires a double-quoted value. It catches `token="abc123"` but misses common property formats like `token=abc123` and `app.password=supersecret`.

**Why it matters:** The docs say hardcoded `password=`, `apiKey=`, `secret=`, and `token=` patterns are blocked, but the implementation only catches a narrower Java-style subset.

**Recommendation:** Expand the pattern or split Java and properties scanning. For `.properties`, catch unquoted values while allowing `${ENV_VAR}` placeholders.

### 6. Medium: Protected-file documentation and actual protection differ

**Evidence:** Cursor rules say `.cursor/rules/*` and `hooks/*` are protected, but the Claude `protect-files.sh` hook only blocks `CLAUDE.md`, `CHECKLIST.md`, `.claude/settings.json`, and `.claude/hooks/*`.

**Why it matters:** The project claims harness guardrails protect harness files, but some harness files can still be edited through normal agent edit tools.

**Recommendation:** Align one of these:

- Broaden `protect-files.sh` to include `.cursor/rules/*`, `hooks/*`, and possibly `scripts/install-git-hooks.sh`.
- Or narrow the docs so they only claim the files actually protected by the hook.

### 7. Medium: CI does not exactly mirror the local 7 checks

**Evidence:** CI says it runs the same 7 checks as the local hook. But CONV-01 checks PR titles only and is skipped on push events. Native git checks commit messages through `hooks/commit-msg`; Claude hook checks extracted commit messages.

**Why it matters:** This is understandable from a GitHub workflow perspective, but the current wording is too absolute.

**Recommendation:** Reword CI documentation to: “CI mirrors build, quality, and structural checks, and checks PR title convention on PRs.” If commit-message enforcement on push is required, add a commit range validation job.

### 8. Low: `post-edit-verify.sh` uses `timeout`, which is absent on default macOS

**Evidence:** `command -v timeout` returned no command in this environment. The hook uses `timeout 30 ./mvnw compile -q`.

**Why it matters:** On macOS, Java edits can produce false “Compilation failed” warnings even when Maven would compile.

**Recommendation:** Use a portable fallback:

- `gtimeout` if coreutils is installed
- plain `./mvnw compile -q` if no timeout command exists
- or a small Python timeout wrapper

### 9. Low: README references missing Korean playbook file

**Evidence:** README project structure lists `agentic-development-playbook-ko.md`, but that file does not exist.

**Why it matters:** Because the talk is in Korean, this missing file is more visible. It may make attendees think the Korean playbook exists when it does not.

**Recommendation:** Either add the Korean translation or remove the README entry before the presentation.

### 10. Low: Messaging sometimes overstates autonomy

**Evidence:** README and AGENTS describe “autonomous AI development with minimal human intervention,” while the playbook correctly emphasizes human-in-the-loop design, review, semantic validation, and explicit approval.

**Why it matters:** For a technical audience, the stronger and safer claim is not “fully autonomous development,” but “autonomous execution and self-correction inside human-controlled workflow gates.”

**Recommendation:** Use the nuanced version in the presentation and align README wording later.

## Playbook Flow Review

The playbook is mostly complete and natural:

1. Decide whether the feature needs the full playbook.
2. Create a ticket and feature branch.
3. Gather ADRs, real data, and constraints.
4. Run brainstorming to produce a spec.
5. Review the spec.
6. Convert the spec into an implementation plan.
7. Review the plan.
8. Start a fresh execution session.
9. Execute inside a worktree.
10. Run harness gates and self-review.
11. Create PR/MR.
12. Process CI and review feedback.
13. Run validation, security checks, logs, and end-to-end checks.
14. Save retrospective/metrics and improve the playbook.

The remaining flow gaps are:

- Add an explicit **human approval gate** after plan review and before execution.
- Specify when a demo may use a lightweight `DEMO-001` ticket instead of a real issue tracker ticket.

## Recommended Fixes Before Wednesday Demo

Completed on 2026-04-27:

1. Fixed the `./mvnw verify` vs `-DskipITs=false verify` issue by running integration tests by default.
2. Fixed `demo/harness-check.sh` so blocked results return non-zero.
3. Updated the worktree section with exact guidance that avoids the checked-out-branch conflict.

Remaining priority order:

1. Install local git hooks with `./scripts/install-git-hooks.sh` before the live demo.
2. Remove or add the missing `agentic-development-playbook-ko.md` reference.
3. Prepare one Korean slide that says: “완전 자율 개발이 아니라, human-in-the-loop workflow + autonomous self-correction loop.”

## Korean Talk Framing

Recommended Korean explanation:

> 이 프로젝트의 핵심은 AI에게 모든 결정을 맡기는 것이 아니라, 사람이 설계와 승인 지점을 잡고, 에이전트가 그 안에서 구현과 검증 루프를 반복하도록 하네스를 만든 것입니다. 즉, 사람은 방향을 잡고, 에이전트는 실행하며, 하네스는 실수를 빠르게 감지해서 자기 교정을 가능하게 합니다.

Good demo narrative:

1. Show the playbook: Design -> Execute -> Review -> Validate.
2. Show the spec and plan artifacts.
3. Show one bad-code scenario or demo harness failure.
4. Show actionable harness error output.
5. Show the corrected 7/7 pass.
6. End with limits: human review, semantic correctness, security scanning, real data validation.

Demo caution:

- Do not run multiple Maven/Quarkus test commands at the same time; Quarkus test mode can collide on port `8081`.
- Have the recorded GIFs ready as fallback.
- Say explicitly which checks are local-fast checks and which are CI/Phase-4 checks.

## Final Assessment

**Presentation readiness:** Good, with a few fixable accuracy issues.  
**Harness implementation:** Real and demonstrable, but not fully aligned across docs, hooks, and CI.  
**Playbook quality:** Strong structure and good human flow, with worktree and validation-command clarifications needed.  
**Most important message for JBUG Korea:** this is a practical pattern for controlling AI coding agents through workflow, guardrails, automated checks, and human approval, not a claim that agents can safely own the whole SDLC alone.
