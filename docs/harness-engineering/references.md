# 하네스 엔지니어링 — 참고 자료

> 직접 읽고 검증한 자료만 수록. 패턴·overview에서 인용한 모든 출처.

---

## 1차 출처

| # | 자료 | 발행 | 핵심 기여 |
|---|---|---|---|
| 1 | [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/) | OpenAI, 2026.02.11 | 3원칙(Map/기계적 제약/부채 컬렉션), 1M줄·1,500 PR·10× 실험 수치 |
| 2 | [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Anthropic, 2025.11.26 | 두 실패 유형, Initializer+Coding agent 구조, feature-list.json·progress.txt |
| 3 | [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Anthropic, 2026.03.24 | Generator+Evaluator 분리, 20× 비용 프리미엄($9→$200), "phase change" 품질 |

---

## 연관 문서 (fieldnotes 내)

| 문서 | 관련 내용 |
|---|---|
| [agent-orchestration/patterns.md 패턴 10](../agent-orchestration/patterns.md) | Long-Running Agent Harness 구현 상세 |
| [agent-orchestration/patterns.md 패턴 9](../agent-orchestration/patterns.md) | Evaluator–Optimizer 구조 |
| [agent-friendly-codebase/patterns.md 패턴 1–3](../agent-friendly-codebase/patterns.md) | AGENTS.md Map 설계, Closure definition |
