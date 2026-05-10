# 에이전트 평가 / 관측 — 참고 자료

직접 읽고 소화한 자료만. 핵심도 순으로 정렬.

## 필독 (먼저 이걸 읽고 시작하라)

- **Anthropic, "Demystifying evals for AI agents"** (2025)
  https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
  이 분야의 어휘를 정한 글. grader 3종(code/model/human), pass@k vs pass^k, 흔한 안티패턴 6가지, 8단계 로드맵, Swiss Cheese 모델까지 한 글에 다 있다. 다른 모든 글이 이걸 가정하고 쓴다.

- **Anthropic, "Effective harnesses for long-running agents"** (2026)
  https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
  feature rubric을 measurable JSON으로 두고 Initializer / Coding agent로 분리하는 패턴. self-eval은 신뢰할 수 없다는 핵심 통찰의 1차 출처.

- **Anthropic, "How we built our multi-agent research system"** (2025-06)
  https://www.anthropic.com/engineering/multi-agent-research-system
  +90.2% / 15× 토큰 트레이드오프, lead Opus + worker Sonnet 패턴, 멀티 에이전트 평가가 *outcomes 중심*이어야 하는 이유. evaluation 섹션에서 LLM-as-judge rubric(factual·citation·completeness·source quality·tool efficiency)을 그대로 보여줌.

- **Anthropic, "Building Effective Agents"** (2024-12)
  https://www.anthropic.com/research/building-effective-agents
  워크플로 5종 (prompt chaining / routing / parallelization / orchestrator-workers / **evaluator-optimizer**). 평가/관측 맥락에서는 evaluator-optimizer가 "generator vs evaluator" 분리 패턴의 정전.

- **Hu et al., "Evaluation-Driven Development and Operations of LLM Agents"** (arXiv:2411.13768, 2025)
  https://arxiv.org/abs/2411.13768
  EDDOps 프로세스 모델 — offline + online 평가를 closed feedback loop로. 평가를 *terminal checkpoint*가 아닌 *continuous governing function*으로 두는 아이디어의 1차 출처.

## 도구 / 플랫폼 공식 문서

### LangSmith (LangChain)

- **LangSmith Evaluation docs**
  https://docs.langchain.com/langsmith/evaluation
  trace 기반 평가, 인간 annotation queue, heuristic·LLM-as-judge·pairwise 4종 evaluator의 reference.

- **LangSmith Observability**
  https://www.langchain.com/langsmith/observability
  Python·TypeScript·Go·Java SDK, framework-agnostic 통합, node-level state diff (LangGraph 한정).

- **LangChain blog, "Insights Agent and Multi-turn Evals"** (2025-10-23)
  https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith
  threads를 1급 개념으로 승격. Multi-turn Evals 자동 채점, Insights Agent 자동 클러스터링. 패턴 #10·#11의 1차 출처.

- **AI Agent Observability — LangChain**
  https://www.langchain.com/articles/agent-observability
  관측-평가-개선 사이클 일반론. 입문 정리에 좋음.

- **LangSmith Trajectory Evals**
  https://docs.langchain.com/langsmith/trajectory-evals
  trajectory matching의 4가지 mode, 코드 예시.

### Langfuse

- **Langfuse Observability docs**
  https://langfuse.com/docs/observability/overview
  OpenTelemetry 기반 trace 모델, 매끈한 LangChain·OpenAI SDK·LiteLLM 통합. self-host docker compose도 같은 페이지 트리.

- **Langfuse Human Annotation**
  https://langfuse.com/docs/scores/annotation
  annotation queue 워크플로의 reference UI. dataset promotion 패턴 #9의 가장 단순한 구현.

- **Langfuse, "LLM Testing: A Practical Guide"** (2025-10-21)
  https://langfuse.com/blog/2025-10-21-testing-llm-applications
  unit / integration / regression 3축에 LLM 앱을 매핑한 글. CI 게이트 패턴 #7의 좋은 보강.

- **Orrick, "Open-source LLM Observability: Langfuse Acquired by ClickHouse"** (2026-01)
  https://www.orrick.com/en/News/2026/01/Open-source-LLM-Observability-Langfuse-Acquired-by-ClickHouse-Inc
  Langfuse가 ClickHouse에 인수된 사실 확인. 100% OSS 유지, Cloud는 standalone.

### Arize Phoenix / OpenInference

