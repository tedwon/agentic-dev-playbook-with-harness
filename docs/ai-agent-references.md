# AI Agent Development Framework References

## Foundational Guides (Start Here)

1. **Anthropic — "Building Effective Agents"** — The most widely cited guide. Distinguishes between **workflows** (predefined orchestration) vs **agents** (LLM-driven decisions). Core advice: start simple, add complexity only when needed.
   - [Research article](https://www.anthropic.com/research/building-effective-agents)
   - [Cookbook with code examples](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents)
   - [Architecture Patterns PDF](https://resources.anthropic.com/hubfs/Building%20Effective%20AI%20Agents-%20Architecture%20Patterns%20and%20Implementation%20Frameworks.pdf)

2. **Anthropic — 2026 Agentic Coding Trends Report** — Data-driven look at how coding agents are reshaping development.
   - [PDF Report](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)

## Reference Architectures

3. **QuantumBlack (McKinsey) — Agentic Workflows for Software Development** — Recommends a **rule-based orchestration engine** around agents rather than self-orchestrating agents. Agents execute tasks; the workflow engine manages sequencing.
   - [Article](https://medium.com/quantumblack/agentic-workflows-for-software-development-dc8e64f4a79d)

4. **Stack AI — 2026 Guide to Agentic Workflow Architectures** — Covers four core architectures and when to use each. Key principle: give the system the smallest amount of freedom that still delivers the outcome.
   - [Article](https://www.stackai.com/blog/the-2026-guide-to-agentic-workflow-architectures)

## Framework-Specific

5. **OpenAI Agents SDK** — Production-grade toolkit with explicit agent handoffs
6. **Google ADK** — Hierarchical agent tree with A2A protocol support
7. **LangGraph** — Graph-based stateful workflows (most popular open-source option)
8. **CrewAI** — Role-based multi-agent team automation

## Key Takeaways Across All Sources

- **Start simple** — a single LLM call + tool often beats a multi-agent system
- **Orchestration > prompt engineering** — designing agent workflows matters more than crafting prompts
- **Specialize agents** — multiple focused agents outperform one general-purpose agent
- **Human-in-the-loop** — delegate execution to agents, but keep architecture decisions and ownership human
- **Observability first** — invest in monitoring, evaluation, and feedback loops from day one

## Sources

- [Building Effective Agents — Anthropic](https://www.anthropic.com/research/building-effective-agents)
- [Anthropic Agent Cookbook](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents)
- [2026 Agentic Coding Trends Report — Anthropic](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)
- [Agentic Workflows for Software Development — QuantumBlack/McKinsey](https://medium.com/quantumblack/agentic-workflows-for-software-development-dc8e64f4a79d)
- [2026 Guide to Agentic Workflow Architectures — Stack AI](https://www.stackai.com/blog/the-2026-guide-to-agentic-workflow-architectures)
- [5 Key Trends Shaping Agentic Development in 2026 — The New Stack](https://thenewstack.io/5-key-trends-shaping-agentic-development-in-2026/)
- [Agentic AI Frameworks for Enterprise Scale — Akka](https://akka.io/blog/agentic-ai-frameworks)
