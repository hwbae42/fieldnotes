# 에이전트 메모리 / 컨텍스트 관리 — 패턴

각 패턴은 다음 형식으로 정리한다.
- **무엇** — 한 줄 정의
- **언제** — 어떤 상황에 적용
- **어떻게** — 구체 구현
- **트레이드오프** — 이 패턴이 비싸지는/실패하는 지점
- **출처** — 검증된 사례

---

## 1. Auto-compaction (자동 요약 압축)

**무엇.** 컨텍스트가 한계에 가까워지면 과거 대화를 요약문으로 *대체*해 자리를 비워주는 기법.

**언제.**
- 한 세션이 수십 턴 이상으로 길어질 때.
- 도구 호출 결과(긴 grep 결과, 파일 내용)가 누적되어 윈도우의 50%+ 를 차지할 때.
- 명시적인 메모리 시스템을 도입하기 전 가장 싸게 얻을 수 있는 효과.

**어떻게.**
- Claude Code: 컨텍스트가 약 83.5%가 차면 자동으로 `/compact`가 발동. 사용자가 직접 `/compact "주제"`로 무엇을 보존할지 지정 가능.
- Anthropic API: `context-management-2025-06-27` 베타 헤더로 **context editing**을 켜면, stale tool_use/tool_result 블록을 자동으로 잘라낸다 — 메시지 흐름은 유지하되 결과 페이로드만 비움. Anthropic 발표 기준 100턴 웹서치 평가에서 토큰 84% 감소, 정확도 29% 향상.
- 직접 구현 시: 임계치(예: 80%)에 도달하면 (a) 첫 N턴 + 시스템 프롬프트는 보존, (b) 가운데 구간을 LLM에 한 번 더 보내 요약, (c) 요약문으로 가운데를 대체.

**트레이드오프.**
- **결정의 이유는 거의 항상 사라진다.** Claude Code 가이드도 명시한다 — 압축은 "할 일과 최근 출력"은 보존하지만 "왜 그 결정을 했는지"는 잃는다. 그래서 *이유*가 보존돼야 한다면 CLAUDE.md / MEMORY.md / 메모리 도구로 따로 적어야 한다.
- 재요약 비용은 대화 길이에 선형 — 길어질수록 매 턴 풀 prefix를 다시 요약하면 비용/지연이 누적된다.
- 압축 모델이 task를 *paraphrase* 해버리는 사례 (Cognition Devin) — 핵심 디테일이 빠진 채 "비슷한 말"만 남는다.

**출처.**
- Anthropic, "Managing context on the Claude Developer Platform" (2025).
- Cognition, "Rebuilding Devin for Claude Sonnet 4.5" (2025) — 직접 fine-tuned 압축 모델을 쓴 사례.
- Claude Code 공식 docs (`/compact`, context-window).

---

## 2. Hierarchical summarization (계층 요약)

**무엇.** 메시지 → 섹션 요약 → 전체 요약처럼 계층적으로 압축하고, 인출 시 적절한 레벨을 선택하는 기법.

**언제.**
- 수십 회 세션을 가로지르는 장기 대화 (LOCOMO 같은 35세션 시나리오).
- 코드베이스 전체 같은 수십만 토큰 코퍼스를 다룰 때.

**어떻게.**
- L0: 원본 메시지 (혹은 raw chunk).
- L1: 세션 단위 요약 (200~500토큰).
- L2: 일/주 단위 메타 요약.
- 인출 시 — 최근은 L0, 1주 전은 L1, 한 달 전은 L2를 가져와 컨텍스트에 합친다.
- Letta는 이 패턴을 "recursive summarization"으로 부르며, eviction 시 약 70%를 요약으로 대체한다.

