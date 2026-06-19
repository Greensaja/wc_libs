-- client/modules/gps.lua — wc_lib
-- GPS multi-route helper (the "draw a route line to a destination"
-- pattern). Extracted from wc_encounter/client/utils.lua
-- (setEncounterGPS/clearEncounterGPS), generalized — framework-agnostic.

WCLibGPS = {}

--- Draws a GPS route to a single destination point.
-- @param x number
-- @param y number
-- @param z number
-- @param colorName string|nil  a COLOR_* hash name, defaults to 'COLOR_RED'
function WCLibGPS.SetRoute(x, y, z, colorName)
  SetGpsMultiRouteRender(false)
  ClearGpsMultiRoute()
  StartGpsMultiRoute(GetHashKey(colorName or 'COLOR_RED'), true, true)
  AddPointToGpsMultiRoute(x, y, z)
  SetGpsMultiRouteRender(true)
end

--- Clears any active GPS multi-route.
function WCLibGPS.ClearRoute()
  SetGpsMultiRouteRender(false)
  ClearGpsMultiRoute()
end
