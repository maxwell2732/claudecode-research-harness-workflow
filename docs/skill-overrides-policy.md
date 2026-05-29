# Skill Overrides Policy (Phase 62.2.5)

> **Status**: Active (2026-05-07)
> **対象**: Claude Code `2.1.129` で `skillOverrides` 設定が `off` / `user-invocable-only` /
> `name-only` の 3 mode をサポートするようになった。Harness の skill ガバナンスとの関係を
> 明示し、enterprise / individual で適切な default を定める。

## ひとことで

`skillOverrides` 3 mode は **モデルに skill を上書きさせるかどうか** の policy。
Harness は 既定で **何も設定しない** (= CC default 挙動) が、enterprise governance では
`name-only` を推奨する。

## たとえると

「料理人 (モデル) にレシピ (skill) をどこまでアレンジさせるか」を決める policy。
- `off`: アレンジ禁止 (既定 skill のみ実行)
- `user-invocable-only`: ユーザーが指名したアレンジだけ許可
- `name-only`: 名前で指定したものだけアレンジ可、勝手に他のレシピは引かない
- 未設定: CC default = ある程度アレンジ可

## 3 mode の意味

| mode | 意味 | 用途 |
|------|------|------|
| `off` | モデル経由の skill activation を完全無効化 | 高度な enterprise 環境、skill の挙動を完全に固定したいとき |
| `user-invocable-only` | ユーザーが `/<skill>` で明示起動した skill のみ許可、モデル自動起動を禁止 | 「モデルが暗黙に skill を呼ぶ」挙動を避けたい中間 governance |
| `name-only` | skill の name フィールド一致による起動のみ許可 (description-based 自動 trigger を抑制) | description のあいまい一致による予期せぬ skill 発動を防ぎたい場合 |
| 未設定 (default) | CC default 挙動。description-based 自動 trigger も含めて全て有効 | 個人開発、Harness 既定 |

## Harness 既定方針

| 環境 | 推奨 mode | 理由 |
|------|-----------|------|
| 個人 / 単独開発 | 未設定 (CC default) | description ベースの自動 trigger が便利 |
| Team (small) | 未設定 + skill manifest 監査 | `scripts/generate-skill-manifest.sh` で skill 一覧を可視化 |
| Enterprise governance | **`name-only`** | description あいまい一致を抑制し、明示的 skill 起動のみ許可 |
| 教育 / training session | `user-invocable-only` | モデルの自動起動を禁じ、学習者が能動的に skill を選ばせる |

`harness-init` で生成する template には **default を入れない** (= CC default を尊重)。
enterprise 利用者は `.claude/settings.json` または `.claude/settings.local.json` で明示する。

## skill manifest との関係

Phase 59.1.2 で `scripts/generate-skill-manifest.sh` が `kind` / `purpose` / `trigger` /
`shape` / `role` / `base` / `pair` / `owner` 等のメタデータを machine-readable に出すようにした。

`skillOverrides: name-only` 環境では、CC は skill の **name** だけを matching する。
description-based 自動 trigger は無効になる。
そのため skill 名は **意味的に明示的** であるべき (`harness-work` / `harness-review` 等の動詞 + 名詞)。

| skill 命名 | name-only mode の挙動 |
|-----------|----------------------|
| `harness-work` | 明示起動は OK (`/harness-work`) |
| `breezing` (alias) | 明示起動は OK (`/breezing`) |
| `harness-loop` | 明示起動は OK (`/harness-loop`) |
| 抽象的 / 一般語 (例: `helper`) | 名前衝突リスクがあるので避ける |

## 設定例

### Enterprise governance (`.claude/settings.json`)

```json
{
  "skillOverrides": "name-only"
}
```

### 個別無効化 (特定環境のみ)

```json
{
  "skillOverrides": "off"
}
```

これにより、自動化されたバッチ実行で skill の暗黙起動を完全に止められる。

### 既定 (推奨されない明示)

明示的に `default` を指定する mode は無いため、未設定で CC default を保つ。

## tests / `harness-init` における扱い

- `tests/test-settings-baseline.sh` (Phase 62.1.4 で作成検討) は `skillOverrides` の存在を
  **許容するが強制しない** (個人開発で `default` を妨げないため)
- `harness-init` は `skillOverrides` を生成 settings に **入れない**
- 移植 / customize 時に enterprise governance が必要な場合は本 doc を参照

## Acceptance 条件 (Phase 62.2.5 DoD)

- [x] 3 mode の意味が表で書かれる
- [x] 推奨 default が環境 (個人 / team / enterprise / education) ごとに固定
- [x] enterprise governance 用途が明示
- [x] Phase 59.1.2 skill manifest との関係が明記
- [x] `harness-init` で default を入れるかの判断が記録 (= 入れない)

## 関連 doc

- Phase 59.1.2 (`scripts/generate-skill-manifest.sh`) — skill metadata 機械化
- Phase 58.2.3 (`docs/upstream-followups-phase58-2026-05-03.md`) — setup / docs 候補としての扱い
- Claude Code 2.1.129 CHANGELOG: `skillOverrides` setting now works with `off`, `user-invocable-only`, `name-only` options
