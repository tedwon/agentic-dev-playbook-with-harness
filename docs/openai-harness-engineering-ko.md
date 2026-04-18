# Harness Engineering: Agent 시대의 Codex 활용법

> OpenAI 원문: [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/) (2026년 2월 11일)
>
> 이 문서는 OpenAI의 Harness Engineering 기사를 한국어로 이해하기 쉽게 정리한 것이에요.

---

## 목차

1. [핵심 요약](#핵심-요약)
2. [실험: 사람이 코드를 한 줄도 쓰지 않은 프로젝트](#실험-사람이-코드를-한-줄도-쓰지-않은-프로젝트)
3. [Harness란 무엇인가?](#harness란-무엇인가)
4. [엔지니어의 역할 변화](#엔지니어의-역할-변화)
5. [Context 관리: 지도를 주되, 백과사전을 주지 마라](#context-관리-지도를-주되-백과사전을-주지-마라)
6. [아키텍처 강제: 제안이 아닌 규칙으로](#아키텍처-강제-제안이-아닌-규칙으로)
7. [Feedforward와 Feedback: 두 가지 제어 방식](#feedforward와-feedback-두-가지-제어-방식)
8. [Entropy 관리: "AI Slop" 문제 해결](#entropy-관리-ai-slop-문제-해결)
9. [Agent 자율성과 Self-Validation](#agent-자율성과-self-validation)
10. [핵심 교훈과 실전 팁](#핵심-교훈과-실전-팁)
11. [아직 풀리지 않은 질문들](#아직-풀리지-않은-질문들)
12. [참고 자료](#참고-자료)

---

## 핵심 요약

OpenAI의 Codex 팀이 **5개월 동안 사람이 직접 코드를 한 줄도 작성하지 않고** 내부
Beta 제품을 만들어 출시했어요. 약 **100만 줄**의 Agent 생성 코드, **1,500개 이상**의
Pull Request, **3명의 엔지니어**로 이뤄낸 결과예요.

이 경험에서 얻은 가장 중요한 교훈은 이거예요:

> **"어려운 건 Agent가 아니라 Harness다."**
>
> 모델을 바꾸지 않고 Harness만 개선해도 성능이 극적으로 향상된다.

LangChain 팀이 이를 실증했어요. 동일한 모델로 Harness만 변경했더니 Terminal Bench
2.0에서 **52.8% → 66.5%**로 성적이 올라 **30위에서 5위**로 뛰어올랐어요.

---

## 실험: 사람이 코드를 한 줄도 쓰지 않은 프로젝트

### 실험 개요

| 항목 | 내용 |
|------|------|
| 시작 시점 | 2025년 8월 말 (빈 Repository에서 출발) |
| 기간 | 약 5개월 |
| 팀 규모 | 엔지니어 3명 |
| 코드량 | 약 100만 줄 (Application 로직, 인프라, 문서, 도구 포함) |
| Pull Request 수 | 약 1,500개 (엔지니어당 하루 평균 3.5개) |
| 사람이 쓴 코드 | **0줄** |
| 결과물 | 내부 일일 사용자 + 외부 Alpha 테스터가 사용하는 Beta 제품 |

### 초기 Scaffold

첫 번째 Commit은 Repository 구조, CI 설정, 포맷팅 규칙, 패키지 매니저 설정,
Application Framework 등의 초기 Scaffold로 구성되었어요. 이것 역시 Codex CLI가
GPT-5를 사용해 생성한 것이에요.

심지어 Agent에게 작업 방법을 지시하는 **AGENTS.md 파일 자체도 Codex가 작성**했어요.
처음부터 인간이 작성한 코드가 시스템의 기반이 된 적이 없어요.

### 핵심 발견

초기 진행이 예상보다 느렸는데, Codex가 능력이 없어서가 아니라 **환경이 충분히
명세되지 않았기 때문**이었어요. Agent에게 도구, 추상화, 내부 구조가 부족했던 거예요.

> **"실패했을 때 해결책은 거의 '더 열심히 시도'가 아니었다."**
>
> 해결책은 항상 **환경(Harness)을 개선하는 것**이었다.

---

## Harness란 무엇인가?

### 정의

**Harness**는 AI Agent에서 **모델을 제외한 모든 것**을 의미해요.

```
Agent = Model + Harness
```

"Harness"라는 단어는 말(馬)에 쓰는 마구(馬具)에서 왔어요 — 강력하지만 예측 불가능한
동물을 유용한 방향으로 이끄는 고삐, 안장, 재갈을 뜻해요.

### Harness의 구성 요소

| 구성 요소 | 설명 | 예시 |
|-----------|------|------|
| **규칙 (Rules)** | Agent가 따라야 하는 개발 규칙 | CLAUDE.md, AGENTS.md |
| **검증 (Verification)** | 규칙 준수 여부를 자동 확인 | Pre-commit Hook, Linter, Test |
| **피드백 루프 (Feedback Loop)** | 위반 시 수정 방법을 Agent에게 전달 | 구조화된 Error Message |
| **가드레일 (Guardrail)** | 위험한 변경을 원천 차단 | Protected File, 의존성 제한 |
| **문서 (Documentation)** | Agent가 참조하는 지식 베이스 | `docs/` 디렉토리, Architecture 문서 |
| **도구 (Tooling)** | Agent의 작업을 지원하는 인프라 | CI/CD, Observability, 개발 환경 |

### Martin Fowler의 정의

Martin Fowler(Thoughtworks)는 Harness Engineering을 다음과 같이 정의했어요:

> **"AI Agent를 통제하면서도 능력을 향상시키는 도구와 실천 방법"**

Harness의 범위는 단순한 안전장치를 넘어서, Agent의 **능력 자체를 향상**시키는 것까지
포함해요.

---

## 엔지니어의 역할 변화

Harness Engineering에서 엔지니어의 역할은 근본적으로 바뀌어요:

| 기존 역할 | Harness Engineering에서의 역할 |
|-----------|-------------------------------|
| 코드 작성 | **코드를 전혀 쓰지 않음** |
| 기능 구현 | **아키텍처 설계** (Agent가 따를 구조) |
| 문서 작성 (부가적) | **문서를 핵심 인프라로 격상** |
| 코드 리뷰 | **Agent 출력 품질 + Harness 효과성 리뷰** |
| 디버깅 | **Harness 개선** (같은 오류가 반복되지 않도록) |

실제 작업 방식은 **깊이 우선(Depth-First)**이었어요:

1. 큰 목표를 작은 빌딩 블록으로 분해
2. Agent에게 그 블록들을 구축하도록 Prompt
3. 완성된 블록을 활용해 더 복잡한 작업 수행
4. 실패하면 **Harness를 개선** (Agent에게 "더 노력해"라고 하지 않음)

> 엔지니어의 주된 업무는 **Agent가 유용한 작업을 할 수 있도록 환경을 만드는 것**이 되었다.

---

## Context 관리: 지도를 주되, 백과사전을 주지 마라

### 초기 실패: "거대한 AGENTS.md" 접근법

OpenAI 팀이 가장 먼저 배운 교훈 중 하나예요:

> **"Codex에게 지도를 주세요. 1,000페이지짜리 설명서를 주지 마세요."**

처음에는 모든 규칙과 지침을 하나의 큰 AGENTS.md 파일에 담으려 했지만 **실패**했어요.
Context는 희소한 자원이고, 거대한 지침 파일은 실제 작업, 코드, 관련 문서가 들어갈
공간을 빼앗아요.

### 해결책: 계층적 문서 구조

| 역할 | 구현 |
|------|------|
| **지도 (Map)** | AGENTS.md — 약 100줄의 짧은 안내 파일 |
| **실제 지식** | `docs/` 디렉토리에 구조화된 문서로 분산 |

OpenAI의 Repository는 하위 컴포넌트별로 **88개의 AGENTS.md 파일**을 사용해요.
이는 Monorepo 규모에서 제약 조건을 구성하는 방법을 보여줘요.

### Context Engineering과의 관계

Harness Engineering과 관련된 세 가지 Engineering 분야가 있어요:

| 분야 | 범위 | 최적화 대상 |
|------|------|------------|
| **Prompt Engineering** | 단일 상호작용 | 한 번의 요청에 대한 지침 최적화 |
| **Context Engineering** | 하나의 Context Window 내 여러 턴 | Token 집합 관리 |
| **Harness Engineering** | 여러 세션, 여러 Agent에 걸친 시스템 | Context Reset, 구조화된 Handoff, Phase Gate |

Harness Engineering은 Prompt Engineering과 Context Engineering의 **상위에**
위치해요. 단일 턴 기법을 멀티 세션, 멀티 Agent 문제에 적용하는 실수를 방지할 수 있어요.

### 핵심 원칙

> **"Agent 관점에서, Context에 없는 것은 존재하지 않는다."**

따라서 Harness는 다음을 포함해야 해요:

- **정적 Context:** 프로젝트별 문서, 스타일 가이드
- **동적 Context:** Observability 데이터, 디렉토리 구조 매핑, CI/CD Pipeline 상태

---

## 아키텍처 강제: 제안이 아닌 규칙으로

### 엄격한 Layer 아키텍처

OpenAI는 **구현을 미시적으로 관리하지 않고, 불변 조건(Invariant)을 강제**하는
방식을 택했어요. 핵심은 단방향 의존성을 가진 엄격한 Layer 아키텍처예요:

```
Types → Config → Repo → Service → Runtime → UI
```

각 Layer는 **왼쪽 Layer에서만 Import**할 수 있어요. 예를 들어:
- `Service`는 `Repo`, `Config`, `Types`를 Import할 수 있어요
- `Service`는 `Runtime`이나 `UI`를 Import할 수 **없어요**

### 기계적 강제 (Mechanical Enforcement)

규칙은 **제안이 아니라 기계적으로 강제**돼요:

| 도구 | 역할 |
|------|------|
| **Deterministic Linter** | 의존성 방향 위반 감지 |
| **LLM 기반 Auditor** | 의미적 패턴 위반 감지 |
| **Structural Test** | 모듈 경계 검증 (예: ArchUnit) |
| **Pre-commit Hook** | Commit 시점에 자동 차단 |

중요한 설계 결정: Error Message에 **수정 방법을 인라인으로 포함**해요. Agent가
"무엇이 잘못됐는지"뿐만 아니라 "어떻게 고쳐야 하는지"도 즉시 알 수 있어요.

### 역설: 제약이 생산성을 높인다

직관에 반하지만, 엄격한 제약은 Agent의 생산성을 **향상**시켜요. Agent가 탐색해야
하는 해결 공간(Solution Space)이 줄어들기 때문이에요.

> 자유도가 높으면 Agent는 더 많은 선택지를 탐색하느라 시간을 낭비하거나
> 잘못된 패턴을 선택할 확률이 높아져요.

---

## Feedforward와 Feedback: 두 가지 제어 방식

Martin Fowler의 기사(Birgitta Boeckeler, Thoughtworks)에서 체계적으로 정리한
프레임워크를 소개해요.

### Feedforward Control (가이드 - 사전 예방)

Agent가 행동하기 **전에** 동작을 안내하여, 첫 번째 시도에서 좋은 결과를 만들
확률을 높여요.

**예시:**
- AGENTS.md / CLAUDE.md (프로젝트 규칙)
- Architecture 문서 (의존성 방향, Layer 구조)
- 코드 스타일 가이드
- CHECKLIST.md (통과 기준)

### Feedback Control (센서 - 사후 교정)

Agent가 행동한 **후에** 결과를 관찰하고 자기 수정을 도와요.

**예시:**
- Test Suite (단위 테스트, 통합 테스트)
- Linter / Formatter
- Pre-commit Hook
- CI/CD Pipeline

### 핵심 통찰

> **"둘 중 하나만 있으면 불완전해요:**
> - Feedback만 있으면 → Agent가 같은 실수를 계속 반복해요
> - Feedforward만 있으면 → 규칙은 인코딩하지만 실제로 작동하는지 확인할 수 없어요
>
> **둘 다 필요해요."**

### 실행 유형: Computational vs Inferential

| 유형 | 특성 | 예시 | 속도 | 신뢰도 |
|------|------|------|------|--------|
| **Computational** | 결정적, CPU 구동 | Test, Linter, Type Checker | 밀리초~초 | 높음 (예측 가능) |
| **Inferential** | 의미적 분석, LLM 활용 | Code Review Agent, "LLM as Judge" | 느림 | 비결정적 (의미적으로 풍부) |

### 제어의 세 가지 영역

#### 1. 유지보수성 Harness (가장 성숙)

기존 도구가 풍부한 영역이에요:
- 중복 코드, 순환 복잡도, 테스트 커버리지 누락 감지
- 아키텍처 Drift, 스타일 위반 감지
- LLM Sensor로 의미적 중복, 과도한 Engineering 감지

#### 2. 아키텍처 적합성 Harness

아키텍처 특성을 정의하는 Fitness Function 활용:
- 성능 요구사항 → 성능 테스트로 검증
- Observability 규칙 (Logging 표준) → 디버깅 지침으로 Agent Reflection
- 모듈 경계 → Structural Test로 강제 (예: ArchUnit)

#### 3. 동작 Harness (가장 어려움)

현재 가장 도전적인 영역:
- Feedforward: 기능 명세 (간단한 Prompt부터 다중 파일 설명까지)
- Feedback: AI 생성 Test Suite, Coverage + Mutation Testing
- 한계: AI가 생성한 테스트에 대한 과도한 의존

---

## Entropy 관리: "AI Slop" 문제 해결

### 문제: AI Slop이란?

Agent가 코드를 대량 생성하면 시간이 지남에 따라 코드베이스에 **Entropy(무질서)**가
쌓여요. 이를 "AI Slop"이라고 해요:

- 일관성 없는 패턴
- 불필요한 코드 중복
- 문서와 실제 코드의 불일치
- 과도하게 복잡한 해결책

### OpenAI의 초기 대응

팀은 처음에 매주 금요일, **주당 근무 시간의 20%**를 AI Slop 정리에 사용했어요.
이는 수동적이고 비효율적이었어요.

### 해결책: 자동화된 Entropy 관리

프로젝트의 핵심 원칙을 Repository에 인코딩한 후, **백그라운드 Codex Task를
스케줄에 따라 실행**하여 문제를 해결했어요:

| 자동화 작업 | 설명 |
|------------|------|
| 문서 일관성 검증 | 문서와 실제 코드의 일치 여부 확인 |
| 제약 위반 스캐닝 | 아키텍처 규칙 위반 탐지 |
| 패턴 강제 | 코드 패턴 표준화 |
| 의존성 감사 | 불필요하거나 위험한 의존성 확인 |

이 Agent들은 규칙 위반을 발견하면 **Refactoring PR을 자동 제출**하고,
대부분 **1분 이내에 자동 Merge**되었어요.

> **핵심:** 같은 문제가 여러 번 발생하면, Feedforward와 Feedback Control을
> 개선하여 미래에 그 문제가 발생할 확률을 줄이거나 완전히 방지해야 해요.

---

## Agent 자율성과 Self-Validation

### 작업 흐름

OpenAI 엔지니어들은 시스템과 **거의 전적으로 Prompt를 통해** 상호작용해요:

1. 엔지니어가 작업을 설명
2. Agent 실행
3. Agent가 Pull Request를 생성
4. PR 완성을 위해 Agent에게 다음을 지시:
   - 자신의 변경사항을 로컬에서 Self-Review
   - 추가 Agent Review 요청
   - 피드백에 응답
   - 모든 Agent Reviewer가 만족할 때까지 반복

### 장시간 자율 실행

Codex Task는 한 번에 **6시간 이상** 연속 실행되었어요 — 보통 엔지니어가 **자는
동안** 진행되었어요.

### 시스템 자율 운영

> **"시스템은 스스로 배포하고, 장애를 일으키고, 수정한다 — 모두 Harness 내의
> Agent가 처리한다."**

---

## 핵심 교훈과 실전 팁

### 1. Harness 설계 원칙

| 원칙 | 설명 |
|------|------|
| **지도를 주세요, 백과사전 말고** | Context는 희소 자원 — 짧고 구조화된 안내를 제공 |
| **불변 조건을 강제하세요, 구현을 강제하지 마세요** | Agent에게 *무엇을* 해야 하는지 알려주되, *어떻게*는 자율에 맡기기 |
| **Error Message에 수정 방법을 포함하세요** | Agent가 오류를 읽고 즉시 자기 수정할 수 있도록 |
| **모든 실패를 한 번에 보고하세요** | 첫 번째 실패에서 멈추지 말고, 모든 문제를 수집해서 한 번에 전달 |
| **보호 파일을 설정하세요** | Agent가 규칙 자체를 수정해서 검사를 "통과"하는 것을 방지 |

### 2. 품질 검사를 개발 주기 전체에 분산

| 단계 | 검사 유형 | 예시 |
|------|-----------|------|
| **Pre-Integration (빠른 검사)** | LSP, 아키텍처 문서, 기본 Linter, 빠른 Test | 편집 직후 |
| **Post-Integration (고비용 검사)** | Mutation Testing, 포괄적 Code Review, 아키텍처 검증 | CI Pipeline |
| **지속적 모니터링 (Drift 감지)** | Dead Code, 테스트 품질, 의존성 스캐닝, SLO 모니터링 | 스케줄 기반 |

### 3. Harnessability (Harness 적용 용이성)

모든 코드베이스가 동일하게 Harness를 지원하는 건 아니에요:

| 특성 | Harness 적합도 |
|------|---------------|
| 강타입 언어 (Java, TypeScript 등) | 높음 — Type Checking Sensor 자연 지원 |
| 잘 정의된 모듈 경계 | 높음 — 아키텍처 제약 적용 용이 |
| Framework 추상화 (Quarkus, Spring 등) | 높음 — Agent 결정 복잡도 감소 |
| 기술 부채가 많은 Legacy 시스템 | 낮음 — 기존 부채에 Control을 후행 적용 필요 |

### 4. Harness Template 개념

일반적인 서비스 유형별로 미리 구축된 Harness 번들을 만들 수 있어요:

| 서비스 유형 | 포함 항목 |
|------------|-----------|
| CRUD API | REST 규칙, 테스트 패턴, DB Migration 검증 |
| Event Processor | 메시지 스키마 검증, 멱등성 테스트 |
| Data Dashboard | 시각화 규칙, 쿼리 성능 검증 |

---

## 아직 풀리지 않은 질문들

OpenAI 팀도 인정하듯, 아직 해결되지 않은 도전 과제들이 있어요:

1. **장기적 아키텍처 일관성** — Agent가 생성한 시스템이 수년에 걸쳐 아키텍처
   일관성을 유지할 수 있을까?

2. **Harness 성장 관리** — Harness가 커지면서 서로 모순되는 Guide와 Sensor가
   생길 수 있어요. 이를 어떻게 관리할까?

3. **Harness 커버리지 측정** — 코드 커버리지처럼 Harness의 커버리지와 품질을
   측정하는 방법이 필요해요.

4. **침묵하는 Sensor 해석** — Sensor가 아무 문제도 감지하지 않을 때, 이것이
   실제로 품질이 좋은 건지 아니면 감지 능력이 부족한 건지 어떻게 구분할까?

5. **인간 판단의 최적 위치** — 인간의 판단이 가장 큰 가치를 발휘하는 지점이 어디인지
   아직 탐색 중이에요.

> **"소프트웨어 구축에는 여전히 규율이 필요하지만, 그 규율은 이제 코드가 아닌
> Scaffolding에서 나타난다."**

---

## 참고 자료

### 원문 및 OpenAI 기사

- [Harness engineering: leveraging Codex in an agent-first world (OpenAI)](https://openai.com/index/harness-engineering/) — 원문 기사
- [Unlocking the Codex harness: how we built the App Server (OpenAI)](https://openai.com/index/unlocking-the-codex-harness/) — Codex Harness 실전 사례

### Anthropic 연구

- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — 장기 실행 Agent를 위한 Harness 설계
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — Feedforward/Feedback 제어 패턴

### 해설 및 분석

- [Harness engineering for coding agent users (Martin Fowler / Thoughtworks)](https://martinfowler.com/articles/harness-engineering.html) — Feedforward/Feedback 프레임워크의 체계적 정리
- [Harness Engineering: The Complete Guide (NxCode)](https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026) — 종합 가이드
- [OpenAI Introduces Harness Engineering (InfoQ)](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex/) — InfoQ 뉴스 분석

### 커뮤니티 리소스

- [Awesome Harness Engineering (GitHub)](https://github.com/ai-boost/awesome-harness-engineering) — Harness Engineering 리소스 모음
- [Learn Harness Engineering (GitHub)](https://github.com/walkinglabs/learn-harness-engineering) — 입문자용 튜토리얼
