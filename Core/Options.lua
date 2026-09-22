--[[ Blizzard Settings → AddOns panel (modern Settings API) ]]
StopPlaying = StopPlaying or {}
StopPlaying.Options = StopPlaying.Options or {}
local O = StopPlaying.Options
local SP = StopPlaying

local registered = false

--- Mirror /sp defer off when Settings toggle turns deferral off with a pending flash.
local function OnDeferChanged(_, value)
  SP.EnsureDB()
  if value == false and SP.IsPendingSessionOver and SP.IsPendingSessionOver() then
    if SP.IsDeferWorthyInstance and SP.IsDeferWorthyInstance() then
      SP.SetPendingSessionOver(false)
      if SP.UI and SP.UI.Flash then SP.UI.Flash:Show() end
      if SP.Print then SP.Print("Pending SESSION OVER shown (defer disabled)") end
    elseif SP.MaybeFlushPendingSessionOver then
      SP.MaybeFlushPendingSessionOver()
    end
  end
  if SP.UI and SP.UI.Hud and SP.UI.Hud.Refresh then
    SP.UI.Hud:Refresh()
  end
end

local function OnHudVisibleChanged(_, value)
  SP.EnsureDB()
  -- Ensure DB matches (Settings already wrote); refresh visibility
  if value ~= nil then
    SP.db.hudVisible = value and true or false
  end
  if SP.UI and SP.UI.Hud and SP.UI.Hud.ApplyVisibility then
    SP.UI.Hud:ApplyVisibility()
  end
end

local function AttachChangedCallback(setting, variableId, fn)
  if not setting then return end
  if type(setting.SetValueChangedCallback) == "function" then
    pcall(setting.SetValueChangedCallback, setting, fn)
  elseif Settings.SetOnValueChangedCallback then
    pcall(Settings.SetOnValueChangedCallback, variableId, fn)
  end
end

function O:Register()
  if registered then return end
  if not Settings or not Settings.RegisterVerticalLayoutCategory then
    return
  end

  SP.EnsureDB()

  local ok, category = pcall(Settings.RegisterVerticalLayoutCategory, "StopPlaying")
  if not ok or not category then
    return
  end

  -- Defer SESSION OVER in instances
  local deferSetting
  ok, deferSetting = pcall(
    Settings.RegisterAddOnSetting,
    category,
    "StopPlaying_deferInInstances",
    "deferInInstances",
    StopPlayingDB,
    Settings.VarType.Boolean,
    "Defer SESSION OVER in dungeons/raids/PvP",
    true
  )
  if ok and deferSetting then
    pcall(Settings.CreateCheckbox, category, deferSetting,
      "Hold the flash until you leave party/raid/pvp/arena instances.")
    AttachChangedCallback(deferSetting, "StopPlaying_deferInInstances", OnDeferChanged)
  end

  -- Show timer HUD
  local hudSetting
  ok, hudSetting = pcall(
    Settings.RegisterAddOnSetting,
    category,
    "StopPlaying_hudVisible",
    "hudVisible",
    StopPlayingDB,
    Settings.VarType.Boolean,
    "Show timer HUD",
    true
  )
  if ok and hudSetting then
    pcall(Settings.CreateCheckbox, category, hudSetting,
      "Show the movable session timer chip. You can also toggle with /sp hud.")
    AttachChangedCallback(hudSetting, "StopPlaying_hudVisible", OnHudVisibleChanged)
  end

  -- Default countdown minutes (slider when API available)
  if Settings.VarType and Settings.VarType.Number and Settings.CreateSlider then
    local minsSetting
    ok, minsSetting = pcall(
      Settings.RegisterAddOnSetting,
      category,
      "StopPlaying_countdownMinutesDefault",
      "countdownMinutesDefault",
      StopPlayingDB,
      Settings.VarType.Number,
      "Default countdown minutes",
      60
    )
    if ok and minsSetting and Settings.CreateSliderOptions then
      local optOk, options = pcall(Settings.CreateSliderOptions, 5, 180, 5)
      if optOk and options then
        if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label
            and options.SetLabelFormatter then
          pcall(function()
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
          end)
        end
        pcall(Settings.CreateSlider, category, minsSetting, options,
          "Preferred budget length; start a timer with /sp timer <minutes>.")
      end
    end
  end

  pcall(Settings.RegisterAddOnCategory, category)
  -- Stable id for Settings.OpenToCategory
  category.ID = "StopPlaying"
  SP.settingsCategory = category
  registered = true
end

--- Open the StopPlaying category in Blizzard Settings (AddOns tab).
function O:Open()
  self:Register()
  local cat = SP.settingsCategory
  if not Settings or not Settings.OpenToCategory then
    if SP.Print then SP.Print("Settings API unavailable on this client") end
    return
  end
  if cat then
    local id = cat.ID
    if type(cat.GetID) == "function" then
      local idOk, got = pcall(cat.GetID, cat)
      if idOk and got ~= nil then id = got end
    end
    local opened = pcall(Settings.OpenToCategory, id)
    if not opened then
      pcall(Settings.OpenToCategory, cat)
    end
  else
    pcall(Settings.OpenToCategory, "StopPlaying")
  end
end
