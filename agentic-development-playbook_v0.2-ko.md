# 사람이 방향을 잡고, Agent가 실행한다. - Agentic Development Playbook

| | |
| --- | --- |
| **Version** | v0.2 |
| **Last updated** | 2026-04-22 |
| **Status** | Living document — updated through real-world practice |

> **"Humans steer. Agents execute."** — [OpenAI, Harness Engineering](https://openai.com/index/harness-engineering/)

Claude Code와 superpowers plugin을 사용하여 AI 지원 기능 개발을 수행하기 위한 가이드예요.

**사용 시점:** 새로운 기능을 개발할 때 — 설계가 확정된 경우(기존 ADR 존재)나 아직 열려 있는
경우(Brainstorming 중 아키텍처 의사결정을 탐색하고 합의 — 이 과정에서 ADR을 생성할 수
있어요) 모두 해당돼요. 예시:
- 비즈니스 로직과 검증을 포함하는 새 REST endpoint 추가
- 외부 서비스 연동(예: LLM 제공자, message broker)
- 데이터 모델 재설계 — Brainstorming 과정에서 설계를 탐색하고 합의

**사용하지 않는 경우:** 소규모 단독 수정이나 버그 수정.

**대상 성숙도 수준:** 이 Playbook은 [AEMI (MetaCTO)](https://www.metacto.com/blogs/mapping-ai-tools-to-every-phase-of-your-sdlc)
또는 [ELEKS](https://eleks.com/blog/ai-sdlc-maturity-model/) 성숙도 척도에서 **Level 3
(Intentional)** 에 해당하는 팀을 대상으로 설계되었어요 — 기존 CI/CD Pipeline을 보유하고
있고 AI 코딩 도구 사용 경험이 있는 팀이에요. Level 1-2의 팀은 전체 Playbook을 적용하기
전에 더 간단한 AI 지원 Workflow(copilot 스타일의 자동 완성과 채팅 기반 지원)부터 시작해야
해요.

**이것은 Human-in-the-Loop Workflow이며, 완전 자율 Workflow가 아니에요.** Agent가 스펙,
계획, 코드를 생성하지만, 사람이 설계 의사결정을 주도하고, 도메인 지식을 제공하며, 실제
데이터에 대해 검증하고, 의미적 불일치를 발견하며, 각 Phase를 진행하기 전에 승인해요. 설계
단계에서만 보통 여러 번의 사람 수정이 필요하고, 모든 테스트가 통과한 후에도 사람의
데이터베이스 점검을 통해서만 발견되는 치명적 버그가 있었어요.

**점진적 신뢰 구축.** Agent에게는 저위험의, 잘 이해된 작업부터 시작하세요. 측정된 성공
후에만 범위를 확장하세요. Agent 자율성을 줄일 권리를 유지하세요. 신뢰 시그널을 추적하세요 —
리뷰 거부율, Merge 후 결함(Agent 생성 코드에서), Phase별 사람 수정 빈도. 업계 전체의
[신뢰 격차](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf?hsLang=en)
(사용률 80%, 신뢰도 29%)는 실패가 아니라 정교해지고 있음을 반영해요 — Agent를 광범위하게
사용한 팀일수록 한계를 더 잘 인식하고 있어요.

**이 Playbook은 자동으로 로드돼요** — `agentic-playbook` skill
(`.claude/skills/agentic-playbook/`)을 통해서요. Brainstorming, writing-plans, 또는
executing-plans 세션을 시작할 때 이 skill이 트리거되어 Agent에게 전체 Workflow, 함정,
subagent 트리거 규칙을 제공해요.

**이 Playbook 최신 유지하기:** 이 문서는 Brainstorming 세션 중 Agent에게 제공되는 입력 중
하나예요. 새로운 함정이 발견되거나, 새로운 subagent 또는 plugin이 추가되거나, Workflow가
변경될 때마다 업데이트하세요. 오래된 Playbook 내용은 같은 실수를 반복하게 해요.

---

## 목차

- [설계 원칙](#설계-원칙)
  - [1. 단순하게 시작하고, 필요할 때만 복잡성을 추가하세요](#1-단순하게-시작하고-필요할-때만-복잡성을-추가하세요)
  - [2. Workflow와 Agent — 차이를 알아두세요](#2-workflow와-agent--차이를-알아두세요)
  - [3. Prompt Engineering보다 Orchestration이 중요해요](#3-prompt-engineering보다-orchestration이-중요해요)
  - [4. Agent를 전문화하세요, 범용화하지 마세요](#4-agent를-전문화하세요-범용화하지-마세요)
  - [5. 최소 자유 원칙](#5-최소-자유-원칙)
  - [6. Reflection — Agent가 자신의 작업을 검토해요](#6-reflection--agent가-자신의-작업을-검토해요)
  - [7. 첫날부터 Observability를 확보하세요](#7-첫날부터-observability를-확보하세요)
  - [8. 개발자는 승인하는 코드를 이해해야 해요](#8-개발자는-승인하는-코드를-이해해야-해요)
- [거버넌스](#거버넌스)
  - [필수 사람 리뷰](#필수-사람-리뷰)
  - [기여 표시](#기여-표시)
  - [Agent 자율성 경계](#agent-자율성-경계)
  - [감사 추적](#감사-추적)
- [설정 (최초 1회)](#설정-최초-1회)
  - [VCS CLI (GitHub 또는 GitLab)](#vcs-cli-github-또는-gitlab)
  - [사전 요건 확인](#사전-요건-확인)
- [기능별 사전 요건](#기능별-사전-요건)
- [Phase 1: 설계 (단일 세션)](#phase-1-설계-단일-세션)
  - [Step 0 — 적절한 복잡성 수준 선택](#step-0--적절한-복잡성-수준-선택)
  - [Step 1 — Brainstorming](#step-1--brainstorming)
  - [Step 2 — Plan 작성](#step-2--plan-작성)
- [Phase 2: 실행 (별도 세션)](#phase-2-실행-별도-세션)
  - [사람 리뷰 전 Self-review (Reflection 패턴)](#사람-리뷰-전-self-review-reflection-패턴)
  - [삭제 전 의존성 그래프 확인](#삭제-전-의존성-그래프-확인)
  - [context7을 활용한 라이브러리 문서 참조](#context7을-활용한-라이브러리-문서-참조)
  - [설정 및 환경 변수](#설정-및-환경-변수)
  - [각 작업 완료 후](#각-작업-완료-후)
- [Phase 3: Code Review](#phase-3-code-review)
  - [Step 1 — MR 생성](#step-1--mr-생성)
  - [Step 2 — CI 자동 리뷰](#step-2--ci-자동-리뷰)
  - [Step 3 — Claude Code로 CI 피드백 검토](#step-3--claude-code로-ci-피드백-검토)
  - [Step 4 — Claude Code 추가 리뷰](#step-4--claude-code-추가-리뷰)
- [Phase 4: 검증](#phase-4-검증)
  - [보안 스캔](#보안-스캔)
  - [Quarkus dev mode를 이용한 로컬 검증](#quarkus-dev-mode를-이용한-로컬-검증)
  - [Integration test — 인접 시스템 포함](#integration-test--인접-시스템-포함)
  - [Dev 배포](#dev-배포)
  - [기능 종료 전 확인사항](#기능-종료-전-확인사항)
- [Metrics](#metrics)
  - [측정 항목](#측정-항목)
  - [활용 방법](#활용-방법)
- [지속적 개선](#지속적-개선)
  - [asciinema로 세션 녹화하기](#asciinema로-세션-녹화하기)
  - [세션 회고](#세션-회고)
  - [개선 사이클](#개선-사이클)
- [주요 함정](#주요-함정)
- [이식성 참고사항](#이식성-참고사항)
- [참고자료](#참고자료)
- [개정 이력](#개정-이력)

---

## 설계 원칙

이 Playbook은 Anthropic의 ["Building Effective Agents"](https://www.anthropic.com/research/building-effective-agents) 연구, QuantumBlack(McKinsey)의 Agentic Workflow 아키텍처, [Andrew Ng의 Agentic Design Pattern](https://www.deeplearning.ai/courses/agentic-ai/), 그리고 Agent 설계에 대한 업계 합의를 기반으로 해요. 이 원칙들은 Workflow의 모든 Phase에 적용돼요.

### 1. 단순하게 시작하고, 필요할 때만 복잡성을 추가하세요

적절한 도구를 갖춘 단일 LLM 호출이 Multi-Agent 시스템보다 나은 경우가 많아요. 병렬
subagent나 복잡한 Orchestration을 적용하기 전에, 더 단순한 접근 방식으로 문제를 해결할 수
없는지 확인하세요. 복잡성은 추정이 아닌 측정 가능한 개선으로 정당화되어야 해요.

### 2. Workflow와 Agent — 차이를 알아두세요

- **Workflow**는 사전 정의된 Orchestration을 따라요: 단계의 순서가 고정되어 있고, LLM은
  해당 제약 안에서 실행해요(예: 이 Playbook의 Phase 1 → 2 → 3 → 4 흐름).
- **Agent**는 LLM이 주도하여 어떤 단계를 어떤 순서로 수행할지 결정해요.

이 Playbook은 **특정 단계에서 Agent 기능을 갖춘 Workflow**예요 — 전체 순서는 사람이
정의하지만, 각 단계 내에서는 Agent가 자율성을 가져요(Brainstorming 탐색, 코드 생성, 리뷰
해석). 이는 Workflow를 주 구조로 사용하고 동적 의사결정이 가치를 더하는 곳에서만 Agent를
활용하라는 Anthropic의 권고와 일치해요.

### 3. Prompt Engineering보다 Orchestration이 중요해요

Agent 간의 상호작용 설계 — 작업 순서 지정, 핸드오프 정의, 입출력 구조화 — 가 개별 Prompt를
작성하는 것보다 중요해요. Plan 문서가 주요 Orchestration 산출물이에요: 작업 순서, 의존성,
검증 게이트, 모델 선택 힌트를 정의해요. Prompt 문구보다 Plan 품질에 시간을 투자하세요.

### 4. Agent를 전문화하세요, 범용화하지 마세요

여러 개의 집중된 Agent가 하나의 범용 Agent보다 성능이 좋아요. 이것이 Workflow에서
하나의 "모든 것을 하는" Prompt 대신 별도의 skill(`/brainstorming`, `/writing-plans`,
`/executing-plans`, `/requesting-code-review`)을 사용하는 이유예요. 각 skill은 좁은
범위와 구체적인 출력을 가져요.

### 5. 최소 자유 원칙

결과를 달성하면서도 최소한의 자율성을 시스템에 부여하세요. 명시적인 지시사항, 검증 게이트,
사람 승인 지점을 통해 Agent 행동을 제약하세요. 제약되지 않은 Agent는 요구사항에서 벗어나고,
구현 세부사항을 환각하며, 사람이 소유해야 할 아키텍처 의사결정을 내려요.

### 6. Reflection — Agent가 자신의 작업을 검토해요

[Reflection](https://www.deeplearning.ai/courses/agentic-ai/)은 Andrew Ng의 네 가지
Agentic Design Pattern 중 하나예요: Agent가 자신의 출력을 비평하고 반복적으로 수정하여
자체 리뷰어 역할을 해요. 이 Workflow에서 Reflection이란:

- 작업 코드를 생성한 후, Agent가 사람 리뷰에 제출하기 전에 스펙과 Plan을 기준으로
  자체 검토해요
- Agent가 구현이 가장 쉬운 것뿐만 아니라 모든 수용 기준을 충족하는지 확인해요
- Self-review가 사람 리뷰 시간을 소비하기 전에 단순한 오류를 잡아요

이것은 Reviewer subagent(Phase 3)와는 구별돼요 — Reflection은 같은 단계 내에서
구현 Agent가 자신의 작업을 점검하는 것이에요.

### 7. 첫날부터 Observability를 확보하세요

모니터링, 평가, 피드백 루프에 투자하세요 — 문제가 발생한 후가 아니라 처음부터요. 이
Workflow에서 Observability란:

- 스펙과 Plan을 버전 관리되는 산출물로 저장하기(대화 Context에만 남기지 않기)
- 각 Phase 전환 시 Reviewer subagent 실행하기
- 각 작업 후 테스트 결과뿐만 아니라 서비스 로그와 데이터베이스 상태 확인하기
- 이 Playbook에 함정을 추적하여 조직 지식으로 축적하기
- 각 실행 세션 종료 시 간략한 "의사결정 및 수정" 요약 저장하기 —
  어떤 Plan 단계에서 사람 개입이 필요했고 그 이유는 무엇인지
- Agent 대화 요약을 스펙 및 Plan과 함께 감사용으로 보존하기

### 8. 개발자는 승인하는 코드를 이해해야 해요

AI 지원 개발은 사람의 전문성을 덜 중요하게 만드는 것이 아니라 *더* 중요하게 만들어요.
[연구에 따르면](https://eleks.com/blog/ai-sdlc-maturity-model/) AI를 엔지니어링 투자를
줄이는 수단으로 취급하는 팀은 안정성 저하, 기술 부채 증가, 보안 리스크 심화를 겪어요.

이 Workflow에서: 리뷰어는 코드가 컴파일되고 테스트가 통과하는지뿐만 아니라, Agent가 *왜*
특정 접근 방식을 선택했는지 설명할 수 있어야 해요. 리뷰어가 Agent의 구현을 설명할 수 없다면,
그것은 속도를 늦추고 조사해야 한다는 신호이지 — 승인하고 넘어가라는 신호가 아니에요.

---

## 거버넌스

AI 생성 코드에 대한 거버넌스 정책은 Workflow가 확장됨에 따라 품질과 책임을 보장해요.
이 정책은 모든 Phase에 적용돼요.

### 필수 사람 리뷰

테스트 결과와 관계없이, 다음 유형의 변경은 Merge 전에 **반드시** 명시적 사람 리뷰를 받아야
해요:
- 인증(Authentication) 및 인가(Authorization) 로직
- 암호화 연산 및 Secret 처리
- 데이터베이스 Migration Script 및 스키마 변경
- API Contract 및 외부 노출 Response 형태
- 운영 환경에 영향을 미치는 설정 변경
- 의존성 추가 또는 버전 변경

### 기여 표시

AI 생성 코드는 `Co-Authored-By` 관례를 사용하여 Commit에 표시해요. 이를 통해 감사 추적이
생성되고, 시간이 지남에 따라 사람이 작성한 코드와 AI가 생성한 코드의 비율을 분석할 수 있어요.

### Agent 자율성 경계

Agent가 자율적으로 **할 수 있는 것:**
- 승인된 Plan에 따른 구현 코드 생성
- 테스트 실행 및 컴파일 오류 수정
- Boilerplate, 설정, Scaffolding 생성
- 현재 작업 범위 내의 Refactoring 제안

Agent가 자율적으로 **할 수 없는 것:**
- 사람 승인 없이 보안 관련 코드 수정
- 승인된 Plan을 넘어서는 작업 범위 변경
- 운영 데이터 삭제 또는 파괴적 데이터베이스 작업 실행
- 사람 확인 없이 코드 Push 또는 PR/MR 생성
- Plan이나 기존 ADR에서 다루지 않는 아키텍처 의사결정

### 감사 추적

이 Workflow를 통해 개발된 각 기능에 대해 다음 산출물을 보존해야 해요:
- 생성된 스펙 (`docs/superpowers/specs/` 에 저장)
- 생성된 Plan (`docs/superpowers/plans/` 에 저장)
- 설계 Phase에서 생성된 ADR
- Code Review 발견사항과 그 처리 결과

---

## 설정 (최초 1회)

### VCS CLI (GitHub 또는 GitLab)

VCS CLI는 이 Workflow 전체에서 PR/MR 생성, CI 상태 확인, 리뷰 코멘트 조회에 사용돼요.

**GitHub** — `gh` CLI를 설치하고 인증하세요:

```bash
gh auth login
```

**GitLab** — `glab` CLI를 설치하고 프로젝트 범위 토큰을 생성하세요:

1. 저장소 → **Settings → Access Tokens**으로 이동
2. 다음 scope의 토큰 생성: `api`, role: Developer
3. 설정: `glab auth login --hostname gitlab.example.com --token <your-token>`

토큰을 단일 저장소로 제한하면 Agentic 세션 중 문제 발생 시(의도하지 않은 PR/MR 생성,
잘못된 PR/MR에 대한 코멘트 등) 영향 범위를 제한할 수 있어요.

### 사전 요건 확인

- Claude Code + superpowers plugin 설치됨 (세션 시작 시 `/using-superpowers`)
- [context7 plugin](https://claude.com/plugins/context7) 활성화 — 학습 데이터에 의존하지
  않고 개발 중 최신 라이브러리 및 Framework 문서를 가져옴(Quarkus, LangChain4j, CDI 등)
- [frontend-design plugin](https://claude.com/plugins/frontend-design) 설치 — 기능에
  웹 UI 작업이 포함되는 경우. `/plugin`으로 설치하고 실행 시작 전 `/reload-plugins`를
  실행하세요. 구현 후에 누락된 plugin을 발견하면 재작업을 의미해요.
- **작업이나 Plan에 참조된 모든 plugin이 설치되고 활성화되어 있어야 해요.** AC 점검 시가
  아니라 실행 세션 시작 시 확인하세요. 최근 추가한 경우 `/reload-plugins`를 실행하세요.
- Maven wrapper(`mvnw`) 사용 가능, 또는 시스템에 Maven 설치됨
- `AGENTS.md` 최신 상태
- [Harness engineering](docs/harness-engineering-guide.md) 구성됨 — pre-commit hook이
  자가 수정 루프를 통해 컴파일, 테스트, 포맷팅, 코딩 규칙을 자동으로 적용

---

## 기능별 사전 요건

1. **티켓이 존재해야 해요.** 티켓은 기능을 추적하고 Branch 이름, Commit 메시지, MR 설명에
   사용되는 `PROJ-XXXX` 식별자를 제공해요. 시작하기 전에 생성하세요.

2. **아키텍처 컨텍스트를 수집하세요.** 이 기능에 대한 ADR이 이미 존재하면 입력으로
   제공하세요. 설계가 아직 열려 있으면 Brainstorming Phase에서 옵션을 탐색하고 ADR을
   생성해요 — 하지만 실행으로 진행하기 전에 결과 의사결정을 팀과 논의하세요. Agent는
   코드만으로는 도메인별 제약사항을 추론할 수 없어요; 아키텍처 컨텍스트(ADR, 팀 입력, 또는
   명시적 도메인 지식)가 필요해요.

3. **실제 입력 데이터를 준비하세요.** 설계 세션 전에 실제 샘플 데이터를 수집하세요:
   실제 API 메시지, 실제 데이터 파일, 인접 시스템의 예시 레코드. 실제 Payload의 필드 이름과
   형태는 문서에서 암시하는 것과 다른 경우가 빈번해요.

---

## Phase 1: 설계 (단일 세션)

> **목표:** superpowers skill이 자체 완결적인 스펙과 구현 Plan을 생성하여, 새로운 Agent가
> 설계 대화 Context 없이도 실행할 수 있게 하는 것이에요. Plan은 세션 간 핸드오프
> 산출물이에요.

### Step 0 — 적절한 복잡성 수준 선택

Brainstorming 전에, 이 기능이 실제로 전체 Playbook이 필요한지 결정하세요.
**단순하게 시작하는 원칙**을 적용하여 결과를 달성하는 가장 가벼운 접근 방식을 선택하세요:

| 복잡성 수준 | 사용 시점 | 접근 방식 |
| --- | --- | --- |
| **단일 LLM 호출 + 도구** | 잘 이해된 변경, 단일 파일 또는 모듈, 명확한 요구사항 | 이 Playbook을 건너뛰세요. Claude Code에 직접 요청하면 돼요. |
| **Workflow (이 Playbook)** | 다중 파일 기능, 횡단 관심사, 설계 의사결정 필요 | 아래의 전체 Phase 1–4 흐름을 따르세요. |
| **병렬 subagent** | Plan에 공유 상태가 없는 독립적 작업 3개 이상 | 실행(Phase 2) 중 `/subagent-driven-development`를 사용하세요. |

대부분의 기능은 중간 행에 해당해요. 상태를 공유하거나 순차적 의존성이 있는 작업에
병렬 subagent를 사용하고 싶은 유혹에 저항하세요 — 조정 오버헤드가 속도 이점을 상쇄해요.

### Step 1 — Brainstorming

Brainstorming skill은 산출물을 생성하기 전에 요구사항, 엣지 케이스, 설계 의사결정을
탐색하는 구조화된 Q&A를 진행해요. 스펙을 출력으로 생성해요.

```
/brainstorming
```

입력으로 제공하세요:
- 티켓(`PROJ-XXXX`)과 한 단락 분량의 기능 설명
- 관련 ADR
- 실제 입력 데이터(Payload 예시, 데이터 파일 샘플, API Response 예시)
- 이 Playbook

**명명 규칙을 일찍 확립하세요.** 스키마 설계 전에 필드명 패턴과 용어에 합의하세요.
늦게 발견된 명명 비일관성은 여러 번의 수정 라운드를 유발해요.

**실제 데이터를 일찍 보여주세요.** 실제 데이터 파일은 스펙 읽기로는 발견하지 못하는 이슈를
꾸준히 드러내요(누락된 필드, 예상치 못한 형식, 도구 이름 불일치).

**코드베이스에 없는 도메인 지식은 명시적으로 제공해야 해요.** Agent는 시스템 고유의 제약사항
(제품 분류체계, 외부 API Response 형태, 플랫폼 메시지 형식, 인증 제공자 세부사항)을
코드에서 추론할 수 없어요.

Brainstorming 세션 마지막에 Agent에게 생성된 스펙을 저장하도록 요청하세요:

```
Save the spec to docs/superpowers/specs/<date>-<ticket>-<short-title>.md
```

그런 다음 자동화된 스펙 리뷰를 실행하세요:

```
Dispatch a reviewer subagent to audit this spec for completeness and correctness.
```

진행하기 전에 모든 Reviewer 발견사항을 처리하세요.

### Step 2 — Plan 작성

writing-plans skill은 스펙을 순서가 지정된 구현 Plan으로 변환해요.

```
/writing-plans
```

Plan은 Agent가 스펙으로부터 생성해요. Plan은 주요 **Orchestration 산출물**이에요 — 어떤
개별 Prompt보다도 중요해요. 각 작업에는 다음이 포함돼요: 목표, 생성/수정할 정확한 파일,
핵심 코드 스니펫, 실행할 테스트를 명시하는 검증 단계. 작업은 기반 레이어(모델, 스키마,
데이터베이스)가 통합 레이어(서비스, 워커, API)보다 먼저 구축되도록 순서가 지정돼요.

Plan은 **규칙 기반 Orchestration** 패턴을 따라요: Agent가 작업을 실행하지만,
Plan(Agent가 아닌)이 순서 지정, 의존성, 검증 게이트를 정의해요. 이 분리를 통해 아키텍처에
대한 통제는 사람에게 유지하면서 구현은 Agent에게 위임할 수 있어요.

Plan에는 작업별 모델 선택 힌트가 포함돼요:

- **Opus**: 서비스/비즈니스 로직, 서비스 간 통합, 복잡한 불변식
- **Sonnet**: 기계적 작업(Boilerplate, Health endpoint, 스키마 정의, K8s Manifest)

생성된 Plan에 대해 Reviewer를 실행하세요:

```
Dispatch a reviewer subagent to audit this plan for gaps, missing dependencies,
and tasks that could cause regressions in adjacent systems.
```

**ADR은 구현 후가 아니라 대화 중에 작성하세요.** 설계 의사결정이 나타나면
`docs/ADR/ADR-template.md`를 사용하여 즉시 기록하세요. Context는 대화 중에 가장
신선해요.

생성된 스펙, Plan, 새로운 ADR을 Commit하세요. Claude Code는 git 작업(Branch 생성,
Commit, Push)을 직접 처리할 수 있어요 — 변경사항을 Commit하고 Push하라고 요청하면 돼요.

---

## Phase 2: 실행 (별도 세션)

> **규칙:** 실행은 새로운 세션에서 시작하세요. 설계 세션은 Context Window를 소진해요.
> 생성된 Plan이 유일한 핸드오프 수단이에요 — 자체 완결적이어야 해요.

```
/executing-plans docs/superpowers/plans/<date>-<ticket>-<plan-name>.md
```

독립적인 작업이 있는 Plan의 경우:

```
/subagent-driven-development
```

### 사람 리뷰 전 Self-review (Reflection 패턴)

각 작업에 대한 코드를 생성한 후, Agent는 사람 리뷰에 제출하기 전에 자체적으로 출력을
검토해야 해요:

1. **스펙 대비 점검:** 구현이 가장 쉬운 것뿐만 아니라 스펙에 나열된 모든 수용 기준을
   충족하는가?
2. **Plan 대비 점검:** 코드가 Plan의 예상 파일, 구조, 접근 방식과 일치하는가?
   건너뛴 단계가 있는가?
3. **환각 점검:** 참조된 모든 API, 메서드, 설정 속성이 실제로 존재하는가?
   Import가 컴파일되는지 확인하세요.
4. **완전성 점검:** 스펙의 엣지 케이스가 처리되었는가? 정상 경로뿐만 아니라
   오류 경로도 구현되었는가?

이 Self-review는 사람 리뷰 시간을 소비하기 전에 단순한 오류를 잡아요. 사람 리뷰의 대체가
아니라 — 품질의 최저선을 높이는 필터예요.

### 삭제 전 의존성 그래프 확인

```bash
grep -rl "<removed-name>" src/
./mvnw compile -q   # 제거 후 컴파일 확인
```

### context7을 활용한 라이브러리 문서 참조

context7 plugin은 이 프로젝트에서 사용하는 라이브러리와 Framework의 최신 문서를 가져와요.
Quarkus, LangChain4j, CDI, RESTEasy, Hibernate 또는 다른 의존성을 다룰 때 사용하세요 —
API를 알고 있다고 생각하더라도 학습 데이터가 최근 변경사항을 반영하지 못할 수 있어요.

### 설정 및 환경 변수

설정 속성을 레이어 전체에 걸쳐 명시적으로 추적하세요. 모든 속성이나 환경 변수에 대해:
`application.properties`와 프로필별 설정 파일(`application-dev.properties` 등)에
설정되어 있는지 확인하세요.

### 각 작업 완료 후

```bash
./mvnw test -q
```

각 Plan 단계가 완료되었는지 명시적으로 확인하세요. 완료를 가정하지 마세요 — 단계의 출력이
존재하고 검증 게이트를 통과하는지 확인하세요. 실행 요약을 위해 해당 단계에서 수행된 사람
수정을 추적하세요.

---

## Phase 3: Code Review

### Step 1 — MR 생성

Claude Code에 PR/MR을 생성하도록 요청하세요 — `gh pr create`(GitHub) 또는
`glab mr create`(GitLab)를 사용하고 Branch diff에서 설명을 생성하여 자동으로 티켓에
연결해요.

대규모 PR/MR(50+ Commit)의 경우, 설명에서 리뷰어에게 스펙, Plan, 피드백 문서를 안내하고;
배포 리스크를 명시하며; 티켓에 연결해야 해요.

### Step 2 — CI 자동 리뷰

CI Pipeline에서 AI Code Review 도구를 자동으로 실행하고 PR/MR에 인라인 코멘트를 게시할 수
있어요.

Push하기 전에, 기능이 아키텍처, 데이터 흐름, 스키마를 변경하는 경우 `AGENTS.md`가
업데이트되었는지 확인하세요.

### Step 3 — Claude Code로 CI 피드백 검토

CI가 완료되면 리뷰 코멘트를 가져와 Claude Code로 해석하고 처리하세요:

```bash
# GitHub — 리뷰 코멘트 가져오기
gh pr view <pr-id> --comments > /tmp/pr_comments.txt

# GitLab — 리뷰 코멘트 가져오기
glab mr view <mr-id> --comments > /tmp/mr_comments.txt
```

그런 다음 Claude Code에서:

```text
Read /tmp/pr_comments.txt. These are the AI code review comments from the CI pipeline.
For each finding: identify if it is blocking, advisory, or a false positive.
For blocking and advisory findings, propose a fix. For false positives, explain why
and draft a comment to add to the PR/MR.
```

receiving-code-review skill을 사용하여 기술적 엄격함으로 피드백을 처리하세요:

```
/receiving-code-review
```

이를 통해 발견사항이 맹목적으로 구현되지 않고, 실제 코드에 대해 검증된 후 수용돼요.

### Step 4 — Claude Code 추가 리뷰

Branch diff에 대해 완전한 독립 리뷰를 실행하세요:

```
/requesting-code-review
```

이것은 `code-reviewer` subagent를 실행하여 보안, 정확성, 프로젝트 규칙과의 일관성을
다루며 — 아키텍처 제약에 초점을 맞추는 CI 리뷰를 보완해요.

---

## Phase 4: 검증

### 보안 스캔

Merge 전에 코드베이스에 대해 정적 분석과 의존성 취약점 스캔을 실행하세요.
AI 생성 코드는 사람이 작성한 코드보다 보안 이슈 발생률이 높아요 — [연구에 따르면
AI 생성 코드의 40%에 보안 취약점이 포함](https://eleks.com/blog/ai-sdlc-maturity-model/)되어
있어요.

```bash
# SEC-01: SpotBugs 정적 분석 — 일반적인 버그 패턴 탐지
./mvnw spotbugs:check -q

# SEC-02: OWASP Dependency-Check — CVSS 7 이상의 CVE 발견 시 빌드 실패
./mvnw dependency-check:check -q

# SEC-03: CycloneDX SBOM 생성 — target/bom.json 출력
./mvnw cyclonedx:makeAggregateBom -q
```

이 세 가지 검사는 CI에서 자동으로 실행되지만 (`.github/workflows/ci.yml` 참조),
PR을 열기 전에 로컬에서도 실행할 수 있어요. Agent의 자기 수정 루프 속도를 유지하기
위해 pre-commit harness에서는 의도적으로 제외했어요.

### Quarkus dev mode를 이용한 로컬 검증

Integration test를 실행하거나 배포하기 전에, 애플리케이션을 로컬에서 검증하세요:

```bash
# Live reload와 함께 dev mode로 시작
./mvnw quarkus:dev

# 별도의 터미널에서 애플리케이션 정상 상태 확인
curl -s http://localhost:8080/q/health
```

일반적인 이슈: 누락된 설정 속성, CDI 주입 실패, 누락된 의존성, 포트 충돌.

### Integration test — 인접 시스템 포함

```bash
./mvnw verify -q
```

이 기능에 추가된 테스트뿐만 아니라 전체 테스트 스위트를 실행하세요. 공유 인프라(설정,
CDI bean, REST endpoint)의 변경은 명목상 "변경되지 않은" 컴포넌트를 깨뜨릴 수 있어요.

### Dev 배포

Dev 환경에 배포하고 실제 서비스로 기능을 검증하세요. 애플리케이션 로그를 직접 검사하세요 —
동작 회귀는 실제 데이터와 실제 트래픽에서만 가시화돼요. 가능하면 로컬 Integration test에
Quarkus dev service를 활용하세요.

### 기능 종료 전 확인사항

- [ ] 애플리케이션이 dev mode에서 오류 없이 시작됨 (`./mvnw quarkus:dev`)
- [ ] 모든 테스트 통과 (`./mvnw verify`)
- [ ] 보안 스캔 통과 (`./mvnw spotbugs:check`, `./mvnw dependency-check:check`)
- [ ] SBOM 생성 (`./mvnw cyclonedx:makeAggregateBom`)
- [ ] 비즈니스 로직이 단위 테스트 경계가 아닌 End-to-End로 검증됨
- [ ] REST endpoint가 예상 Response를 반환함
- [ ] 애플리케이션 로그에 무음 실패(Silent failure)가 없음
- [ ] 리뷰어가 Agent의 구현 선택을 설명할 수 있음 (역량 약화 점검)
- [ ] 의사결정 및 수정 로그와 함께 실행 요약이 저장됨
- [ ] 티켓이 업데이트되고 Merge된 PR/MR에 연결됨

---

## Metrics

Workflow의 효과를 평가하고 개선 영역을 식별하기 위해 기능 전체에 걸쳐 이 Metrics를
추적하세요.

### 측정 항목

| Metric | 설명 | 수집 시점 |
|--------|------|-----------|
| **사람 수정률** | Phase별(설계, 실행, 리뷰) 사람 수정 횟수 | 각 Phase 종료 시 |
| **Plan 단계 재작업률** | 재작업이나 이탈이 필요했던 Plan 단계의 비율 | 실행 종료 시 |
| **결함 도입률** | 리뷰 및 테스트 중 AI 생성 코드에서 발견된 결함 | 리뷰 및 검증 종료 시 |
| **보안 발견률** | 스캔 또는 리뷰에서 AI 생성 코드에서 발견된 보안 이슈 | 검증 종료 시 |
| **Merge까지 소요 시간** | 설계 시작부터 PR/MR Merge까지의 캘린더 타임 | 기능 종료 시 |
| **리뷰 거부율** | 변경이 필요한 리뷰 사이클의 비율 | 리뷰 종료 시 |

### 활용 방법

- 기능 간 Metrics를 비교하여 어떤 작업 유형이 Agentic Workflow에서 가장 큰 혜택을 받고
  어떤 유형이 더 많은 사람 개입이 필요한지 파악하세요
- 사람 수정률이 상승하면 Agent에게 현재 역량을 넘어서는 작업이 주어지고 있다는 신호일 수
  있어요 — 범위를 줄이거나 더 많은 Context를 추가하세요
- 시간이 지남에 따라 수정률이 하락하면 팀의 스펙, Plan, Agent 지시사항이 개선되고 있다는
  신호예요
- 결함 및 보안 발견률을 사용하여 신뢰 수준과 거버넌스 정책을 조정하세요

---

## 지속적 개선

Playbook은 사용을 통해 개선돼요. Agentic 개발 세션을 녹화하고, 간략한 회고를 작성하며,
발견사항을 이 문서에 반영하세요. 의도적인 기록 없이는 같은 실수가 기능 전체에 걸쳐 반복돼요.

### asciinema로 세션 녹화하기

[asciinema](https://asciinema.org/)는 터미널 세션을 경량의 텍스트 기반 파일로 녹화해요 —
Claude Code Workflow에 이상적이에요. 녹화본은 검색 가능하고, 아무 속도로나 재생 가능하며,
화면 녹화보다 훨씬 작아요.

**설정:**

```bash
# 설치 (macOS)
brew install asciinema

# 인증 (선택 — asciinema.org에 업로드하는 경우)
asciinema auth
```

**세션 녹화하기:**

```bash
# Claude Code 실행 전에 녹화 시작
asciinema rec docs/sessions/<date>-<ticket>-<phase>.cast \
  --title "PROJ-1234 Phase 2 Execution" \
  --idle-time-limit 30

# 평소처럼 작업 — Claude Code, git, Maven 명령 등
# Ctrl+D를 누르거나 'exit'를 입력하여 녹화 중지
```

**명명 규칙:** `<date>-<ticket>-<phase>.cast`

- 예시: `2026-04-18-PROJ-1234-design.cast`
- 예시: `2026-04-18-PROJ-1234-execution.cast`

**저장:** `.cast` 파일은 `docs/sessions/`에 저장하세요. 공유를 위해 asciinema.org 또는
자체 호스팅 인스턴스에 업로드하세요 — 업로드 URL은 `asciinema upload` 직후에 반환돼요.

**실무 팁:**

- `--idle-time-limit 30`은 유휴 간격을 30초로 제한해요 — 긴 사고 일시정지가 재생 시간을
  늘리지 않아요
- 여러 시간의 세션은 하나의 연속 녹화 대신 Phase별(설계, 실행, 리뷰)로 녹화하세요 — 짧은
  녹화본이 리뷰하기 더 쉬워요
- 녹화본이 큰 경우 `docs/sessions/*.cast` 패턴을 `.gitignore`에 추가하세요; 저장소에는
  회고 문서와 asciinema.org 링크만 저장하세요

### 세션 회고

각 기능 후(또는 복잡한 기능의 경우 각 Phase 후) 간략한 회고를 작성하세요.
회고는 녹화본의 인덱스예요 — *어디를* 봐야 하는지 알려주어 수 시간의 터미널 출력을
다시 재생할 필요가 없어요.

**저장 위치:** `docs/sessions/<date>-<ticket>-retrospective.md`

**템플릿:**

```markdown
# Retrospective: PROJ-1234 — <기능 제목>

**날짜:** YYYY-MM-DD
**녹화된 Phase:** Design / Execution / Review (.cast 또는 asciinema.org URL 링크)

## 잘된 점
- (Agent가 사람 개입 없이 올바르게 처리한 것)

## 사람 수정이 필요했던 점
- (개입이 필요했던 곳, 무엇이 잘못되었는지, 녹화에서의 대략적 타임스탬프)

## Merge 후 발견된 이슈
- (Merge 후 발견된 버그나 문제 — Playbook 개선을 위한 가장 가치 있는 섹션)

## 식별된 Playbook 개선사항
- (위의 발견사항을 기반으로 이 Playbook에 반영할 구체적 변경사항)
```

**작성 시점:** Context가 신선한 세션 직후. 오늘 작성된 10분짜리 회고가 다음 주에 작성될
상세한 분석보다 더 가치가 있어요.

### 개선 사이클

```text
1. Agentic 개발 세션 녹화 (asciinema)
2. 회고 작성 (직후에)
3. 회고 검토 — 기능 간 반복되는 패턴 식별
4. 이 Playbook 업데이트:
   - 새로운 함정? → 주요 함정 테이블에 추가
   - 새로운 거버넌스 규칙 필요? → 거버넌스 섹션에 추가
   - Phase Workflow 갭? → 해당 Phase 섹션 업데이트
   - Metric 인사이트? → Metrics 섹션 개선
5. 변경사항과 이유를 개정 이력에 업데이트
```

목표는 피드백 루프예요: 이 Playbook을 통해 개발된 각 기능이 다음 기능을 더 부드럽게
만들어야 해요. 같은 이슈를 두 번 식별하는 회고는 Playbook에 갭이 있다는 신호예요 — 수정은
조직의 암묵지가 아닌 이 문서에 반영되어야 해요.

---

## 주요 함정

| 함정 | 예방법 |
| --- | --- |
| 기능 감사 없이 오래된 코드 삭제 | 삭제 전 필드별 동등성 감사 수행 |
| 프로필별 파일에서 설정 속성 누락 | `application.properties`와 프로필 변형(`-dev`, `-test`, `-prod`)에 걸쳐 설정 추적 |
| 경계에서 Mock 처리된 테스트가 실제 Integration 버그를 숨김 | 최소 하나의 `@QuarkusTest`가 체인을 통해 흐르는 실제 인자를 검증 |
| 공유 컴포넌트 제거가 다른 CDI bean을 깨뜨림 | 공유 컴포넌트 제거 전 `grep -rl` + `./mvnw compile` 실행 |
| 새 코드에서 다른 의미로 필드 이름 재사용 | 이전 코드와 Javadoc을 읽으세요 — 이름만으로 의미적 동등성을 가정하지 마세요 |
| 설계 세션이 실행 전에 Context Window를 소진 | 설계와 실행은 항상 별도 세션; 생성된 Plan은 자체 완결적이어야 함 |
| 실행 시작 시 필수 plugin 미설치 | 작업에 나열된 모든 plugin이 실행 시작 전에 설치되고 활성화되었는지 확인(`/reload-plugins`) — AC 점검 시가 아닌 |
| 구현 후 ADR 작성 | 설계 Context가 신선한 대화 중에 ADR 작성 |
| Dev mode에서 무음 시작 실패 | 매번 재시작 후 Quarkus dev mode 콘솔 출력 확인; CDI 및 설정 오류 주시 |
| 로컬에서 잡히지 않는 API 호환성 깨짐 | REST endpoint나 Response 형태에 호환성 깨지는 변경을 Push하기 전에 `./mvnw verify`를 로컬에서 실행 |
| 코멘트나 문서에서 조작된 Metrics | 운영 데이터를 사용할 수 없으면 명시적으로 말하세요; 권위 있어 보이는 숫자를 만들어내지 마세요 |
| 사람이 요청할 때만 subagent 호출 | 필수 트리거 포인트를 사용하세요; PostToolUse hook이 자동으로 알림을 주입할 수 있어요 |
| Agent에게 너무 일찍 너무 많은 자율성 부여 | 단일 LLM + 도구로 시작; 측정 가능하게 더 나을 때만 Multi-Agent로 확대("최소 자유 원칙" 참조) |
| Orchestration 수정 대신 Prompt 조정 | 출력 품질이 낮을 때 Prompt를 다시 쓰기 전에 작업 순서 지정과 입력 구조를 재설계하세요 |
| Agent가 존재하지 않는 API 호출을 생성 | 각 작업 후 Import된 모든 클래스, 메서드, API 호출이 컴파일되는지 확인하세요 — API가 존재한다는 Agent의 확신을 신뢰하지 마세요 |
| Agent가 Plan 단계를 조용히 건너뜀 | 가정이 아닌 검증 게이트를 통한 명시적 작업 완료 추적; 각 세션 끝에서 Plan 체크리스트 검토 |
| Agent가 Framework 설정 속성을 만들어냄 | context7 문서 또는 Framework의 공식 레퍼런스에 대해 설정 속성 확인; 확인 없이 익숙하지 않은 속성을 수용하지 마세요 |
| Agent가 의미적으로 부정확한 비즈니스 로직 생성 | 사람 리뷰는 컴파일과 테스트 통과뿐만 아니라 도메인 정확성을 검증해야 해요; 테스트도 Agent가 생성한 경우 로직이 잘못되어도 테스트가 통과할 수 있어요 |
| 리뷰어가 설명할 수 없는 코드를 승인 | 리뷰어가 Agent의 접근 방식을 왜 선택했는지 설명할 수 없으면, 승인 전에 멈추고 조사하세요 — 이것은 역량 약화 신호예요 |

---

## 이식성 참고사항

이 Playbook의 구조는 Claude Code를 넘어 적응 가능하도록 설계되었어요:

**이식 가능한 요소** (도구에 구애받지 않음):
- 4단계 Workflow (설계 → 실행 → 리뷰 → 검증)
- 8가지 설계 원칙 전체
- 거버넌스 정책 및 자율성 경계
- 함정 테이블 및 Metrics Framework
- 사전 요건 요구사항 (티켓, ADR, 실제 데이터)

**Claude Code 고유 요소** (다른 도구에 적용 시 수정 필요):
- Slash command (`/brainstorming`, `/writing-plans`, `/executing-plans` 등)
- superpowers plugin 및 subagent 실행
- context7 및 frontend-design plugin 참조
- `Co-Authored-By` Commit 기여 표시 형식

이 Playbook을 다른 Agent 도구에 적용할 때는 이식 가능한 요소를 유지하고 도구 고유 요소를
대상 플랫폼의 동등한 기능으로 교체하세요.

---

## 참고자료

**프로젝트 문서:**

- [AGENTS.md](AGENTS.md) — 프로젝트 규칙 및 코딩 가이드라인
- [AI Agent References](docs/ai-agent-references.md) — 이 Playbook에 영향을 준 선별된 연구 및 아키텍처 가이드

**기반 연구:**

- [Building Effective Agents — Anthropic](https://www.anthropic.com/research/building-effective-agents) — Workflow와 Agent의 구분, 단순하게 시작하기 원칙, 핵심 아키텍처 패턴
- [Anthropic Agent Cookbook](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents) — Agent 패턴 코드 예시
- [2026 Agentic Coding Trends Report — Anthropic](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf) — 코딩 Agent가 개발을 어떻게 변화시키는지에 대한 데이터 기반 분석
- [Agentic Workflows for Software Development — QuantumBlack/McKinsey](https://medium.com/quantumblack/agentic-workflows-for-software-development-dc8e64f4a79d) — 규칙 기반 Orchestration 엔진 패턴 (Agent가 실행하고, Workflow가 순서를 관리)
- [2026 Guide to Agentic Workflow Architectures — Stack AI](https://www.stackai.com/blog/the-2026-guide-to-agentic-workflow-architectures) — 최소 자유 원칙, 네 가지 핵심 아키텍처
- [Andrew Ng's Four Agentic Design Patterns — DeepLearning.AI](https://www.deeplearning.ai/courses/agentic-ai/) — Reflection, Tool Use, Planning, Multi-Agent Collaboration
- [AI-Native Development vs. AI Agentic Development Workflows — Strategic Research Report](../ai-native-vs-agentic-development-report.md) — 이 향상된 버전에 정보를 제공한 비교 분석

**업계 거버넌스 및 도입:**

- [Agentic AI Enterprise Adoption Guide — Deloitte](https://www.deloitte.com/us/en/what-we-do/capabilities/applied-artificial-intelligence/articles/agentic-ai-enterprise-adoption-guide.html) — 단계적 도입, 거버넌스, 리스크 관리
- [AI-SDLC Maturity Model — ELEKS](https://eleks.com/blog/ai-sdlc-maturity-model/) — 5단계: Traditional → AI-Autonomous; 보안 리스크 데이터
- [AI Tools for Every SDLC Phase: 2026 Guide — MetaCTO](https://www.metacto.com/blogs/mapping-ai-tools-to-every-phase-of-your-sdlc) — AEMI 성숙도 평가 Framework

**Plugin:**

- [context7](https://claude.com/plugins/context7) — 라이브 라이브러리 문서 (Quarkus, LangChain4j, CDI 등)
- [superpowers](https://claude.com/plugins/superpowers) — Brainstorming, writing-plans, executing-plans, code-review skill
- [frontend-design](https://claude.com/plugins/frontend-design) — 프로덕션 수준의 웹 UI 생성; 브라우저 대면 컴포넌트가 있는 기능에 필수

---

## 개정 이력

### 2026-04-12 — 전략적 연구 보고서 검토 기반 향상 버전

[AI-Native Development vs. AI Agentic Development Workflows 전략적 연구 보고서](../ai-native-vs-agentic-development-report.md)에 대해 Playbook을 검토하고 업계 연구(Anthropic, McKinsey, Deloitte, ELEKS, Andrew Ng)의 발견사항을 반영했어요.

**변경사항:**

- **새로운 "거버넌스" 섹션** — 필수 사람 리뷰 카테고리, Agent 자율성 경계, 기여 표시 정책,
  감사 추적 요구사항. Deloitte의 도입 가이드와 ELEKS 성숙도 모델의 보안 리스크 발견사항에
  의해 주도됨.
- **새로운 "Metrics" 섹션** — 측정 항목(사람 수정률, 결함률, 보안 발견, Merge까지 소요
  시간), 수집 시점, 활용 방법. MetaCTO AEMI Framework와 McKinsey 생산성 측정 가이던스 기반.
- **새로운 설계 원칙 6: Reflection** — Andrew Ng의 네 번째 Agentic Design Pattern 반영.
  Agent가 사람 리뷰 전에 스펙에 대해 자체 출력을 검토함.
- **새로운 설계 원칙 8: 개발자는 승인하는 코드를 이해해야 함** — ELEKS 연구에서 식별된
  역량 약화 리스크 대응(AI 생성 코드의 40% 보안 취약점 비율).
- **향상된 서문** — AEMI/ELEKS Framework를 사용한 성숙도 수준 타게팅(Level 3 Intentional)
  추가, Anthropic 2026 신뢰 격차 데이터(사용률 80%, 신뢰도 29%) 기반의 신뢰 구축
  가이던스.
- **Phase 2의 새로운 "사람 리뷰 전 Self-review" 단계** — 4개 항목 체크리스트로 Reflection
  원칙을 실행으로 구체화.
- **Phase 4의 새로운 "보안 스캔" 단계** — SpotBugs 및 OWASP Dependency-Check 명령,
  AI 생성 코드의 40%에 보안 이슈가 포함된다는 ELEKS 발견에 의해 주도됨.
- **5개의 새로운 함정** — Agent가 존재하지 않는 API 호출을 생성, Agent가 Plan 단계를
  조용히 건너뜀, Agent가 Framework 설정 속성을 만들어냄, Agent가 의미적으로 부정확한
  비즈니스 로직 생성, 리뷰어가 설명할 수 없는 코드를 승인.
- **Phase 4의 향상된 종료 체크리스트** — 보안 스캔, 역량 약화 점검, 실행 요약 항목 추가.
- **새로운 "이식성 참고사항"** — 도구에 구애받지 않는 Playbook 요소와 Claude Code 고유
  요소를 식별, 보고서의 단일 LLM 제공자로부터의 분리 권고에 따름.
- **확장된 참고자료** — Andrew Ng의 설계 패턴, 전략적 연구 보고서, 업계 거버넌스 소스
  (Deloitte, ELEKS, MetaCTO) 추가.

### 2026-04-11 — Quarkus/Java 프로젝트에 맞춘 Playbook 조정

Python 기반 멀티 서비스 프로젝트에서 실제 Quarkus/Java 기술 스택에 맞게 Playbook을
적응시켰어요.

**변경사항:**

- **설정 섹션** — GitLab 전용 토큰 설정을 범용 VCS CLI 가이던스(GitHub `gh` 및
  GitLab `glab`)로 교체; 독립 이슈 트래커 CLI 섹션 제거
- **사전 요건** — `.pre-commit-config.yaml`을 Maven wrapper로 교체; Python 라이브러리
  참조(FastAPI, SQLAlchemy, dbt, Alembic, Pydantic)를 Quarkus, LangChain4j, CDI,
  RESTEasy, Hibernate로 교체
- **Phase 2** — `python -m pytest`를 `./mvnw test`로 교체; `dbt compile`을
  `./mvnw compile`로 교체; 서비스 간/K8s 데이터 흐름을 Quarkus 설정 속성 추적으로 교체
- **Phase 3** — GitLab `glab`과 함께 GitHub `gh` 명령 추가; PR/MR 용어 일반화
- **Phase 4** — podman compose 검증을 Quarkus dev mode로 교체; Python E2E 테스트
  명령을 `./mvnw verify`로 교체; Java/Quarkus에 맞게 종료 체크리스트 업데이트
- **주요 함정** — Python/dbt/K8s 고유 함정 제거; Quarkus 고유 함정(CDI 주입 실패,
  `@QuarkusTest`, 설정 프로필, dev mode 콘솔) 추가
- **생성됨** `docs/ADR/ADR-template.md` — 이전에 참조되었지만 누락되었던 파일
- **추가됨** Maven wrapper(`mvnw`) — AGENTS.md에서 참조되었지만 누락되었던 파일

### 2026-04-10 — 연구 기반 원칙 및 아키텍처 가이던스

[AI Agent References](docs/ai-agent-references.md)의 인사이트로 Playbook을 개선했어요.
Anthropic의 "Building Effective Agents" 연구, QuantumBlack/McKinsey의 Agentic Workflow
아키텍처, Stack AI의 아키텍처 가이드를 다루고 있어요.

**변경사항:**

- **새로운 "설계 원칙" 섹션** (6가지 원칙)이 설정 앞에 추가됨:
  1. 단순하게 시작하고, 필요할 때만 복잡성을 추가하세요 — Anthropic의 핵심 조언에서
  2. Workflow와 Agent — 이 Playbook이 특정 단계에서 Agent 기능을 갖춘 Workflow임을 설명
  3. Prompt Engineering보다 Orchestration — 작업 순서 지정이 Prompt 문구보다 중요
  4. Agent를 전문화하세요, 범용화하지 마세요 — 단일 Prompt 대신 별개의 skill을 사용하는 이유
  5. 최소 자유 원칙 — Stack AI의 아키텍처 가이드에서
  6. 첫날부터 Observability — 여러 출처의 합의에서
- **Phase 1의 새로운 "Step 0 — 적절한 복잡성 수준 선택"** — 가장 가벼운 접근 방식
  (단일 호출 vs. 전체 Playbook vs. 병렬 subagent)을 선택하기 위한 의사결정 테이블
- **향상된 Plan 작성 가이던스** — Plan을 규칙 기반 Orchestration 산출물로 설명
  (QuantumBlack/McKinsey 패턴에서)
- **2개의 새로운 함정** — Agent에게 너무 일찍 너무 많은 자율성 부여; Orchestration 수정
  대신 Prompt 조정
- **확장된 참고자료 섹션** — 설명과 함께 5개의 기반 연구 소스 추가
