# RESEARCH-METHOD.md — 리서치 상세 방법론

> **리서치를 시작하기 직전에만 읽는다.** 일상적인 에이전트 컨텍스트가 아니라 작업 착수 직전 참조용.

---

## 착수 전 체크 (3단계)

```bash
cat claude-progress.txt   # 이전 세션 상태, 중단된 작업 있는지
cat feature-list.json     # 우선순위 확인
cat docs/index.md         # 차후 조사 목록에서 범위 파악
```

`feature-list.json`에서 선택한 항목의 `status`를 `"in_progress"`로 변경한 뒤 시작.

---

## 신규 주제 조사 순서

1. `docs/{주제}/` 디렉토리 생성
2. `overview.md` 먼저 작성 — "왜 지금 이 주제인가"부터 시작
3. `patterns.md` 작성 — 아래 패턴 템플릿 사용, 패턴마다 반드시 5개 섹션
4. `references.md` 작성 — 직접 읽고 검증한 자료만
5. `docs/index.md` 완료 주제에 추가, 차후 목록에서 제거
6. `README.md` 완료 주제/패턴 수/핵심 설명 동기화
7. `feature-list.json` 해당 항목 status → `"done"`
8. `claude-progress.txt` 갱신

---

## 기존 주제 확장 순서

1. 기존 `patterns.md`의 마지막 패턴 번호 확인
2. 파일 하단에 N+1번부터 추가 (새 파일 생성 금지)
3. `references.md`에 새 출처 추가
4. `docs/index.md`의 해당 주제 설명 패턴 수 업데이트
5. `README.md`의 패턴 수/핵심 설명 업데이트
6. 차후 조사 목록에서 완료 항목 제거
7. `feature-list.json`, `claude-progress.txt` 갱신

---

## 패턴 작성 템플릿

```markdown
## N. 패턴 이름

### 무엇
한 줄 정의. 기술 용어는 괄호로 한국어 병기 가능.

### 언제
- 적용 조건 1
- 적용 조건 2 (구체적인 상황으로)

### 어떻게

구체적인 구현 방법. 코드 예시는 출처가 있는 경우에만.

### 트레이드오프
- 장점: ...
- 단점 / 실패 지점: ...

### 출처
- [출처 제목](URL) — 어떤 내용을 참고했는지 한 줄 설명
```

---

## 문서 작성 원칙

- **언제 왜 쓰는가** 중심 — 개념 설명보다 적용 조건이 먼저
- **출처 없는 주장 금지** — 추측이면 "(추측)" 명시 후 최소화
- **한국어** — 고유명사·기술 용어는 원문 병기
- **패턴 번호 이어쓰기** — 기존 N개면 N+1번부터

---

## 완료 전 체크리스트

```bash
bash scripts/validate-docs.sh   # 5개 섹션 구조 통과 확인
bash scripts/find-tech-debt.sh  # TODO·확인 필요 잔존 여부
```

- [ ] 모든 패턴에 출처 URL 또는 출판물명 있음
- [ ] 추측성 주장 없거나 "(추측)"으로 명시됨
- [ ] `docs/index.md` 업데이트됨
- [ ] `README.md` 업데이트됨
- [ ] `feature-list.json` status → `"done"`
- [ ] `claude-progress.txt` 갱신됨
