# 그래프 기반 RAG 패턴 카탈로그

## 1. GraphRAG (Microsoft)

### 무엇
LLM으로 사전에 엔티티·관계 그래프를 추출한 뒤, 그래프 위에서 **커뮤니티 탐지(Leiden 등)**를 돌려 계층적 클러스터를 만들고, 각 커뮤니티에 대해 LLM이 요약 보고서를 미리 생성해 두는 방식. 쿼리 시점에는 커뮤니티 요약들을 map-reduce 방식으로 합쳐 답한다. "전역 의미 파악(global sense-making)" 질의를 baseline RAG가 못 푸는 문제를 정면으로 겨냥한다.

### 언제
- 데이터셋 전체에 대한 **요약·테마·트렌드** 질의가 자주 들어올 때 ("주요 주제 5가지", "이 회사의 리스크 요약").
- 장편 서사·뉴스 코퍼스처럼 **여러 문서를 가로지르는 추론**이 필요한 사적 데이터(private corpus).
- 인덱싱 비용을 한 번에 지불할 여력이 있고, 코퍼스가 비교적 정적인 환경.

### 어떻게
**인덱싱 단계**:
1. 텍스트 chunk 단위로 LLM 호출 → 엔티티·관계·주장(claim) 추출.
2. 추출 결과를 합쳐 글로벌 그래프 구축, **계층적 커뮤니티 탐지**(Leiden 알고리즘) 적용.
3. 각 커뮤니티에 대해 LLM이 **community summary**를 사전 생성. 계층 별로 모두 만든다.

**쿼리 단계**:
- *Global search*: 모든 커뮤니티 요약에 대해 부분 답변을 병렬 생성 → 최종 LLM 호출로 종합.
- *Local search*: 질의에서 엔티티를 식별 → 인접 노드·관계·텍스트 단위·커뮤니티 요약을 컨텍스트로 묶어 답변.

### 트레이드오프
- **인덱싱 비용**: 매우 높음. 청크별 추출 + 계층별 community summary 생성으로 토큰 사용량이 크다(공식 README가 비용 경고). LightRAG 논문 비교 사례에서는 retrieval 한 번에 GraphRAG가 약 610k 토큰을 쓰는 측정값이 보고됨.
- **쿼리 비용**: Global search는 커뮤니티 수만큼 부분 답변 호출이 필요해 가장 비싸다. Local search는 상대적으로 저렴.
- **정확도**: Global·sense-making 질의에서 baseline RAG 대비 "포괄성·다양성에서 실질적 개선"(arXiv:2404.16130 평가).
- **증분 업데이트**: 약함. 새 문서가 들어오면 커뮤니티 구조 재계산이 필요하다는 한계가 LightRAG 논문에서 지적됨.

