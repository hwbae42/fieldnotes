# 코딩 에이전트 친화적인 코드베이스 — 패턴

> 조사 시점: 2026-05-10. 출처는 [`references.md`](./references.md). 개념적 배경은 [`overview.md`](./overview.md).
>
> 각 패턴 형식: **무엇 / 언제 / 어떻게 / 트레이드오프 / 출처**.
> 모든 코드 예시는 출처에서 검증한 형식만 사용. 출처 없는 내 추측은 "추측"으로 명시.

---

## 1. AGENTS.md를 단일 source of truth로 두기

### 무엇
프로젝트당 하나의 메모리 파일을 AGENTS.md로 두고, Claude Code 같은 도구별 파일(CLAUDE.md)은 도구 고유 기능만 담거나 AGENTS.md를 import한다. 이를 통해 빌드/테스트/스타일 같은 공통 컨벤션을 N벌 유지하지 않는다.

### 언제
- 한 프로젝트에서 두 개 이상의 코딩 에이전트(예: Claude Code + Codex, 또는 Claude Code + Cursor)를 쓸 때.
- 팀원마다 도구가 다른 OSS 프로젝트.
- 단 하나의 도구만 쓸 거고 그게 평생 안 바뀔 거라고 100% 확신하면 그 도구의 native 파일(`CLAUDE.md`)만 써도 된다 — 그러나 OSS라면 외부 기여자를 위해 AGENTS.md를 권장.

### 어떻게

루트에 `AGENTS.md` 두고 Claude Code용 CLAUDE.md는 다음과 같이 import만:

```markdown
# CLAUDE.md
@AGENTS.md

# Claude-specific overrides
- Use the `@my-team/lint-config` MCP server for project-wide linting
- Prefer the security-reviewer subagent for any auth-related changes
```

CLAUDE.md의 `@path/to/import` 구문은 Anthropic 공식 best-practices가 명시적으로 지원하는 문법이다.

### 트레이드오프
- AGENTS.md는 표준이지만 Claude-specific 기능(import, path-scoped rules, hooks 연동)이 빈약하다. Claude Code의 native 기능을 적극 쓸 거면 분리 비용을 받아들여야 한다.
- 두 파일 동기화 부담은 거의 없다 — Claude Code는 CLAUDE.md를 *우선*하고 fallback으로만 AGENTS.md를 본다. 따라서 AGENTS.md를 truth로 두고 CLAUDE.md는 import + 추가만 하는 구조면 한쪽만 갱신해도 충분.

