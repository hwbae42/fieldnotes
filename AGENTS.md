# AGENTS.md — fieldnotes 리포 안내

> Claude Code, OpenAI Codex 등 모든 코딩 에이전트의 단일 진입점.
> CLAUDE.md는 이 파일의 심링크다 — 둘 다 같은 내용.

---

## 이 레포의 목적

AI 엔지니어링 생태계의 트렌드·방법론을 직접 소화하고 정제해두는 리서치 레포.
단순 링크 모음이 아니라, **다른 프로젝트에 그대로 가져다 쓸 수 있는 형태**로 작성한다.

---

## 파일 구조

```
AGENTS.md               ← 지금 여기 (단일 진입점)
CLAUDE.md               ← AGENTS.md 심링크 (Claude Code용)
RESEARCH-METHOD.md      ← 리서치 시작 전에만 읽는 상세 조사 방법론
feature-list.json       ← 다음 작업 목록, status 관리
claude-progress.txt     ← 세션 간 핸드오프 상태
scripts/
├── validate-docs.sh    ← 패턴 구조 검증 (5개 섹션 존재 여부)
└── find-tech-debt.sh   ← 미완성·확인 필요 항목 탐지
docs/
├── index.md            ← 완료 주제 목록 + 차후 조사 목록
└── {주제}/
    ├── overview.md     ← 개념 요약, 왜 이 주제인가
    ├── patterns.md     ← 패턴 카탈로그
    └── references.md   ← 검증된 참고 자료
```

---

## 세션 시작/종료 루틴

**시작 전**
```bash
cat claude-progress.txt   # 이전 세션 상태 파악
cat feature-list.json     # 다음 작업 우선순위 확인
```

**리서치 시작 전 추가로**: `cat RESEARCH-METHOD.md`

**종료 후**
1. `docs/index.md` 업데이트 (완료 주제 추가, 차후 목록에서 제거)
2. `claude-progress.txt` 업데이트 (완료 항목 체크, 다음 작업 명시)

---

## 패턴 완료 기준 (Definition of Done)

patterns.md의 모든 패턴은 다음 5개 섹션을 반드시 포함해야 한다.

| 섹션 | 허용 표기 |
|---|---|
| 무엇 | `**무엇**` / `**무엇.**` / `### 무엇` |
| 언제 | `**언제**` / `**언제 쓰나**` / `**언제.**` / `### 언제` |
| 어떻게 | `**어떻게**` / `**어떻게 적용**` / `**어떻게.**` / `### 어떻게` |
| 트레이드오프 | `**트레이드오프**` / `**트레이드오프.**` / `### 트레이드오프` |
| 출처 | `**출처**` / `**출처/예시**` / `### 출처` |

```bash
bash scripts/validate-docs.sh   # 자동 검증
```

---

## 완료된 주제 (2026-05-10 기준)

| 주제 | 핵심 내용 |
|---|---|
| [에이전트 오케스트레이션](docs/agent-orchestration/overview.md) | 멀티 에이전트 설계, 11개 패턴, 하네스 프레임워크 비교 |
| [에이전트 친화적 코드베이스](docs/agent-friendly-codebase/overview.md) | AGENTS.md 설계, 14개 패턴, MCP 통합 |
| [에이전트 메모리 / 컨텍스트](docs/agent-memory-context/overview.md) | Context engineering, 13개 패턴, RAG 연동, 압축 기법 |
| [에이전트 평가 / 관측](docs/agent-evals-observability/overview.md) | LLM-as-judge, 14개 패턴, 트레이스 표준, eval-driven CI |
| [하네스 엔지니어링 현장 보고](docs/harness-engineering/overview.md) | Codex 팀 3원칙, Anthropic 2가지 실패 유형, 6개 패턴, 1M줄·0 수동 코드 달성 방법론 |

---

## 차후 조사 목록

자세한 항목과 우선순위는 `feature-list.json` 참고.

**기존 주제 확장**
- `agent-memory-context` + Advanced RAG: Self-RAG, CRAG, RAPTOR, RAG-Fusion (높음) / HyDE, Modular RAG (중간) / FLARE (낮음)
- `agent-evals-observability` + RAGAS (높음)
- `harness-engineering` + 도구 레이어 설계 (높음) — 7요소 #02
- `harness-engineering` + 샌드박스·인젝션 방어 (높음) — 7요소 #05 시스템 측면
- `harness-engineering` + 에이전트 루프 제어 (높음) — 7요소 #04 세션 내부
- `harness-engineering` + 하네스 케이스 스터디 (중간) — Claude Code/Aider/Cursor/Devin/OpenHands/SWE-agent × 7요소
- `harness-engineering` + 컨텍스트 파이프라인 동적 주입 (중간) — 7요소 #01 동적 측면
- `harness-engineering` + 비용·모델 라우팅 (중간)

**신규 주제**
- 그래프 기반 RAG — GraphRAG, LightRAG, HippoRAG (높음)

---

## 자주 쓰는 명령

```bash
# 패턴 구조 검증
bash scripts/validate-docs.sh

# 기술 부채 탐지
bash scripts/find-tech-debt.sh

# 전체 파일 목록
find docs/ -type f | sort

# 키워드 검색
grep -ri "키워드" docs/
```

---

## 핵심 제약

- **한국어로 작성** — 모든 docs
- **출처 없는 주장 금지** — 패턴마다 출처/예시 필수 (URL 또는 출판물명)
- **기존 파일에 추가** — 기존 주제 확장 시 새 파일 생성 금지
- **패턴 번호 이어쓰기** — 기존 patterns.md에 N+1번부터
- **validate-docs.sh 통과** — 구조 오류 있으면 커밋 금지
