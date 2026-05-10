# fieldnotes — 문서 인덱스

> 마지막 업데이트: 2026-05-10

## 완료된 주제

### [에이전트 오케스트레이션 / 하네스](./agent-orchestration/overview.md)
멀티 에이전트 시스템 설계, 오케스트레이터-서브에이전트 아키텍처, 하네스 비교.

| 파일 | 내용 |
|---|---|
| [overview.md](./agent-orchestration/overview.md) | 하네스 정의, 단일 vs 멀티 에이전트 트레이드오프, 프레임워크 비교 매트릭스 |
| [patterns.md](./agent-orchestration/patterns.md) | 11개 패턴 (Orchestrator-Worker, Supervisor, Swarm, Routing, Plan-and-Execute 등) |
| [references.md](./agent-orchestration/references.md) | 25+ 핵심 자료 |

---

### [코딩 에이전트 친화적인 코드베이스](./agent-friendly-codebase/overview.md)
AGENTS.md / CLAUDE.md 설계, 도구 권한 관리, 훅 자동화, 서브에이전트 구성.

| 파일 | 내용 |
|---|---|
| [overview.md](./agent-friendly-codebase/overview.md) | 왜 에이전트 친화성이 필요한가, 메커니즘 지도, AGENTS.md 표준 등장 배경 |
| [patterns.md](./agent-friendly-codebase/patterns.md) | 14개 패턴 (Permissions allowlist, Hooks, Skills, Subagent 격리, MCP 통합 등) |
| [references.md](./agent-friendly-codebase/references.md) | 25+ 핵심 자료 |

---

### [에이전트 메모리 / 컨텍스트 관리](./agent-memory-context/overview.md)
Context engineering, 장기 메모리 전략, 압축 기법, RAG 연동, 세션 간 상태 지속.

| 파일 | 내용 |
|---|---|
| [overview.md](./agent-memory-context/overview.md) | Context engineering 정의, 메모리 분류, 백엔드 비교, RAG와의 차이 |
| [patterns.md](./agent-memory-context/patterns.md) | 13개 패턴 (Auto-compaction, 벡터 DB 인출, 파일 기반 메모리, Context offloading 등) |
| [references.md](./agent-memory-context/references.md) | 19개 핵심 자료 |

---

### [에이전트 평가 / 관측](./agent-evals-observability/overview.md)
LLM-as-judge, trajectory eval, OpenTelemetry GenAI / OpenInference 트레이스 표준, eval-driven CI 게이트, 멀티 에이전트 outcomes 채점.

| 파일 | 내용 |
|---|---|
| [overview.md](./agent-evals-observability/overview.md) | 어휘(trace/span/run/thread/grader/outcome), 3축 분류(누가×무엇을×언제), 도구 6개 비교, 트레이스 표준, 멀티 에이전트 특수성, EDDOps |
| [patterns.md](./agent-evals-observability/patterns.md) | 14개 패턴 (Trajectory match, LLM-as-judge bias mitigation, Outcomes-based grading, Generator/Evaluator 분리, OpenInference 트레이스, CI gate, Online guardrail, Annotation queue, Multi-turn eval, Insight clustering, Cost/latency, pass^k, Swiss Cheese 등) |
| [references.md](./agent-evals-observability/references.md) | 50+ 핵심 자료 (Anthropic Demystifying evals 외) |

---

## 차후 조사 목록

(현재 등록된 항목 없음 — 위 4개 주제로 일단락. 새 후보가 생기면 여기 추가.)
