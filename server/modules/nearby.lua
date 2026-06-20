-- server/modules/nearby.lua — wc_libs
-- Server-side proximity query helpers. Framework-agnostic — pure FiveM natives.

WCLibNearby = {}

--- Returns all player source IDs within `radius` metres of `source`.
-- The result never includes `source` itself.
-- @param source number  the reference player source
-- @param radius number  metres
-- @return table  array of source IDs (empty if none)
function WCLibNearby.GetPlayersInRadius(source, radius)
  local result  = {}
  local srcCoords = GetEntityCoords(GetPlayerPed(source))
  local r2 = radius * radius

  for _, pid in ipairs(GetPlayers()) do
    local s = tonumber(pid)
    if s and s ~= source then
      local c = GetEntityCoords(GetPlayerPed(s))
      local dx, dy, dz = srcCoords.x - c.x, srcCoords.y - c.y, srcCoords.z - c.z
      if (dx * dx + dy * dy + dz * dz) <= r2 then
        result[#result + 1] = s
      end
    end
  end

  return result
end
