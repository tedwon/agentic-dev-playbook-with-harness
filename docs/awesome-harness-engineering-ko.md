# Awesome Harness Engineering 한글 가이드

> **원본:** [ai-boost/awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering)
>
> AI Agent Harness 구축을 위한 리소스, 패턴, 템플릿 모음을 한국어로 정리한 문서입니다.

---

## Harness Engineering이란?

**Harness Engineering**은 AI Agent를 둘러싼 **스캐폴딩(scaffolding)을 설계하는 분야**예요.

여기서 말하는 스캐폴딩이란:

- **Context 전달** — Agent에게 어떤 정보를 줄 것인가
- **Tool 인터페이스** — Agent가 사용할 도구를 어떻게 설계할 것인가
- **Planning 산출물** — 계획 수립과 작업 분해를 어떻게 구조화할 것인가
- **검증 루프(Verification Loop)** — 결과를 어떻게 자동 검증할 것인가
- **메모리 시스템** — 상태와 기억을 어떻게 관리할 것인가
- **Sandbox** — 실행 환경을 어떻게 격리할 것인가

핵심 공식: **Agent = Model + Harness**

이 목록은 **Model이 아닌 Harness**에 초점을 맞추고 있어요. 여기 있는 모든 컴포넌트는 Model 혼자서는 할 수 없기 때문에 존재하며, 최고의 Harness는 Model이 발전하면서 이 컴포넌트들이 불필요해질 것을 알고 설계되어 있어요.

---

## 목차

