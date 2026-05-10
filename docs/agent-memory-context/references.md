# 에이전트 메모리 / 컨텍스트 관리 — 참고 자료

직접 읽고 소화한 자료만. 아래는 핵심도 순.

## 필독

- **Anthropic, "Effective context engineering for AI agents"** (2025)
  https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
  Context engineering 용어를 자리 잡게 한 글. 어텐션 예산 / context rot / just-in-time retrieval / compaction·structured note-taking·sub-agents 3대 long-horizon 기법.

- **Anthropic, "Managing context on the Claude Developer Platform"** (2025)
  https://claude.com/blog/context-management
  Context editing(`context-management-2025-06-27` 베타)과 Memory tool(`memory_20250818`) 공식 발표. 100턴 웹서치 평가에서 토큰 84%↓, 정확도 둘 다 켰을 때 39%↑.

- **LangChain, "Context Engineering for Agents"** (Lance Martin, 2025)
  https://www.langchain.com/blog/context-engineering-for-agents
  Write/Select/Compress/Isolate 4분류와 각각의 구체 사례·트레이드오프. 외울 가치 있는 표 다수.

- **LangChain, "Memory for agents"**
  https://www.langchain.com/blog/memory-for-agents
  Semantic/episodic/procedural 분류와 hot path/background/feedback 업데이트 트레이드오프. CoALA의 실용 버전.

- **Claude Code 공식 docs, "How Claude remembers your project"**
  https://code.claude.com/docs/en/memory
  CLAUDE.md vs auto memory(MEMORY.md) 차이, 로딩 순서, `/compact` 후 무엇이 살아남는가. 코딩 에이전트 운영자에게 가장 실용적.

## 프레임워크 / 도구

- **Anthropic Memory tool API docs**
  https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool
  6가지 명령 명세, security(path traversal), Compaction 조합, multi-session software development 패턴(initializer + progress log).

- **Letta, "Agent Memory"**
  https://www.letta.com/blog/agent-memory
  Message buffer / Core / Recall / Archival 4계층. MemGPT 후속작 입장에서 Sleep-Time Compute(비동기 메모리 정리)까지.

- **Mem0, "State of AI Agent Memory 2026"**
  https://mem0.ai/blog/state-of-ai-agent-memory-2026
  LOCOMO 비교 표, 19개 vector + 2개 graph backend 지원, 미해결 문제(application-level 평가, staleness, identity, consent) 솔직한 정리.

- **Atlan, "Vector Database vs Knowledge Graph"**
  https://atlan.com/know/vector-database-vs-knowledge-graph-agent-memory/
  Vector / KG / Governed metadata graph 3축 비교. Hybrid가 표준이 된 이유, 운영 측면(콜드스타트/거버넌스/freshness).

- **Cognition, "Rebuilding Devin for Claude Sonnet 4.5"** (2025)
  https://cognition.ai/blog/devin-sonnet-4-5-lessons-and-challenges
  Sonnet 4.5의 context-awareness가 만든 "context anxiety" + 그 우회(1M 베타에서 200K cap). 자체 압축 모델 fine-tune 사례.

- **Anthropic, "How we built our multi-agent research system"**
  https://www.anthropic.com/engineering/multi-agent-research-system
  멀티 에이전트 90.2% 향상, 토큰 15× 비용. lead의 plan을 200K 한계 전 외부 메모리에 저장하는 패턴.

## 학술 논문

- **Packer et al., "MemGPT: Towards LLMs as Operating Systems"** (arxiv 2310.08560, 2023–2024)
  가상 컨텍스트를 OS page swap으로 비유. 이후 모든 메모리 시스템의 기준점. 2024.09부터 Letta로 통합.

- **Maharana et al., "LOCOMO"** (arxiv 2402.17753, ACL 2024)
  35세션·평균 9K토큰 장기 대화 벤치. 5종 reasoning. 메모리 시스템 비교의 사실상 표준. 합성 데이터 한계 인지 필요.

- **Xu et al., "Zep: Temporal Knowledge Graph for Agent Memory"** (arxiv 2501.13956, 2025)
  시간 유효성을 1급으로. DMR 94.8%(MemGPT 93.4%). 충돌 시 삭제가 아닌 `valid_to` 갱신으로 과거 시점 질의 보존.

- **Xu et al., "A-MEM: Agentic Memory"** (arxiv 2502.12110, NeurIPS 2025)
  Zettelkasten 영감. 새 메모리 추가 시 기존 메모리의 contextual representation까지 진화시킴.

- **"Memory for Autonomous LLM Agents: Mechanisms, Evaluation, and Emerging Frontiers"** (서베이)
  https://arxiv.org/html/2603.07670v1
  5 메커니즘 + failure modes(summarization drift, semantic mismatch, staleness, contradiction). 입문자에게 한 번 훑기 좋음.

## 케이스 스터디 / 실전

- **orchestrator.dev, "Claude Code Agent Memory: 2026 Best Practices"**
  https://orchestrator.dev/blog/2026-04-06--claude-code-agent-memory-2026/
  CLAUDE.md 300줄 미만, "이 줄 빼면 실수하나?" 원칙. 보안 규칙은 CLAUDE.local.md (compaction 후 reload).

- **Hindsight, "Your Claude Code Subagents Don't Share What They Learn"** (2026.05)
  https://hindsight.vectorize.io/blog/2026/05/06/claude-code-subagents-shared-memory
  서브에이전트 격리로 학습이 휘발되는 문제. native 해결책의 한계와 공유 메모리 레이어 필요성.

- **Leonie Monigatti, "The Evolution from RAG to Agent Memory"**
  https://www.leoniemonigatti.com/blog/from-rag-to-agent-memory.html
  RAG read-only 한계 vs memory read-write. Semantic/episodic/procedural을 별도 collection으로.

- **Martin Fowler, "Context Engineering for Coding Agents"**
  https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html
  코딩 에이전트 한정 실용 가이드. CLAUDE.md/rules/skills/subagents/hooks 사용 시점 비교.

## 컨텍스트 엔지니어링 (메타)

- **Weaviate, "Context Engineering — LLM Memory and Retrieval"**
  https://weaviate.io/blog/context-engineering
  6 컴포넌트(System prompt/Instructions/User input/Structured I/O/Tools/RAG & Memory) 분류.

- **"Agentic Context Engineering" (ACE)** (arxiv 2510.04618, 2025)
  컨텍스트를 evolving playbook으로 보고 generation/reflection/curation으로 진화. 아직 학술 단계.

## 미해결 / 솔직한 인지

자료마다 인정하는, 2026.05 시점에 답이 없는 영역.
- **Application-level 평가**: LOCOMO는 일반적 recall만. 도메인별 평가셋은 각자.
- **Staleness 자동 검출**: "이 메모리가 더 이상 맞지 않다"의 일관된 자동 판단 부재.
- **Cross-device identity**: anonymous→authenticated 전이의 표준 부재.
- **Procedural memory 자동 갱신**: 가중치 학습 외 형태로의 절차 영속화는 거의 비어 있음.
- **서브에이전트 간 학습 공유**: 격리 장점과 학습 휘발 단점의 정면 충돌. 외부 메모리 레이어가 임시 해법.
