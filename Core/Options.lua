--[[ Blizzard Settings → AddOns panel (canvas layout, v1.4) ]]
StopPlaying = StopPlaying or {}
StopPlaying.Options = StopPlaying.Options or {}
local O = StopPlaying.Options
local SP = StopPlaying

local registered = false
local canvas -- root panel frame
local widgets = {} -- refs for refresh

---------------------------------------------------------------------------
-- Shared helpers
---------------------------------------------------------------------------

local function OnDeferChanged(value)
  SP.EnsureDB()
  SP.db.deferInInstances = value and true or false
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

local function ApplyHudAppearance()
  if SP.UI and SP.UI.Hud and SP.UI.Hud.ApplyAppearance then
    SP.UI.Hud:ApplyAppearance()
  end
  if SP.UI and SP.UI.Hud and SP.UI.Hud.Refresh then
    SP.UI.Hud:Refresh()
  end
end

local function Label(parent, text, size)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetText(text or "")
  if size then
    pcall(function()
      local f, _, flags = fs:GetFont()
      fs:SetFont(f, size, flags)
    end)
  end
  return fs
end

local function MakeCheckbox(parent, name, labelText, initial, onClick)
  local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  local lbl = Label(cb, labelText)
  lbl:SetPoint("LEFT", cb, "RIGHT", 4, 1)
  cb:SetChecked(initial and true or false)
  cb:SetScript("OnClick", function(self)
    onClick(self:GetChecked())
  end)
  cb._label = lbl
  return cb
end

local function MakeSlider(parent, name, minV, maxV, step, initial, onChanged)
  local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  slider:SetMinMaxValues(minV, maxV)
  slider:SetValueStep(step)
  pcall(function() slider:SetObeyStepOnDrag(true) end)
  slider:SetWidth(200)
  slider:SetHeight(17)
  local low = _G[name .. "Low"]
  local high = _G[name .. "High"]
  local title = _G[name .. "Text"]
  if low then low:SetText(tostring(minV)) end
  if high then high:SetText(tostring(maxV)) end
  if title then title:SetText("") end
  slider:SetValue(initial)
  slider:SetScript("OnValueChanged", function(self, value)
    if self._suppress then return end
    onChanged(value)
  end)
  return slider
end

---------------------------------------------------------------------------
-- Font list (built-in + optional LibSharedMedia)
---------------------------------------------------------------------------

