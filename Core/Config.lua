--[[ Breakpoints for elapsed mode ]]
StopPlaying = StopPlaying or {}
StopPlaying.Config = StopPlaying.Config or {}
local C = StopPlaying.Config

function C:OnLoad()
end

function C:GetBreakpoints()
  local db = StopPlaying.db
  return db.breakpoints or { amber = 45 * 60, red = 75 * 60, pulse = 90 * 60 }
end
