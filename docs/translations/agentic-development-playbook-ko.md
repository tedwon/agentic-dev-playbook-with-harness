<!-- This is a Korean translation for human reference only.
     The authoritative version is agentic-development-playbook.md.
     AI agents should NOT use this file for workflow guidance. -->

# Humans steer. Agents execute. - Agentic Development Playbook

| | |
| --- | --- |
| **Version** | v0.4 |
| **Last updated** | 2026-04-23 |
| **Status** | Living document — 실제 실무 경험을 반영하여 지속적으로 업데이트해요 |

> 이 playbook은 version 관리되고 tag가 지정되어 project 간 혼동을 방지해요.
> 새로운 engagement를 시작하기 전에 항상 최신 version을 사용하고 있는지 확인하세요.
>
> **"Humans steer. Agents execute."** — [OpenAI, Harness Engineering](https://openai.com/index/harness-engineering/)

이 project에서 Claude Code와 superpowers plugin을 사용하여 AI 기반 feature 개발을 수행하는
guide예요.

**사용 시점:** 새로운 feature를 개발할 때 — design이 확정된 경우(기존 ADR이 있는 경우)나
아직 열려 있는 경우(brainstorming 중에 architectural decision을 탐색하고 합의하는 경우 —
skill이 process의 일부로 ADR을 생성할 수 있어요) 모두 해당해요. 예시:
- Business logic과 validation이 포함된 새로운 REST endpoint 추가
- External service integration (예: LLM provider, message broker)
- Data model 재설계 — brainstorming 과정에서 design을 탐색하고 합의

**사용하지 않을 때:** 작은 단독 fix나 bug fix의 경우.

**Target maturity level:** 이 playbook은 [AEMI (MetaCTO)](https://www.metacto.com/blogs/mapping-ai-tools-to-every-phase-of-your-sdlc)
또는 [ELEKS](https://eleks.com/blog/ai-sdlc-maturity-model/) maturity scale에서 **Level 3
(Intentional)**에 해당하는 team을 위해 설계되었어요 — 기존 CI/CD pipeline이 있고 AI coding tool
사용 경험이 있는 team이에요. Level 1-2에 해당하는 team은 full playbook을 채택하기 전에
copilot 방식의 completion과 chat 기반 assistance 같은 더 간단한 AI 지원 workflow부터 시작해야 해요.

**이것은 human-in-the-loop workflow이며, 완전한 autonomous workflow가 아니에요.** Agent가 spec,
plan, code를 생성하지만, human이 design decision을 주도하고, domain knowledge를 제공하고,
실제 data로 검증하고, semantic mismatch를 포착하고, 각 phase를 진행하기 전에 승인해요.
Design 단계에서만 여러 번의 human correction이 필요한 것이 일반적이며, 모든 test가 통과한
후에도 human의 database 검사를 통해서만 발견된 critical bug가 있었어요.

**점진적으로 trust를 구축하세요.** Low-risk이면서 잘 이해된 task부터 agent에게 맡기세요.
측정된 성공 이후에만 scope을 확장하세요. Trust가 위반되었을 때 agent autonomy를 줄일 수 있는
권한을 유지하세요. Trust signal을 추적하세요 — review rejection rate, agent가 생성한 code의
post-merge defect, 그리고 phase별 human correction 빈도를 확인하세요. 업계 전반의
[trust gap](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf?hsLang=en)
(사용률 80%, trust 29%)은 실패가 아닌 점점 정교해지는 것을 반영해요 — agent를 광범위하게
사용한 team일수록 agent의 한계를 더 잘 인식하고 있어요.

**이 playbook은 자동으로 load돼요** — `agentic-playbook` skill
(`.claude/skills/agentic-playbook/`)을 통해서요. Brainstorming, writing-plans, 또는
executing-plans session을 시작할 때 trigger되며, agent에게 전체 workflow, pitfall, subagent
trigger rule을 제공해요.

**이 playbook을 최신 상태로 유지하기:** 이 문서는 brainstorming session 중에 agent에게
제공되는 input 중 하나예요. 새로운 pitfall이 발견되거나, 새로운 subagent나 plugin이
추가되거나, workflow가 변경될 때마다 업데이트하세요. 오래된 playbook content는 반복적인
실수로 이어져요.

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
  - [Step 0 — Create a feature branch](#step-0--create-a-feature-branch)
  - [Step 1 — Choose the right level of complexity](#step-1--choose-the-right-level-of-complexity)
  - [Step 2 — Brainstorming](#step-2--brainstorming)
  - [Step 3 — Plan writing](#step-3--plan-writing)
- [Phase 2: Execution (separate session)](#phase-2-execution-separate-session)
  - [Step 0 — Create an isolated worktree](#step-0--create-an-isolated-worktree)
  - [Step 1 — Execute the plan](#step-1--execute-the-plan)
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

이 playbook은 Anthropic의 ["Building Effective Agents"](https://www.anthropic.com/research/building-effective-agents) 연구, QuantumBlack(McKinsey)의 agentic workflow architecture, [Andrew Ng의 agentic design pattern](https://www.deeplearning.ai/courses/agentic-ai/), 그리고 agent design에 대한 업계 전반의 합의에 기반하고 있어요. 이 원칙들은 workflow의 모든 phase에 적용돼요.

### 1. Start simple, add complexity only when needed

적절한 tool을 갖춘 단일 LLM call이 multi-agent system보다 나은 성능을 보이는 경우가 많아요.
Parallel subagent나 복잡한 orchestration을 사용하기 전에, 더 간단한 접근 방식으로 문제를
해결할 수 없는지 확인하세요. Complexity는 측정 가능한 개선으로 정당화되어야 하며, 우월하다고
가정해서는 안 돼요.

### 2. Workflows vs. agents — know the difference

- **Workflow**는 미리 정의된 orchestration을 따라요: step의 순서가 고정되어 있고, LLM은
  그 제약 조건 내에서 실행해요 (예: 이 playbook의 Phase 1 → 2 → 3 → 4 flow).
- **Agent**는 어떤 step을 어떤 순서로 수행할지 LLM이 결정해요.

이 playbook은 **특정 step에서 agent 기능을 갖춘 workflow**예요 — 전체 순서는 human이
정의하지만, 각 step 내에서 agent가 autonomy를 가져요 (brainstorming 탐색, code 생성,
review 해석). 이것은 workflow를 주요 구조로 사용하고 dynamic한 의사결정이 가치를
더하는 곳에서만 agent를 사용하라는 Anthropic의 권고와 일치해요.

### 3. Orchestration over prompt engineering

Agent 간의 상호작용을 설계하는 것 — task 순서 지정, handoff 정의, input과 output 구조화 —
이 개별 prompt를 작성하는 것보다 더 중요해요. Plan document가 주요 orchestration artifact예요:
task 순서, dependency, verification gate, model 선택 hint를 정의해요. Prompt 문구보다
plan 품질에 시간을 투자하세요.

### 4. Specialize agents, don't generalize

여러 개의 focused된 agent가 하나의 general-purpose agent보다 나은 성능을 보여요. 이것이
workflow에서 하나의 "모든 것을 하는" prompt 대신 각각의 skill (`/brainstorming`,
`/writing-plans`, `/executing-plans`, `/requesting-code-review`)을 사용하는 이유예요.
각 skill은 좁은 scope과 specific한 output을 가지고 있어요.

### 5. Minimal freedom principle

결과를 달성하면서도 가능한 최소한의 autonomy를 system에 부여하세요. 명시적인 instruction,
verification gate, human approval point를 통해 agent behavior를 제약하세요. 제약 없는
agent는 requirement에서 벗어나고, implementation detail을 hallucinate하며, human이 소유해야
할 architectural decision을 내려요.

### 6. Reflection — the agent reviews its own work

[Reflection](https://www.deeplearning.ai/courses/agentic-ai/)은 Andrew Ng의 네 가지
agentic design pattern 중 하나예요: agent가 자신의 output을 반복적으로 비판하고 수정하며,
자체 reviewer 역할을 해요. 이 workflow에서 reflection은 다음을 의미해요:

- 각 task의 code를 생성한 후, agent가 human review에 제출하기 전에 spec과 plan에 대해
  자체적으로 output을 review해요
- Agent가 구현하기 가장 쉬운 것들뿐만 아니라, 모든 acceptance criteria를 implementation이
  충족하는지 확인해요
- Self-review는 human review 시간을 소모하기 전에 단순한 error를 포착해요

이것은 reviewer subagent (Phase 3)와 다른 개념이에요 — reflection은 같은 step 내에서
implementing agent가 자신의 작업을 점검하는 것이에요.

### 7. Observability from day one

문제가 발생한 후가 아니라, 처음부터 monitoring, evaluation, feedback loop에 투자하세요.
이 workflow에서 observability는 다음을 의미해요:

- Spec과 plan을 version 관리되는 artifact로 저장 (단순한 conversation context가 아닌)
- 각 phase 전환 시 reviewer subagent 실행
- 각 task 후에 test 결과뿐만 아니라 service log와 database 상태 확인
- 이 playbook에서 pitfall을 tracking하여 조직적 지식으로 축적
- 각 execution session 종료 시 간략한 "decisions and corrections" 요약 저장 —
  어떤 plan step에서 human 개입이 필요했는지와 그 이유
- Spec과 plan과 함께 agent conversation summary를 audit용으로 보존

### 8. Developers must understand the code they approve

AI 기반 개발은 human expertise를 덜 중요하게 만드는 것이 아니라, *더* 중요하게 만들어요.
[연구에 따르면](https://eleks.com/blog/ai-sdlc-maturity-model/) AI를 engineering 투자를
줄이는 방법으로 취급하는 team은 stability 감소, technical debt 증가, 그리고 복합적인
security risk에 직면해요.

이 workflow에서: reviewer는 code가 compile되고 test가 통과하는지뿐만 아니라, agent가 *왜*
특정 접근 방식을 선택했는지 설명할 수 있어야 해요. Reviewer가 agent의 implementation을
설명할 수 없다면, 그것은 승인하고 넘어가는 것이 아니라 속도를 늦추고 조사해야 한다는
signal이에요.

---

## Governance

AI가 생성한 code에 대한 governance policy는 workflow가 확장됨에 따라 품질과 accountability를
보장해요. 이 policy는 모든 phase에 적용돼요.

### Mandatory human review

다음 유형의 변경사항은 test 결과와 관계없이 merge 전에 **반드시** 명시적인 human review를
받아야 해요:
- Authentication과 authorization logic
- Cryptographic operation과 secret handling
- Database migration script과 schema 변경
- API contract과 public-facing response shape
- Production environment에 영향을 미치는 configuration 변경
- Dependency 추가 또는 version 변경

### Attribution

AI가 생성한 code는 `Co-Authored-By` convention을 사용하여 commit에서 attribution돼요.
이를 통해 audit trail이 생성되고, 시간 경과에 따른 human이 작성한 code 대 AI가 생성한
code의 비율 분석이 가능해져요.

### Agent autonomy boundaries

Agent가 autonomous하게 **할 수 있는 것:**
- 승인된 plan에 따라 implementation code 생성
- Test 실행 및 compilation error 수정
- Boilerplate, configuration, scaffolding 생성
- 현재 task scope 내에서 refactoring 제안

Agent가 autonomous하게 **할 수 없는 것:**
- Human approval 없이 security-critical code 수정
- 승인된 plan을 넘어서 작업 scope 변경
- Production data 삭제 또는 destructive database operation 실행
- Human 확인 없이 code push 또는 PR/MR 생성
- Plan이나 기존 ADR에서 다루지 않은 architectural decision

### Audit trail

이 workflow를 통해 개발된 각 feature에 대해 다음 artifact를 보존해야 해요:
- 생성된 spec (`docs/superpowers/specs/`에 위치)
- 생성된 plan (`docs/superpowers/plans/`에 위치)
- Design phase에서 생성된 ADR
- Code review 결과와 그 처리 내역

---

## Setup (one-time)

### VCS CLI (GitHub or GitLab)

VCS CLI는 이 workflow 전반에서 PR/MR 생성, CI status 확인, review comment 가져오기에
사용돼요.

**GitHub** — `gh` CLI를 설치하고 인증하세요:

```bash
gh auth login
```

**GitLab** — `glab` CLI를 설치하고 project-scoped token을 생성하세요:

1. Repository → **Settings → Access Tokens**으로 이동
2. Scope: `api`, role: Developer로 token 생성
3. 설정: `glab auth login --hostname gitlab.example.com --token <your-token>`

Token을 single repository로 제한하면 agentic session 중 문제가 발생했을 때
(의도하지 않은 PR/MR 생성, 잘못된 PR/MR에 comment 등) blast radius를 줄여요.

### Verify prerequisites

- Claude Code + superpowers plugin 설치됨 (session 시작 시 `/using-superpowers`)
- [context7 plugin](https://claude.com/plugins/context7) 활성화됨 — training data에
  의존하지 않고 개발 중에 최신 library 및 framework documentation을 가져옴
  (Quarkus, LangChain4j, CDI 등)
- [frontend-design plugin](https://claude.com/plugins/frontend-design) 설치됨 (feature에
  web UI 작업이 포함된 경우) — `/plugin`으로 설치하고 execution 시작 전에
  `/reload-plugins` 실행. Implementation 후에 plugin이 없다는 것을 발견하면 rework이 필요해요.
- **Task 또는 plan에 참조된 모든 plugin이 설치되고 활성 상태여야 해요.** AC-check 시점이
  아니라 execution session 시작 시 확인하세요. 최근 추가한 경우 `/reload-plugins`를
  실행하세요.
- Maven wrapper (`mvnw`)가 사용 가능하거나, Maven이 system에 설치됨
- `AGENTS.md`가 최신 상태
- [Harness engineering](docs/harness-engineering-guide.md) 설정됨 — pre-commit hook이
  self-correction loop를 통해 compilation, test, formatting, coding convention을
  자동으로 enforce

---

## Prerequisites per feature

1. **Ticket이 존재해야 해요.** Ticket은 feature를 추적하고 branch name, commit message,
   MR description에 사용되는 `PROJ-XXXX` identifier를 제공해요. 시작 전에 ticket을
   생성하세요.

2. **Architectural context를 수집하세요.** 이 feature에 대한 ADR이 이미 존재하면 input으로
   제공하세요. Design이 아직 열려 있으면 brainstorming phase에서 option을 탐색하고 ADR을
   생성해요 — 하지만 execution으로 넘어가기 전에 결과적인 decision을 team과 논의하세요.
   Agent는 code만으로 domain-specific한 constraint를 도출할 수 없어요; architectural
   context (ADR, team input, 또는 명시적인 domain knowledge)가 필요해요.

3. **실제 input data가 준비되어야 해요.** Design session 전에 실제 sample data를
   수집하세요: 실제 API message, 실제 data file, 인접 system의 example record.
   실제 payload의 field name과 shape은 documentation이 암시하는 것과 자주 달라요.

---

## Phase 1: Design (one session)

> **Goal:** superpowers skill이 design conversation context 없이도 fresh agent가
> 실행할 수 있는 self-contained spec과 implementation plan을 생성해요. Plan이 session 간의
> handoff artifact예요.

### Step 0 — Create a feature branch

Design 작업을 시작하기 전에 `main`에서 feature branch를 생성하세요. 이 feature의 모든
artifact — spec, plan, ADR, implementation code — 는 이 branch에 속해요.

```bash
git checkout -b feat/PROJ-1234-short-description
```

**Naming convention:** `feat/<ticket>-<short-description>` (예:
`feat/PROJ-1234-add-task-api`). Prerequisite step의 ticket ID를 사용하세요. 이 branch는
네 phase 모두를 거쳐요 — Phase 1에서 design artifact가 commit되고, Phase 2에서
implementation code가, Phase 3에서 이 branch로 PR/MR이 생성돼요.

### Step 1 — Choose the right level of complexity

Brainstorming 전에, 이 feature가 실제로 full playbook이 필요한지 결정하세요.
**Start-simple principle**을 적용하세요 — 결과를 달성하는 가장 가벼운 접근 방식을 사용하세요:

| Complexity level             | 사용 시점                                                         | 접근 방식                                                             |
| ---------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Single LLM call + tools**  | 잘 이해된 변경, 하나의 file이나 module, 명확한 requirement      | 이 playbook을 건너뛰세요. Claude Code에 직접 요청하세요.                   |
| **Workflow (this playbook)** | Multi-file feature, cross-cutting concern (예: logging, security, error handling), design decision 필요 | 아래의 full Phase 1–4 flow를 따르세요. Execution은 isolation을 위해 git worktree를 사용해요. |
| **Parallel subagents**       | Plan에 shared state 없이 3개 이상의 independent task가 있을 때                  | Execution (Phase 2) 중에 `/subagent-driven-development`를 사용하세요.       |

대부분의 feature는 가운데 행에 해당해요. State를 공유하거나 sequential dependency가 있는
task에 parallel subagent를 사용하려는 유혹을 억제하세요 — coordination overhead가
speed gain을 초과해요.

### Step 2 — Brainstorming

Brainstorming skill은 artifact를 생성하기 전에 requirement, edge case, design decision을
탐색하는 구조화된 Q&A를 주도해요. Output으로 spec을 생성해요.

```
/brainstorming
```

Input으로 제공할 것:
- Ticket (`PROJ-XXXX`)과 한 paragraph 분량의 feature description
- 관련 ADR
- 실제 input data (payload example, data file sample, API response example)
- 이 playbook

**Naming convention을 일찍 확립하세요.** Schema design 전에 field name pattern과
terminology에 합의하세요. 늦게 발견된 naming 불일치는 여러 차례의 correction round를
유발해요.

**실제 data를 일찍 보여주세요.** 실제 data file은 spec을 읽는 것만으로는 발견하지 못하는
issue를 일관되게 드러내요 (누락된 field, 예상치 못한 format, tool name 불일치).

**Codebase에 없는 domain knowledge는 명시적으로 제공해야 해요.** Agent는 code에서
system-specific한 constraint (product taxonomy, external API response shape, platform
message format, auth provider 세부사항)를 추론할 수 없어요.

Brainstorming session 마무리 시, agent에게 생성된 spec을 저장하도록 요청하세요:

```
Save the spec to docs/superpowers/specs/<date>-<ticket>-<short-title>.md
```

그런 다음 automated spec review를 dispatch하세요:

```
Dispatch a reviewer subagent to audit this spec for completeness and correctness.
```

진행하기 전에 모든 reviewer 발견 사항을 해결하세요.

### Step 3 — Plan writing

Writing-plans skill은 spec을 순서화된 implementation plan으로 변환해요.

```
/writing-plans
```

Plan은 agent가 spec에서 생성해요. Plan이 주요 **orchestration artifact**예요 — 어떤
개별 prompt보다 더 중요해요. 각 task에는 goal, 생성/수정할 정확한 file, 주요 code snippet,
그리고 어떤 test를 실행할지 지정하는 verification step이 포함돼요. Task는 foundation
layer (model, schema, database)가 integration layer (service, worker, API) 전에
구축되도록 순서가 정해져요.

Plan은 **rule-based orchestration** pattern을 따라요: agent가 task를 실행하지만,
plan이 (agent가 아닌) sequencing, dependency, verification gate를 정의해요. 이 분리는
implementation을 agent에게 위임하면서 human이 architecture를 통제할 수 있게 해요.

Plan에는 task별 model 선택 hint가 포함돼요:

- **Opus**: service/business logic, cross-service integration, 복잡한 invariant
- **Sonnet**: mechanical task (boilerplate, health endpoint, schema definition, K8s manifest)

생성된 plan에 reviewer를 dispatch하세요:

```
Dispatch a reviewer subagent to audit this plan for gaps, missing dependencies,
and tasks that could cause regressions in adjacent systems.
```

**ADR은 conversation 중에 만드세요, 이후가 아니라.** Design decision이 나오면 즉시
`docs/ADR/ADR-template.md`를 사용하여 기록하세요. Context는 conversation 중에 가장
생생해요.

생성된 spec, plan, 그리고 새로운 ADR을 Step 0에서 만든 feature branch에 commit하세요.
Claude Code가 git operation (commit, push)을 직접 처리할 수 있어요 — 변경사항을 commit하고
push하도록 요청하기만 하면 돼요.

Phase 2를 시작하기 전에, primary checkout을 feature branch에서 다른 곳으로 전환하세요,
보통 `main`으로 돌아가요. Git은 일반적으로 같은 branch를 두 개의 worktree에서 동시에
checkout할 수 없으므로, execution worktree가 feature branch를 사용하려면 해당 branch가
free 상태여야 해요.

```bash
git switch main
git pull --ff-only
```

---

## Phase 2: Execution (separate session)

> **Rule:** execution을 위해 fresh session을 시작하세요. Design session은 context window를
> 소진해요. 생성된 plan이 유일한 handoff예요 — self-contained여야 해요.

### Step 0 — Create an isolated worktree

Plan을 실행하기 전에, agent의 작업을 main checkout에서 격리하기 위해 **git worktree**를
생성하세요. 이렇게 하면 broken build, corrupted state, 또는 half-finished 작업이
working directory에 영향을 미치는 것을 방지해요.

```text
/using-git-worktrees
```

Worktree는 자체 branch가 checkout된 별도의 directory를 생성해요. 모든 agent 작업 —
code 생성, compilation, testing — 은 이 sandbox 안에서 이루어져요. Main checkout은
건드리지 않고 안정적으로 유지돼요.

**Agentic workflow에서 worktree가 중요한 이유:**

- **Main branch 보호:** agent가 buggy code를 작성하거나 iteration loop 중에 build를
  깨트려도 primary workspace는 영향받지 않아요
- **Parallel 작업:** agent가 worktree에서 iterate하는 동안 main checkout에서 계속
  작업할 수 있어요
- **Clean merge gate:** worktree에서 모든 harness check가 통과한 후에만 code가
  merge back돼요
- **Easy cleanup:** agent의 작업이 구제 불가능하면 `git worktree remove <path>`로
  worktree를 제거하세요 — `git reset --hard`나 수동 cleanup이 필요 없어요

**Worktree workflow:**

```text
1. Main checkout이 feature branch에 있지 않은지 확인 (예: `git switch main`)
2. Worktree 생성:  /using-git-worktrees (worktree에서 feature branch를 checkout)
3. Plan 실행:     /executing-plans (agent가 전적으로 worktree 안에서 작업)
4. 검증:           모든 harness check가 worktree에서 통과 (BUILD-01..CONV-02)
5. Merge:          모든 check가 통과한 후에만 feature branch를 merge back
6. Cleanup:        `git worktree remove <path>`로 worktree 제거
```

### Step 1 — Execute the plan

```text
/executing-plans docs/superpowers/plans/<date>-<ticket>-<plan-name>.md
```

Independent task가 있는 plan의 경우:

```text
/subagent-driven-development
```

### Self-review before human review (Reflection pattern)

각 task의 code를 생성한 후, agent는 human review에 제출하기 전에 자체 output을 review해야
해요:

1. **Spec 대비 확인:** implementation이 구현하기 가장 쉬운 것들뿐만 아니라, spec에
   나열된 모든 acceptance criteria를 충족하나요?
2. **Plan 대비 확인:** code가 plan의 예상 file, structure, approach와 일치하나요?
   건너뛴 step은 없나요?
3. **Hallucination 확인:** 참조된 모든 API, method, configuration property가 실제로
   존재하나요? Import가 compile되는지 확인하세요.
4. **Completeness 확인:** spec의 edge case가 처리되었나요? Happy path뿐만 아니라
   error path도 구현되었나요?

이 self-review는 human review 시간을 소모하기 전에 단순한 error를 포착해요. Human
review를 대체하는 것이 아니라 — 품질 하한선을 높이는 filter예요.

### Dependency graph before deletion

```bash
grep -rl "<removed-name>" src/
./mvnw compile -q   # 제거 후 compilation 확인
```

### Library documentation with context7

context7 plugin은 이 project에서 사용하는 library와 framework의 최신 documentation을
가져와요. Quarkus, LangChain4j, CDI, RESTEasy, Hibernate 또는 기타 dependency로 작업할
때 사용하세요 — API를 알고 있다고 생각해도, training data가 최근 변경사항을 반영하지
않을 수 있어요.

### Configuration and environment variables

Configuration property를 layer 전반에 걸쳐 명시적으로 추적하세요. 모든 property나
env var에 대해: `application.properties`와 profile-specific config file
(`application-dev.properties` 등)에 설정되어 있는지 확인하세요.

### After each task

```bash
./mvnw test -q
```

각 plan step이 완료되었는지 명시적으로 확인하세요. 완료를 가정하지 마세요 — step의 output이
존재하고 verification gate가 통과하는지 확인하세요. Step 중에 이루어진 human correction을
execution summary에 기록하세요.

---

## Phase 3: Code Review

### Step 1 — Create the MR

Claude Code에 PR/MR 생성을 요청하세요 — `gh pr create` (GitHub) 또는 `glab mr create`
(GitLab)를 사용하고 branch diff에서 description을 생성하여 ticket을 자동으로 link해요.

대규모 PR/MR (50+ commit)의 경우, description은 reviewer를 spec, plan, feedback document로
안내해야 하고; deployment risk를 명시하고; ticket에 link해야 해요.

### Step 2 — CI automated review

CI pipeline은 AI code review tool을 자동으로 실행하고 PR/MR에 inline comment를 게시할 수
있어요.

Push 전에, feature가 architecture, data flow, 또는 schema를 변경하는 경우 `AGENTS.md`가
업데이트되었는지 확인하세요.

### Step 3 — Review CI feedback with Claude Code

CI가 완료되면, review comment를 가져와서 Claude Code로 해석하고 처리하세요:

```bash
# GitHub — review comment 가져오기
gh pr view <pr-id> --comments > /tmp/pr_comments.txt

# GitLab — review comment 가져오기
glab mr view <mr-id> --comments > /tmp/mr_comments.txt
```

그런 다음 Claude Code에서:

```text
Read /tmp/pr_comments.txt. These are the AI code review comments from the CI pipeline.
For each finding: identify if it is blocking, advisory, or a false positive.
For blocking and advisory findings, propose a fix. For false positives, explain why
and draft a comment to add to the PR/MR.
```

Receiving-code-review skill을 사용하여 feedback을 기술적 엄밀함으로 처리하세요:

```
/receiving-code-review
```

이렇게 하면 finding이 맹목적으로 수용되지 않고, 실제 code에 대해 검증된 후에
수락돼요.

### Step 4 — Additional Claude Code review

Branch diff의 전체 independent review를 실행하세요:

```
/requesting-code-review
```

이것은 `code-reviewer` subagent를 dispatch하여 security, correctness, project convention과의
일관성을 검토해요 — architectural constraint에 초점을 맞추는 CI review를 보완해요.

---

## Phase 4: Validation

### Security scanning

Merge 전에 codebase에 static analysis와 dependency vulnerability scanning을 실행하세요.
AI가 생성한 code는 human이 작성한 code보다 security issue 비율이 더 높아요 — [연구에 따르면
AI가 생성한 code의 40%가 security vulnerability를 포함해요](https://eleks.com/blog/ai-sdlc-maturity-model/).

```bash
# SEC-01: SpotBugs static analysis — 일반적인 bug pattern 감지
./mvnw spotbugs:check -q

# SEC-02: OWASP Dependency-Check — CVSS >= 7인 CVE에서 build 실패
./mvnw dependency-check:check -q

# SEC-03: CycloneDX SBOM generation — target/bom.json 생성
./mvnw cyclonedx:makeAggregateBom -q
```

이 세 가지 check는 CI에서 자동 실행되지만 (`.github/workflows/ci.yml` 참고), PR을
열기 전에 로컬에서도 실행할 수 있어요. Agent의 self-correction loop를 빠르게
유지하기 위해 의도적으로 pre-commit harness에서 제외되었어요.

### Local validation with Quarkus dev mode

Integration test를 실행하거나 배포하기 전에, application을 로컬에서 검증하세요:

```bash
# Live reload로 dev mode 시작
./mvnw quarkus:dev

# 별도 terminal에서 application이 healthy한지 확인
curl -s http://localhost:8080/q/health
```

일반적인 문제: 누락된 config property, CDI injection failure, 누락된 dependency,
port conflict.

### Integration tests — include adjacent systems

```bash
./mvnw verify -q
```

이 feature를 위해 추가된 test뿐만 아니라 전체 test suite를 실행하세요. 공유 infrastructure
(configuration, CDI bean, REST endpoint)에 대한 변경은 명목상 "변경되지 않은"
component를 깨뜨릴 수 있어요.

### Dev deployment

Dev environment에 배포하고 실제 service로 feature를 실행해 보세요. Application log를
직접 확인하세요 — behavioral regression은 실제 data와 실제 traffic에서만 가시적으로
드러나요. 가능하면 local integration testing에 Quarkus dev service를 활용하세요.

### Before closing the feature

- [ ] Application이 dev mode에서 error 없이 시작됨 (`./mvnw quarkus:dev`)
- [ ] 모든 test 통과 (`./mvnw verify`)
- [ ] Security scanning 통과 (`./mvnw spotbugs:check`, `./mvnw dependency-check:check`)
- [ ] SBOM 생성됨 (`./mvnw cyclonedx:makeAggregateBom`)
- [ ] Business logic이 end-to-end로 검증됨 (unit test boundary에서만이 아닌)
- [ ] REST endpoint가 예상 response를 반환
- [ ] Application log에 silent failure 없음
- [ ] Reviewer가 agent의 implementation 선택을 설명할 수 있음 (skill atrophy check)
- [ ] Merge 후 git worktree가 정리됨 (stale worktree directory 없음)
- [ ] Decision과 correction log가 포함된 execution summary 저장됨
- [ ] Ticket이 업데이트되고 merged PR/MR에 link됨

---

## Metrics

이 metric을 feature 전반에 걸쳐 추적하여 agentic workflow의 효과를 평가하고 개선
영역을 식별하세요.

### What to measure

| Metric | Description | 측정 시점 |
|--------|-------------|-----------------|
| **Human correction rate** | Phase별 human correction 횟수 (design, execution, review) | 각 phase 종료 시 |
| **Plan step rework rate** | Rework이나 deviation이 필요했던 plan step의 비율 | Execution 종료 시 |
| **Defect introduction rate** | Review와 testing 중 AI가 생성한 code에서 발견된 defect | Review 및 validation 종료 시 |
| **Security finding rate** | Scanning 또는 review에서 AI가 생성한 code의 security issue | Validation 종료 시 |
| **Time-to-merge** | Design 시작부터 PR/MR merge까지의 calendar time | Feature 종료 시 |
| **Review rejection rate** | 변경이 필요했던 review cycle의 비율 | Review 종료 시 |

### How to use

- Feature 전반의 metric을 비교하여 어떤 task type이 agentic workflow에서 가장 큰 이점을
  얻고 어떤 것이 더 많은 human 개입이 필요한지 식별하세요
- Human correction rate가 증가하면 agent가 현재 능력을 넘어선 task를 받고 있다는 것을
  나타낼 수 있어요 — scope을 줄이거나 더 많은 context를 추가하세요
- 시간이 지남에 따라 correction rate가 감소하면 team의 specification, plan, agent
  instruction이 개선되고 있다는 signal이에요
- Defect와 security finding rate를 사용하여 trust level과 governance policy를
  보정하세요

---

## Continuous Improvement

Playbook은 사용을 통해 개선돼요. Agentic development session을 녹화하고, 간략한
retrospective를 작성하고, 발견 사항을 이 문서에 반영하세요. 의도적인 기록 없이는
같은 실수가 feature 전반에 걸쳐 반복돼요.

### Recording sessions with asciinema

[asciinema](https://asciinema.org/)는 terminal session을 가벼운 text 기반 file로
녹화해요 — Claude Code workflow에 이상적이에요. Recording은 검색 가능하고, 어떤 속도로든
재생 가능하며, screen recording보다 훨씬 작아요.

**Setup:**

```bash
# Install (macOS)
brew install asciinema

# Authenticate (선택 — asciinema.org에 upload하는 경우)
asciinema auth
```

**Session 녹화:**

```bash
# Claude Code 실행 전에 recording 시작
asciinema rec docs/sessions/<date>-<ticket>-<phase>.cast \
  --title "PROJ-1234 Phase 2 Execution" \
  --idle-time-limit 30

# 정상적으로 작업 — Claude Code, git, Maven command 등
# Ctrl+D를 누르거나 'exit'을 입력하여 recording 중지
```

**Naming convention:** `<date>-<ticket>-<phase>.cast`

- Example: `2026-04-18-PROJ-1234-design.cast`
- Example: `2026-04-18-PROJ-1234-execution.cast`

**Storage:** `.cast` file을 `docs/sessions/`에 저장하세요. 공유하려면 asciinema.org나
self-hosted instance에 upload하세요 — `asciinema upload` 직후 upload URL이 반환돼요.

**실용적 tip:**

- `--idle-time-limit 30`은 idle gap을 30초로 제한해요 — 긴 thinking pause가 playback
  시간을 늘리지 않아요
- Multi-hour session의 경우, 하나의 연속 recording 대신 phase별 (design, execution,
  review)로 녹화하세요 — 짧은 recording이 review하기 더 쉬워요
- Recording이 큰 경우 `docs/sessions/*.cast` pattern을 `.gitignore`에 추가하세요;
  repository에는 retrospective document와 asciinema.org link만 저장하세요

### Session retrospective

각 feature (또는 복잡한 feature의 경우 각 phase) 후에 간략한 retrospective를 작성하세요.
Retrospective는 recording의 index예요 — 시간의 terminal output을 전부 재생하지 않아도
*어디*를 봐야 하는지 알려줘요.

**저장 위치:** `docs/sessions/<date>-<ticket>-retrospective.md`

**Template:**

```markdown
# Retrospective: PROJ-1234 — <feature title>

**Date:** YYYY-MM-DD
**Phases recorded:** Design / Execution / Review (link to .cast or asciinema.org URL)

## What went well
- (agent가 intervention 없이 올바르게 처리한 것)

## Human corrections needed
- (개입이 필요했던 부분, 무엇이 잘못되었는지, recording에서의 대략적인 timestamp)

## Post-merge issues
- (merge 후 발견된 bug나 문제 — playbook 개선에 가장 가치 있는 section)

## Playbook improvements identified
- (위 발견 사항을 바탕으로 이 playbook에 할 구체적인 변경)
```

**작성 시점:** session 직후, context가 생생할 때. 오늘 작성하는 10분짜리 retrospective가
다음 주에 작성하는 상세한 분석보다 더 가치 있어요.

### Improvement cycle

```text
1. Agentic development session 녹화 (asciinema)
2. Retrospective 작성 (직후에)
3. Retrospective review — feature 전반에 걸친 반복 pattern 식별
4. 이 playbook 업데이트:
   - 새로운 pitfall? → Key Pitfalls table에 추가
   - 새로운 governance rule 필요? → Governance section에 추가
   - Phase workflow gap? → 해당 Phase section 업데이트
   - Metric insight? → Metrics section 개선
5. 변경 사항과 이유를 Revision History에 업데이트
```

목표는 feedback loop예요: 이 playbook을 통해 개발된 각 feature가 다음 feature를 더
매끄럽게 만들어야 해요. 같은 issue를 두 번 식별하는 retrospective는 playbook gap을
signal해요 — 수정은 tribal knowledge가 아니라 이 문서에 있어야 해요.

---

## Key Pitfalls

| Pitfall | Prevention |
| ------- | ---------- |
| Old code가 feature audit 없이 삭제됨 | 삭제 전에 field별 parity를 audit하세요 |
| Config property가 profile-specific file에 누락됨 | `application.properties`와 profile variant (`-dev`, `-test`, `-prod`) 전반에 걸쳐 config를 추적하세요 |
| Boundary에서 mock된 test가 실제 integration bug를 숨김 | 최소 하나의 `@QuarkusTest`가 chain을 통해 실제 argument가 흐르는지 검증하세요 |
| Shared component 제거가 다른 CDI bean을 깨뜨림 | 공유 component 제거 전에 `grep -rl` + `./mvnw compile` |
| 새 code에서 다른 semantics로 field name이 재사용됨 | Old code와 Javadoc을 읽으세요 — name만으로 semantic equivalence를 가정하지 마세요 |
| Design session이 execution 전에 context window를 소진 | Design과 execution은 항상 별도 session이에요; 생성된 plan은 self-contained여야 해요 |
| Execution 시작 시 required plugin이 설치되지 않음 | AC-check 시점이 아니라 execution 시작 전에 task에 나열된 모든 plugin이 설치되고 활성 상태인지 확인하세요 (`/reload-plugins`) |
| Implementation 후에 ADR이 작성됨 | Design context가 생생할 때 conversation 중에 ADR을 작성하세요 |
| Dev mode에서 silent startup failure | 매번 재시작 후 Quarkus dev mode console output을 확인하세요; CDI와 config error를 주시하세요 |
| 로컬에서 잡히지 않은 breaking API change | REST endpoint나 response shape에 breaking change를 push하기 전에 `./mvnw verify`를 로컬에서 실행하세요 |
| Comment나 documentation에 fabricated metric | Production data를 사용할 수 없으면 명시적으로 말하세요; 권위 있어 보이는 숫자를 만들어내지 마세요 |
| Human이 요청할 때만 subagent가 호출됨 | Mandatory trigger point를 사용하세요; PostToolUse hook이 자동으로 reminder를 inject할 수 있어요 |
| Agent에게 너무 일찍 너무 많은 autonomy를 부여 | Single LLM + tool부터 시작하세요; 측정 가능하게 더 나은 경우에만 multi-agent로 확장하세요 ("minimal freedom principle" 참고) |
| Orchestration 수정 대신 prompt tweaking | Output 품질이 낮으면 prompt를 다시 작성하기 전에 task sequencing과 input structure를 재설계하세요 |
| Agent가 존재하지 않는 API 호출을 생성 | 각 task 후에 import된 모든 class, method, API call이 compile되는지 확인하세요 — API가 존재한다는 agent의 확신을 신뢰하지 마세요 |
| Agent가 plan step을 조용히 건너뜀 | 가정이 아닌 verification gate로 task 완료를 명시적으로 추적하세요; 각 session 종료 시 plan checklist를 review하세요 |
| Agent가 framework config property를 만들어냄 | context7 documentation이나 framework의 official reference에서 configuration property를 확인하세요; 익숙하지 않은 property를 확인 없이 수용하지 마세요 |
| Agent가 semantically incorrect한 business logic을 생성 | Human review는 compilation과 test 통과뿐만 아니라 domain correctness를 검증해야 해요; test도 agent가 생성했다면 logic이 잘못되어도 test가 통과할 수 있어요 |
| Reviewer가 설명할 수 없는 code를 승인 | Reviewer가 agent가 왜 특정 접근 방식을 선택했는지 설명할 수 없으면, 승인하기 전에 속도를 늦추고 조사하세요 — 이것은 skill atrophy signal이에요 |
| Agent가 main checkout에서 직접 작업 | Execution에는 항상 git worktree를 사용하세요 — agent 작업을 격리하고 main branch corruption을 방지해요; cleanup은 directory 삭제이지 `git reset`이 아니에요 |
| Feature 완료 후 worktree가 남아있음 | Merge 후 worktree를 삭제하세요; stale worktree는 disk space를 소비하고 어떤 directory에 현재 작업이 있는지 혼란을 일으켜요 |

---

## Portability Note

이 playbook의 구조는 Claude Code 외의 도구에도 적용 가능하도록 설계되었어요:

**Portable element** (tool에 구애받지 않는):
- 4-phase workflow (Design → Execute → Review → Validate)
- 8개의 모든 design principle
- Governance policy와 autonomy boundary
- Pitfall table과 metrics framework
- Prerequisite requirement (ticket, ADR, 실제 data)

**Claude Code-specific element** (다른 tool에서는 adaptation 필요):
- Slash command (`/brainstorming`, `/writing-plans`, `/executing-plans` 등)
- Superpowers plugin과 subagent dispatch
- context7와 frontend-design plugin 참조
- `Co-Authored-By` commit attribution format

이 playbook을 다른 agent tool에 적용할 때, portable element는 유지하고
tool-specific element를 target platform의 equivalent로 교체하세요.

---

## References

**Project docs:**

- [AGENTS.md](AGENTS.md) — project convention과 coding guideline
- [AI Agent References](docs/ai-agent-references.md) — 이 playbook에 영감을 준 선별된 연구와 architecture guide

**Foundational research:**

- [Building Effective Agents — Anthropic](https://www.anthropic.com/research/building-effective-agents) — workflow vs. agent 구분, start-simple principle, core architecture pattern
- [Anthropic Agent Cookbook](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents) — agent pattern의 code example
- [2026 Agentic Coding Trends Report — Anthropic](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf) — coding agent가 개발을 어떻게 재편하는지에 대한 data 기반 분석
- [Agentic Workflows for Software Development — QuantumBlack/McKinsey](https://medium.com/quantumblack/agentic-workflows-for-software-development-dc8e64f4a79d) — rule-based orchestration engine pattern (agent가 실행하고 workflow가 sequencing을 관리)
- [2026 Guide to Agentic Workflow Architectures — Stack AI](https://www.stackai.com/blog/the-2026-guide-to-agentic-workflow-architectures) — minimal freedom principle, 4가지 core architecture
- [Andrew Ng's Four Agentic Design Patterns — DeepLearning.AI](https://www.deeplearning.ai/courses/agentic-ai/) — Reflection, Tool Use, Planning, Multi-Agent Collaboration
- [AI-Native Development vs. AI Agentic Development Workflows — Strategic Research Report](../ai-native-vs-agentic-development-report.md) — 이 enhanced version에 영감을 준 비교 분석

**Industry governance and adoption:**

- [Agentic AI Enterprise Adoption Guide — Deloitte](https://www.deloitte.com/us/en/what-we-do/capabilities/applied-artificial-intelligence/articles/agentic-ai-enterprise-adoption-guide.html) — 단계적 adoption, governance, risk management
- [AI-SDLC Maturity Model — ELEKS](https://eleks.com/blog/ai-sdlc-maturity-model/) — 5 level: Traditional → AI-Autonomous; security risk data
- [AI Tools for Every SDLC Phase: 2026 Guide — MetaCTO](https://www.metacto.com/blogs/mapping-ai-tools-to-every-phase-of-your-sdlc) — AEMI maturity assessment framework

**Plugins:**

- [context7](https://claude.com/plugins/context7) — live library documentation (Quarkus, LangChain4j, CDI 등)
- [superpowers](https://claude.com/plugins/superpowers) — brainstorming, writing-plans, executing-plans, code-review skill
- [frontend-design](https://claude.com/plugins/frontend-design) — production-grade web UI 생성; browser-facing component가 있는 모든 feature에 필수

---

## Revision History

### 2026-04-23 — Phase 1에 feature branch 생성 추가

Design 작업을 시작하기 전에 feature branch를 생성하는 명시적 step을 추가했어요.

**Changes:**

- **Phase 1에 새로운 "Step 0 — Create a feature branch"** — 모든 feature artifact
  (spec, plan, ADR, implementation code)가 처음부터 dedicated branch에 commit되어
  깨끗한 commit history와 명확한 PR/MR scope을 제공해요
- **Phase 1 step 번호 재지정** — complexity 선택이 Step 1, brainstorming이 Step 2,
  plan writing이 Step 3으로 변경
- **Phase 1 closing paragraph 업데이트** — commit이 commit 시점에 branch 생성을
  암시하는 대신 Step 0에서 생성된 feature branch를 참조
- **Phase 2 worktree workflow 업데이트** — worktree가 새로운 branch를 생성하는 대신
  기존 feature branch를 사용

### 2026-04-22 — Phase 2에 git worktree isolation 추가

Agentic execution의 isolation mechanism으로 git worktree를 통합했어요.

**Changes:**

- **Phase 2에 새로운 "Step 0 — Create an isolated worktree"** — agent가 plan 실행 전에
  git worktree를 생성하여, agent의 iteration loop 중 broken build, corrupted state,
  half-finished 작업으로부터 main checkout을 보호하는 sandbox를 제공
- **Step 0 complexity table 업데이트** — Workflow row에 worktree isolation 참조 추가
- **두 개의 새로운 pitfall** — agent가 main checkout에서 직접 작업 (대신 worktree 사용);
  feature 완료 후 worktree가 남아있음 (merge 후 정리)
- **Closing checklist 업데이트** — worktree cleanup verification step 추가
- **Execution step 이름 변경** — 새로운 worktree step을 수용하기 위해 Phase 2 step
  번호 재지정 (Step 0: worktree, Step 1: plan 실행)

### 2026-04-12 — Strategic research report review 기반 enhanced version

[AI-Native Development vs. AI Agentic Development Workflows strategic research
report](../ai-native-vs-agentic-development-report.md)를 기준으로 playbook을 검토하고
업계 연구 (Anthropic, McKinsey, Deloitte, ELEKS, Andrew Ng)의 발견 사항을 반영했어요.

**Changes:**

- **새로운 "Governance" section** — mandatory human review category, agent autonomy
  boundary, attribution policy, audit trail requirement. Deloitte의 adoption guide와
  ELEKS maturity model의 security risk 발견 사항에 의해 주도됨.
- **새로운 "Metrics" section** — 무엇을 측정할 것인지 (human correction rate, defect rate,
  security finding, time-to-merge), 언제 측정할 것인지, 어떻게 사용할 것인지. MetaCTO
  AEMI framework과 McKinsey productivity measurement guidance 기반.
- **새로운 Design Principle 6: Reflection** — Andrew Ng의 네 번째 agentic design pattern
  반영. Agent가 human review 전에 spec에 대해 자체적으로 output을 review.
- **새로운 Design Principle 8: Developers must understand the code they approve** —
  ELEKS 연구에서 식별된 skill atrophy risk 해결 (AI가 생성한 code의 40% security
  vulnerability rate).
- **Enhanced introduction** — AEMI/ELEKS framework을 사용한 maturity level targeting
  (Level 3 Intentional) 추가, Anthropic 2026 trust gap data (사용률 80%, trust 29%)
  기반의 trust-building guidance.
- **Phase 2에 새로운 "Self-review before human review" step** — 4-point checklist로
  Reflection principle을 실제로 적용.
- **Phase 4에 새로운 "Security scanning" step** — SpotBugs와 OWASP Dependency-Check
  command, ELEKS의 AI가 생성한 code의 40%가 security issue를 포함한다는 발견에 의해 주도됨.
- **5개의 새로운 pitfall** — agent가 존재하지 않는 API 호출 생성, agent가 plan step을
  조용히 건너뜀, agent가 framework config property를 만들어냄, agent가 semantically
  incorrect한 business logic 생성, reviewer가 설명할 수 없는 code를 승인.
- **Phase 4 closing checklist 강화** — security scanning, skill atrophy check, execution
  summary item 추가.
- **새로운 "Portability Note"** — report의 단일 LLM provider에서 decouple하라는 권고에
  따라 어떤 playbook element가 tool-agnostic이고 어떤 것이 Claude Code-specific인지 식별.
- **References 확장** — Andrew Ng의 design pattern, strategic research report, 업계
  governance 출처 (Deloitte, ELEKS, MetaCTO) 추가.

### 2026-04-11 — Quarkus/Java project에 맞게 playbook 조정

Playbook을 Python 기반 multi-service project에서 실제 Quarkus/Java tech stack에 맞게
조정했어요.

**Changes:**

- **Setup section** — GitLab-only token setup을 일반 VCS CLI guidance (GitHub `gh`와
  GitLab `glab`)로 교체; standalone issue tracker CLI section 제거
- **Prerequisites** — `.pre-commit-config.yaml`을 Maven wrapper로 교체; Python library
  참조 (FastAPI, SQLAlchemy, dbt, Alembic, Pydantic)를 Quarkus, LangChain4j, CDI,
  RESTEasy, Hibernate로 교체
- **Phase 2** — `python -m pytest`를 `./mvnw test`로 교체; `dbt compile`을
  `./mvnw compile`로 교체; cross-service/K8s data flow를 Quarkus config property
  tracing으로 교체
- **Phase 3** — GitLab `glab`과 함께 GitHub `gh` command 추가; PR/MR 용어 일반화
- **Phase 4** — podman compose validation을 Quarkus dev mode로 교체; Python E2E test
  command를 `./mvnw verify`로 교체; Java/Quarkus용 closing checklist 업데이트
- **Key Pitfalls** — Python/dbt/K8s-specific pitfall 제거; Quarkus-specific pitfall 추가
  (CDI injection failure, `@QuarkusTest`, config profile, dev mode console)
- `docs/ADR/ADR-template.md` **생성** — 이전에 참조되었지만 누락되어 있었음
- Maven wrapper (`mvnw`) **추가** — 이전에 AGENTS.md에서 참조되었지만 누락되어 있었음

### 2026-04-10 — Research 기반 principle과 architecture guidance

[AI Agent References](docs/ai-agent-references.md)의 insight로 playbook을 개선했어요.
Anthropic의 "Building Effective Agents" 연구, QuantumBlack/McKinsey의 agentic workflow
architecture, Stack AI의 architecture guide를 참고했어요.

**Changes:**

- Setup 앞에 **새로운 "Design Principles" section** (6개 principle) 추가:
  1. Start simple, add complexity only when needed — Anthropic의 core advice에서
  2. Workflows vs. agents — 이 playbook이 특정 step에서 agent 기능을 갖춘 workflow임을 설명
  3. Orchestration over prompt engineering — task sequencing이 prompt 문구보다 중요
  4. Specialize agents, don't generalize — 단일 prompt보다 각각의 skill을 사용하는 이유를 설명
  5. Minimal freedom principle — Stack AI의 architecture guide에서
  6. Observability from day one — cross-source 합의에서
- **Phase 1에 새로운 "Step 0 — Choose the right level of complexity"** — 가장 가벼운
  접근 방식을 선택하기 위한 decision table (single call vs. full playbook vs. parallel subagent)
- **Enhanced plan writing guidance** — plan을 rule-based orchestration artifact로 설명
  (QuantumBlack/McKinsey pattern에서)
- **2개의 새로운 pitfall** — agent에게 너무 일찍 너무 많은 autonomy 부여; orchestration
  수정 대신 prompt tweaking
- **References section 확장** — 5개의 foundational research source에 설명 추가