**트레이드오프.**
- **세 번째 패스에서 중요한 디테일이 증발한다.** 자주 쓰이지 않는 희귀한 사실은 첫 압축은 살아남아도 L2까지 가면 사라지는 경향. Mem0 가이드도 같은 문제 지적.
- 매번 풀 prefix를 다시 요약하지 않게 *증분* 설계가 필요 (이미 요약된 구간은 보존하고 새로운 구간만 합산).

**출처.**
- "Memory for Autonomous LLM Agents" 서베이 (arxiv 2603.07670v1) — failure modes 정리.
- Letta 블로그, "Agent Memory" — recursive summarization 구현.
- Mem0, "LLM Chat History Summarization" 가이드 (2025).

---

## 3. Scratchpad / Working memory file

**무엇.** 한 태스크를 수행하는 동안 에이전트가 자기 생각·계획·중간 결과를 *외부 파일* 또는 *상태 객체*에 적어두는 기법.

**언제.**
- 다단계 추론 (planning, multi-step reasoning).
- 컨텍스트 한계 근처에서 중요한 발견을 잃지 않으려 할 때.
- 서브에이전트에 작업을 넘기기 전 lead agent가 plan을 보존해야 할 때.

**어떻게.**
- LangGraph: state 객체의 한 필드(`scratchpad: str`)로 정의. 매 턴 update.
- Anthropic 멀티 에이전트 리서치 시스템: lead agent가 200K 한계가 가까워지면 plan을 외부 메모리에 저장 — 그 뒤 컨텍스트가 truncate돼도 plan은 살아남는다.
- 도구 형태: `write_scratchpad(content)` / `read_scratchpad()` 또는 단순히 `Write(/tmp/plan.md)`.

**트레이드오프.**
- 너무 자주 쓰면 자기 자신의 노이즈가 됨 — 매 턴 scratchpad를 갱신하고 다시 읽으면 컨텍스트가 도리어 부풀어 오른다.
- 어떤 LLM은 자기 노트를 *너무 신뢰* 해 (Cognition 보고) 부정확한 paraphrase를 사실로 굳혀버린다.

**출처.**
- LangChain, "Context Engineering for Agents" (Lance Martin).
- Anthropic, "How we built our multi-agent research system" (2025).

---

## 4. 외부 파일 기반 메모리 (Claude Code MEMORY.md / Memory tool 패턴)

**무엇.** 프로젝트 또는 워킹트리 단위로 마크다운 파일 디렉토리를 두고, 에이전트가 거기 CRUD 하도록 하는 단순하지만 강력한 패턴.

**언제.**
- 코딩 에이전트, 사람과 함께 검토·편집할 노트를 다룰 때.
- 시맨틱 검색이 *필수*가 아닐 때 (수백~수천 항목 규모).
- 감사·재현이 중요한 환경.

**어떻게.**
- **Claude Code의 두 층**:
  - `CLAUDE.md` (사람이 쓴 규칙) — 매 세션 풀로 로딩. 200줄 미만 권장. `./CLAUDE.md`, `~/.claude/CLAUDE.md`, `./CLAUDE.local.md`로 스코프 분리. `/compact` 후에도 자동 재주입.
  - `~/.claude/projects/<project>/memory/MEMORY.md` (Claude가 쓴 자동 메모리) — 첫 200줄 또는 25KB까지만 매 세션 자동 로딩. 나머지 토픽 파일은 on-demand로 Read.
- **Anthropic Memory tool (API)**: `tools=[{type:"memory_20250818", name:"memory"}]`. 에이전트가 `view`/`create`/`str_replace`/`insert`/`delete`/`rename` 명령을 호출하면 클라이언트가 `/memories` 디렉토리에서 실행. 시스템 프롬프트에 자동 삽입되는 가이드 — *"항상 작업 시작 전에 /memories를 확인하라. 컨텍스트가 언제든 리셋될 수 있다고 가정하라."*

