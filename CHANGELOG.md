# Changelog

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
