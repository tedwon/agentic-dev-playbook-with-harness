# Issue #2: 명언 AI 챗봇 기능 — Claude Code 따라하기 가이드

> 이슈: [#2 명언 AI 챗봇 기능 추가](https://github.com/tedwon/agentic-dev-playbook-with-harness/issues/2)
>
> 이 가이드는 [Agentic Development Playbook](../agentic-development-playbook.md)의 Phase 1~4를
> Issue #2에 맞춰 구체적으로 풀어 쓴 것입니다. 각 단계의 프롬프트를 그대로 복사-붙여넣기하면 됩니다.

---

## 사전 준비 (데모 전에 반드시 확인)

### Ollama 설치 및 모델 다운로드

이 기능은 로컬 LLM(qwen3:1.7b)을 사용합니다. Ollama가 설치되어 있고 모델이 준비되어 있어야 합니다.

```bash
# Ollama 설치 (macOS)
brew install ollama

# 모델 다운로드 (최초 1회, 약 1.1GB)
ollama pull qwen3:1.7b

# Ollama 서비스 시작 (별도 터미널에서 실행 — Phase 4 로컬 검증까지 유지)
ollama serve
```

> **Ollama가 실행 중이 아니면** Phase 4 로컬 검증에서 챗봇 API가 connection refused로 실패합니다.

### asciinema 설치 (터미널 녹화)

각 Phase별 Claude Code 세션을 터미널 녹화로 남기면 나중에 리뷰·데모·회고에 유용합니다.
녹화 파일은 텍스트 기반이라 가볍고, 재생 속도 조절과 텍스트 검색이 가능합니다.

```bash
# 설치 (macOS)
brew install asciinema

# 인증 (선택 — asciinema.org에 업로드할 때 필요)
asciinema auth
```

### Claude Code 플러그인 확인

```text
# Claude Code 세션에서 context7 플러그인이 활성화되어 있는지 확인
# 미설치 시: /plugin context7 → /reload-plugins
```

플레이북 규칙: *"Required plugin not installed at execution start →
Verify all plugins at the start of the session, not at AC-check time."*

### 현재 프로젝트 상태 파악

현재 코드에는 LangChain4j/Ollama 관련 의존성이 **없습니다** — 에이전트가 추가해야 합니다.

| 항목 | 현재 상태 |
|------|-----------|
| `pom.xml` | quarkus-rest, quarkus-rest-jackson, quarkus-arc, quarkus-smallrye-health만 있음 |
| LangChain4j | **미포함** → 브레인스토밍/플랜에서 추가 필요 |
| 명언 데이터 | `QuoteService.java`에 인메모리 `ArrayList<Quote>` 8개 (DB 아님) |
| `application.properties` | `app.quote.default-category=inspiration` 1줄만 있음 |

---

## 전체 흐름 요약

```text
🔴 녹화 시작: issue-2-design.cast
Phase 1 (Design) — 세션 1
  ① 피처 브랜치 수동 생성
  ② /brainstorming → 스펙 생성
  ③ 스펙 리뷰어 디스패치
  ④ /writing-plans → 플랜 생성
  ⑤ 플랜 리뷰어 디스패치
  ⑥ 설계 산출물 커밋 & push
  ⑦ git switch main (브랜치 해제)
⏹ 녹화 종료
                    ↓
🔴 녹화 시작: issue-2-execution.cast
Phase 2 (Execution) — 세션 2 (새 세션 필수)
  ① /using-git-worktrees → worktree 자동 생성
  ② /executing-plans → 플랜 실행
  ③ 전체 테스트 통과 확인
                    ↓
Phase 3 (Code Review) — 세션 2 계속 또는 세션 3
  ① PR 생성
  ② CI 리뷰 피드백 확인
  ③ /requesting-code-review → 독립 리뷰
⏹ 녹화 종료
                    ↓
🔴 녹화 시작: issue-2-validation.cast
Phase 4 (Validation)
  ① 보안 스캔
  ② 로컬 검증
  ③ 클로징 체크리스트
  ④ worktree 정리
⏹ 녹화 종료
```

**왜 Phase 1과 2를 별도 세션으로?**
설계 대화가 컨텍스트 윈도우를 소모합니다. 생성된 플랜 문서가 유일한 핸드오프 수단이므로,
플랜은 반드시 자기완결적(self-contained)이어야 합니다.

**왜 Phase 1 끝에서 `git switch main`?**
git은 같은 브랜치를 두 worktree에서 동시에 체크아웃할 수 없습니다.
Phase 2에서 worktree가 피처 브랜치를 체크아웃하려면, 메인 체크아웃이 해당 브랜치에서 벗어나 있어야 합니다.

---

## Phase 1: Design (세션 1)

### 녹화 시작

Claude Code를 열기 **전에** 터미널 녹화를 시작합니다:

```bash
asciinema rec docs/sessions/$(date +%Y-%m-%d)-issue-2-design.cast \
  --title "Issue #2 Phase 1 Design" \
  --idle-time-limit 30
```

> `--idle-time-limit 30` — 입력 없이 30초 이상 지나면 자동으로 건너뜁니다.
> 긴 대기 시간이 재생에 포함되지 않아 빠르게 리뷰할 수 있습니다.

이 녹화 안에서 아래의 모든 Phase 1 단계를 진행합니다.

### ① 피처 브랜치 생성

터미널에서 직접 실행합니다 (Claude Code가 아닌 수동):

```bash
git checkout -b feat/issue-2-quote-ai-chatbot
```

### ② 브레인스토밍

Claude Code를 열고 아래 프롬프트를 **그대로** 입력합니다:

```text
/brainstorming

명언 AI 챗봇 기능을 추가하려고 합니다.

## 이슈
https://github.com/tedwon/agentic-dev-playbook-with-harness/issues/2

## 기능 설명
사용자가 명언에 대해 자유롭게 질문하면 AI가 대화로 답변하는 챗봇 REST API를 추가합니다.

## 요구사항
- 자연어 질문 → AI 답변 (명언 해설, 상황별 적용, 명언 추천)
- 기존 명언 데이터(인메모리)를 컨텍스트로 활용
- 로컬 LLM 모델 기반 (외부 API/웹 검색 불필요)

## 기술 스택
- Quarkus 3.34.3, Java 21
- Quarkus LangChain4j (Ollama 연동) — 현재 pom.xml에 미포함, 추가 필요
- 로컬 LLM: qwen3:1.7b (알리바바 오픈소스 모델, 17억 파라미터)
- context7 플러그인으로 Quarkus LangChain4j + Ollama 최신 문서 참조할 것

## 기존 코드 구조 (실제)
- Quote record: `Quote(long id, String text, String author, String category)` — src/main/java/dev/tedwon/Quote.java
- QuoteService: 인메모리 ArrayList에 8개 명언 저장 (DB 아님) — src/main/java/dev/tedwon/QuoteService.java
- QuoteResource: GET /api/quotes, /api/quotes/random, /api/quotes/{id} — src/main/java/dev/tedwon/QuoteResource.java
- application.properties: `app.quote.default-category=inspiration` (1줄)

## 기존 명언 데이터 (실제 — QuoteService.java에서 발췌)
| id | text | author | category |
|----|------|--------|----------|
| 1 | Talk is cheap. Show me the code. | Linus Torvalds | programming |
| 2 | Programs must be written for people to read. | Harold Abelson | programming |
| 3 | Any fool can write code that a computer can understand. | Martin Fowler | programming |
| 4 | First, solve the problem. Then, write the code. | John Johnson | programming |
| 5 | The best way to predict the future is to invent it. | Alan Kay | inspiration |
| 6 | Simplicity is the soul of efficiency. | Austin Freeman | inspiration |
| 7 | The only way to do great work is to love what you do. | Steve Jobs | inspiration |
| 8 | In the middle of difficulty lies opportunity. | Albert Einstein | inspiration |

## 참고
- 플레이북: agentic-development-playbook.md
- 프로젝트 가이드: AGENTS.md
```

브레인스토밍 중 에이전트가 Q&A를 진행합니다. **이때 해야 할 것:**

- 필드 이름, 네이밍 컨벤션을 **일찍 합의**하세요
- 실제 데이터(API 응답 예시, DB 레코드)가 있으면 **보여주세요**
- 도메인 지식(기존 명언 DB 구조, LLM 모델 종류 등)을 **명시적으로 알려주세요**

### ③ 스펙 저장 & 리뷰

브레인스토밍이 끝나면 Claude Code에 아래를 입력합니다:

```text
Save the spec to docs/superpowers/specs/2026-04-29-issue-2-quote-ai-chatbot.md
```

그 다음 리뷰어를 디스패치합니다:

```text
Dispatch a reviewer subagent to audit this spec for completeness and correctness.
```

리뷰어가 찾은 문제점을 **모두 해결**한 뒤 다음으로 넘어갑니다.

### ④ 플랜 작성

```text
/writing-plans
```

에이전트가 스펙을 기반으로 구현 플랜을 생성합니다. 플랜에는 각 태스크마다
목표, 수정할 파일, 코드 스니펫, 검증 단계가 포함됩니다.

### ⑤ 플랜 리뷰

```text
Dispatch a reviewer subagent to audit this plan for gaps, missing dependencies,
and tasks that could cause regressions in adjacent systems.
```

리뷰어 피드백을 반영합니다.

### ⑥ 설계 산출물 커밋 & push

터미널에서 직접 커밋합니다 (수동):

```bash
git add docs/superpowers/ docs/ADR/
git commit -m "docs(design): add spec and plan for issue-2 quote AI chatbot"
git push -u origin feat/issue-2-quote-ai-chatbot
```

> **참고:** 상위 CLAUDE.md에 "Claude Code should NEVER create git commits automatically" 정책이
> 있으므로, 설계 산출물 커밋은 수동으로 합니다. Phase 2 실행 중 커밋은 에이전트가 직접
> 수행합니다 (harness self-correction loop의 일부).

커밋되는 파일 예시:
- `docs/superpowers/specs/2026-04-29-issue-2-quote-ai-chatbot.md`
- `docs/superpowers/plans/2026-04-29-issue-2-quote-ai-chatbot-plan.md`
- `docs/ADR/ADR-xxx-*.md` (설계 중 생긴 결정사항이 있다면)

### ⑦ main으로 복귀

터미널에서 직접 실행합니다:

```bash
git switch main    # 피처 브랜치 → main 브랜치로 전환
git pull --ff-only # 원격 최신 변경사항을 가져옴 (fast-forward만 허용)
```

- **`git switch main`** — `git checkout main`과 같은 역할이지만, 브랜치 전환 전용으로 만들어진 더 새로운 명령입니다.
- **`git pull --ff-only`** — fast-forward만 허용합니다. 로컬에 커밋이 없고 원격만 앞서 있으면 정상 업데이트되고, 로컬과 원격이 갈라져서 merge가 필요하면 실패합니다 (의도치 않은 merge 커밋 방지).

### 녹화 종료

Claude Code 세션을 닫은 뒤 녹화를 종료합니다:

```bash
# Ctrl+D 또는 exit 입력으로 녹화 종료
exit
```

> **Phase 1 완료.** 이 세션을 닫습니다.

---

## Phase 2: Execution (세션 2 — 새 세션 필수)

### 녹화 시작

새 터미널을 열고 녹화를 먼저 시작합니다:

```bash
asciinema rec docs/sessions/$(date +%Y-%m-%d)-issue-2-execution.cast \
  --title "Issue #2 Phase 2 Execution" \
  --idle-time-limit 30
```

이 녹화 안에서 Claude Code를 열고 Phase 2~3 단계를 진행합니다.

### ① Worktree 생성

**새 Claude Code 세션**을 열고 입력합니다:

```text
/using-git-worktrees
```

에이전트가 피처 브랜치(`feat/issue-2-quote-ai-chatbot`)를 격리된 worktree 디렉토리에
자동 체크아웃합니다. 이후 모든 작업은 이 worktree 안에서 이루어집니다.

**worktree를 사용하는 이유:**
- 메인 체크아웃이 깨지지 않음 (에이전트가 빌드를 망가뜨려도 안전)
- 메인에서 다른 작업을 병행할 수 있음
- 실패 시 `git worktree remove <path>` 한 줄로 정리

### ② 플랜 실행

```text
/executing-plans docs/superpowers/plans/<Phase 1에서 생성된 플랜 파일명>.md
```

예시: `/executing-plans docs/superpowers/plans/2026-04-29-issue-2-quote-ai-chatbot-plan.md`

> **팁:** Phase 1 ④에서 에이전트가 생성한 실제 파일명을 사용하세요.
> 파일명이 기억나지 않으면 `ls docs/superpowers/plans/` 로 확인합니다.

에이전트가 플랜의 각 태스크를 순서대로 실행합니다.

**실행 중 자동으로 일어나는 일:**
- 각 태스크 완료 후 `./mvnw test` 실행 (harness 자동 검증)
- 커밋 시 pre-commit hook이 7가지 체크를 실행 (BUILD-01~CONV-02)
- 체크 실패 시 에이전트가 자동 수정 후 재시도 (self-correction loop)

**실행 중 사람이 해야 할 것:**
- 에이전트의 설계 결정이 맞는지 확인
- 비즈니스 로직이 도메인 요구사항과 일치하는지 검증
- 테스트가 통과해도 로직이 틀릴 수 있으니 직접 확인

### ③ 전체 테스트 확인

모든 태스크 완료 후:

```bash
./mvnw verify
```

---

## Phase 3: Code Review

### ① 브랜치 push & PR 생성

먼저 worktree의 변경사항이 원격에 push 되어 있어야 합니다.
Claude Code에 입력합니다:

```text
Push this branch to origin, then create a PR linking to issue #2.
```

에이전트가 `git push` 후 `gh pr create`로 PR을 생성하고 설명을 작성합니다.

### ② CI 리뷰 피드백 확인

CI가 완료되면:

```bash
gh pr view <pr-number> --comments > /tmp/pr_comments.txt
```

Claude Code에 입력합니다:

```text
Read /tmp/pr_comments.txt. These are the AI code review comments from the CI pipeline.
For each finding: identify if it is blocking, advisory, or a false positive.
For blocking and advisory findings, propose a fix. For false positives, explain why.
```

피드백 처리를 위한 스킬:

```text
/receiving-code-review
```

### ③ 독립 코드 리뷰

```text
/requesting-code-review
```

code-reviewer 서브에이전트가 보안, 정확성, 프로젝트 컨벤션을 검토합니다.

---

### 녹화 종료 (Phase 2~3)

Phase 3까지 마쳤으면 녹화를 종료합니다:

```bash
exit
```

---

## Phase 4: Validation

### 녹화 시작

Phase 4는 별도 터미널에서 수동으로 진행하므로 새 녹화를 시작합니다:

```bash
asciinema rec docs/sessions/$(date +%Y-%m-%d)-issue-2-validation.cast \
  --title "Issue #2 Phase 4 Validation" \
  --idle-time-limit 30
```

### ① 보안 스캔

```bash
# 정적 분석 (버그 패턴 검출)
./mvnw spotbugs:check

# 의존성 취약점 스캔 (CVSS >= 7 실패)
./mvnw dependency-check:check

# SBOM 생성
./mvnw cyclonedx:makeAggregateBom
```

### ② 로컬 검증

> **Ollama가 실행 중인지 확인하세요.** 별도 터미널에서 `ollama serve`가 돌아가고 있어야 합니다.
> 실행 중이 아니면 챗봇 API가 connection refused로 실패합니다.

```bash
# Ollama 실행 확인
curl -s http://localhost:11434/api/tags | head -5

# Quarkus dev 모드로 시작
./mvnw quarkus:dev

# 별도 터미널에서 헬스체크
curl -s http://localhost:8080/q/health
```

챗봇 API 테스트 (엔드포인트와 요청 형태는 플랜/스펙에 따라 달라질 수 있습니다):

```bash
# 아래는 예시입니다 — 실제 구현된 API 스펙(OpenAPI: http://localhost:8080/q/swagger-ui)을 확인 후 테스트하세요
curl -s -X POST http://localhost:8080/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Stay hungry, stay foolish 이 명언 설명해줘"}'
```

### ③ 클로징 체크리스트

- [ ] Ollama가 실행 중이고 qwen3:1.7b 모델이 로드됨
- [ ] `./mvnw quarkus:dev` 로 에러 없이 시작됨
- [ ] `./mvnw verify` 전체 테스트 통과
- [ ] 보안 스캔 통과 (`spotbugs:check`, `dependency-check:check`)
- [ ] SBOM 생성됨 (`target/bom.json`)
- [ ] 챗봇 API가 실제 요청에 올바르게 응답함
- [ ] 로그에 silent failure 없음
- [ ] 리뷰어가 에이전트의 구현 선택을 설명할 수 있음 (skill atrophy check)
- [ ] 실행 요약 저장 (결정사항 및 수정 내역)
- [ ] 이슈 #2 업데이트 및 PR 링크 완료

### ④ Worktree 정리

PR 머지 후:

```bash
git worktree remove <worktree-path>
```

### 녹화 종료 & 정리

```bash
# 녹화 종료
exit

# 녹화 파일 확인
ls -lh docs/sessions/*.cast
```

녹화 파일을 공유하려면 asciinema.org에 업로드합니다:

```bash
asciinema upload docs/sessions/<파일명>.cast
```

> **팁:** `.cast` 파일이 커서 `.gitignore`에 추가하고 asciinema.org 링크만 문서에 남길 수도 있습니다.

---

## 데모 녹화 재생

Phase 1~4 완료 후, 핵심 장면을 보여주는 데모 녹화 4개가 `demo/issue-2-chatbot/recordings/`에 생성됩니다.
발표 중 터미널에서 아래 명령으로 재생할 수 있습니다.

### Self-Correction 데모

하네스가 위반 코드를 잡고 → 에이전트가 수정 → 7/7 체크 통과하는 과정을 보여줍니다.

```bash
asciinema play -s 2 demo/issue-2-chatbot/recordings/04-chatbot-self-correction.cast
```

### Build & Test 데모

13개 테스트 전체 통과 + 하네스 7/7 체크 통과를 보여줍니다.

```bash
asciinema play -s 2 demo/issue-2-chatbot/recordings/05-chatbot-build-test.cast
```

### Live API 데모

Ollama(qwen3:1.7b) 연동 실시간 AI 챗봇 응답을 보여줍니다.

> **주의:** 이 녹화는 녹화 시점의 LLM 응답이 기록되어 있으므로 Ollama 실행 없이 재생 가능합니다.

```bash
asciinema play -s 2 demo/issue-2-chatbot/recordings/06-chatbot-live-api.cast
```

### Security 데모

SpotBugs 정적 분석 + CycloneDX SBOM 생성을 보여줍니다.

```bash
asciinema play -s 2 demo/issue-2-chatbot/recordings/07-chatbot-security.cast
```

> **재생 속도 조절:** `-s 2`는 2배속입니다. 원래 속도로 보려면 `-s 2`를 빼고 실행하세요.
> 재생 중 `Space`로 일시정지, `.`으로 한 프레임 전진, `Ctrl+C`로 종료할 수 있습니다.

> **완료!** 이슈 [#2](https://github.com/tedwon/agentic-dev-playbook-with-harness/issues/2)를 닫습니다.
