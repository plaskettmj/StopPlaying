--[[ Session timer: countdown or elapsed with breakpoints ]]
StopPlaying = StopPlaying or {}
StopPlaying.UI = StopPlaying.UI or {}
StopPlaying.UI.Timer = StopPlaying.UI.Timer or {}
local T = StopPlaying.UI.Timer

local function Fmt(sec)
  sec = math.max(0, math.floor(sec + 0.5))
  local m = math.floor(sec / 60)
  local s = sec % 60
  return string.format("%02d:%02d", m, s)
end

function T:Init()
  self._fired = false
  self.ticker = C_Timer.NewTicker(0.25, function() self:Tick() end)
  local db = StopPlaying.db
  if db.timerMode == "countdown" and db.timerEndsAt and db.timerEndsAt > time() then
    self._fired = false
  elseif db.timerMode == "countdown" and db.timerEndsAt and db.timerEndsAt <= time() then
    self._fired = true
    if StopPlaying.UI.Flash then StopPlaying.UI.Flash:Show() end
  end
end

function T:StartCountdown(minutes)
  local db = StopPlaying.db
  db.timerMode = "countdown"
  db.timerStartedAt = time()
  db.timerEndsAt = time() + math.floor(minutes * 60)
  self._fired = false
  if StopPlaying.UI.Flash then StopPlaying.UI.Flash:Hide() end
  StopPlaying.Print(string.format("Countdown %d min — stop when it hits zero", minutes))
  self:Tick()
end

function T:StartElapsed()
  local db = StopPlaying.db
  db.timerMode = "elapsed"
  db.timerStartedAt = time()
  db.timerEndsAt = nil
  self._fired = false
  if StopPlaying.UI.Flash then StopPlaying.UI.Flash:Hide() end
  StopPlaying.Print("Elapsed session timer started (amber/red/pulse breakpoints)")
  self:Tick()
end

function T:Stop()
  local db = StopPlaying.db
  db.timerMode = "off"
  db.timerEndsAt = nil
  db.timerStartedAt = nil
  self._fired = false
  if StopPlaying.UI.Flash then StopPlaying.UI.Flash:Hide() end
  if StopPlaying.UI.Hud and StopPlaying.UI.Hud.Refresh then StopPlaying.UI.Hud:Refresh() end
  StopPlaying.Print("Timer stopped")
end

function T:GetDisplay()
  local db = StopPlaying.db
  if db.timerMode == "countdown" and db.timerEndsAt then
    local left = db.timerEndsAt - time()
    return "CD " .. Fmt(math.max(0, left)), left
  elseif db.timerMode == "elapsed" and db.timerStartedAt then
    local elapsed = time() - db.timerStartedAt
    return "EL " .. Fmt(elapsed), elapsed
  end
  return "Timer —", nil
end

function T:ElapsedColor()
  local db = StopPlaying.db
  if db.timerMode ~= "elapsed" or not db.timerStartedAt then return 1, 1, 1 end
  local elapsed = time() - db.timerStartedAt
  local bp = (StopPlaying.Config and StopPlaying.Config.GetBreakpoints and StopPlaying.Config:GetBreakpoints()) or db.breakpoints
  if elapsed >= (bp.pulse or 5400) then
    local pulse = (math.sin(GetTime() * 8) * 0.5 + 0.5)
    return 1, 0.2 + 0.3 * pulse, 0.2
  elseif elapsed >= (bp.red or 4500) then
    return 1, 0.25, 0.2
  elseif elapsed >= (bp.amber or 2700) then
    return 1, 0.75, 0.2
  end
  return 0.85, 0.95, 0.85
end

function T:Tick()
  local db = StopPlaying.db
  if db.timerMode == "countdown" and db.timerEndsAt then
    if (db.timerEndsAt - time()) <= 0 and not self._fired then
      self._fired = true
      if StopPlaying.UI.Flash then StopPlaying.UI.Flash:Show() end
    end
  end
  if StopPlaying.UI.Hud and StopPlaying.UI.Hud.Refresh then
    StopPlaying.UI.Hud:Refresh()
  end
end
