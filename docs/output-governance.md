# Output Governance Policy

最終更新: 2026-05-05

この文書は、Hook や自動整形処理が Claude Code の tool output を扱う時の安全方針を定義する。

## ひとことで

`PostToolUse.hookSpecificOutput.updatedToolOutput` は既定では使わない。
使う場合は opt-in の redaction / compaction / normalization に限り、監査証跡と review / test evidence を消さない。

## たとえると

tool output は、作業現場の監視カメラ映像のようなもの。
見やすく要約することはあっても、事故の証拠になる部分を勝手に切り落としてはいけない。

## 方針

| 項目 | 判断 |
|------|------|
| 既定動作 | `updatedToolOutput` は返さない |
| 許可用途 | 明示 opt-in の redaction、compaction、normalization |
| 禁止用途 | test failure、review finding、security finding、command error の隠蔽 |
| 監査証跡 | 元出力の保存先、変換理由、変換ルールを残す |
| 出力契約 | stdout は単一 JSON object。説明ログは stderr へ出す |

## 許可する変換

### Redaction

秘密情報を伏せるための変換。

例:

- API key を `<REDACTED:api-key>` に置換する
- access token を `<REDACTED:token>` に置換する
- 個人情報を `<REDACTED:personal-data>` に置換する

禁止:

- エラー行ごと削除する
- failing test name を消す
- review finding の file:line を消す

### Compaction

巨大出力を短くするための変換。

例:

- 成功ログの重複行を折りたたむ
- 1000 行以上の dependency install log を要約する
- 末尾に `full_output_path` を残して全文をファイル保存する

禁止:

- failure summary を省略する
- stack trace の先頭と最後を両方消す
- `pytest`, `vitest`, `go test`, `npm test` の失敗箇所を消す

### Normalization

表示ゆれを揃えるための変換。

例:

- absolute temp path を stable placeholder にする
- timestamp を `<TIMESTAMP>` にする
- progress spinner の制御文字を除く

禁止:

- exit code の意味を変える
- stderr を成功扱いに見せる
- review / test の判定語を置換する

## JSON stdout contract

Hook が Claude Code に構造化出力を返す場合、stdout は JSON だけにする。
人間向けログは stderr に出す。

最小形:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse"
  }
}
```

`updatedToolOutput` を使う場合:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "updatedToolOutput": "redacted or compacted tool output",
    "additionalContext": "Output was redacted with policy output-governance.v1. Full output is stored at .claude/state/audit/tool-output/<id>.log."
  }
}
```

必須条件:

1. stdout に JSON 以外を混ぜない。
2. `updatedToolOutput` を返す時は opt-in 設定を確認する。
3. full output または復元可能な audit record を保存する。
4. 変換理由と変換種別を `additionalContext` または audit record に残す。
5. review / test evidence を削除しない。

## Harness default

Harness の既定では `updatedToolOutput` を使わない。
理由は、review や test の根拠を勝手に短くすると、あとで「本当に失敗していたのか」「何を直したのか」が追えなくなるため。

必要な時だけ、個別 hook で次を明示する。

```json
{
  "outputTransform": {
    "enabled": true,
    "mode": "redact",
    "auditTrail": true
  }
}
```

この設定名は policy 上の例であり、実装側は同等の opt-in を持てばよい。
重要なのは「既定で改変しない」「改変したら追跡できる」「品質証拠を消さない」の 3 点。
