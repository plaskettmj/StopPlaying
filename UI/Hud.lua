--[[ Movable session timer chip ]]
StopPlaying = StopPlaying or {}
StopPlaying.UI = StopPlaying.UI or {}
StopPlaying.UI.Hud = StopPlaying.UI.Hud or {}
local Hud = StopPlaying.UI.Hud

local BASE_W, BASE_H = 140, 28
local DEFAULT_FONT_PATH = "Fonts\\FRIZQT__.TTF"
local DEFAULT_FONT_KEY = "Friz Quadrata TT"

--- Built-in Blizzard fonts (retail paths).
Hud.BUILTIN_FONTS = {
  { key = "Friz Quadrata TT", path = "Fonts\\FRIZQT__.TTF" },
  { key = "Arial Narrow",     path = "Fonts\\ARIALN.TTF" },
  { key = "Morpheus",         path = "Fonts\\MORPHEUS.TTF" },
  { key = "Skurri",           path = "Fonts\\SKURRI.TTF" },
}

--- Resolve a font key to a file path. Tries built-ins then LibSharedMedia-3.0.
function Hud:ResolveFontPath(key)
  key = key or DEFAULT_FONT_KEY
  if key == "default" or key == "" then
    key = DEFAULT_FONT_KEY
  end
  for _, entry in ipairs(self.BUILTIN_FONTS) do
    if entry.key == key then
      return entry.path, entry.key
    end
  end
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local ok, path = pcall(function()
      return LSM:Fetch(LSM.MediaType.FONT, key, true)
    end)
    if ok and path and path ~= "" then
      return path, key
    end
  end
  return DEFAULT_FONT_PATH, DEFAULT_FONT_KEY
end

--- Apply scale + font from SavedVariables. Safe to call before/after Init.
function Hud:ApplyAppearance()
  if not self.frame then return end
  local db = StopPlaying.db
  if not db then return end

  local scale = 1.0
  if StopPlaying.Config and StopPlaying.Config.ClampHudScale then
    scale = StopPlaying.Config:ClampHudScale(db.hudScale)
  else
    scale = tonumber(db.hudScale) or 1.0
    if scale < 0.6 then scale = 0.6 end
    if scale > 2.0 then scale = 2.0 end
  end
  db.hudScale = scale

  self.frame:SetSize(BASE_W, BASE_H)
  pcall(function() self.frame:SetScale(scale) end)

  local size = tonumber(db.hudFontSize) or 12
  if size < 8 then size = 8 end
  if size > 32 then size = 32 end
  db.hudFontSize = size

  local path = select(1, self:ResolveFontPath(db.hudFont))
  local applied = false
  if self.frame.text and self.frame.text.SetFont then
    local ok = pcall(function()
      self.frame.text:SetFont(path, size, "OUTLINE")
    end)
    applied = ok
  end
  if not applied and self.frame.text then
    -- Fallback: inherit GameFontHighlight look
    pcall(function()
      local font, _, flags = GameFontHighlight:GetFont()
      self.frame.text:SetFont(font or DEFAULT_FONT_PATH, size, flags or "OUTLINE")
    end)
  end
end

function Hud:Init()
  if self.frame then
    self:ApplyAppearance()
    self:ApplyVisibility()
    self:Refresh()
    return
  end
  local f = CreateFrame("Frame", "StopPlayingTimerHud", UIParent, "BackdropTemplate")
  f:SetSize(BASE_W, BASE_H)
  f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  f:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
  f:SetBackdropBorderColor(0.4, 0.35, 0.2, 0.9)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint(1)
    StopPlaying.db.hudPoint = { p, nil, rp, x, y }
  end)

  f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.text:SetPoint("CENTER")
  f.text:SetText("Timer —")

  self.frame = f
  local hp = StopPlaying.db.hudPoint
  if hp then
    f:ClearAllPoints()
    f:SetPoint(hp[1], UIParent, hp[3], hp[4], hp[5])
  else
    f:SetPoint("TOP", UIParent, "TOP", 0, -8)
  end
  self:ApplyAppearance()
  self:ApplyVisibility()
  self:Refresh()
end

function Hud:ApplyVisibility()
  if not self.frame then return end
  local vis = StopPlaying.db.hudVisible
  if vis == nil then vis = true end
  if vis then self.frame:Show() else self.frame:Hide() end
end

function Hud:Toggle()
  local cur = StopPlaying.db.hudVisible
  if cur == nil then cur = true end
  StopPlaying.db.hudVisible = not cur
  self:ApplyVisibility()
end

function Hud:Refresh()
  if not self.frame then return end
  local label = "Timer —"
  if StopPlaying.UI.Timer and StopPlaying.UI.Timer.GetDisplay then
    label = StopPlaying.UI.Timer:GetDisplay()
  end
  self.frame.text:SetText(label)
  if StopPlaying.UI.Timer and StopPlaying.UI.Timer.ElapsedColor then
    local r, g, b = StopPlaying.UI.Timer:ElapsedColor()
    self.frame.text:SetTextColor(r, g, b)
  else
    self.frame.text:SetTextColor(1, 1, 1)
  end
end
