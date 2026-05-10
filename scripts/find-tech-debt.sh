#!/usr/bin/env bash
# find-tech-debt.sh — 미완성 항목, TODO, 출처 없음 등을 탐지
# Codex 팀 "기술 부채 가비지 컬렉션" 패턴 적용

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
FEATURE_LIST="$REPO_ROOT/feature-list.json"

echo "=== fieldnotes 기술 부채 스캔 ==="
echo ""

# 1. "확인 필요" 플래그
echo "── [확인 필요] 마커 ──"
if grep -rn "확인 필요" "$DOCS_DIR" 2>/dev/null; then
  echo ""
else
  echo "  (없음)"
  echo ""
fi

# 2. TODO / TBD
echo "── [TODO / TBD] 마커 ──"
if grep -rni "\bTODO\b\|\bTBD\b" "$DOCS_DIR" 2>/dev/null; then
  echo ""
else
  echo "  (없음)"
  echo ""
fi

# 3. "미수록" / "작성 예정"
echo "── [미수록 / 작성 예정] 마커 ──"
if grep -rn "미수록\|내용 없음\|작성 예정" "$DOCS_DIR" 2>/dev/null; then
  echo ""
else
  echo "  (없음)"
  echo ""
fi

# 4. 출처 섹션이 명시적으로 비어있거나 미확인인 경우
echo "── [출처 미확인] 마커 ──"
if grep -rn "출처.*없음\|출처.*N/A\|출처.*미확인" "$DOCS_DIR" 2>/dev/null; then
  echo ""
else
  echo "  (없음)"
  echo ""
fi

# 5. feature-list.json 미완료 항목
echo "── [feature-list.json] 미완료 항목 ──"
if [ -f "$FEATURE_LIST" ] && command -v python3 &>/dev/null; then
  python3 -c "
import json, sys
with open('$FEATURE_LIST') as f:
    data = json.load(f)
pending = [t for t in data.get('topics', []) if t.get('status') != 'done']
if not pending:
    print('  (모든 항목 완료)')
else:
    for t in pending:
        icon = '🔴' if t.get('priority') == 'high' else ('🟡' if t.get('priority') == 'medium' else '⚪')
        print(f'  {icon} [{t[\"status\"]}] {t[\"id\"]} — {t[\"title\"]}')
"
else
  echo "  (feature-list.json 없거나 python3 없음 — 수동 확인 필요)"
fi
echo ""

echo "=== 스캔 완료 ==="
