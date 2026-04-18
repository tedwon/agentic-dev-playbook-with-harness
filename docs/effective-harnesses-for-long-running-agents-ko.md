# 장시간 실행 Agent를 위한 효과적인 Harness 설계

> 원문: [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — Anthropic Engineering Blog

---

## 핵심 문제: Agent는 왜 장시간 작업에서 실패할까?

AI Agent가 복잡한 작업을 수행할 때, 한 번의 Context Window(대화 세션)로는 끝나지 않는 경우가 많아요. 예를 들어, 웹 애플리케이션을 처음부터 구축하는 작업은 몇 시간, 심지어 며칠이 걸릴 수 있죠.

문제는 **새로운 세션이 시작될 때마다 이전 세션의 기억이 전혀 없다**는 거예요. 마치 매일 아침 새로운 개발자가 프로젝트에 투입되는데, 인수인계 없이 처음부터 코드를 파악해야 하는 상황과 같아요.

이 문제를 해결하기 위해 Anthropic이 제안하는 방법이 바로 **Harness(하네스)** 설계예요.

---

## 해결책: 2단계 Agent 구조

Anthropic은 인간 개발팀의 교대 근무 방식에서 영감을 받았어요. 핵심은 두 가지 역할의 Agent를 분리하는 거예요.

### 1단계: Initializer Agent (초기화 Agent)

프로젝트를 **처음 시작할 때 한 번만** 실행되는 Agent예요. 하는 일은 다음과 같아요:

| 작업 | 설명 |
|------|------|
| `init.sh` 생성 | 개발 환경을 자동으로 설정하는 Script |
| `claude-progress.txt` 생성 | Agent가 수행한 작업을 기록하는 진행 노트 |
| 초기 Git Commit | 프로젝트의 기준점(Baseline)을 만드는 첫 Commit |

이것은 마치 새 팀원이 합류하기 전에 **프로젝트 환경과 문서를 미리 준비해 두는 것**과 같아요.

### 2단계: Coding Agent (코딩 Agent)

이후 세션마다 실행되는 Agent예요. 매 세션 시작 시 다음 순서를 따라요:

```
1. 진행 노트(claude-progress.txt) 읽기
2. Git 히스토리 확인하기
3. 구현할 Feature 하나 선택하기
4. 구현 및 테스트하기
5. 완료되면 Commit하고 진행 노트 업데이트하기
```

핵심은 **한 번에 하나의 Feature만 작업한다**는 거예요. 욕심내서 여러 개를 동시에 하면 Context가 소진되어 중간에 실패할 확률이 높아져요.

---

## Harness의 핵심 구성 요소

### Feature List (기능 목록)

Initializer Agent가 **200개 이상의 구체적인 Feature를 JSON 파일로 생성**해요. 각 Feature는 처음에 "실패" 상태로 표시되어 있어요.

중요한 규칙이 있어요:

> **"테스트를 삭제하거나 수정하는 것은 절대 허용되지 않는다."**

이렇게 하면 Agent가 "테스트를 통과시키기 위해 테스트 자체를 고치는" 꼼수를 쓰지 못해요. Feature를 실제로 구현해야만 테스트가 통과되는 구조예요.

### Progress Notes (진행 기록)

매 세션이 끝날 때 Agent는 자신이 한 일을 `claude-progress.txt`에 기록해요. 다음 세션의 Agent는 이 파일을 읽고 **이전 세션에서 어디까지 진행했는지** 파악할 수 있어요.

이것은 교대 근무에서 **인수인계 문서**와 같은 역할을 해요.

### Testing Protocol (테스트 규약)

Agent는 코드 리뷰만으로는 발견하기 어려운 버그를 잡기 위해 **Browser Automation(Puppeteer)을 활용한 End-to-End 테스트**를 수행해요. 실제 사용자처럼 브라우저에서 기능을 확인하는 거예요.

---

## Agent가 흔히 실패하는 4가지 패턴과 해결책

Anthropic이 실험을 통해 발견한 주요 실패 패턴이에요:

| 실패 패턴 | 문제 | 해결책 |
|-----------|------|--------|
| **조기 완료 선언** | 아직 안 끝났는데 "다 했다"고 보고 | Feature List로 남은 작업을 명확히 추적 |
| **버그 있는 인수인계** | 깨진 상태로 Commit하여 다음 세션이 혼란 | Git Commit과 Progress Notes로 깨끗한 상태 유지 |
| **불완전한 테스트** | 코드만 보고 "잘 돌아갈 것"이라 판단 | Browser Automation으로 실제 동작 확인 |
| **환경 설정 혼란** | 매 세션마다 환경을 어떻게 시작할지 헤맴 | `init.sh` Script로 환경 자동 설정 |

---

## 세션 시작 루틴

모든 Coding Agent 세션은 동일한 루틴으로 시작해요:

```
1. 현재 디렉토리 확인
2. 진행 기록(Progress Notes) 읽기
3. Feature List 확인 (어떤 기능이 남았는지)
4. 기본 기능 테스트 실행
5. 점진적 Feature 작업 시작
```

이 루틴이 일관되게 유지되기 때문에, Agent가 매번 "어디서부터 시작하지?"라고 헤매는 시간이 없어져요.

---

## 우리 프로젝트와의 연결

이 Anthropic 문서의 원칙은 우리 프로젝트의 Harness Engineering과 직접적으로 연결돼요:

| Anthropic 원칙 | 우리 프로젝트 적용 |
|----------------|-------------------|
| Feature List로 진행 추적 | `CHECKLIST.md`로 7가지 품질 검증 |
| Progress Notes로 상태 기록 | Git Commit과 `claude-progress.txt` |
| `init.sh`로 환경 자동화 | `./mvnw` Wrapper와 Pre-commit Hook |
| 테스트 삭제 금지 | CONV-02: 모든 `@Path` 클래스에 테스트 필수 |
| 점진적 Feature 구현 | Agentic Playbook의 단계별 실행 |
| 세션 시작 루틴 | CLAUDE.md와 AGENTS.md 규칙 자동 로딩 |

---

## 미래 방향: 아직 풀리지 않은 질문들

Anthropic은 아직 탐구 중인 영역도 솔직하게 공유하고 있어요:

- **Multi-Agent vs Single Agent**: 테스트 전문 Agent, QA Agent, 정리 Agent 등을 따로 두는 게 나을까, 아니면 하나의 범용 Agent가 더 효과적일까?
- **다른 도메인으로의 확장**: 웹 개발 외에 과학 연구, 금융 모델링 같은 분야에서도 같은 원칙이 통할까?

---

## 핵심 요약

```
장시간 Agent 작업의 성공 공식:

  1. 기억의 다리를 놓아라 → Progress Notes + Git History
  2. 한 번에 하나만 해라 → 점진적 Feature 구현
  3. 직접 확인해라 → Browser Automation 테스트
  4. 환경을 자동화해라 → init.sh Script
  5. 꼼수를 막아라 → 테스트 수정 금지 규칙
```

> **"Agent에게 자유를 주되, Harness로 방향을 잡아줘라."**
> — Anthropic의 Harness Engineering 철학
