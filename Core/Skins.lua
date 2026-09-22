--[[ Soft skin support: ElvUI / Masque / Skinner / Aurora (no hard deps) ]]
StopPlaying = StopPlaying or {}
StopPlaying.Skins = StopPlaying.Skins or {}
local Skins = StopPlaying.Skins

local applied = false

local function TryElvUI()
  if not _G.ElvUI then return end
  local ok, E = pcall(function() return unpack(ElvUI) end)
  if not ok or not E then return end
  local S = E:GetModule("Skins", true)
  if not S then return end

  local Flash = StopPlaying.UI and StopPlaying.UI.Flash
  if Flash then
    if Flash.plusBtn and S.HandleButton then
      pcall(S.HandleButton, S, Flash.plusBtn)
    end
    if Flash.dismissBtn and S.HandleButton then
      pcall(S.HandleButton, S, Flash.dismissBtn)
    end
  end

  local Hud = StopPlaying.UI and StopPlaying.UI.Hud
  local frame = Hud and Hud.frame
  if frame then
    if S.HandleFrame then
      pcall(S.HandleFrame, S, frame)
    elseif frame.SetTemplate then
      pcall(frame.SetTemplate, frame, "Transparent")
    end
  end
end

local function TryMasque()
  if not LibStub then return end
  local MSQ = LibStub("Masque", true)
  if not MSQ then return end

  local Flash = StopPlaying.UI and StopPlaying.UI.Flash
  if not Flash then return end

  local group = MSQ:Group("StopPlaying", "Flash")
  if not group or not group.AddButton then return end

  if Flash.plusBtn then
    pcall(function() group:AddButton(Flash.plusBtn) end)
  end
  if Flash.dismissBtn then
    pcall(function() group:AddButton(Flash.dismissBtn) end)
  end
  Skins.masqueGroup = group
end

local function TrySkinner()
  local sk = _G.Skinner
  if not sk or type(sk.applySkin) ~= "function" then return end

  local Hud = StopPlaying.UI and StopPlaying.UI.Hud
  if Hud and Hud.frame then
    pcall(sk.applySkin, sk, Hud.frame)
  end

  local Flash = StopPlaying.UI and StopPlaying.UI.Flash
  if Flash then
    if Flash.plusBtn then pcall(sk.applySkin, sk, Flash.plusBtn) end
    if Flash.dismissBtn then pcall(sk.applySkin, sk, Flash.dismissBtn) end
  end
end

local function TryAurora()
  local A = _G.Aurora2 or _G.Aurora
  if not A then return end

  local function skinFrame(frame)
    if not frame then return end
    if type(A.SkinFrame) == "function" then
      pcall(A.SkinFrame, A, frame)
    elseif type(A.CreateBackdrop) == "function" then
      pcall(A.CreateBackdrop, A, frame)
    elseif A.Base and type(A.Base.SetBackdrop) == "function" then
      pcall(A.Base.SetBackdrop, A.Base, frame)
    end
  end

  local function skinButton(btn)
    if not btn then return end
    if type(A.SkinButton) == "function" then
      pcall(A.SkinButton, A, btn)
    else
      skinFrame(btn)
    end
  end

  local Hud = StopPlaying.UI and StopPlaying.UI.Hud
  if Hud and Hud.frame then skinFrame(Hud.frame) end

  local Flash = StopPlaying.UI and StopPlaying.UI.Flash
  if Flash then
    skinButton(Flash.plusBtn)
    skinButton(Flash.dismissBtn)
  end
end

--- Best-effort skin hooks. Safe when skin addons are absent.
function Skins:Apply()
  if applied then return end
  applied = true
  pcall(TryElvUI)
  pcall(TryMasque)
  pcall(TrySkinner)
  pcall(TryAurora)
end