- **arize-ai/phoenix (GitHub)**
  https://github.com/arize-ai/phoenix
  OSS LLM/Agent observability 본체. OpenInference span kinds 10종이 여기서 유래.

- **arize-ai/openinference**
  https://github.com/Arize-ai/openinference
  OTel 보강 spec. Python 30+ 통합, JS/Java 지원. agent 디버깅용 `AGENT`/`TOOL`/`GUARDRAIL`/`EVALUATOR` 등의 분류가 1차 정의.

- **Phoenix Tracing Overview**
  https://arize.com/docs/phoenix/tracing/llm-traces
  LLM·Tool·Retriever·Agent span의 시각적 trace 디버깅. agent stack 어떤 것이든 OTel-호환 백엔드로 보낼 수 있다는 점이 강조.

- **Arize, "LLM as a Judge"**
  https://arize.com/llm-as-a-judge/
  pre-built evaluator 카탈로그(faithfulness, hallucination, toxicity 등 50+).

### Braintrust

- **Braintrust 공식 사이트 / docs**
  https://www.braintrust.dev/
  observability + eval을 한 워크플로로. CI 게이트가 가장 매끈한 도구로 평가됨. Loop가 prompt/scorer/dataset를 자동 생성해주는 부가 기능.

- **Braintrust, "AI agent evaluation framework"**
  https://www.braintrust.dev/articles/ai-agent-evaluation-framework
  multi-step agent 평가의 일반 프레임. trace + golden dataset + scorer 3축 정리.

- **Braintrust, "LLM evaluation guide"**
  https://www.braintrust.dev/articles/llm-evaluation-guide
  evals / metrics / regression test의 어휘 정리. 입문 글로도 좋음.

- **braintrustdata/autoevals (GitHub)**
  https://github.com/braintrustdata/autoevals
  사전 정의 LLM-as-judge metric 모음. 직접 import해서 쓸 수 있음.

### DeepEval / Confident AI

- **deepeval.com 공식**
  https://deepeval.com/
  pytest 스타일 LLM 테스트, 50+ pre-built metric (RAG·agent·conversational·safety·multimodal). Apache 2.0.

- **DeepEval AI Agent Evaluation guide**
  https://deepeval.com/guides/guides-ai-agent-evaluation
  agent 한정 평가 패턴 — task completion, tool correctness, conversation eval.

- **DeepEval G-Eval docs**
  https://deepeval.com/docs/metrics-llm-evals
  chain-of-thought rubric grader 패턴.

### OpenAI Evals

- **Evaluate agent workflows — OpenAI API docs**
  https://developers.openai.com/api/docs/guides/agent-evals
  Agents SDK 위에서 trace → eval run → grader → score 사이클을 그대로.

- **OpenAI Evals (GitHub, OSS framework)**
  https://github.com/openai/evals
  open-source benchmark registry + framework.

- **Evaluation best practices — OpenAI**
  https://developers.openai.com/api/docs/guides/evaluation-best-practices
  그래더 디자인, 데이터셋 큐레이션, regression 패턴의 OpenAI 공식 권고.

### Trajectory & Trace 기반 평가 도구

- **langchain-ai/agentevals (GitHub)**
  https://github.com/langchain-ai/agentevals
  trajectory match modes (strict/unordered/subset/superset) 의 표준 구현. 패턴 #2의 1차 출처.

- **Arize Trajectory Evaluations**
  https://arize.com/docs/ax/evaluate/evaluators/trace-and-session-evals/trace-level-evaluations/agent-trajectory-evaluations
  Phoenix/AX에서의 trajectory 평가 — agentevals와 비교 가치.

## 표준 (OpenTelemetry GenAI / OpenInference)

- **OpenTelemetry GenAI Semantic Conventions**
  https://opentelemetry.io/docs/specs/semconv/gen-ai/
  2026-05 시점 *Development* status. 5개 시그널(events / exceptions / metrics / model spans / agent spans). `gen_ai.*` namespace.

- **OpenTelemetry GenAI Agent Spans**
  https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/
  agent operation 전용 span attribute 명세. `gen_ai.operation.name=create_agent` 등.

- **OpenInference Semantic Conventions**
  https://arize-ai.github.io/openinference/spec/semantic_conventions.html
  10가지 span kinds, attribute 이름. OTel과 layered 관계.

