# StopPlaying

A lightweight World of Warcraft session timer. Set a play budget, watch a movable HUD chip, and get a hard-to-ignore full-screen alert when time is up.

Works on current Midnight-era retail (`## Interface` 120100 / 120007). Optional for WoW Forever once that client reports its interface version.

## Features
- **Countdown** — `/sp timer 60` for a 60-minute budget
- **Flash** — SESSION OVER overlay with **+15 min** or **Dismiss**
- **Instance deferral** (v1.2.0+, default ON) — in party/raid/pvp/arena, flash waits until you leave the instance
- **Elapsed** — `/sp elapsed` with amber / red / pulse breakpoints
- **HUD** — drag to move; `/sp hud` to toggle
- **Options** (v1.3.0) — Blizzard Settings → AddOns → StopPlaying, or `/sp options`
- **Soft skins** (v1.3.0) — best-effort styling when ElvUI, Masque, Skinner, or Aurora are present (OptionalDeps; no hard requirement)

## Install
1. Download a release zip (or clone this repo)
2. Ensure the folder is named `StopPlaying` inside `Interface\AddOns\`
3. Enable the addon at character select and `/reload`

## Options
Open **Esc → Options → AddOns → StopPlaying**, or run `/sp options` (alias `/sp config`).

| Setting | DB key | Default |
|---------|--------|---------|
| Defer SESSION OVER in dungeons/raids/PvP | `deferInInstances` | on |
| Show timer HUD | `hudVisible` | on |
| Default countdown minutes | `countdownMinutesDefault` | 60 |

Turning **Defer** off while a SESSION OVER is pending shows the flash immediately (same as `/sp defer off`).

## Commands
| Command | Action |
|---------|--------|
| `/sp timer <minutes>` | Start countdown |
| `/sp timer stop` | Clear timer / hide flash |
| `/sp elapsed` | Start elapsed session timer |
| `/sp hud` | Toggle HUD chip |
| `/sp defer` | Toggle instance deferral of SESSION OVER |
| `/sp defer on\|off` | Explicitly enable/disable deferral (default on) |
| `/sp options` / `/sp config` | Open Settings → AddOns → StopPlaying |
| `/stopplaying` | Same as `/sp` |

## Skin support
StopPlaying does not embed or require skin libraries. If ElvUI, Masque, Skinner, or Aurora is loaded, a best-effort pass runs after HUD/Flash init (HandleButton / Masque group / applySkin / Aurora SkinFrame-style APIs). Skin quality varies by addon version; absences are ignored silently.

## License
MIT — see [LICENSE](LICENSE).

## CurseForge
Project listing TBD after author portal setup.