**트레이드오프.**
- 시맨틱 검색이 안 되니 파일 분할·인덱싱(MEMORY.md를 인덱스로)이 직접 설계해야 함.
- 파일 수가 폭증하면 LLM이 잘못된 파일을 만들거나 같은 정보를 여러 군데 적는 *sprawl*이 발생. 가이드: "꼭 필요한 경우가 아니면 새 파일을 만들지 말라"를 명시 프롬프트에 포함.
- 보안: path traversal 위험 — `/memories` 외부 접근을 클라이언트에서 막아야 (Anthropic 공식 가이드의 명시적 경고).

**출처.**
- Claude Code 공식 docs, "How Claude remembers your project" — `CLAUDE.md`, auto memory, `MEMORY.md` 인덱스 패턴.
- Anthropic, Memory tool API docs (`memory_20250818`).
- orchestrator.dev, "Claude Code Agent Memory: 2026 Best Practices."

---

## 5. Vector DB로 시맨틱 인출

**무엇.** 메모리 항목을 임베딩으로 색인하고, 쿼리도 임베딩으로 변환해 cosine similarity 상위 K개를 가져오는 기법.

**언제.**
- 메모리 항목이 수만~수백만 단위일 때.
- 자유 텍스트(대화, 문서)에서의 fuzzy 매칭.
- 정형화된 ontology를 미리 짜기 어려울 때.

**어떻게.**
- 대화에서 "원자 사실"을 LLM 한 번 더 호출해 추출 → 임베딩 → 메타데이터(유저 ID, 타임스탬프, 카테고리)와 함께 저장.
- 쿼리 시: 현재 사용자 입력을 임베딩 → top-K(보통 5~10) → 메타데이터로 필터링(같은 유저, 최근 30일 등) → 컨텍스트에 합침.
- 백엔드: Mem0는 Qdrant/Chroma/Weaviate/pgvector/Pinecone 등 19개 백엔드를 지원. 작은 프로젝트는 pgvector(이미 PostgreSQL 있으면)면 충분.

**트레이드오프.**
- **얕은 매칭** — "I love TypeScript"와 "I switched from Python to TypeScript"는 임베딩이 비슷해 둘 다 인출되는데, 의미는 다르다. 충돌 해소는 별도 로직 필요.
- **시간 약함** — "현재 사용자는 어떤 언어를 쓰는가?"에 RAG는 옛날 사실까지 같이 떠올린다.
- **다중 홉 안 됨** — "X의 매니저의 동료" 같은 관계 질의는 본질적으로 못 함.

**출처.**
- Mem0, "State of AI Agent Memory 2026" — 19개 vector backend 목록과 LOCOMO 결과.
- Atlan, "Vector DB vs Knowledge Graph for Agent Memory" — 명시적 비교 테이블.

---

## 6. Knowledge graph 메모리 (관계와 시간 보존)

**무엇.** 메모리를 entity-relation triple로 저장. 시간 유효성(`valid_from`, `valid_to`)을 함께 기록.

**언제.**
- 관계 추론이 답에 핵심일 때 (의료 계층, 시스템 의존성, 가족·조직 관계).
- 사실이 시간에 따라 *변하는* 환경 — "사용자의 회사는?"이 작년과 다를 수 있을 때.
- 감사·설명 가능성이 요구될 때.

**어떻게.**
- Graphiti (Zep 오픈소스): 새 사실이 들어오면 (a) 시맨틱+키워드+그래프 검색으로 충돌 후보를 찾고, (b) 기존 사실의 `valid_to`를 갱신해 *invalidate* 하되 삭제하지 않음 — 과거 시점 질의를 위해 보존.
- Mem0g: vector를 entry-point로 쓰고 그 노드에서 그래프 traversal. 하이브리드.
- Neo4j 또는 Kuzu(임베디드)를 백엔드로.
- 추출 단계: LLM 호출로 대화에서 (subject, predicate, object, timestamp) 추출. 비용 부담.

