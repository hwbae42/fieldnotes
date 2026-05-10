# 코딩 에이전트 친화적인 코드베이스 — 개요

> 조사 시점: 2026-05-10. 출처는 [`references.md`](./references.md).
> 구체적 패턴은 [`patterns.md`](./patterns.md).

---

## 왜 "에이전트 친화적"인가

코딩 에이전트(Claude Code, Codex CLI, Cursor agent 등)는 일반 IDE 사용자와 다음 세 가지 점에서 다르게 동작한다.

1. **컨텍스트가 비싸고, 차면 망가진다.**
   Claude Code 공식 문서는 본인들의 베스트 프랙티스 전체가 "Claude's context window fills up fast, and performance degrades as it fills"라는 한 줄 제약 위에 서 있다고 명시한다. 사람이 IDE에서 파일을 열어보는 비용은 사실상 0이지만, 에이전트가 같은 파일을 Read하면 수백~수천 토큰의 영구 점유가 발생하고, 대화가 길어질수록 앞쪽 지시가 잊히기 시작한다.

2. **암묵적 컨벤션을 못 읽는다.**
   사람 신입은 `BillingService` 옆 `BillingProcessor`가 사실상 deprecated라는 걸 동료가 한마디 해주거나 git blame을 보고 안다. 에이전트는 둘 다 자신감 있게 grep해서 잘못된 쪽을 호출한다. Stack Overflow Blog(2026-03)는 이를 "agents don't run on vibes"로 정리한다 — 사람의 tacit knowledge에 의존하는 부분이 모두 명시화되어야 한다.

3. **유사하지만 미묘하게 다른 개념에서 쉽게 무너진다.**
   "doom loops" 분석(Amazing CTO)은 `CustomerID` vs `CustomerNo`, JET 템플릿 vs Go 템플릿처럼 한 도메인에 닮은 개념이 공존하면 LLM이 둘을 섞어 쓰기 시작하고, 수정 시도가 더 큰 혼란을 만들고, 결국 모든 변경을 되돌리거나 테스트가 빨갛게 떠도 "끝났다"고 선언한다.

따라서 "사람이 읽기 좋은 코드"와 "에이전트가 다루기 좋은 코드"는 90%는 겹치지만, 10%는 다르다. 그 10%가 본 문서의 주제다.

---

## 핵심 메커니즘 지도

Claude Code 기준의 확장점을 한 장으로 보면 다음과 같다. 다른 에이전트(Codex, Cursor 등)도 비슷한 카테고리를 갖지만 명칭과 세부 동작이 다르다.

| 메커니즘 | 무엇을 하나 | 위치 / 포맷 | 언제 쓰나 |
|---|---|---|---|
| **메모리 파일** (CLAUDE.md / AGENTS.md / `.cursorrules` / `.github/copilot-instructions.md`) | 매 세션 시작 시 모델 컨텍스트에 자동 주입되는 영구 지시 | 프로젝트 root + 부모/자식 디렉토리 + `~/.claude/CLAUDE.md` | 빌드/테스트 명령, 코드 스타일, 도메인 용어, "절대 하지 말 것" |
| **Permissions** | 어떤 도구를 무프롬프트로 허용/거부할지 결정 | `.claude/settings.json`, `.claude/settings.local.json`, `~/.claude/settings.json` | 안전한 명령은 자동 허용, 위험한 건 명시 차단 |
| **Hooks** | 특정 lifecycle 시점에 사용자 스크립트를 결정적으로 실행 | `settings.json`의 `hooks` 키 | "edit 후 항상 lint", "테스트 빨가면 종료 못 함" 같은 강제 사항 |
| **Slash commands / Skills** | 반복 워크플로를 한 단어로 호출 가능한 단위로 추상화 | `.claude/skills/<name>/SKILL.md` (또는 `.claude/commands/`) | `/deploy`, `/fix-issue 1234`, `/security-review` |
| **Subagents** | 별도 컨텍스트 윈도우에서 격리된 작업 실행 | `.claude/agents/<name>.md` (YAML frontmatter + 시스템 프롬프트) | 큰 출력을 만들거나 특정 권한이 필요한 작업, 장시간 탐색 |
| **MCP servers** | Claude Code를 외부 시스템(이슈 트래커, DB, Figma, Slack 등)에 연결 | `.mcp.json` (project) / `~/.claude.json` (user) | "코드 → 채팅에 붙여넣기"를 반복하는 모든 흐름 |

