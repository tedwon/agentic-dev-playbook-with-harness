# Harness Engineering Guide

> JBUG Korea 세미나 데모 — AI 에이전트의 자율적 개발을 가능하게 하는 harness engineering 소개

## Harness Engineering이란?

**Agent = Model + Harness**

AI 에이전트는 LLM 모델 단독으로는 안정적인 개발을 할 수 없습니다.
"하네스(harness)"란 모델을 감싸는 모든 인프라(환경)를 의미합니다:

- **규칙(Rules):** 에이전트가 따라야 하는 개발 규칙 (CLAUDE.md, AGENTS.md)
- **검증(Verification):** 규칙 준수 여부를 자동으로 확인하는 hooks
- **피드백 루프(Feedback Loops):** 위반 시 구체적인 수정 방법을 에이전트에게 전달
- **가드레일(Guardrails):** 위험한 변경을 원천적으로 차단 (protected files)

**핵심 발견:** 하네스 개선만으로 코딩 벤치마크에서 30위 → 5위로 상승한 사례가 있습니다.
모델을 바꾸지 않고도, 하네스만 잘 설계하면 에이전트의 성능이 극적으로 향상됩니다.

## 두 가지 제어 방식

### Feedforward Controls (가이드 — 예방적)

에러가 발생하기 **전에** 에이전트의 행동을 안내합니다. 고속도로의 가드레일과 같습니다.

| 파일 | 역할 |
| ---- | ---- |
| CLAUDE.md | 프로젝트 규칙, 자기교정 프로토콜 |
| AGENTS.md | 개발 규칙, 기술 스택 가이드 |
| CHECKLIST.md | 커밋 전 통과해야 하는 7가지 검증 항목 |

### Feedback Controls (센서 — 교정적)

에러가 발생한 **후에** 감지하고 수정을 유도합니다. 테스트 스위트와 같습니다.

| Hook | 시점 | 역할 |
| ---- | ---- | ---- |
| pre-commit-harness.sh | git commit 전 | 7가지 검증 실행, 실패 시 차단 |
| protect-files.sh | 파일 편집 전 | 하네스 설정 파일 수정 차단 |
| post-edit-verify.sh | 파일 편집 후 | Java 파일 편집 시 빠른 컴파일 체크 |

## 자기교정 루프 (Self-Correction Loop)

이 데모의 핵심 혁신입니다:

```text
┌─────────────────────────────────────────────────┐
│                                                 │
│  1. AI 에이전트가 코드 작성                      │
│                    │                            │
│                    ▼                            │
│  2. git commit 시도                              │
│                    │                            │
│                    ▼                            │
│  3. Pre-commit 하네스가 7가지 검증 실행           │
│                    │                            │
│              모두 통과?                          │
│              /        \                         │
│           Yes          No                       │
│            │            │                       │
│            ▼            ▼                       │
│     커밋 완료!    에러 메시지 출력                │
│     (exit 0)     (exit 2)                       │
│                         │                       │
│                         ▼                       │
│                  에이전트가 에러 읽고              │
│                  자동으로 수정                    │
│                         │                       │
│                         └────── 재시도 ──────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

**인간의 개입 없이** 에이전트가 스스로 품질 기준을 충족할 때까지 반복합니다.

## 7가지 자동 검증 항목

| ID | 검증 | 통과 기준 |
| -- | ---- | --------- |
| BUILD-01 | 컴파일 | `./mvnw compile -q` 성공 |
| BUILD-02 | 테스트 | `./mvnw test` 모든 테스트 통과 |
| BUILD-03 | 코드 포맷 | `./mvnw spotless:check -q` 통과 |
| QUAL-01 | System.out 금지 | Logger만 허용 |
| QUAL-02 | 시크릿 금지 | 하드코딩된 비밀번호/키 없음 |
| CONV-01 | 커밋 메시지 형식 | Conventional Commits 준수 |
| CONV-02 | 테스트 커버리지 | REST 엔드포인트별 테스트 필수 |

## 데모 시나리오

### 시연할 내용

"AI 에이전트에게 새 REST 엔드포인트 추가를 요청합니다."

```text
User: "Add a /time endpoint that returns the current server time in ISO format"
```

### 하네스가 자동으로 잡는 것들

1. **테스트 파일 누락** (CONV-02) — `TimeResourceTest.java` 없으면 차단
2. **System.out.println 사용** (QUAL-01) — Logger로 교체 요구
3. **잘못된 커밋 메시지** (CONV-01) — Conventional Commits 형식 요구
4. **코드 포맷 위반** (BUILD-03) — Spotless 자동 수정 안내

### 기대 결과

에이전트가 모든 위반 사항을 자동으로 수정하고, 인간의 개입 없이 커밋을 완료합니다.

## 프로젝트 구조

```text
quarkus-agentic-dev-playbook-with-harness/
├── CLAUDE.md                         # 하네스 규칙 + 자기교정 프로토콜
├── AGENTS.md                         # 개발 가이드 + 하네스 엔지니어링 섹션
├── CHECKLIST.md                      # 7가지 검증 규칙 체크리스트
├── .claude/
│   ├── settings.json                 # Hook 설정 + 권한
│   ├── hooks/
│   │   ├── pre-commit-harness.sh    # 메인 pre-commit 검증 (7 checks)
│   │   ├── protect-files.sh          # 보호 파일 수정 차단
│   │   └── post-edit-verify.sh      # 편집 후 컴파일 체크
│   └── skills/
│       └── agentic-playbook/        # Agentic 워크플로우 스킬
├── pom.xml                           # Maven + Spotless 플러그인
├── src/main/java/                    # 애플리케이션 코드
├── src/test/java/                    # 테스트 코드
└── docs/
    └── harness-engineering-guide.md  # 이 문서
```

## 참고 자료

### Harness Engineering 개념

- OpenAI: [Harness Engineering](https://openai.com/index/harness-engineering/) — "Agent = Model + Harness" 개념의 기원
- OpenAI: [Unlocking the Codex Harness](https://openai.com/index/unlocking-the-codex-harness/) — 코딩 에이전트용 하네스 실전 사례

### Anthropic 연구

- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — 장기 실행 에이전트를 위한 효과적인 하네스 설계
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — Feedforward/Feedback 제어 패턴
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — 에이전트 설계의 기초 원칙

### 커뮤니티 리소스

- [Awesome Harness Engineering](https://github.com/ai-boost/awesome-harness-engineering) — 하네스 엔지니어링 리소스 모음
- [Claude Code Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks) — Claude Code hook 시스템 공식 문서