**트레이드오프.**
- 콜드스타트 비용 — 온톨로지 설계, 추출 프롬프트 튜닝.
- 추출 LLM 비용이 매 턴 추가됨 (Mem0는 이걸 background async로 빼서 hot path에서 제거).
- 작은 프로젝트(개인 비서, 코딩 에이전트)에는 과한 경우가 많다.

**출처.**
- Zep, "A Temporal Knowledge Graph Architecture for Agent Memory" (arxiv 2501.13956). DMR 벤치 94.8% (vs MemGPT 93.4%).
- Graphiti GitHub / Neo4j 블로그.
- Mem0 graph memory 가이드 — vector + graph 하이브리드 우위.

---

## 7. 메모리 쓰기 게이트 (Write decision)

**무엇.** *모든* 대화를 저장하면 노이즈가 쌓인다. LLM이 "이건 저장 가치가 있는가"를 판단하게 만드는 패턴.

**언제.**
- 메모리 시스템을 처음 도입할 때 가장 자주 빠뜨리는 단계.
- 사용자별 preference, 결정, 정정(correction) 같은 durable한 사실만 남기고 싶을 때.

**어떻게.**
- Mem0의 write 파이프라인:
  1. **Extract** — 대화에서 atomic fact 후보를 LLM이 뽑아냄 ("user prefers Python", "user's timezone is CET").
  2. **Verify** — 각 후보에 대해 8가지 체크 (entity, object, location, temporal, organizational, completeness, relational, supported by source). 불통과는 drop.
  3. **Classify** — Fact / Event / Instruction / Task로 분류. Task는 ephemeral (자동 만료).
- LangChain의 패턴 분류:
  - Hot path (응답 전 동기 갱신) — 즉시 사용 가능, 지연 ↑.
  - Background (대화 후 비동기) — 지연 0, 다음 세션부터 사용 가능. Mem0 v1.0부터 기본.

**트레이드오프.**
- Hot path는 매 턴마다 추가 LLM 호출 → 응답 지연 +1~3초.
- Background는 사용자가 "내가 방금 X라고 말했지" 라고 다음 턴에 말해도 못 알아듣는다.
- Verify 단계는 비싸고 false negative(중요 사실을 drop)가 종종 발생.

**출처.**
- Mem0, "AI Memory Management for LLMs and Agents" — 8-check verifier.
- LangChain, "Memory for agents" — hot path vs background 트레이드오프 표.

---

## 8. 인출 시 관련성 + 최신성 + 사용 빈도 가중치

**무엇.** 메모리 검색은 단순 cosine similarity가 아니라 *score = relevance × recency × usage* 같은 합성 점수로.

**언제.**
- 시간이 지나면 가치가 떨어지는 정보 (예: "오늘 방콕에 있다" vs "Python을 좋아한다").
- 자주 인출되는 메모리가 더 강해지고, 안 쓰이면 약해지길 원할 때 (인간 기억의 spacing effect 모방).

**어떻게.**
- 점수 = `α * cosine + β * exp(-Δt / τ) + γ * usage_count`. τ는 항목 카테고리에 따라 다르게 (Fact: 길게, Task: 짧게).
- Generative Agents (Stanford, 2023) 논문이 원조 — recency, importance, relevance의 가중합.
- FadeMem 류 — 메모리를 long-term layer (천천히 decay) / short-term layer (빠르게 decay)로 이중화.

**트레이드오프.**
- 가중치(α, β, γ) 튜닝은 도메인 의존적 — 평가 셋이 없으면 손으로 정하게 됨.
- "최신 사실이 무조건 옳다"는 가정이 깨지는 경우 (사용자가 농담했거나, 일시적 상태였을 때).

**출처.**
- "Generative Agents: Interactive Simulacra of Human Behavior" — recency × importance × relevance.
- arxiv "When to Forget" (2604.12007), FadeMem (2512.12856) — 디케이 함수 설계.

---

## 9. Context offloading (도구 결과를 파일로 저장하고 경로만 주입)