이 표의 항목들은 **서로 다른 layer를 담당**하는 게 핵심이다. CLAUDE.md는 "advisory"(지시) 이고, hooks는 "deterministic"(강제)다. CLAUDE.md에 "테스트 돌려"라고 써도 모델이 잊을 수 있지만, Stop hook으로 테스트 실패 시 `decision: "block"`을 반환하면 모델은 못 끝내고 계속 작업한다. Anthropic 공식 best-practices가 이 점을 콕 짚어 강조한다: *"Use hooks for actions that must happen every time with zero exceptions."*

---

## AGENTS.md 표준의 등장 배경

2025년 중반까지 각 에이전트 도구는 자기만의 메모리 파일 컨벤션을 밀고 있었다.

- Claude Code: `CLAUDE.md`
- Cursor: `.cursorrules` → 이후 `.cursor/rules/*.mdc`
- GitHub Copilot: `.github/copilot-instructions.md`
- Aider, Zed, Continue 등은 각자 자기 파일

같은 프로젝트에서 여러 도구를 쓰면 동일한 "build/test/style" 정보를 N벌 유지해야 했다. 이 비대칭을 해소하기 위해 **OpenAI Codex, Google Jules, Cursor, Factory, Sourcegraph가 공동으로 AGENTS.md** 라는 단일 표준을 발표했고, 현재 Linux Foundation 산하 Agentic AI Foundation이 stewardship을 가져갔다(agents.md 공식 페이지).

AGENTS.md 사이트 기준 60,000+ OSS 프로젝트가 채택했고, 지원 도구는 OpenAI Codex, Cursor, Jules, Gemini CLI, Aider, Zed, Warp, JetBrains Junie, Devin, Windsurf 등이다. Claude Code는 native로 CLAUDE.md를 읽지만 AGENTS.md를 fallback으로 사용한다.

**실용 결론** (DeployHQ 비교 글 + Crosley AGENTS.md patterns의 일치된 권고):
> 단일 source of truth으로 **AGENTS.md**를 두고, Claude-only 기능(import 구문, hooks, skills 연동)이 필요할 때만 CLAUDE.md를 추가. CLAUDE.md에서 `@AGENTS.md` import로 중복을 피한다.

본 fieldnotes 자체도 이 원칙을 따라가는 게 좋다 — 새 프로젝트 시작 시 AGENTS.md부터 만들고, Claude-specific 항목만 CLAUDE.md로 분리.

---

## 메모리 파일 포맷 비교 한 장 정리

| 항목 | AGENTS.md | CLAUDE.md | `.cursor/rules/*.mdc` | `.github/copilot-instructions.md` |
|---|---|---|---|---|
| 소유 도구 | 멀티 (Codex, Cursor, Jules, Aider, Zed, Claude Code 등 60+ OSS 채택) | Claude Code | Cursor | GitHub Copilot |
| 파일 위치 | 프로젝트 root + 디렉토리 트리 | 프로젝트 root + `~/.claude/` + 부모/자식 디렉토리 | `.cursor/rules/` 디렉토리 | `.github/copilot-instructions.md` |
| 다중 파일 모드 | nested AGENTS.md (자식 우선) | nested CLAUDE.md (자동 합산) | `.mdc` 파일들 + activation modes | `.github/instructions/*.instructions.md` (path-specific) |
| Frontmatter | (표준 자체엔 없음, 도구별 확장) | 자체 마크다운 + `@import` | YAML frontmatter (`alwaysApply`, `globs` 등) | YAML frontmatter (`applyTo`, `excludeAgent`) |
| Activation modes | (전역 + nearest) | (자동 + on-demand) | Always / Auto Attached / Agent Requested / Manual | Path-glob 또는 always |
| Local override | 도구별 (Codex의 `AGENTS.override.md` 등) | `CLAUDE.local.md` (gitignore 권장) | `.cursor/rules/*.mdc` 자체 | (없음) |
| 권장 길이 | ~수백 줄, 패키지마다 분리 | < 300줄 (HumanLayer), 공식은 "concise" | 룰별 분리, 한 파일 짧게 | "concise"만 명시 |

