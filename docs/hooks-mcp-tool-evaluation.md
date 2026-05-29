# Hooks `type: "mcp_tool"` Adoption Decision (Phase 62.1.3)

> **Decision**: **Deferred (not adopted in Phase 62)**
> **Re-evaluation condition**: When the harness-mem MCP route reaches GA and shell-wrapper-induced latency consistently exceeds 5 minutes/month in telemetry.

## In a nutshell

Claude Code `2.1.118` added the ability for hooks to directly call MCP tools using `type: "mcp_tool"`.
However, the latency in the current Harness wrappers (`scripts/hook-handlers/*.sh`) is small based on actual measurements, and the additional cost of designing fallback logic and auth scope outweighs the benefit — so this is recorded as deferred for Phase 62.

## Analogy

Similar to "the discussion of buying a new power tool." The work can be done with a hand tool (shell wrapper); before switching to a power tool (direct MCP call), you need to sort out where the outlet (auth) is and get an extension cord (fallback). Since the inconvenience of the hand tool isn't causing that much trouble right now, the purchase is postponed.

## Background

### Changes in Claude Code 2.1.118

- In addition to the existing `type: "command"` (shell script) and `type: "agent"` (LLM agent), `type: "mcp_tool"` is now available in PostToolUse / PreToolUse etc.
- When `mcp_tool` is specified, a specific MCP server tool can be called directly when the hook fires.
- In Harness, MCP tools such as `harness_mem_record_event` and `harness_mem_resume_pack` already exist.

### Current Harness hook implementation

| Hook path | Mechanism | Example |
|-----------|-----------|---------|
| `scripts/hook-handlers/memory-bridge.sh` | Shell wrapper POSTs to harness-mem daemon via `curl` | UserPromptSubmit, PostToolUse |
| `scripts/hook-handlers/memory-session-start.sh` | Shell wrapper `exec`s the `harness-mem` script of the same name | SessionStart |
| `scripts/hook-handlers/elicitation-handler.sh` | Shell wrapper formats input with `jq` and returns JSON to stdout | Elicitation |

These were wired in Phase 49 (XR-003) and are operating without issues.

## Comparison table

| Aspect | Shell wrapper (current) | `type: "mcp_tool"` direct call |
|--------|------------------------|-------------------------------|
| Latency | 50–200ms (curl + jq + daemon RTT) | Estimated 10–50ms (CC internal MCP client RTT) |
| Auth scope | Wrapper does not hold token directly (handled by daemon) | MCP auth scope resolution required at hook execution |
| Error propagation | Shell exit code + stderr (coarse granularity) | MCP RPC error code (fine granularity) |
| Fallback | `silent skip` implemented inside wrapper | Hook itself cannot fall back (depends on CC side) |
| Observability | Shell logs in `.claude/state/hook-runs.jsonl` | Visible as MCP call via OTel |
| Implementation cost | Existing assets as-is | hooks.json schema extension + auth design + fallback wiring |
| Distribution risk | Low (shell wrapper idempotency ensured) | Medium (hook may fail if MCP server unreachable) |

## Decision factors

### (i) Prediction for calling `harness_mem_record_event` directly from PostToolUse

- **Latency**: Actual measurement of current `memory-post-tool-use.sh` (50–150ms total) expected to drop to ~10–50ms with `mcp_tool`. However, since this is not on the critical path of PostToolUse hook itself, no user-perceptible impact.
- **Auth**: `harness_mem_record_event` requires the harness-mem daemon's bearer token (or local socket). Unconfirmed whether CC's MCP client can hold this token in hook execution context.
- **Error propagation**: Currently the shell wrapper silently skips on daemon unreachable; achieving equivalent behavior with `mcp_tool` depends on CC-side hook timeout/retry spec.

### (ii) Shell wrapper vs. direct call trade-off

Shell wrapper advantages:
- Already wired in Phase 49; no operational issues
- Silent skip / partial success on failure is self-contained in wrapper
- Can handle harness-mem API schema changes without touching the CC side (hooks.json)

`mcp_tool` advantages:
- Self-contained within CC; removes dependency on external processes (curl, jq)
- Consistent OTel telemetry
- Natural path when `harness-mem` is fully converted to a pure MCP server

### (iii) Fallback policy when MCP unreachable

Candidates and selection for this case:

| Policy | Description | Adoption decision |
|--------|-------------|------------------|
| `silent skip` | MCP unreachable = no-op; continue | **First candidate if this is adopted**. Consistent with current Phase 49 behavior |
| `queue` | On unreachable, accumulate in local queue and retry next time | Over-engineering (harness-mem itself has a queue; would be duplicated) |
| `drop` | On unreachable, discard the event | Not recommended; degrades telemetry accuracy |

If adopted, standardize on **silent skip**.

### (iv) Relationship with Phase 61 local ledger

The `.claude/state/elicitation/events.jsonl` introduced in Phase 61 functions as an **append-only fallback** when harness-mem is unreachable.
Even after adopting `mcp_tool`, the path of CC-side hook → local ledger write must remain for daemon unreachable cases.
This means re-implementing the same two-layer defense as the current wrapper structure on the CC hook side, which is an additional implementation burden.

## Conclusion

| Item | Details |
|------|---------|
| Adoption decision | **Deferred** |
| Reason | No operational issues with current shell wrappers; adopting `mcp_tool` requires additional design work for auth / fallback / Phase 61 ledger alignment |
| Re-evaluation triggers | (a) harness-mem MCP route reaches GA, (b) wrapper latency exceeds 5 min/month in telemetry, (c) CC publishes official guidance on hook auth |
| Phase 62 action | Creation of this doc only. Implementation and hooks.json changes deferred to next phase decision |

## Acceptance criteria (Phase 62.1.3 DoD)

- [x] `docs/hooks-mcp-tool-evaluation.md` exists
- [x] Comparison table (latency / auth / error / fallback, 4 items) for shell wrapper vs `type: "mcp_tool"` direct call
- [x] Fallback policy on MCP unreachable is explicitly fixed as `silent skip`
- [x] Overlap/complementary relationship with Phase 61 ledger explained in 1 paragraph
- [x] Decision recorded as one of adopt / defer / reject → **deferred**
- [x] Adoption conditions (re-evaluation triggers) listed as 3 items

## References

- Claude Code CHANGELOG `2.1.118`: <https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md>
- Phase 53 snapshot doc: `docs/upstream-update-snapshot-2026-04-23.md` (read-only MCP only allowed in `53.1.2 MCP tool hook decision`; write operations prohibited)
- Phase 49 (XR-003): `.claude-plugin/hooks.json` shell wrapper wiring
- Phase 61: `.claude/state/elicitation/events.jsonl` local ledger