- **Earezki, "OpenTelemetry just standardized LLM tracing"** (2026-03-21)
  https://earezki.com/ai-news/2026-03-21-opentelemetry-just-standardized-llm-tracing-heres-what-it-actually-looks-like-in-code/
  OTel GenAI semconv를 코드 예시로 풀어쓴 입문. 어떤 attribute가 어디 들어가는지 한눈에.

- **AgentMarketCap, "OpenTelemetry for AI Agents"** (2026-04-07)
  https://agentmarketcap.ai/blog/2026/04/07/opentelemetry-ai-agents-observability-standard
  OpenInference span kinds로 가능한 디버깅 쿼리 예시. 패턴 #6 보강 자료.

## LLM-as-Judge 심화

- **Monte Carlo Data, "LLM-As-Judge: 7 Best Practices & Evaluation Templates"**
  https://www.montecarlodata.com/blog-llm-as-judge/
  position·verbosity·self-preference·authority 4 bias 정리. *"use LLM-as-a-judge to improve your judgment, not replace your judgment"* 인용 출처.

- **Confident AI, "LLM-as-a-Judge — Complete Guide"**
  https://www.confident-ai.com/blog/why-llm-as-a-judge-is-the-best-llm-evaluation-method
  pointwise vs pairwise, reference-based grading, 일관성 점검 권고. 가장 실용적인 단일 글.

- **Openlayer, "LLM as Judge Guide"** (2026-03)
  https://www.openlayer.com/blog/post/llm-as-judge-evaluation-guide
  reference-based vs reference-free, judge model 선택 기준, 환각 격감 사례.

- **Langfuse LLM-as-a-Judge docs**
  https://langfuse.com/docs/evaluation/evaluation-methods/llm-as-a-judge
  Langfuse에서의 운영 방법. UI 기반 judge 정의.

- **Cameron R. Wolfe, "Using LLMs for Evaluation"**
  https://cameronrwolfe.substack.com/p/llm-as-a-judge
  2024년 글이지만 학계 관점에서 LLM-as-judge의 한계와 agreement 측정 방법을 가장 잘 정리.

## Guardrails / Online Evaluation

- **LangChain Guardrails docs**
  https://docs.langchain.com/oss/python/langchain/guardrails
  pre-LLM / post-LLM 분리, 사용 가능한 evaluator 카탈로그.

- **Datadog, "LLM guardrails best practices"**
  https://www.datadoghq.com/blog/llm-guardrails-best-practices/
  *"start with offline evaluations and only add performance guards if absolutely necessary"* 권고. real-time vs offline trade-off 정리.

- **Coralogix, "What Are AI Guardrails?"**
  https://coralogix.com/ai-blog/ai-guardrails/
  guardrail 카테고리(input·output·topic·PII·toxicity)와 production 사례.

- **NVIDIA NeMo Guardrails**
  https://github.com/NVIDIA-NeMo/Guardrails
  programmable guardrail toolkit. Colang DSL이 가장 표현력 있는 옵션.

- **guardrails-ai/guardrails**
  https://github.com/guardrails-ai/guardrails
  validator 카탈로그(Hub). Python에서 가장 쉽게 시작할 수 있는 OSS.

- **Arize, "Production LLM Evaluation"**
  https://arize.com/llm-evaluation/production-llm-evaluation/
  online evaluation 운영 — sampling 비율, drift 감지, alert.

## 비교 / 시장 정리 (2026)

- **Laminar, "Top 6 Agent Observability Platforms"** (2026-04-23)
  https://laminar.sh/article/2026-04-23-top-6-agent-observability-platforms
  6개 플랫폼(LangSmith·Langfuse·Phoenix·Helicone·Datadog·Honeycomb) 비교. 가장 균형 잡힌 2026 글.

- **DigitalApplied, "Agent Observability: LangSmith, Langfuse, Arize 2026"**
  https://www.digitalapplied.com/blog/agent-observability-platforms-langsmith-langfuse-arize-2026
  3개 플랫폼 강점·약점·가격대 비교. 의사결정 기준 표가 직관적.

- **Anudeep, "LangSmith vs Arize vs Braintrust"** (Medium, 2026-03)
  https://anudeepsri.medium.com/langsmith-vs-arize-vs-braintrust-e397e4728a76
  사용 시나리오별 추천. 하나만 읽는다면 이 글.

