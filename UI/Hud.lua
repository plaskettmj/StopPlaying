--[[ Movable session timer chip ]]
StopPlaying = StopPlaying or {}
StopPlaying.UI = StopPlaying.UI or {}
StopPlaying.UI.Hud = StopPlaying.UI.Hud or {}
local Hud = StopPlaying.UI.Hud

function Hud:Init()
  if self.frame then
    self:ApplyVisibility()
    self:Refresh()
    return
  end
  local f = CreateFrame("Frame", "StopPlayingTimerHud", UIParent, "BackdropTemplate")
  f:SetSize(140, 28)
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
