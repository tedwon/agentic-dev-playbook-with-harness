# Harness 작동 원리

이 프로젝트의 Harness Engineering 구현에 대한 종합 가이드입니다:
각 구성 요소의 작동 방식, 연결 구조, 그리고 예제를 통한 시스템 사용법을 설명해요.

---

## 목차

1. [개요](#개요)
2. [아키텍처](#아키텍처)
3. [구성 요소 상세 분석](#구성-요소-상세-분석)
   - [Feedforward Control (가이드)](#feedforward-control-가이드)
   - [Feedback Control (센서)](#feedback-control-센서)
4. [Hook 시스템 내부 구조](#hook-시스템-내부-구조)
   - [Pre-Commit Harness](#1-pre-commit-harness)
   - [파일 보호](#2-파일-보호)
   - [편집 후 검증](#3-편집-후-검증)
5. [7가지 자동 검사 항목](#7가지-자동-검사-항목)
6. [자기 수정 루프](#자기-수정-루프)
7. [사용 예제](#사용-예제)
   - [예제 1: 새로운 REST Endpoint 추가 (정상 경로)](#예제-1-새로운-rest-endpoint-추가-정상-경로)
   - [예제 2: Harness가 위반 사항을 감지하고 수정](#예제-2-harness가-위반-사항을-감지하고-수정)
   - [예제 3: 보호 파일 Guardrail](#예제-3-보호-파일-guardrail)
8. [커스터마이징 가이드](#커스터마이징-가이드)
9. [문제 해결](#문제-해결)

---

## 개요

이 프로젝트는 **Harness Engineering**을 구현하고 있어요 — AI Agent를 신뢰성 있고
자율적으로 만드는 데 필요한 스캐폴딩을 설계하는 기술 분야예요.

**핵심 원칙:**

```
Agent = Model + Harness
```

AI Model(Claude, GPT 등)이 코드를 생성해요. Harness는 품질을 검증하고,
잘못된 Commit을 차단하며, 실행 가능한 피드백을 제공하고, Agent가 사람의 개입 없이
스스로 수정할 수 있게 해줘요.

**실제로 어떻게 작동하나요:** AI Agent가 코드를 작성하고 Commit을 시도하면,
Harness가 자동으로 7가지 품질 검사를 실행해요. 하나라도 실패하면 Commit이
차단되고, Agent는 정확히 무엇을 수정해야 하는지 상세한 오류 메시지를 받아요.
Agent가 문제를 수정하고 다시 시도하면 돼요. 모든 검사를 통과할 때까지 이 루프가
계속돼요 — 사람이 필요 없어요.

---

## 아키텍처

```text
┌──────────────────────────────────────────────────────────────────────┐
│                         HARNESS ARCHITECTURE                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  FEEDFORWARD CONTROLS (오류 예방)                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐                │
│  │  CLAUDE.md   │  │  AGENTS.md  │  │ CHECKLIST.md │                │
│  │ Harness 규칙 │  │ 개발 가이드 +│  │ 7개 검사 규칙│                │
│  │ 자기 수정    │  │ Harness Eng │  │ Rule ID 포함 │                │
│  │ 프로토콜     │  │ 섹션        │  │              │                │
│  └─────────────┘  └─────────────┘  └──────────────┘                │
│                                                                      │
│  FEEDBACK CONTROLS (감지 + 수정)                                    │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  .claude/settings.json (Hook 연결)                        │       │
│  │                                                           │       │
│  │  PreToolUse: Bash  ─────> pre-commit-harness.sh          │       │
│  │  PreToolUse: Edit  ─────> protect-files.sh               │       │
│  │  PostToolUse: Edit ─────> post-edit-verify.sh            │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                      │
│  BUILD TOOLS                                                        │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  pom.xml: Spotless Maven Plugin (Google Java Format AOSP) │       │
│  │  Maven Surefire: Unit 테스트                              │       │
│  │  Maven Compiler: Java 21 컴파일                           │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 구성 요소 상세 분석

### Feedforward Control (가이드)

이 파일들은 매 세션 시작 시 AI Agent의 컨텍스트에 로드돼요.
Agent가 코드를 작성하기 **전에** 동작을 안내하여, 사전에 오류를 줄여줘요.

#### CLAUDE.md — Harness 규칙

**위치:** 프로젝트 루트

**로드 시점:** Claude Code 세션 시작 시 자동 로드

**포함 내용:**
- Rule ID가 지정된 7가지 필수 규칙 (BUILD-01부터 CONV-02까지)
- **자기 수정 프로토콜** — Commit이 차단되었을 때 Agent가 따라야 할 단계별 지침
- Agent가 수정하면 안 되는 보호 파일 목록
- 빌드 명령어 참조
- 코드 규칙 (Java 21, Quarkus, 로깅, 테스트)

**왜 중요한가요:** CLAUDE.md는 Harness에서 가장 레버리지가 높은 파일이에요. 모든
대화에 포함되고 Agent가 취하는 모든 행동에 영향을 줘요. Agent가 코드를 작성하기 전에
이 규칙을 읽기 때문에, 많은 위반 사항이 아예 발생하지 않도록 예방돼요.

#### AGENTS.md — 개발 가이드라인

**위치:** 프로젝트 루트

**추가 내용:** 하단의 "Harness Engineering" 섹션에서 다음을 설명해요:
- `Agent = Model + Harness` 개념
- Feedforward vs Feedback Control 유형
- 7단계의 자기 수정 루프
- 각 검사 ID와 해당 명령어를 매핑한 테이블

**왜 중요한가요:** AGENTS.md는 Agent가 규칙이 *왜* 존재하는지 이해할 수 있도록
더 깊은 컨텍스트를 제공해요. 단순히 규칙이 무엇인지만 아는 것이 아니라요.
이러한 이해는 Agent가 Edge Case에서 더 나은 결정을 내리는 데 도움이 돼요.

#### CHECKLIST.md — 검증 규칙

**위치:** 프로젝트 루트

**포함 내용:**
- ID, 설명, 통과 기준이 있는 7가지 규칙
- 올바른 패턴과 잘못된 패턴을 보여주는 코드 예제
- 위반 사항 처리 흐름도
- 보호 파일 목록

**왜 중요한가요:** "통과"가 무엇을 의미하는지에 대한 단일 소스 오브 트루스(Single Source of Truth)예요.
사람과 AI Agent 모두 품질 기준을 이해하기 위해 이 파일을 참조해요.

### Feedback Control (센서)

이것들은 Claude Code의 Hook 시스템에 의해 트리거되는 실행 가능한 스크립트예요.
개발 워크플로우의 특정 시점에 자동으로 실행돼요.

#### .claude/settings.json — Hook 연결

이 파일은 Claude Code의 라이프사이클 이벤트를 Hook 스크립트에 연결해요:

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

**Matcher 작동 방식:**
- `"Bash"` — 모든 Bash Tool 호출 시 실행 (스크립트가 `git commit`을 필터링)
- `"Edit|Write"` — 모든 파일 편집 또는 쓰기 작업 시 실행

**Exit Code 작동 방식:**
- `exit 0` — 작업을 계속 진행 허용
- `exit 2` — 작업을 차단하고 Agent에게 오류 메시지 표시

---

## Hook 시스템 내부 구조

### 1. Pre-Commit Harness

**파일:** `.claude/hooks/pre-commit-harness.sh`

**트리거:** Bash Tool의 PreToolUse (`git commit` 명령어만 필터링)

**단계별 작동 방식:**

```text
Step 1: stdin을 통해 Claude Code로부터 JSON 입력 읽기
        ┌─────────────────────────────────────────────────────┐
        │ {"tool_input":{"command":"git commit -m \"...\" "}} │
        └─────────────────────────────────────────────────────┘
                              │
Step 2: python3 JSON 파서를 사용하여 bash 명령어 추출
                              │
Step 3: Guard Clause — "git commit" 명령어인가?
        ├── 아니오 → 즉시 exit 0 (Commit이 아닌 명령어는 허용)
        └── 예    → 검사 계속 진행
                              │
Step 4: -m 플래그에서 Commit 메시지 추출
        처리 가능: -m "msg", -m 'msg', 그리고 heredoc 패턴
                              │
Step 5: 7개 검사 모두 실행, 모든 실패 사항 수집
        ├── BUILD-01: ./mvnw compile -q
        ├── BUILD-02: ./mvnw test -q
        ├── BUILD-03: ./mvnw spotless:check -q
        ├── QUAL-01:  grep으로 System.out.print 검색
        ├── QUAL-02:  grep으로 하드코딩된 시크릿 검색
        ├── CONV-01:  Commit 메시지에 정규식 매칭
        └── CONV-02:  @Path 클래스 vs *Test.java 파일 비교
                              │
Step 6: 결과 보고
        ├── 모두 통과 → exit 0 (Commit 진행)
        └── 하나라도 실패 → exit 2 (Commit 차단 + 오류 보고서)
```

**핵심 설계 결정 — 모든 실패 수집:** 이 스크립트는 첫 번째 실패에서 멈추지 않아요.
모든 검사를 실행하고 모든 실패를 한 번에 보고해요. 이렇게 하면 Agent가 반복적인
Commit 시도를 통해 실패를 하나씩 발견하는 대신, 한 번에 모든 것을 수정할 수 있어요.

**핵심 설계 결정 — LLM 최적화된 오류 메시지:** 각 실패에는 다음이 포함돼요:
- Rule ID (예: `[FAIL] QUAL-01`)
- 무엇이 잘못되었는지 (예: `System.out.println found in: TimeResource.java`)
- 정확한 수정 방법 (예: `Replace with org.jboss.logging.Logger`)
- 구체적인 코드 예제

### 2. 파일 보호

**파일:** `.claude/hooks/protect-files.sh`

**트리거:** Edit/Write Tool의 PreToolUse

**작동 방식:**

```text
Step 1: JSON 입력 읽기, tool_input에서 file_path 추출
Step 2: 프로젝트 내 상대 경로로 정규화
Step 3: 보호 파일 목록과 대조:
        - CLAUDE.md
        - CHECKLIST.md
        - .claude/settings.json
        - .claude/hooks/* (hooks 디렉토리의 모든 파일)
Step 4: 일치 → exit 2 (설명과 함께 편집 차단)
        불일치 → exit 0 (편집 허용)
```

**왜 중요한가요:** 파일 보호가 없으면, AI Agent가 Harness 규칙 자체를 수정해서
실패하는 검사를 "해결"할 수 있어요 — Commit을 차단하는 규칙을 제거하는 식으로요.
보호 Hook이 이를 방지하여 Harness가 온전히 유지되도록 해요.

### 3. 편집 후 검증

**파일:** `.claude/hooks/post-edit-verify.sh`

**트리거:** Edit/Write Tool의 PostToolUse

**작동 방식:**

```text
Step 1: JSON 입력 읽기, file_path 추출
Step 2: 편집된 파일이 .java 파일인지 확인
        ├── Java가 아님 → exit 0 (건너뛰기)
        └── Java 파일  → 계속 진행
Step 3: ./mvnw compile -q 실행 (30초 타임아웃)
Step 4: 컴파일 실패 시 → stderr에 경고 출력
        (권고 사항만 — 편집을 차단하지 않음)
Step 5: 항상 exit 0
```

**왜 중요한가요:** **조기 피드백**을 제공해요. Agent가 여러 편집을 한 후 Commit
시점에서야 컴파일 오류를 발견하는 대신, 각 Java 파일 편집 직후에 경고를 받아요.
이를 통해 Agent가 점진적으로 문제를 발견하고 수정할 수 있어요.

---

## 7가지 자동 검사 항목

### 빌드 규칙

| ID | 검사 | 명령어 | 감지 대상 |
|----|------|--------|-----------|
| BUILD-01 | 컴파일 | `./mvnw compile -q` | 구문 오류, 누락된 import, 타입 불일치, 미해결 참조 |
| BUILD-02 | 테스트 | `./mvnw test` | 테스트 실패, 어설션 오류, 런타임 예외, 회귀 버그 |
| BUILD-03 | 포맷팅 | `./mvnw spotless:check -q` | 일관성 없는 들여쓰기, import 순서, 코드 스타일 위반 |

### 코드 품질 규칙

| ID | 검사 | 감지 방법 | 감지 대상 |
|----|------|-----------|-----------|
| QUAL-01 | System.out 금지 | `grep -rl "System\.out\.print" src/main/java/` | Logger를 사용해야 하는 디버그 출력문 |
| QUAL-02 | 시크릿 금지 | `grep -rEl` (password/key 패턴) | 소스 코드에 하드코딩된 패스워드, API Key, Token |

### 규약 규칙

| ID | 검사 | 감지 방법 | 감지 대상 |
|----|------|-----------|-----------|
| CONV-01 | Commit 형식 | 정규식: `^(feat\|fix\|docs\|refactor\|test\|chore)(\(.+\))?: .+` | "added stuff"이나 "fix" 같은 비표준 Commit 메시지 |
| CONV-02 | 테스트 커버리지 | `@Path` 클래스와 `*Test.java` 파일 비교 | 대응하는 테스트 파일이 없는 REST Endpoint |

---

## 자기 수정 루프

이것이 Harness의 핵심 혁신이에요 — 사람의 개입 없이 자율적인 개발을 가능하게 하는
폐쇄 피드백 루프예요.

```text
┌─────────────────────────────────────────────────────────────┐
│                    SELF-CORRECTION LOOP                      │
│                                                             │
│  ┌──────────────────────┐                                   │
│  │ 1. Agent가 CLAUDE.md │                                   │
│  │    규칙을 따라       │                                   │
│  │    코드 작성         │                                   │
│  └──────────┬───────────┘                                   │
│             │                                               │
│             v                                               │
│  ┌──────────────────────┐                                   │
│  │ 2. Agent가           │                                   │
│  │    git commit -m "..."│                                  │
│  │    실행               │                                  │
│  └──────────┬───────────┘                                   │
│             │                                               │
│             v                                               │
│  ┌──────────────────────┐                                   │
│  │ 3. PreToolUse Hook   │                                   │
│  │    이 실행되고        │                                   │
│  │    pre-commit-harness│                                   │
│  │    가 7개 검사 실행   │                                   │
│  └──────────┬───────────┘                                   │
│             │                                               │
│        모두 통과?                                            │
│        /        \                                           │
│      예          아니오                                      │
│       │           │                                         │
│       v           v                                         │
│  ┌─────────┐ ┌──────────────────────┐                      │
│  │ exit 0  │ │ exit 2               │                      │
│  │ Commit  │ │ Commit 차단됨         │                      │
│  │ 진행    │ │                      │                      │
│  │         │ │ Rule ID와 수정 지침이  │                      │
│  └─────────┘ │ 포함된 상세 오류      │                      │
│              │ 보고서               │                      │
│              └──────────┬───────────┘                      │
│                         │                                   │
│                         v                                   │
│              ┌──────────────────────┐                      │
│              │ 4. Agent가 오류를    │                      │
│              │    읽고 모든 위반     │                      │
│              │    사항 수정         │                      │
│              └──────────┬───────────┘                      │
│                         │                                   │
│                         └──────── Step 2로 돌아감 ──────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**일반적인 흐름:**
- **최상의 경우:** Agent가 CLAUDE.md 규칙을 따르고, 깔끔한 코드를 작성하여, 7개
  검사가 첫 번째 시도에서 모두 통과해요. Commit이 즉시 완료돼요.
- **일반적인 경우:** 1~2개 검사가 실패 (예: 포맷팅 + 테스트 누락). Agent가
  두 문제를 모두 수정하고 두 번째 시도에서 성공적으로 Commit해요.
- **최악의 경우:** 여러 문제가 있어요. Agent가 2~3회 반복이 필요할 수 있지만,
  Harness는 항상 필요한 구체적인 수정 방법을 제공해요.

---

## 사용 예제

### 예제 1: 새로운 REST Endpoint 추가 (정상 경로)

이 예제는 Harness가 첫 번째 시도에서 깔끔한 Commit을 허용하는 경우를 보여줘요.

**AI Agent에 대한 사용자 프롬프트:**

```
/time 엔드포인트를 추가해서 현재 서버 시간을 ISO 8601 형식으로 반환하세요.
```

**Agent의 동작 (CLAUDE.md의 안내를 따름):**

1. `src/main/java/dev/tedwon/TimeResource.java` 생성:

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

2. `src/test/java/dev/tedwon/TimeResourceTest.java` 생성:

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

3. `./mvnw spotless:apply`를 실행하여 코드 포맷팅

4. 스테이징 및 Commit:

```bash
git add src/main/java/dev/tedwon/TimeResource.java
git add src/test/java/dev/tedwon/TimeResourceTest.java
git commit -m "feat(time): add server time endpoint with ISO 8601 format"
```

**Harness 출력 (모든 검사 통과):**

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

Commit이 진행돼요. 사람의 개입이 필요 없어요.

---

### 예제 2: Harness가 위반 사항을 감지하고 수정

이 예제는 자기 수정 루프가 실제로 작동하는 모습을 보여줘요 — Harness가 잘못된
Commit을 차단하고 Agent가 자동으로 문제를 수정해요.

**사용자 프롬프트:**

```
/greeting 엔드포인트를 추가해서 name 파라미터를 받아 인사말을 반환하세요.
```

**Agent의 첫 번째 시도 (위반 사항 포함):**

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
        System.out.println("Greeting request for: " + name);  // 위반: QUAL-01
        return "Hello, " + (name != null ? name : "World") + "!";
    }
}
```

Agent가 테스트 파일 생성을 잊고, System.out을 사용하며, 잘못된 Commit 메시지를 작성해요:

```bash
git commit -m "added greeting endpoint"
```

**Harness 출력 (3개 검사 실패):**

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

**Agent의 자기 수정 (오류 메시지의 안내를 따름):**

1. `System.out.println`을 Logger로 교체:

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

2. `src/test/java/dev/tedwon/GreetingEndpointTest.java` 생성:

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

3. 올바른 Commit 메시지로 재시도:

```bash
git add -A
git commit -m "feat(greeting): add personalized greeting endpoint"
```

**Harness 출력 (두 번째 시도에서 모든 검사 통과):**

```
========================================
HARNESS: ALL 7/7 CHECKS PASSED
Commit allowed.
========================================
```

Commit이 진행돼요. Agent가 사람의 개입 없이 3가지 위반 사항을 모두 자기 수정했어요.

---

### 예제 3: 보호 파일 Guardrail

이 예제는 Harness가 Agent 자신의 규칙을 수정하는 것을 방지하는 모습을 보여줘요.

**시나리오:** Agent가 QUAL-01 실패를 만나고, 실제 코드를 수정하는 대신
CLAUDE.md에서 규칙을 제거하는 것을 고려해요.

**Agent가 CLAUDE.md 편집을 시도:**

```
CLAUDE.md를 편집해서 System.out에 관한 QUAL-01 규칙을 제거
```

**Harness 출력 (편집 차단):**

```
HARNESS: EDIT BLOCKED
File 'CLAUDE.md' is protected by the harness.
These files define the harness rules and cannot be modified by the AI agent.
If you need to change this file, ask the human operator for approval.
```

편집이 거부돼요. Agent는 실제 코드의 위반 사항을 수정해야 해요.

**동일한 보호가 다음 파일에도 적용돼요:**
- `CHECKLIST.md` — Agent가 체크리스트에서 검사를 제거할 수 없어요
- `.claude/settings.json` — Agent가 Hook을 비활성화할 수 없어요
- `.claude/hooks/*` — Agent가 Hook 스크립트를 수정할 수 없어요

---

## 커스터마이징 가이드

### 새로운 검사 추가

8번째 검증 검사를 추가하려면:

1. **CHECKLIST.md에 새 ID로 규칙 정의** (예: `[QUAL-03]`)

2. **`.claude/hooks/pre-commit-harness.sh`에 검사 추가:**

```bash
# =============================================================================
# CHECK 8: QUAL-03 — 새로운 검사
# =============================================================================
echo "HARNESS: Running QUAL-03 (your check)..." >&2
if your_check_command_here; then
    pass
else
    fail "QUAL-03" "실패 내용 설명.
  -> 수정 방법.
  -> 올바른 코드 예제."
fi
```

3. **TOTAL_CHECKS를 7에서 8로 업데이트:**

```bash
TOTAL_CHECKS=8
```

4. **CLAUDE.md에 규칙 추가** — Agent가 사전에 알 수 있도록

### 새로운 보호 파일 추가

`.claude/hooks/protect-files.sh`를 편집하고 `PROTECTED_FILES` 배열에 파일명을 추가하세요:

```bash
PROTECTED_FILES=(
    "CLAUDE.md"
    "CHECKLIST.md"
    ".claude/settings.json"
    "your-new-protected-file.md"    # 추가됨
)
```

### 검사 엄격도 조정

각 검사의 엄격도를 높이거나 낮출 수 있어요:

- **BUILD-02 (테스트):** `./mvnw test -q`를 `./mvnw verify -q`로 변경하여
  Integration 테스트도 포함
- **QUAL-02 (시크릿):** `SECRET_PATTERNS` 정규식을 수정하여 더 많은 패턴 감지
- **CONV-02 (테스트 커버리지):** `@Path` 외에 `@RequestMapping` 등 다른
  어노테이션도 검사하도록 확장

---

## 문제 해결

### Hook이 실행되지 않음

**증상:** Harness 검사 없이 Commit이 통과돼요.

**확인 사항:**
1. `.claude/settings.json`에 `hooks` 섹션이 있는지 확인
2. Hook 스크립트에 실행 권한이 있는지 확인: `ls -la .claude/hooks/*.sh`
3. `python3`이 사용 가능한지 확인: `which python3`

### Hook 타임아웃

**증상:** 첫 번째 실행이 너무 오래 걸려요.

**해결:** `./mvnw compile`을 수동으로 한 번 실행하여 Maven 의존성 캐시를 채우세요.
이후 실행은 빨라요 (~10-15초로 7개 검사 모두 완료).

### QUAL-02 오탐지

**증상:** QUAL-02가 테스트 데이터나 설정 예제를 하드코딩된 시크릿으로 감지해요.

**해결:** 이 검사는 `src/main/java/`와 `src/main/resources/`를 스캔해요.
`src/test/`의 테스트 데이터는 스캔하지 않아요. 특정 패턴을 제외해야 한다면,
`pre-commit-harness.sh`의 `SECRET_PATTERNS` 정규식을 수정하세요.

### CONV-01이 Heredoc Commit 메시지에서 실패

**증상:** 복잡한 heredoc 패턴에서 Commit 메시지 추출이 실패해요.

**해결:** Commit 메시지에 간단한 `-m "message"` 형식을 사용하세요. heredoc
파서는 기본적인 경우만 처리하며 모든 변형을 다루지 않을 수 있어요.

---

## Agentic Development Playbook과의 연결

Harness Engineering 레이어는 기존의
[Agentic Development Playbook](../agentic-development-playbook_v0.2.md)을
**실행 단계** (Phase 2)를 자동화하여 강화해요:

| Playbook 단계 | Harness 없이 | Harness 포함 |
|---------------|-------------|-------------|
| Phase 1: 설계 | 사람 주도의 브레인스토밍 | 동일 (변경 없음) |
| Phase 2: 실행 | 사람이 각 단계를 검토 | Agent가 Harness 루프를 통해 자기 수정 |
| Phase 3: 리뷰 | 사람 + CI 리뷰 | 동일, 단 리뷰에 도달하는 이슈 감소 |
| Phase 4: 검증 | 수동 테스트 | 동일, 단 빌드/테스트 이슈가 더 일찍 감지됨 |

Harness는 설계 결정, 아키텍처, 보안이 중요한 코드에 대한 사람의 판단을
대체하지 않아요. 매 Commit마다 사람의 개입이 필요했을 기계적인 품질 검사를
자동화해요.

---

## 참고 자료

- [OpenAI — Harness Engineering](https://openai.com/index/harness-engineering/)
- [OpenAI — Unlocking the Codex Harness](https://openai.com/index/unlocking-the-codex-harness/)
- [Anthropic — Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Anthropic — Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Awesome Harness Engineering](https://github.com/ai-boost/awesome-harness-engineering)
- [Claude Code Hooks Documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