핵심 시사점:
- **표준 vs native** 트레이드오프. AGENTS.md는 가장 넓게 작동하지만 도구 고유 기능(예: Claude의 `@import`, Cursor의 activation mode)을 놓친다.
- **path-scoping 방식**이 도구마다 다르다. Cursor는 `.mdc` frontmatter, Copilot은 `instructions/*.instructions.md`, Claude Code는 nested CLAUDE.md + skills의 `paths` frontmatter. 의미는 비슷하지만 동작이 다르므로 monorepo에서는 도구별로 검증 필요.
- **`CLAUDE.local.md`**는 Anthropic 공식이 명시한 "팀과 공유하지 않는 개인 노트" 슬롯. AGENTS.md 표준엔 동등 기능이 없어서 도구별 확장(`AGENTS.override.md` 등)으로 대체.

---

## 계층 구조 (monorepo / 멀티 패키지)

AGENTS.md, CLAUDE.md 모두 **"가장 가까운 파일이 이긴다(nearest wins)"** 원칙을 따른다. 정확한 동작은 도구별로 미묘하게 다르다.

- **AGENTS.md** (agents.md 공식): 작업 중인 파일 위치에서 위로 디렉토리 트리를 올라가며 가장 가까운 AGENTS.md를 사용. 자식이 부모를 override.
- **CLAUDE.md** (Anthropic 공식 best-practices): 부모 디렉토리의 CLAUDE.md는 자동으로 합쳐지고(`root/CLAUDE.md` + `root/foo/CLAUDE.md`), 자식 디렉토리 CLAUDE.md는 그 디렉토리 파일을 다룰 때 on-demand로 pull-in. 즉 **합산형**에 가까움.
- **Codex 확장**: `AGENTS.override.md`는 부모 지시를 부분 교체가 아니라 완전 대체(릴리스 동결, 보안 인시던트 시 사용). 표준 일부가 아닌 Codex 확장.

monorepo 권장:
- root에 "전 패키지에 보편적인" 룰만 둠 (어떤 언어/런타임을 쓰는지, lint/test 명령은 어디 있는지, "secrets 커밋 금지" 같은 hard rule).
- 각 `packages/*` 또는 `services/*`에 자체 AGENTS.md/CLAUDE.md를 두고 그 패키지 고유의 빌드 명령, 디자인 패턴, deprecated 모듈 경고 등을 기록.
- root 한 파일에 모든 패키지를 쑤셔 넣으면 (a) 컨텍스트 폭발, (b) 잘못된 패키지 컨벤션 적용 — 이는 The Prompt Shelf의 monorepo 가이드가 명시적으로 경고하는 안티패턴.

---

## 큰 원칙 (모든 패턴이 이 셋으로 환원됨)

### 1. 명시성 > 암묵성

사람에게는 자연스러운 단서가 에이전트에게는 노이즈거나 오정보다.

- "코드 스타일은 보면 알아요"가 아니라 → 실제 모범 파일을 가리킨다 (`copy patterns from app/components/DashForm.tsx`).
- "테스트는 알아서"가 아니라 → 명령 그대로 적는다 (`pnpm vitest run path/to/file.test.ts`).
- "deprecated 모듈은 손대지 마"가 아니라 → 디렉토리 단위로 named (`Never edit src/legacy/**, edit src/v2/** instead`).
- 명명 규칙은 **단어 단위로** 적는다. `CustomerID`인지 `CustomerNo`인지를 직접 명시. 두 개가 공존한다면 그 자체가 에이전트 함정이라 리팩토링 후보로 등록.

