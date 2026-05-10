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

## 7. Tool description ergonomics (도구 설명 인체공학)

### 무엇
도구 이름·description·파라미터 명을 "사람 신입에게 설명하듯" 설계해 에이전트의 도구 선택 정확도를 끌어올린다. 잘못된 description은 에이전트를 완전히 엉뚱한 경로로 보낸다.

### 언제
- 에이전트가 비슷한 두 도구 중 잘못된 쪽을 반복적으로 고를 때.
- 도구를 만들었지만 "왜 안 쓰지?" 또는 "왜 잘못 쓰지?" 증상이 보일 때.
- 새 MCP 서버나 인하우스 도구를 추가하기 직전 — 사후 수정보다 첫 description이 훨씬 싸다.
- 외부 사용자(다른 에이전트)에게 도구를 공개할 때.

### 어떻게

Anthropic이 명시한 두 가지 핵심 권고:

1. **Namespace로 충돌 제거.** `search`처럼 평범한 이름은 의미 없는 공간을 차지한다. `asana_projects_search`, `asana_users_search`처럼 prefix/suffix를 붙이면 모델이 의도를 1턴에 식별하고, 중복 도구를 컨텍스트에서 통합 표현할 수 있다.
2. **파라미터는 의도 명세.** `user` 대신 `user_id`, `q` 대신 `search_query`. 이름 자체가 입력 형식의 절반을 설명해야 한다.

Anthropic 멀티 에이전트 리서치 시스템 사례에서, 도구 description을 자동으로 재작성하는 *tool-testing 에이전트*를 도입한 결과 후속 에이전트의 **task completion time이 40% 감소**했다. 같은 코드, 같은 모델, description만 바꿔서 얻은 수치다.

Anti-pattern 카탈로그:
- 한 줄짜리 description (`"Get user data."`) — 어떤 user인지, 어떤 data인지 없음.
- 이름이 같고 의도만 미묘하게 다른 두 도구 (`get_user`, `fetch_user`).
- 파라미터에 free-form string만 받고 형식 힌트 없음.

### 트레이드오프
- description이 길어지면 토큰 비용이 늘어난다 — 도구가 50개라면 description만으로 수천 토큰. 패턴 8(동적 로딩)과 함께 운용.
- "좋은 description" 기준이 주관적이라 팀 내 합의가 필요 — 자동 평가(eval)로 객관화 가능.
- 실패 지점: description을 영어로만 쓰면 비영어 사용자 의도와 어긋날 수 있음. 도구 사용 trace를 주기적으로 샘플링해 오용 패턴을 description에 역반영.

