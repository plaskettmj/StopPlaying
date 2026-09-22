--[[ StopPlaying — session countdown / elapsed timer with stop alert ]]
StopPlaying = StopPlaying or {}
local SP = StopPlaying

SP.ADDON = "StopPlaying"
SP.VERSION = "1.4.1"

local DEFER_INSTANCE_TYPES = {
  party = true,
  raid = true,
  pvp = true,
  arena = true,
}

local defaults = {
  hudVisible = true,
  hudPoint = { "TOP", nil, "TOP", 0, -8 },
  hudScale = 1.0,
  hudFont = "Friz Quadrata TT",
  hudFontSize = 12,
  timerMode = "off",
  timerEndsAt = nil,
  timerStartedAt = nil,
  countdownMinutesDefault = 60,
  breakpoints = { amber = 45 * 60, red = 75 * 60, pulse = 90 * 60 },
  deferInInstances = true,
  pendingSessionOver = false,
}

local function DeepCopy(src)
  if type(src) ~= "table" then return src end
  local t = {}
  for k, v in pairs(src) do t[k] = DeepCopy(v) end
  return t
end

function SP.EnsureDB()
  if type(StopPlayingDB) ~= "table" then StopPlayingDB = {} end
  for k, v in pairs(defaults) do
    if StopPlayingDB[k] == nil then
      StopPlayingDB[k] = DeepCopy(v)
    end
  end
  -- Clamp scale if present but out of range
  local sc = tonumber(StopPlayingDB.hudScale)
  if sc then
    if sc < 0.6 then StopPlayingDB.hudScale = 0.6 end
    if sc > 2.0 then StopPlayingDB.hudScale = 2.0 end
  end
  SP.db = StopPlayingDB
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffc9a227StopPlaying|r: " .. tostring(msg))
end
SP.Print = Print

--- True when the player is in a party/raid/pvp/arena instance worth deferring the flash for.
function SP.IsDeferWorthyInstance()
  local inInstance, instanceType = IsInInstance()
  if not inInstance then
    return false
  end
  if not instanceType or instanceType == "" then
    local _, iType = GetInstanceInfo()
    instanceType = iType
  end
  return DEFER_INSTANCE_TYPES[instanceType] == true
end

function SP.SetPendingSessionOver(pending)
  SP.EnsureDB()
  SP.db.pendingSessionOver = pending and true or false
end

function SP.IsPendingSessionOver()
  SP.EnsureDB()
  return SP.db.pendingSessionOver == true
end

--- Central path for SESSION OVER: defer in instances when toggle is on, else flash.
function SP.TriggerSessionOver(source)
  SP.EnsureDB()
  local deferOn = SP.db.deferInInstances ~= false
  if deferOn and SP.IsDeferWorthyInstance() then
    if not SP.IsPendingSessionOver() then
      SP.SetPendingSessionOver(true)
      Print("Session budget hit — SESSION OVER deferred until you leave this instance (/sp defer off to disable)")
    end
    if SP.UI and SP.UI.Hud and SP.UI.Hud.Refresh then
      SP.UI.Hud:Refresh()
    end
    return false
  end
  SP.SetPendingSessionOver(false)
  if SP.UI and SP.UI.Flash then
    SP.UI.Flash:Show()
  end
  return true
end

--- If pending and no longer in a defer-worthy instance, show the flash once.
function SP.MaybeFlushPendingSessionOver()
  if not SP.IsPendingSessionOver() then
    return
  end
  if SP.IsDeferWorthyInstance() then
    return
  end
  SP.SetPendingSessionOver(false)
  if SP.UI and SP.UI.Flash then
    SP.UI.Flash:Show()
  end
  Print("Left instance — SESSION OVER")
  if SP.UI and SP.UI.Hud and SP.UI.Hud.Refresh then
    SP.UI.Hud:Refresh()
  end
end

local function Usage()
  Print("Usage: /sp timer [min] | /sp timer stop | /sp elapsed | /sp hud | /sp defer [on|off] | /sp options")
end

