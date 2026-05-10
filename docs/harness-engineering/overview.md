# 하네스 엔지니어링 — 개요

> 조사 시점: 2026-05-10. 출처는 [`references.md`](./references.md).
> 구체적 패턴은 [`patterns.md`](./patterns.md).

---

## 왜 "하네스 엔지니어링"이 별도 분야인가

"에이전트가 잘 동작한다"는 말은 두 가지를 뜻할 수 있다 — *모델이 좋다*는 뜻이거나, *하네스 설계가 좋다*는 뜻. 2026년 시점의 현장 보고들은 후자의 비중이 생각보다 훨씬 크다고 말한다.

> *"The harness — not the model — is where most of the leverage lives."*
> — OpenAI Codex 팀 (2026.02)

하네스(harness)는 모델 가중치를 제외한 모든 것이다. 컨텍스트 파일, 권한 설정, 훅, 세션 간 핸드오프 파일, 멀티에이전트 구조, 검증 자동화 — 에이전트가 "어떤 환경에서" 일하는지를 결정하는 모든 것. 같은 모델이라도 하네스가 달라지면 결과가 달라지는 건 이제 수치로 확인된다.

---

## OpenAI Codex 팀 현장 보고 (2026.02.11)

**출처**: ["Harness engineering: leveraging Codex in an agent-first world"](https://openai.com/index/harness-engineering/) — OpenAI 공식 블로그

빈 저장소에서 시작, 5개월, 팀 3명 → 7명으로 성장하며 진행한 실험의 결과:

| 지표 | 수치 |
|---|---|
| 코드 라인 | 100만 줄 |
| PR 수 | 1,500건 |
| 수동 작성 코드 | **0줄** |
| 개발 속도 | 수동 대비 **10배** |

Codex 팀이 이 결과를 만든 설계 원칙 세 가지:

1. **지도를 줘라 (Map, not manual)** — 에이전트에게 1,000페이지 문서가 아닌 "한 장짜리 지도"를 제공. 컨텍스트 파일 하나로 어디에 무엇이 있는지, 무엇을 하면 안 되는지를 담는다.
2. **아키텍처 제약을 기계적으로 강제** — 에이전트는 규칙을 "잊을" 수 있다. lint·test·hook으로 아키텍처 제약을 코드에 굽는다. 에이전트가 잘못된 모듈을 건드리면 CI가 막는다.
3. **기술 부채 가비지 컬렉션 (자동 PR)** — 에이전트가 정기적으로 코드베이스를 스캔해 기술 부채를 탐지하고 수정 PR을 자동 제출한다. 사람은 approve만 한다.

핵심 통찰:
> *"컨텍스트에 없는 것 = 존재하지 않는 것."*
> 에이전트는 컨텍스트 밖의 관습·이전 결정·암묵적 규칙을 추론하지 않는다. 명시하지 않으면 없는 것으로 취급한다.

---

## Anthropic 현장 보고 (2025.11 / 2026.03)

**출처**:
- ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (2025.11.26)
- ["Harness design for long-running application development"](https://www.anthropic.com/engineering/harness-design-long-running-apps) (2026.03.24)

Anthropic이 실제 장기 에이전트 작업에서 관찰한 두 가지 반복 실패 유형:

**실패 유형 ①: 원샷(one-shot) 함정**
모든 것을 한 세션에서 해결하려는 시도. 컨텍스트 윈도우가 작업 중간에 차오르고, 에이전트가 뒤로 갈수록 초기 지시를 잊으며, 결과 품질이 급락한다.

**실패 유형 ②: 조기 완료 선언**
실제로 끝나지 않았는데 "완료했습니다"로 종료. 검증 자동화가 없을 때 특히 흔하다.

해결 구조:

```
세션 0 ── Initializer Agent  ─── feature-list.json 생성
                              ─── progress.txt 생성
                              ─── 초기 인프라 셋업

세션 1..N ── Coding Agent  ─── progress.txt 읽기 (이전 상태 복원)
                           ─── 우선순위 높은 미완 feature 선택
                           ─── 작업 + 검증 (end-to-end test)
                           ─── git commit + progress 갱신

별도 세션 ── Evaluator Agent ─── 산출물 채점
                             ─── 다음 액션 권고
```

핵심 발견 (harness-design 2026.03):
- Generator + Evaluator 분리 구조가 단일 에이전트 대비 **"위상 변화(phase change)"급 품질 차이**를 만든다.
- 비용 프리미엄: 세션당 $9 → $200. 20배. 그러나 산출물 품질 차이도 그에 상응.

---

## 두 팀의 접근법 비교

| 관점 | OpenAI Codex 팀 | Anthropic |
|---|---|---|
| 핵심 문제 | 에이전트가 컨텍스트 없이 작동 | 에이전트가 이산 세션으로 기억 없이 시작 |
| 해결 방향 | 컨텍스트 파일 + 기계적 제약 | 세션 간 핸드오프 파일 + 역할 분리 |
| 강제 수단 | lint·hook·CI | feature-list.json·progress.txt·Evaluator |
| 핵심 통찰 | 컨텍스트 = 존재 여부 | 역할 분리 = 품질 위상 변화 |
| 공통점 | **단일 세션 원샷 금지** | **단일 세션 원샷 금지** |

---

## 기존 문서와의 관계

이 문서는 두 팀의 접근법을 **현장 보고·원칙** 수준에서 정리한다. 구체적인 구현 패턴은 이미 다른 문서에 더 자세히 있다:

- **세션 간 핸드오프 구조** → [에이전트 오케스트레이션 패턴 10: Long-Running Agent Harness](../agent-orchestration/patterns.md)
- **Evaluator 분리** → [에이전트 오케스트레이션 패턴 9: Evaluator–Optimizer](../agent-orchestration/patterns.md)
- **AGENTS.md Map 설계** → [에이전트 친화적 코드베이스 패턴 1–2](../agent-friendly-codebase/patterns.md)
- **완료 조건 명시** → [에이전트 친화적 코드베이스 패턴 3: Closure definition](../agent-friendly-codebase/patterns.md)
