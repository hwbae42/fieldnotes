# 하네스 엔지니어링 — 패턴 카탈로그

> 조사 시점: 2026-05-10. 출처는 [`references.md`](./references.md). 개념적 배경은 [`overview.md`](./overview.md).
>
> 각 패턴 형식: **무엇 / 언제 / 어떻게 / 트레이드오프 / 출처**.
> 기존 패턴과 중복을 피하기 위해 구현 상세는 agent-orchestration·agent-friendly-codebase를 참조하고, 여기서는 원칙·framing·현장 수치에 집중한다.

패턴 목록:
1. [Map-first context design (지도 우선 컨텍스트 설계)](#1-map-first-context-design)
2. [Mechanical architecture enforcement (아키텍처 제약 기계적 강제)](#2-mechanical-architecture-enforcement)
3. [Automated tech debt collection (기술 부채 자동 수거)](#3-automated-tech-debt-collection)
4. [Context-existence equivalence (컨텍스트 = 존재 여부)](#4-context-existence-equivalence)
5. [One-shot trap avoidance (원샷 함정 회피)](#5-one-shot-trap-avoidance)
6. [Generator-Evaluator separation (생성-평가 역할 분리)](#6-generator-evaluator-separation)

---

## 1. Map-first context design

### 무엇
에이전트가 첫 턴부터 의존하는 단일 컨텍스트 파일(AGENTS.md)에 "지도" — 디렉토리 구조, 핵심 명령, 금지 사항, 완료 기준 — 를 담는다. 1,000페이지 문서 대신 한 장짜리 지도.

### 언제
- 에이전트 프로젝트를 시작할 때 가장 먼저 해야 하는 일.
- 에이전트가 "엉뚱한 파일을 수정"하거나 "deprecated 모듈을 호출"하는 증상이 반복될 때.
- 팀원마다 에이전트 도구가 달라 동일 컨텍스트를 여러 도구에 줘야 할 때.

### 어떻게

AGENTS.md의 최소 구성 (Codex 팀이 실제 사용한 구조 기반):

```markdown
# [프로젝트명] — 에이전트 컨텍스트

## 디렉토리 지도
- src/v2/      ← 모든 신규 코드 여기
- src/legacy/  ← 절대 수정 금지, deprecated
- scripts/     ← 빌드·배포 자동화

## 핵심 명령
- 테스트: `pnpm vitest run`
- 빌드:   `pnpm build`
- 린트:   `pnpm lint && pnpm typecheck`

## 완료 기준
위 세 명령이 모두 exit 0일 때 완료.

## 절대 하지 말 것
- src/legacy/** 수정
- .env* 파일 커밋
- npm/yarn 사용 (pnpm만)
```

길이 기준: Codex 팀은 "모델이 무시하기 시작하기 전까지"를 기준으로 관리. HumanLayer는 60줄 미만 운영.

### 트레이드오프
- 파일이 현실과 괴리되면 에이전트가 틀린 지도를 믿고 잘못된 방향으로 간다 — 코드 변경과 동기화 필수.
- "모든 것을 넣겠다"는 욕심이 지도를 1,000페이지로 만들어 처음 문제로 회귀.
- 해결: "이 줄이 없으면 에이전트가 실수를 저지르나?"를 자문하며 줄이기.

### 출처
- [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/) — Principle 1: "Give the agent a map, not a manual." 1M줄 프로젝트에 적용.
- [agent-friendly-codebase 패턴 1–2](../agent-friendly-codebase/patterns.md) — AGENTS.md 6-섹션 구조 상세.

---

## 2. Mechanical architecture enforcement

### 무엇
아키텍처 규칙을 문서가 아닌 **코드·도구**에 굽는다. lint rule, import restriction, CI 테스트, hook으로 에이전트가 위반 시 즉시 실패 신호를 받게 한다. 에이전트는 규칙을 "잊을" 수 없다 — 잊으면 exit 1을 받는다.

### 언제
- AGENTS.md에 "X 하지 마라"고 써도 에이전트가 반복적으로 위반할 때.
- 모듈 경계, 레이어 분리, deprecated 코드 격리처럼 아키텍처적으로 중요한 제약이 있을 때.
- 에이전트가 자율 모드(비대화형)로 대규모 변경을 할 때 — 사람이 모든 PR을 검토하기 전에 기계가 먼저 걸러야 함.

### 어떻게

**레이어 1 — lint rule**

ESLint의 `no-restricted-imports`로 금지 import를 컴파일 오류로:

```js
// eslint.config.js
rules: {
  "no-restricted-imports": ["error", {
    patterns: [{ group: ["*/legacy/*"], message: "Use src/v2/** instead." }]
  }]
}
```

**레이어 2 — Claude Code PostToolUse hook**

모든 파일 수정 직후 자동으로 lint를 돌려 에이전트에게 즉각 피드백:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "pnpm lint --quiet" }]
    }]
  }
}
```

**레이어 3 — Stop hook (완료 조건 강제)**

에이전트가 테스트 실패 상태로 종료를 선언하면 차단:

```bash
#!/usr/bin/env bash
# stop-hook.sh
if ! pnpm vitest run --silent 2>/dev/null; then
  echo '{"decision":"block","reason":"테스트 실패 — 수정 후 재시도"}'
  exit 0
