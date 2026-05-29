# Hokage Spin-Off Readiness

Last updated: 2026-05-22

## Conclusion

No public spin-off yet.

Claude Code Harness remains a Claude-first product. "Hokage" is currently the
v4 Go-native runtime line, and Hokage Core extraction is underway as an internal
architecture direction. Do not present `Hokage Harness` as a public cross-host
product until the gates below pass.

## Gate Scope

The Phase 73 support claim freeze covers these hosts:

| Host | Current tier | Public claim boundary |
|---|---|---|
| Claude Code | `supported` | Claude-first product support is allowed. |
| Codex CLI | `internal-compatible` | Internal compatibility only until direct plugin install and companion smoke are verified together. |
| Codex app | `candidate` | Candidate only until app-specific handoff/runtime smoke passes. |
| OpenCode | `internal-compatible` | Internal compatibility only until runtime bootstrap smoke passes. |
| Cursor | `candidate` | Candidate only; existing PM handoff docs are not adapter support. |
| GitHub Copilot CLI | `candidate` | Candidate only; official CLI docs and Superpowers mapping are not Harness support proof. |
| Antigravity CLI | `future/unsupported` | Future/unsupported public claim until official/verified adapter route and local bootstrap smoke are observed. |

`not_observed != absent`: unavailable local runtime smoke stays unknown or not
observed. It must not be promoted into support, and it must not be treated as
proof that no route can exist.

## Gate Status

| Adapter readiness | Result | Evidence | Public boundary |
|---|---|---|---|
| Claude Code adapter | PARTIAL | Claude-first plugin baseline remains the product surface | Does not prove cross-host spin-off readiness |
| Codex adapter | PASS | Codex CLI direct plugin smoke, package gate, and companion route are test-backed | `internal-compatible`, not Codex app parity |
| OpenCode adapter | PASS | OpenCode bootstrap plugin, setup docs, and static validation are test-backed | `internal-compatible`; runtime auto-routing proof is explicitly out of scope for this phase |

| Gate | Current result | Verification evidence | Remaining blocker |
|---|---|---|---|
| Claude Code support | SUPPORTED | Claude-first plugin baseline and existing validation path are the product surface | Do not imply this proves other hosts |
| Codex CLI internal compatibility | INTERNAL-COMPATIBLE | Existing Codex mirrors, setup path, companion review, and local CLI help evidence from `docs/research/superpowers-cherrypick.md` | Direct plugin install and companion smoke must pass together before public support wording |
| Codex app candidate | CANDIDATE | Codex app is listed separately from CLI in the Phase 73 research artifact | App-specific worktree/UI handoff smoke is missing |
| OpenCode internal compatibility | INTERNAL-COMPATIBLE | Existing OpenCode mirror/package validation path and official plugin/skills docs evidence | Runtime bootstrap and native skill smoke are missing |
| Cursor candidate | CANDIDATE | Current Cursor marketplace/rules evidence plus Superpowers reference shape | Harness-specific rules/plugin install, bootstrap, and workflow smoke are missing |
| GitHub Copilot CLI candidate | CANDIDATE | Official CLI plugin docs and Superpowers tool mapping reference | Local CLI availability plus Harness bootstrap/skill smoke are missing |
| Antigravity CLI future/unsupported | FUTURE/UNSUPPORTED | Official snippets were observed, but no extracted static docs, local install, or Harness adapter route was proven | Official/verified route and local bootstrap smoke are missing |
| Capability matrix | PASS | `docs/tool-capability-matrix.md` and `bash tests/test-tool-capability-matrix.sh` cover Phase 73 tiers and false parity | None for the 73.1.2 contract freeze |
| Bootstrap routing | PASS | `docs/bootstrap-routing-contract.md` and `bash tests/test-bootstrap-routing-contract.sh` define static golden prompt routing and unsupported-host behavior | Runtime auto-routing proof is explicitly out of scope for this phase |
| Release preflight | PASS | `bash scripts/release-preflight.sh` includes adapter gates when adapter paths changed, release claims adapter support, or `--check-adapters` is used | CI run evidence still requires pushing the branch before a release tag |
| Positioning | PASS | README / README_ja use conservative extraction wording | Keep this wording until the other gates pass |

## Last Verification Snapshot

Historical Phase 70 local verification retained as context. This table does
not promote Codex CLI or OpenCode beyond `internal-compatible`, and it does not
cover Codex app, Cursor, GitHub Copilot CLI, or Antigravity CLI runtime smoke.

| Command | Result |
|---|---|
| `./tests/validate-plugin.sh` | PASS |
| `bash tests/test-codex-package.sh` | PASS |
| `node scripts/build-opencode.js` | PASS |
| `node scripts/validate-opencode.js` | PASS |
| `bash scripts/sync-skill-mirrors.sh --check` | PASS |
| `bash tests/test-tool-capability-matrix.sh` | PASS |
| `bash tests/test-bootstrap-routing-contract.sh` | PASS |
| `bash scripts/release-preflight.sh` | PASS locally with non-blocking warnings for env/health/CI availability and existing residual-scan candidates |

## Candidate And Unsupported Host Reasons

| Host | Status | Reason |
|---|---|---|
| Codex app | Candidate | Codex CLI help and setup path do not prove app behavior. |
| Cursor | Candidate | Existing 2-agent handoff docs are not a full adapter: no verified bootstrap route, capability matrix, release gate, or runtime safety parity. |
| GitHub Copilot CLI | Candidate | No local CLI smoke, Harness-specific bootstrap proof, or release-preflight integration exists in this phase. |
| Antigravity CLI | Future/unsupported for public claim | No official or verified Harness adapter route, local install availability proof, or bootstrap smoke exists in this phase. |

## Next Adapter Candidates

| Candidate | Why it is next | Required proof before support claim |
|---|---|---|
| OpenCode | It now has skills-primary setup, mirror generation, validation, and stale command/MCP cleanup | Add runtime bootstrap proof or keep support wording limited to packaging/static contract validation |
| Codex CLI | It already has native skill surfaces, package tests, documented bootstrap routing, and local plugin command evidence | Direct plugin install and companion smoke must pass together |
| Codex app | It may share some Codex concepts but has separate app behavior | App-specific worktree/UI handoff smoke |
| Cursor | It has existing 2-agent workflow docs, but not adapter parity | Define whether it is a handoff integration or a real adapter before adding any support claim |
| GitHub Copilot CLI | Official plugin docs describe skills/commands/hooks/MCP fields | Local CLI availability and Harness bootstrap/skill smoke |
| Antigravity CLI | Official snippets suggest plugin/skill/hook concepts | Extractable official docs or verified route plus local bootstrap smoke |

## Allowed Public Wording

Use:

```text
Claude Code Harness is Claude-first, with Hokage Core extraction underway.
```

Do not use:

```text
Describe Hokage as a public cross-host product before these gates pass.
```

## Exit Criteria

The `No public spin-off yet` conclusion can change only when all of the
following are true:

- Claude Code remains supported and every public non-Claude support claim has
  host-specific install/update, bootstrap, workflow smoke, and release gate
  evidence.
- Capability differences are documented and test-backed.
- Bootstrap routing has golden prompt coverage or explicit unsupported results.
- Release preflight blocks only adapters claimed by that release.
- README / README_ja can state support without implying safety parity that the
  host cannot provide.
