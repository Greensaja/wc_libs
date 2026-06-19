-- client/modules/distance.lua — wc_libs
-- Distance / proximity helpers.
-- Extracted from the pattern repeated across wc_encounter's
-- client.lua (_dist3D2, zone checks) and every encounter file's
-- "#(GetEntityCoords(playerPed) - GetEntityCoords(ped)) < X" checks.
-- Framework-agnostic — pure math.

WCLibDistance = {}

--- Squared 3D distance between two points. Avoids a sqrt call when
-- you only need to compare against a squared radius — slightly
-- cheaper if called every tick in a hot loop.
-- @return number
function WCLibDistance.SquaredDistance(ax, ay, az, bx, by, bz)
  local dx, dy, dz = ax - bx, ay - by, az - bz
  return dx * dx + dy * dy + dz * dz
end

--- Actual 3D distance between two points (vector3 or {x,y,z} tables).
-- @param a table  vector3 or {x,y,z}
-- @param b table  vector3 or {x,y,z}
-- @return number
function WCLibDistance.GetDistance(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  local dz = a.z - b.z
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Checks whether `point` is within `radius` of `center`.
-- Uses squared comparison internally — no sqrt.
-- @param point table  vector3 or {x,y,z}
-- @param center table  vector3 or {x,y,z}
-- @param radius number
-- @return boolean
function WCLibDistance.IsNearCoords(point, center, radius)
  local d2 = WCLibDistance.SquaredDistance(point.x, point.y, point.z, center.x, center.y, center.z)
  return d2 <= (radius * radius)
end

--- Convenience: checks whether the local player ped is within
-- `radius` of `center`. Saves the GetEntityCoords(PlayerPedId())
-- boilerplate at every call site.
-- @param center table  vector3 or {x,y,z}
-- @param radius number
-- @return boolean
function WCLibDistance.IsPlayerNearCoords(center, radius)
  local p = GetEntityCoords(PlayerPedId())
  return WCLibDistance.IsNearCoords(p, center, radius)
end