fi
echo '{"decision":"approve"}'
```

세 레이어가 쌓이면 에이전트는 아키텍처 규칙을 위반한 채 "완료"를 선언할 수 없다.

### 트레이드오프
- 초기 셋업 비용: lint rule·hook·테스트를 구성하는 데 시간이 든다.
- 너무 엄격한 rule은 에이전트가 정당한 리팩터도 못 하게 막을 수 있다 — rule은 최소한으로.
- 의도적으로 실패 상태를 만들어야 하는 TDD 흐름에서는 Stop hook을 일시 우회하는 escape hatch 필요.

### 출처
- [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/) — Principle 2: "Mechanically enforce architecture constraints."
- [agent-friendly-codebase 패턴 4–6](../agent-friendly-codebase/patterns.md) — PostToolUse hook, Stop hook 구현 상세.

---

## 3. Automated tech debt collection

### 무엇
에이전트가 주기적으로 코드베이스를 스캔해 기술 부채(TODO, deprecated 호출, lint warning, 미사용 의존성)를 탐지하고, 수정 후 PR을 자동 제출한다. 사람은 approve 여부만 결정한다.

### 언제
- 코드베이스가 성숙해 지속적인 유지보수가 필요한 프로젝트.
- "언젠간 고쳐야지" 목록이 쌓여 아무도 건드리지 않는 기술 부채가 있을 때.
- 에이전트가 대부분의 코드를 작성하는 agent-first 프로젝트 — Codex 팀처럼 수동 코드 0 환경에서는 부채 수거도 에이전트가 담당하는 게 자연스러움.

### 어떻게

**단계 1 — 탐지 에이전트 실행**

```bash
# 정기 실행 (CI 스케줄 또는 수동 트리거)
claude -p "
코드베이스를 스캔해 다음을 찾아라:
1. TODO/FIXME 주석이 달린 함수
2. 사용하지 않는 import
3. src/legacy/** 를 참조하는 src/v2/** 코드
각 항목을 JSON으로 출력: {file, line, type, description}
" --output-format json > tech-debt-report.json
```

**단계 2 — 수정 에이전트 + 자동 PR**

```bash
cat tech-debt-report.json | claude -p "
각 항목을 수정하라. 수정 후:
1. 테스트 실행 (pnpm vitest run)
2. 린트 실행 (pnpm lint)
두 명령이 exit 0이면 git commit하고 PR을 열어라.
PR 제목: 'chore: auto tech-debt [{type}] {file}'
" --permission-mode auto
```

Codex 팀은 이 흐름으로 1,500 PR 중 상당수를 자동 생성했으며 수동 코드는 0이었다.

### 트레이드오프
- 자동 PR 노이즈: 작은 수정 PR이 대량으로 열리면 리뷰 부담 증가. PR 배치 처리나 threshold 설정으로 완화.
- 잘못된 수정이 자동으로 올라올 위험 — 반드시 테스트·린트 통과를 PR 조건으로.
- 수정이 의미론적으로 틀릴 수 있음 (문법은 맞아도 로직이 다른 경우). 사람 검토가 최종 게이트.

### 출처
- [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/) — Principle 3: "Tech debt garbage collection via auto PR." 수동 코드 0 달성의 배경.

---

## 4. Context-existence equivalence

### 무엇
에이전트는 컨텍스트에 없는 정보를 **존재하지 않는 것으로 취급**한다. 암묵적 관습, 이전 결정의 배경, "당연히 알겠지" 싶은 규칙 — 명시하지 않으면 에이전트에게는 없는 것이다.

이것은 패턴이라기보다 에이전트와 협업하는 사람이 내면화해야 할 **인식론적 원칙**이다. 다른 모든 패턴이 이 원칙 위에 서 있다.

### 언제
에이전트가 예상과 다르게 동작할 때 가장 먼저 물어야 하는 질문: *"이 정보가 컨텍스트에 있었는가?"*

흔한 증상:
- 에이전트가 deprecated 모듈을 호출한다 → AGENTS.md에 명시했나?
- 에이전트가 A 라이브러리 대신 B를 쓴다 → "A를 써라"가 컨텍스트에 있었나?
- 에이전트가 팀 컨벤션을 모른다 → 문서화했나, 아니면 "다들 알지"였나?

### 어떻게

컨텍스트 파일을 검토할 때 각 줄에 대해 자문한다:

> *"이 줄이 없으면 에이전트가 실수를 저지르는가?"*

실수가 예상된다면 남긴다. 그렇지 않으면 지운다 (컨텍스트 길이가 품질에 영향).

실무 체크리스트:
- [ ] 금지 모듈·디렉토리가 명시되어 있나?
- [ ] 사용해야 하는 도구·런타임이 명시되어 있나?
- [ ] 완료 기준이 검증 가능한 명령으로 정의되어 있나?
- [ ] 두 개의 비슷한 개념이 공존할 때 구분 기준이 명시되어 있나? (예: `CustomerID` vs `CustomerNo`)

### 트레이드오프
- 원칙을 과하게 적용하면 AGENTS.md가 1,000페이지로 뚱뚱해진다 — 패턴 1(Map-first)의 길이 원칙과 함께 운용.
- 무엇을 명시할지는 판단의 영역이다. 기준: 에이전트의 과거 실수 패턴에서 역으로 추출하는 게 가장 정확.

### 출처
- [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/) — *"What's not in context = doesn't exist."* Codex 팀의 핵심 통찰.

---

## 5. One-shot trap avoidance

### 무엇
컨텍스트 윈도우를 초과하는 작업을 한 세션에서 해결하려는 "원샷 함정"을 피한다. 작업을 청크로 분해하고, 세션 간 핸드오프 파일로 연속성을 유지한다.

### 언제
- 단일 세션이 끝나기 전에 작업이 완료되지 않거나 품질이 급락하는 것을 경험했을 때.
- 큰 마이그레이션, 대규모 리팩터, 기능 단위 자율 개발처럼 본질적으로 장기적인 작업.
- 에이전트가 뒤로 갈수록 초기 지시를 잊는 증상이 반복될 때.

### 어떻게

Anthropic이 정립한 두 파일 패턴:

**feature-list.json** — 무엇을 해야 하는가

```json
{
  "topics": [
    {
      "id": "auth-migration",
      "status": "in_progress",
      "priority": "high",
      "done_criteria": "pnpm test exits 0, no legacy/auth imports remain"
    },
    {
      "id": "db-schema-update",
      "status": "pending",
      "priority": "medium"
    }
  ]
}
```

**progress.txt** — 지금 어디까지 왔는가

```
세션 3 (2026-05-10): auth-migration 진행 중
완료: UserService 마이그레이션, AuthMiddleware 마이그레이션
남은 것: TokenRefreshService, 통합 테스트
다음 세션 시작: cat progress.txt → TokenRefreshService부터
```

세션이 시작될 때마다 에이전트가 두 파일을 읽어 상태를 복원한다. 이전 세션의 컨텍스트가 없어도 어디서 재개해야 하는지 안다.

실패 유형 ② (조기 완료 선언)는 이 패턴과 Closure definition(agent-friendly-codebase 패턴 3)을 함께 적용해 차단한다.

### 트레이드오프
- progress.txt가 실제 코드 상태와 괴리되면 다음 세션이 잘못된 전제로 시작 — 커밋과 동기화 필수.
- 청크가 너무 크면 한 세션에서 끝나지 않아 또 잘린다. 청크 크기 튜닝 필요.
- 검증 자동화(테스트, lint)가 없으면 에이전트가 "완료"라고 해도 확인할 방법이 없다.

### 출처
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — 두 실패 유형 정의, Initializer+Coding agent 구조, feature-list+progress 파일 패턴.
- [agent-orchestration 패턴 10](../agent-orchestration/patterns.md) — Long-Running Agent Harness 구현 상세.

---

## 6. Generator-Evaluator separation

### 무엇
작업을 생성하는 에이전트(Generator)와 결과를 평가하는 에이전트(Evaluator)를 분리한다. 같은 에이전트가 자기 작품을 평가하면 "사실 이건 좋은데..."로 합리화하는 경향이 강해 품질 게이트가 동작하지 않는다.

### 언제
- 에이전트 산출물의 품질이 "그럭저럭 동작하지만 좋지 않다"는 평가를 받을 때.
- 주관적 기준이 있는 작업 — UI 설계, 문서, 아키텍처 결정, 코드 품질 평가.
- 비용 프리미엄(~20×)을 정당화할 수 있는 높은 품질이 요구되는 작업.

### 어떻게

Anthropic harness-design 논문의 3-에이전트 구조:

```
[Planner Agent]
  ↓ 목표·구조·완료 기준 정의
[Generator Agent]
  ↓ 구현 (코드, 문서, 설계 등)
[Evaluator Agent]
  ↓ 독립 채점 — "이게 기준을 충족하는가?"
  ↓ 미충족 시 Generator에게 피드백 → 재시도
```

Evaluator는 별도 시스템 프롬프트로 분리하거나 별도 모델 인스턴스를 사용한다. Anthropic이 내부적으로 사용한 rubric 구조:

```
평가 기준 (각 1–5점):
- Correctness: 명세를 충족하는가?
- Quality: 코드·문서 품질이 기준 이상인가?
- Completeness: 빠진 케이스가 없는가?
모두 4점 이상이면 통과.
```

### 트레이드오프
- **비용 프리미엄이 크다**: Anthropic 실험에서 단일 에이전트 $9/세션 → Generator+Evaluator $200/세션. 20×.
- 그러나 보고된 품질 차이는 "위상 변화(phase change)"급 — 단순한 개선이 아니라 다른 카테고리의 결과.
- Evaluator rubric이 잘못 설계되면 Generator가 그쪽으로 최적화되어 엉뚱한 방향으로 수렴한다 — rubric 설계가 핵심.
- max iterations와 stop criteria 없이 실행하면 무한 루프 위험.

### 출처
- [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) — Generator+Evaluator 20× 비용 프리미엄, "phase change" 품질 발견.
- [agent-orchestration 패턴 9](../agent-orchestration/patterns.md) — Evaluator–Optimizer 구현 상세.

---

## 패턴 선택 가이드

| 증상 | 적용할 패턴 |
|---|---|
| 에이전트가 deprecated 코드를 계속 호출 | 패턴 4 → 패턴 1 (컨텍스트에 명시) |
| 명시했는데도 위반을 반복 | 패턴 2 (기계적 강제) |
| 기술 부채가 쌓이고 아무도 안 건드림 | 패턴 3 (자동 수거 파이프라인) |
| 세션 중간에 품질이 급락 | 패턴 5 (청크 분해 + 핸드오프) |
| 산출물이 "그럭저럭"에서 벗어나지 않음 | 패턴 6 (Evaluator 분리, 비용 감수) |
