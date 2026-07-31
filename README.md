# cmux-manager

**Keeps a room full of Claude Code sessions alive inside [cmux](https://github.com/manaflow-ai/cmux).**

Running a fleet of Claude Code sessions inside cmux is powerful, until an app update kills every session, the 5-hour usage limit freezes your agents mid-task, a recovery run leaves you with 11 duplicate workspaces, or half the fleet just sits idle because nobody's watching. `cmuxman` closes those gaps with one CLI, standing on [agentmaster](https://github.com/manaflow-ai) for fleet ground-truth rather than re-guessing it.

```
cmuxman update          # update cmux, keep every session, prove it
cmuxman brief           # one-shot state-of-everything (real commits + fleet + limits)
cmuxman optimize start  # bounded autopilot: auto-nudge + auto-dedupe, rate-capped, logged
cmuxman remote-install  # drive all of it from your phone
```

## Install

```bash
git clone https://github.com/Supersynergy/cmux-manager
cd cmux-manager && ./install.sh
cmuxman doctor
```

Requirements: macOS, [cmux](https://github.com/manaflow-ai/cmux), `python3`, `jq`, `gh` (for updates). Strongly recommended: [agentmaster](https://github.com/manaflow-ai) on PATH, `status`/`optimize` use its structured session-state (`Needs input`/`working`/`ready`) instead of a weaker screen-text fallback. Optional: [callagent](https://github.com/Supersynergy) `ca` pool for `council`.

## Why it works when naive approaches fail

| Failure mode | cmuxman answer |
|---|---|
| App quit kills the restore process itself | update worker is **launchd-owned**, survives the quit |
| Restore guesses which sessions to bring back | **manifest** of actually-running session IDs, captured before quit |
| cmux ≥0.64.20 self-restores → naive rescue duplicates everything | self-restore detection + **targeted** rescue of only missing sessions |
| Update leaves the socket dead | spawn falls back to the app's **AppleScript** dictionary |
| "Done" without proof | verify gate: `missing=0, dupes=0` + macOS notification |
| Usage limit blocks the fleet silently | HUD scan finds blocked sessions, schedules a launchd nudge for the reset minute |

## Commands

**Fleet** (status/goals backed by [agentmaster](https://github.com/manaflow-ai) when installed)
- `status`, ground-truth table: agentmaster's real session state, or a cmux-dot fallback
- `brief [days]`, one-shot state-of-everything: real git commits (not touched-but-idle dirs) + fleet status + limit-scan, in one command instead of re-deriving it by hand
- `tail <ws> [n]`, last n lines of a workspace screen
- `send <ws> <text>`, type text + Enter, refuses busy or booting targets (`--force` to override)
- `spawn --cwd D --command C`, new workspace; works even with a dead socket
- `dedupe [--apply]`, find duplicate-title workspaces, close idle twins (keeps selected/busy/lowest id)
- `goal <name> <text>` / `goals`, pin/list fleet goals (passthrough to agentmaster; not reimplemented)
- `triage <ws>`, for a stale/ambiguous session: last screen + a ready-to-paste `metaflow` kill-or-continue prompt
- `council <question> [-e codex,gemini,kimi]`, fan a question out to a local engine pool, print all answers

**Update & recovery**
- `update [--force]`, release check → dmg download → codesign gate → snapshot → launchd worker: manifest → quit → install (rollback kept) → relaunch → wait for self-restore → targeted rescue → verify + notification
- `verify` / `restore-missing` / `rescue`, each phase runnable standalone
- `snapshot [name]`, named snapshot copy into your vault (+ git commit)

**Limit auto-resume, autopilot & remote**
- `limit-scan`, sessions blocked at or near the usage limit
- `resume-fleet [--now|--at HH:MM]`, records blocked sessions, computes the reset time from their HUD, schedules a launchd one-shot that nudges each one to continue (skips anything mid-turn)
- `optimize start [every-min]`, recurring bounded autopilot (default every 20 min): reads agentmaster's fleet state, auto-nudges usage-limit-blocked sessions and auto-closes idle duplicate workspaces. Every cycle is rate-capped, fully logged, and checks the *outcome* of its own previous actions, a workspace that fails the same action repeatedly gets an automatic backoff (recursive learning, not blind repetition). A one-line summary compounds into your memory store (`synx put`) after each cycle.
- `optimize stop`, kill-switch: stops the loop immediately
- `optimize status`, ledger tail, today's action count, active backoffs
- `optimize cycle`, run one decision cycle now (what the timer calls)
- `remote-install` / `remote-serve`, control the fleet from your phone via a secret [ntfy.sh](https://ntfy.sh) topic; commands are **allowlisted** (no arbitrary shell), replies arrive on `<topic>-r`. The listener runs *inside* a cmux workspace (the cmux socket refuses launchd-started processes), and `optimize start`'s recurring timer pokes it the same way, launchd is a clock here, never the actor.

## Safety model

`optimize`'s autopilot has no per-project exceptions, it acts on every workspace, including ones running real-money-adjacent work. That's a deliberate scope choice, kept safe by engineering the loop itself, not by carving out exceptions:

- Fixed action set. The autopilot can only do two things: nudge a usage-limit-blocked session to continue, or close an idle duplicate workspace. It cannot run arbitrary commands, edit files, or touch a project's own code/trading logic, those stay gated by that project's own controls.
- Rate-capped. Hard caps per cycle and per day (`CMUXMAN_OPT_MAX_PER_CYCLE`/`_DAY`, default 8/60). A runaway fleet state cannot turn into a runaway action loop.
- Fully audited. Every action is logged to `~/.config/cmuxman/optimize.db` before/after, with the fleet state that triggered it, nothing is silent, `optimize status` shows the trail.
- Outcome-checked, self-backing-off. Each cycle verifies whether its *previous* actions actually worked (via agentmaster's state); repeated failures on the same workspace trigger an automatic cooldown instead of retrying forever.
- Trivial kill-switch. `cmuxman optimize stop` removes the timer and arms a stop-flag the next cycle checks first, even if the timer removal is delayed.
- Nothing is closed or interrupted without a just-in-time busy check (`esc to interrupt` on screen = hands off) elsewhere in the CLI (`send`, `dedupe`).
- `dedupe` (manual) is dry-run by default; `--apply` re-checks each target before closing.
- Updates verify the Developer-ID signature of the downloaded app before replacing anything; the previous version stays as `cmux.app.old`.
- The remote listener executes only allowlisted `cmuxman` subcommands. Treat the topic name as a secret; rotate it by deleting `~/.config/cmuxman/remote-topic` and re-running `remote-install`.

## Vendored helpers

- `cmux-spawn`, socket-first workspace spawn with AppleScript fallback
- `cmux-rescue`, tier-0 session restore from `~/.claude/projects` alone (zero dependencies on snapshots or sockets)

## License

MIT © Supersynergy
