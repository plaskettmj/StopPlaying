# Changelog

## 1.4.4
- Docs: Retail **and** WoW Forever both supported (install paths + CurseForge link in README)
- TOC Notes updated for dual-client support; `X-Curse-Project-ID` added

## 1.4.3
- Media: replace Settings gallery shot; add breakpoints Options screenshot (`04-settings.png`, `05-settings-breakpoints.png`)

## 1.4.0
- **Resizable HUD** — SavedVariables `hudScale` (default 1.0, clamp 0.6–2.0); Options slider 60%–200%; applied via `SetScale` + `Hud:ApplyAppearance()`
- **HUD font style** — `hudFont` (default `Friz Quadrata TT` → `Fonts\FRIZQT__.TTF`) and `hudFontSize` (default 12)
  - Built-in dropdown: Friz Quadrata TT, Arial Narrow, Morpheus, Skurri
  - OptionalDeps `LibSharedMedia-3.0`: when present, LSM fonts merge into the dropdown; callbacks refresh the list
- **Elapsed breakpoint editors** — Options UI edits amber / red / pulse in **minutes** (DB still stores seconds)
  - EditBox + ±1 arrows (Shift ±5); constraint `1 ≤ amber < red < pulse ≤ 600` with gentle auto-clamp
  - Visual segmented bar (0→amber green, amber→red amber, red→pulse red, pulse→end pulsing); domain `0 .. max(pulse×1.1, 120)` minutes; draggable markers sync both ways with the editors
- **Options architecture** — single canvas Settings category (`RegisterCanvasLayoutCategory`) with General / Appearance / Elapsed sections; `/sp options` still opens category ID `StopPlaying`

## 1.3.1

- `/sp timer` with no minutes uses the default countdown from Settings.

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
