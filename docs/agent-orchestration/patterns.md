# 에이전트 오케스트레이션 — 패턴 카탈로그

> 마지막 업데이트: 2026-05-10
> 모든 패턴은 출처가 있는 사례에서 추출했다. 각 항목은 **무엇 / 언제 / 어떻게 / 트레이드오프 / 출처** 순.

이 문서의 가정: [overview.md](./overview.md)의 용어와 단일/멀티 에이전트 프레임을 이미 읽었다.

패턴 목록:
1. [Single-agent + Tools (Default)](#1-single-agent--tools-default)
2. [Orchestrator-Worker (Lead + Subagents)](#2-orchestrator-worker-lead--subagents)
3. [Supervisor (LangGraph 스타일)](#3-supervisor-langgraph-스타일)
4. [Swarm / Peer Handoff](#4-swarm--peer-handoff)
5. [Subagent for Context Isolation](#5-subagent-for-context-isolation)
6. [Parallel Tool Calls / Fan-out](#6-parallel-tool-calls--fan-out)
7. [Routing & Triage Handoff (OpenAI Agents SDK)](#7-routing--triage-handoff-openai-agents-sdk)
8. [Plan-and-Execute](#8-plan-and-execute)
9. [Evaluator–Optimizer (Generator + Critic)](#9-evaluatoroptimizer-generator--critic)
10. [Long-Running Agent Harness (Planner-Generator-Evaluator + 세션 핸드오프)](#10-long-running-agent-harness)
11. [Eval-Driven Agent Design](#11-eval-driven-agent-design)

---

## 1. Single-agent + Tools (Default)

**무엇**
하나의 모델 인스턴스가 전체 작업을 ReAct 루프(생각 → 도구 → 관찰 → 반복)로 끝까지 수행. 멀티 에이전트의 반대편 기본값.

**언제 쓰나**
- 작업이 단일 컨텍스트 윈도우 안에 들어옴.
- 결정 간 의존성이 강해 한 에이전트가 전체 흐름을 봐야 함 (대부분의 코딩 작업).
- 멀티 에이전트의 토큰 비용·복잡성이 가치를 정당화하지 못함.

**어떻게 적용**

```
사용자 질의 ──▶ [Agent (LLM + tools + memory)] ──▶ 결과
                       │  (loop)
                       ▼
                  Bash / Read / Edit / WebSearch / MCP ...
```

- 모델에게 충분한 컨텍스트와 도구를 주고, 자체 ReAct 루프로 진행.
- 컨텍스트가 커지면 compaction·요약·외부 메모리(파일)로 오프로드.
- 위험 도구는 권한 모드(`acceptEdits`, `plan`)와 훅으로 가드.

**트레이드오프**
- 장점: 단순. 추적·디버깅 쉬움. 결정 간 일관성 보장. 토큰·LLM 호출 적음.
- 단점: 컨텍스트 윈도우가 병목. 병렬 가능한 작업도 직렬화됨. 너무 큰 작업은 결국 코히런스를 잃는다.

**출처/예시**
- Cognition의 ["Don't Build Multi-Agents"](https://cognition.ai/blog/dont-build-multi-agents) — Devin이 채택한 기본 자세.
- Anthropic [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — "Agents can be used for open-ended problems" + 단순함이 우선.
- Claude Code 자체 — 사용자 메인 세션은 단일 에이전트, 서브에이전트는 보조.

---

## 2. Orchestrator-Worker (Lead + Subagents)

**무엇**
중앙 LLM(orchestrator/lead)이 작업을 동적으로 분해하고, 워커 LLM들에게 위임하고, 결과를 합성한다. 분해와 위임 자체를 코드가 아니라 LLM이 결정하는 것이 routing/parallelization 워크플로우와의 차이.

**언제 쓰나**
- 어떤 단계가 필요한지 미리 예측하기 어려운 **너비 우선(breadth-first) 탐색** — 리서치, 시장 조사, 후보 풀 좁히기.
- 정보량이 단일 컨텍스트를 초과.
- 하위 작업들이 진정으로 병렬 가능하고 결과가 단순 결합 가능 (요약/인용).
- 가치가 토큰 비용 ~15× 증가를 정당화.

**어떻게 적용**

```
              ┌────────────────────────┐
              │  Lead Agent (Opus)     │
              │  - plan strategy       │
              │  - spawn subagents     │
              │  - synthesize results  │
              └────────────────────────┘
                 │           │           │
        ┌────────▼─┐  ┌──────▼───┐  ┌───▼──────┐
        │Subagent 1│  │Subagent 2│  │Subagent 3│
        │ (Sonnet) │  │ (Sonnet) │  │ (Sonnet) │
        └──────────┘  └──────────┘  └──────────┘
        각자 독립 컨텍스트에서 도구 호출
```

핵심 프롬프트 엔지니어링 (Anthropic이 production에서 학습):
- **각 서브에이전트에게 명시적 task spec**: 목표, 출력 포맷, 도구 가이드, 작업 경계, 사용해야 할 소스.
- **노력 스케일링 룰**: "단순 사실 확인 1 에이전트, 3~10 도구 호출 / 직접 비교 2~4 에이전트, 각 10~15 호출 / 복잡한 연구 더 많이". 안 그러면 "50개 서브에이전트 스폰" 같은 폭주가 흔함.
- **도구 사용 휴리스틱 명시**: 사용 가능 도구를 먼저 점검, 쿼리는 너무 길지 않게.
- **결과 전달**: 외부 시스템(파일/메모리)에 저장 후 lightweight 참조만 부모에게 — 토큰 절감.

**트레이드오프**
- 장점: 병렬화로 wall-clock 시간 ~90% 단축 가능. 단일 컨텍스트 한계 극복. Anthropic 내부에서 +90.2% 성능.
- 단점: **약 15× 토큰**. 디버깅 난도 급증(여러 트레이스 합쳐 봐야 함). 서브에이전트가 작업을 오해하면 같은 검색을 중복하거나 엉뚱한 방향으로 감. 강한 의존성 작업(코딩)에는 부적합.

**흔한 실패 모드**
- **과도한 스폰**: 단순 질의에 서브에이전트 50개 — 명시적 노력 룰로 해결.
- **중복 작업**: 두 서브에이전트가 같은 검색 — 작업 경계 프롬프트로 해결.
- **소스 편향**: SEO 농장이 권위 있는 출처를 누름 — 평가 주도로 발견.
- **긴 쿼리**: 너무 구체적인 쿼리는 결과가 적음 — 휴리스틱 명시.

**출처/예시**
- Anthropic [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — Opus(lead) + Sonnet(workers). 이 패턴의 reference 구현.
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — orchestrator-workers 워크플로우.

---

## 3. Supervisor (LangGraph 스타일)

**무엇**
Orchestrator-Worker의 **명시적 그래프 구현**. 한 supervisor 노드가 라우팅 결정을 모두 내리고, 워커 노드는 결과를 supervisor로 돌려보낸다. 모든 통신이 supervisor를 거친다 (hub-and-spoke).

**언제 쓰나**
- 라우팅 정확도가 latency보다 중요할 때.
- 정렬된 실행 + validation gate가 필요할 때.
- 중간 결과를 보고 동적으로 재라우팅해야 할 때.
- 서드파티 에이전트와 통합 (워커가 서로를 몰라도 됨).

**어떻게 적용** (LangGraph 의사 코드)

```python
from langgraph_supervisor import create_supervisor

supervisor = create_supervisor(
    agents=[research_agent, writer_agent, math_agent],
    model="anthropic/claude-sonnet-4",
    prompt="You route requests to the right specialist..."
)
```

기본 흐름: 사용자 입력 → supervisor가 어느 워커가 처리할지 결정 → 워커 실행 → 결과 supervisor로 → 종료 여부 결정 → 반복.

**트레이드오프**
- 장점: **추론하기 쉽다** — 라우팅 노드 하나, 명확한 제어 흐름, 트레이스에 모든 결정이 보임. 가장 generic, 거의 모든 시나리오에 동작.
- 단점: supervisor의 **"translation 오버헤드"** — 워커가 사용자에게 직접 응답 못 하므로 supervisor가 메시지를 다시 다룸. swarm 대비 ~20–40% 토큰 더 사용. 8–12 라운드 후 supervisor 컨텍스트 포화 위험.

**LangChain 자체 벤치마크 결과** ([benchmarking-multi-agent-architectures](https://www.langchain.com/blog/benchmarking-multi-agent-architectures)):
- swarm이 약간(slight) 더 정확.
- 그러나 supervisor는 서드파티 에이전트 호환성 + 디버깅 용이성으로 **권장 출발점**.
- 직접 메시지 포워딩(forward_message_tool)·핸드오프 클러터 제거로 supervisor도 ~50% 성능 향상.

**출처/예시**
- [langgraph_supervisor 레퍼런스](https://reference.langchain.com/python/langgraph-supervisor) — `create_supervisor`, `create_handoff_tool`, `create_forward_message_tool`.
- [LangGraph 멀티 에이전트 벤치마크](https://www.langchain.com/blog/benchmarking-multi-agent-architectures).

---

## 4. Swarm / Peer Handoff

**무엇**
모든 에이전트가 같은 레벨에 있고, 핸드오프 도구를 통해 **직접 서로에게 제어권을 넘긴다**. 중앙 supervisor 없음. 한 시점에 활성 에이전트는 하나.

**언제 쓰나**
- latency가 결정적으로 중요할 때 (한 보고에서 supervisor → swarm 전환으로 end-to-end 응답시간 ~40% 단축).
- 에이전트 간 의존도가 낮고 컨텍스트가 자체적으로 충족될 때.
- 모든 에이전트가 서로를 알 수 있는 폐쇄 시스템 (서드파티 어려움).

**어떻게 적용** (LangGraph)

```python
from langgraph_swarm import create_swarm, create_handoff_tool

flight_booking = make_agent(tools=[search_flights, create_handoff_tool(agent_name="hotel")])
hotel_booking  = make_agent(tools=[search_hotels,  create_handoff_tool(agent_name="flight")])

app = create_swarm([flight_booking, hotel_booking], default_active_agent="flight")
```

또는 OpenAI Agents SDK의 `handoffs=[other_agent]`도 본질적으로 swarm과 같은 모델.

**트레이드오프**
- 장점: 더 적은 LLM 호출, 더 적은 토큰 (supervisor의 translation 단계 없음), 더 낮은 latency. 살짝 더 정확하다는 벤치마크.
- 단점: 모든 에이전트가 핸드오프 그래프를 알아야 함 → 서드파티 통합 불가. 8–10번 이상 핸드오프 후 cascading drift 위험. 중앙 감사 포인트 부재 → 트레이스 재구성 어려움.

**Augment Code의 시나리오 가이드** ([swarm-vs-supervisor](https://www.augmentcode.com/guides/swarm-vs-supervisor)):
- swarm: read-heavy 탐색·요약, 독립 모듈 병렬, 낮은 의존도.
- supervisor: 정렬된 실행 + 검증 게이트, 동적 재라우팅, 단일 컨텍스트 초과.

**출처/예시**
- [langgraph_swarm 레퍼런스](https://reference.langchain.com/python/langgraph-swarm).
- [OpenAI Swarm](https://github.com/openai/swarm) 원본 (educational/experimental, 2024-10) → 후속이 OpenAI Agents SDK.

---

## 5. Subagent for Context Isolation

**무엇**
부모 에이전트가 잡일(검색, 로그 파싱, 큰 코드 탐색)을 **새로운 컨텍스트 윈도우의 서브에이전트**에게 위임. 서브에이전트는 자기 컨텍스트에서 도구를 사용하고, 부모에게는 **요약만** 돌려준다.

→ 멀티 에이전트의 가장 *비논쟁적인* 형태. Cognition도 단일 컨텍스트 변형(fork)으로 권장.

**언제 쓰나**
- 어떤 작업이 부모 메인 컨텍스트를 검색 결과·로그·큰 파일로 폭발시키려 할 때.
- 작업이 자체 완결적 (입력→요약 출력).
- 특정 도구만 허용한 격리 실행이 필요 (보안·재현성).
- 더 작고 빠른 모델로 비용 절감 (예: Haiku 서브에이전트).

**어떻게 적용** (Claude Code 정의 예)

```yaml
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
permissionMode: plan
---

You are a code reviewer. Analyze the code and provide
specific, actionable feedback.
```

호출 시 부모는 Agent(구 Task) 도구로 서브에이전트 이름과 작업 프롬프트만 넘긴다. 부모 컨텍스트에는 **서브에이전트 최종 응답만** 들어온다.

Claude Agent SDK 등가:

```python
options = ClaudeAgentOptions(
    allowed_tools=["Read", "Glob", "Grep", "Agent"],
    agents={
        "code-reviewer": AgentDefinition(
            description="Code reviewer for quality and security.",
            prompt="Analyze code quality...",
            tools=["Read", "Glob", "Grep"],
        )
    },
)
```

서브에이전트 옵션: `tools`/`disallowedTools` (도구 화이트/블랙리스트), `model` (haiku/sonnet/opus), `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `memory`(persistent), `isolation: worktree`(임시 git worktree).

**Fork 변형**: 부모 컨텍스트를 통째로 상속받는 서브에이전트 — 입력 격리는 잃지만 출력 격리는 유지. Cognition의 "share full context" 원칙을 일부 만족.

**트레이드오프**
- 장점: 메인 컨텍스트 절약 → 더 긴 세션 가능. 도구 권한 격리. 모델 다운시프트로 비용 절감. 한 세션 내에서 동작 (멀티 세션 조율 불필요).
- 단점: 부모는 서브에이전트의 추론·중간 결과를 못 봄 — 디버깅 어려움. 서브에이전트는 다른 서브에이전트를 스폰 못 함 (Claude Code 정책). 서브에이전트 간 통신 없음.

**Claude Code의 빌트인 서브에이전트** (참고):
- **Explore** (Haiku, read-only): 코드베이스 탐색. 결과를 요약만 반환.
- **Plan** (inherit, read-only): plan 모드 중 자동 호출, 무한 중첩 방지.
- **General-purpose**: 모든 도구, 복잡한 다단계 위임.

**출처/예시**
- [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) — production-grade 정의 형식.
- [Claude Agent SDK subagents](https://platform.claude.com/docs/en/agent-sdk/subagents).
- [MindStudio: sub-agents context management](https://www.mindstudio.ai/blog/sub-agents-claude-code-context-management).

---

## 6. Parallel Tool Calls / Fan-out

**무엇**
한 에이전트가 **여러 도구 호출을 병렬로 동시 발사** (한 어시스턴트 턴에서 N개의 tool_use 블록). 멀티 에이전트와 다르게 한 모델 인스턴스가 모두 보고 다음 턴에서 결과를 합친다.

**언제 쓰나**
- 독립적인 정보 수집 (여러 파일 동시 읽기, 여러 API 동시 호출, 여러 검색 쿼리).
- 부모 컨텍스트에 결과 모두 들어와도 부담스럽지 않을 때.
- 멀티 에이전트보다 더 가벼운 병렬화로 충분할 때.

**어떻게 적용**
Anthropic API와 대부분 SDK가 한 어시스턴트 응답에 여러 `tool_use` 블록을 허용. 모델에게 명시적으로 "If you need multiple independent pieces of information, request them all in a single message via parallel tool calls."를 시스템 프롬프트에 넣는 것이 결정적.

병렬 도구 호출이 단일 에이전트 컨텍스트를 직접 압박하므로, **결과 크기가 큰 경우에는 [패턴 5: subagent for context isolation]을 결합**해 서브에이전트가 fan-out을 흡수하게 한다. Anthropic Research 시스템에서 "parallel execution (3-5 subagents simultaneously) cut research time by up to 90%"는 정확히 이 결합.

**트레이드오프**
- 장점: 단순. 한 모델 인스턴스가 결과를 보고 통합하므로 일관성 유지. 멀티 에이전트의 토큰·복잡성 폭증 없이 wall-clock 단축.
- 단점: 결과 합쳐서 컨텍스트가 빠르게 부풀음. 모델이 학습 분포에 따라 병렬 호출을 잘 하지 않을 수도 있어 프롬프트로 유도 필요. 호출 간 의존성이 있으면 직렬화 필요.

**출처/예시**
- Anthropic Research 시스템 — fan-out + 서브에이전트 결합.
- Claude Code의 일상적 동작 — 동일 턴에서 여러 Read·Grep 동시 호출.

---

## 7. Routing & Triage Handoff (OpenAI Agents SDK)

**무엇**
하나의 triage 에이전트가 사용자 입력을 분류하고, 여러 등록된 핸드오프 중 하나로 **제어권을 완전히 이전**. 일단 핸드오프되면 새 에이전트가 사용자와의 대화를 소유.

핵심 차이: handoff는 단순 함수 호출이 아니다 — **active agent 자체가 바뀐다**. 메시지 히스토리는 다음 에이전트로 그대로 전달(또는 input_filter로 가공).

**언제 쓰나**
- 고객 지원처럼 명확히 분리된 도메인이 있을 때 (주문 / 환불 / FAQ).
- 라우팅 자체가 워크플로우의 일부이고, 선택된 specialist가 사용자 인터페이스를 owning해야 할 때.

**어떻게 적용**

```python
from agents import Agent, handoff
from pydantic import BaseModel

class EscalationData(BaseModel):
    reason: str
    severity: str

billing_agent = Agent(name="Billing", instructions="...", tools=[...])
refund_agent  = Agent(name="Refund",  instructions="...", tools=[...])

triage_agent = Agent(
    name="Triage",
    instructions="Route to the right specialist.",
    handoffs=[
        billing_agent,
        handoff(refund_agent, input_type=EscalationData, on_handoff=log_escalation),
    ],
)
```

LLM이 `transfer_to_billing` 또는 `transfer_to_refund` 도구를 호출하면 SDK가 active agent를 교체.

**Handoff vs Agent-as-tool 결정 기준** (OpenAI 공식 가이드):
- **Handoff**: routing이 워크플로우의 일부, specialist가 다음 사용자 인터랙션을 소유해야 함.
- **Agent.as_tool()**: specialist가 bounded 부분 작업을 도와야 하지만 사용자 대화는 원래 에이전트가 계속 유지.

**트레이드오프**
- 장점: 사용자 의도에 맞춰 적절한 도구·프롬프트·정책 셋이 인계됨. 메시지 히스토리 전체가 넘어가 컨텍스트 손실 없음. metadata(escalation reason 등) 구조화된 인계 가능.
- 단점: 핸드오프 후 원래 에이전트로 돌아오려면 명시적 back-handoff 필요. 핸드오프 그래프가 커지면 LLM이 잘못된 라우팅 선택 가능 → 평가 필요. 모든 에이전트가 같은 SDK·런타임에 살아야 함 (서드파티 어려움).

**출처/예시**
- [OpenAI Agents SDK handoffs docs](https://openai.github.io/openai-agents-python/handoffs/).
- [Orchestrating Agents: Routines and Handoffs (OpenAI Cookbook)](https://cookbook.openai.com/examples/orchestrating_agents).

---

## 8. Plan-and-Execute

**무엇**
한 LLM이 먼저 **전체 다단계 계획을 작성**하고, 별도의 executor가 단계별로 실행. 각 단계 후 결과를 보고 필요시 재계획. ReAct가 단계마다 LLM 추론을 부르는 것과 대비된다.

**언제 쓰나**
- 단계 수가 크고 미리 큰 그림을 보고 시작하는 게 유리할 때.
- 비용·latency 절감이 중요할 때 (단계 실행은 가벼운 모델이나 결정론적 코드 가능).
- 단계가 명시적으로 보여 감사·승인이 필요할 때 (사용자에게 plan을 검토하게 함).

**어떻게 적용**

```
사용자 질의 ──▶ [Planner LLM] ──▶ [Plan: step1, step2, step3, ...]
                                          │
                                          ▼
                              [Executor: step별 도구 호출 / sub-LLM]
                                          │
                                          ▼
                          [Replan if needed] ──▶ 최종 결과
```

대표 변형:
- **Plain plan-and-execute**: 위 그대로.
- **ReWOO (Reasoning WithOut Observation)**: 모든 단계를 미리 계획하고 변수 placeholder로 연결, 마지막에 한 번만 LLM이 합치기.
- **LLMCompiler**: 의존성 DAG로 계획을 짜서 가능한 단계를 병렬화.

Claude Code의 Plan 모드도 가벼운 변형: 사용자가 `plan` 권한 모드로 진입하면 모델은 코드를 변경하지 않고 단계 계획만 작성, 사용자가 승인하면 실행.

**트레이드오프**
- 장점: LLM 호출 수 감소. 단계가 가벼운 모델/코드로 가능. 사용자 승인 게이트 자연스러움. 큰 작업의 코히런스 유지.
- 단점: 환경이 동적이거나 단계 결과가 다음 결정을 크게 바꾸는 작업에서는 plan이 빠르게 stale해짐 → 잦은 재계획. Plan이 부정확하면 잘못된 단계를 끝까지 실행할 위험.

**ReAct와의 선택 기준**:
- 다음 단계가 직전 결과에 강하게 의존 → ReAct.
- 단계가 미리 계획 가능하고 다수 → Plan-and-Execute.
- 둘 다 → 외부 plan, 내부 ReAct 하이브리드 (Anthropic Research가 사실상 이 형태).

**출처/예시**
- [LangChain — Plan-and-Execute Agents](https://www.langchain.com/blog/planning-agents).
- [ReAct vs Plan-and-Execute 실용 비교 (DEV)](https://dev.to/jamesli/react-vs-plan-and-execute-a-practical-comparison-of-llm-agent-patterns-4gh9).

---

## 9. Evaluator–Optimizer (Generator + Critic)

**무엇**
한 LLM이 결과를 생성하고, **별도 LLM이 평가/피드백**을 주어 루프 안에서 반복 정제. 두 역할을 분리하는 게 핵심 — 같은 모델이 자기 작품을 평가하면 "사실 이건 좋은데..."로 합리화하는 경향이 강해 quality gate가 동작 안 함.

**언제 쓰나**
- 명확한 평가 기준이 있고 반복 정제로 품질이 오를 때 (글쓰기, 디자인, 번역, 코드 리팩터).
- 첫 시도가 거의 정답이지만 "한 끗" 부족할 때.
- 측정 가능한 rubric으로 환원할 수 있는 주관적 품질.

**어떻게 적용**

```
[Generator LLM] ──▶ candidate
        ▲                │
        │                ▼
        └── [Evaluator LLM] ──▶ pass? ──▶ 결과
                  │ feedback
                  └────── (loop)
```

핵심 디테일 (Anthropic의 "harness design for long-running apps"에서):
- **주관적 기준을 측정 가능한 rubric으로 인코딩**. 디자인 작업이라면 "originality / craft / functionality" 같이 개별 채점 가능한 기준으로 분해.
- Evaluator는 별도 모델이거나 다른 시스템 프롬프트로 분리. 사실상 다른 에이전트.
- 5–15회 critique-and-refine 사이클이 흔함 (복잡한 창작/풀스택 작업).

**트레이드오프**
- 장점: 주관적·미적 품질을 자동으로 끌어올림. 모델 self-grading의 "좋아 보입니다" 편향 회피. plan 검증·테스트 합격 같은 명시적 게이트 가능.
- 단점: 토큰 비용 N배. 무한 루프 / 발산 위험 → max iterations과 stop criteria 필수. evaluator가 잘못된 기준이면 generator가 그쪽으로 끌려감.

**출처/예시**
- Anthropic [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — "evaluator-optimizer" 워크플로우.
- Anthropic [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — "separating the agent doing the work from the agent judging it proves to be a strong lever".

---

## 10. Long-Running Agent Harness

**무엇**
컨텍스트 윈도우보다 훨씬 긴 작업(수 시간~며칠)을 위해, **여러 세션에 걸친 구조화된 핸드오프 + 결과·진행 상태를 파일/git에 외부화**. 단일 세션 안의 패턴이 아니라 **세션 간** 패턴.

**언제 쓰나**
- 작업이 한 세션의 컨텍스트로 끝나지 않음 (장기 마이그레이션, 대규모 리팩터, 기능 단위 자율 빌드).
- 사용자가 비동기로 (overnight 등) 진행 상황을 검토하고 싶을 때.
- 평가/검증 사이클을 본 작업과 분리해야 할 때.

**어떻게 적용** (Anthropic이 production에서 검증한 형태)

```
세션 0 ── Initializer Agent ──▶ 인프라 셋업
                              ─ feature_list.json
                              ─ progress.txt
                              ─ init.sh
                                       │
                                       ▼
세션 1..N ── Coding Agent ──▶ git log + progress.txt 읽음
                            ──▶ 가장 우선순위 높은 미완 feature 선택
                            ──▶ 작업 + verify(end-to-end test)
                            ──▶ git commit + progress 갱신
                                       │
                                       ▼
                          Evaluator Agent (별 세션)
                            ──▶ 산출물 채점, 다음 액션 권고
```

핵심 원칙 ([effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)):
1. **Decompose into tractable chunks** — 한 번에 하나의 feature.
2. **Separate generation from evaluation** — 다른 에이전트가 채점.
3. **Structured handoffs between sessions** — 컨텍스트를 통째로 reset하고 진행 파일로 다음 세션을 복원.
4. **Pre-specify "done" via contracts** — 청크별로 완료 기준을 미리 합의.
5. **Encode subjective standards as measurable criteria**.
6. **Re-examine harnesses as models improve** — 모델이 좋아지면 스캐폴딩 제거.

또한 보고된 **Planner → Generator → Evaluator** 3-에이전트 패턴이 long-running task의 canonical answer로 부상 중. Planner는 구조와 목표, Generator는 실행, Evaluator는 독립 품질 검토 — 모두 **공유 컨텍스트가 아닌 구조화된 artifact로 핸드오프** ([2026 framework comparison](https://qubittool.com/blog/ai-agent-framework-comparison-2026)).
> 확인 필요: Anthropic의 공식 포스트가 명시적으로 "Planner-Generator-Evaluator"라는 3-에이전트 명명을 쓰는지, 아니면 커뮤니티 정리인지 일부 자료에 혼선이 있다. Anthropic 본문은 "Initializer + Coding agent + 분리된 evaluator" 패턴을 강조. 채택 시 원 출처 직접 확인 권장.

**트레이드오프**
- 장점: 컨텍스트 무한 한계 사실상 해소. 사람의 비동기 검토 가능. 실패 시 git로 롤백 자연스러움. 평가 분리로 품질 게이트.
- 단점: 외부화된 progress 파일이 stale·불일치하면 다음 세션이 잘못된 상태로 시작. 청크가 너무 크면 한 세션에 안 끝남. 검증 자동화(end-to-end test, 브라우저 자동화)가 거의 필수 — 없으면 evaluator가 동작 못 함.

**출처/예시**
- Anthropic [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (2026).
- Anthropic [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps).

---

## 11. Eval-Driven Agent Design

**무엇**
에이전트를 **TDD처럼 평가 데이터셋·rubric에서 출발해 설계·개선**. 프롬프트·도구·라우팅 변경의 효과를 모두 평가 점수로 측정.

**언제 쓰나**
- 프로덕션 에이전트 — "느낌으로" 개선이 통하지 않는 단계.
- A/B로 프롬프트·모델·하네스 변형을 비교해야 할 때.
- 회귀를 막아야 할 때 (특히 모델 업그레이드 시).

**어떻게 적용**

기본 사이클:
1. **Eval 데이터셋 수집** — 실제 사용 트레이스 (LangSmith, Braintrust, Langfuse), 합성 케이스.
2. **메트릭 정의** — task success(end-to-end), 단계별 품질(각 도구 호출이 적절했나), 비용/latency.
3. **CI/CD 게이트** — Braintrust GitHub Action처럼 PR마다 eval 돌려 점수 떨어지면 머지 차단.
4. **Trace 기반 디버깅** — 멀티 에이전트는 트레이스 없이는 디버그 불가. 부모-자식 관계 + 도구 호출 시간선 시각화.

Anthropic Research 시스템에서 한 핵심 학습: "Tool-testing agents improved descriptions, reducing completion time by 40%." 즉 **에이전트가 자기 도구 설명을 개선하도록 다시 평가에 넣는 메타 사이클**.

**트레이드오프**
- 장점: 모델·프롬프트 바꿀 때 회귀 안전망. 멀티 에이전트의 디버깅 가능성 확보. 비용·품질 trade-off를 데이터로.
- 단점: 초기 셋업 비용 큼. 평가 데이터 수집·골드 라벨링이 시간을 먹음. 자동 평가가 인간 판단을 대체할 수 없는 영역(소스 품질 편향처럼) 존재.

**LangSmith vs Braintrust 간략**:
- **LangSmith** — LangChain/LangGraph 통합 강함, 트레이스 + eval에 강한 LangChain 팀 제품.
- **Braintrust** — 프레임워크 중립, 네이티브 GitHub Action으로 PR 머지 게이트가 1급 시민.
- **Langfuse** — OSS 자체 호스팅 가능, 트레이스 우선.
- 셋 다 OpenTelemetry 기반 표준화 흐름.

**출처/예시**
- [LangSmith Evaluations](https://www.langchain.com/langsmith/evaluation).
- [Braintrust vs LangSmith 비교](https://www.braintrust.dev/articles/langsmith-vs-braintrust).
- Anthropic Multi-agent Research system — eval로 도구 설명을 개선한 사례.

---

## 패턴 선택 빠른 가이드

| 상황 | 1차 선택 | 2차 보강 |
|---|---|---|
| 단일 컨텍스트로 끝나는 일반 작업 | Single-agent + Tools | 위험 도구는 권한 모드/훅 |
| 메인 컨텍스트 폭발 우려 | Subagent for Context Isolation | 도구 화이트리스트로 좁히기 |
| 너비 우선 리서치, 정보 수집 | Orchestrator-Worker | Parallel Tool Calls + 평가 분리 |
| 사용자 인터페이스가 분기되는 도메인(지원) | Routing & Triage Handoff | input_filter로 컨텍스트 정리 |
| 정렬된 multi-step 워크플로우 + 검증 게이트 | Supervisor | Eval 게이트 + Plan-and-Execute |
| latency 극도 중시, 폐쇄 시스템 | Swarm | 8회 이상 핸드오프 시 cascading 주의 |
| 단계 많고 비용 절감 필요 | Plan-and-Execute | 단계는 가벼운 모델/코드 |
| 주관적 품질 정제 | Evaluator-Optimizer | rubric을 측정 가능한 기준으로 |
| 컨텍스트 윈도우 초과하는 장시간 작업 | Long-Running Harness (세션 핸드오프) | git/파일 외부 메모리 |
| 모든 프로덕션 | Eval-Driven Design | 트레이스 + CI 게이트 |

각 패턴에서 한 가지만 기억해야 한다면: **단순한 패턴부터 시작하고, 평가가 멀티 에이전트의 가치를 입증할 때만 복잡도를 올려라**. Anthropic·Cognition 양쪽 모두 이 점에서는 같은 말을 한다.
