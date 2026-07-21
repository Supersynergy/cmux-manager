# Changelog

## [0.2.0] — 2026-07-21

Meta-orchestrator release. Built on real recon, not assumption: the fleet
already had a mature status/goals backend ([agentmaster](https://github.com/manaflow-ai),
18 releases) — cmuxman now uses it instead of duplicating it, and adds the
capabilities that were genuinely missing on top.

### Added
- `cmuxman status` — now backed by `agentmaster ls --json` (real session
  state: `Needs input`/`working`/`ready`) instead of a screen-text guess;
  falls back to the old cmux-dot heuristic if agentmaster isn't installed.
- `cmuxman brief [days]` — one-shot state-of-everything: real git commits
  (recon script, filters mtime-only-touch noise) + fleet status + limit-scan.
  Operationalizes a manual `/checkin` pass into a repeatable command.
- `cmuxman goal` / `goals` — thin passthrough to agentmaster's goal-pinning
  (not reimplemented).
- `cmuxman triage <ws>` — for a stale/ambiguous workspace: last screen +
  agentmaster peek + a ready-to-paste `metaflow` kill-or-continue prompt.
  cmuxman has no research budget of its own, so it hands off the evidence
  instead of guessing.
- `cmuxman optimize` — bounded recursive-learning autopilot. Recurring
  launchd timer (default 20 min, timer-only — same architecture as
  `resume-fleet`'s ntfy-to-in-cmux-listener handoff, since the cmux socket
  refuses launchd-started processes) runs one decision cycle: nudge
  usage-limit-blocked sessions, close idle duplicate workspaces. Every
  cycle is rate-capped (`start`/`stop`), fully logged to a local ledger
  (`optimize status`), checks whether its *own previous actions* actually
  worked via agentmaster's state, and auto-backs-off a workspace after
  repeated failures instead of retrying blindly. Writes a one-line summary
  to the memory store each cycle so learned backoffs compound across
  rebuilds. No per-project autonomy exceptions — the safety boundary is
  the fixed 2-action set + rate caps + audit trail + kill-switch, not a
  denylist.

### Verified before release
- End-to-end autonomous chain proven live: phone/ntfy trigger → in-cmux
  listener → `optimize cycle` → ledger entry, timestamped.
  `optimize cycle` on a clean fleet correctly decided "nothing to do" (no
  false-positive nudges/closes).
- `status`/`brief`/`triage`/`goals` all run clean against a live 18-workspace
  fleet.

## [0.1.1] — 2026-07-19

- Fix: `launchctl submit` restarts exited jobs forever — the resume timer
  fired every ~39 minutes overnight instead of once. One-shot jobs now
  remove their own label.
- Fix: the cmux socket denies any launchd-started process ("only processes
  started inside cmux can connect") — the remote listener moved from a
  LaunchAgent into a cmux workspace; `resume-fleet`'s scheduled timer now
  pokes it via ntfy instead of calling cmux directly. The update worker
  respawns the listener after an app update.
- Fix: usage-limit block text only counts when it appears in the last 12
  screen lines — stale scrollback was producing false `BLOCKED` reads.
- `doctor` gained a remote-listener health check.

## [0.1.0] — 2026-07-19

First public release. Every feature below was proven against a live 30-workspace
fleet before shipping.

### Added
- `cmuxman update` — zero-loss cmux app updates: manifest of live sessions →
  launchd-owned quit/install (codesign-gated, rollback kept) → relaunch →
  self-restore detection → targeted rescue of missing sessions → verify gate
  (`missing=0, dupes=0`) with macOS notification.
- `cmuxman resume-fleet` — detects sessions blocked at the Claude usage limit
  (screen + HUD scan), computes the reset time, schedules a launchd one-shot
  that nudges each blocked session to continue. `--at HH:MM` and `--now` modes.
- `cmuxman dedupe` — duplicate-workspace finder/closer with keep-priority
  (selected > busy > lowest id) and just-in-time busy guard. Dry-run default.
- `cmuxman status / tail / send / spawn` — fleet inspection and safe steering;
  `send` refuses mid-turn or booting targets.
- `cmuxman council` — fan a question out to a local multi-engine worker pool.
- `cmuxman remote-install / remote-serve` — phone remote control via secret
  ntfy.sh topic with command allowlist.
- `cmuxman doctor / verify / snapshot / rescue / restore-missing`.
- Vendored zero-dependency helpers: `cmux-spawn` (AppleScript fallback),
  `cmux-rescue` (tier-0 restore from `~/.claude/projects`).
