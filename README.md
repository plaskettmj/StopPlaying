# StopPlaying

A lightweight World of Warcraft session timer. Set a play budget, watch a movable HUD chip, and get a hard-to-ignore full-screen alert when time is up.

Works on current Midnight-era retail (`## Interface` 120100 / 120007). Optional for WoW Forever once that client reports its interface version.

## Features
- **Countdown** — `/sp timer` uses Settings default; `/sp timer 60` overrides
- **Flash** — SESSION OVER overlay with **+15 min** or **Dismiss**
- **Instance deferral** (v1.2.0+, default ON) — in party/raid/pvp/arena, flash waits until you leave the instance
- **Elapsed** — `/sp elapsed` with configurable amber / red / pulse breakpoints
- **HUD** — drag to move; `/sp hud` to toggle; scale + font from Options (v1.4.0)
- **Options** (v1.3.0+) — Blizzard Settings → AddOns → StopPlaying, or `/sp options`
- **Soft skins** (v1.3.0) — best-effort styling when ElvUI, Masque, Skinner, or Aurora are present (OptionalDeps; no hard requirement)
- **LibSharedMedia fonts** (v1.4.0, optional) — when `LibSharedMedia-3.0` is loaded, its fonts appear in the HUD font dropdown

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
| HUD scale | `hudScale` | `1.0` (60%–200%) |
| HUD font | `hudFont` | `Friz Quadrata TT` |
| HUD font size | `hudFontSize` | `12` |
| Elapsed breakpoints (seconds) | `breakpoints.amber / .red / .pulse` | 45m / 75m / 90m |

Turning **Defer** off while a SESSION OVER is pending shows the flash immediately (same as `/sp defer off`).

### Appearance (v1.4.0)
- **HUD scale** slider (60%–200%) calls `Hud:ApplyAppearance()` → `frame:SetScale(hudScale)` on a 140×28 base chip, plus `SetFont` for outline text.
- **HUD font** dropdown lists Blizzard built-ins (`Fonts\FRIZQT__.TTF`, `ARIALN.TTF`, `MORPHEUS.TTF`, `SKURRI.TTF`). If LibSharedMedia-3.0 is present (OptionalDeps only — not embedded), its font list is merged and kept fresh via `LibSharedMedia_Registered` / `LibSharedMedia_SetGlobal` callbacks.

### Elapsed breakpoints (v1.4.0)
Options edits **minutes**; SavedVariables still store **seconds**. Constraint: `1 ≤ amber < red < pulse ≤ 600` (auto-clamped).

The visual bar represents **0 .. max(pulse × 1.1, 120) minutes** (dynamic). Segments: green → amber → red → pulsing red zone. Drag markers or type in the EditBoxes; both stay in sync. Arrow buttons adjust ±1 (Shift ±5).

## Commands
| Command | Action |
|---------|--------|
| `/sp timer` | Start countdown with default minutes from Options |
| `/sp timer <minutes>` | Start countdown with an explicit length |
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

## Media
CurseForge gallery screenshots live in `media/`:
- `01-session-over.png` — SESSION OVER flash
- `02-countdown-hud.png` — countdown HUD
- `03-timer-idle.png` — idle HUD
- `04-settings.png` — Options: General + Appearance
- `05-settings-breakpoints.png` — Options: HUD font + elapsed breakpoints

## CurseForge
Project listing TBD after author portal setup.
