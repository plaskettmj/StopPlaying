--[[ Full-UI flash overlay when countdown hits zero ]]
StopPlaying = StopPlaying or {}
StopPlaying.UI = StopPlaying.UI or {}
StopPlaying.UI.Flash = StopPlaying.UI.Flash or {}
local F = StopPlaying.UI.Flash

function F:Init()
  if self.frame then return end
  local f = CreateFrame("Frame", "StopPlayingFlashFrame", UIParent)
  f:SetAllPoints(UIParent)
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:Hide()
  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetAllPoints()
  f.bg:SetColorTexture(0.55, 0.05, 0.05, 0.55)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  f.title:SetPoint("CENTER", 0, 40)
  f.title:SetText("SESSION OVER")
  f.title:SetTextColor(1, 0.85, 0.2)

  f.plus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.plus:SetSize(120, 32)
  f.plus:SetPoint("CENTER", -70, -30)
  f.plus:SetText("+15 min")
  f.plus:SetScript("OnClick", function()
    self:Hide()
    if StopPlaying.UI.Timer then StopPlaying.UI.Timer:StartCountdown(15) end
  end)

  f.dismiss = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.dismiss:SetSize(120, 32)
  f.dismiss:SetPoint("CENTER", 70, -30)
  f.dismiss:SetText("Dismiss")
  f.dismiss:SetScript("OnClick", function()
    self:Hide()
    if StopPlaying.UI.Timer then StopPlaying.UI.Timer:Stop() end
  end)

  f.pulse = 0
  f:SetScript("OnUpdate", function(_, elapsed)
    f.pulse = f.pulse + elapsed
    local a = 0.35 + 0.25 * (math.sin(f.pulse * 6) * 0.5 + 0.5)
    f.bg:SetColorTexture(0.65, 0.02, 0.02, a)
  end)

  self.frame = f
end

function F:Show()
  self:Init()
  self.frame:Show()
end

function F:Hide()
  if self.frame then self.frame:Hide() end
end