local function CollectFontKeys()
  local keys = {}
  local seen = {}
  local builtins = (SP.UI and SP.UI.Hud and SP.UI.Hud.BUILTIN_FONTS) or {
    { key = "Friz Quadrata TT" },
    { key = "Arial Narrow" },
    { key = "Morpheus" },
    { key = "Skurri" },
  }
  for _, e in ipairs(builtins) do
    if e.key and not seen[e.key] then
      seen[e.key] = true
      keys[#keys + 1] = e.key
    end
  end
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local ok, list = pcall(function() return LSM:List(LSM.MediaType.FONT) end)
    if ok and type(list) == "table" then
      for _, name in ipairs(list) do
        if name and not seen[name] then
          seen[name] = true
          keys[#keys + 1] = name
        end
      end
    end
  end
  table.sort(keys, function(a, b)
    -- Keep Friz first
    if a == "Friz Quadrata TT" then return true end
    if b == "Friz Quadrata TT" then return false end
    return a:lower() < b:lower()
  end)
  return keys
end

---------------------------------------------------------------------------
-- Breakpoint bar + editors
---------------------------------------------------------------------------

local function RefreshBreakpointUI()
  if not widgets.bp then return end
  local C = SP.Config
  if not C then return end
  local m = C:GetBreakpointsMinutes()
  local barMax = C:GetBarMaxMinutes()
  widgets.bp._suppress = true
  for _, key in ipairs({ "amber", "red", "pulse" }) do
    local eb = widgets.bp.edits[key]
    if eb then eb:SetText(tostring(m[key])) end
  end
  widgets.bp._suppress = false
  widgets.bp.barMax = barMax
  if widgets.bp.RedrawBar then
    widgets.bp.RedrawBar()
  end
end

local function SetBpFromUI(key, minutes)
  local C = SP.Config
  if not C then return end
  C:SetBreakpointMinutes(key, minutes)
  RefreshBreakpointUI()
  if SP.UI and SP.UI.Hud and SP.UI.Hud.Refresh then
    SP.UI.Hud:Refresh()
  end
end

local function BuildBreakpointSection(parent, yTop)
  local bp = { edits = {}, markers = {} }
  widgets.bp = bp

  local title = Label(parent, "Elapsed breakpoints (minutes)")
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yTop)
  title:SetTextColor(1, 0.82, 0)
  yTop = yTop - 22

  local keys = {
    { key = "amber", label = "Amber", color = { 1, 0.75, 0.2 } },
    { key = "red",   label = "Red",   color = { 1, 0.25, 0.2 } },
    { key = "pulse", label = "Pulse", color = { 1, 0.35, 0.35 } },
  }

  local rowY = yTop
  for i, info in ipairs(keys) do
    local lbl = Label(parent, info.label)
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, rowY)
    lbl:SetTextColor(info.color[1], info.color[2], info.color[3])

    local eb = CreateFrame("EditBox", "StopPlayingBP_" .. info.key, parent, "InputBoxTemplate")
    eb:SetSize(50, 20)
    eb:SetPoint("LEFT", lbl, "LEFT", 70, 0)
    eb:SetAutoFocus(false)
    eb:SetNumeric(true)
    eb:SetMaxLetters(4)
    eb:SetScript("OnEnterPressed", function(self)
      local v = tonumber(self:GetText())
      if v then SetBpFromUI(info.key, v) end
      self:ClearFocus()
    end)
    eb:SetScript("OnEditFocusLost", function(self)
      if bp._suppress then return end
      local v = tonumber(self:GetText())
      if v then SetBpFromUI(info.key, v) end
    end)
    bp.edits[info.key] = eb

    local up = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    up:SetSize(22, 20)
    up:SetPoint("LEFT", eb, "RIGHT", 6, 0)
    up:SetText("+")
    up:SetScript("OnClick", function()
      local cur = tonumber(eb:GetText()) or 0
      local step = IsShiftKeyDown() and 5 or 1
      SetBpFromUI(info.key, cur + step)
    end)

    local down = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    down:SetSize(22, 20)
    down:SetPoint("LEFT", up, "RIGHT", 2, 0)
    down:SetText("-")
    down:SetScript("OnClick", function()
      local cur = tonumber(eb:GetText()) or 0
      local step = IsShiftKeyDown() and 5 or 1
      SetBpFromUI(info.key, cur - step)
    end)

    local hint = Label(parent, "±1  (Shift ±5)")
    hint:SetPoint("LEFT", down, "RIGHT", 8, 0)
    hint:SetTextColor(0.55, 0.55, 0.55)
    if i ~= 1 then hint:Hide() end

    rowY = rowY - 28
  end

  -- Visual bar: domain 0 .. max(pulse*1.1, 120) minutes (documented in README)
  local barHost = CreateFrame("Frame", "StopPlayingBPBar", parent, "BackdropTemplate")
  barHost:SetSize(420, 36)
  barHost:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, rowY - 8)
  barHost:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  barHost:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
  barHost:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.8)
  bp.barHost = barHost

  local segGreen = barHost:CreateTexture(nil, "ARTWORK")
  local segAmber = barHost:CreateTexture(nil, "ARTWORK")
  local segRed = barHost:CreateTexture(nil, "ARTWORK")
  local segPulse = barHost:CreateTexture(nil, "ARTWORK")
  segGreen:SetColorTexture(0.35, 0.7, 0.4, 0.85)
  segAmber:SetColorTexture(1.0, 0.75, 0.2, 0.9)
  segRed:SetColorTexture(0.95, 0.25, 0.2, 0.9)
  segPulse:SetColorTexture(0.85, 0.15, 0.15, 0.55)

  local barLabel = Label(parent, "Bar scale: 0 … max(pulse×1.1, 120) min — drag markers")
  barLabel:SetPoint("TOPLEFT", barHost, "BOTTOMLEFT", 0, -4)
  barLabel:SetTextColor(0.55, 0.55, 0.55)

  local function MinutesToX(mins, barMax, width)
    if barMax <= 0 then return 0 end
    local t = math.max(0, math.min(1, mins / barMax))
    return t * width
  end

  local function XToMinutes(x, barMax, width)
    if width <= 0 then return 0 end
    local t = math.max(0, math.min(1, x / width))
    return math.floor(t * barMax + 0.5)
  end

  local function MakeMarker(key, r, g, b)
    local m = CreateFrame("Button", nil, barHost)
    m:SetSize(12, 28)
    m:SetFrameLevel(barHost:GetFrameLevel() + 5)
    local tex = m:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetColorTexture(r, g, b, 1)
    m.tex = tex
    local tip = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tip:SetPoint("BOTTOM", m, "TOP", 0, 1)
    tip:SetText(key:sub(1, 1):upper())
    m:EnableMouse(true)
    m:RegisterForDrag("LeftButton")
    m:SetScript("OnDragStart", function(self)
      self._dragging = true
    end)
    m:SetScript("OnDragStop", function(self)
      self._dragging = false
    end)
    m:SetScript("OnUpdate", function(self)
      if not self._dragging then return end
      local mx, my = GetCursorPosition()
      local scale = barHost:GetEffectiveScale()
      local left = barHost:GetLeft() or 0
      local width = barHost:GetWidth() - 4
      local x = (mx / scale) - left - 2
      x = math.max(0, math.min(width, x))
      local barMax = bp.barMax or 120
      local mins = XToMinutes(x, barMax, width)
      SetBpFromUI(key, mins)
    end)
    m:SetScript("OnClick", function(self)
      -- click focuses the matching edit box
      local eb = bp.edits[key]
      if eb then eb:SetFocus() end
    end)
    bp.markers[key] = m
    return m
  end

  MakeMarker("amber", 1, 0.75, 0.2)
  MakeMarker("red", 1, 0.25, 0.2)
  MakeMarker("pulse", 1, 0.4, 0.4)

  function bp.RedrawBar()
    local C = SP.Config
    if not C then return end
    local m = C:GetBreakpointsMinutes()
    local barMax = C:GetBarMaxMinutes()
    bp.barMax = barMax
    local width = barHost:GetWidth() - 4
    local h = 16
    local y = -10

    local function place(tex, fromMin, toMin)
      local x0 = MinutesToX(fromMin, barMax, width)
      local x1 = MinutesToX(toMin, barMax, width)
      tex:ClearAllPoints()
      tex:SetPoint("TOPLEFT", barHost, "TOPLEFT", 2 + x0, y)
      tex:SetSize(math.max(1, x1 - x0), h)
      tex:Show()
    end

    place(segGreen, 0, m.amber)
    place(segAmber, m.amber, m.red)
    place(segRed, m.red, m.pulse)
    place(segPulse, m.pulse, barMax)

    for _, key in ipairs({ "amber", "red", "pulse" }) do
      local marker = bp.markers[key]
      local x = MinutesToX(m[key], barMax, width)
      marker:ClearAllPoints()
      marker:SetPoint("CENTER", barHost, "TOPLEFT", 2 + x, y - h / 2)
    end

    barLabel:SetText(string.format(
      "Bar scale: 0 … %d min (max(pulse×1.1, 120)) — drag markers or edit boxes",
      barMax
    ))
  end

  -- Pulse zone shimmer
  barHost:SetScript("OnUpdate", function(self, elapsed)
    self._t = (self._t or 0) + elapsed
    local pulse = (math.sin(self._t * 4) * 0.5 + 0.5)
    segPulse:SetColorTexture(0.85, 0.1 + 0.2 * pulse, 0.1, 0.45 + 0.35 * pulse)
  end)

  RefreshBreakpointUI()
  return rowY - 70
