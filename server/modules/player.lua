-- server/modules/player.lua — wc_lib
-- Public player/character/job access. Dispatches to whichever
-- framework adapter is active (set by server/init.lua).
--
-- Best practice reminder (from both VORP and RSG's own docs): never
-- cache the result of these calls across waits/threads — always grab
-- fresh data right before you use it.

WCLibPlayer = {}
WCLibPlayer._activeAdapter = nil

--- Returns a flat snapshot table of player data:
-- { source, charid, firstname, lastname, job = {name,label,grade,onduty},
--   money, gold, rol, xp, age, gender, group }
-- Some fields are nil on frameworks that don't have the concept
-- (e.g. `gold`/`rol` are always nil on RSG, `onduty` is currently nil
-- on VORP — see the relevant adapter for details).
-- @param source integer
-- @return table|nil
function WCLibPlayer.GetPlayer(source)
  if not WCLibPlayer._activeAdapter then return nil end
  return WCLibPlayer._activeAdapter.GetPlayer(source)
end

--- Returns the raw underlying character/player object for the active
-- framework (VORP's `character`, RSG's `Player`). Use this when you
-- need to call a framework-native method the flat GetPlayer() table
-- doesn't expose — it's the same object server.lua/webhook.lua were
-- duplicating resolution logic for.
-- @param source integer
-- @return table|nil
function WCLibPlayer.GetCharacter(source)
  if not WCLibPlayer._activeAdapter then return nil end
  return WCLibPlayer._activeAdapter.GetCharacter(source)
end

--- @return table|nil  { name, label, grade, onduty }
function WCLibPlayer.GetJob(source)
  if not WCLibPlayer._activeAdapter then return nil end
  return WCLibPlayer._activeAdapter.GetJob(source)
end
