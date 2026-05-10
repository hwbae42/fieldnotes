#!/usr/bin/env bash
# validate-docs.sh — 모든 패턴 파일이 5개 필수 섹션을 갖는지 검증
# Codex 팀 "아키텍처 제약 기계적 강제" 패턴 적용

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
ERRORS=0

# 각 섹션의 bold 마커 패턴 — 표기 변형(무엇. / 무엇 쓰나 등) 모두 허용
REQUIRED_SECTIONS=("무엇" "언제" "어떻게" "트레이드오프" "출처")

check_topic_structure() {
  local topic_dir="$1"
  local topic
  topic=$(basename "$topic_dir")

  for required_file in overview.md patterns.md references.md; do
    if [ ! -f "$topic_dir/$required_file" ]; then
      echo "  ❌ 누락 파일: docs/$topic/$required_file"
      ERRORS=$((ERRORS + 1))
    fi
  done
}

check_patterns_file() {
  local file="$1"
  local topic
  topic=$(basename "$(dirname "$file")")

  echo "  docs/$topic/patterns.md"

  for section in "${REQUIRED_SECTIONS[@]}"; do
    # bold 마커(**무엇**, **무엇.**) 또는 H3 헤더(### 무엇) 둘 다 허용
    if ! grep -qE "^### ${section}|\*\*${section}" "$file"; then
      echo "    ❌ 섹션 없음: ${section}"
      ERRORS=$((ERRORS + 1))
    fi
  done
}

echo "=== fieldnotes 문서 구조 검증 ==="
echo ""

echo "── 파일 구조 검사 ──"
for topic_dir in "$DOCS_DIR"/*/; do
  [ -d "$topic_dir" ] || continue
  topic=$(basename "$topic_dir")
  printf "  docs/%s/\n" "$topic"
  check_topic_structure "$topic_dir"
done

echo ""
echo "── 패턴 섹션 검사 (5개 필수: 무엇/언제/어떻게/트레이드오프/출처) ──"
for topic_dir in "$DOCS_DIR"/*/; do
  [ -d "$topic_dir" ] || continue
  patterns_file="$topic_dir/patterns.md"
  [ -f "$patterns_file" ] || continue
  check_patterns_file "$patterns_file"
done

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "✅ 모든 검증 통과 (오류 0개)"
else
  echo "❌ 총 ${ERRORS}개 오류 — 커밋 전 수정 필요"
  exit 1
fi