**무엇.** 큰 도구 결과(파일 내용, API 응답, 이미지)를 컨텍스트에 *값으로* 넣지 않고, 외부에 저장한 뒤 경로/ID만 컨텍스트에 둠.

**언제.**
- 도구 결과가 1K+ 토큰을 넘기는 경우 (코드베이스 grep, 큰 JSON 응답).
- 한 도구 결과를 여러 후속 단계가 참조할 가능성이 적을 때.
- 멀티모달 (이미지, 오디오) — Hugging Face CodeAgent가 sandbox에 두는 패턴.

**어떻게.**
- 도구 호출 결과를 `/tmp/results/{hash}.json` 같은 경로에 저장.
- 컨텍스트에는 `"saved 4.3MB JSON to /tmp/results/abc123.json (314 fields, top-level keys: users, orders, ...)"` 같은 메타데이터만.
- 후속 단계가 필요하면 `read_file(path)` 또는 `jq_query(path, expr)` 같은 도구로 *조각만* 가져옴.

**트레이드오프.**
- 모든 도구 호출이 한 번 이상의 라운드트립을 더 요구하게 됨 → 지연 ↑.
- 에이전트가 경로를 잊거나 잘못된 경로로 호출하면 silent failure.
- 작은 결과까지 offload하면 오버헤드만 늘어남 — heuristic threshold 필요 (예: 500 토큰 초과시).

**출처.**
- LangChain, "Context Engineering" — sandbox / state schema 절.
- Anthropic 멀티 에이전트 리서치 시스템 — 서브에이전트가 결과를 외부 시스템에 저장하고 lightweight reference만 lead에게 반환.

---

## 10. 서브에이전트로 컨텍스트 격리

**무엇.** 한 작업을 별도 컨텍스트 윈도우에서 돌리고, 부모는 *요약된 결과*만 받는 패턴. 부모 컨텍스트의 오염을 막는다.

**언제.**
- 탐색 단계가 길고 (수십 개 파일 읽기) 그 중 결론만 필요할 때.
- 병렬 처리가 가능한 독립 서브태스크.
- 한 작업이 token-heavy 객체(이미지, 큰 JSON)를 다룰 때.

**어떻게.**
- Claude Code: `/agents`로 named subagent 정의. `description`, `tools`, `memory: project|user|local` 프론트매터로 메모리 스코프 지정. 부모는 description으로 위임 결정.
- Anthropic 멀티 에이전트 리서치: lead(Opus 4) + 병렬 worker(Sonnet 4)들. lead가 plan을 외부 메모리에 저장 후 worker에게 격리된 윈도우로 위임. worker는 발견한 핵심만 반환.
- LangGraph: 하위 그래프(subgraph) 패턴, 별도 state로 격리.

**트레이드오프.**
- **15× 토큰 비용** — Anthropic 보고에 따르면 멀티 에이전트는 단일 챗 대비 약 15배 토큰. 가치가 비용보다 높을 때만 정당화됨.
- **서브에이전트끼리 학습 공유 안 됨** — Hindsight 보고: 서브에이전트들이 각자 같은 탐색을 반복함. 해결책으로 공유 메모리 레이어를 별도로 둬야.
- 부모가 mid-execution으로 서브에이전트를 *조정* 못함 — 동기 봉쇄 구조 (Anthropic 본인 한계로 인정).

**출처.**
- Anthropic, "How we built our multi-agent research system" (2025) — 90.2% 향상, 15× 토큰.
- Claude Code, "Subagents" docs.
- Hindsight blog (2026.05) — 서브에이전트 메모리 공유 한계.

---

## 11. RAG + 에이전트 메모리 결합

**무엇.** 정적 사실(문서)은 RAG로, 동적 사실(사용자 상태, 결정, 일화)은 메모리 시스템으로 분리하고 둘 다 컨텍스트에 합치는 패턴.

