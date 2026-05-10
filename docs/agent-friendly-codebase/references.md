# 참고 자료

본 문서들을 작성하면서 직접 읽고 검증한 자료. 모든 인용·예시는 아래 출처 중 하나에서 가져왔다. 임의의 추측이나 미확인 자료는 포함하지 않았다.

조사 시점: 2026-05-10. 모든 URL은 같은 날 접근.

---

## 공식 docs (1차 출처)

### Claude Code

1. **Best practices for Claude Code** — Anthropic
   <https://code.claude.com/docs/en/best-practices>
   "Give Claude a way to verify its work"가 가장 높은 ROI라는 점, CLAUDE.md include/exclude 표, 4단계 워크플로(Explore→Plan→Implement→Commit) 등 Claude Code 운용의 1차 가이드. 본 문서들에서 가장 많이 인용한 자료.

2. **Hooks reference** — Anthropic
   <https://code.claude.com/docs/en/hooks>
   PreToolUse / PostToolUse / Stop / UserPromptSubmit 등 모든 hook event 정의. JSON 출력 포맷, 종료 코드 2의 동작, `decision: "block"` 의미. patterns.md의 hook 항목 근거.

3. **Configure permissions** — Anthropic
   <https://code.claude.com/docs/en/permissions>
   `permissions.allow / ask / deny` 평가 순서(deny→ask→allow), Bash 와일드카드 규칙, 프로세스 래퍼(`timeout`, `xargs`) 처리, settings 우선순위(managed > CLI > local > project > user). permission 패턴의 함정(예: `Bash(curl http://github.com/ *)`이 매칭되지 않는 케이스)도 명시.

4. **Create custom subagents** — Anthropic
   <https://code.claude.com/docs/en/sub-agents>
   서브에이전트 frontmatter 필드 전체(`name`, `description`, `tools`, `model`, `permissionMode`, `isolation: worktree` 등), 빌트인 Explore/Plan, 서브에이전트가 다시 서브에이전트를 spawn할 수 없다는 제약.

5. **Extend Claude with skills** — Anthropic
   <https://code.claude.com/docs/en/skills>
   SKILL.md 포맷, `disable-model-invocation`, `user-invocable`, `paths`, 동적 컨텍스트 주입(`` !`cmd` ``) 등. "Custom commands have been merged into skills"라는 통합 정책 명시.

6. **Connect Claude Code to tools via MCP** — Anthropic
   <https://code.claude.com/docs/en/mcp>
   MCP local / project / user scope, `claude mcp add` CLI, `.mcp.json` 포맷, 자동 재연결 동작.

### AGENTS.md / 멀티 도구 표준

7. **AGENTS.md (공식 사이트)** — Agentic AI Foundation (Linux Foundation)
   <https://agents.md/>
   AGENTS.md의 정의, 60,000+ OSS 프로젝트 채택, 지원 도구 목록(OpenAI Codex, Cursor, Jules, Gemini CLI, Aider, Zed 등), monorepo에서 "nearest file wins" 원칙.

8. **Adding repository custom instructions for GitHub Copilot** — GitHub Docs
   <https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot>
   `.github/copilot-instructions.md` 위치, `.github/instructions/*.instructions.md` path-specific instructions, AGENTS.md 호환성.

---

## 분석·실전 베스트 프랙티스

9. **Writing a good CLAUDE.md** — HumanLayer
   <https://www.humanlayer.dev/blog/writing-a-good-claude-md>
   "frontier LLMs can reliably follow 150-200 instructions" 근거, "< 300 lines" 권고, 자기 회사 root CLAUDE.md가 60줄 미만이라는 사례. "Never send an LLM to do a linter's job"이라는 강한 어조의 조언.

10. **How to write a great agents.md: Lessons from over 2,500 repositories** — GitHub Blog
    <https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/>
    2,500+ 리포지토리 실증 분석. 효과적인 6개 섹션(commands, testing, structure, style, git workflow, boundaries), "Never commit secrets"가 가장 흔한 효과적 제약.

11. **AGENTS.md Patterns: What Actually Changes Agent Behavior** — Blake Crosley
    <https://blakecrosley.com/blog/agents-md-patterns>
    "Closure definitions"(완료 조건을 종료 코드 0으로 명시) 패턴, `AGENTS.override.md`의 용도, prose 단락이 무시되는 이유.

12. **Building shared coding guidelines for AI (and people too)** — Stack Overflow Blog (2026-03-26)
    <https://stackoverflow.blog/2026/03/26/coding-guidelines-for-ai-agents-and-people-too/>
    AI/사람 공용 가이드라인 작성법. "agents don't run on vibes", explicit examples / gold standard files / clear rationale 권장.

13. **Reasons I Found Why AIs Struggle With Coding** — Amazing CTO
    <https://www.amazingcto.com/where-ai-struggle-doom-loops/>
    "doom loops" 개념. CustomerID vs CustomerNo, JET vs Go templates 같은 유사 개념 충돌이 LLM 혼란의 핵심이라는 관찰.

14. **Improve your AI code output with AGENTS.md** — Builder.io
    <https://www.builder.io/blog/agents-md>
    "Examples beat abstractions" — 패턴 설명 대신 실제 파일 참조(`copy app/components/DashForm.tsx`). dos/don'ts, file-scoped commands, PR checklist 권고.

15. **CLAUDE.md, AGENTS.md & Copilot Instructions: Configure Every AI Coding Assistant** — DeployHQ
    <https://www.deployhq.com/blog/ai-coding-config-files-guide>
    네 가지 포맷(CLAUDE.md, AGENTS.md, .cursorrules, copilot-instructions.md) 비교. "Start with AGENTS.md, layer tool-specific files only when needed" 결론.

---

## 미해결·확인 필요 영역

- **monolith vs polyrepo 에이전트 친화성에 대한 정량 데이터**: GitHub Blog의 2,500 리포지토리 분석은 단일 리포지토리가 다수였고 monorepo vs multirepo 직접 비교는 못 찾음. patterns.md에서는 "정성적 권고"로만 다룸.
- **AGENTS.md의 `AGENTS.override.md` 동작**: Codex 한정 기능인지 표준 일부인지 출처마다 표현이 갈림. agents.md 공식 사이트는 명시 없음, Crosley 글은 "Codex specifically supports"로 표현. 본 문서에서도 "Codex 확장"으로만 표기.
- **CLAUDE.md 실제 권장 길이**: HumanLayer는 "< 300 lines, 60 lines preferred", Anthropic 공식은 명시적 줄 수 권고 없이 "concise"만 언급. 둘 다 인용하되 절대값으로 단정 안 함.
- **2026년 시점 hook event 전체 목록**: 1차 fetch 결과 12+개 이벤트 명시. 그러나 v2.0.x 단위로 추가/변경되는 흐름이라, 본 문서에 적은 PreToolUse/PostToolUse/Stop/UserPromptSubmit이 stable한 핵심이라는 전제로 작성.

---

## 그룹별 빠른 색인

- **공식 docs**: 1, 2, 3, 4, 5, 6, 7, 8
- **표준 / 스펙**: 7, 8, 10
- **베스트 프랙티스 글**: 9, 11, 12, 14
- **실전 사례 / 분석**: 10, 13
- **도구별 비교**: 15