1. [Foundations (기초 문헌)](#1-foundations-기초-문헌)
2. [Design Primitives (설계 원칙)](#2-design-primitives-설계-원칙)
   - [Agent Loop](#21-agent-loop)
   - [Planning & Task Decomposition](#22-planning--task-decomposition)
   - [Context Delivery & Compaction](#23-context-delivery--compaction)
   - [Tool Design](#24-tool-design)
   - [Skills & MCP](#25-skills--mcp)
   - [Permissions & Authorization](#26-permissions--authorization)
   - [Memory & State](#27-memory--state)
   - [Task Runners & Orchestration](#28-task-runners--orchestration)
   - [Verification & CI Integration](#29-verification--ci-integration)
   - [Observability & Tracing](#210-observability--tracing)
   - [Debugging & Developer Experience](#211-debugging--developer-experience)
   - [Human-in-the-Loop](#212-human-in-the-loop)
3. [Reference Implementations (참조 구현)](#3-reference-implementations-참조-구현)
4. [핵심 인사이트 요약](#4-핵심-인사이트-요약)

---

## 1. Foundations (기초 문헌)

Harness Engineering을 하나의 분야로 정립한 핵심 에세이와 논문들이에요.

### OpenAI

| 문서 | 핵심 내용 |
|------|-----------|
| [Harness Engineering](https://openai.com/index/harness-engineering/) | Harness Engineering을 하나의 분야로 정의한 최초의 글. Codex 같은 Agent가 안정적으로 작동하도록 스캐폴딩을 설계하는 방법을 다뤄요. |
| [Unrolling the Codex Agent Loop](https://openai.com/index/unrolling-the-codex-agent-loop/) | Codex Agent Loop의 각 단계를 분해해서 설명해요. 관찰(Observe) → 계획(Plan) → 실행(Act) → 검증(Verify) 순서로 진행돼요. |
| [Run Long-Horizon Tasks with Codex](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex/) | 장기 작업 계획의 실전 가이드. Plan.md, Implement.md, Documentation.md를 재사용 가능한 Harness 산출물로 소개해요. |
| [A Practical Guide to Building AI Agents](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/) | 2026년 4월 발표. Single-Agent vs Multi-Agent Orchestration, Tool 설계, Guardrail 패턴을 실무 관점에서 정리해요. |

### Anthropic

| 문서 | 핵심 내용 |
|------|-----------|
| [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) | Agent 아키텍처의 기초. Workflow vs Agent를 언제 사용해야 하는지, 기본 요소를 어떻게 조합하는지 다뤄요. |
| [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) | 장기 멀티 세션 개발 작업을 위한 Harness 설계. 핵심 통찰: **모든 Harness 컴포넌트는 "Model이 이것을 못한다"는 가정 위에 존재하며, 그 가정은 만료된다.** |
| [Writing Effective Tools for Agents](https://www.anthropic.com/engineering/writing-effective-tools-for-agents) | Tool 인터페이스 설계 가이드. 이름 짓기, Schema, 에러 표현, 반환값 규칙 등. **Tool 설계는 곧 Agent UX**라는 원칙을 제시해요. |
| [Beyond Permission Prompts](https://www.anthropic.com/engineering/beyond-permission-prompts) | 자연어 기반 권한 텍스트에 의존하지 않고 구조화된 Permission 시스템을 Agent Harness에 내장하는 방법. |
| [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | Agent 평가 프레임워크. 무엇을 측정할지, Eval Harness를 어떻게 구축할지, 왜 단위 테스트 스타일의 평가가 Agent에게는 실패하는지 설명해요. |
| [What is an AI Agent?](https://www.anthropic.com/research/what-is-an-agent) | Agent의 정의. Harness 설계 결정을 내릴 때 "Agent란 무엇인가"에 대한 명확한 기준점이 되어요. |
| [2026 Agentic Coding Trends Report](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf?hsLang=en) | **Harness 설정만으로 벤치마크 점수가 5점 이상 변동**할 수 있다는 실증 데이터. Single-Agent에서 Multi-Agent 팀으로의 전환을 다뤄요. |

### Google / Microsoft / Martin Fowler

| 문서 | 핵심 내용 |
|------|-----------|
| [Google ADK](https://developers.googleblog.com/en/agent-development-kit-easy-to-build-multi-agent-applications/) | Google의 Multi-Agent 토폴로지, Tool 등록 모델, Eval 파이프라인 설계 근거를 설명해요. |
| [Martin Fowler: Harness Engineering](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html) | 세 가지 상호 연결 시스템으로 정리: **Context Engineering**(Agent가 아는 것 관리), **Architectural Constraints**(Linter/테스트 등 결정론적 검증), **Entropy Management**(문서 드리프트 자동 수정). "Humans on the loop" 개념을 가장 명확하게 정리해요. |
| [Azure SRE Agent](https://techcommunity.microsoft.com/blog/appsonazureblog/how-we-build-azure-sre-agent-with-agentic-workflows/4508753) | **35,000건 이상의 프로덕션 인시던트를 자율 처리**, 완화 시간을 40.5시간 → 3분으로 단축. 2026년 발표된 가장 데이터가 풍부한 프로덕션 Harness 사례예요. |
| [Context Engineering for Azure SRE Agent](https://techcommunity.microsoft.com/blog/appsonazureblog/context-engineering-lessons-from-building-azure-sre-agent/4481200/) | 100개 이상의 맞춤 Tool 대신 파일 시스템 기반 Context Engineering으로 전환. `read_file`, `grep`, `find`, `shell`만으로 "Intent Met" 점수가 **45% → 75%**로 상승. |
| [Red Hat: Harness Engineering](https://developers.redhat.com/articles/2026/04/07/harness-engineering-structured-workflows-ai-assisted-development) | Enterprise 관점의 Harness Engineering. 비정형 티켓 대신 구조화된 Context, MCP를 통한 도구 확장, 4단계 모델(vibes, specs, skills, agents)을 제안해요. |
| [LangChain: Anatomy of an Agent Harness](https://blog.langchain.com/the-anatomy-of-an-agent-harness/) | Harness를 구성하는 5가지 기본 요소: Filesystem, Code Execution, Sandbox, Memory, Context Management. |

---

## 2. Design Primitives (설계 원칙)

Harness 컴포넌트를 **해결하려는 문제 영역별**로 정리한 섹션이에요.

### 2.1 Agent Loop

Agent Loop은 Agent가 작동하는 핵심 루프 구조예요: **관찰 → 사고 → 행동 → 검증**을 반복해요.

**핵심 리소스:**

- [ReAct 논문](https://arxiv.org/abs/2210.03629) — Thought/Action/Observation 루프 구조를 정의한 기초 논문. 거의 모든 Agent Harness의 근간이에요.
- [LangGraph Low Level Concepts](https://langchain-ai.github.io/langgraph/concepts/low_level/) — Agent Loop을 방향 그래프로 모델링. 종료 조건, Tool 결과에 따른 분기, 중간 상태 저장 등을 명시적으로 구현해요.
- [Extended Thinking (Claude API)](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking) — `budget_tokens`로 턴당 추론 깊이를 제어하고, thinking block을 Tool 결과 전달 시 반드시 유지해야 한다는 중요한 제약사항이 있어요.
- [LangChain: Improving Deep Agents](https://blog.langchain.com/improving-deep-agents-with-harness-engineering/) — **Harness만 변경해서 Terminal Bench 2.0에서 30위 → Top 5 달성**. Model 교체 없이 검증 루프, Context 주입, 루프 감지 미들웨어, "reasoning sandwich"(계획/검증 단계에서 최대 사고 집중) 적용.

**핵심 교훈:** Harness 설계가 성능의 주요 레버이지, Model 능력이 아니에요.

### 2.2 Planning & Task Decomposition

계획 수립과 작업 분해를 별도의 Harness 레이어로 분리하는 패턴이에요.

**핵심 패턴:**

- **Plan-and-Execute 패턴:** Planner LLM이 단계 목록을 생성하고, Executor Agent가 이를 수행하며, 필요할 때만 재계획해요. ([LangChain](https://blog.langchain.com/plan-and-execute-agents/))
- **Milestone 기반 Planning:** Plan.md, Implement.md를 Harness 수준 상태로 활용 ([OpenAI](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex/))
- **Multi-Agent 토폴로지 선택:** Subagent, Skills, Handoff, Router 네 가지 패턴 중 선택. Subagent는 Multi-Domain 시나리오에서 Skills보다 **67% 적은 토큰** 처리 ([LangChain](https://blog.langchain.com/choosing-the-right-multi-agent-architecture/))
- **Cross-Session 상태 유지:** Feature 목록, Git 커밋, 테스트 게이트를 세션 간 상태로 활용하는 구조화된 핸드오프 메커니즘 ([Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents))

### 2.3 Context Delivery & Compaction

Agent에게 전달하는 Context를 어떻게 관리하고 압축할 것인가에 대한 영역이에요.

**핵심 기술:**

| 기법 | 설명 | 효과 |
|------|------|------|
| **Server-Side Compaction** | 오래된 Context를 자동 요약하여 Window 한계 내에서 운영 | 토큰 소비 **84% 감소** ([Claude API](https://platform.claude.com/docs/en/build-with-claude/compaction)) |
| **Prompt Compression** | [LLMLingua](https://github.com/microsoft/LLMLingua)로 최대 20배 압축, 성능 손실 최소화 | 지연시간에 민감한 Agent Loop에 적합 |
| **Prompt Caching** | 반복되는 System Prompt, Tool 정의를 캐시 | 멀티턴 세션의 비용을 크게 절감 ([Claude API](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)) |
| **자율 Context 압축** | Agent 스스로 압축 시점을 결정하는 Tool 호출 방식 | 서브태스크 중간에 압축이 끼어들어 추론이 깨지는 문제 해결 ([LangChain](https://blog.langchain.com/autonomous-context-compression/)) |
| **Content Negotiation** | Agent 요청 시 `text/markdown`으로 응답하여 HTML 보일러플레이트 제거 | Context Window에 들어가기 전에 불필요한 내용 제거 ([Vercel](https://vercel.com/blog/making-agent-friendly-pages-with-content-negotiation)) |

### 2.4 Tool Design

Agent가 사용하는 Tool의 이름, Schema, 에러 메시지, 반환값을 어떻게 설계할 것인가의 영역이에요.

**핵심 원칙:**

- **Tool 설계 = Agent UX** — 이름, Schema, 에러 표면, 반환값 관례가 Agent의 신뢰성을 결정해요 ([Anthropic](https://www.anthropic.com/engineering/writing-effective-tools-for-agents))
- **JSON Schema 기반 Tool 정의** — 여러 Model에서 작동하는 표준 인터페이스 ([OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling))
- **Tool Annotation으로 위험도 표시** — `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`를 MCP Tool에 부여. 단일 Tool의 안전성이 아닌 Tool **조합**에서 발생하는 위험을 고려해야 해요 ([MCP Blog](https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/))
- **구조화된 출력 보장** — [Outlines](https://github.com/dottxt-ai/outlines)(Regex/CFG/JSON Schema로 토큰 샘플링 제한), [Instructor](https://python.useinstructor.com/)(Pydantic 모델 기반 구조화된 추출)

### 2.5 Skills & MCP

**MCP (Model Context Protocol)** 은 Anthropic이 만든 오픈 프로토콜로, Agent를 외부 Tool, 데이터 소스, 서비스에 표준화된 방식으로 연결해요.

**MCP 생태계:**

| 리소스 | 설명 |
|--------|------|
| [MCP 공식 사이트](https://modelcontextprotocol.io/introduction) | 프로토콜 명세 및 소개 |
| [공식 MCP Server들](https://github.com/modelcontextprotocol/servers) | GitHub, Slack, Postgres, Puppeteer 등 참조 구현 |
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | 스크린샷 대신 Accessibility Tree를 사용하여 토큰 비용 대폭 감소 |
| [MCP Inspector](https://github.com/modelcontextprotocol/inspector) | MCP Server 디버깅 UI |
| [Streamable HTTP Transport](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports) | 원격 MCP 배포를 가능하게 하는 전송 규격 |
| [2026 MCP Roadmap](https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/) | 수평 확장, `.well-known` 검색, Tasks 프리미티브, Enterprise 확장 계획 |

**관련 프로토콜:**

- **[A2A Protocol](https://github.com/a2aproject/A2A)** — Google의 Agent-to-Agent 프로토콜. JSON-RPC over HTTP(S)/SSE, Agent Card 기반 서비스 검색
- **[AG-UI](https://github.com/ag-ui-protocol/ag-ui)** — Agent-to-UI 프로토콜. MCP(Tool 접근)와 A2A(Agent 간 통신) 사이의 빈 레이어를 채우는 실시간 UI 연결
- **[Composio](https://github.com/ComposioHQ/composio)** — 250개 이상의 SaaS API를 Agent-Ready Action으로 래핑, 관리형 OAuth 포함

**핵심 발견:** Agent가 Tool을 직접 호출하는 대신 **코드를 작성하여 MCP Server와 상호작용**하면 토큰 오버헤드가 최대 **98.7% 감소** ([Anthropic](https://www.anthropic.com/engineering/code-execution-with-mcp))

### 2.6 Permissions & Authorization

Agent에게 어떤 권한을 어떻게 부여할 것인가에 대한 영역이에요.

**핵심 패턴:**

- **5단계 평가 순서:** Hooks → Deny Rules → Permission Mode → Allow Rules → canUseTool ([Claude Agent SDK](https://platform.claude.com/docs/en/agent-sdk/permissions))
- **두 가지 Authorization 유형:** On-behalf-of(사용자 자격 증명 대행) vs Fixed-credential(Agent 자체 계정) — 위협 모델이 근본적으로 달라요 ([LangChain](https://blog.langchain.com/two-different-types-of-agent-authorization/))
- **Auto Mode:** 승인 피로 문제 해결(사용자가 93%를 승인하여 승인이 무의미해지는 현상). 빠른 단일 토큰 게이트 + 위험 플래그 시에만 심층 추론 ([Anthropic](https://www.anthropic.com/engineering/claude-code-auto-mode))
- **OWASP LLM06: Excessive Agency** — 과도한 기능, 불필요한 권한, 승인 메커니즘 부재에 대한 표준 체크리스트 ([OWASP](https://genai.owasp.org/llmrisk/llm062025-excessive-agency/))
- **IETF 표준화** — AI Agent Authentication의 첫 IETF 표준 규격(2026년 3월). SPIFFE 스타일 식별자, OAuth Token Exchange, DPoP 활용 ([IETF Draft](https://datatracker.ietf.org/doc/draft-klrc-aiagent-auth/))

### 2.7 Memory & State

Agent의 상태와 기억을 어떻게 관리하고 지속시킬 것인가의 영역이에요.

**3가지 메모리 유형 (COALA 기반):**

| 유형 | 설명 | 예시 |
|------|------|------|
| **Procedural** (절차적) | Agent의 행동 규칙과 관례 | AGENTS.md, System Prompt |
| **Semantic** (의미적) | 지식과 사실 | 코드 컨벤션, 도메인 지식 |
| **Episodic** (에피소드적) | 과거 경험과 상호작용 기록 | 이전 세션 요약, Git 커밋 이력 |

**핵심 시스템:**

- **[Letta (MemGPT)](https://github.com/letta-ai/letta)** — 3단계 메모리(Core/Archival/Recall) 참조 아키텍처
- **[mem0](https://github.com/mem0ai/mem0)** — Drop-in 범용 메모리 레이어. AWS Agent SDK의 독점 메모리 제공자
- **[Zep](https://github.com/getzep/zep)** — 대화 자동 요약, 엔티티 추출, 세션 이력 시맨틱 검색

**핵심 교훈:**

- 메모리 품질은 대부분 **신선도(freshness)와 무효화(invalidation)** 문제예요. 오래되고 Branch 특정적인 메모리는 메모리가 없는 것보다 위험해요 ([GitHub Copilot](https://github.blog/ai-and-ml/github-copilot/building-an-agentic-memory-system-for-github-copilot/))
- In-Context 메모리는 **~8,000개 사실에서 용량 초과**, Compaction 시 **60% 사실 파괴**, 연쇄 요약 시 **54% 행동 드리프트** 발생 ([Knowledge Objects 논문](https://arxiv.org/abs/2603.17781))

### 2.8 Task Runners & Orchestration

Agent를 실행하고, 여러 Agent를 조율하는 인프라 영역이에요.

**주요 Framework:**

| Framework | 특징 |
|-----------|------|
| **[LangGraph](https://github.com/langchain-ai/langgraph)** | 그래프 기반 State Machine. Supervisor/Subagent 토폴로지, 에러 복구, Checkpoint 지속성. 가장 널리 채택된 Orchestration 레이어 |
| **[OpenAI Agents SDK](https://github.com/openai/openai-agents-python)** | Handoff와 Guardrail 중심의 경량 Multi-Agent Framework. Swarm의 프로덕션 후속작 |
| **[Google ADK](https://github.com/google/adk-python)** | Code-First Agent Framework. Multi-Agent Orchestration, Tool 등록, Session 상태, Eval 파이프라인 내장 |
| **[AutoGen](https://github.com/microsoft/autogen)** | Microsoft의 Multi-Agent 대화 Framework. 대규모 Multi-Agent Harness 설계의 가장 포괄적인 오픈소스 참조 |
| **[CrewAI](https://github.com/crewAIInc/crewAI)** | 이중 레이어: Crew(자율 위임) + Flow(이벤트 기반 결정론적 제어). 자율/스크립트 실행 혼합의 최고 예시 |
| **[PydanticAI](https://github.com/pydantic/pydantic-ai)** | 타입 안전 Agent Framework. Tool 정의가 Pydantic Model이어서 출력 불일치가 타입 체크 오류로 전환 |
| **[Vercel AI SDK](https://github.com/vercel/ai)** | TypeScript 최고의 AI Agent Toolkit. 월 2천만+ 다운로드, 25+ Provider 통합 |
| **[Mastra](https://github.com/mastra-ai/mastra)** | TypeScript 네이티브 (Gatsby 팀). 40+ Provider, 내장 Workflow/RAG/Agent Orchestration |

**프로덕션 아키텍처:**

- **Brain/Hands/Session 분리:** "Brain"(Claude + Harness), "Hands"(Sandbox/Tool), "Session"(Append-Only 이벤트 로그)을 독립적으로 실패/교체 가능하게 분리. p50 TTFT **~60%**, p95 **90% 이상** 감소 ([Anthropic](https://www.anthropic.com/engineering/managed-agents))
- **[LiteLLM](https://github.com/BerriAI/litellm)** — 100+ LLM Provider를 단일 OpenAI 호환 인터페이스로. 429/500 에러 시 자동 Failover, 예산 제한

### 2.9 Verification & CI Integration

Agent 출력을 어떻게 검증하고 CI 파이프라인에 통합할 것인가의 영역이에요.

**핵심 원칙:**

1. **결정론적 검사부터** — Linter, 테스트, 명령어 시퀀스 확인을 먼저 수행
2. **LLM-as-Judge는 마지막에** — 비용이 많이 들므로 결정론적 검사가 커버하지 못하는 영역에만 사용
3. **Capability Eval과 Regression Eval 분리** — 전자는 개선 목표(낮은 통과율), 후자는 보호 목표(거의 100%). 혼합하면 우선순위 판단이 틀려져요

**핵심 도구:**

- **[promptfoo](https://github.com/promptfoo/promptfoo)** — YAML 기반 LLM 테스팅. LLM-as-Judge, Assertion DSL, CI 통합
- **[AgentBench](https://github.com/THUDM/AgentBench)** — 다중 환경(OS, DB, Web, Code) Agent 벤치마크
- **[AgentAssay](https://arxiv.org/abs/2603.02601)** — 비결정론적 Workflow용 회귀 테스트. 행동 Fingerprinting으로 86% 회귀 감지, 토큰 비용 78% 절감

### 2.10 Observability & Tracing

Agent의 모든 추론 단계와 Tool 호출을 추적하고 모니터링하는 영역이에요.

**핵심 도구:**

| 도구 | 특징 |
|------|------|
| **[OpenLLMetry](https://github.com/traceloop/openllmetry)** | OpenTelemetry 기반. 기존 OTEL 생태계(Grafana, Datadog, Jaeger)를 Agent에 적용 |
| **[Langfuse](https://github.com/langfuse/langfuse)** | 가장 널리 채택된 Self-Hostable LLM Observability 플랫폼 |
| **[Arize Phoenix](https://github.com/Arize-ai/phoenix)** | Self-Hostable Trace UI 및 Eval 런타임. 오프라인 재생(Replay) 가능 |
| **[W&B Weave](https://github.com/wandb/weave)** | Agent Workflow 전용 Tracing/Eval. 자동 Call Graph 캡처 |
| **[Pydantic Logfire](https://github.com/pydantic/logfire)** | 모든 Trace 데이터가 SQL 쿼리 가능. Agent가 프로덕션 Observability 데이터를 직접 조회 가능 |
| **[Helicone](https://github.com/Helicone/helicone)** | 300+ Model 가격 DB. 비용 추적, 세션 Tracing, Prompt 버전 관리 |

**핵심 표준:** [OTel GenAI Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/) — `gen_ai.system`, `gen_ai.request.model` 등 표준 속성명으로 Harness Trace를 OTEL 호환 백엔드 간 이식 가능하게 만들어요.

### 2.11 Debugging & Developer Experience

Agent 실패를 어떻게 진단하고 디버깅할 것인가의 영역이에요.

**핵심 도구와 연구:**

- **[AgentOps](https://github.com/AgentOps-AI/agentops)** — Session Replay, 비용 추적, 실패 감지. CrewAI, LangGraph, OpenAI Agents SDK 등 10+ Framework 지원
- **[AgentRx (Microsoft)](https://www.microsoft.com/en-us/research/blog/systematic-debugging-for-ai-agents-introducing-the-agentrx-framework/)** — 자동 근본 원인 분석. Trajectory 정규화, 제약 합성, 제약 기반 평가. 기존 방법보다 **23.6% 높은 실패 위치 특정** 정확도
- **[AgentPrism](https://github.com/evilmartians/agent-prism)** — OTEL Trace 데이터를 인터랙티브 시각화로 변환하는 React 컴포넌트 라이브러리

**실제 Agent 시스템의 주요 결함 유형** (375개 GitHub Issue 분석, [논문](https://arxiv.org/abs/2603.06847)):

1. 초기화 실패
2. 역할 이탈
3. 메모리/상태 결함
4. Orchestration 실패
5. Tool 통합 오류

### 2.12 Human-in-the-Loop

Agent 루프에 인간 개입을 어떻게 삽입할 것인가의 영역이에요.

**세 가지 인간 개입 자세** ([Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/humans-and-agents.html)):

| 자세 | 설명 | 확장성 |
|------|------|--------|
| **Human outside the loop** | Agent에게 작업 위임 후 결과만 검토 | 낮음 |
| **Human in the loop** | 개별 출력을 직접 검토/승인 | 중간 |
| **Human on the loop** | Harness 자체를 설계/유지보수 | **높음** (Agent 처리량에 비례해 확장) |

**핵심 발견:** 경험 많은 사용자는 개별 행동 승인(새로울 때 20% Auto-Approve)에서 개입 전용 감독(750+ 세션에서 40% Auto-Approve)으로 전환해요 ([Anthropic](https://www.anthropic.com/news/measuring-agent-autonomy))

**구현 참조:**
- **[HITL Protocol](https://github.com/rotorstar/hitl-protocol)** — HTTP 202 + Review URL 패턴. ~15줄 코드로 Agent에 Human 승인 게이트 삽입
- **[Claude Agent SDK](https://platform.claude.com/docs/en/agent-sdk/user-input)** — `canUseTool` 콜백으로 모든 Tool 요청에서 Allow/Deny/Approve-with-Changes/Suggest-Alternative 응답

---

## 3. Reference Implementations (참조 구현)

실제 코드를 연구할 가치가 있는 저장소들이에요.

### 교육 및 튜토리얼

| 리소스 | 왜 볼 가치가 있는가 |
|--------|---------------------|
| [anthropics/claude-cookbooks](https://github.com/anthropics/claude-cookbooks) | Orchestrator-Worker 패턴, Parallel Tool Calling, Context Compaction 등 공식 노트북 |
| [huggingface/smolagents](https://github.com/huggingface/smolagents) | ~1,000줄 핵심 코드로 구현된 최소한의 Agent 라이브러리. 반나절 만에 전체 Harness를 읽을 수 있어요 |
| [shareAI-lab/learn-claude-code](https://github.com/shareAI-lab/learn-claude-code) | Claude Code를 Agent Harness로 단계별 분해 (s01–s12) |
| [Skill Issue: Harness Engineering](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) | Agent 실패의 대부분은 설정 문제이지 Model 한계가 아니라는 실무자 가이드 |

### Generators & Meta-Harnesses

Harness 자체를 생성하거나 최적화하는 시스템이에요.

| 리소스 | 설명 |
|--------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Anthropic Hackathon 우승작 (140K+ Stars). Skills, Memory, 보안 스캔, 지속적 학습이 포함된 Agent Harness 최적화 시스템 |
| [Claude Agent SDK](https://platform.claude.com/docs/en/agent-sdk/overview) | Claude Code의 전체 Harness를 프로그래밍 API로 노출. Tool 실행 루프를 직접 구현하지 않고 상속 |
| [AutoAgent](https://github.com/kevinrgu/autoagent) | 과제와 벤치마크를 주면 밤새 System Prompt, Tool 구성, Agent Orchestration을 자동 반복 최적화. SpreadsheetBench에서 **96.5%로 1위** |
| [metaharness](https://github.com/SuperagenticAI/metaharness) | AGENTS.md, 셋업 스크립트, 검증 로직을 최적화 대상으로 취급하는 메타 최적화 루프 |

### Demo Harnesses

| 리소스 | 특징 |
|--------|------|
| [OpenHands](https://github.com/OpenHands/OpenHands) | 가장 아키텍처적으로 완전한 오픈소스 Coding Agent. Runtime/Sandbox/EventStream/Agent Controller 3계층 설계 |
| [SWE-agent](https://github.com/SWE-agent/SWE-agent) | Agent-Computer Interface(ACI) — 범용 Bash 대신 도메인 특화 파일 뷰어/검색/편집기 Tool |
| [Aider](https://github.com/Aider-AI/aider) | Architect Mode로 계획(한 LLM)과 코딩(다른 LLM) 분리. Git을 Undo 메커니즘으로 활용 |
| [OpenCode](https://github.com/anomalyco/opencode) | 131K+ Stars, 월 250만+ 활성 개발자. 75+ LLM Provider, LSP 자동 설정, 멀티세션 병렬 Agent |
| [browser-use](https://github.com/browser-use/browser-use) | 최소한의 브라우저 자동화 Agent Harness. 핵심 루프 메커니즘 이해를 위한 "최소 실행 가능 Harness" 참조 |

---

## 4. 핵심 인사이트 요약

### Harness-First 사고

> "최고의 Harness는 Model이 발전하면서 그 컴포넌트들이 불필요해질 것을 알고 설계된다."

Harness 설계는 "Model이 못하는 것"에 대한 가정 위에 세워지며, 그 가정은 시간이 지나면 만료돼요.

### Context가 핵심 자원

- Context Window 관리, Compaction, "Context Engineering"이 주요 최적화 레버예요
- **파일 시스템 기반 Context** (소스 코드, Runbook, 쿼리 스키마, 과거 조사 노트를 파일로 노출)가 100개의 맞춤 Tool보다 나을 수 있어요 (Azure SRE Agent 사례)

### 아키텍처를 통한 안전성

- Permission 시스템, Multi-Agent 조율, Sandbox 설계가 Prompt 수준의 신뢰보다 중요해요
- 단일 Tool 안전성 분석은 Tool **조합**에서 발생하는 위험을 놓칠 수 있어요

### Multi-Agent 토폴로지

- Single Agent에서 Orchestrated 팀으로의 전환은 아키텍처적 결정(Handoff, Routing, Shared State)이 필요해요
- Multi-Agent 시스템은 분산 시스템처럼 행동하므로, 모든 Handoff에 Typed Schema와 명시적 경계 검증이 필요해요

### Eval 방법론

- 검증에는 계층적 접근이 필요해요 — **결정론적 검사가 먼저**, LLM-as-Judge는 필요한 곳에만
- Harness 설정만으로 벤치마크 점수가 **5점 이상** 변동할 수 있어요

### 프로덕션 실증 데이터

| 사례 | 수치 |
|------|------|
| Azure SRE Agent | 인시던트 완화 시간 40.5시간 → **3분** |
| Azure SRE Agent Context Engineering | Intent Met 점수 45% → **75%** |
| LangChain Deep Agent | Harness만 변경으로 Terminal Bench 30위 → **Top 5** |
| Server-Side Compaction | 토큰 소비 **84% 감소** |
| MCP 코드 실행 방식 | 토큰 오버헤드 **98.7% 감소** |
| Claude Code Skills Routing | 정확도 73% → **85%** (부정 예시 추가) |

---

## 관련 Awesome 리스트

| 리소스 | 초점 |
|--------|------|
| [EvoMap/awesome-agent-evolution](https://github.com/EvoMap/awesome-agent-evolution) | Agent 진화, 자기 수정 |
| [Picrew/awesome-agent-harness](https://github.com/Picrew/awesome-agent-harness) | 구현 중심 150개 항목 |
| [VoltAgent/awesome-ai-agent-papers](https://github.com/VoltAgent/awesome-ai-agent-papers) | 363+ arXiv 논문 (주간 업데이트) |
| [bradAGI/awesome-cli-coding-agents](https://github.com/bradAGI/awesome-cli-coding-agents) | 80+ 터미널 네이티브 AI Coding Agent 카탈로그 |

---

> **참고:** 이 문서는 [ai-boost/awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering) 저장소의 내용을 한국어로 설명하고 정리한 것이에요. 원본은 활발하게 업데이트되고 있으므로, 최신 내용은 원본 저장소를 참조해 주세요.