end

---------------------------------------------------------------------------
-- Font dropdown
---------------------------------------------------------------------------

local DEFAULT_FONT_PATH_FALLBACK = "Fonts\\FRIZQT__.TTF"

local function UpdateFontPreview()
  local preview = widgets.fontPreview
  if not preview then return end
  SP.EnsureDB()
  local key = SP.db.hudFont or "Friz Quadrata TT"
  local size = tonumber(SP.db.hudFontSize) or 12
  local path = DEFAULT_FONT_PATH_FALLBACK
  if SP.UI and SP.UI.Hud and SP.UI.Hud.ResolveFontPath then
    path = select(1, SP.UI.Hud:ResolveFontPath(key))
  end
  local ok = pcall(function()
    preview:SetFont(path, math.max(12, size), "OUTLINE")
  end)
  if not ok then
    pcall(function()
      local f, _, flags = GameFontHighlight:GetFont()
      preview:SetFont(f, math.max(12, size), flags or "OUTLINE")
    end)
  end
  preview:SetText("Preview: CD 45:00")
  preview:SetTextColor(0.85, 0.95, 0.85)
end

local function BuildFontDropdown(parent, anchor)
  local label = Label(parent, "HUD font")
  label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -18)

  local dd = CreateFrame("Frame", "StopPlayingFontDropdown", parent, "UIDropDownMenuTemplate")
  dd:SetPoint("LEFT", label, "LEFT", 90, -2)

  local preview = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  preview:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -10)
  preview:SetText("Preview: CD 45:00")
  widgets.fontPreview = preview

  local function Selected()
    SP.EnsureDB()
    return SP.db.hudFont or "Friz Quadrata TT"
  end

  local function RefreshDD()
    if not UIDropDownMenu_SetText then return end
    pcall(UIDropDownMenu_SetText, dd, Selected())
  end

  local function ApplyFontChoice(key)
    SP.EnsureDB()
    SP.db.hudFont = key
    ApplyHudAppearance()
    UpdateFontPreview()
    RefreshDD()
  end

  local function Initialize(self, level)
    local keys = CollectFontKeys()
    local info
    for _, key in ipairs(keys) do
      info = UIDropDownMenu_CreateInfo()
      info.text = key
      info.checked = (key == Selected())
      info.func = function()
        ApplyFontChoice(key)
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end

  pcall(UIDropDownMenu_Initialize, dd, Initialize)
  pcall(UIDropDownMenu_SetWidth, dd, 180)
  RefreshDD()
  UpdateFontPreview()

  widgets.fontDropdown = dd
  widgets.RefreshFontDropdown = function()
    pcall(UIDropDownMenu_Initialize, dd, Initialize)
    RefreshDD()
    UpdateFontPreview()
  end

  -- LibSharedMedia callbacks: refresh list when fonts are registered
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM and LSM.RegisterCallback then
    local proxy = {}
    function proxy:LibSharedMedia_Registered(event, mediatype, key)
      if mediatype == nil or mediatype == LSM.MediaType.FONT then
        if widgets.RefreshFontDropdown then widgets.RefreshFontDropdown() end
      end
    end
    function proxy:LibSharedMedia_SetGlobal(event)
      if widgets.RefreshFontDropdown then widgets.RefreshFontDropdown() end
    end
    pcall(function()
      LSM.RegisterCallback(proxy, "LibSharedMedia_Registered", "LibSharedMedia_Registered")
      LSM.RegisterCallback(proxy, "LibSharedMedia_SetGlobal", "LibSharedMedia_SetGlobal")
    end)
    O._lsmProxy = proxy
  end

  return label
