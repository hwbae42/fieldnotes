# 에이전트 오케스트레이션 / 하네스 — Overview

> 마지막 업데이트: 2026-05-10
> 모델 지식 컷오프: 2026-01 / 본 문서는 2025–2026 자료 우선.

## 왜 이 분야가 중요한가

같은 모델이라도 **하네스 설계에 따라 결과 품질의 표준편차가 모델 자체보다 더 크다**. 대표적으로 보고된 수치는 동일한 Claude Opus 모델로 Claude Code는 77%, Cursor는 93%로 16%p 차이가 났다는 사례 ([thoughts.jock.pl](https://thoughts.jock.pl/p/ai-coding-harness-agents-2026)). Anthropic도 Research 시스템에서 멀티 에이전트 구성으로 단일 에이전트 대비 +90.2% 성능을 얻었다고 발표했다 ([Anthropic Engineering, 2025-06](https://www.anthropic.com/engineering/multi-agent-research-system)).

즉, 2026년 시점의 AI 엔지니어링 레버리지는 **모델 선택보다 하네스 설계**에 빠르게 옮겨가고 있다. "decent model + great harness > great model + bad harness" ([Addy Osmani, Agent Harness Engineering](https://addyosmani.com/blog/agent-harness-engineering/)).

## "하네스"란 무엇인가 — 정의

> **에이전트 = 모델(들) + 하네스**

하네스(harness)는 모델 가중치를 제외한 모든 것이다. 모델이 도구를 사용해 다단계로 목표를 달성하도록 만드는 모든 코드·구성·실행 로직.

널리 인용되는 분해 (출처: [MindStudio](https://www.mindstudio.ai/blog/what-is-agent-harness-architecture-explained), [Addy Osmani](https://addyosmani.com/blog/agent-harness-engineering/)):

| 구성 요소 | 역할 |
|---|---|
| **Model interface** | 어떤 LLM을 쓸지 추상화 (모델 교체·앙상블) |
| **Tool registry** | 사용 가능한 도구 카탈로그 + 스키마 |
| **Context manager** | 매 턴 모델이 보는 것을 결정 (compaction, snip, 메모리) |
| **Loop / planning** | ReAct, plan-and-execute 등 추론 루프 |
| **Execution engine** | 도구 호출 실행, 샌드박스, 타임아웃 |
| **Memory** | 세션 내·세션 간 상태 |
| **Permissions / guardrails** | 승인 게이트, 정책, 감사 로그 |
| **Orchestration** | 멀티 에이전트 조정 (있는 경우) |
| **Observability** | 트레이싱, 비용 측정, 평가 |

이 정의가 중요한 이유: **각 컴포넌트는 "모델이 혼자선 못 한다고 가정한 것"을 인코딩**한다. 모델이 좋아지면 일부 컴포넌트는 제거해야 한다 ([effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).

## 워크플로우 vs 에이전트 — Anthropic의 구분

Anthropic의 [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) (2024-12) essay가 정한 기본 어휘:

- **워크플로우(workflow)**: LLM과 도구가 **사전 정의된 코드 경로**로 오케스트레이션됨. 결정 흐름이 코드에 박혀 있다.
- **에이전트(agent)**: LLM이 **스스로 절차와 도구 사용을 동적으로 결정**한다.

> "optimizing single LLM calls with retrieval and in-context examples is usually enough" — 즉 단순한 게 우선이고 멀티 스텝 에이전트는 정말 필요할 때만 도입한다.

Anthropic이 정리한 **5가지 워크플로우 패턴** (모두 에이전트보다 단순):

1. **Prompt chaining** — 순차 LLM 호출
2. **Routing** — 입력 분류 후 전문화된 경로로 분기
3. **Parallelization** — 분할(sectioning) 또는 투표(voting)
4. **Orchestrator-workers** — 중앙 LLM이 동적으로 분해·위임·합치기
5. **Evaluator-optimizer** — 한 LLM이 다른 LLM을 평가/피드백

이 분류는 멀티 에이전트라는 단어가 가리키는 게 사실 **여러 다른 패턴의 묶음**임을 명확히 한다.

## 단일 에이전트 vs 멀티 에이전트 — 양쪽 입장 공정하게

이 분야에서 가장 뜨거운 논쟁. 같은 시기(2025년 6월 중순)에 정반대 결론이 발표되어 더 부각됐다.

### A. Cognition: "Don't Build Multi-Agents" (2025-06)

[원문 — cognition.ai/blog/dont-build-multi-agents](https://cognition.ai/blog/dont-build-multi-agents) (Walden Yan).

핵심 주장 두 가지:
1. **"Share context, and share full agent traces, not just individual messages"**
2. **"Actions carry implicit decisions, and conflicting decisions carry bad results"**

대표 예시 (Flappy Bird): 부모 작업 "Flappy Bird 클론 만들기"가 두 서브에이전트로 분기되면, 한쪽은 슈퍼 마리오 배경을, 다른 한쪽은 게임에 안 맞는 새 메커니즘을 만들어, 서로의 암묵적 결정을 알지 못해 합쳐지지 않는다.

결론: 현재 LLM은 사람처럼 정교한 에이전트 간 의사소통을 못 한다. 따라서 단일 스레드 에이전트 + 충분한 컨텍스트를 우선하라.

### B. Anthropic: "How we built our multi-agent research system" (2025-06)

[원문 — anthropic.com/engineering/multi-agent-research-system](https://www.anthropic.com/engineering/multi-agent-research-system).

오케스트레이터-워커 패턴. 리드 에이전트(Claude Opus 4)가 쿼리 분석·전략 수립 → 서브에이전트들(Claude Sonnet 4)에게 병렬 탐색 위임 → 결과 합성.

핵심 결과:
- 단일 에이전트 대비 **+90.2%** 성능 (BrowseComp 류 리서치 평가).
- 단, **약 15× 토큰 사용**. 가치가 큰 작업에만 정당화됨.
- 효과적이려면 **프롬프트 엔지니어링이 결정적**: 각 서브에이전트에게 명시적 목표·출력 포맷·도구 가이드·작업 경계·노력 스케일링(쉬운 질의 1 에이전트, 비교 2~4 에이전트 등)을 줘야 한다.

### 두 입장은 사실 충돌하지 않는다

자세히 읽으면 두 글이 다른 작업 영역을 본다.

| 영역 | 멀티 에이전트가 잘 맞는다 | 단일 에이전트가 낫다 |
|---|---|---|
| 작업 성격 | 너비 우선(breadth-first) 탐색, 독립 검색·정보 수집 | 깊은 종속성·코딩(이전 결정이 다음 결정에 강하게 영향) |
| 정보 양 | 단일 컨텍스트 윈도우 초과 | 한 컨텍스트에 들어옴 |
| 병렬화 가능성 | 높음 | 낮음 |
| 가치 / 토큰 비용 | 가치가 15× 비용을 정당화 | 안 함 |
| 합치기 난이도 | 결과를 단순 결합 가능 (인용·요약) | 결과 간 일관성 필요 |

Anthropic 자신도 같은 글에서 "Most domains that require all agents to share the same context or involve many dependencies between agents are not a good fit for multi-agent systems today. For example, most coding tasks involve fewer truly parallelizable tasks than research"라고 적었다.

**실용적 결정 트리**:
1. 단일 LLM 호출 + 도구로 풀리는가? → 그렇게 하라.
2. 작업이 본질적으로 병렬 탐색/리서치인가? → 오케스트레이터-워커 고려.
3. 결정 간 의존성이 강한 코딩·디버깅인가? → 단일 에이전트 + 컨텍스트 격리(서브에이전트로 외부 노이즈만 분리) 우선.

## 핵심 개념 정의

- **오케스트레이터(orchestrator) / 슈퍼바이저(supervisor) / 리드 에이전트**: 작업을 받아 분해하고 워커에게 위임, 결과를 합성. LangGraph는 supervisor라고 부르고, Anthropic은 lead/orchestrator라 부른다.
- **워커(worker) / 서브에이전트(subagent) / 스페셜리스트(specialist)**: 위임받은 부분 작업을 처리.
- **컨텍스트 격리(context isolation)**: 서브에이전트가 자기 컨텍스트 윈도우에서만 작업하고 부모에게는 **요약만 반환**. 부모 컨텍스트의 노이즈 폭발을 막는다. Claude Code의 Agent(구 Task) 도구가 대표 예 ([Claude Code subagents docs](https://code.claude.com/docs/en/sub-agents)).
- **핸드오프(handoff)**: 한 에이전트가 다른 에이전트로 **제어권 자체를 이전**. OpenAI Agents SDK 핵심 프리미티브 ([OpenAI handoffs docs](https://openai.github.io/openai-agents-python/handoffs/)).
- **Agent-as-tool**: 다른 에이전트를 함수처럼 호출하고 결과만 받음. 제어권은 부모에 남음.
- **포크(fork) 서브에이전트**: 부모 컨텍스트를 통째로 상속받는 서브에이전트. 입력 격리는 잃지만 출력 격리는 유지.
- **권한 모드(permission mode)**: 도구 호출 시 사용자 승인을 어떻게 처리할지 (`default`, `acceptEdits`, `auto`, `plan`, `bypassPermissions` 등). 하네스 안전성의 핵심.
- **컨텍스트 압축(compaction)**: 컨텍스트가 커지면 자동/수동으로 요약·정리. Claude Agent SDK는 5단계 파이프라인(budget reduction → snip → microcompact → context collapse → auto-compact)을 갖는다.

## 주요 하네스 / 프레임워크 한 줄 요약

| 카테고리 | 도구 | 한 줄 요약 | 적용 시점 |
|---|---|---|---|
| **Coding harness — CLI** | Claude Code | `CLAUDE.md`·서브에이전트·훅 가장 성숙. 장시간 자율 실행 강함, 토큰 무거움 | 복잡한 리팩터, overnight 작업 |
| | Codex CLI / 클라우드 | OpenAI 클라우드 컨테이너에서 PR 단위로 자율 실행 | 격리된 기능 구현, 백그라운드 |
| | Aider | git-우선 페어 프로그래머. 모든 편집이 커밋 | 점진적 리팩터, 토큰 절약 |
| | Cline | VS Code 확장 페어 프로그래머 | IDE 내 대화형 |
| | Gemini CLI / OpenCode / Pi | 모델·프로바이더 무관, 가벼운 primitives | 모델 비교, 커스텀 통합 |
| **Coding harness — IDE/cloud** | Cursor | IDE 통합 + 클라우드 에이전트 + worktree 병렬 | 키보드 앞 일상 흐름 |
| | Devin | 종단 자율 SWE 에이전트, single-thread 강조 | 위임형 작업 (Cognition 철학) |
| | GitHub Copilot Agent | GitHub Issues·PR과 통합 | 깃허브 워크플로우 내 |
| **Agent runtime / SDK** | Claude Agent SDK | Claude Code의 라이브러리화. tool loop·compaction·서브에이전트 포함 | Claude 전용·관리형 환경 원할 때 |
| | OpenAI Agents SDK | Agents·Tools·Handoffs·Guardrails 4 프리미티브, 핸드오프 중심 | OpenAI 생태계, 순차 위임 |
| | LangGraph | 상태 그래프, supervisor·swarm 구현 제공 | 모델 무관, 정교한 제어가 필요할 때 |
| | CrewAI | 역할 기반 팀(역할·태스크 DSL) | 콘텐츠/리서치 파이프라인, 빠른 시작 |
| | AutoGen / AG2 | 대화 기반 GroupChat, 협상형 에이전트 | 코드 생성·연구; *유지보수 모드* |
| | Strands | 모델 무관 미니멀 (AWS Bedrock 친화) | AWS, 대규모 도구 카탈로그 |

(출처: [QubitTool 2026 비교](https://qubittool.com/blog/ai-agent-framework-comparison-2026), [Tembo 2026 가이드](https://www.tembo.io/blog/coding-cli-tools-comparison), [thoughts.jock.pl](https://thoughts.jock.pl/p/ai-coding-harness-agents-2026))

> 확인 필요: AutoGen은 2026년 초 Microsoft가 broader Agent Framework로 개발 우선순위를 옮겨 사실상 maintenance 모드라는 보고가 다수 있다 ([gurusup](https://gurusup.com/blog/best-multi-agent-frameworks-2026)). 새 프로젝트 채택 시 검토 필요.

## 에이전트 루프 — 두 가지 큰 갈래

(자세한 패턴은 `patterns.md` 참고.)

- **ReAct (reason + act)**: 매 턴 모델이 "생각 → 도구 호출 → 관찰 → 다시 생각"을 반복. 다음 행동이 직전 결과에 강하게 의존하는 열린 작업에 강함. 거의 모든 코딩 에이전트의 기본 루프.
- **Plan-and-execute**: 먼저 전체 다단계 계획 수립 → 실행자가 단계별 수행 → 필요시 재계획. 단계 수가 크고 병렬화 가능한 작업에 강함. LLM 호출 수와 비용을 줄일 수 있음 ([LangChain planning agents 글](https://www.langchain.com/blog/planning-agents)).

실전에서는 **외부 루프는 plan-and-execute, 내부 루프는 ReAct** 같은 하이브리드가 흔하다. Anthropic의 multi-agent research system은 본질적으로 외부에서 plan(리드 에이전트), 내부 서브에이전트는 ReAct로 동작한다.

## "다른 프로젝트에 어떻게 가져다 쓸까" 관점의 체크리스트

새 프로젝트에서 에이전트 시스템을 도입할 때, 위 개념을 다음 순서로 적용:

1. **단일 LLM + RAG/도구로 풀리지 않는다는 증거**가 먼저 있는가? 없으면 거기서 멈춰라.
2. 작업이 워크플로우(코드 경로 고정)로 충분한가, 모델이 동적으로 결정해야 하는가?
3. 컨텍스트 폭발을 일으키는 부분 작업(검색, 로그 파싱)은 **컨텍스트 격리된 서브에이전트**로 빼라. 결과만 부모로 돌아오도록.
4. 멀티 에이전트는 **병렬 가능 + 가치 있는 작업** 한정. 코딩처럼 결정 간 의존성이 강하면 단일 에이전트 + 충분한 컨텍스트 공유가 우선.
5. 하네스는 **모델이 혼자 못 한다고 가정한 것의 인코딩**이다. 모델 업그레이드 후 정기적으로 스캐폴딩을 걷어내라.
6. 평가/관측을 처음부터 박아라 ([LangSmith](https://www.langchain.com/langsmith/evaluation), [Braintrust](https://www.braintrust.dev/), Langfuse 등). 멀티 에이전트는 트레이스 없이는 디버그가 불가능에 가깝다.

구체 패턴은 [patterns.md](./patterns.md), 출처는 [references.md](./references.md).
