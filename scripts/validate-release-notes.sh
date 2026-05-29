#!/bin/bash
# validate-release-notes.sh
# GitHub Release ノートのフォーマット検証スクリプト
# 使用方法: ./scripts/validate-release-notes.sh [tag]
# 例: ./scripts/validate-release-notes.sh v2.10.0

set -e

TAG="${1:-}"
ERRORS=0

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ERRORS=$((ERRORS + 1))
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

# タグが指定されていない場合は最新のリリースをチェック
if [ -z "$TAG" ]; then
    TAG=$(gh release list --limit 1 --json tagName -q '.[0].tagName')
    echo "📋 Checking latest release: $TAG"
fi

# リリースノートを取得
NOTES=$(gh release view "$TAG" --json body -q '.body' 2>/dev/null)

if [ -z "$NOTES" ]; then
    log_error "リリースが見つかりません: $TAG"
    exit 1
fi

echo ""
echo "🔍 リリースノート検証: $TAG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. 見出しチェック
if echo "$NOTES" | grep -qE "^## 🎯 (あなたにとって何が変わるか|What's Changed for You)"; then
    # 日英混在チェック
    if echo "$NOTES" | grep -qE "^## 🎯 .*\|"; then
        log_error "見出しに日英混在があります（| で区切られている）"
    else
        log_ok "見出し: 正しい形式"
    fi
else
    log_error "見出しがありません: 🎯 あなたにとって何が変わるか"
fi

# 2. Before → After テーブルチェック
if echo "$NOTES" | grep -q "Before → After"; then
    log_ok "Before → After テーブル: あり"
else
    log_error "Before → After テーブルがありません"
fi

# 3. フッターチェック
if echo "$NOTES" | grep -q "Generated with \[Claude Code\]"; then
    log_ok "フッター: あり"
else
    log_error "フッターがありません: 🤖 Generated with [Claude Code](...)"
fi

# 4. 日英混在チェック（詳細）
# 英語の見出しパターン
if echo "$NOTES" | grep -qE "^## (What's New|What's Changed|Summary)$"; then
    log_warn "英語の見出しが使用されています（日本語推奨）"
fi

# 日本語と英語の説明が並列で存在
if echo "$NOTES" | grep -qE "^\*\*.+\*\*$" | grep -q "[a-zA-Z]" && echo "$NOTES" | grep -qE "^\*\*.+\*\*$" | grep -q "[ぁ-んァ-ン一-龥]"; then
    log_warn "説明文に日英混在の可能性があります"
fi

# 5. セクションチェック
for section in "Added" "Changed" "Fixed" "Security"; do
    if echo "$NOTES" | grep -q "^## $section"; then
        log_ok "セクション: $section あり"
    fi
done

# 6. 太字サマリーチェック
if echo "$NOTES" | head -10 | grep -qE "^\*\*.+\*\*$"; then
    log_ok "太字サマリー: あり"
else
    log_warn "太字サマリーが見つかりません（1行で変更の価値を説明）"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}検証結果: $ERRORS 件のエラー${NC}"
    echo ""
    echo "📖 参照: .claude/rules/github-release.md"
    exit 1
else
    echo -e "${GREEN}検証結果: すべてのチェックを通過${NC}"
    exit 0
fi
