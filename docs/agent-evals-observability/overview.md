# 에이전트 평가 / 관측 — Overview

> 마지막 업데이트: 2026-05-10
> 모델 지식 컷오프: 2026-01 / 본 문서는 2025–2026 자료 우선.

## 왜 이 분야가 중요한가

에이전트는 "동작은 한다"와 "신뢰할 만하게 동작한다" 사이의 간극이 다른 어떤 소프트웨어보다 크다. Anthropic의 ["Demystifying evals for AI agents"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)는 이 간극이 어떻게 드러나는지 한 줄로 요약한다 — *"users report the agent feels worse after changes, and the team is 'flying blind.'"*

세 가지 사실이 평가/관측을 1급 시스템 컴포넌트로 끌어올렸다.

1. **에이전트 동작은 비결정적이다.** 같은 입력에 다른 trajectory가 나오고, 그 trajectory들은 모두 정답일 수 있다. 단발 unit test로는 못 잡는다.
2. **최종 출력만 보면 silent failure를 놓친다.** 평가를 final-output에만 한 에이전트는 trajectory까지 본 평가에서 드러나는 회귀의 **20–40%를 통과시킨다** ([Latitude 비교, 2026](https://latitude.so/blog/top-llm-evaluation-tools-ai-agents-2026-devto)). "정답은 맞는데 작년 데이터를 봤다" 식 실패가 일상적.
3. **하네스 컴포넌트가 서로의 가정을 인코딩한다.** 모델·프롬프트·툴 스키마·메모리·orchestration이 함께 변하므로 전체를 trace 단위로 봐야 한다 ([Anthropic, "Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).

업계 표현: **"AI 엔지니어링 == 평가/관측"**. Braintrust의 표현으로 *"observability and evaluation are not separate concerns"* — 한 시스템 안에서 production trace가 곧 다음 eval dataset이 된다 ([Braintrust, "AI agent evaluation framework"](https://www.braintrust.dev/articles/ai-agent-evaluation-framework)).

## 핵심 어휘 정의

이 분야 글은 어휘를 모르면 한 줄도 못 읽는다. 가장 자주 등장하는 6개를 먼저.

| 용어 | 정의 | 출처 |
|---|---|---|
| **Trace** | 한 요청에서 시작된 전체 실행의 트리. 여러 span으로 구성. | OpenTelemetry GenAI semconv |
| **Span** | trace의 한 단위 — LLM 호출, tool 호출, retrieval, 한 에이전트 호출 등. parent/child 관계로 트리 형성. | 동상 |
| **Run** | 하나의 task/trial 실행 = 평가의 단위. trace와 거의 동의어로 쓰이지만 *evaluation-time*에는 run, *production-time*에는 trace로 더 자주 부른다. | LangSmith / OpenAI Evals |
| **Thread** | 한 사용자와 에이전트 사이의 multi-turn 대화 전체. 2025–2026에 LangSmith가 1급 개념으로 승격. | [LangSmith, 2025-10-23](https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith) |
| **Grader / Scorer / Evaluator** | run의 score를 내는 함수. code-based / model-based / human의 셋 중 하나. | Anthropic, "Demystifying evals" |
| **Outcome** | 작업이 끝난 뒤의 환경 상태(파일 트리, DB row, 화면 픽셀). 중간 step이 아니라 *결과*만 보는 평가의 단위. | [Anthropic Outcomes (2026 beta)](https://thenewstack.io/anthropic-managed-agents-dreaming-outcomes/) |

여기에 두 가지 *축*이 따라온다.

- **Online vs Offline 평가** — production traffic 위에서 매 요청 평가하면 online, 미리 만든 dataset에서 배치로 돌리면 offline. EDDOps 논문은 *둘 다*를 closed feedback loop로 연결하라고 주장한다 ([arXiv 2411.13768](https://arxiv.org/abs/2411.13768)).
- **Output vs Trajectory 평가** — 최종 답만 보는 평가 vs 도구 호출 시퀀스·중간 결정까지 보는 평가. 에이전트에서는 *둘 다 필요*. Output만 보면 silent failure를 놓친다는 게 trajectory eval이 등장한 이유.

## 평가는 누가, 무엇을, 언제 — 3축 분류

Anthropic의 ["Demystifying evals"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)가 가장 많이 인용되는 이유는 평가를 **누가(grader)** × **무엇을(target)** × **언제(stage)**로 분해한 게 이 분야의 사실상 표준 어휘가 됐기 때문.

### 누가 평가하는가 — 3종 grader

| Grader | 장점 | 약점 | 언제 |
|---|---|---|---|
| **Code-based** | 빠름·쌈·재현 가능·objective | "valid한 변형"을 false negative로 잡음 (예: `"96.12"` 기대했는데 `"96.120"`) | 정답이 deterministic 일 때 (수치 일치, JSON 스키마, 컴파일 통과, 테스트 통과) |
| **Model-based (LLM-as-judge)** | flexible·뉘앙스 capture·스케일러블 | 비결정적·position bias 등 4 bias·grader 비용 | 정답이 nuance를 가질 때 (요약 품질, 톤, "도움이 됐는가") |
| **Human** | gold standard | 느리고 비싸고 일관성 부족 | 새 grader 보정, 5–10% spot-check, 어려운 도메인 ([Monte Carlo](https://www.montecarlodata.com/blog-llm-as-judge/)) |

["You should use LLM-as-a-judge to improve your judgment, not replace your judgment."](https://www.montecarlodata.com/blog-llm-as-judge/) — IBM Pin-Yu Chen.

### 무엇을 평가하는가 — 5종 target

1. **Final output** — 답이 맞는가. 가장 단순하지만 silent failure에 약하다.
2. **Trajectory / tool calls** — 어떤 도구를 어떤 순서로 어떤 인자로 불렀는가. AgentEvals의 strict / unordered / subset / superset 모드가 표준 ([langchain-ai/agentevals](https://github.com/langchain-ai/agentevals)).
3. **Outcome / environment state** — 작업 완료 후 파일·DB·화면 상태. coding agent는 "테스트가 통과한다", computer-use agent는 "장바구니에 X가 들어갔다".
4. **Cost / latency / reliability** — 토큰·달러·p95 지연·재시도 횟수. 운영 메트릭이지만 평가의 일급 차원이다.
5. **Conversation-level / thread** — multi-turn 전체 흐름에서 "사용자의 *진짜* 목표를 달성했는가". LangSmith Multi-turn Evals가 이 단위 ([LangChain 2025-10-23](https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith)).

### 언제 평가하는가 — 3 stage

| Stage | 무엇 | 주된 grader | 도구 |
|---|---|---|---|
| **Dev / CI** | offline eval, golden set, regression gate | 주로 code-based + 일부 model-based | LangSmith / Braintrust / DeepEval / OpenAI Evals |
| **Pre-prod / canary** | 새 버전이 골든셋에서 회귀 안 일으키는지 PR 머지 게이트 | model-based + pairwise A/B | LangSmith CI, [Traceloop GitHub Action](https://www.traceloop.com/blog/automated-prompt-regression-testing-with-llm-as-a-judge-and-ci-cd) |
| **Production / online** | 실제 트래픽에서 매 trace 채점, drift·refusal·toxicity guardrail | 빠른 code 체크 + 가벼운 LLM judge | Langfuse online evals, Arize Phoenix runtime, Datadog LLM Obs |

["the offline pipeline's primary objective is regression testing — identifying failures, drift, and latency before production"](https://testquality.com/llm-regression-testing-pipeline/) — TestQuality 2026.

## 도구 비교 — 2026년 5월 시점

> 같은 분야가 2024–2025 사이에 폭발했다. 2026년 4월 기준, agent observability는 *6개의 production-grade 플랫폼*으로 정리되는 양상 ([Laminar 2026-04-23](https://laminar.sh/article/2026-04-23-top-6-agent-observability-platforms)).

| 도구 | 라이선스/호스팅 | 강점 | 약점 / 주의 | 출처 |
|---|---|---|---|---|
| **LangSmith** | Closed, hosted (CI 게이트 가능) | LangChain/LangGraph와 **deepest** 통합 — node 단위 state diff. Threads + Multi-turn Evals + Insights Agent (2025-10) | 프레임워크 종속 강함, per-trace 가격 | [LangSmith Eval docs](https://docs.langchain.com/langsmith/evaluation) |
| **Langfuse** | OSS (MIT), self-host or cloud | OSS·framework-agnostic·OpenTelemetry 기반·prompt mgmt+evals 통합. **Clickhouse 인수(2026-01)**, 100% OSS 유지 | 깊은 관측 기능은 hosted 경쟁자보다 얕음 | [Langfuse docs](https://langfuse.com/docs) |
| **Arize Phoenix / AX** | OSS (Phoenix) + 상용 (AX) | OpenInference 10 span kinds — agent 전용 trace taxonomy. drift·toxicity 등 50+ 메트릭 | "ML monitoring 출신" 분위기 — gen AI-only 팀에는 무거울 수 있음 | [arize-ai/phoenix](https://github.com/arize-ai/phoenix) |
| **Braintrust** | Closed, hosted, free tier 1M spans/mo | observability + eval을 **하나의 워크플로**로 — CI 게이트가 가장 매끈. Loop(prompt/scorer 자동 생성) | 비교적 신생, 데이터 거주 옵션 적음 | [braintrust.dev](https://www.braintrust.dev/) |
| **DeepEval** | OSS (Apache 2.0) | pytest 스타일 unit test, 50+ 사전 정의 메트릭, RAG·agent·conversational 커버 | dev-time 위주 (런타임 관측은 Confident AI 클라우드로 분리) | [deepeval.com](https://deepeval.com/) |
| **OpenAI Evals** | OSS framework + Platform UI | OpenAI Agents SDK·Responses API 통합, dataset/Trace/Grader가 한 SDK | OpenAI 모델 중심, 다른 stack 결합은 별도 작업 | [OpenAI Agent Evals](https://platform.openai.com/docs/guides/agent-evals) |
| **Helicone** | OSS, drop-in proxy | proxy 한 줄로 끝나는 가장 낮은 진입 장벽 | trace 깊이는 위 도구들보다 얕음 | [Laminar 2026 비교](https://laminar.sh/article/2026-04-23-top-6-agent-observability-platforms) |
| **Datadog LLM Observability / Honeycomb** | 상용, enterprise | 이미 그 회사를 쓰면 zero-friction. APM과 함께 보기 좋음 | LLM 전용 기능은 specialist 도구보다 뒤짐 | [DigitalApplied 2026 비교](https://www.digitalapplied.com/blog/agent-observability-platforms-langsmith-langfuse-arize-2026) |

**선택 결정 트리** ([LangSmith vs Arize vs Braintrust 비교](https://anudeepsri.medium.com/langsmith-vs-arize-vs-braintrust-e397e4728a76)와 [Laminar 비교](https://laminar.sh/article/2026-04-23-top-6-agent-observability-platforms) 종합):

1. **LangChain/LangGraph 위에 만들고 있다** → LangSmith. node-level state diff는 다른 곳에서 못 본다.
2. **OSS·self-host가 필수 (data residency, 컴플라이언스)** → Langfuse 1순위, Phoenix 2순위.
3. **Eval-driven CI gate가 핵심** → Braintrust (가장 매끈) 또는 DeepEval (OSS, pytest).
4. **OpenAI Agents SDK / Responses API 중심** → OpenAI Evals + (필요 시) Langfuse.
5. **이미 Datadog/Honeycomb 쓰는 enterprise** → 같은 벤더 LLM Obs. zero-friction이 다른 모든 장점을 상쇄.

> *"Which platform you choose matters less than choosing one and using it daily"* — 2026 비교 글들의 일관된 결론.

## 트레이스 표준 — OpenTelemetry GenAI vs OpenInference

같은 trace를 백엔드를 바꿔가며 보고 싶다면 표준 두 개를 알아야 한다.

### OpenTelemetry GenAI Semantic Conventions

OpenTelemetry가 2025–2026에 **GenAI semconv**를 추가. 2026-05 시점은 여전히 *Development* status (stable 아님). 다섯 가지 시그널 카테고리:

- Events (input/output)
- Exceptions
- Metrics (token, latency, cost)
- **Model spans** (LLM 한 번 호출)
- **Agent spans** (에이전트 인스턴스 생성·실행)

provider별 specialization도 정의돼 있다 — Anthropic, OpenAI, Bedrock, Azure AI, MCP. 표준 attribute namespace는 `gen_ai.*` ([OpenTelemetry GenAI semconv](https://opentelemetry.io/docs/specs/semconv/gen-ai/)).

핵심 가치 — *"engineering teams can switch between backends like Datadog, Arize Phoenix, and Jaeger without reconfiguring their entire instrumentation layer"* ([Earezki 2026-03](https://earezki.com/ai-news/2026-03-21-opentelemetry-just-standardized-llm-tracing-heres-what-it-actually-looks-like-in-code/)).

### OpenInference — Arize의 "OTel + α"

Arize가 만든 OpenInference는 OTel 호환이지만 한 단계 더 들어간다. **10가지 span kinds**:

| Span kind | 의미 |
|---|---|
| `CHAIN` | 합성 단계 (LangChain Runnable 류) |
| `LLM` | 단일 LLM 호출 |
| `TOOL` | 도구 호출 |
| `RETRIEVER` | 벡터/검색 인출 |
| `EMBEDDING` | 임베딩 생성 |
| `AGENT` | 한 에이전트 단위 |
| `RERANKER` | 재순위화 |
| `GUARDRAIL` | 입력/출력 검증 |
| `EVALUATOR` | LLM-as-judge 호출 |
| `PROMPT` | 프롬프트 템플릿 단위 |

이 분류 덕에 *"show me all TOOL spans where the tool selection differed from the previous run"* 같은 질의가 한 줄 ([AgentMarketCap 2026-04](https://agentmarketcap.ai/blog/2026/04/07/opentelemetry-ai-agents-observability-standard)).

언제 무엇을 쓰나:
- 백엔드를 가능한 자유롭게 바꾸고 싶다 → **OTel GenAI** 우선.
- 깊은 agent debugging이 필요하고 Phoenix·Arize AX·OTel 호환 백엔드 어디든 보내겠다 → **OpenInference**.
- 두 표준은 *경쟁이 아니라 layered* — OpenInference가 OTel을 wrap한다.

## 멀티 에이전트 평가의 특수성

단일 에이전트 평가의 어휘로는 안 잡히는 4가지가 있다.

### 1. 같은 outcome에 *복수의* valid trajectory

["multi-agent systems can take completely different valid approaches to reach the same goal. This variability requires evaluation methodologies that focus on outcomes rather than process compliance"](https://www.zenml.io/llmops-database/building-a-multi-agent-research-system-for-complex-information-tasks) — Anthropic 멀티 에이전트 리서치 시스템 회고.

대응: trajectory를 strict 매칭하지 말고 **outcomes-based grading**. rubric을 쓰고 grader가 그 rubric으로 채점하게.

### 2. Self-eval은 신뢰할 수 없다

["when asked to evaluate work they've produced, agents tend to respond by confidently praising the work — even when, to a human observer, the quality is obviously mediocre"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).

대응: **Generator와 Evaluator를 분리.** Anthropic의 3-agent harness(2026-04 발표)는 Planner / Generator / Evaluator를 별도 컨텍스트로 둔다. *"Separating the agent doing the work from the agent judging it proves to be a strong lever to address this issue."* GAN과 같은 구조 ([Epsilla blog](https://www.epsilla.com/blogs/anthropic-harness-engineering-multi-agent-gan-architecture)).

같은 task — Evaluator 없이 20분/$9에 broken core. 풀 Planner→Generator→Evaluator로 6시간/$200에 functionally correct ([InfoQ 2026-04](https://www.infoq.com/news/2026/04/anthropic-three-agent-harness-ai/)).

### 3. Multi-turn / thread 단위가 새 평가 단위

LangSmith가 *threads*를 1급 개념으로 만들고 Multi-turn Evals를 출시한 게 2025-10-23. 이 평가의 단위는 한 turn이 아니라 **conversation 전체** — *"Measure whether your agent accomplished the user's goal across an entire interaction"*.

scoring은 conversation이 끝난 뒤 자동으로, LLM-as-judge prompt를 사용자가 정의 ([LangChain blog](https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith)).

### 4. 멀티 에이전트의 trace는 발산한다

리드 에이전트 + N개 서브에이전트 + 각 도구 호출 + 메모리 인출 = trace tree가 깊어지고 span 수가 폭발. OpenInference의 `AGENT` / `CHAIN` / `TOOL` 분류가 의미 있어지는 지점.

## 비결정성 메트릭 — pass@k와 pass^k

같은 task를 k번 돌렸을 때 — 두 다른 질문이 있다.

- **pass@k**: 적어도 한 번이라도 맞히는 확률. *"the likelihood that an agent gets at least one correct solution in k attempts"*.
- **pass^k**: k번 *모두* 맞히는 확률. *"the probability that all k trials succeed"*.

성능 곡선은 정반대로 움직인다 — pass@k는 k가 커질수록 올라가고, pass^k는 k가 커질수록 내려간다. **production 신뢰성 지표는 pass^k.** ([Anthropic, "Demystifying evals"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)).

## 흔한 실수 — Anthropic이 정리한 6가지

["Demystifying evals"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)에서 직접 인용 가능한 안티패턴들:

1. **Rigid grading** — `"96.12"`를 기대했는데 `"96.120"`이 와서 fail. valid 변형을 false negative로 잡음.
2. **Ambiguous task spec** — *"agents shouldn't fail due to ambiguous specs"*. 사람도 못 풀 task로 채점하지 말 것.
3. **Step-level overfit** — "이 도구를 이 순서로 호출했어야 한다"를 강제하면 *overly brittle tests*. 동일 outcome의 다른 경로를 자르게 됨.
4. **Eval saturation** — 모든 task가 통과되면 더 못 본다. 새 어려운 task를 계속 추가해야 함.
5. **Unbalanced problem set** — 양성·음성·boundary case가 한쪽으로 쏠리면 *one-sided optimization*.
6. **Unstable environment** — trial끼리 환경이 새는 경우 (DB row 잔존, 캐시 hit). isolation 필요.

## Swiss Cheese Model — 단일 평가 레이어로는 못 잡는다

Anthropic의 ["Demystifying evals"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)는 자동 evals를 *broader ecosystem* 안에 둔다 — *"no single evaluation layer catches every issue."*

| 레이어 | 무엇을 잡는가 | 비용 |
|---|---|---|
| Code-based unit eval (CI) | 명백한 deterministic 회귀 | 매우 낮음 |
| LLM-as-judge regression (CI/preview) | 품질·뉘앙스 회귀 | 중간 |
| Production trace + online guardrail | drift, prompt injection, PII 누설 | 중간(p95 지연 +α) |
| Human annotation queue (5–10% spot) | 새 grader 보정, edge case 발견 | 높지만 sampled |
| A/B test / user feedback | 실제 사용자 가치 | 높음, 가장 ground truth에 가까움 |
| Manual transcript review | "왜 그렇게 됐는가" 의 root cause | 높음, 가장 정보 밀도 높음 |

치즈 구멍이 다 다른 위치에 있다. 한 장 더 겹치는 것이 핵심.

## EDDOps — 평가가 아닌, 평가-주도 개발

arXiv 2411.13768이 제안한 **Evaluation-Driven Development & Operations of LLM Agents** 가 이 분야의 메타 프레임이다. 핵심 주장:

- 전통적 SDLC는 release gate에 evaluation을 끼워 넣는다.
- LLM 에이전트의 *open-ended·probabilistic·system-level interaction* 특성 때문에 그 모델이 안 통한다.
- 대신 **offline (development-time) + online (runtime) 평가를 closed feedback loop**로.
- 평가 결과가 (1) 런타임 적응 (2) governed redevelopment 양쪽을 모두 trigger.

실용적으로는: **production trace를 매일 dataset으로 promote 하고, 그 dataset으로 다음 PR을 게이트한다.** Braintrust가 *"observability and evaluation are not separate concerns"*라고 한 게 이 사상.

## 무엇부터 시작하나 — 8단계 로드맵

["Demystifying evals"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)를 그대로 옮기면:

1. **Start early**: 실제 실패 20–50건을 골든셋으로.
2. **Convert manual checks**: 사람이 매번 보던 체크를 test case로 코드화.
3. **Write unambiguous tasks**: 정답이 한 가지로 결정되도록.
4. **Build balanced problem sets**: 양성·음성·경계.
5. **Stable environments**: trial 간 격리.
6. **Thoughtful graders**: 가능한 곳은 deterministic, 나머지는 LLM-as-judge + bias mitigation.
7. **Read transcripts**: grader 자체가 맞게 동작하는지 사람 spot-check.
8. **Monitor saturation**: 통과율 100%면 새 어려운 task로 갱신.

이 순서가 중요한 이유: 도구 선택보다 **무엇을 평가할지**를 먼저 정해야 한다는 것. 도구는 마지막에 골라도 늦지 않다.

## 한 페이지 요약

- **에이전트 = 모델 + 하네스**, 평가/관측은 그 하네스의 1급 컴포넌트.
- 어휘: trace / span / run / thread / grader / outcome / online·offline / output·trajectory.
- 평가의 3축: 누가(code / LLM / human) × 무엇을(output / trajectory / outcome / cost / thread) × 언제(dev / preview / prod).
- 도구는 6개로 정리됨 — LangSmith / Langfuse / Phoenix / Braintrust / DeepEval / OpenAI Evals (+ Datadog / Honeycomb).
- 표준은 OTel GenAI semconv (외곽) + OpenInference (agent-aware 10 span kinds).
- 멀티 에이전트는 outcomes-based eval, generator/evaluator 분리, multi-turn thread 평가가 핵심.
- pass@k vs pass^k — production은 pass^k가 정직하다.
- Swiss Cheese: 한 레이어로 못 잡는다. 5–6 레이어를 겹쳐라.
- EDDOps: production trace → dataset → CI gate가 closed loop.

다음: 위 어휘로 표현되는 [구체적 패턴 13개](./patterns.md)와 [참고 자료](./references.md).
