# StopPlaying

A lightweight World of Warcraft session timer. Set a play budget, watch a movable HUD chip, and get a hard-to-ignore full-screen alert when time is up.

Works on current Midnight-era retail (`## Interface` 120100 / 120007). Optional for WoW Forever once that client reports its interface version.

## Features
- **Countdown** — `/sp timer 60` for a 60-minute budget
- **Flash** — SESSION OVER overlay with **+15 min** or **Dismiss**
- **Elapsed** — `/sp elapsed` with amber / red / pulse breakpoints
- **HUD** — drag to move; `/sp hud` to toggle

## Install
1. Download a release zip (or clone this repo)
2. Ensure the folder is named `StopPlaying` inside `Interface\AddOns\`
3. Enable the addon at character select and `/reload`

## Commands
| Command | Action |
|---------|--------|
| `/sp timer <minutes>` | Start countdown |
| `/sp timer stop` | Clear timer / hide flash |
| `/sp elapsed` | Start elapsed session timer |
| `/sp hud` | Toggle HUD chip |
| `/stopplaying` | Same as `/sp` |

## License
MIT — see [LICENSE](LICENSE).

## CurseForge
Project listing TBD after author portal setup.
