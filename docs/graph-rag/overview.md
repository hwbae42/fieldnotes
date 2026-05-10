# 그래프 기반 RAG

> 한 줄 요약: 일반 vector RAG가 풀지 못하는 멀티홉 추론과 전역(global) 요약 질의를, 엔티티 그래프와 그래프 알고리즘을 통해 푸는 retrieval 패러다임.

## 왜 지금 이 주제인가

Microsoft Research가 2024년 4월 GraphRAG 논문(arXiv:2404.16130)과 7월 오픈소스 릴리스를 공개한 이후, 그래프 기반 RAG는 빠르게 별도 카테고리로 자리잡았다. 동일 시기에 OSU-NLP의 HippoRAG가 NeurIPS 2024에 채택되었고, HKU 그룹의 LightRAG(arXiv:2410.05779)가 EMNLP 2025에 게재되며 비용·증분 업데이트 측면을 다듬었다. 셋 모두 "엔티티 그래프 + 그래프 탐색"이라는 공통 골격을 공유한다.

기본 vector RAG는 두 가지 한계가 분명하다. 첫째, **멀티홉 질의**(여러 문서·엔티티에 흩어진 사실을 잇는 답변)에서 임베딩 유사도만으로는 연결고리를 찾기 어렵다. Microsoft 공식 블로그는 baseline RAG가 "관련 정보를 잇지 못한다(struggles to connect the dots)"고 명시했다. 둘째, **전역 요약 질의**("이 데이터셋의 핵심 주제 5가지는?")에서 top-k chunk 검색은 부분만 보여줄 뿐이다. 그래프는 엔티티·관계를 명시적 구조로 만들어 두 문제를 동시에 공략한다.

다만 공짜는 아니다. 인덱싱 단계에서 LLM으로 엔티티·관계·커뮤니티 요약을 추출해야 하고, GraphRAG 공식 README는 "indexing은 비싼 작업이니 작게 시작하라"고 명시한다. 비용·정확도·증분 업데이트의 트레이드오프를 이해해야 도입 결정을 내릴 수 있다.

## 이 주제가 다루는 것 / 다루지 않는 것

**다루는 것**: GraphRAG, LightRAG, HippoRAG 세 가지 그래프 기반 RAG 기법. LLM으로 비정형 텍스트에서 엔티티 그래프를 만들고, 그래프 구조(커뮤니티 요약, dual-level retrieval, Personalized PageRank)로 검색하는 retrieval 측면.

**다루지 않는 것**: 일반적인 KG embedding(TransE, RotatE 등 학습형 임베딩), 그래프 DB 운영(Neo4j 클러스터링·인덱싱), 메모리로서의 KG(이미 [agent-memory-context/patterns.md](../agent-memory-context/patterns.md) 6번 "Knowledge graph 메모리"에서 다룸).

## 한 줄로 보는 3가지 기법

| 기법 | 핵심 아이디어 | 강점 |
|---|---|---|
| GraphRAG | 엔티티 그래프 + 계층적 community summary | global query / sense-making |
| LightRAG | dual-level(저수준 엔티티 + 고수준 키워드) retrieval, 증분 업데이트 | 비용·속도·운영성 |
| HippoRAG | 해마 기억 모델 비유, Personalized PageRank로 단일 스텝 멀티홉 | 멀티홉 정확도 |