end

---------------------------------------------------------------------------
-- Build canvas
---------------------------------------------------------------------------

local function BuildCanvas()
  if canvas then return canvas end

  local root = CreateFrame("Frame", "StopPlayingOptionsCanvas")
  root:Hide()
  -- Settings canvas typically fills the category page; give a tall content height
  root:SetSize(660, 620)

  local scroll = CreateFrame("ScrollFrame", "StopPlayingOptionsScroll", root, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -8)
  scroll:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -28, 8)

  local content = CreateFrame("Frame", "StopPlayingOptionsContent", scroll)
  content:SetSize(620, 900)
  scroll:SetScrollChild(content)

  SP.EnsureDB()
  local db = SP.db
  local y = -8

  -- Header
  local header = Label(content, "StopPlaying  v" .. (SP.VERSION or ""))
  header:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  pcall(function()
    local f, _, flags = header:GetFont()
    header:SetFont(f, 16, flags)
  end)
  y = y - 28

  -- --- General ---
  local genTitle = Label(content, "General")
  genTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  genTitle:SetTextColor(1, 0.82, 0)
  y = y - 24

  local deferCb = MakeCheckbox(
    content,
    "StopPlayingOpt_Defer",
    "Defer SESSION OVER in dungeons/raids/PvP",
    db.deferInInstances ~= false,
    function(checked)
      OnDeferChanged(checked)
    end
  )
  deferCb:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y)
  widgets.deferCb = deferCb
  y = y - 28

  local deferHint = Label(content, "Hold the flash until you leave party/raid/pvp/arena instances.")
  deferHint:SetPoint("TOPLEFT", content, "TOPLEFT", 42, y)
  deferHint:SetTextColor(0.6, 0.6, 0.6)
  y = y - 22

  local hudCb = MakeCheckbox(
    content,
    "StopPlayingOpt_Hud",
    "Show timer HUD",
    db.hudVisible ~= false,
    function(checked)
      SP.EnsureDB()
      SP.db.hudVisible = checked and true or false
      if SP.UI and SP.UI.Hud and SP.UI.Hud.ApplyVisibility then
        SP.UI.Hud:ApplyVisibility()
      end
    end
  )
  hudCb:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y)
  widgets.hudCb = hudCb
  y = y - 28

  local hudHint = Label(content, "Show the movable session timer chip. You can also toggle with /sp hud.")
  hudHint:SetPoint("TOPLEFT", content, "TOPLEFT", 42, y)
  hudHint:SetTextColor(0.6, 0.6, 0.6)
  y = y - 26

  -- Default countdown minutes
  local minsLabel = Label(content, "Default countdown minutes")
  minsLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  y = y - 18

  local minsVal = Label(content, tostring(db.countdownMinutesDefault or 60))
  minsVal:SetPoint("TOPLEFT", content, "TOPLEFT", 240, y + 18)

  local minsSlider = MakeSlider(
    content,
    "StopPlayingOpt_Mins",
    5, 180, 5,
    tonumber(db.countdownMinutesDefault) or 60,
    function(value)
      value = math.floor(value / 5 + 0.5) * 5
      SP.EnsureDB()
      SP.db.countdownMinutesDefault = value
      minsVal:SetText(tostring(value))
    end
  )
  minsSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y - 4)
  local low = _G["StopPlayingOpt_MinsLow"]
  local high = _G["StopPlayingOpt_MinsHigh"]
  if low then low:SetText("5") end
  if high then high:SetText("180") end
  widgets.minsSlider = minsSlider
  y = y - 48

  local minsHint = Label(content, "Preferred budget length; start with /sp timer or /sp timer <minutes>.")
  minsHint:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  minsHint:SetTextColor(0.6, 0.6, 0.6)
  y = y - 30

  -- --- Appearance ---
  local appTitle = Label(content, "Appearance")
  appTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  appTitle:SetTextColor(1, 0.82, 0)
  y = y - 24

  local scaleLabel = Label(content, "HUD scale")
  scaleLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  y = y - 18

  local scalePct = math.floor((tonumber(db.hudScale) or 1.0) * 100 + 0.5)
  local scaleVal = Label(content, scalePct .. "%")
  scaleVal:SetPoint("TOPLEFT", content, "TOPLEFT", 240, y + 18)

  local scaleSlider = MakeSlider(
    content,
    "StopPlayingOpt_Scale",
    60, 200, 5,
    scalePct,
    function(value)
      value = math.floor(value / 5 + 0.5) * 5
      local scale = value / 100
      SP.EnsureDB()
      if SP.Config and SP.Config.ClampHudScale then
        scale = SP.Config:ClampHudScale(scale)
      end
      SP.db.hudScale = scale
      scaleVal:SetText(tostring(math.floor(scale * 100 + 0.5)) .. "%")
      ApplyHudAppearance()
    end
  )
  scaleSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y - 4)
  local sLow = _G["StopPlayingOpt_ScaleLow"]
  local sHigh = _G["StopPlayingOpt_ScaleHigh"]
  if sLow then sLow:SetText("60%") end
  if sHigh then sHigh:SetText("200%") end
  widgets.scaleSlider = scaleSlider
  y = y - 48

  local scaleHint = Label(content, "HUD chip scale (60%–200%). Applied via SetScale; font stays sharp via SetFont.")
  scaleHint:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  scaleHint:SetTextColor(0.6, 0.6, 0.6)
  y = y - 26

  -- Font dropdown (anchor = scaleHint)
  local fontAnchor = CreateFrame("Frame", nil, content)
  fontAnchor:SetSize(1, 1)
  fontAnchor:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  BuildFontDropdown(content, fontAnchor)
  y = y - 58

  local fontHint = Label(content, "Preview updates instantly. The HUD chip updates immediately too — no /reload needed.")
  fontHint:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  fontHint:SetTextColor(0.6, 0.6, 0.6)
  y = y - 18
  local fontHint2 = Label(content, "Built-in Blizzard fonts; LibSharedMedia fonts appear when LSM is loaded.")
  fontHint2:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  fontHint2:SetTextColor(0.6, 0.6, 0.6)
  y = y - 28

  -- --- Elapsed breakpoints (title lives inside BuildBreakpointSection) ---
  local newY = BuildBreakpointSection(content, y)
  y = newY - 20

  local foot = Label(content, "Constraint: 1 ≤ amber < red < pulse ≤ 600 minutes. Values auto-clamp.")
  foot:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
  foot:SetTextColor(0.55, 0.55, 0.55)

  -- Sync widgets when panel is shown
  root:SetScript("OnShow", function()
    SP.EnsureDB()
    local d = SP.db
    if widgets.deferCb then
      widgets.deferCb:SetChecked(d.deferInInstances ~= false)
    end
    if widgets.hudCb then
      widgets.hudCb:SetChecked(d.hudVisible ~= false)
    end
    if widgets.minsSlider then
      widgets.minsSlider._suppress = true
      widgets.minsSlider:SetValue(tonumber(d.countdownMinutesDefault) or 60)
      widgets.minsSlider._suppress = false
      minsVal:SetText(tostring(d.countdownMinutesDefault or 60))
    end
    if widgets.scaleSlider then
      local pct = math.floor((tonumber(d.hudScale) or 1.0) * 100 + 0.5)
      widgets.scaleSlider._suppress = true
      widgets.scaleSlider:SetValue(pct)
      widgets.scaleSlider._suppress = false
      scaleVal:SetText(pct .. "%")
    end
    if widgets.RefreshFontDropdown then widgets.RefreshFontDropdown() end
    if UpdateFontPreview then UpdateFontPreview() end
    RefreshBreakpointUI()
  end)

  canvas = root
  O.canvas = root
  O.content = content
  return root
end

---------------------------------------------------------------------------
-- Register / Open
---------------------------------------------------------------------------

function O:Register()
  if registered then return end
  if not Settings then return end

  local frame = BuildCanvas()
  if not frame then return end

  local ok, category
  if Settings.RegisterCanvasLayoutCategory then
    ok, category = pcall(Settings.RegisterCanvasLayoutCategory, frame, "StopPlaying")
  end
  if not ok or not category then
    -- Fallback: vertical layout with a note (should be rare on Midnight)
    if Settings.RegisterVerticalLayoutCategory then
      ok, category = pcall(Settings.RegisterVerticalLayoutCategory, "StopPlaying")
    end
    if not ok or not category then
      return
    end
  end

  pcall(Settings.RegisterAddOnCategory, category)
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