### 출처
- agents.md 공식 (#7) — AGENTS.md 표준 정의 및 60K+ 채택 사례.
- DeployHQ 비교 글 (#15) — *"Maintain one source of truth (AGENTS.md) and have tool-specific files reference it."*
- Anthropic best-practices (#1) — `@import` 구문.

---

## 2. 메모리 파일 구성: WHAT / WHY / HOW + 6 섹션

### 무엇
메모리 파일(AGENTS.md/CLAUDE.md)을 쓸 때 따라야 할 구조. 단순히 "프로젝트 설명"이 아니라, 에이전트가 작업 시작 직후에 *바로* 쓸 수 있는 형태로 정렬한다.

### 언제
모든 에이전트 친화적 프로젝트의 출발점. 파일이 없으면 다른 모든 패턴이 의미 없음.

### 어떻게

**3-section framework** (HumanLayer + uxplanet 권고의 합집합):
- **WHAT**: 스택, 디렉토리 지도, 버전. *"React 18 + TypeScript + Vite + Tailwind CSS"*처럼 구체적 버전까지.
- **WHY**: 프로젝트의 목적, 디렉토리별 책임. 이 부분이 없으면 에이전트가 잘못된 추상화를 만든다.
- **HOW**: 빌드, 테스트, 린트의 *정확한 명령*. "Use bun, not node" 같은 환경 결정.

**GitHub Blog의 2,500 리포지토리 분석으로 검증된 6가지 핵심 섹션**:
1. Commands (가장 위에 두기 — 가장 자주 참조됨)
2. Testing practices
3. Project structure
4. Code style examples (설명 X, **실제 코드 스니펫**)
5. Git workflow
6. Clear boundaries (always do / ask first / never do 3-tier)

**구체적 모범**:

```markdown
# Commands
- Install: `pnpm install --frozen-lockfile`
- Test (single file): `pnpm vitest run path/to/file.test.ts`
- Test (full): `pnpm test` — 단, 30초 이상 걸리니 가능하면 단일 파일.
- Lint: `pnpm lint` (eslint), `pnpm typecheck` (tsc --noEmit)
- Build: `pnpm build`

# A task is complete when
1. `pnpm typecheck` exits 0
2. `pnpm lint` exits 0
3. `pnpm vitest run` exits 0
4. New code has corresponding tests in `*.test.ts`

# Never do
- Never commit secrets. `.env*` 파일은 절대 커밋 금지.
- Never edit `src/legacy/**` — deprecated. 새 기능은 `src/v2/**`에서.
- Never use `npm` or `yarn` — 이 프로젝트는 `pnpm`만 사용.
```

### 트레이드오프
- 파일이 길어지면 모델이 무시하기 시작한다. HumanLayer는 자기네 root CLAUDE.md가 60줄 미만이라고 보고. Anthropic도 "300줄"보다는 "각 줄마다 *Would removing this cause Claude to make mistakes?*를 자문" 권고.
- *"Write clean code"* 같은 LLM이 이미 아는 자명한 룰을 적으면 정작 중요한 룰을 가린다.

### 출처
- HumanLayer "Writing a good CLAUDE.md" (#9) — 150-200 instruction 한계, "Never send an LLM to do a linter's job".
- GitHub Blog 2,500 repos 분석 (#10) — 6 섹션, "Never commit secrets" 가장 효과적.
- Builder.io AGENTS.md tips (#14) — "Examples beat abstractions".
- Anthropic best-practices (#1) — include/exclude 표.

---

## 3. "Closure definition": 완료 조건을 종료 코드로 명시

### 무엇
"task is complete when"을 *exit code 0인 명령 N개*로 정의한다. 추상적인 "잘 작동해야 함"이 아니라 검증 가능한 절차.

### 언제
- 에이전트에게 멀티스텝 작업을 시킬 때.
- 자율 모드(`--permission-mode auto` 또는 비대화형)에서 돌릴 때 특히 중요.

### 어떻게

AGENTS.md에 다음 섹션을 둔다:

```markdown
# Definition of done
A task is complete when ALL of the following pass:
1. `pnpm typecheck` exits 0
2. `pnpm lint` exits 0
3. `pnpm vitest run` exits 0
4. Manual verification per the PR checklist below
```

여기에 추가로 Stop hook(패턴 5 참고)을 걸어두면, 에이전트가 위 조건 미충족 시 종료를 차단할 수 있다.

### 트레이드오프
- 너무 엄격하면 에이전트가 본질적이지 않은 실패에 갇혀 무한 루프(예: 의존성 다운로드 실패가 명령 실패로 잡혀 영원히 retry).
- 명령에 의도된 실패(failing test 작성 후 fix 흐름)가 있으면 일시적으로 hook을 우회하는 escape hatch가 필요.

### 출처
- Crosley AGENTS.md patterns (#11) — "A task is complete when ALL of the following pass: ..." 예시.
- Anthropic best-practices (#1) — "Give Claude a way to verify its work."

---

## 4. Permissions allowlist: settings.json의 deny → ask → allow 평가 순서

### 무엇
Claude Code의 `settings.json`에 권한 룰을 적어 위험한 명령은 차단, 안전한 명령은 무프롬프트 통과시킨다.

### 언제
- 프로젝트마다 안전 명령(테스트, 빌드)이 다를 때 → project settings에 둠.
- 개인 패턴(자주 쓰는 `gh issue list` 같은 read-only 명령) → user settings에 둠.

### 어떻게

`.claude/settings.json` (팀 공유, git에 commit):

```json
{
  "permissions": {
    "allow": [
      "Bash(pnpm test*)",
      "Bash(pnpm typecheck)",
      "Bash(pnpm lint)",
      "Bash(pnpm vitest *)",
      "Bash(gh issue view *)",
      "Bash(gh pr view *)",
      "Read(./**)"
    ],
    "ask": [
      "Bash(git push *)",
      "Bash(pnpm install*)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git reset --hard *)",
      "Read(./.env*)",
      "Edit(./.env*)"
    ]
  }
}
```

핵심 규칙(공식 docs):
- **평가 순서: deny → ask → allow**. 첫 매칭이 이긴다. 그래서 deny가 절대적.
- **Bash 와일드카드**: `Bash(pnpm test*)`는 `pnpm test`, `pnpm test foo`, `pnpm test:e2e` 다 매칭. `Bash(pnpm test *)`(공백 있음)는 `pnpm test foo`는 매칭하지만 `pnpm test:e2e`는 안 됨(word boundary).
- **컴파운드 명령 인식**: `Bash(safe-cmd *)` 룰은 `safe-cmd && rm -rf /`를 통과시키지 않는다. `&&`, `||`, `;`, `|`, 줄바꿈은 분해되어 각 부분이 독립 매칭되어야 함.
- **read-only 명령은 자동 허용**: `ls`, `cat`, `head`, `tail`, `grep`, `find`, `wc`, `diff`, `stat`, `du`, `cd`, read-only `git`은 default allow. 따로 `allow`에 안 적어도 됨.

### 함정 (공식 docs가 명시적으로 경고)
- `Bash(curl http://github.com/ *)` 같은 URL 제약은 깨지기 쉽다. `curl -X GET http://github.com/...`, `https://...`, redirect 따라가는 `bit.ly`, 환경변수 `URL=... && curl $URL` 같은 변형이 다 매칭 실패. URL 제약은 PreToolUse hook이나 `WebFetch(domain:...)`로 해야 한다.
- `Bash(devbox run *)` 같은 환경 래퍼 룰은 `devbox run rm -rf .` 같은 위험 명령을 그대로 통과시킨다. process wrapper 화이트리스트(`timeout`, `time`, `nice`, `nohup`, `stdbuf`, `xargs`)에 포함된 것만 자동 stripping된다.

### 트레이드오프
- allowlist를 너무 자유롭게 두면 prompt injection 시 큰 사고 가능.
- 너무 엄격하면 사용자가 *허용 피로(approval fatigue)* 누적 → "10번째 클릭부턴 그냥 누른다" 상태가 됨. 공식 docs도 같은 현상을 경고.
- 절충: read-only 명령은 적극 allow, write/network 명령은 ask, 파괴적 명령은 deny.

### 출처
- Anthropic Configure permissions (#3).
- DeployHQ (#15) — 4종 비교에서 Claude의 차별점 중 하나로 강조.

---

## 5. PostToolUse hook으로 lint/typecheck 강제

### 무엇
파일이 편집될 때마다 lint/typecheck를 자동 실행. 실패하면 결과를 모델에게 컨텍스트로 주입해서 다음 턴에 self-correct하게 한다.

### 언제
- "edit 후엔 항상 X를 돌려"가 CLAUDE.md에 적혀 있는데도 모델이 종종 잊을 때.
- 빠른 정적 검사(typecheck, lint, format)가 있는 프로젝트.

### 어떻게

`.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/typecheck.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

`.claude/hooks/typecheck.sh`:
```bash
#!/usr/bin/env bash
set -e
output=$(pnpm typecheck 2>&1) || {
  jq -n --arg output "$output" '{
    decision: "block",
    reason: "Typecheck failed. Fix the errors before continuing.",
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $output
    }
  }'
  exit 0
}
exit 0
```

핵심:
- PostToolUse는 **이미 실행된 도구를 막을 수 없다** (이미 파일이 쓰였음). 하지만 `decision: "block"`을 반환하면 *다음 모델 턴*을 차단해서 에이전트가 강제로 fix 모드로 진입.
- exit code 2는 PostToolUse에서는 stderr만 보이고 차단 안 됨. JSON으로 `decision: "block"`을 명시해야 함.
- `additionalContext`로 lint 출력을 모델에 주입하면, 모델이 어떤 줄이 깨졌는지 바로 알고 수정 가능.

### 트레이드오프
- typecheck가 느린 프로젝트(모노레포 전체 tsc)에서는 매 edit마다 돌리면 마비. → 변경 파일만 검사하는 incremental tool 필요(예: `tsc --noEmit --incremental` 또는 affected packages만).
- 위양성(transient error, 의존성 미설치 등)이 잦으면 에이전트가 fix loop에 갇힘.
- 디버깅 어려움 — hook 출력은 사용자에게 노출이 제한적이다. `/hooks` 명령으로 등록 상태 확인 필요.

### 출처
- Anthropic Hooks reference (#2) — JSON 포맷, `decision: "block"`, `additionalContext`.
- Anthropic best-practices (#1) — *"Claude can write hooks for you. 'Write a hook that runs eslint after every file edit'"*.

---

## 6. Stop hook으로 "테스트 통과 전엔 못 끝낸다" 강제

### 무엇
에이전트가 작업을 끝내려 할 때마다 빌드/테스트를 돌려서 실패하면 종료를 차단한다. *"declaring victory before tests pass"*를 기술적으로 막는 강제.

### 언제
- 자율적 멀티스텝 작업이 자주 있는 환경.
- 사람이 매번 PR 검토할 여력이 없는 OSS / 야간 배치성 작업.

### 어떻게

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-done.sh",
            "timeout": 300
          }
        ]
      }
    ]
  }
}
```

`verify-done.sh`:
```bash
#!/usr/bin/env bash
if ! pnpm test --silent; then
  jq -n '{
    decision: "block",
    reason: "Tests are failing. Fix them before declaring done."
  }'
  exit 0
fi
exit 0
```

Stop hook에서 `decision: "block"`은 모델이 종료 못 하게 하고 다음 턴으로 돌입. 결과적으로 "테스트 통과까지 자동으로 계속 작업"하는 흐름.

### 트레이드오프
- 무한 루프 위험. 모델이 못 고치는 종류의 실패(환경 문제, 외부 의존)면 끝없이 회전. `maxTurns` 제한이나 retry 카운터 hook 안에 두는 게 안전.
- 사용자가 "여기서 멈춰, 내일 마저"하고 싶을 때도 강제됨 → 일시 disable 메커니즘 필요(`disableStopHook` 환경변수 등 — 출처에서 명시 없음, 확인 필요).
- exit code 2도 Stop hook에선 차단으로 해석됨. JSON과 exit code 둘 다 옵션이지만 JSON이 reason까지 줄 수 있어 권장.

### 출처
- Anthropic Hooks reference (#2) — Stop hook의 `decision: "block"` 동작, exit 2 = 차단.
- Pixelmojo / claudefa.st 등의 실전 글들도 같은 패턴 권장(검색 결과 1차 link만 확인).

---

## 7. 슬래시 커맨드 / Skill로 반복 워크플로 추상화

### 무엇
"이슈 가져와서 → 코드 읽고 → 패치 → 테스트 → PR" 같은 멀티스텝 흐름을 한 단어 명령으로 캡슐화. 매번 같은 단락을 붙여넣지 않는다.

### 언제
- 같은 지시를 3회 이상 붙여넣은 게 보였을 때 (이게 정확히 Anthropic의 권고 트리거).
- CLAUDE.md의 한 섹션이 "사실"이 아니라 "절차"가 되었을 때 — 그건 SKILL.md로 옮길 신호.

### 어떻게

Claude Code 2026 시점에서 **`/commands/foo.md`와 `.claude/skills/foo/SKILL.md`는 동작 동일**(공식 docs: "Custom commands have been merged into skills"). 신규는 SKILL.md를 권장.

`.claude/skills/fix-issue/SKILL.md`:

```markdown
---
description: GitHub 이슈를 읽고 fix하고 PR 만들기. "fix issue 1234" 같은 요청에 사용.
disable-model-invocation: true
allowed-tools: Bash(gh issue *) Bash(gh pr *) Read Edit Write Bash(pnpm *)
---

Fix GitHub issue $ARGUMENTS.

1. `gh issue view $ARGUMENTS`로 이슈 본문 확인.
2. 관련 파일을 grep/glob으로 탐색.
3. 변경 → typecheck → 테스트.
4. 명확한 commit message로 커밋.
5. `gh pr create`로 PR 생성. body에 `Fixes #$ARGUMENTS` 포함.
```

호출: `/fix-issue 1234`.

### 핵심 frontmatter 필드
- `description`: Claude가 자동 호출 결정에 쓰는 텍스트. 핵심 use case를 앞에 (1,536자 cap에 잘림).
- `disable-model-invocation: true`: side effect 있는 워크플로(deploy, commit, send slack)에 필수. 사용자만 트리거 가능.
- `user-invocable: false`: 반대로 background knowledge ("legacy system이 이렇게 동작함")는 자동 호출만 되고 메뉴엔 안 뜨게.
- `allowed-tools`: 이 skill 활성 동안 무프롬프트 허용할 도구. `permission settings`와 별개로 동작.
- `paths`: 특정 글로브에 매칭되는 파일 작업 시에만 자동 활성화. monorepo의 패키지별 skill에 유용.
- `context: fork` + `agent: Explore`: skill을 forked subagent에서 실행해서 메인 컨텍스트를 보호.

### 동적 컨텍스트 주입

`` !`command` `` 구문은 모델에게 보내기 *전*에 사용자 머신에서 실행되어 결과가 prompt에 인라인된다. PR 요약 skill 예:

```markdown
---
description: PR 요약
allowed-tools: Bash(gh *)
---

## PR diff
!`gh pr diff`

## PR 코멘트
!`gh pr view --comments`

위 내용을 3-bullet으로 요약하고 위험 신호를 나열하라.
```

이건 모델이 도구를 호출하는 게 아니다 — preprocessing이라 모델은 이미 결과만 본다. 이슈 추적하면서 컨텍스트 낭비를 막는 강력한 기법.

### 트레이드오프
- skill 본문은 호출되면 세션 끝까지 컨텍스트에 남는다 (auto-compact 후엔 5,000 토큰까지 보존, 25K 공유 budget). 자주 호출하는 큰 skill은 그래서 배경 스토리보다 명령형으로 쓰는 게 좋다.
- skill description이 너무 비슷하면 Claude가 잘못된 skill 자동 호출 — naming/description 명확성 필요.
- skill 본문이 길어지면(>500줄) 메인 SKILL.md 외 reference.md/examples.md로 분리하고 본문에서만 link.

### 출처
- Anthropic Extend Claude with skills (#5) — frontmatter, `disable-model-invocation`, `!` 동적 주입, lifecycle.
- Anthropic best-practices (#1) — skill을 만드는 트리거 시점.

---

## 8. Subagent로 컨텍스트 격리

### 무엇
"탐색·분석·리뷰" 같은 큰 출력 작업을 별도 컨텍스트 윈도우의 subagent에 위임. subagent는 자기 200K 컨텍스트에서 일하고 메인에는 *요약만* 돌려준다.

### 언제
- 코드베이스 전체 탐색이 필요할 때 (수십~수백 파일 grep).
- 보안 리뷰, 마이그레이션 계획 등 도메인 특화 시스템 프롬프트가 필요할 때.
- 권한을 더 좁게 잡고 싶을 때 (예: 리뷰 에이전트는 read-only).
- 비용 절감 — 단순 탐색은 Haiku로 충분.

### 어떻게

`.claude/agents/security-reviewer.md`:

```markdown
---
name: security-reviewer
description: 보안 취약점 검토. auth, crypto, input validation 변경 후 자동 호출.
tools: Read, Grep, Glob, Bash
model: opus
---

당신은 시니어 보안 엔지니어. 코드를 검토해 다음을 찾는다:
- Injection (SQL, XSS, command)
- Auth / Authz 결함
- 코드에 들어간 secret
- 안전하지 않은 데이터 처리

발견 시 파일:줄 형식으로 인용하고 권장 수정안을 제시하라.
```

호출: 메인 세션에서 *"Use the security-reviewer subagent to review the auth changes."*

### Subagent 핵심 frontmatter
- `name`, `description` (필수): description은 "언제 위임할지" Claude가 보는 신호.
- `tools` (옵션): 비우면 부모 도구 모두 상속. 명시하면 그 목록만.
- `model`: `sonnet`, `opus`, `haiku`, full ID, `inherit` 중. 빠른 탐색은 `haiku` 권장.
- `permissionMode`: `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions` 중. 격리된 worktree와 함께 쓰면 acceptEdits 안전.
- `isolation: worktree`: 임시 git worktree에서 작업. 변경 없으면 자동 정리.
- `maxTurns`: 무한 루프 방지.
- `memory: project | user | local`: 세션 간 누적 학습 (예: codebase 패턴 반복 이슈를 기억).

### 빌트인 subagent

Claude Code에는 **Explore** (Haiku, read-only, 코드베이스 검색 전용), **Plan** (read-only, plan mode 보조), **general-purpose** (모든 도구 + 복잡 작업)가 기본 내장. 명시적으로 *"use the Explore subagent to find all callers of `processPayment`"* 호출 가능.

### 제약
- **Subagent는 다른 subagent를 spawn할 수 없다**. nested 격리 불가. 다중 협업이 필요하면 *agent teams* 별도 기능 사용.
- subagent는 fresh context로 시작 — 메인 세션의 기존 발견을 모른다. 호출 prompt에 충분한 single-shot 컨텍스트가 필요.

### 트레이드오프
- 각 subagent 호출은 자기 시스템 프롬프트 + 환경 정보를 새로 로드해서 토큰을 *더* 쓸 수도 있다 — 단순 read 한 번이면 메인이 직접 하는 게 싸다.
- description이 모호하면 Claude가 subagent를 안 쓰거나 잘못 위임함.

### 출처
- Anthropic Create custom subagents (#4) — frontmatter 전체, 빌트인 종류, 제약(no nesting).
- Anthropic best-practices (#1) — subagent를 "investigate"에 쓰는 패턴.

---

## 9. MCP server로 외부 시스템 통합

### 무엇
"코드에서 정보 → 채팅에 붙여넣기" 흐름을 자동화. Claude Code가 직접 GitHub issue, Sentry error, Postgres DB, Figma design을 읽고 쓸 수 있게 한다.

### 언제
- 같은 외부 시스템 데이터를 매번 복붙할 때.
- 비코딩 컨텍스트가 자주 코딩 작업에 필요할 때 (이슈 트래커 → 구현, 모니터링 → 디버깅).

### 어떻게

3가지 추가 방법:

```bash
# 1. 원격 HTTP (권장 for cloud services)
claude mcp add --transport http notion https://mcp.notion.com/mcp

# 2. 인증 헤더 포함
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer $TOKEN"

# 3. 로컬 stdio (Airtable 예)
claude mcp add --transport stdio --env AIRTABLE_API_KEY=YOUR_KEY airtable \
  -- npx -y airtable-mcp-server
```

3가지 scope:
- **local** (기본): `~/.claude.json`, 현재 프로젝트만, 본인만.
- **project**: `.mcp.json` 프로젝트 root에 저장 → git commit으로 팀 공유.
- **user**: `~/.claude.json`, 본인의 모든 프로젝트.

세션 내에서 `/mcp`로 서버 상태/도구 수 확인. 인증 필요 시 OAuth 2.0 흐름 트리거.

### 흔한 실전 MCP server (공식 docs에서 언급된 것만)
- GitHub (이슈/PR 관리)
- Notion (문서 검색·작성)
- Sentry (프로덕션 에러)
- Postgres / Supabase (DB 직접 조회)
- Figma (디자인 → 코드)
- Slack / Gmail (알림·채널)
- Playwright (브라우저 자동화)

### 보안 함정 (공식 docs 경고)
> *"Use third party MCP servers at your own risk - Anthropic has not verified the correctness or security of all these servers. Be especially careful when using MCP servers that could fetch untrusted content, as these can expose you to prompt injection risk."*

신뢰 안 되는 MCP 서버 + 자동 도구 허용 = prompt injection 공격 표면. 이 때문에 MCP 도구도 permission 시스템 적용 대상이고, `mcp__servername__toolname` 또는 `mcp__servername` 와일드카드로 deny 가능.

### 트레이드오프
- 도구 추가 = 컨텍스트 비용. 모든 MCP 서버는 도구 description을 시스템 프롬프트에 싣는다. 안 쓰는 서버는 비활성화.
- MCP 도구 출력이 10,000 토큰 넘으면 경고 (`MAX_MCP_OUTPUT_TOKENS`로 조정 가능).
- 외부 서비스 의존성 = 외부 장애 시 에이전트 작업 중단.

### 출처
- Anthropic MCP docs (#6).
- Anthropic best-practices (#1) — *"With MCP servers, you can ask Claude to implement features from issue trackers..."*.

---

## 10. 테스트를 에이전트의 1차 검증 도구로

### 무엇
에이전트가 자기 변경을 *스스로* 검증할 수 있게 만드는 가장 큰 레버. Anthropic 공식이 "single highest-leverage thing you can do"로 부르는 것.

### 언제
**모든 프로젝트.** 예외 없음. 검증 불가능한 변경은 에이전트가 가장 위험하게 만들 수 있는 변경.

### 어떻게

세 가지 층:

**(a) 빠르고 결정적인 단위 테스트 우선**
- 풀 테스트 슈트가 5분 걸리면 에이전트는 사실상 못 돌린다 → 한 파일/한 기능 단위로 격리 가능한 명령이 있어야 함.
- AGENTS.md에 *single-file* 명령을 명시: `pnpm vitest run path/to/file.test.ts`.

**(b) "Definition of done"을 명령으로**
- 패턴 3 참조. exit 0 명령 N개로 정의.

**(c) Spec / TDD 흐름**
- "Coding Is Like Cooking" (2026-03)이 정리한 흐름: 작업 시작 시 markdown SPEC을 만들고, 에이전트가 SPEC 기반으로 테스트 먼저 작성, 그 다음 구현, 테스트 통과 시까지 반복.
- 사용자: *"Implement X. First write failing tests covering [edge cases], then make them pass. Address root causes, don't suppress."*

**(d) 시각적 변경은 스크린샷으로**
- UI 변경: *"\[paste before screenshot] implement this design. take a screenshot of the result and compare. list differences and fix them."*
- Anthropic의 Claude in Chrome extension이 이 워크플로 지원.

### 트레이드오프
- 테스트가 거짓 양성/음성이면 에이전트가 잘못 학습된다 — 빨강 테스트가 사실은 해결 불가능한 환경 이슈인데도 영원히 retry.
- 통합 테스트가 무거우면 에이전트는 회피하고 unit만 돌림 → 본질적 회귀 놓침.

### 출처
- Anthropic best-practices (#1) — verification 표.
- "Test-Driven Development with Agentic AI" (2026-03) — spec → test → impl 흐름. (검색 결과 #6, 직접 fetch 안 했음. 표면적 일치만 확인했으니 보수적으로만 인용.)

---

## 11. 에이전트 함정 제거 — 죽은 코드, 유사 개념, 숨은 매직

### 무엇
에이전트가 *자주* 헷갈리는 코드 패턴들을 적극적으로 제거/재명명. 이게 가장 적게 논의되지만 가장 영향 큰 카테고리.

### 언제
- 에이전트가 잘못된 함수를 호출하거나, deprecated 모듈을 수정하거나, 두 비슷한 개념을 섞을 때.
- "doom loop" 증상이 보일 때 (에이전트가 같은 곳을 반복 수정하다가 결국 모든 변경 revert).

### 어떻게

**(a) 죽은 코드 제거**
- commented-out 블록 모두 삭제 (git history 있음).
- 미사용 export, deprecated 함수, 안 쓰는 분기 — 모두 deprecation 표시 후 다음 release에서 삭제.
- 이유: 에이전트는 "이 함수 있네"하고 호출함. 호출되지 않을 코드라도 grep에 잡히면 모델은 활성으로 간주.

**(b) 유사 개념 분리** (Amazing CTO 핵심 통찰)
- 한 도메인에서 유사 명사가 둘 이상 공존하면 에이전트는 섞기 시작:
  - `CustomerID` vs `CustomerNo` → 하나로 통일.
  - `BillingService` vs `BillingProcessor` → 한쪽 deprecated 명시 또는 흡수.
  - JET 템플릿 vs Go 템플릿 공존 → 한쪽으로 마이그레이션.
- 통일이 어려우면 *명명을 더 다르게* 만들기: `LegacyBillingService`, `CustomerExternalID`처럼 prefix로 충돌 방지.

**(c) 숨은 매직 / 암묵적 컨벤션 명시화**
- "이 디렉토리 파일은 자동 import됨" 같은 규칙은 README / AGENTS.md에 노출.
- 매크로/메타프로그래밍이 흔한 코드는 *generated 파일임*을 파일 헤더에 명시 ("DO NOT EDIT — generated by ...").
- PostToolUse hook으로 generated 파일 편집 차단 가능 (`additionalContext: "This file is generated. Edit src/schema.ts instead."` 패턴).

**(d) 일관된 네이밍**
- camelCase / snake_case 혼용 금지 — agentic 도구가 두 컨벤션 사이에서 흔들린다(Stack Overflow Blog 인용).
- "tabs vs spaces" 같은 사소한 컨벤션도 AGENTS.md에 적기. IDE/언어가 강제하면 모를까, 아니면 명시.

### 트레이드오프
- 통일 자체가 큰 리팩토링이라 한 번에 못 한다 → "최소한 새 코드는 X"로 시작.
- 죽은 코드 제거는 외부 의존이 있는 경우 위험 (다른 팀이 import 중). semver-major 단위로.

### 출처
- Amazing CTO "doom loops" (#13) — 유사 개념이 LLM 혼란의 핵심이라는 관찰, JET vs Go 템플릿 사례.
- Stack Overflow Blog (#12) — naming 일관성, 명시적 examples 권장.
- jetbrains.com/coding-guidelines-for-your-ai-agents (검색 결과, 표면 확인만) — "no commented-out code" 권고.

---

## 12. PR / 커밋 컨벤션을 에이전트 친화적으로

### 무엇
에이전트가 PR을 만들 때 일관된 형식을 따르도록 AGENTS.md에 *예시*를 둔다. 사람 코드 리뷰 부담을 줄이고 자동 lint/CI가 잘 작동하게.

### 언제
- 에이전트가 자율적으로 PR을 만들어 내는 환경 (예: Stop hook + skill + auto mode 조합).
- 팀 PR template이 이미 있는 프로젝트.

### 어떻게

AGENTS.md에 다음 섹션을 둔다:

```markdown
# PR 컨벤션
- title: `<type>(<scope>): <description>` (Conventional Commits)
- body는 다음 형식:

  ## Summary
  - 무엇이 변했는지 1-3 bullet
  ## Test plan
  - [ ] 변경에 대응하는 unit test 추가
  - [ ] `pnpm test` exits 0
  - [ ] 수동 검증 단계 (해당 시)
  Fixes #<issue>

# Commit 메시지
- 첫 줄 50자 이내, body는 wrap 72.
- "왜"를 적고 "무엇"은 diff에서 보이게.
```

추가로 SKILL.md `/release` 또는 `/open-pr`을 두면 에이전트가 매번 같은 형식을 만든다.

### 트레이드오프
- 너무 엄격한 PR template은 작은 fix에 과도한 ceremony. 작은 변경용 simplified template 별도.
- "Co-authored-by" 같은 attribution은 정책에 맞춰 명시 (Anthropic 자체 가이드도 "Co-Authored-By: Claude ..." 추가 권장이지만 프로젝트 정책 우선).

### 출처
- GitHub Blog 2,500 repos (#10) — 6 핵심 섹션 중 git workflow.
- Builder.io (#14) — PR checklist를 명시적 권고로 포함.

---

## 13. monorepo: 패키지별 메모리 파일 + path-scoped skills

### 무엇
하나의 root AGENTS.md에 모든 패키지를 쑤셔넣지 말고, 각 패키지에 자체 AGENTS.md/CLAUDE.md를 두고 root에는 *공통*만 둔다.

### 언제
- monorepo (Turborepo, Nx, Bazel 등).
- 같은 리포에 다른 언어/스택이 공존(예: `services/api` Python + `apps/web` TypeScript).

### 어떻게

```
my-monorepo/
├── AGENTS.md              # 공통 (Node 버전, monorepo 도구, "secrets 금지")
├── .claude/
│   ├── settings.json      # 공통 permissions
│   └── skills/
│       └── release/SKILL.md
├── apps/
│   ├── web/
│   │   ├── AGENTS.md      # Vite, React 18, design tokens 위치
│   │   └── .claude/skills/
│   │       └── add-page/SKILL.md  # frontend 전용
│   └── mobile/
│       └── AGENTS.md      # Expo, React Native
└── services/
    └── api/
        ├── AGENTS.md      # FastAPI, ruff 설정, test 명령
        └── .claude/skills/
            └── add-endpoint/SKILL.md  # backend 전용
```

핵심:
- AGENTS.md: 자식 우선(nearest wins), 자식이 부모 override.
- CLAUDE.md: 자동 합산형 — 부모가 자동 로드되고 자식이 추가됨. 따라서 자식 CLAUDE.md는 *추가*만 적고 "패키지 전용 oddity"에 집중.
- Skill `paths` frontmatter: `paths: apps/web/**`로 frontend skill을 backend 작업 시 안 뜨게.
- Subagent: monorepo 패키지별로 다른 도구셋이 필요하면 패키지별 subagent 정의.

### 트레이드오프
- "어디에 적어야 하지?" 결정 비용 발생. 룰: *2개 이상 패키지에 해당 = root, 한 패키지 한정 = 자식*.
- 자식 파일이 많아지면 root와 inconsistency 위험.

### 출처
- agents.md 공식 (#7) — nearest wins, 패키지마다 ship.
- Anthropic best-practices (#1) — CLAUDE.md monorepo: *"useful for monorepos where both root/CLAUDE.md and root/foo/CLAUDE.md are pulled in automatically"*.
- The Prompt Shelf의 monorepo 가이드 (#10 검색 결과 표면 확인) — root 단일 파일 안티패턴 경고.

---

## 14. CLI 도구를 에이전트의 1차 인터페이스로

### 무엇
GitHub, AWS, Sentry, gcloud 같은 외부 시스템과의 상호작용은 *CLI*로 통일. 사람용 GUI / SDK 우회 코드는 에이전트가 다루기 어렵다.

### 언제
- 에이전트가 외부 서비스와 통신해야 할 때.
- 인증·rate limit 때문에 unauthenticated REST 호출이 자주 막힐 때.

### 어떻게

- `gh` CLI를 권장 (이슈, PR, comment, release).
- AWS는 `aws` CLI, GCP는 `gcloud`, Sentry는 `sentry-cli`.
- Claude Code는 *모르는* CLI도 `--help` 읽고 학습 가능 — *"Use 'foo-cli-tool --help' to learn about foo, then use it to solve A, B, C."*
- `gh` 인증을 사전에 해두면(`gh auth login`) 에이전트가 토큰 관리 안 해도 됨.

### 트레이드오프
- CLI 출력이 토큰 비용. 큰 list 명령은 `--json` + `jq`로 좁히기.
- CLI 자체 변경(major version)이 에이전트 학습에 영향 — `--help` 캐싱 안 됨.

### 출처
- Anthropic best-practices (#1) — *"CLI tools are the most context-efficient way to interact with external services"*.

---

## 패턴 적용 우선순위 (ROI 순)

리서치 + 공식 권고를 종합한 우선순위. 새 프로젝트 도입 순서로 사용:

1. **AGENTS.md 50줄** (패턴 1, 2) — 가장 적은 노력, 가장 즉각적 효과.
2. **Verification 명령 정비** (패턴 10) — 단일 파일 테스트 명령, exit-code-based done definition.
3. **Permissions allowlist 최소세트** (패턴 4) — 안전한 read-only 명령들 allow.
4. **PostToolUse lint hook** (패턴 5) — typecheck/lint 강제.
5. **반복 워크플로 1개를 SKILL.md로** (패턴 7) — `/fix-issue` 같은 직관적인 것부터.
6. **Subagent로 큰 탐색 격리** (패턴 8) — Explore subagent부터 활용.
7. **유사 개념 / 죽은 코드 정리** (패턴 11) — 점진적, 큰 리팩토링.
8. **MCP server는 마지막** (패턴 9) — 외부 의존이 진짜 자주 필요한지 확인 후.

Stop hook(패턴 6), monorepo 분리(패턴 13)는 규모가 일정 이상일 때만.