SLASH_STOPPLAYING1 = "/sp"
SLASH_STOPPLAYING2 = "/stopplaying"
SlashCmdList.STOPPLAYING = function(msg)
  msg = (msg or ""):match("^%s*(.-)%s*$") or ""
  local cmd, rest = msg:match("^(%S+)%s*(.*)$")
  cmd = cmd and cmd:lower() or ""
  rest = (rest or ""):match("^%s*(.-)%s*$") or ""

  if cmd == "" or cmd == "help" then
    Usage()
    Print("  defer — toggle/instance-defer SESSION OVER (default on). /sp defer | /sp defer on|off")
    Print("  options|config — open Blizzard Settings → AddOns → StopPlaying")
    return
  end
  if cmd == "options" or cmd == "config" then
    if SP.Options and SP.Options.Open then
      SP.Options:Open()
    else
      Print("Options panel not available")
    end
    return
  end
  if cmd == "hud" then
    if SP.UI and SP.UI.Hud then SP.UI.Hud:Toggle() end
    return
  end
  if cmd == "elapsed" then
    if SP.UI and SP.UI.Timer then SP.UI.Timer:StartElapsed() end
    return
  end
  if cmd == "defer" then
    SP.EnsureDB()
    local arg = rest:lower()
    if arg == "on" or arg == "1" or arg == "true" then
      SP.db.deferInInstances = true
      Print("Defer SESSION OVER in party/raid/pvp/arena: ON")
    elseif arg == "off" or arg == "0" or arg == "false" then
      SP.db.deferInInstances = false
      Print("Defer SESSION OVER in party/raid/pvp/arena: OFF")
      -- If already pending, flush now that deferral is disabled
      if SP.IsPendingSessionOver() and not SP.IsDeferWorthyInstance() then
        SP.MaybeFlushPendingSessionOver()
      elseif SP.IsPendingSessionOver() then
        -- Still in instance but user turned defer off: show immediately
        SP.SetPendingSessionOver(false)
        if SP.UI and SP.UI.Flash then SP.UI.Flash:Show() end
        Print("Pending SESSION OVER shown (defer disabled)")
      end
    elseif arg == "" then
      SP.db.deferInInstances = not (SP.db.deferInInstances ~= false)
      Print("Defer SESSION OVER in instances: " .. (SP.db.deferInInstances and "ON" or "OFF"))
    else
      Print("Usage: /sp defer [on|off]")
      return
    end
    if SP.UI and SP.UI.Hud and SP.UI.Hud.Refresh then SP.UI.Hud:Refresh() end
    return
  end
  if cmd == "timer" then
    if rest:lower() == "stop" then
      if SP.UI and SP.UI.Timer then SP.UI.Timer:Stop() end
      return
    end
    local mins
    if rest == "" then
      SP.EnsureDB()
      mins = tonumber(SP.db.countdownMinutesDefault) or 60
    else
      mins = tonumber(rest)
    end
    if not mins or mins <= 0 then
      Usage()
      return
    end
    if SP.UI and SP.UI.Timer then SP.UI.Timer:StartCountdown(mins) end
    return
  end
  Usage()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == SP.ADDON then
    SP.EnsureDB()
    if SP.Config and SP.Config.OnLoad then SP.Config:OnLoad() end
  elseif event == "PLAYER_LOGIN" then
    SP.EnsureDB()
    if SP.UI then
      if SP.UI.Flash and SP.UI.Flash.Init then SP.UI.Flash:Init() end
      if SP.UI.Timer and SP.UI.Timer.Init then SP.UI.Timer:Init() end
      if SP.UI.Hud and SP.UI.Hud.Init then SP.UI.Hud:Init() end
    end
    if SP.Skins and SP.Skins.Apply then SP.Skins:Apply() end
    if SP.Options and SP.Options.Register then SP.Options:Register() end
    -- After /reload mid-dungeon with pending flag, wait for leave
    if SP.IsPendingSessionOver() then
      C_Timer.After(0.5, function() SP.MaybeFlushPendingSessionOver() end)
    end
    Print("v" .. SP.VERSION .. " ready — /sp timer 60 · /sp options · /sp defer")
  elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
    SP.EnsureDB()
    SP.MaybeFlushPendingSessionOver()
  end
end)
