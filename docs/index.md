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
| [patterns.md](./agent-memory-context/patterns.md) | 17개 패턴 (Auto-compaction, 벡터 DB 인출, 파일 기반 메모리, Context offloading, Self-RAG, CRAG, RAPTOR, RAG-Fusion 등) |
| [references.md](./agent-memory-context/references.md) | 19+ 핵심 자료 |

---

### [에이전트 평가 / 관측](./agent-evals-observability/overview.md)
LLM-as-judge, trajectory eval, OpenTelemetry GenAI / OpenInference 트레이스 표준, eval-driven CI 게이트, 멀티 에이전트 outcomes 채점.

| 파일 | 내용 |
|---|---|
| [overview.md](./agent-evals-observability/overview.md) | 어휘(trace/span/run/thread/grader/outcome), 3축 분류(누가×무엇을×언제), 도구 6개 비교, 트레이스 표준, 멀티 에이전트 특수성, EDDOps |
| [patterns.md](./agent-evals-observability/patterns.md) | 15개 패턴 (Trajectory match, LLM-as-judge bias mitigation, Outcomes-based grading, Generator/Evaluator 분리, OpenInference 트레이스, CI gate, Online guardrail, Annotation queue, Multi-turn eval, Insight clustering, Cost/latency, pass^k, Swiss Cheese, RAGAS) |
| [references.md](./agent-evals-observability/references.md) | 50+ 핵심 자료 (Anthropic Demystifying evals, RAGAS) |

---

### [하네스 엔지니어링 현장 보고](./harness-engineering/overview.md)
OpenAI Codex 팀·Anthropic의 agent-first 개발 실험 결과와 설계 원칙. 1M줄·1,500 PR·수동 코드 0 달성 방법론. 하네스 7요소(컨텍스트·도구·메모리·루프·가드레일·평가·오케스트레이션) 전 영역 패턴 카탈로그.

| 파일 | 내용 |
|---|---|
| [overview.md](./harness-engineering/overview.md) | Codex 팀 3원칙, Anthropic 두 실패 유형, 두 팀 비교 |
| [patterns.md](./harness-engineering/patterns.md) | 25개 패턴 (Map-first, 기계적 제약 강제, 기술 부채 자동 수거, Context=존재, 원샷 함정 회피, Generator-Evaluator 분리, 도구 description 인체공학, 도구 카탈로그 동적 로딩, MCP 설계, 도구 결과 오프로딩, 샌드박스 격리, egress 화이트리스트, 시크릿 redaction, Dual-LLM, CaMeL, Permission mode 그라디언트, Halting condition, 무한 루프 탐지, Self-critique 횟수 튜닝, JIT 컨텍스트 로딩, Compaction 트리거, 인라인 vs 외부 참조, 역할별 모델 라우팅, Prompt caching 운영, Batched evaluation) |
| [references.md](./harness-engineering/references.md) | 1차 출처 (OpenAI·Anthropic·Simon Willison·DeepMind 등) |

---

### [그래프 기반 RAG](./graph-rag/overview.md)
일반 vector RAG가 풀지 못하는 멀티홉 추론과 전역 요약 질의를 엔티티 그래프와 그래프 알고리즘으로 푸는 retrieval 패러다임.

| 파일 | 내용 |
|---|---|
| [overview.md](./graph-rag/overview.md) | 왜 그래프인가, vector RAG의 두 한계(멀티홉·global), 3개 기법 한 줄 비교 |
| [patterns.md](./graph-rag/patterns.md) | 3개 패턴 (GraphRAG, LightRAG, HippoRAG) |
| [references.md](./graph-rag/references.md) | 1차 자료(arXiv 논문 3편), 공식 구현, 비교·평가 |

---

## 차후 조사 목록

### 기존 주제 확장

#### `agent-memory-context` — Advanced RAG 검색 패턴 (남은 항목)

| 기술 | 한 줄 요약 | 우선순위 |
|---|---|---|
| **HyDE** | 가상의 답변 문서를 생성해 임베딩 공간 미스매치를 줄이는 쿼리 증강 | 중간 |
| **Modular RAG** | RAG 컴포넌트(인덱싱·검색·생성·피드백)를 독립 모듈로 조합하는 아키텍처 프레임워크 | 중간 |
| **FLARE** | 생성 중 불확실 구간에서 능동적으로 검색을 트리거하는 interleaved retrieval | 낮음 |

---

#### `harness-engineering` — 7요소 보강 (남은 항목)

| 묶음 | 한 줄 요약 | 우선순위 |
|---|---|---|
| **하네스 케이스 스터디** | Claude Code/Aider/Cursor/Devin/OpenHands/SWE-agent × 7요소 매트릭스 | 중간 |
