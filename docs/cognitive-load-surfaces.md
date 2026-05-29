# 認知負荷を下げる 3 つの HTML 画面 (Phase 65)

Claude が「何を考えて」「今どこにいて」「何ができたか」を、エンジニアじゃない人でも 3 秒で把握できるようにする 3 つの HTML 画面。

## やりたいこと

AI と一緒に開発するとき、コミットログや Plans.md (=タスク一覧マークダウン) を読み続けるのは認知負荷が高い。
発注者・プロデューサー・経営者が、進行中の AI 開発を **ブラウザで開いてひと目で判断できる** 1 枚紙の HTML を 3 種類提供する。

| Surface | 何のため | いつ見る |
|---------|----------|----------|
| **Plan Brief** (着工前) | 「Claude はこう理解した。これで進めて OK?」 | 実装前の承認 |
| **Progress Tracker** (工事中) | 「今どこまで進んで、いつ終わる見込み?」 | 任意のタイミング (自動再生成) |
| **Acceptance Demo** (引き渡し時) | 「この成果物、受け取りますか?」 | 実装完了後の検収 |

## やり方

### Plan Brief (1st surface)

```bash
# Claude セッション中に
/harness-plan-brief
```

Claude が以下を 1 枚 HTML にまとめる:
- ユーザー要求の Claude 側理解
- 選択肢 (やり方が複数あれば each option)
- リスク (ハマりそうな箇所)
- 受け入れ条件 (acceptance_criteria)
- 確信度 (0-100、根拠付き)

ユーザーは「OK で進めて」「ここを修正」「質問あり」を返す。
判断は `personal-preference.v1` schema で記録 (sha256 ハッシュ付き)。

### Progress Tracker (2nd surface)

```bash
# 進捗確認
/harness-progress
```

または PostToolUse hook が Edit/Write/Bash 発火時に **60 秒に 1 回** 自動再生成。

表示内容:
- progress_pct (cc:完了 / 総タスク × 100)
- 現在の WIP タスク
- 直近完了タスク 5 件
- 未着手タスク 5 件
- drift alert (5 種、severity 色分け: 赤=critical / 黄=warn / 青=info)

### Acceptance Demo (3rd surface)

```bash
# 実装完了後
/harness-accept
```

Claude が以下を 1 枚 HTML にまとめる:
- 判定 (ship / wait / reject の 3 択)
- 受け入れ条件の検証 (Plan Brief の各項目に「確認済み」「未確認」マーク)
- 未検証の留保事項
- 過去の問題パターン履歴
- 提示成果物のリスト

ユーザーは accept / override / reject を返す。
判断は `acceptance-decision.v1` で記録、Plan Brief と **同じ user_request_hash** で graph join 可能。

## 気をつけること

### 1. Plan Brief と Acceptance Demo は user_request_hash で連結される

Plan Brief 起動時に「ユーザー要求文」の sha256 ハッシュを取り、record に保存。
Acceptance Demo も同じハッシュを取って record に保存。
**この 2 record は同 hash で `mcp__harness__harness_mem_search` から graph join 可能**。

「あの時のあのプラン、結果どうなった?」を後から完全に振り返れる仕組み。

### 2. Progress Tracker の rate limit (60 秒)

PostToolUse hook が大量の Edit/Write を引き起こす場面 (large refactor) でも、HTML 再生成は 60 秒に 1 回までに制限される。
state file: `.claude/state/progress-last-regen.txt` (epoch seconds)。

### 3. drift alert は session 内で蓄積、永続化しない

5 種の alert (scope-creep / time-overrun / repeated-failure / cost-warning / high-risk-file) は、
1 セッション内の状態を Progress Tracker HTML に表示するもの。
**メモリには永続化しない** (issue #87 方針、Lead プロセス in-memory のみ)。

過去 alert への user 判断は `progress-past-judgments.sh` で集計し「過去 N 件中 M 件で同様の提案を断っています」を表示するが、
こちらは別途 `alert-judgment.v1` record として permanent storage する設計余地あり (本フェーズ未実装)。

### 4. クライアント情報の取り扱い

cross-project search を有効化する `--cross-project-group <name>` flag を使った場合、
**3 層 redaction** (Layer 2a 辞書 + Layer 2b NER + Layer 3 final scan) が自動適用される。
詳細: [cross-project-safety.md](cross-project-safety.md)

## 関連ファイル

| ファイル | 用途 |
|---------|------|
| `skills/harness-plan-brief/` | Plan Brief skill (Phase 65.1) |
| `skills/harness-accept/` | Acceptance Demo skill (Phase 65.2) |
| `skills/harness-progress/` | Progress Tracker skill (Phase 65.4) |
| `templates/html/plan-brief.html.template` | Plan Brief HTML template |
| `templates/html/accept.html.template` | Acceptance Demo HTML template |
| `templates/html/progress.html.template` | Progress Tracker HTML template |
| `scripts/render-html.sh` | mustache 風 template renderer (`--with-redaction` flag 対応) |
| `scripts/plan-brief-record-decision.sh` | Plan Brief 判断記録 |
| `scripts/accept-record-decision.sh` | Acceptance Demo 判断記録 |
| `scripts/progress-snapshot.sh` | Plans.md → snapshot JSON |
| `scripts/progress-detect-drift.sh` | 5 alert kind 検出 |
| `scripts/progress-past-judgments.sh` | 過去判断 lookup |
| `scripts/hook-handlers/posttool-progress-regen.sh` | PostToolUse 自動再生成 hook |

## 関連 schema

- `plan-brief-context.v1` (Plan Brief render input)
- `acceptance-context.v1` (Acceptance Demo render input)
- `progress-snapshot.v1` (Progress Tracker render input)
- `personal-preference.v1` (Plan Brief 判断記録)
- `acceptance-decision.v1` (Acceptance Demo 判断記録)
- `progress-alert.v1` (drift alert)