**언제.**
- 도메인 지식(매뉴얼, 정책 문서)과 사용자별 상태가 *둘 다* 필요한 시스템.
- 거의 모든 프로덕션 챗봇/어시스턴트.

**어떻게.**
- Layer 1 — Semantic memory (RAG): 회사 매뉴얼, FAQ를 vector DB에. 매 쿼리마다 top-K 인출.
- Layer 2 — Episodic + procedural memory: 사용자별 사실을 별도 store에. user_id로 필터링해 인출.
- 컨텍스트 조립: `system + user_profile_facts + retrieved_docs + recent_episodes + current_user_input`.
- LeonieMonigatti의 "From RAG to Agent Memory" 글이 이 분리를 명확히 — 두 시스템을 하나로 합치려 하지 말고 두 collection으로 나눠라.

**트레이드오프.**
- 두 시스템 운영 — 인덱싱 파이프라인, 모니터링, 백업이 두 배.
- 인출 결과가 서로 모순될 수 있음 (문서는 "기본값은 X", 메모리는 "사용자가 Y로 바꿈"). 메모리에 우선순위를 줘야.

**출처.**
- Leonie Monigatti, "The Evolution from RAG to Agent Memory."
- IBM, "What Is AI Agent Memory" — RAG/memory 분리 권장.

---

## 12. 메모리 디케이 / 만료 정책

**무엇.** 모든 메모리는 영원하지 않다. 카테고리별로 만료/디케이 규칙을 정해 자동 정리.

**언제.**
- 메모리 저장소가 몇 달째 운영되며 양이 늘어날 때.
- 오래된 사실이 *틀린* 사실로 굳어지는 staleness 문제.
- 규제(GDPR right to be forgotten 등) 대응.

**어떻게.**
- 분류별 TTL — Task: 24h, Event: 30d, Fact: ∞(단 사용 빈도로 약화), Instruction: ∞.
- 명시적 expiration tag — 메모리를 만들 때 LLM이 "이 사실의 자연 수명"을 추정해 tag.
- LRU eviction — 마지막 access 시각 기준 가장 오래된 것부터 제거.
- Soft expire (Graphiti 방식) — 삭제 대신 `valid_to` 갱신. 과거 시점 질의를 위해 보존.

**트레이드오프.**
- 너무 짧으면 사용자가 "내가 말했잖아" 라고 화남.
- 너무 길면 staleness 누적.
- "사용자가 더 이상 ~이 아니다"라는 negation은 자동 추출이 어렵다 — 명시적 reflection 단계 필요.

**출처.**
- arxiv "When to Forget: A Memory Governance Primitive" (2604.12007).
- Graphiti — temporal validity 모델.
- Anthropic Memory tool docs — "memory expiration" 권장 (구현은 클라이언트 책임).

---

## 13. 메모리 충돌 해소 (새 사실 vs 기존 사실)

**무엇.** "사용자는 Python 좋아함" + "사용자는 TS로 이사" 가 동시에 있을 때 어느 쪽이 맞는지 결정.

**언제.**
- 사용자 상태/선호가 시간에 따라 변하는 시스템.
- 사실 추출이 잦은 환경 (대부분의 메모리 시스템).

**어떻게.**
- **시간 우선** (Graphiti) — 새 사실이 들어오면 충돌하는 기존 사실의 `valid_to`를 *지금*으로 갱신. 두 사실 모두 보존하되 "현재 유효한" 것은 새 쪽.
- **LLM 중재** (Mem0 manage 단계) — manage 시 LLM이 "ADD / UPDATE / DELETE / KEEP" 결정. Mem0 v1.0의 핵심.
- **Confidence 기반** — 사실마다 신뢰도 점수, 새 사실이 더 강하면 덮어쓰기.

**트레이드오프.**
- LLM 중재는 비싸고(추가 호출) 일관적이지 않다.
- 시간 우선은 단순하지만 농담/일시적 발언을 영구 사실로 굳혀버림.
- Confidence는 점수 산출 자체가 별도 모델 학습 부담.