### 2. 확인 가능성 (verifiability)

Anthropic 공식 best-practices가 *"the single highest-leverage thing you can do"*라고 부르는 항목.

- 테스트 명령이 있고, 그 명령이 빠르게 통과/실패 신호를 준다.
- 린터가 있고, 에이전트가 자기 변경 후 자동으로 돌릴 수 있다 (PostToolUse hook).
- "성공 = exit code 0인 N개 명령 통과"로 정의되면 에이전트가 자기 일을 self-correct할 수 있다.
- 검증 불가능한 변경은 에이전트에게 맡기지 않는 게 낫다 — "보기엔 멀쩡한데 안 되는" 결과가 가장 위험.

### 3. 격리 (isolation)

큰 컨텍스트, 위험한 권한, 이질적 도메인은 메인 세션에서 떼어낸다.

- **컨텍스트 격리**: 거대한 grep, 로그 분석, 문서 탐색은 subagent에서 → 결과 요약만 부모로 복귀.
- **권한 격리**: 위험한 도구(예: `Bash(rm *)`, `git push *`)는 deny 또는 ask. 에이전트별로 `tools` 화이트리스트.
- **변경 격리**: `isolation: worktree`를 단 subagent는 임시 git worktree에서 일해서 메인 작업 트리를 더럽히지 않음. 변경이 없으면 자동 청소.

이 셋이 전부다. 다음 문서([patterns.md](./patterns.md))의 12개 패턴은 모두 이 세 원칙 중 하나(또는 둘)의 구체화다.

---

## 본 fieldnotes에 가져다 쓰는 관점

새 프로젝트에 적용할 때 권장 순서:

1. **AGENTS.md 먼저, 50줄 이내**. 빌드/테스트 명령 + 핵심 don'ts + 디렉토리 지도. 이 파일은 사람도 읽는다는 전제로.
2. **`.claude/settings.json`에 최소 permissions allowlist**. 가장 자주 호출되는 read-only 명령들(자기 프로젝트의 `pnpm test`, `cargo check`, `gh issue *` 등)을 allow에 넣어 프롬프트 피로 줄이기. 위험한 건 deny 또는 ask.
3. **PostToolUse hook으로 lint/typecheck 자동화**. CLAUDE.md에 "lint 돌려"라고 적는 대신 결정적으로 강제.
4. **반복 워크플로가 보이면 SKILL.md로 추상화**. `/fix-issue`, `/security-review`, `/release` 같은 단위.
5. **컨텍스트가 자주 폭발하는 작업이 있으면 subagent로 분리**. "탐색"·"리뷰"·"마이그레이션" 같은 본질적으로 큰 작업.
6. **외부 시스템 의존이 반복되면 MCP server**. Notion, Sentry, Postgres, GitHub 등.

각 단계의 구체 패턴은 [patterns.md](./patterns.md)에 있다.

---

## 모르는/확인 안 된 부분

- 본 문서가 다루는 메커니즘 대부분은 Claude Code 기준이다. Codex CLI, Cursor agent에도 유사 기능이 있지만 "permission mode 매트릭스"나 "hook lifecycle event 전체 목록"같은 세부는 도구마다 다르다 — 본 fieldnotes는 Claude Code를 1차로, AGENTS.md 표준에 해당하는 부분만 cross-tool로 작성했다.
- "monorepo가 multirepo보다 에이전트 친화적인가"에 대한 정량 데이터는 못 찾았다. patterns.md에서는 정성적 권고로만 다룬다.
- CLAUDE.md 권장 길이("< 300 lines"는 HumanLayer 권고이고 Anthropic 공식은 줄 수 명시 없음)는 출처에 따라 갈린다 — 본 문서는 둘 다 인용하되 단정짓지 않는다.
