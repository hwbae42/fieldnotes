# 참고 자료

> 모두 직접 읽고 본 문서에 인용한 자료. 단순 링크 모음이 아니다.
> 각 항목: 한 줄 요약 + 왜 이걸 읽어야 하는지.

## 필독 (먼저 이걸 읽고 시작하라)

- **[Building Effective Agents — Anthropic (2024-12)](https://www.anthropic.com/research/building-effective-agents)**
  워크플로우 vs 에이전트 구분과 5개 워크플로우 패턴(prompt chaining / routing / parallelization / orchestrator-workers / evaluator-optimizer)의 정전. 이 분야의 어휘를 정한 글이라 다른 모든 문서가 이걸 가정하고 쓴다.

- **[How we built our multi-agent research system — Anthropic Engineering (2025-06)](https://www.anthropic.com/engineering/multi-agent-research-system)**
  Orchestrator-Worker 패턴의 production 케이스 스터디. lead Opus + worker Sonnet으로 +90.2% / 15× 토큰 트레이드오프. 서브에이전트 위임 프롬프트 엔지니어링과 흔한 실패 모드(과도 스폰, 중복 작업, 소스 편향) 정리.

- **[Don't Build Multi-Agents — Cognition / Walden Yan (2025-06)](https://cognition.ai/blog/dont-build-multi-agents)**
  반대 진영. "Share full context, share full agent traces, not just messages" / "Actions carry implicit decisions". Flappy Bird 예시. Devin 팀이 단일 스레드 에이전트를 고집하는 이유. Anthropic 글과 짝으로 함께 읽어야 함.

- **[Effective harnesses for long-running agents — Anthropic Engineering (2026)](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)**
  컨텍스트 윈도우보다 긴 작업을 위한 세션 간 핸드오프 + 평가 분리 + measurable rubric. "every component in a harness encodes an assumption about what the model can't do" 한 문장이 핵심. 하네스 디자인의 1급 자료.

- **[Harness design for long-running application development — Anthropic Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)**
  위 글의 짝. Initializer + Coding agent + 진행 파일/git 외부 메모리 구체 셋업.

## 프레임워크 / 하네스 공식 문서

- **[Claude Agent SDK Overview — code.claude.com](https://code.claude.com/docs/en/agent-sdk/overview)**
  Claude Code의 라이브러리화. tool loop·서브에이전트·MCP·세션·권한 모드의 reference. SDK vs Claude Code CLI vs Managed Agents 비교 표.

- **[Claude Code Subagents — code.claude.com](https://code.claude.com/docs/en/sub-agents)**
  서브에이전트 YAML 스펙(name, description, tools, model, permissionMode, mcpServers, hooks, memory, isolation 등)과 빌트인 Explore/Plan/General-purpose. 컨텍스트 격리 패턴의 production-grade 정의.

- **[OpenAI Agents SDK — Handoffs](https://openai.github.io/openai-agents-python/handoffs/)**
  `handoff()` API와 triage 패턴. "Handoffs vs Agent.as_tool()" 결정 기준이 명확.

- **[Orchestrating Agents: Routines and Handoffs — OpenAI Cookbook](https://cookbook.openai.com/examples/orchestrating_agents)**
  OpenAI Swarm의 정신적 계승자. routine + handoff로 멀티 에이전트를 단순하게 표현하는 작은 예제 코드.

- **[langgraph_supervisor 레퍼런스 — LangChain](https://reference.langchain.com/python/langgraph-supervisor)**
  `create_supervisor`, `create_handoff_tool`, `create_forward_message_tool` API. supervisor 패턴의 official 구현.

- **[langgraph_swarm 레퍼런스 — LangChain](https://reference.langchain.com/python/langgraph-swarm)**
  `create_swarm`, `add_active_agent_router`. swarm 패턴 official 구현.

- **[Plan-and-Execute Agents — LangChain Blog](https://www.langchain.com/blog/planning-agents)**
  ReAct 대비 plan-and-execute의 동기와 변형(ReWOO, LLMCompiler). 단순한 dia그램으로 차이가 잘 보임.

## 케이스 스터디 / 비교

- **[Benchmarking Multi-Agent Architectures — LangChain Blog](https://www.langchain.com/blog/benchmarking-multi-agent-architectures)**
  τ-bench 변형으로 single / supervisor / swarm 비교. swarm이 약간 더 정확하지만 supervisor의 generic·서드파티 호환을 권장. 토큰·정확도 그래프가 직관적.

- **[Swarm vs Supervisor — Augment Code](https://www.augmentcode.com/guides/swarm-vs-supervisor)**
  시나리오별 선택 기준 + cascading drift 같은 실패 모드. supervisor → swarm 전환으로 latency 40% 단축 사례.

- **[AI Coding Harness Comparison 2026 — thoughts.jock.pl](https://thoughts.jock.pl/p/ai-coding-harness-agents-2026)**
  Claude Code / Codex CLI / Aider / OpenCode / Cursor / Pi의 강점·약점을 시나리오 표로 정리. "같은 Opus 모델이 Claude Code 77%, Cursor 93%" 16%p 격차로 하네스 효과 정량화.

- **[2026 AI Agent Framework Showdown — QubitTool](https://qubittool.com/blog/ai-agent-framework-comparison-2026)**
  Claude Agent SDK / Strands / LangGraph / OpenAI Agents SDK 크로스 비교. 모델 종속성·관측·생산 성숙도 매트릭스. 선택 가이드.

- **[Agent Harness Engineering — Addy Osmani](https://addyosmani.com/blog/agent-harness-engineering/)**
  "Agent = Model + Harness" 프레임. ratchet principle, behaviour-driven design, 모델 개선 시 스캐폴딩 제거. 일반 원칙 정리에 좋음.

- **[What Is an Agent Harness? — MindStudio](https://www.mindstudio.ai/blog/what-is-agent-harness-architecture-explained)**
  하네스의 9개 컴포넌트 분해(Model Interface / Tool Registry / Context Manager / Planning / Execution / Memory / Feedback / Guardrails / Orchestration). 어휘 통일 용도.

## 비판적 시각 / 양쪽 입장

- **[AI Leaders Clash Over Agent Architecture — CTOL Digital](https://www.ctol.digital/news/ai-leaders-clash-agent-architecture-cognition-anthropic-strategies/)**
  Cognition vs Anthropic 입장 차이를 정리한 분석. 두 글이 사실은 다른 작업 영역을 본다는 점을 잘 짚는다.

- **[Multi-Agent Research System (Simon Willison's notes)](https://simonwillison.net/2025/Jun/14/multi-agent-research-system/)**
  Anthropic 글에 대한 Simon의 현실적인 코멘터리. 멀티 에이전트 회의론에서 설득된 이유와 토큰 비용 트레이드오프 강조.

## 평가 / 관측

- **[LangSmith Evaluations — LangChain](https://www.langchain.com/langsmith/evaluation)**
  trace 기반 에이전트 평가. 단계별 도구 호출 채점, LangGraph와 통합.

- **[Braintrust vs LangSmith](https://www.braintrust.dev/articles/langsmith-vs-braintrust)**
  관점은 자사 우호적이지만 PR 머지 게이트로서의 native CI/CD 비교가 쓸 만하다. 프레임워크 중립이 필요하면 Braintrust, LangChain stack에 깊이 들어가 있으면 LangSmith.

## 기타 도움 됐지만 위 카테고리에 안 들어간 자료

- **[Effective Context Engineering for AI Agents — MachineLearningMastery](https://machinelearningmastery.com/effective-context-engineering-for-ai-agents-a-developers-guide/)** — context engineering 어휘 입문.
- **[Context Engineering for Coding Agents — Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html)** — coding 도메인 한정 context 관리 패턴 정리.
- **[ReAct vs Plan-and-Execute (DEV)](https://dev.to/jamesli/react-vs-plan-and-execute-a-practical-comparison-of-llm-agent-patterns-4gh9)** — 두 루프의 단순한 비교 예시.

---

## 인용 가이드

본 fieldnotes 안에서 위 자료를 인용할 때는:
- 1차 출처(Anthropic, OpenAI, LangChain 등 공식)를 우선.
- 2차 분석(Medium / DEV / 비교 블로그)은 1차가 없을 때 또는 cross-validation 용도로만.
- 모든 일자·수치는 원문 링크와 함께 기재 (예: `+90.2%`, `15× 토큰`은 Anthropic 공식 글).