### 출처
- [From Local to Global: A Graph RAG Approach to Query-Focused Summarization (arxiv 2404.16130)](https://arxiv.org/abs/2404.16130) — Edge et al., Microsoft, 2024.
- [microsoft/graphrag](https://github.com/microsoft/graphrag) — 공식 구현·README 비용 경고.
- [GraphRAG: Unlocking LLM discovery on narrative private data](https://www.microsoft.com/en-us/research/blog/graphrag-unlocking-llm-discovery-on-narrative-private-data/) — Microsoft Research Blog 2024.

---

## 2. LightRAG

### 무엇
GraphRAG의 운영 비용·증분 업데이트 약점을 정조준한 그래프 RAG. 인덱싱은 GraphRAG와 비슷하게 LLM으로 엔티티·관계를 뽑아 그래프를 만들지만, **community summary 단계를 생략**하고, 검색 시 **dual-level(저수준/고수준) 키워드 추출**로 그래프를 두 층위에서 동시에 탐색한다. 그래프와 vector store를 함께 쓰는 하이브리드.

### 언제
- 코퍼스가 **자주 갱신**되는 환경(뉴스, 사내 문서, 법률 업데이트).
- GraphRAG의 정확도는 원하지만 **토큰 예산·지연 시간**이 빡빡할 때.
- 운영용 REST API·Web UI·Neo4j/PostgreSQL 등 백엔드 통합이 필요한 production RAG 서비스.

### 어떻게
**인덱싱 단계**:
1. 청크별 LLM 호출로 엔티티·관계 추출, 그래프와 vector index 동시 구축.
2. 새 문서 도입 시 영향받는 노드만 갱신하는 **증분 업데이트 알고리즘** 적용 — 전체 community 재구성 없이 수정 가능.

**쿼리 단계**:
1. 질의에서 LLM으로 **low-level 키워드**(구체 엔티티)와 **high-level 키워드**(상위 개념·주제)를 각각 추출.
2. low-level 키워드는 엔티티 노드·인접 관계를 가져오고, high-level은 관계·주제 묶음을 가져온다.
3. 두 결과를 합쳐 단일 LLM 호출로 답변 생성.

### 트레이드오프
- **인덱싱 비용**: GraphRAG보다 낮음(community summary 생성 없음).
- **쿼리 비용**: 논문 보고에 따르면 retrieval 한 번에 LightRAG는 100토큰 미만 + API 호출 1회로 가능, GraphRAG의 커뮤니티 수 × 평균 토큰에 비해 큰 차이.
- **정확도**: 4개 도메인(농업·CS·법률·혼합)에서 GraphRAG 대비 49.6–54.8% win rate(arXiv:2410.05779 평가 표).
- **약점**: GraphRAG의 명시적 계층 community 요약이 없어, 코퍼스 전체를 가로지르는 거시적 요약 질의에서는 그래프-only 방식만으로는 약할 수 있음(추측, 논문은 vector hybrid로 보완한다고 기술).

### 출처
- [LightRAG: Simple and Fast Retrieval-Augmented Generation (arxiv 2410.05779)](https://arxiv.org/abs/2410.05779) — Guo et al., HKU, 2024; EMNLP 2025.
- [HKUDS/LightRAG](https://github.com/HKUDS/LightRAG) — 공식 구현, dual-level retrieval 코드.

---

## 3. HippoRAG

### 무엇
인간 해마(hippocampus)의 인덱싱 이론에서 영감을 얻은 RAG. 신피질(neocortex) 역할은 LLM이, 해마의 패턴 분리·완성 역할은 **Personalized PageRank(PPR)**가 맡는다. 멀티홉 질의에 대해 IRCoT 같은 반복적 검색-추론 없이 **단일 스텝**으로 답을 끌어내는 것이 목표.

### 언제
- **멀티홉 QA**가 핵심 워크로드일 때(MuSiQue, 2WikiMultiHopQA, HotpotQA 류).
- 반복 검색(iterative retrieval) 비용을 줄이고 싶을 때 — 논문은 IRCoT 대비 10–30× 저렴, 6–13× 빠름을 보고.
- 엔티티 중심 코퍼스(인물·사건·조직 관계가 풍부한 위키·뉴스).

### 어떻게
**인덱싱 단계**:
1. 각 passage에 대해 **OpenIE**(LLM 기반)로 (엔티티, 관계, 엔티티) 트리플 추출.
2. 동일·유사 엔티티 노드를 임베딩 유사도로 잇는 **synonym edge** 추가 → 단일 KG 구축.
3. 노드(엔티티), 엣지(관계), passage 사이 매핑 인덱스 보존.

**쿼리 단계**:
1. 질의에서 LLM으로 **named entity** 추출 → KG 노드와 매칭(seed node).
2. seed에서 **Personalized PageRank** 실행 → 관련 노드 점수 분포 산출.
3. 노드 점수를 매핑된 passage 점수로 환산해 top-k passage를 한 번에 회수, 단일 LLM 호출로 답변.

### 트레이드오프
- **인덱싱 비용**: GraphRAG·RAPTOR·LightRAG 대비 낮음(community summary 없이 OpenIE만)이라고 OSU-NLP-Group/HippoRAG README가 명시.
- **쿼리 비용**: PPR은 결정론적·CPU 연산이라 LLM 호출이 1~2회로 끝나 매우 저렴.
- **정확도**: 멀티홉 QA에서 기존 RAG 대비 최대 +20%; IRCoT와 결합 시 추가 개선(arXiv:2405.14831 §4).
- **약점**: 엔티티 추출 품질에 강하게 의존. 엔티티 중심이 아닌 서사·요약 질의(global sense-making)에서는 GraphRAG보다 약할 가능성(추측, 논문은 factual recall·associativity에 집중).

### 출처
- [HippoRAG: Neurobiologically Inspired Long-Term Memory for Large Language Models (arxiv 2405.14831)](https://arxiv.org/abs/2405.14831) — Gutiérrez et al., OSU NLP, NeurIPS 2024.
- [OSU-NLP-Group/HippoRAG](https://github.com/OSU-NLP-Group/HippoRAG) — 공식 구현, 벤치마크 스크립트.