### 출처
- [How we built our multi-agent research system](https://www.anthropic.com/engineering/built-multi-agent-research-system) — *"Bad tool descriptions can send agents down completely wrong paths."* description 재작성 → 40% 시간 단축.
- [Writing tools for AI agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — namespace, 파라미터 명명 권고.

---

## 8. 도구 카탈로그 동적 로딩

### 무엇
모든 도구 description을 시스템 프롬프트에 한꺼번에 박아넣지 않는다. 컨텍스트에는 도구 *카탈로그*(목록·요약)만 두고, 실제 description·schema는 호출 직전에 just-in-time으로 노출하거나 파일시스템에서 읽도록 한다.

### 언제
- MCP 서버가 3개 이상 연결되어 도구 description만으로 수만 토큰을 소모할 때.
- 도구 개수가 늘면서 모델이 "비슷한 도구 중 잘못된 것을 고르는" 빈도가 증가할 때.
- 같은 에이전트가 다양한 작업을 수행해 매 작업마다 필요한 도구 부분집합이 다를 때.

### 어떻게

세 가지 점진적 전략:

1. **도구 통합 (consolidation).** Anthropic 권고: `get_customer_by_id`, `list_transactions`, `list_notes`를 하나의 `get_customer_context`로 묶는다. 도구 수 자체를 줄여 description 비용을 절감.
2. **Just-in-time 노출.** 첫 턴에는 도구 *이름과 한 줄 요약*만 제공. 에이전트가 "이 도구 쓰겠다"고 선언하면 그제서야 full schema를 컨텍스트에 주입. Claude Code MCP 서버 enable/disable, sub-agent의 tool whitelist가 같은 원리.
3. **Code execution 패턴.** Anthropic의 *Code execution with MCP* 제안: MCP 도구를 TypeScript 파일로 디스크에 두고 에이전트는 필요할 때만 `import`. Google Drive→Salesforce 예시에서 **150,000 토큰 → 2,000 토큰, 98.7% 절감**.

```
agent_workspace/
├── tools/
│   ├── asana/projects.ts    ← schema, 호출 시점에만 read
│   ├── asana/tasks.ts
│   └── linear/issues.ts
└── catalog.md               ← 한 줄씩 요약, 항상 컨텍스트
```

### 트레이드오프
- Just-in-time은 latency를 추가한다 — 도구 선택 후 schema 로딩에 1턴 더 필요.
- Code execution 방식은 샌드박스·실행 환경 인프라가 필요하며 (Anthropic 본인도 인정) "구현은 독자에게 맡긴다"는 단계.
- 도구 카탈로그 요약이 부정확하면 에이전트가 "이 도구가 있는지조차" 모르고 다른 길로 감.
- 실패 지점: namespace 없이 동적 로딩만 적용하면 동명 도구 충돌이 더 심해진다 — 패턴 7과 함께.

### 출처
- [Code execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) — 150K→2K 토큰 절감, progressive tool discovery, filesystem-as-tools.
- [Writing tools for AI agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — *"more tools don't always lead to better outcomes"*, 도구 통합 권고.
- [Simon Willison: Code execution with MCP](https://simonwillison.net/2025/Nov/4/code-execution-with-mcp/) — *"all of those tool descriptions take up a lot of valuable real estate."*

---

## 9. MCP 서버를 인하우스 함수처럼 설계

### 무엇
MCP 서버를 "범용 SaaS API의 얇은 wrapper"로 만들지 않는다. 자기 에이전트가 실제로 수행하는 작업 흐름에 맞춘 high-level 함수로 설계하고, 응답은 high-signal 정보만 반환한다.

### 언제
- 외부 SaaS 도구(Asana, Linear, GitHub 등)를 에이전트에 붙일 때.
- MCP 도구를 호출할 때마다 응답이 수천 토큰을 차지하고 그중 대부분이 ID·메타데이터일 때.
- 한 작업을 위해 MCP 도구를 5번 이상 chain해야 할 때 — 인터페이스가 잘못 설계됐다는 신호.

### 어떻게

Anthropic의 네 가지 권고를 MCP 서버 설계에 그대로 적용:

1. **High-level 작업 단위로 도구를 묶는다.** Customer 정보를 보려고 `get_customer` + `list_orders` + `list_tickets`를 따로 호출하지 말고, `get_customer_context(customer_id)` 하나로 끝낸다.
2. **응답에서 low-signal 토큰을 제거한다.** UUID, 내부 ID, 시스템 timestamp 대신 `name`, `image_url`, `file_type` 같은 사람·에이전트가 읽을 수 있는 필드를 우선. Anthropic 사례에서 같은 데이터를 concise 형식으로 반환했더니 **206 → 72 토큰 (~⅓)**.
3. **`response_format` enum 제공.** `"detailed"`(ID 포함)와 `"concise"`(요약) 중 에이전트가 선택. 디버깅 시에는 detailed, 일반 작업에서는 concise.
4. **기본 25,000 토큰 cap.** Claude Code는 도구 응답을 25K 토큰으로 자른다. MCP 서버도 자체 pagination·truncation·필터링 파라미터를 갖춰야 한다.

권한 분리: 한 MCP 서버에 read와 write를 섞어두면 에이전트 sandbox 정책을 짤 수 없다. `linear_read`(조회 전용)와 `linear_write`(생성·수정)를 분리해 PostToolUse hook이나 permission rule에서 다르게 다룬다.

### 트레이드오프
- High-level 도구는 재사용성이 떨어진다 — 한 작업에 최적화하면 다른 작업에서 어색.
- 응답 포맷을 가공할수록 MCP 서버 코드가 복잡해지고 SaaS API 변경에 깨지기 쉬움.
- "이 도구가 정말 필요한가?"라는 1차 질문 없이 SaaS의 모든 endpoint를 wrapper로 노출하면 패턴 8이 풀어야 할 도구 폭증을 도리어 악화시킨다.
- 실패 지점: MCP 응답을 줄이려고 핵심 ID를 빼면 후속 도구 호출이 막힌다 — concise 모드에서도 호출 chain에 필요한 최소 ID는 남겨야 함.

### 출처
- [Writing tools for AI agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — high-signal 응답, ResponseFormat enum, 25K 토큰 기본 cap, 206→72 토큰 사례.
- [Code execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) — MCP 도구 chain의 토큰 누적 문제.

---

## 10. 도구 결과 오프로딩과 압축

### 무엇
용량이 큰 도구 결과(파일 read, grep, 빌드 로그)를 컨텍스트에 그대로 주입하지 않는다. 결과를 파일에 dump하고 **경로와 요약만 반환**하거나, sub-agent가 탐색 후 1–2K 토큰으로 압축한 보고서만 상위 에이전트에 올린다.

### 언제
- 단일 도구 호출이 컨텍스트의 큰 비중을 차지해 후반 턴에서 품질이 떨어질 때.
- grep, find, 대형 로그처럼 결과 크기가 입력으로 예측 불가능할 때.
- 같은 결과를 여러 턴에 걸쳐 다시 보지 않아도 되는 일회성 탐색일 때.

### 어떻게

세 가지 기법을 조합:

**(a) Truncation + 페이지네이션 기본값.** 모든 도구는 `head`, `tail`, `offset`, `limit`, `pattern` 파라미터를 갖고 합리적 기본값을 설정. Claude Code의 Read 도구가 "기본 2,000줄, offset 지원"인 것이 정확히 이 패턴.

**(b) 파일로 dump → 경로 반환.** 큰 결과는 작업 디렉토리에 저장하고 응답으로는 경로·라인 수·핵심 매치만:

```json
{
  "result_file": ".agent/results/grep-2026-05-10-1.txt",
  "match_count": 1843,
  "first_5_matches": ["src/auth.ts:42 ...", "..."],
  "next_action_hint": "read with offset to inspect"
}
```

에이전트는 필요할 때만 그 파일을 읽는다. Anthropic *Effective context engineering*의 file-system-as-context 패턴: *"folder hierarchies, naming conventions, and timestamps all provide important signals."*

**(c) Sub-agent 요약.** 탐색이 큰 작업은 sub-agent에 위임해 수천 토큰을 소모하게 두고, 상위 에이전트에게는 1,000–2,000 토큰의 요약만 올린다. Anthropic이 명시: *"specialized sub-agents can explore extensively ... while returning only condensed summaries."*

또한 turn 깊이가 쌓이면 과거 도구 결과의 raw 출력은 제거(tool result clearing). Anthropic 권고: *"once a tool has been called deep in the message history, why would the agent need to see the raw result again?"*

### 트레이드오프
- 파일로 dump하면 후속 턴에서 같은 정보를 다시 읽는 비용 발생 — pagination·요약을 함께 둬야 net 절감.
- Sub-agent 요약은 손실 압축이라 핵심 단서가 누락되면 상위 에이전트가 잘못된 결론으로 직진.
- Tool result clearing이 너무 공격적이면 에이전트가 "방금 본 파일이 뭐였더라"를 잃는다 — 최근 N턴은 보존.
- 실패 지점: 결과 파일을 git에 커밋하면 부채로 누적 — `.agent/`를 `.gitignore`에 두는 운영 규칙 필수.

### 출처
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — just-in-time retrieval, file-system-as-context, sub-agent 요약(1–2K 토큰), tool result clearing.
- [Writing tools for AI agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — *"pagination, range selection, filtering, and/or truncation with sensible default parameter values"*.

---

## 11. 에이전트 샌드박스 격리

### 무엇
에이전트의 파일·프로세스·네트워크 접근을 호스트에서 분리된 일회성 환경(devcontainer, Docker, ephemeral VM, firejail)에 가두어 폭주·악성 도구 호출의 폭발 반경을 차단하는 구조.

### 언제
- `bypassPermissions` 류 자율 모드(YOLO)를 켜고 싶을 때 — 공식 문서가 "isolated environments like containers or VMs" 사용을 명시 요구.
- 신뢰할 수 없는 코드베이스·이슈·웹 콘텐츠를 읽고 명령을 실행하는 워크플로.
- CI에서 PR 자동 수정 등 무인(unattended) 에이전트 실행.
- 호스트 자격증명·SSH 키·`~/.aws`가 노출 가능한 개발 머신.

### 어떻게
- **Anthropic 레퍼런스 devcontainer**(`anthropics/claude-code/.devcontainer`): `Dockerfile` + `devcontainer.json` + `init-firewall.sh`로 구성. `init-firewall.sh`가 컨테이너 부팅 시 iptables 규칙을 적용해 egress를 화이트리스트 도메인으로만 제한.
- 워크스페이스만 bind mount, 그 외 home·SSH 키는 마운트하지 않음.
- 일회성: 세션마다 컨테이너를 새로 만들고 폐기(ephemeral). 영속 상태는 명시된 볼륨에만.
- Linux 단일 프로세스 격리는 `firejail`로 syscall·파일시스템을 좁히고, 더 강한 격리는 firecracker microVM 또는 클라우드 VM.

### 트레이드오프
- 장점: `bypassPermissions` 모드에서도 호스트 손상·자격증명 유출 방지, 재현성 확보.
- 단점: 셋업·디스크 비용, IDE/디버거 통합 마찰, 빌드 캐시 손실.
- 우회 위험: 워크스페이스에 `.env`·자격증명을 두면 격리 의미 상실. 모델이 컨테이너 안에서 외부로 자체 exfil할 수 있어 egress 제어와 반드시 병행해야 함(다음 패턴).

### 출처
- [Choose a permission mode — Claude Code Docs](https://code.claude.com/docs/en/permission-modes) — "Only use this mode in isolated environments like containers or VMs where Claude Code cannot cause damage."
- [anthropics/claude-code .devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer) — Dockerfile·devcontainer.json·init-firewall.sh 3종 세트.
- [Development Containers Specification](https://containers.dev/) — devcontainer.json 표준.

---

## 12. 네트워크 egress 화이트리스트

### 무엇
에이전트가 동작하는 컨테이너·VM에서 default-deny + 화이트리스트 정책으로 외부 네트워크 호출을 강제 제한해 모델 자체 데이터 exfil과 indirect prompt injection 페이로드의 외부 통신을 끊는 패턴.

### 언제
- 에이전트가 `curl`·`wget`·MCP HTTP 도구·패키지 매니저(`npm install` 등)를 자유 실행할 때.
- 외부 콘텐츠(이슈, 웹페이지, README)를 읽는 indirect injection 표면이 큰 워크플로.
- 사내 코드·시크릿이 노출된 워크스페이스에서 작업.

### 어떻게
- **Default-deny iptables**: `iptables -P OUTPUT DROP` 후 필요한 도메인·포트만 ACCEPT. Anthropic 레퍼런스 `init-firewall.sh`는 컨테이너 시작 시 이 패턴 그대로 적용.
- 도메인 화이트리스트 예시: `api.anthropic.com`, `registry.npmjs.org`, `pypi.org`, `github.com`. 동적 IP는 `ipset`으로 주기 갱신.
- 강제 프록시: 컨테이너의 `HTTP(S)_PROXY`를 mitmproxy/Squid로 라우팅 → URL allowlist + 요청·응답 로깅. 에이전트가 우회하려고 raw socket을 써도 iptables가 막음.
- DNS 격리: 내부 DNS 리졸버로 고정해 DNS 기반 exfil(`xxx.attacker.com` 쿼리) 차단.

### 트레이드오프
- 장점: indirect injection이 성공해도 외부 송신처가 막혀 비밀 유출·C2 통신 불가. OWASP LLM01 "least privilege" 권고 충족.
- 단점: 빌드가 새 도메인을 호출할 때마다 화이트리스트 갱신 필요, 폐쇄망 처음 셋업 비용 큼.
- 우회 위험: 에이전트가 화이트리스트 안의 정상 서비스(예: GitHub Gist, Pastebin)를 exfil 채널로 악용 가능 — 도메인 단위가 아닌 경로·계정 단위 정책이 더 안전.

### 출처
- [anthropics/claude-code init-firewall.sh](https://github.com/anthropics/claude-code/tree/main/.devcontainer) — 컨테이너 부팅 시 iptables egress 화이트리스트 적용.
- [OWASP LLM01:2025 Prompt Injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/) — "Apply least privilege by restricting model access to minimum necessary permissions."

---

## 13. 시크릿 redaction & 탐지 파이프라인

### 무엇
프롬프트·도구 결과·커밋 시점 세 지점에서 정규식·엔트로피 기반 스캐너로 API 키·토큰·비밀번호를 검출·차단해 모델 컨텍스트와 git 히스토리에 시크릿이 새어 들어가지 않게 하는 다층 방어.

### 언제
- 에이전트가 `.env`·`config/`·`~/.aws/credentials` 같은 파일을 자동으로 읽을 수 있는 환경.
- 도구 결과(쉘 stdout, HTTP 응답)가 그대로 프롬프트에 첨부되어 모델 → 외부 API로 흘러갈 위험.
- 에이전트가 `git commit`·PR 생성을 자율 수행.

### 어떻게
- **Pre-commit 훅**: gitleaks를 pre-commit 프레임워크로 등록.
  ```yaml
  repos:
    - repo: https://github.com/gitleaks/gitleaks
      rev: v8.24.2
      hooks:
        - id: gitleaks
  ```
  `pre-commit install` 후 모든 커밋이 자동 스캔. 100+ 빌트인 규칙, base64·hex 디코딩, Shannon entropy 임계값(기본 ~3.5).
- **CI 게이트**: `gitleaks git --report-path report.json`로 PR마다 베이스라인 비교, hit 시 머지 블록.
- **런타임 redaction**: 도구 결과를 모델에 보내기 전 `detect-secrets`/`gitleaks stdin`로 스캔해 매치 토큰을 `[REDACTED]`로 치환. 스트리밍 입력도 `cat file | gitleaks stdin -v`로 처리 가능.
- **Hook 우회 방지**: `--no-verify`·`SKIP=gitleaks`를 정책으로 금지, 서버 측 push hook 또는 GitHub secret scanning을 보강.

### 트레이드오프
- 장점: 다층(컨텍스트 진입 + 커밋 진출) 차단, 정규식만으로도 대부분 키 포맷 커버.
- 단점: false positive로 합법 코드(테스트 픽스처)가 막힘, 저엔트로피 시크릿(짧은 PIN)은 놓침, 룰 유지비.
- 우회 위험: 에이전트가 시크릿을 base64/문자열 분해로 변형하거나 새 파일명·non-git 경로(예: `/tmp`)에 두면 hook이 안 잡음. 런타임 redaction이 없으면 모델이 이미 본 후라 이론상 prompt injection 트리거에 노출.

### 출처
- [gitleaks/gitleaks](https://github.com/gitleaks/gitleaks) — 정규식 + 엔트로피, pre-commit·CI·stdin 모드, 100+ 빌트인 룰.
- [OWASP LLM01:2025 Prompt Injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/) — "Filter inputs/outputs by identifying and handling sensitive content."

---

## 14. Dual-LLM 패턴 (Privileged / Quarantined 분리)

### 무엇
사용자 지시를 다루는 Privileged LLM(P-LLM, 도구 호출 권한 보유)과 외부 untrusted 콘텐츠를 다루는 Quarantined LLM(Q-LLM, 도구 권한 없음)을 분리하고, 둘 사이는 비-LLM Controller가 변수 토큰으로만 데이터를 전달하도록 강제하는 prompt injection 방어 구조.

### 언제
- 에이전트가 이메일·웹페이지·이슈 댓글 등 indirect injection 표면을 읽고 같은 컨텍스트에서 도구를 호출할 때.
- 요약·번역·분류 같은 "데이터 처리"와 "행동" 단계를 명확히 나눌 수 있는 워크플로.
- 시스템 프롬프트만으로는 신뢰 경계가 무너지는, 자율도 높은 어시스턴트.

### 어떻게
- 입력 라우팅: 사용자 메시지·승인된 시스템 지시만 P-LLM에 들어감. P-LLM은 도구 호출과 다음 단계 계획을 결정.
- untrusted 콘텐츠는 Q-LLM이 처리. Q-LLM은 도구·외부 호출 권한 없음. "go rogue at any moment"를 가정하고 설계.
- Controller(일반 코드)가 Q-LLM의 출력을 변수 토큰(`$VAR_42`)으로만 보관, **원문 텍스트는 절대 P-LLM 프롬프트에 합치지 않음**. P-LLM은 토큰만 보고 "$VAR_42를 누구에게 보내라" 같은 지시를 내림.
- 사용자에게는 Controller가 토큰을 원문으로 치환해 표시.

### 트레이드오프
- 장점: 가장 단순하면서도 "untrusted 토큰이 P-LLM 결정에 절대 닿지 않는다"는 명확한 경계 제공.
- 단점: Willison 본인이 인정하듯 "implementation complexity and a degraded user experience" — 두 LLM·중간 코드·UX 마찰 모두 증가. P-LLM이 Q-LLM 출력의 의미를 보지 못하므로 복잡한 협업 태스크에서 표현력이 떨어짐.
- 우회 위험: 사용자가 untrusted 데이터를 직접 복붙하면 신뢰 경계 붕괴. CaMeL 논문은 Q-LLM 출력이 "어떤 변수를 어떻게 쓸지"의 제어 흐름에 영향을 주면 여전히 injection 가능함을 지적.

### 출처
- [The Dual LLM pattern for building AI assistants that can resist prompt injection — Simon Willison (2023.04.25)](https://simonwillison.net/2023/Apr/25/dual-llm-pattern/) — Privileged/Quarantined 분리, Controller 변수 토큰 메커니즘, 한계 자평.

---

## 15. CaMeL — capability 기반 권한 분리

### 무엇
Google DeepMind가 Dual-LLM의 한계를 보완해 제안한 방어 모델. P-LLM이 사용자 요청을 Python 유사 코드로 변환하고, custom 인터프리터가 데이터의 출처·신뢰도를 capability(메타데이터 태그)로 추적해 도구 호출 시 정책을 결정적으로(probabilistic 아님) 강제한다.

### 언제
- Dual-LLM에선 구분 안 되는 "untrusted 데이터가 제어 흐름에 영향" 케이스(예: 이메일 본문이 어느 주소로 보낼지를 결정)를 막고 싶을 때.
- 강한(provable) 보장이 필요한 고위험 에이전트 — 결제, 파일 삭제, 외부 API 호출.
- AgentDojo류 적대 벤치마크에서 검증된 방어를 도입하려는 팀.

### 어떻게
- P-LLM이 자연어 요청 → Python 유사 코드로 변환. 데이터 흐름과 제어 흐름을 코드 구조로 분리.
- Q-LLM은 untrusted 콘텐츠 파싱(예: 이메일에서 주소 추출)만 수행. 결과 값에는 출처 capability가 붙음.
- custom 인터프리터가 코드 실행 시 각 변수의 capability(예: `source=email_body`, `tainted=true`)를 추적하고, 도구 호출 인자가 정책을 위반하면(예: tainted 주소로 송금) 차단·사용자 승인 요구.
- 오픈소스로 공개(Google Research GitHub).

### 트레이드오프
- 장점: 결정적(Probabilistic 아님) "strong guarantees" — Willison이 "the first mitigation offering strong guarantees"라 평가. AgentDojo에서 정책 위반 차단하면서 task success 77%(방어 없을 때 84%) 유지.
- 단점: 7%p 성공률 하락, 정책 작성·유지 비용, 사용자 결정 피로(잦은 승인 프롬프트). 자연어 → 코드 변환이 가능한 태스크에 한정.
- 우회 위험: 논문 저자도 "prompt injection attacks are not fully solved" 명시. 정책 자체가 잘못 짜이면 무효, capability 전파 누락 시 우회 가능.

### 출처
- [CaMeL: Defeating Prompt Injections by Design (arxiv 2503.18813)](https://arxiv.org/abs/2503.18813) — DeepMind, AgentDojo에서 77% task success, 결정적 capability 시스템.
- [CaMeL offers a promising new direction — Simon Willison (2025.04.11)](https://simonwillison.net/2025/Apr/11/camel/) — Dual-LLM 한계 지적과 P-LLM/Q-LLM + 인터프리터 구조 분석.

---

## 16. Permission mode 그라디언트 (gradient autonomy)

### 무엇
에이전트의 자율도를 단일 on/off가 아니라 단계화된 모드로 노출해(읽기 전용 → 편집 자동승인 → 모든 도구 우회), 작업 위험도와 환경(로컬·CI·컨테이너)에 맞춰 사용자가 신뢰 경계를 명시 선택하게 하는 UX 패턴.

### 언제
- 같은 에이전트를 탐색·계획·구현·무인 CI 등 다양한 위험도 컨텍스트에서 재사용할 때.
- 조직 정책으로 "프로덕션 레포는 plan만, 샌드박스는 bypass 허용" 같은 분기 통제가 필요할 때.
- 신규 사용자에게 안전한 디폴트를 주고, 숙련 사용자에겐 escape hatch를 제공해야 할 때.

### 어떻게 — Claude Code 4단계
- **default**: 표준 권한. 보호 경로 쓰기·쉘 명령마다 프롬프트.
- **plan**: 모델이 파일 읽기·쉘 탐색은 가능하지만 소스 편집·파괴적 호출은 금지. "research and propose changes without making them."
- **acceptEdits**: 파일 편집·쓰기 도구만 자동 승인(쉘 명령 등 비편집 도구는 여전히 프롬프트). git diff로 사후 리뷰하는 워크플로 전제.
- **bypassPermissions**: 모든 권한 프롬프트 스킵. `.git`·`.claude`·`.vscode`·`.idea`·`.husky` 쓰기까지 허용. 단 root·home 삭제는 회로 차단기로 여전히 프롬프트. 공식 문서는 "no protection against prompt injection or unintended actions"이며 컨테이너·VM에서만 사용하라고 경고.
- 디폴트 고정: `settings.json`의 `"defaultMode": "acceptEdits"` 등으로 환경별 강제. 모드 위에 allow/deny 룰을 더 얹어 도구 단위 미세 조정 가능(bypass 제외).

### 트레이드오프
- 장점: 위험도-자율도 매칭, plan 모드로 "읽기만 하는 리뷰 에이전트" 등 안전 디폴트 구현 용이. acceptEdits로 승인 피로 감소.
- 단점: 모드 의미를 사용자가 정확히 이해해야 안전 — 잘못 누른 bypass가 호스트 손상으로 직결. 모드와 별개로 도구·MCP가 자체 권한을 가지므로 정책이 분산됨.
- 우회 위험: bypassPermissions는 prompt injection 방어 0. 컨테이너 격리·egress 화이트리스트(패턴 11·12)와 결합하지 않으면 사실상 RCE 표면. acceptEdits에서도 모델이 `package.json`·`.husky` 같은 트리거 파일을 편집해 다음 쉘 호출을 선점할 수 있음.

### 출처
- [Choose a permission mode — Claude Code Docs](https://code.claude.com/docs/en/permission-modes) — default/plan/acceptEdits/bypassPermissions 4단계 정의.
- [Claude Code settings — defaultMode](https://code.claude.com/docs/en/settings) — `"defaultMode"` 설정으로 환경별 디폴트 강제.

---

## 17. Halting condition & max iterations

### 무엇
에이전트 루프에 **명시적 종료 조건**과 **상한선(max steps)**을 강제로 박는다. "도구 호출이 더 없을 때 자연스럽게 끝난다"에만 의존하지 않는다.

### 언제
- 에이전트가 자율 모드(비대화형)로 실행될 때 — 사람이 매 턴 개입하지 않으므로 잘못된 종료 조건은 곧 비용 폭주.
- 도구 호출 결과가 비결정적이거나(외부 API 의존), 모델이 작업을 마쳤음에도 "한 번 더 확인"을 반복하는 패턴이 관찰될 때.
- 토큰 비용·실시간 응답이 SLA로 걸려 있을 때.

### 어떻게

다층 종료 조건을 stack 한다 (먼저 만족하는 것이 종료 사유로 기록됨):

```python
def should_halt(state) -> tuple[bool, str]:
    if state.last_response.tool_calls == []:
        return True, "no_tool_calls"          # 모델 자연 종료
    if state.last_response.stop_signal:
        return True, "explicit_stop"          # finish/done 도구 호출
    if state.step >= MAX_STEPS:
        return True, "max_steps"              # 상한
    if state.tokens_used >= TOKEN_BUDGET:
        return True, "token_budget"           # 비용 가드
    return False, ""
```

**Graceful degradation** — 마지막 N step에 도달하면 "남은 step 안에 정리·요약하라"고 시스템 메시지를 주입해서 빈손 종료를 막는다. LangGraph의 기본 `recursion_limit`은 25; 초과 시 `GraphRecursionError`로 즉시 중단된다.

상한 기본값 가이드:
- LangGraph 기본 `recursion_limit = 25` (StateGraph가 stop 조건 도달 전에 step 한계 초과 시 에러).
- Anthropic "Building effective agents"는 구체 숫자 없이 *"stopping conditions (such as a maximum number of iterations)"*를 위험 허용도에 맞춰 설정하라고만 지침.

### 트레이드오프
- 상한이 너무 낮으면 정당한 장기 작업이 잘림 — 도메인별 튜닝 필요. 너무 높이면(1,000+) 무한 루프 시 그저 더 비싼 청구서.
- "no_tool_calls" 종료에만 의존하면, 모델이 "다 됐다"고 거짓 선언하면서 끝내는 실패 유형 ②(조기 완료 선언)에 취약 — 패턴 5(One-shot trap avoidance)와 결합 필요.
- Graceful degradation 메시지를 너무 일찍 주입하면 작업이 짧게 끝나는 쪽으로 편향.

### 출처
- [Building effective agents](https://www.anthropic.com/research/building-effective-agents) — *"it's also common to include stopping conditions (such as a maximum number of iterations) to maintain control."*
- [LangGraph GRAPH_RECURSION_LIMIT](https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT) — 기본 25 step, 초과 시 명시적 에러 throw.
- [AutoGPT Issue #1994 — "Gets stuck in a loop"](https://github.com/Significant-Gravitas/AutoGPT/issues/1994) — continuous mode에서 동일 쿼리 반복 실행, 종료 조건 부재가 노출시킨 결함 사례.

---

## 18. 무한 루프·반복 도구 호출 탐지

### 무엇
직전 N step의 도구 호출 시그니처를 비교해 **동일/유사 호출의 연속 반복**을 자동 차단한다. 모델이 "한 번 더 검색해볼게요"를 무한 반복하는 실패 유형을 step 상한에 도달하기 전에 끊는다.

### 언제
- 자율 에이전트가 동일 검색·동일 파일 읽기·동일 명령을 반복 호출하는 패턴이 로그에 남을 때 (AutoGPT가 동일 Google 쿼리를 분 단위로 반복한 사례가 대표적).
- max_iterations만으로 막으려니 비용이 너무 큰 경우 — 25 step × 큰 컨텍스트면 이미 충분한 손실.
- 도구가 멱등(idempotent)이라 반복 호출이 새로운 정보를 주지 않음이 명백할 때.

### 어떻게

**시그니처 기반 탐지** — 도구 이름 + 정규화한 인자의 해시를 큐에 쌓고, 최근 N개에서 같은 시그니처가 K회 이상 등장하면 차단:

```python
from collections import deque
RECENT = deque(maxlen=5)

def signature(call) -> str:
    return f"{call.name}:{hash(canonicalize(call.args))}"

def detect_loop(call) -> bool:
    sig = signature(call)
    RECENT.append(sig)
    return RECENT.count(sig) >= 3   # 최근 5턴 중 3번 동일 → 루프
```

차단 시 에이전트에게 단순 차단이 아니라 **피드백 메시지**를 주입한다: *"같은 도구 호출을 반복하고 있다. 새로운 정보가 들어오지 않으니 다른 접근을 시도하거나 finish 도구로 종료하라."* 이 메시지가 다음 턴 컨텍스트에 들어가야 모델이 행동을 바꾼다.

**의미적 루프 탐지(고도화)** — 인자가 살짝 다르지만 의도가 같은 경우 (예: "low tax countries" / "countries with low taxes"). 임베딩 유사도 ≥ 0.95를 추가 시그널로 쓴다. 비용·지연 트레이드오프 있음 — 핫패스에는 부담.

### 트레이드오프
- 멱등이지만 **정당한 재시도**(네트워크 일시 장애 후 재시도)도 차단될 수 있음 — 에러 응답이 끼어 있는 retry는 시그니처에서 제외하는 예외 규칙 필요.
- 임계값 K가 너무 작으면 false positive로 정상 흐름이 끊긴다. K=3, window=5가 출발점으로 무난하나 도메인별 튜닝 필요(추측).
- 의미적 루프 탐지는 임베딩 호출 비용·지연이 매 턴 추가되므로 고비용 자율 세션에만 도입.

### 출처
- [AutoGPT Issue #1994](https://github.com/Significant-Gravitas/AutoGPT/issues/1994) — *"It loops the same queries although it successfully got the google results."* 메모리·루프 탐지 부재가 production agent에 일으킨 실패.
- [Building effective agents](https://www.anthropic.com/research/building-effective-agents) — autonomous agent의 *"compounding errors"* 위험과 sandboxed testing·guardrail 권장.

---

## 19. Self-critique 횟수 튜닝

### 무엇
Reflexion·Self-Refine류의 자기비평 루프를 몇 번 돌릴지를 **데이터로 정한다**. "많을수록 좋다"는 근거 없는 가정을 버리고, 작업별 품질-비용 곡선을 측정해 정지점을 결정한다.

### 언제
- Generator-Evaluator 분리(패턴 6)를 이미 적용했고, evaluator 통과율을 더 끌어올리려는 단계.
- 자기비평이 토큰 비용을 N+1배로 키우는데 품질 향상이 측정되지 않을 때.
- 동일 작업에서 critique 후에도 같은 결함이 남는 패턴이 반복될 때.

### 어떻게

**1단계 — 곡선 측정.** 동일 입력에 대해 critique 횟수를 0, 1, 2, 3, 4로 변화시키며 evaluator 점수와 누적 토큰 비용을 기록한다. Self-Refine 논문은 *"Most gains are in the initial iterations"*임을 코드 최적화·감정 반전 실험에서 보고했다 — 첫 1~2회에서 큰 폭, 이후 평탄.

**2단계 — 임계 규칙.**

```python
def stop_critique(scores: list[float], k: int = 1) -> bool:
    if len(scores) < 2: return False
    delta = scores[-1] - scores[-2]
    return delta < EPSILON or len(scores) >= MAX_CRITIQUE  # 통상 3~4
```

평균적으로 Reflexion이 AlfWorld에서 *"performance increase halts between trials 6 and 7"*을 보였다는 보고가 있고, 메모리 버퍼 크기 Ω도 *"usually set to 1–3"*이다. 무제한이 아니라 이 범위가 합리적 출발점.

**3단계 — task type별 default 분리.** 코드 작성·테스트 fix처럼 객관 평가 가능한 작업은 평가자가 통과시킬 때까지 (보통 2~3회로 수렴). 자유서술·디자인 평가는 더 많은 critique이 통계적으로 유의하지 않을 때가 잦으므로 1~2회로 캡.

### 트레이드오프
- 비용은 critique 횟수에 거의 선형으로 증가 — Generator+Evaluator는 단일 호출 대비 ~20× (Anthropic harness-design 보고). critique 추가는 그 위에 곱연산.
- 잘못 설계된 evaluator는 과적합을 일으킨다 — critique를 돌수록 rubric에 맞춰 휘면서 실제 사용성이 떨어지는 방향으로 수렴할 수 있음.
- "곡선이 평탄해지면 멈춘다"가 항상 옳지는 않다 — 일부 작업은 후반에 점프가 있다는 보고도 있어, MAX_CRITIQUE를 조기 종료가 아닌 안전망으로만 쓰는 보수적 셋팅이 안전.

### 출처
- [Reflexion: Language Agents with Verbal Reinforcement Learning (arxiv 2303.11366)](https://arxiv.org/abs/2303.11366) — AlfWorld 12 trial, 메모리 Ω 1–3 권장.
- [Self-Refine: Iterative Refinement with Self-Feedback (arxiv 2303.17651)](https://arxiv.org/abs/2303.17651) — *"Most gains are in the initial iterations"*, ~20% 평균 향상의 대부분이 1~2회 critique에 집중.
- [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) — Generator+Evaluator 분리의 ~20× 비용 프리미엄.

---

## 패턴 선택 가이드

| 증상 | 적용할 패턴 |
|---|---|
| 에이전트가 deprecated 코드를 계속 호출 | 패턴 4 → 패턴 1 (컨텍스트에 명시) |
| 명시했는데도 위반을 반복 | 패턴 2 (기계적 강제) |
| 기술 부채가 쌓이고 아무도 안 건드림 | 패턴 3 (자동 수거 파이프라인) |
| 세션 중간에 품질이 급락 | 패턴 5 (청크 분해 + 핸드오프) |
| 산출물이 "그럭저럭"에서 벗어나지 않음 | 패턴 6 (Evaluator 분리, 비용 감수) |
| 에이전트가 비슷한 도구 중 잘못된 쪽을 고름 | 패턴 7 (description 재작성) → 패턴 8 (도구 통합·동적 로딩) |
| 도구 description만으로 컨텍스트가 포화 | 패턴 8 (Code execution / JIT 노출) |
| MCP 응답이 ID·메타데이터로 채워짐 | 패턴 9 (high-signal 설계) → 패턴 10 (오프로딩) |
| `bypassPermissions`로 자율 실행하고 싶음 | 패턴 11 (샌드박스) + 패턴 12 (egress) + 패턴 16 (mode 그라디언트) 동시 |
| 시크릿이 컨텍스트·커밋에 노출 | 패턴 13 (gitleaks 다층) |
| 외부 콘텐츠를 읽고 도구 호출하는 워크플로 | 패턴 14 (Dual-LLM) → 고위험이면 패턴 15 (CaMeL) |
| 에이전트가 동일 도구 호출을 반복 | 패턴 18 (시그니처 탐지) → 패턴 17 (max_iterations 안전망) |
| critique 횟수가 비용만 키우고 품질은 정체 | 패턴 19 (곡선 측정 후 임계값) |
