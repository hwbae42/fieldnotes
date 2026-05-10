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

### 기존 주제 확장

#### `agent-memory-context` — Advanced RAG 검색 패턴 추가
현재 docs는 RAG를 메모리 백엔드로 다루지만, 검색 품질을 높이는 기법들은 미수록. 아래를 패턴으로 추가 검토.

| 기술 | 한 줄 요약 | 우선순위 |
|---|---|---|
| **Self-RAG** | 에이전트가 검색 필요 여부를 스스로 판단·비판하는 adaptive retrieval | 높음 |
| **CRAG (Corrective RAG)** | 검색 결과 품질을 평가하고 부족하면 web 검색으로 보완하는 교정 루프 | 높음 |
| **RAPTOR** | 재귀적 요약으로 계층 트리 인덱스를 구성하는 long-doc 검색 기법 | 높음 |
| **RAG-Fusion** | 멀티 쿼리 생성 + RRF 재랭킹으로 검색 강건성 향상 | 높음 |
| **HyDE** | 가상의 답변 문서를 생성해 임베딩 공간 미스매치를 줄이는 쿼리 증강 | 중간 |
| **FLARE** | 생성 중 불확실 구간에서 능동적으로 검색을 트리거하는 interleaved retrieval | 낮음 |
| **Modular RAG** | RAG 컴포넌트(인덱싱·검색·생성·피드백)를 독립 모듈로 조합하는 아키텍처 프레임워크 | 중간 |

#### `agent-evals-observability` — RAG 전용 평가 프레임워크 추가

| 기술 | 한 줄 요약 | 우선순위 |
|---|---|---|
| **RAGAS** | Faithfulness / Answer Relevancy / Context Precision 등 RAG 특화 지표 자동 측정 프레임워크 | 높음 |

---

### 신규 주제 후보

#### 그래프 기반 RAG / 지식 그래프 메모리
GraphRAG·LightRAG·HippoRAG를 묶어 "관계 중심 검색 아키텍처"로 정리. 현재 overview에 GraphRAG가 표 한 줄로만 등장하며 내용 없음.

| 기술 | 한 줄 요약 | 우선순위 |
|---|---|---|
| **GraphRAG** (Microsoft) | 엔티티 그래프 + community summary로 global/local 쿼리 지원 | 높음 |
| **LightRAG** | 경량 그래프 + dual-level 검색(저수준 엔티티·고수준 토픽)으로 GraphRAG 비용 절감 | 높음 |
| **HippoRAG** | 해마 기억 구조에서 착안한 KG 기반 RAG — episodic vs semantic 기억 분리 | 중간 |
