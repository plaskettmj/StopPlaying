# Changelog

## 1.3.0
- **Settings panel** — Blizzard Settings → AddOns → StopPlaying (modern Settings API)
  - Defer SESSION OVER in dungeons/raids/PvP (`deferInInstances`, default on)
  - Show timer HUD (`hudVisible`)
  - Default countdown minutes slider when the client supports it
- `/sp options` and `/sp config` open the panel via `Settings.OpenToCategory`
- Turning defer off in Settings with a pending flash mirrors `/sp defer off` (flush / show)
- **Soft skin support** (best-effort when those addons are present; no hard deps): ElvUI, Masque, Skinner, Aurora

## 1.2.0
- **Instance-aware deferral**: when the play budget hits zero in a party, raid, pvp, or arena instance, SESSION OVER waits until you leave
- Toggle (SavedVariables, default ON): `/sp defer` or `/sp defer on|off`
- Pending flag survives `/reload` mid-instance; flash fires once after leave
- Open world / other instance types still flash immediately

## 1.1.0
- Initial public release as **StopPlaying**
- Movable HUD chip with live countdown or elapsed session time
- Full-screen SESSION OVER flash with +15 min and Dismiss
- Elapsed mode color breakpoints (45m amber / 75m red / 90m pulse)
- Slash commands: `/sp`, `/stopplaying`
