--[[ Breakpoints + appearance helpers ]]
StopPlaying = StopPlaying or {}
StopPlaying.Config = StopPlaying.Config or {}
local C = StopPlaying.Config

local BP_MIN = 1
local BP_MAX = 600

function C:OnLoad()
end

--- Seconds table { amber, red, pulse }
function C:GetBreakpoints()
  local db = StopPlaying.db
  return db.breakpoints or { amber = 45 * 60, red = 75 * 60, pulse = 90 * 60 }
end

--- Minutes table { amber, red, pulse } (integers)
function C:GetBreakpointsMinutes()
  local bp = self:GetBreakpoints()
  return {
    amber = math.floor((bp.amber or 2700) / 60 + 0.5),
    red   = math.floor((bp.red   or 4500) / 60 + 0.5),
    pulse = math.floor((bp.pulse or 5400) / 60 + 0.5),
  }
end

--- Gentle clamp/reorder so 1 ≤ amber < red < pulse ≤ 600
function C:NormalizeBreakpointsMinutes(amber, red, pulse)
  amber = math.floor(tonumber(amber) or 45)
  red   = math.floor(tonumber(red) or 75)
  pulse = math.floor(tonumber(pulse) or 90)

  amber = math.max(BP_MIN, math.min(BP_MAX - 2, amber))
  red   = math.max(BP_MIN + 1, math.min(BP_MAX - 1, red))
  pulse = math.max(BP_MIN + 2, math.min(BP_MAX, pulse))

  if amber >= red then red = amber + 1 end
  if red >= pulse then pulse = red + 1 end
  if pulse > BP_MAX then
    pulse = BP_MAX
    if red >= pulse then red = pulse - 1 end
    if amber >= red then amber = red - 1 end
    amber = math.max(BP_MIN, amber)
  end
  return amber, red, pulse
end

--- Write minutes into db.breakpoints (as seconds). Returns normalized minutes.
function C:SetBreakpointsMinutes(amber, red, pulse)
  StopPlaying.EnsureDB()
  amber, red, pulse = self:NormalizeBreakpointsMinutes(amber, red, pulse)
  StopPlaying.db.breakpoints = {
    amber = amber * 60,
    red   = red * 60,
    pulse = pulse * 60,
  }
  return amber, red, pulse
end

--- Set one key (amber|red|pulse) in minutes; reorders others gently.
function C:SetBreakpointMinutes(key, minutes)
  local m = self:GetBreakpointsMinutes()
  if key == "amber" then m.amber = minutes
  elseif key == "red" then m.red = minutes
  elseif key == "pulse" then m.pulse = minutes
  else return m end
  local a, r, p = self:SetBreakpointsMinutes(m.amber, m.red, m.pulse)
  return { amber = a, red = r, pulse = p }
end

--- Bar domain in minutes: 0 .. max(pulse * 1.1, 120), floored to int.
function C:GetBarMaxMinutes()
  local m = self:GetBreakpointsMinutes()
  local mx = math.max(math.ceil((m.pulse or 90) * 1.1), 120)
  return math.min(BP_MAX + 60, mx)
end

function C:ClampHudScale(v)
  v = tonumber(v) or 1.0
  if v < 0.6 then return 0.6 end
  if v > 2.0 then return 2.0 end
  return v
end
