--[[ StopPlaying — session countdown / elapsed timer with stop alert ]]
StopPlaying = StopPlaying or {}
local SP = StopPlaying

SP.ADDON = "StopPlaying"
SP.VERSION = "1.1.0"

local defaults = {
  hudVisible = true,
  hudPoint = { "TOP", nil, "TOP", 0, -8 },
  timerMode = "off",
  timerEndsAt = nil,
  timerStartedAt = nil,
  countdownMinutesDefault = 60,
  breakpoints = { amber = 45 * 60, red = 75 * 60, pulse = 90 * 60 },
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
  SP.db = StopPlayingDB
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffc9a227StopPlaying|r: " .. tostring(msg))
end
SP.Print = Print

local function Usage()
  Print("Usage: /sp timer <min> | /sp timer stop | /sp elapsed | /sp hud")
end

SLASH_STOPPLAYING1 = "/sp"
SLASH_STOPPLAYING2 = "/stopplaying"
SlashCmdList.STOPPLAYING = function(msg)
  msg = (msg or ""):match("^%s*(.-)%s*$") or ""
  local cmd, rest = msg:match("^(%S+)%s*(.*)$")
  cmd = cmd and cmd:lower() or ""

  if cmd == "" or cmd == "help" then
    Usage()
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
  if cmd == "timer" then
    rest = (rest or ""):match("^%s*(.-)%s*$") or ""
    if rest:lower() == "stop" then
      if SP.UI and SP.UI.Timer then SP.UI.Timer:Stop() end
      return
    end
    local mins = tonumber(rest)
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
    Print("v" .. SP.VERSION .. " ready — /sp timer 60")
  end
end)