- **Latitude, "Best AI Evaluation Tools for Agents in 2026"**
  https://latitude.so/blog/agent-first-comparison-guide-vs-braintrust
  agent-first 도구 vs LLM-only 도구 차이. silent failure가 trajectory eval에서 드러나는 *20–40%* 수치 출처.

- **MLflow, "Top 5 LLM and Agent Observability Tools in 2026"**
  https://mlflow.org/top-5-agent-observability-tools/
  MLflow 자기 입장이지만 OSS 위주 비교에 균형이 있음.

## CI / 회귀 테스트 운영

- **Traceloop, "Automated Prompt Regression Testing with LLM-as-a-Judge and CI/CD"**
  https://www.traceloop.com/blog/automated-prompt-regression-testing-with-llm-as-a-judge-and-ci-cd
  GitHub Action 형태로 매 PR에 평가 게이트. 3-layer gate 패턴의 좋은 보강.

- **TestQuality, "LLM Regression Testing Pipeline for QA Engineers"** (2026)
  https://testquality.com/llm-regression-testing-pipeline/
  RAG triad·gold sets·layered eval. *"deploying without a gating offline evaluation suite is an architectural anti-pattern"* 인용 출처.

- **Evidently AI, "CI/CD for LLM apps"**
  https://www.evidentlyai.com/blog/llm-unit-testing-ci-cd-github-actions
  GitHub Actions에서 매끈한 unit test 워크플로 셋업.

- **LangChain blog, "Agent Evaluation Readiness Checklist"**
  https://blog.langchain.com/agent-evaluation-readiness-checklist/
  production agent를 ship 하기 전 체크리스트. 8개 골든셋 시작·trace 계측·CI gate 운영의 prerequisites.

## 케이스 스터디 / 분석

- **InfoQ, "Anthropic Designs Three-Agent Harness"** (2026-04)
  https://www.infoq.com/news/2026/04/anthropic-three-agent-harness-ai/
  3-agent harness의 외부 분석. 같은 task에서 evaluator 유무에 따른 결과 차이(20분/$9 broken vs 6시간/$200 functional).

- **Epsilla, "GAN-Style Agent Loop"**
  https://www.epsilla.com/blogs/anthropic-harness-engineering-multi-agent-gan-architecture
  generator/evaluator 분리를 GAN과 유비. 코드 예시로 일반화한 글.

- **The New Stack, "Anthropic will let its managed agents dream"**
  https://thenewstack.io/anthropic-managed-agents-dreaming-outcomes/
  Outcomes(2026 베타) — *"a separate grader evaluates the output against your criteria in its own context window"*. 패턴 #4의 출처.

- **VentureBeat, "Anthropic wants to own your agent's memory, evals, and orchestration"**
  https://venturebeat.com/orchestration/anthropic-wants-to-own-your-agents-memory-evals-and-orchestration-and-that-should-make-enterprises-nervous
  Anthropic이 plat-form-level 평가/관측 전체를 관할하려는 전략 분석. 벤더 lock-in 측면의 비판적 시각.

- **Hostinger × Braintrust 케이스** (ZenML LLMOps DB)
  https://www.zenml.io/llmops-database/building-a-comprehensive-llm-evaluation-framework-with-braintrust-integration
  실제 production scale에서 평가 프레임워크 구축. 골든셋 운영·CI 통합·alert thresholds.

- **Anthropic Multi-Agent Research case** (ZenML LLMOps DB)
  https://www.zenml.io/llmops-database/building-a-multi-agent-research-system-for-complex-information-tasks
  Anthropic 1차 글의 외부 정리. *"focus on outcomes rather than process compliance"* 인용 출처.

- **VentureBeat, "Monitoring LLM behavior: Drift, retries, and refusal patterns"**
  https://venturebeat.com/infrastructure/monitoring-llm-behavior-drift-retries-and-refusal-patterns
  production 운영 안티패턴 모음. drift·refusal 메트릭 정의에 좋은 글.

## Annotation / Human-in-the-Loop

- **John Snow Labs, "Top 6 Annotation Tools for HITL LLMs Evaluation"**
  https://www.johnsnowlabs.com/top-6-annotation-tools-for-hitl-llms-evaluation-and-domain-specific-ai-model-training/
  HITL annotation tool 비교. UX 차이가 quality에 영향 큼.

