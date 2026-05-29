---
description: UIデバッグ/検証は agent-browser（インストール済みの場合）を優先する
alwaysApply: true
_harness_template: "rules/ui-debugging-agent-browser.md.template"
_harness_version: "2.7.13"
---

# UI Debugging Rule (Prefer Agent Browser)

## 基本方針

- UI/UXの不具合・画面上の再現が必要な調査は、**agent-browser を最優先で使う**
- 他のブラウザ系ツール（MCP の chrome-devtools、playwright）より先に agent-browser を試す
- 画面とソースコードを往復しながら、**再現 → 原因推定 → 修正 → 再検証** を短いサイクルで回す

## agent-browser の優位性

| 特徴 | 説明 |
|------|------|
| **AI 最適化** | `snapshot -i -c` で要素参照（`@e1`, `@e2`）を取得可能 |
| **シンプル** | CLI で直接実行、MCP 経由不要 |
| **高速** | Rust 製バイナリ |
| **セッション管理** | `--session` で複数タブを並列管理 |

## 進め方（推奨）

### 1. 再現条件を固める

- 対象URL、ユーザー状態（ログイン/権限/データ）、期待値/実際の挙動を明文化

### 2. agent-browser で再現

```bash
# ページを開く
agent-browser open https://example.com/target-page

# AI 向けスナップショットを取得（インタラクティブ要素のみ）
agent-browser snapshot -i -c

# 出力例:
# - button "Login" [ref=e1]
# - input "Email" [ref=e2]
# - input "Password" [ref=e3]
```

### 3. 操作を実行して問題を再現

```bash
# 要素参照でクリック
agent-browser click @e1

# フォームに入力
agent-browser fill @e2 "test@example.com"
agent-browser fill @e3 "password123"

# 状態を確認
agent-browser snapshot -i -c
```

### 4. 観測→仮説→コード確認

- スナップショット/スクリーンショット/コンソールログの情報を根拠に、原因候補を絞る
- 関連するソース（UI/状態管理/API/バリデーション）を確認

### 5. 最小修正で直す

- 変更範囲を抑え、意図と副作用を説明できる修正にする

### 6. agent-browser で再検証

```bash
# 同じ手順で再現しないことを確認
agent-browser open https://example.com/target-page
agent-browser snapshot -i -c
agent-browser click @e1
# ...
```

## agent-browser が使えない場合のフォールバック

以下の順序で代替手段を試す：

1. **MCP ブラウザツール**（chrome-devtools, playwright）
2. **手動再現**:
   - 再現手順（URL/操作/期待値/実際）
   - スクリーンショット/動画
   - コンソールログ/ネットワークログ
3. **自動E2E**:
   - 可能なら最小の Playwright/Cypress テストを追加して回帰を防ぐ

## よく使うコマンド

```bash
# 基本操作
agent-browser open <url>          # ページを開く
agent-browser snapshot -i -c      # スナップショット（AI向け）
agent-browser click @e1           # クリック
agent-browser fill @e2 "text"     # 入力
agent-browser screenshot out.png  # スクリーンショット

# デバッグ
agent-browser --headed open <url> # ブラウザを表示
agent-browser console             # コンソールログ表示
agent-browser errors              # ページエラー表示

# 情報取得
agent-browser get text @e1        # テキスト取得
agent-browser get html @e1        # HTML取得
agent-browser get url             # 現在のURL
```
