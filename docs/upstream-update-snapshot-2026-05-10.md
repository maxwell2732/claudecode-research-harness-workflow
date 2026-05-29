# Codex upstream snapshot - 2026-05-10

この snapshot は、Codex `0.130.0` stable を Claude-harness で追跡するための記録です。
Phase 67.1.1 では upstream 事実を固定し、Phase 67.1.2 以降で provider / app-server /
plugin workflow docs へ実装する対象を分けます。

確認日:

- 2026-05-10 (Asia/Tokyo)

対象 release:

- tag: `rust-v0.130.0`
- name: `0.130.0`
- prerelease: `false`
- published_at: `2026-05-08T23:09:55Z`
- release URL: <https://github.com/openai/codex/releases/tag/rust-v0.130.0>
- compare: <https://github.com/openai/codex/compare/rust-v0.129.0...rust-v0.130.0>

既存 Harness の追従済み地点:

- Codex `0.124.0` stable (Phase 56)
- Codex `0.125.0` / `0.128.0` stable (Phase 58)
- Claude Code `2.1.112`-`2.1.132` follow-up (Phase 62)

分類:

- `A: 検証強化`: 今回の snapshot / Feature Table / CHANGELOG / tests で upstream 追跡を固定する。
- `C: 自動継承`: Codex 本体の修正をそのまま受ける。Harness wrapper を重ねない。
- `P: Plans 化`: Harness に活用価値があるが、この snapshot では runtime 実装せず Phase 67 task に切る。
- `B: 書いただけ 0 件`: 実装・テスト・後続 Plans に接続しない説明だけの項目は作らない。

## Version-by-version breakdown

| Version | Upstream item | どうよくなる | Category | Harness surface | Harness action |
|---------|---------------|--------------|----------|-----------------|----------------|
| Codex `0.130.0` stable | plugin details show bundled hooks | plugin が同梱 hook を持つか判断しやすくなる | P | Codex plugin workflow docs / setup review | Phase 67.1.2 で plugin-bundled hooks の表示を docs に接続し、Harness が inline hook を推測生成しない方針を維持する |
| Codex `0.130.0` stable | plugin sharing exposes link metadata/discoverability controls | shared plugin の link 情報と discoverability を扱いやすくなる | P | plugin sharing policy | Phase 67.1.2 で marketplace / private sharing の責務境界として docs 化する |
| Codex `0.130.0` stable | top-level `codex remote-control` | remote control の入口が分かりやすくなる | P | Codex workflow docs | Phase 67.1.2 で `codex remote-control` を official top-level command として追記する |
| Codex `0.130.0` stable | app-server Thread pagination APIs | thread 一覧の大規模化に耐えやすくなる | P | app-server / session docs | Phase 67.1.2 で Thread pagination APIs を app-server policy に接続する |
| Codex `0.130.0` stable | Bedrock `aws login` profile credentials | Bedrock profile credentials の取得経路が明確になる | P | provider setup docs | Phase 67.1.2 で `aws login` / `amazon-bedrock` / console-login credentials の境界を追記する |
| Codex `0.130.0` stable | `view_image` through selected environments | selected environment 経由で画像確認できる | P | multi-environment review docs | Phase 67.1.2 で selected-environment `view_image` を read-only first / one primary write environment と矛盾しない形にする |
| Codex `0.130.0` stable | live app-server threads refresh latest config snapshot | live thread が最新 config snapshot を反映しやすくなる | P | app-server config lifecycle | Phase 67.1.2 で live threads from latest config snapshot の期待値を docs 化する |
| Codex `0.130.0` stable | turn diff accuracy after `apply_patch` including partial failures | `apply_patch` 後の turn diffs が正確になる | C | review / diff UX | 本体修正を自動継承。Harness 側で turn diffs の workaround は追加しない |
| Codex `0.130.0` stable | ThreadStore summaries/resume/fork improvements | summary / resume / fork が安定する | C | session runtime | 本体修正を自動継承。Plans SSOT や harness-loop state を二重化しない |
| Codex `0.130.0` stable | remote compaction emits `response.processed` and omits `service_tier` under API auth | remote compaction の event / auth 挙動が安定する | C | remote compaction telemetry | 本体修正を自動継承。Harness telemetry は `response.processed` を観測対象として残し、`service_tier` 欠落をエラー扱いしない |
| Codex `0.130.0` stable | Windows sandbox runtime bin cache | Windows sandbox 起動時の runtime bin 解決が速く安定する | C | Windows sandbox runtime | 本体修正を自動継承。Harness は Windows workaround を追加しない |
| Codex `0.130.0` stable | docs use `cargo install --locked` | install 手順の再現性が上がる | P | setup docs | Phase 67.1.3 で Codex install guidance を棚卸しし、古い cargo install 例があれば `cargo install --locked` に寄せる |
| Codex `0.130.0` stable | configurable OTel trace metadata | trace metadata を環境に合わせて付けやすくなる | P | telemetry policy | Phase 67.1.3 で OTel trace metadata を privacy-first / local-first policy と衝突しない形で評価する |
| Codex `0.130.0` stable | built-in MCPs first-class runtime servers | built-in MCPs を runtime server として扱いやすくなる | P | MCP setup docs | Phase 67.1.3 で built-in MCPs と plugin-provided MCP の境界を docs 化する |
| Codex `0.130.0` stable | `CODEX_HOME` environments TOML provider | environments TOML provider を `CODEX_HOME` 配下で扱える | P | Codex setup / environment policy | Phase 67.1.3 で `CODEX_HOME` environments TOML provider と repo-local config の優先順位を固定する |
| Codex `0.130.0` stable | remove skills list extra roots | skill root の重複・余分な探索が減る | C | skill runtime | 本体修正を自動継承。Harness skill manifest generator は現状維持 |

## Phase 67 follow-up plan

| Task | Scope |
|------|-------|
| 67.1.1 | この snapshot、Feature Table、CHANGELOG、upstream integration test を追加する |
| 67.1.2 | Codex provider / app-server / multi-environment policy を `0.130.0` stable に更新する |
| 67.1.3 | Codex setup / telemetry / MCP / environment docs を `0.130.0` stable に更新する |
| 67.1.4 | Phase 67 の integration validation と Plans marker 更新を行う |

## B: 書いただけ 0 件の理由

- `A` はこの snapshot と `tests/test-claude-upstream-integration.sh` による検証強化として固定した。
- `P` は Phase 67.1.2 / 67.1.3 の docs / policy work に接続した。
- `C` は Codex 本体の runtime fix として自動継承する理由を 1 行で明記した。
- Feature Table と CHANGELOG だけに載せて終わる item は残していない。

## No-op adaptation decision for this snapshot

この snapshot 自体は no-op adaptation とする。

理由:

- `codex remote-control`, app-server Thread pagination APIs, selected-environment `view_image`,
  Bedrock `aws login`, plugin hooks は docs / policy 境界の更新が先で、runtime wrapper を即変更する根拠ではない。
- `apply_patch` 後の turn diffs、ThreadStore summaries/resume/fork improvements、Windows sandbox runtime bin cache は Codex 本体の修正であり、Harness 側で二重 workaround を作ると将来の挙動と競合する。
- OTel trace metadata、built-in MCPs、`CODEX_HOME` environments TOML provider は便利だが、privacy / setup precedence / MCP ownership の境界を Phase 67.1.3 で固定してから採用する。
