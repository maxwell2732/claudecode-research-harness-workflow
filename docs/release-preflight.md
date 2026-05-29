# Release Preflight

`scripts/release-preflight.sh` は、公開前に「今 release してよいか」を先に止めるための read-only チェックです。
vendor-neutral を前提にしているので、AWS 固定や特定の deploy 基盤に依存しません。

## 何を見るか

- working tree が clean か
- `CHANGELOG.md` に `[Unreleased]` があるか
- `.env.example` と `.env` が大きくずれていないか。`.env` がない repo は warning に留め、managed secrets 前提の運用を止めすぎない
- 既存の `healthcheck` / `preflight` コマンドが通るか
- `agents/` / `core/` / `hooks/` / `scripts/` の shipped surface に `mockData` / `dummy` / `localhost` / `TODO` / `FIXME` などの残骸が残っていないかを警告する
- tag 作成前に `node scripts/build-opencode.js` / `node scripts/validate-opencode.js` / `bash scripts/sync-skill-mirrors.sh --check` を実行し、`opencode/`, `skills-codex/`, `codex/.codex/skills/` の mirror drift が 0 であるか
- 取得できる場合は CI の最新状態が成功しているか

mirror drift gate は release tag 前の fail gate です。`build-opencode.js` が差分を生成した場合、preflight は失敗し、その差分を commit してから tag 作成へ進みます。

Actions runtime audit (2026-05-11): repo workflows use `actions/checkout@v6`; Node setup uses `actions/setup-node@v6`; Go setup uses `actions/setup-go@v6`. These v6 action lines run on the Node 24 action runtime and avoid the Node 20 deprecation warning.

## 使い方

```bash
scripts/release-preflight.sh
scripts/release-preflight.sh --root /path/to/other/repo
```

## 環境変数

- `HARNESS_RELEASE_PROJECT_ROOT`: 別 repo を点検したいときの root
- `HARNESS_RELEASE_HEALTHCHECK_CMD`: repo 固有の healthcheck コマンド
- `HARNESS_RELEASE_CI_STATUS_CMD`: CI 状態確認を差し替えたいときのコマンド

## dry-run との関係

`/release --dry-run` でも preflight は必ず通す。
dry-run は「公開操作をしない」という意味で、preflight は「公開してよい状態かを確認する」という意味。
両者は別物なので、dry-run でも preflight は省略しない。

## GitHub Release workflow

`.github/workflows/release.yml` でも、GitHub Release の作成や既存 release への asset upload より前に `bash ./scripts/release-preflight.sh --check-adapters` を実行する。

tag-triggered workflow は detached HEAD で動くため、CI status が取得できない場合は warning boundary として扱う。release-ready の判断は、clean tree、mirror drift、adapter smoke、distribution archive gate などの preflight failure が 0 であることを前提にする。

`tests/test-distribution-archive.sh` は `git archive HEAD` から配布物の形を検証する。これは committed artifact の検証であり、dirty / untracked local files は含まれない。したがって、release claim の前には clean-tree preflight と組み合わせて使う。
