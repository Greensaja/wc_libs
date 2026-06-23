---@diagnostic disable
-- client/modules/marker.lua — wc_libs
-- Ground-circle (DrawMarker) helper.
-- In RedM, DrawMarker is invoked via native 0x2A32FAA57B937173.
-- Default marker type 0x94FDAE17 renders as a flat disc on the ground.

WCLibMarker = {}

--- Creates a ground-circle marker that draws every frame until removed.
-- Returns a handle with a Remove() method.
-- @param x number
-- @param y number
-- @param z number
-- @param opts table|nil
--   opts.type       number|nil  marker type hash, default 0x94FDAE17 (flat disc)
--   opts.scaleX     number|nil  horizontal radius, default 1.0
--   opts.scaleY     number|nil  y-axis radius, default equals scaleX
--   opts.scaleZ     number|nil  disc height, default 0.1
--   opts.r          number|nil  red   0-255, default 255
--   opts.g          number|nil  green 0-255, default 255
--   opts.b          number|nil  blue  0-255, default 255
--   opts.a          number|nil  alpha 0-255, default 150
--   opts.drawRadius number|nil  only render when player is within this distance
-- @return table  handle — call handle:Remove() to stop drawing
function WCLibMarker.Create(x, y, z, opts)
  opts = opts or {}
  local markerType = opts.type   or 0x94FDAE17
  local sx = opts.scaleX or 1.0
  local sy = opts.scaleY or sx
  local sz = opts.scaleZ or 0.1
  local r  = opts.r or 255
  local g  = opts.g or 255
  local b  = opts.b or 255
  local a  = opts.a or 150
  local drawRadius = opts.drawRadius

  local handle = { active = true }

  function handle:Remove()
    self.active = false
  end

  CreateThread(function()
    while handle.active do
      local draw = true
      if drawRadius then
        local pp = GetEntityCoords(PlayerPedId())
        local dx = pp.x - x
        local dy = pp.y - y
        draw = (dx * dx + dy * dy) <= (drawRadius * drawRadius)
      end
      if draw then
        Citizen.InvokeNative(0x2A32FAA57B937173,
          markerType,
          x + 0.0, y + 0.0, z + 0.0,
          0.0, 0.0, 0.0,
          0.0, 0.0, 0.0,
          sx + 0.0, sy + 0.0, sz + 0.0,
          r, g, b, a,
          false, false, 0, false, nil, nil, false)
      end
      Wait(0)
    end
  end)

  return handle
end