- **arXiv 2502.13417, "RLTHF: Targeted Human Feedback for LLM Alignment"** (2025)
  https://arxiv.org/html/2502.13417v1
  uncertain sample만 사람 큐로 보내는 selective annotation 패턴. 패턴 #9의 학술 근거.

- **Medium, "A Minimal Feedback Loop for LLM Applications"** (Alex Gidiotis, 2025-12)
  https://medium.com/@alexgidiotis_96550/a-minimal-feedback-loop-for-llm-applications-aecfaede98e1
  사용자 thumbs feedback → annotation queue → dataset promotion의 가장 단순한 셋업.

## 기타 도움 됐지만 위 카테고리에 안 들어간 자료

- **Databricks, "What is AI Agent Evaluation?"**
  https://www.databricks.com/blog/what-is-agent-evaluation
  벤더 중립 입문. trajectory vs outcome 어휘를 가장 평이하게.

- **Google Cloud, "A methodical approach to agent evaluation"**
  https://cloud.google.com/blog/topics/developers-practitioners/a-methodical-approach-to-agent-evaluation
  Vertex AI 위 사례지만 일반화된 pattern checklist. ADK eval과 함께 읽기 좋음.

- **Red Hat Developers, "Eval-driven development: Build and evaluate reliable AI agents"** (2026-03)
  https://developers.redhat.com/articles/2026/03/23/eval-driven-development-build-evaluate-ai-agents
  eval-driven dev process를 단계별로. EDDOps 논문의 실용 버전.

- **Dev.to, "Eval-driven development for a local-LLM agent"** (Erez Shahaf)
  https://dev.to/erez_shahaf/eval-driven-development-for-a-local-llm-agent-how-i-shipped-lore-020-with-confidence-2m75
  로컬 LLM 에이전트(Lore 0.2.0)의 eval 운영기. 1인 OSS 규모에서의 현실적 셋업.

- **QuantumBlack/McKinsey, "Evaluations for the agentic world"**
  https://medium.com/quantumblack/evaluations-for-the-agentic-world-c3c150f0dd5a
  엔터프라이즈 컨설팅 시각의 평가 프레임. trajectory 안정성·outcome 분산 강조.

---

## 미해결 / 솔직한 인지

자료마다 인정하는, 2026.05 시점에 답이 없는 영역.

- **Grader 자체의 보정** — judge 모델이 sample drift에 따라 같은 trace에 다른 점수를 매긴다. judge versioning + 정기 인간 calibration 외 표준 부재.
- **Prompt injection / jailbreak 검출** — signature 기반은 빠르게 stale, semantic 기반은 false positive. cat-and-mouse 게임이 끝날 기미가 없음.
- **멀티 에이전트 trajectory 평가** — 발산하는 trace tree에서 *어느 분기가 valid한가*를 일관되게 채점할 표준 부재. 현재는 outcome으로만.
- **Eval saturation 후속** — 골든셋이 다 통과되기 시작하면 다음 어려운 task를 *생성*하는 자동화는 없음. 사람이 손으로 추가.
- **Cost-quality Pareto frontier 자동화** — 모델·프롬프트 조합이 폭발적으로 늘면 어떤 PR이 frontier 상에 있는지 자동 판단 부재. 사람이 dashboard 보고 결정.
- **Multi-turn LLM-as-judge 정확도** — single-turn에서는 80–90% agreement지만 long thread에서는 의도 추정이 흔들린다. 정확한 수치는 도메인별.
- **Annotator agreement 운영** — 2명 라벨링 + Cohen's kappa는 알지만 *언제 그게 충분한가*는 도메인별. 표준 가이드라인 부재.
- **OTel GenAI semconv stable화 시점** — 2026-05 현재 *Development* status. 언제 stable이 될지 불확실 — 그동안 attribute 이름 변경 risk.

---

## 인용 가이드

본 fieldnotes 안에서 위 자료를 인용할 때:
- 1차 출처(Anthropic, OpenAI, LangChain, Arize, Braintrust 공식)를 우선.
- 2차 분석(Medium / DEV / 비교 블로그)은 1차가 없을 때 또는 cross-validation 용도로만.
- 모든 일자·수치는 원문 링크와 함께 기재 (예: `+90.2%`, `15× 토큰`은 Anthropic 공식 글; `silent failure 20–40%`는 Latitude 비교).
- *Development* status인 표준(OTel GenAI semconv 등)은 그 사실을 함께 명시.