**출처.**
- Zep / Graphiti — temporal invalidation 패턴.
- Mem0, "AI Memory Management" — write→manage→read 루프의 manage 단계 분석.
- "From Experience to Strategy" (arxiv 2511.07800) — 메모리 그래프 학습 가능성.

---

## 패턴 조합 — 실전 레시피 3가지

### A. 코딩 에이전트 (개인/팀)
1. CLAUDE.md (사람이 쓰는 규칙) — 패턴 4.
2. Auto memory MEMORY.md (Claude가 쓰는 학습) — 패턴 4.
3. `/compact` 자동 + 사용자 호출 — 패턴 1.
4. Heavy 탐색은 named subagent에 위임 — 패턴 10.
5. 큰 grep / file read 결과는 재요약하지 말고 다시 grep — 패턴 9의 변형.

### B. 사용자 별 어시스턴트 (장기 메모리 필요)
1. Mem0/Letta/Zep 중 택 1 — 도메인 관계 깊이 따라 vector vs hybrid 결정.
2. Background extraction (응답 지연 0) — 패턴 7.
3. 인출 시 recency + relevance 합성 점수 — 패턴 8.
4. 카테고리별 TTL — 패턴 12.
5. RAG (도메인 매뉴얼) + memory (사용자 상태) 분리 — 패턴 11.

### C. 멀티 에이전트 리서치 시스템
1. Lead-worker 패턴 — 패턴 10.
2. Lead의 plan을 외부 메모리에 저장 (200K 한계 대비) — 패턴 3.
3. Worker 결과를 외부 저장소에 두고 reference만 반환 — 패턴 9.
4. 공유 메모리 레이어로 worker간 학습 공유 — 패턴 10의 약점 보완.
5. Auto-compaction (server-side) + memory tool 결합 — 패턴 1 + 4.

---

## 평가: 메모리 시스템을 어떻게 측정하나

이 부분은 솔직히 *아직 안 풀린 영역* 이다. 몇 가지만 정리.

- **LOCOMO** (Snap Research, 2024–2025) — 35세션, 평균 9K 토큰의 합성 대화. 5가지 reasoning(single-hop, multi-hop, temporal, commonsense, adversarial). 산업 표준에 가깝지만, *합성* 데이터라 실제 사용자 패턴과 거리가 있음. Mem0의 발표 점수 비교는 거의 다 LOCOMO 기준.
- **DMR (Deep Memory Retrieval)** — Zep/MemGPT 비교에서 사용. 깊은 인출 능력 단일 점수.
- **Application-level 평가의 부재** — Mem0 자신이 "State of AI Agent Memory 2026"에서 솔직히 인정 — LOCOMO 66%가 코딩 에이전트엔 충분해도 의료 어시스턴트엔 위험할 수 있다.

**실용 제안.** 자기 도메인의 50~100개 trace를 수기 라벨링해 두고, 메모리 변경 시 회귀 평가. LangSmith/Braintrust 같은 평가 인프라를 도구로 쓰되, *벤치마크 점수에 끌려가지 말 것* — 자기 문제에 맞는 평가가 항상 우선.

---

## 정리 — 가져다 쓸 때의 원칙

1. **가장 단순한 것부터.** 코딩 에이전트라면 CLAUDE.md + auto memory만으로 80% 해결.
2. **세션 안 ≠ 세션 가로질러.** 둘은 다른 문제다. 한 세션 압축은 auto-compaction, 가로지르기는 메모리 시스템.
3. **이유는 따로 적어라.** 압축은 결정의 *이유*를 거의 항상 잃는다.
4. **Hot path는 마지막에.** 비동기 추출이 거의 항상 첫 선택.
5. **충돌·만료는 처음부터 설계.** 6개월 뒤에 retrofitting 하면 너무 비싸다.
