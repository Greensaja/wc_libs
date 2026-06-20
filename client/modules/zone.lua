-- client/modules/zone.lua — wc_libs
-- Radius-based zone exclusion helpers. Framework-agnostic.
-- Pattern extracted from wc_encounter/client/client.lua (IsInNoEncounterZone).
-- Use this for "don't trigger inside cities" checks in any resource.

WCLibZone = {}

--- Tests whether a position is inside any zone in the list.
-- Uses squared-distance comparison — no sqrt per call.
--
-- @param pos table  vector3 or {x, y, z}
-- @param zones table  array of { x, y, z, radius, name? }
-- @return boolean, string|nil  inside, name of matching zone (or nil)
function WCLibZone.IsInside(pos, zones)
  if not zones or #zones == 0 then return false, nil end
  for _, z in ipairs(zones) do
    local dx = pos.x - (z.x or 0.0)
    local dy = pos.y - (z.y or 0.0)
    local dz = pos.z - (z.z or 0.0)
    if (dx * dx + dy * dy + dz * dz) <= (z.radius * z.radius) then
      return true, z.name
    end
  end
  return false, nil
end

--- Convenience wrapper: tests whether the local player ped is inside any zone.
-- @param zones table  same format as IsInside
-- @return boolean, string|nil
function WCLibZone.IsPlayerInside(zones)
  local p = GetEntityCoords(PlayerPedId())
  return WCLibZone.IsInside(p, zones)
end
