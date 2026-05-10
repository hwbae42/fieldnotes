# fieldnotes

새로 등장하는 트렌드와 방법론을 조사·정리하고, 다른 프로젝트에 적용하기 위한 리서치 레포입니다.

## 목적

- 빠르게 변화하는 AI 엔지니어링 생태계를 추적하고 핵심 개념을 문서화
- 조사한 내용을 실제 프로젝트에 적용할 수 있는 형태로 정제
- 반복 실험 없이 이미 검증된 패턴을 빠르게 가져다 쓸 수 있는 지식 베이스 구축

## 완료된 주제

| 주제 | 패턴 수 | 참고 자료 |
|---|---|---|
| [에이전트 오케스트레이션 / 하네스](docs/agent-orchestration/overview.md) | 11개 | 25+ |
| [코딩 에이전트 친화적인 코드베이스](docs/agent-friendly-codebase/overview.md) | 14개 | 25+ |
| [에이전트 메모리 / 컨텍스트 관리](docs/agent-memory-context/overview.md) | 13개 | 19개 |
| [에이전트 평가 / 관측](docs/agent-evals-observability/overview.md) | 14개 | 50+ |

전체 목록 및 차후 조사 후보 → [`docs/index.md`](docs/index.md)

## 구조

```
docs/
├── index.md            # 완료 주제 목록 + 차후 조사 목록
└── {주제}/
    ├── overview.md     # 개념 요약 및 배경
    ├── patterns.md     # 구체적인 패턴 및 적용 방법
    └── references.md   # 참고 자료
```

## 운영 방식

- 주제별로 `docs/` 하위에 디렉토리를 만들어 문서화
- 단순 링크 모음이 아닌, 직접 소화하고 정제한 내용만 기록
- 다른 프로젝트에 가져다 쓸 수 있도록 **실용적인 형태**로 작성
- AI 에이전트와 협업 시 → [`AGENTS.md`](AGENTS.md) 참고
