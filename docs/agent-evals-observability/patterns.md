# 에이전트 평가 / 관측 — 패턴

> 조사 시점: 2026-05-10. 출처는 [`references.md`](./references.md). 개념적 배경은 [`overview.md`](./overview.md).
>
> 각 패턴 형식: **무엇 / 언제 / 어떻게 / 트레이드오프 / 출처**.
> 모든 코드 예시는 출처에서 검증한 형식만 사용. 출처 없는 추측은 "추측"으로 명시.

---

## 1. 골든셋(golden set) 부터 만들기

### 무엇
플랫폼·프레임워크 선택 전에, **실제 실패 사례 20–50건**을 입력 + 기대 결과 + 검증 방법으로 정리한 데이터셋. 이게 모든 후속 평가의 단위가 된다.

### 언제
에이전트가 처음 production 트래픽을 받기 시작했거나, 사람이 매번 같은 점검을 손으로 할 때. 도구 선정보다 *먼저*.

### 어떻게
- **소스는 production trace 또는 manual review.** 합성 데이터는 cold-start 보조용으로만.
- 한 entry = `{input, expected_output OR rubric, environment_state, why_it_failed_originally}`.
- 양성·음성·경계 case가 균형 잡히게 ([Anthropic, "Demystifying evals"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)).
- 모호한 task는 즉시 제외 — *"agents shouldn't fail due to ambiguous specs"*. 사람이 풀라고 해도 답이 안 나오면 grader도 못 푼다.
- 처음에는 LangSmith/Braintrust/Langfuse의 dataset UI를 쓰지 말고 **CSV/JSONL 한 파일**로. 도구는 셋이 안정되면 옮겨도 늦지 않다.

### 트레이드오프
- 너무 많이 만들면 **eval saturation**으로 가는 길이 빨라진다 — 모두 통과하기 시작하면 새로운 어려운 case 추가가 필요.
- 합성 데이터로 양을 늘리면 *real-world distribution shift*를 잃는다. 가능하면 production 샘플에서 promote.
- 골든셋이 한 사람의 손에서만 자라면 그 사람의 bias가 박힌다 — annotator 2명 spot-check 권장.

### 출처
- Anthropic, "Demystifying evals for AI agents" — 8단계 로드맵 1·3단계.
- TestQuality, "LLM Regression Testing Pipeline" (2026) — *"The best test cases come from real production traffic."*
- Braintrust, "AI agent evaluation framework".

---

## 2. Trajectory matching — strict / unordered / subset / superset

### 무엇
에이전트가 호출한 도구 시퀀스(=trajectory)를 reference trajectory와 비교해 채점하는 방식. 매칭 모드 4가지로 강도를 조절.

### 언제
도구 호출 *순서·집합*이 정답의 일부일 때. 코딩 에이전트의 "테스트 먼저 실행 후 수정", 리서치 에이전트의 "검색 → 읽기 → 합성".

