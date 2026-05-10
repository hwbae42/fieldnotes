# AGENTS.md — fieldnotes 리포 안내

## 이 레포의 목적

AI 엔지니어링 생태계의 트렌드·방법론을 직접 소화하고 정제해두는 리서치 레포.
단순 링크 모음이 아니라, **다른 프로젝트에 그대로 가져다 쓸 수 있는 형태**로 작성한다.

---

## 문서 구조

```
docs/
├── index.md                        ← 완료 주제 목록 + 차후 조사 목록 (항상 여기서 시작)
└── {주제}/
    ├── overview.md                 ← 개념 요약, 배경, 왜 지금 이 주제인가
    ├── patterns.md                 ← 구체적인 패턴 (무엇/언제/어떻게/트레이드오프/출처)
    └── references.md               ← 검증된 참고 자료
```

**진입점은 언제나 `docs/index.md`다.** 완료된 주제와 차후 조사 목록이 함께 있다.

---

## 완료된 주제 (2026-05-10 기준)

| 주제 | 핵심 내용 |
|---|---|
| [에이전트 오케스트레이션](docs/agent-orchestration/overview.md) | 멀티 에이전트 설계, 11개 패턴, 하네스 프레임워크 비교 |
| [에이전트 친화적 코드베이스](docs/agent-friendly-codebase/overview.md) | AGENTS.md/CLAUDE.md 설계, 14개 패턴, MCP 통합 |
| [에이전트 메모리 / 컨텍스트](docs/agent-memory-context/overview.md) | Context engineering, 13개 패턴, RAG 연동, 압축 기법 |
| [에이전트 평가 / 관측](docs/agent-evals-observability/overview.md) | LLM-as-judge, 14개 패턴, 트레이스 표준, eval-driven CI |

---

## 차후 조사 목록 요약

자세한 내용은 `docs/index.md` → "차후 조사 목록" 참고.

**기존 주제 확장**
- `agent-memory-context` + Advanced RAG: Self-RAG, CRAG, RAPTOR, RAG-Fusion (높음) / HyDE, Modular RAG (중간) / FLARE (낮음)
- `agent-evals-observability` + RAGAS (높음)

**신규 주제 후보**
- 그래프 기반 RAG: GraphRAG, LightRAG, HippoRAG

---

## 작업 방식

### 새 주제 조사 시작 순서

1. `docs/index.md` 차후 조사 목록에서 우선순위 확인
2. `docs/{주제}/` 디렉토리 생성
3. `overview.md` 먼저 작성 — "왜 지금 이 주제인가"부터
4. `patterns.md` 작성 — 패턴마다 무엇/언제/어떻게/트레이드오프/출처
5. `references.md` 작성
6. `docs/index.md` 완료 주제 목록에 추가, 차후 목록에서 제거

### 기존 주제 확장 시

- 기존 파일에 섹션 추가 (새 파일 생성 말고)
- patterns.md에 패턴 번호 이어서 추가
- references.md에 출처 추가

### 문서 작성 원칙

- 한국어로 작성
- 개념 설명보다 **언제 왜 쓰는가**가 중심
- 출처 없는 주장은 쓰지 않는다
- 패턴 하나 = 무엇/언제/어떻게/트레이드오프/출처 형식 준수

---

## 자주 쓰는 명령

```bash
# 현재 파일 전체 목록
find docs/ -type f | sort

# 특정 키워드가 등장하는 파일 찾기
grep -ri "키워드" docs/

# 완료 주제 + 차후 목록 확인
cat docs/index.md
```
