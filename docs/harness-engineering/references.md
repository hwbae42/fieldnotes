# 하네스 엔지니어링 — 참고 자료

> 직접 읽고 검증한 자료만 수록. 패턴·overview에서 인용한 모든 출처.

---

## 1차 출처

| # | 자료 | 발행 | 핵심 기여 |
|---|---|---|---|
| 1 | [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/) | OpenAI, 2026.02.11 | 3원칙(Map/기계적 제약/부채 컬렉션), 1M줄·1,500 PR·10× 실험 수치 |
| 2 | [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Anthropic, 2025.11.26 | 두 실패 유형, Initializer+Coding agent 구조, feature-list.json·progress.txt |
| 3 | [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Anthropic, 2026.03.24 | Generator+Evaluator 분리, 20× 비용 프리미엄($9→$200), "phase change" 품질 |
| 4 | [Sequoia Ascent 2026 summary](https://karpathy.bearblog.dev/sequoia-ascent-2026/) | Andrej Karpathy, 2026.04.30 | Software 3.0, agentic engineering, 검증 가능성, MenuGen 결제 오류, agent-native infrastructure |
| 5 | [Andrej Karpathy: From Vibe Coding to Agentic Engineering](https://www.youtube.com/watch?v=96jN2OCOfLs) | Sequoia Capital, 2026.04.29 | 원본 인터뷰 영상. vibe coding vs agentic engineering, Software 3.0, jagged intelligence |

---

## 도구 레이어 / 가드레일 / 루프 제어 (패턴 7–19 추가, 2026-05-10)

### 도구 레이어 (패턴 7–10)
- Anthropic, *Writing tools for AI agents — with AI agents* (2025). https://www.anthropic.com/engineering/writing-tools-for-agents — namespace, ResponseFormat enum, 25K 토큰 cap, 206→72 토큰 사례.
- Anthropic, *How we built our multi-agent research system*. https://www.anthropic.com/engineering/built-multi-agent-research-system — description 재작성 → task completion 40% 단축.
- Anthropic, *Code execution with MCP* (2025). https://www.anthropic.com/engineering/code-execution-with-mcp — 150K→2K 토큰(98.7%) 절감, progressive tool discovery.
- Anthropic, *Effective context engineering for AI agents*. https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents — JIT retrieval, file-system-as-context, sub-agent 1–2K 요약.
- Simon Willison, *Code execution with MCP* (2025-11-04). https://simonwillison.net/2025/Nov/4/code-execution-with-mcp/.

### 샌드박스·인젝션 방어 (패턴 11–16)
- Claude Code Docs, *Choose a permission mode*. https://code.claude.com/docs/en/permission-modes — default/plan/acceptEdits/bypassPermissions 4단계.
- anthropics/claude-code `.devcontainer`. https://github.com/anthropics/claude-code/tree/main/.devcontainer — Dockerfile + devcontainer.json + init-firewall.sh.
- Development Containers Specification. https://containers.dev/.
- OWASP, *LLM01:2025 Prompt Injection*. https://genai.owasp.org/llmrisk/llm01-prompt-injection/ — least privilege 권고.
- gitleaks/gitleaks. https://github.com/gitleaks/gitleaks — pre-commit·CI·stdin redaction.
- Simon Willison, *The Dual LLM pattern* (2023-04-25). https://simonwillison.net/2023/Apr/25/dual-llm-pattern/.
- Debenedetti et al., *CaMeL: Defeating Prompt Injections by Design*, arXiv:2503.18813 (DeepMind, 2025). https://arxiv.org/abs/2503.18813.
- Simon Willison, *CaMeL offers a promising new direction* (2025-04-11). https://simonwillison.net/2025/Apr/11/camel/.

### 루프 제어 (패턴 17–19)
- Anthropic, *Building effective agents*. https://www.anthropic.com/research/building-effective-agents — stopping conditions·max iterations.
- LangGraph, *GRAPH_RECURSION_LIMIT*. https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT — 기본 25 step.
- Significant-Gravitas/AutoGPT Issue #1994. https://github.com/Significant-Gravitas/AutoGPT/issues/1994 — 무한 루프 실패 사례.
- Shinn et al., *Reflexion: Language Agents with Verbal Reinforcement Learning*, arXiv:2303.11366 (2023). https://arxiv.org/abs/2303.11366 — 메모리 Ω 1–3.
- Madaan et al., *Self-Refine: Iterative Refinement with Self-Feedback*, arXiv:2303.17651 (2023). https://arxiv.org/abs/2303.17651 — initial iterations에서 대부분의 향상.

## 컨텍스트 파이프라인 동적 주입 / 비용·모델 라우팅 (패턴 20–25 추가, 2026-05-10)

### 컨텍스트 파이프라인 동적 (패턴 20–22)
- Anthropic, *Effective context engineering for AI agents*. https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents — JIT retrieval, "art of compaction".
- Claude Code Docs, *Manage costs effectively*. https://code.claude.com/docs/en/costs — subagent 위임, 200줄 가이드, skills 분리.
- Claude Code Docs, *Memory*. https://code.claude.com/docs/en/memory — MEMORY.md 200줄/25KB, `@path` 임포트, `.claude/rules/` paths frontmatter, `/compact` 후 CLAUDE.md 재주입.
- Anthropic API Docs, *Compaction*. https://platform.claude.com/docs/en/build-with-claude/compaction — beta `compact-2026-01-12`, 트리거 임계치, compaction 블록 동작.

### 비용·모델 라우팅 (패턴 23–25)
- Anthropic, *Building effective agents — Routing*. https://www.anthropic.com/research/building-effective-agents — Haiku/Sonnet 분기 routing workflow.
- Claude API pricing. https://claude.com/platform/api — 2026-05 시점 Opus/Sonnet/Haiku 단가, prompt caching 1.25×/2×/0.1× 곱수, batch 50% 할인.
- Anthropic, *Prompt caching*. https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching — breakpoint 배치 규칙, 모델별 최소 토큰, 20블록 lookback, silent miss 진단.
- Anthropic, *Message Batches API*. https://docs.anthropic.com/en/docs/build-with-claude/batch-processing — 50% 할인, 100k 요청/256MB 한도, 24h SLA.

## Karpathy agentic engineering 보강 (패턴 26–28 추가, 2026-05-12)

- Andrej Karpathy, *Sequoia Ascent 2026 summary*. https://karpathy.bearblog.dev/sequoia-ascent-2026/ — Software 3.0, 검증 가능성, vibe coding vs agentic engineering, MenuGen의 Stripe/Google 이메일 매칭 오류, agent-native infrastructure.
- Sequoia Capital, *Andrej Karpathy: From Vibe Coding to Agentic Engineering*. https://www.youtube.com/watch?v=96jN2OCOfLs — 원본 인터뷰 영상.
- 아일의 워크룸, *카파시가 "뒤처졌다"고 느낀 AI 코딩의 진짜 변화*. https://youtu.be/dlAn9H8goUA — 한국어 해설 영상. 원본 인터뷰의 에이전틱 코딩·검증 가능성·시스템 모델 관점을 국내 개발자 맥락으로 재정리.

## 연관 문서 (fieldnotes 내)

| 문서 | 관련 내용 |
|---|---|
| [agent-orchestration/patterns.md 패턴 10](../agent-orchestration/patterns.md) | Long-Running Agent Harness 구현 상세 |
| [agent-orchestration/patterns.md 패턴 9](../agent-orchestration/patterns.md) | Evaluator–Optimizer 구조 |
| [agent-friendly-codebase/patterns.md 패턴 1–3](../agent-friendly-codebase/patterns.md) | AGENTS.md Map 설계, Closure definition |