### 어떻게
LangChain의 [agentevals](https://github.com/langchain-ai/agentevals) 패키지가 표준에 가깝다.

```python
from agentevals.trajectory.match import create_trajectory_match_evaluator

evaluator = create_trajectory_match_evaluator(
    trajectory_match_mode="strict",        # or "unordered" / "subset" / "superset"
    tool_args_match_mode="exact",          # 인자까지 정확히 매칭
    tool_args_match_overrides={...}        # 일부 인자는 fuzzy 허용
)

result = evaluator(
    outputs=actual_messages,
    reference_outputs=reference_messages
)
# {"key": "trajectory_strict_match", "score": 0/1}
```

| 모드 | 의미 | 적합한 상황 |
|---|---|---|
| `strict` | 같은 도구·같은 인자·같은 순서 | 절차가 1개로 정해진 task |
| `unordered` | 같은 도구·같은 인자, 순서 무관 | 병렬 가능한 검색·집계 |
| `subset` | reference의 부분집합이면 OK | 빠른 경로 인정 |
| `superset` | reference 모두 + 추가 호출 OK | "최소한 이건 했어야 한다" |

LLM-as-judge로 fuzzy 매칭이 필요하면 `create_trajectory_llm_as_judge(prompt=TRAJECTORY_ACCURACY_PROMPT, model=...)`.

### 트레이드오프
- **strict는 거의 항상 너무 빡빡하다.** 같은 outcome의 다른 경로를 회귀로 잡는다. Anthropic도 *"checking very specific steps like a sequence of tool calls in the right order produces overly brittle tests"*고 경고.
- `subset`이 보통 좋은 출발점.
- 도구 인자 fuzzy 매칭(`tool_args_match_overrides`)을 안 쓰면 timestamp·UUID 같은 가변 인자 때문에 항상 fail.
- *순서가 정말 의미 있는* 단계(payment confirm 전에 cart total)는 strict로, 나머지는 unordered로 *섞어* 쓰는 게 실전.

### 출처
- [langchain-ai/agentevals](https://github.com/langchain-ai/agentevals) — API 시그니처.
- [LangSmith Trajectory Evals docs](https://docs.langchain.com/langsmith/trajectory-evals).
- [Arize Trajectory Evaluations](https://arize.com/docs/ax/evaluate/evaluators/trace-and-session-evals/trace-level-evaluations/agent-trajectory-evaluations).

---

## 3. LLM-as-judge — bias 4종 mitigation 없이는 쓰지 마라

### 무엇
LLM에게 rubric과 출력 한두 개를 주고 점수·승자를 매기게 하는 grader 패턴. 강력하지만 미가공 상태로 쓰면 untreated bias 4종(position, verbosity, self-preference, authority)이 그대로 나온다.

### 언제
정답이 deterministic 매칭으로 안 잡히는 모든 곳 — 요약 품질, 톤, helpfulness, RAG faithfulness, tool 적절성.

### 어떻게

**Pointwise(단일 출력에 1–5)** vs **Pairwise(A vs B 중 누가 나음)**:

| 방식 | 장점 | 약점 |
|---|---|---|
| Pointwise | 매 run 한 번 호출. 회귀 추적·dashboard에 적합 | 절대 점수가 run마다 drift |
| Pairwise | 안정적·민감도 높음 | output 두 개 필요 (현재 vs baseline) |

**Bias 4종과 mitigation** ([Monte Carlo](https://www.montecarlodata.com/blog-llm-as-judge/), [Confident AI](https://www.confident-ai.com/blog/why-llm-as-a-judge-is-the-best-llm-evaluation-method)):

1. **Position bias** — A를 먼저 보여주면 A를 선호. *"40% GPT-4 inconsistency"*.
   - 대응: (A,B)와 (B,A) *둘 다* 평가 → 둘 다 A를 골라야 A 승.
2. **Verbosity bias** — 긴 답을 선호.
   - 대응: rubric에 *"length is not a factor; reward concision when correct"* 명시.
3. **Self-preference** — 같은 모델 패밀리 출력을 선호.
   - 대응: judge와 generator를 다른 패밀리로. 또는 GPT-4로 Claude 출력을 채점.
4. **Authority bias** — "Berkeley 연구진이 답했다"고 하면 점수가 오름.
   - 대응: 메타데이터·이름·출처를 grader 입력에서 strip.

**G-Eval 패턴** (DeepEval) — chain-of-thought rubric으로 sub-criteria마다 별도 점수, 가중 평균.

```python
from deepeval.metrics import GEval
from deepeval.test_case import LLMTestCaseParams

correctness = GEval(
    name="Correctness",
    criteria="Determine whether the actual output is factually correct based on the expected output",
    evaluation_params=[LLMTestCaseParams.INPUT,
                       LLMTestCaseParams.ACTUAL_OUTPUT,
                       LLMTestCaseParams.EXPECTED_OUTPUT],
)
```

**Reference-based vs reference-free** — 정답이 있다면 reference에 grade하게 시키면 환각 격감 ([Openlayer](https://www.openlayer.com/blog/post/llm-as-judge-evaluation-guide)).

### 트레이드오프
- judge가 안정 인간 평가와 *agreement 80–90%* 라는 보고가 많지만 *내 도메인*에서는 별도 검증 필요.
- 모든 trace에 LLM-as-judge를 돌리면 token 비용이 본 작업과 같은 자릿수가 된다 — sampling이 필요.
- judge 모델을 바꾸면 historical score가 비교 불가 — judge 버전을 trace에 박아 두거나, 마이그레이션 시 backfill.
- bias는 *완전히* 제거되지 않는다. spot-check 5–10%는 사람으로 ([Pin-Yu Chen, IBM](https://www.montecarlodata.com/blog-llm-as-judge/)).

### 출처
- Anthropic, "Demystifying evals" — model-based grader 정의.
- DeepEval [G-Eval docs](https://deepeval.com/docs/metrics-llm-evals).
- Monte Carlo Data, "LLM-as-Judge: 7 Best Practices".
- Confident AI, "LLM-as-a-Judge — Complete Guide".
- [Arize, "LLM as a Judge"](https://arize.com/llm-as-a-judge/).

---

## 4. Outcomes-based grading — rubric으로 *결과만* 본다

### 무엇
trajectory를 매칭하는 대신 **목표 outcome을 rubric**으로 적고, grader가 그 rubric으로 채점한다. 같은 outcome의 다른 경로가 모두 valid가 된다.

### 언제
- 멀티 에이전트가 *복수의 valid trajectory*를 만들 때 (리서치, 디자인).
- task가 long-horizon이고 step-level 채점이 brittle할 때.
- "사용자 목표 달성"이 step보다 명확할 때.

### 어떻게

**Anthropic Outcomes 패턴** (Managed Agents 베타, 2026):
1. rubric을 자연어로 작성 — *"이 PR이 승인 가능한 상태인지"*, *"홈 화면에서 X 버튼 클릭 시 Y 다이얼로그가 뜨는지"*.
2. 에이전트는 rubric을 *작업 가이드*로 받고 그쪽으로 작업.
3. 별도 grader 에이전트가 *자기 컨텍스트 윈도우에서* 출력만 보고 rubric으로 채점 — generator의 reasoning에 영향받지 않음.
4. fail이면 grader가 무엇이 부족한지 지목 → 에이전트가 다시 시도.

**Anthropic 3-agent harness의 feature rubric** ([Effective harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)):

```json
{
  "features": [
    {"id": "new-chat-button",
     "status": "failing",
     "test_steps": [
       "Navigate to main interface",
       "Click the 'New Chat' button",
       "Verify a new conversation is created"
     ]},
    ...
  ]
}
```

처음에는 모두 `failing`. 코딩 에이전트가 진행하며 하나씩 `passing`으로 갱신. 평가가 *generator의 컨텍스트 안에서* 가능한 형태로 들어 있다.

### 트레이드오프
- rubric이 모호하면 grader도 모호해진다. 예: *"좋은 디자인"* → grader 서명이 안 나옴. 측정 가능한 sub-criteria로 분해.
- rubric을 generator에 *그대로* 보여주면 generator가 rubric을 짝사랑할 수 있다 (Goodhart). 일부는 generator에 숨기기 가능.
- pure outcomes는 trajectory의 비효율(불필요 도구 호출 폭발)을 못 잡는다 — cost/latency 메트릭과 *결합*해야.

### 출처
- Anthropic, "Effective harnesses for long-running agents" — feature rubric 예시.
- ["Anthropic will let its managed agents dream"](https://thenewstack.io/anthropic-managed-agents-dreaming-outcomes/) (The New Stack) — Outcomes 베타 발표.
- Anthropic Multi-agent research system 회고 — *"focus on outcomes rather than process compliance"*.

---

## 5. Generator / Evaluator 분리 — GAN-style 3-agent harness

### 무엇
Generator(작업)와 Evaluator(채점)를 *서로 다른 컨텍스트의 에이전트*로 분리. 더 들어가면 Planner까지 셋으로 분리.

### 언제
- 멀티 시간대 long-running 에이전트 (multi-hour autonomous coding).
- self-eval이 fail-loud 하지 않고 *false positive*로 가는 도메인 (frontend, design, generative writing).

### 어떻게

**Anthropic 3-agent harness** (2026-04 발표, [InfoQ](https://www.infoq.com/news/2026/04/anthropic-three-agent-harness-ai/)):

| 역할 | 컨텍스트 격리 | 책임 |
|---|---|---|
| **Planner** | 풀 spec 받음, output은 self-contained chunks | spec → 작업 분해 |
| **Generator** | 한 chunk + 진행 상태 파일만 | 코드 작성, 진행 파일 갱신 |
| **Evaluator** | 출력만 + Playwright MCP로 live 페이지 | rubric 기준 채점, 비판 작성 |

generator가 *"made code changes but failed to recognize the feature didn't work end-to-end"* 하던 self-eval 안티패턴을, evaluator가 **실제 브라우저로 클릭해 보면서** 깬다. *"do all testing as a human user would."*

결과 (같은 frontend task):
- Evaluator 없이: 20분/$9, broken core mechanics.
- 풀 loop: 6시간/$200, functionally correct.

**일반화** — 단순화하면 evaluator-optimizer 워크플로 ([Anthropic, "Building Effective Agents"](https://www.anthropic.com/research/building-effective-agents)). 두 에이전트면 충분한 경우도 많다.

### 트레이드오프
- **15× 토큰**(또는 그 이상) 비용. 가치가 큰 작업에만 정당화 ([Anthropic Multi-Agent Research](https://www.anthropic.com/engineering/multi-agent-research-system)).
- evaluator 자체가 LLM이라 *evaluator가 generator의 거짓 자신감을 따라가는* 안티패턴 가능 → evaluator를 다른 모델 패밀리로, few-shot 예시로 보정.
- Planner의 chunk 분해가 잘못되면 모든 generator가 잘못된 방향 — Planner 출력은 사람 review가 cheap insurance.

### 출처
- [Anthropic, "Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
- [Epsilla, "GAN-Style Agent Loop"](https://www.epsilla.com/blogs/anthropic-harness-engineering-multi-agent-gan-architecture).
- [InfoQ, "Anthropic Designs Three-Agent Harness"](https://www.infoq.com/news/2026/04/anthropic-three-agent-harness-ai/).
- Anthropic, "Building Effective Agents" (워크플로 #5 evaluator-optimizer).

---

## 6. Trace + span — OpenInference 10 span kinds로 보기

### 무엇
모든 LLM 호출·tool 호출·retrieval·embedding을 OpenTelemetry span으로 emit하고, parent-child 트리로 한 trace에 묶는다. OpenInference의 `openinference.span.kind` 값으로 의미를 구분.

### 언제
- 에이전트 디버깅이 "마지막 LLM 응답"만 봐서는 안 잡힐 때 (대부분).
- *어떤* 도구 호출에서 비용·지연이 폭발했는지 알아야 할 때.
- 백엔드(Phoenix / Datadog / Honeycomb / Langfuse)를 바꿔갈 가능성이 있을 때.

### 어떻게
- 프레임워크 자동 계측 — OpenInference Python 30+ 패키지 (OpenAI, Anthropic, LangChain, LlamaIndex, Bedrock, Mistral, ...). LangChain 4j, Spring AI도 지원.
- 직접 계측이 필요하면 OTel SDK + `gen_ai.*` attribute namespace + `openinference.span.kind` 로.

```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span(
    "tool.search_database",
    attributes={
        "openinference.span.kind": "TOOL",
        "tool.name": "search_database",
        "tool.parameters": json.dumps({"q": query}),
        "gen_ai.system": "anthropic",
    }
) as span:
    result = run_tool(query)
    span.set_attribute("output.value", str(result)[:1000])
```

10가지 span kinds (`CHAIN`, `LLM`, `TOOL`, `RETRIEVER`, `EMBEDDING`, `AGENT`, `RERANKER`, `GUARDRAIL`, `EVALUATOR`, `PROMPT`)로 *"show me all TOOL spans where the tool selection differed from the previous run"* 같은 질의가 가능 ([AgentMarketCap](https://agentmarketcap.ai/blog/2026/04/07/opentelemetry-ai-agents-observability-standard)).

### 트레이드오프
- OTel GenAI semconv는 2026-05 시점 *Development* status — attribute 이름이 변할 수 있다. `OTEL_SEMCONV_STABILITY_OPT_IN`로 버전 lock.
- 모든 span을 다 보내면 trace 데이터 양이 본 LLM 호출의 5–10×. sampling 필요 (prod 환경에서 100%면 비싸진다).
- input/output payload는 PII가 있을 수 있어 redaction이 boundary 책임.
- OpenInference vs OTel GenAI는 *경쟁이 아니라 layered* — OpenInference가 OTel을 wrap. 두 표준 다 호환되는 백엔드(Phoenix·Datadog 등)를 고르면 미래 안전.

### 출처
- [OpenTelemetry GenAI semconv](https://opentelemetry.io/docs/specs/semconv/gen-ai/).
- [arize-ai/openinference](https://github.com/Arize-ai/openinference) — span kinds 정의.
- [Phoenix tracing docs](https://arize.com/docs/phoenix/tracing/llm-traces).
- [Earezki, "OpenTelemetry just standardized LLM tracing"](https://earezki.com/ai-news/2026-03-21-opentelemetry-just-standardized-llm-tracing-heres-what-it-actually-looks-like-in-code/) (2026-03).

---

## 7. Eval-driven CI gate — PR 머지 게이트로 평가 묶기

### 무엇
`prompt`, system instruction, model 설정 변경 PR이 올라오면 CI가 골든셋·LLM-as-judge·trajectory matching 셋을 돌려 회귀를 차단.

### 언제
프롬프트·모델·도구 스키마가 *코드처럼 자주* 바뀌는 모든 production 에이전트.

### 어떻게

**최소 구성** — Braintrust / LangSmith CI / Traceloop GitHub Action / DeepEval 모두 패턴은 동일.

```yaml
# .github/workflows/eval.yml
on:
  pull_request:
    paths: ['prompts/**', 'agents/**']

jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install deepeval
      - run: deepeval test run tests/test_agent.py
      - name: Compare to baseline
        run: deepeval compare --base origin/main --head HEAD
```

**3-layer gate** ([TestQuality 2026](https://testquality.com/llm-regression-testing-pipeline/), Evidently 가이드):

| Layer | 무엇 | 비용 | gate |
|---|---|---|---|
| 1. Deterministic asserts | 도구 호출 여부, JSON schema, exit code 0 | 매우 낮음 | hard fail |
| 2. Trajectory match (subset) | 필수 도구가 다 불렸는가 | 낮음 | hard fail |
| 3. LLM-as-judge regression | 품질 점수가 baseline보다 *통계적으로* 낮은가 | 중간 | soft gate (PR comment + reviewer) |

baseline은 main 브랜치 평균 또는 최근 N개 deploy의 평균.

### 트레이드오프
- 골든셋이 너무 작으면 noise가 크다 — 한 task에서 score가 0.1 떨어진 게 진짜 회귀인지 분산인지 구분 안 됨. 50건 이상 권장.
- 비싼 LLM-as-judge를 모든 PR에 풀로 돌리면 token 비용이 GPU billing처럼 쌓인다. **PR diff가 prompt 영역만 건들면** 빠른 layer 1·2로, prompt+model 둘 다 건들면 풀로.
- "soft gate" 비율이 너무 높으면 reviewer fatigue — 일정 baseline 대비 *유의미한* drop만 PR comment로.
- Eval이 main에서 noisy하게 fail하기 시작하면 dev 신뢰가 깨진다 — main에서 매일 baseline 갱신.

### 출처
- [Traceloop, "Automated Prompt Regression Testing"](https://www.traceloop.com/blog/automated-prompt-regression-testing-with-llm-as-a-judge-and-ci-cd).
- [Evidently AI, "CI/CD for LLM apps"](https://www.evidentlyai.com/blog/llm-unit-testing-ci-cd-github-actions).
- [TestQuality, "LLM Regression Testing Pipeline"](https://testquality.com/llm-regression-testing-pipeline/) (2026).
- [Braintrust LLM evaluation guide](https://www.braintrust.dev/articles/llm-evaluation-guide).

---

## 8. Online evaluation + guardrails — 매 trace 위에서 채점

### 무엇
production 트래픽 *매 요청* (또는 sampled 비율)에 대해 score를 매기고, 정책 위반은 input/output guardrail로 막는다. offline eval과 다른 stage.

### 언제
- production에 들어간 직후 — drift·prompt injection·PII 누설을 *발견 즉시* 잡고 싶을 때.
- 규제 도메인 (금융, 헬스케어) — 사후가 아닌 사전 차단이 의무.

### 어떻게

**두 종류의 guardrail** ([LangChain guardrails](https://docs.langchain.com/oss/python/langchain/guardrails), [Datadog](https://www.datadoghq.com/blog/llm-guardrails-best-practices/)):

| 위치 | 검사 | 예시 |
|---|---|---|
| Input (pre-LLM) | prompt injection, PII scrubbing, topic restriction | NeMo Guardrails, Guardrails AI, OpenAI moderation |
| Output (post-LLM) | faithfulness, PII leakage, toxicity, refusal | Arize Phoenix online evals, Langfuse evals |

**Online evals** (Langfuse / Phoenix / Arize AX):
- 매 trace 또는 sampled 비율에 LLM-as-judge를 *비동기로* 돌려 score를 trace에 attach.
- 결과를 dashboard로 stream — drift 알람 가능 (faithfulness 점수가 7일 평균보다 -0.1 시 page).
- *"Running post-hoc evaluations on traces lets teams filter to flagged injection attack attempts, sensitive data exposures, or toxic inputs or outputs"* ([Datadog](https://www.datadoghq.com/blog/llm-guardrails-best-practices/)).

**hard guardrail vs soft guardrail**:
- hard — 검출 시 응답 차단 또는 fallback 메시지. 지연 +α.
- soft — 비동기 채점, alert만 — 사용자에는 영향 없음.

권고: **soft로 시작해서 데이터로 hard가 필요한 곳을 좁히기** ([Datadog](https://www.datadoghq.com/blog/llm-guardrails-best-practices/)). *"It's recommended to start with offline evaluations and only add performance guards if absolutely necessary."*

### 트레이드오프
- hard guardrail은 p95 latency를 200–500ms 추가시킨다. 합쳐 들어가면 1초 가까이.
- LLM 기반 guardrail은 자체적으로 false positive — 정상 요청을 차단. precision·recall 모니터링 필수.
- prompt injection 검출은 cat-and-mouse — 새 공격 패턴이 끊임없이 나옴. signature가 빠르게 stale.
- 모든 trace를 LLM-as-judge에 넘기면 비싸다. 1–10% sampling이 보통 시작점, alert가 잡히면 그 영역만 집중 sampling.

### 출처
- [LangChain Guardrails](https://docs.langchain.com/oss/python/langchain/guardrails).
- [Datadog, "LLM guardrails best practices"](https://www.datadoghq.com/blog/llm-guardrails-best-practices/).
- [Coralogix, "AI Guardrails"](https://coralogix.com/ai-blog/ai-guardrails/).
- [NVIDIA NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails).
- [guardrails-ai/guardrails](https://github.com/guardrails-ai/guardrails).
- [Arize Production LLM Evaluation](https://arize.com/llm-evaluation/production-llm-evaluation/).

---

## 9. Annotation queue → dataset promotion

### 무엇
production trace 중 흥미로운 (실패·경계·새 패턴) 것을 큐에 보내고, 사람이 라벨을 붙이며 *promote* 시켜 골든셋·regression set을 만드는 흐름.

### 언제
- 평가 자동화가 어느 정도 돼 있고, *새* 실패 패턴을 데이터셋으로 흡수하는 게 병목일 때.
- LLM-as-judge grader 자체를 보정하려고 인간 라벨이 필요할 때.

### 어떻게
- LangSmith annotation queue / Langfuse human annotation / Braintrust human review가 모두 비슷한 UI 제공.
- 트리거: `score < threshold`, `user_thumbs_down=true`, `tool_error=true`, `latency > p95` 등의 자동 룰로 큐 채움.
- 라벨러는 trace를 풀로 보고 (input + 모든 span + 최종 출력) score·comment·suggested_fix를 단다.
- 라벨이 일정 수 모이면 그 trace들을 dataset에 promote — 다음 PR의 회귀 게이트가 된다.

**RLTHF 패턴** ([arxiv 2502.13417](https://arxiv.org/html/2502.13417v1)) — LLM이 자신 없는(uncertain) sample만 인간 큐로, 나머지는 LLM auto-label.

### 트레이드오프
- annotator 간 일관성이 떨어지면 dataset 품질이 그대로 떨어진다 — 2명 라벨링 + 의견 조정(inter-annotator agreement) 측정 필수.
- 큐에 너무 많이 쌓이면 그냥 backlog가 된다. 트리거 룰을 좁게 — 중복 제거 / cluster representative 만 노출.
- 라벨이 많아질수록 골든셋이 *과거*의 분포로 편향. production drift가 있다면 trace 시점도 *함께* 저장하고 시간으로 weight 내림.
- 골든셋이 곧 *grader 자체의 보정 기준*이 되므로 라벨에 의문이 있을 때 라벨러를 추적할 수 있어야 — `annotator_id` 필드 필수.

### 출처
- [Langfuse, "Human Annotation for LLM apps"](https://langfuse.com/docs/scores/annotation).
- [LangSmith Evaluation docs](https://docs.langchain.com/langsmith/evaluation) — annotation queue.
- John Snow Labs, "Top 6 Annotation Tools for HITL LLMs Evaluation".
- [RLTHF: Targeted Human Feedback](https://arxiv.org/html/2502.13417v1) (arXiv 2025).

---

## 10. Multi-turn / thread-level evaluation

### 무엇
multi-turn 대화 *전체*를 단위로 채점한다. 한 턴이 정답이라도 대화가 사용자 목표를 미달하면 fail.

### 언제
- 챗봇·콘시어지·고객지원 에이전트.
- *"agent feels worse"*가 어느 한 턴이 아니라 흐름의 누적인 도메인.

### 어떻게

**LangSmith Multi-turn Evals (2025-10-23)** ([LangChain blog](https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith)):
- session_id로 묶인 trace들이 자동으로 한 *thread*가 됨.
- conversation 종료(또는 N분 idle) 시 자동 LLM-as-judge — *"Measure whether your agent accomplished the user's goal across an entire interaction"*.
- 사용자가 judge prompt를 정의: 사용자 의도 추론 → 작업 완료 여부 → 미완료 사유.

**평가 차원** ([Anthropic Demystifying evals — conversational]):
- task completion (사용자 목표 달성?)
- turn limits (몇 턴 안에 풀었나)
- interaction quality (사용자가 frustrated 신호?)
- "second LLM이 사용자를 simulate" — synthetic conversation eval에 사용.

**simulator pattern**:
- Generator agent를 평가용 *user simulator agent*와 마주 앉힌다.
- 대본 없이 simulator가 자유롭게 페르소나를 연기, 양쪽이 자연스럽게 대화.
- LLM-as-judge가 끝나고 thread를 채점.

### 트레이드오프
- 한 thread가 길어질수록 judge prompt 크기 ↑ → 토큰 비용 ↑.
- 사용자 의도가 *끝까지 안 명확*한 경우 judge가 잘못 추정하기 쉬움 — judge에 "intent unclear" 옵션을 주는 게 안전.
- multi-turn은 비결정성이 누적 — pass^k로 보면 점수가 가파르게 떨어진다. 이게 단발 eval보다 정직한 신호.
- thread 단위 평가는 *한 번 끝난 뒤*에만 가능 — real-time guardrail에는 불충분. turn 단위 빠른 가드와 thread 단위 후속 평가를 *같이*.

### 출처
- [LangChain blog, "Insights Agent and Multi-turn Evals"](https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith).
- Anthropic, "Demystifying evals" — conversational agents 섹션.
- DeepEval [conversational metrics](https://deepeval.com/).

---

## 11. Insight clustering — 실패를 자동으로 묶기

### 무엇
production trace에 LLM agent를 띄워 *비슷한 실패 패턴*을 클러스터링하고 카테고리·root cause 후보를 생성한다.

### 언제
- trace 양이 사람이 손으로 분류 불가능한 규모.
- "어디부터 고쳐야 하나" 우선순위가 안 보일 때.

### 어떻게
**LangSmith Insights Agent (2025-10-23)** ([LangChain blog](https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith)):
- 사용자가 grouping 차원을 고름: usage pattern / negative interactions / custom filter (기간·키워드).
- 분석 시간 ≤15분, 결과는 카테고리별 trace 리스트로 제공.
- *"cluster based on how your agent is messing up, looking for signals in each conversation that indicate a negative interaction (user getting frustrated, etc), and then group the root causes."*

**일반화 워크플로**:
1. trace에서 임베딩 추출 (또는 LLM이 한 줄 요약).
2. clustering (HDBSCAN / k-means / LLM agent grouping).
3. 각 cluster에 LLM이 라벨·representative trace 선정.
4. 사람이 cluster를 이슈로 변환 (*"이 30개는 모두 'tool X 인자 검증 부족'에서 옴"*).

### 트레이드오프
- 분석 모델이 *잘못된 카테고리화*를 하면 우선순위가 어긋난다. 첫 라운드는 사람이 cluster label만 검증하는 게 안전.
- 너무 큰 trace 모집단을 한 번에 던지면 cluster가 generic해짐 — 시간·feature 슬라이스로 좁혀서 돌리기.
- *"frustration signal"* 자체가 LLM 추정이라 도메인에 따라 noise — thumbs-up/down·explicit feedback이 있다면 그쪽이 우선 신호.

### 출처
- [LangChain blog, "Insights Agent"](https://www.langchain.com/blog/insights-agent-multiturn-evals-langsmith).
- [LangSmith Insights Agent reverse-engineering](https://gist.github.com/Dowwie/1dada92c45f80c472c667bb6c99e0e59) — 내부 동작 추정.

---

## 12. Cost / latency tracking per span

### 무엇
모든 LLM·tool span에 token in/out·USD·duration·retry count attribute를 attach. trace 단위로 합산해 quality metric과 *함께* 본다.

### 언제
- 비용이 본 작업의 1× 이상으로 들어가는 모든 production 에이전트.
- 모델 교체(downgrade·캐시) 가설을 객관적으로 검증해야 할 때.

### 어떻게
- OTel GenAI metrics: `gen_ai.client.token.usage`, `gen_ai.client.operation.duration` 표준.
- LangSmith / Langfuse / Phoenix 모두 자동 capture, custom price table 설정 가능.
- 대시보드에 *quality vs cost* 산점도 — 같은 task에서 모델·prompt 변경이 quality는 비슷한데 cost는 절반이라면 즉시 ship 후보.

**핵심 메트릭**:

| 메트릭 | 단위 | 알람 기준 |
|---|---|---|
| cost per resolved task | USD/task | baseline +30% |
| token p95 per trace | tokens | baseline +50% |
| tool call count per task | count | baseline +2 (불필요 retry?) |
| span duration p95 | sec | SLO 위반 |
| retry rate | % | baseline +5%p |

["multi-agent uses ~15× tokens of single agent — value must justify"](https://www.anthropic.com/engineering/multi-agent-research-system) — Anthropic이 자신들의 멀티 에이전트 케이스에 대해 한 정직한 표현. 이걸 *측정해서* 정당화해야 한다.

### 트레이드오프
- 비용 메트릭만 보면 quality 회귀를 놓친다 — *항상* quality와 짝으로.
- token count는 모델마다 토크나이저가 달라 절대 비교가 어렵다 — USD로 환산하는 게 더 안정.
- per-span attribution이 정확하려면 SDK가 streaming chunk 단위까지 잡아야. 자체 framework는 streaming 시 누락 흔함.
- "모델을 다운그레이드하면 cost는 떨어지지만 trajectory가 길어져 *전체* token이 오히려 늘어남" 케이스가 흔하다 — trace 전체 합으로 비교.

### 출처
- [OpenTelemetry GenAI metrics](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-metrics/).
- [Anthropic Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system).
- [LangSmith observability](https://www.langchain.com/langsmith/observability).
- [Langfuse cost tracking](https://langfuse.com/docs).

---

## 13. pass^k regression — 비결정성을 정직하게 보고

### 무엇
같은 task를 k번 돌려서 *모두 통과*하는 비율을 본다. 단일 통과율(pass@1)이 숨기는 분산을 드러낸다.

### 언제
- production 신뢰성 SLO를 정해야 할 때.
- 모델 변경 전후 비교 — pass@1만 보면 *비슷*해 보이지만 pass^5는 격차 큼.

### 어떻게
- 골든셋의 각 task를 k=3~10번 돌림 (temperature는 production 설정 그대로).
- pass@k = "k번 중 한 번이라도 통과", pass^k = "k번 모두 통과".
- production SLO에 가까운 건 **pass^k** — 사용자는 매 시도마다 새로 본다.

["pass@k and pass^k diverge with k. pass@k goes up, pass^k goes down. Production reliability is closer to pass^k"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) — Anthropic.

### 트레이드오프
- k=10이면 비용도 10×. 핵심 골든셋(20–50) 상위 sample만 풀 k 반복.
- pass^k가 원하는 만큼 안 올라간다고 temperature를 0으로 내리면 *다른* 종류의 회귀(다양성·robustness 부족) 위험.
- environment isolation이 깨지면 k번 사이에 누수가 생겨 pass^k가 인위적으로 올라간다 — 환경 reset 필수.

### 출처
- Anthropic, "Demystifying evals for AI agents" — pass@k / pass^k 정의.
- SWE-bench Verified pattern (실행 가능한 deterministic test로 outcome 채점).

---

## 14. Swiss Cheese — 평가 레이어 6장 겹치기

### 무엇
어떤 한 평가 레이어도 모든 결함을 잡지 못한다. 정직한 운영은 *서로 다른 위치에 구멍이 있는* 6개 레이어를 겹치는 것.

### 언제
production 트래픽이 늘고 incidents가 *어떤 종류든* 중요해질 때 (모든 production 에이전트 결국).

### 어떻게

| 레이어 | 잡는 것 | 비용 | 패턴 # |
|---|---|---|---|
| 1. Code-based unit eval (CI) | 명백한 deterministic 회귀 | 매우 낮음 | 7 |
| 2. LLM-as-judge regression (CI/preview) | 품질·뉘앙스 회귀 | 중간 | 3, 7 |
| 3. Trajectory match (CI) | 도구 호출 순서·집합 회귀 | 낮음 | 2 |
| 4. Production trace + online guardrail | drift, prompt injection, PII | 중간 | 6, 8 |
| 5. Annotation queue (5–10% spot) | 새 grader 보정, edge case | 높음 (sampled) | 9 |
| 6. A/B test / explicit user feedback | 실제 사용자 가치 | 가장 가까운 ground truth | (다음 절) |

["no single evaluation layer catches every issue"](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) — Anthropic.

### 트레이드오프
- 6장 다 운영하면 ops 부담이 큰 게 사실 — 시작은 1·2·4 셋으로, 사고가 늘 때마다 한 장씩 추가.
- 레이어가 늘면 *어디서* 잡혔는지 추적이 중요 — incident 회고 시 "레이어 N이 잡았어야 했다"가 명확해야 다음 PR의 우선순위.
- 모든 레이어가 같은 model family(예: GPT를 grader로, GPT가 generator)면 self-preference로 같은 구멍에 약함 — grader는 *다른* family로.

### 출처
- Anthropic, "Demystifying evals for AI agents" — Swiss Cheese 모델 명시.
- 의료·항공 안전공학에서 가져온 일반 frame.

---

## 패턴 간 관계 — 한 에이전트의 평가 시스템 만들기

위 14개를 다 쓰는 게 아니라, 단계적으로 쌓는다. 보통의 진행 순서:

```
[start] ──→ #1 골든셋 20–50건
              │
              ├─→ #2 trajectory match (subset 모드)
              │
              └─→ #3 LLM-as-judge (pointwise, position swap)
                       │
                       └─→ #7 CI gate (deterministic + judge regression)
                                │
production 진입 ──→ #6 OpenInference trace 계측
                       │
                       ├─→ #8 online guardrail (soft → 필요시 hard)
                       │
                       ├─→ #12 cost / latency tracking
                       │
                       └─→ #9 annotation queue → 골든셋에 promote (loop back)

규모가 커지면 ──→ #11 insight clustering
              ──→ #10 multi-turn thread eval
              ──→ #13 pass^k SLO

high-stakes 멀티 에이전트 ──→ #5 generator/evaluator 분리
                          ──→ #4 outcomes-based grading

전체에 걸쳐 ──────────→ #14 Swiss Cheese (6 레이어 동시 운영)
```

이 그래프는 [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)의 *"start simple, add complexity only when needed"* 원칙과 같은 정신.
