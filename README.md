# cmux-manager

**Fleet manager for [cmux](https://github.com/manaflow-ai/cmux) + Claude Code — zero-loss app updates, usage-limit auto-resume, duplicate cleanup, and phone remote control.**

Running a fleet of Claude Code sessions inside cmux is powerful — until an app update kills every session, the 5-hour usage limit freezes your agents mid-task, or a recovery run leaves you with 11 duplicate workspaces. `cmuxman` closes those gaps with one CLI.

```
cmuxman update          # update cmux, keep every session, prove it
cmuxman resume-fleet    # auto-continue agents when the usage limit resets
cmuxman dedupe --apply  # close duplicate workspaces (busy-guarded)
cmuxman remote-install  # drive all of it from your phone
```

## Install

```bash
git clone https://github.com/Supersynergy/cmux-manager
cd cmux-manager && ./install.sh
cmuxman doctor
```

Requirements: macOS, [cmux](https://github.com/manaflow-ai/cmux), `python3`, `jq`, `gh` (for updates), optional [callagent](https://github.com/Supersynergy) `ca` pool for `council`.

## Why it works when naive approaches fail

| Failure mode | cmuxman answer |
|---|---|
| App quit kills the restore process itself | update worker is **launchd-owned** — survives the quit |
| Restore guesses which sessions to bring back | **manifest** of actually-running session IDs, captured before quit |
| cmux ≥0.64.20 self-restores → naive rescue duplicates everything | self-restore detection + **targeted** rescue of only missing sessions |
| Update leaves the socket dead | spawn falls back to the app's **AppleScript** dictionary |
| "Done" without proof | verify gate: `missing=0, dupes=0` + macOS notification |
| Usage limit blocks the fleet silently | HUD scan finds blocked sessions, schedules a launchd nudge for the reset minute |

## Commands

**Fleet**
- `status` — one line per workspace: id, BUSY/IDLE/SHELL, title
- `tail <ws> [n]` — last n lines of a workspace screen
- `send <ws> <text>` — type text + Enter, refuses busy or booting targets (`--force` to override)
- `spawn --cwd D --command C` — new workspace; works even with a dead socket
- `dedupe [--apply]` — find duplicate-title workspaces, close idle twins (keeps selected/busy/lowest id)
- `council <question> [-e codex,gemini,kimi]` — fan a question out to a local engine pool, print all answers

**Update & recovery**
- `update [--force]` — release check → dmg download → codesign gate → snapshot → launchd worker: manifest → quit → install (rollback kept) → relaunch → wait for self-restore → targeted rescue → verify + notification
- `verify` / `restore-missing` / `rescue` — each phase runnable standalone
- `snapshot [name]` — named snapshot copy into your vault (+ git commit)

**Limit auto-resume & remote**
- `limit-scan` — sessions blocked at or near the usage limit
- `resume-fleet [--now|--at HH:MM]` — records blocked sessions, computes the reset time from their HUD, schedules a launchd one-shot that nudges each one to continue (skips anything mid-turn)
- `remote-install` / `remote-serve` — control the fleet from your phone via a secret [ntfy.sh](https://ntfy.sh) topic; commands are **allowlisted** (no arbitrary shell), replies arrive on `<topic>-r`

## Safety model

- Nothing is closed or interrupted without a just-in-time busy check (`esc to interrupt` on screen = hands off).
- `dedupe` is dry-run by default; `--apply` re-checks each target before closing.
- Updates verify the Developer-ID signature of the downloaded app before replacing anything; the previous version stays as `cmux.app.old`.
- The remote listener executes only allowlisted `cmuxman` subcommands. Treat the topic name as a secret; rotate it by deleting `~/.config/cmuxman/remote-topic` and re-running `remote-install`.

## Vendored helpers

- `cmux-spawn` — socket-first workspace spawn with AppleScript fallback
- `cmux-rescue` — tier-0 session restore from `~/.claude/projects` alone (zero dependencies on snapshots or sockets)

## License

MIT © Supersynergy
