-- server/modules/revive.lua — wc_libs
-- Public Revive/Heal access. Dispatches to the active adapter.
--
-- On VORP: native Core.Player.Revive/Heal.
-- On RSG: no-op + console warning if the configured ambulance
-- resource (WCLibConfig.RSGAmbulanceResource) isn't running, per the
-- locked design decision — never errors, just tells you why nothing
-- happened.

WCLibRevive = {}
WCLibRevive._activeAdapter = nil

--- @param source integer
-- @return boolean  success
function WCLibRevive.Revive(source)
  if not WCLibRevive._activeAdapter then return false end
  return WCLibRevive._activeAdapter.Revive(source)
end

--- @param source integer
-- @return boolean  success
function WCLibRevive.Heal(source)
  if not WCLibRevive._activeAdapter then return false end
  return WCLibRevive._activeAdapter.Heal(source)
end
