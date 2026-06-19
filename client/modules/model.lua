-- client/modules/model.lua — wc_libs
-- Model & anim-dict loading helpers.
-- Extracted from wc_encounter/client/utils.lua — framework-agnostic,
-- pure native wrappers. No VORP/RSG branching needed here at all.

WCLibModel = {}

local function _hash(m)
  return type(m) == 'number' and m or GetHashKey(m)
end

--- Requests a ped/vehicle/object model and waits for it to load.
-- @param name string|number  model name or hash
-- @param timeoutMs number|nil  defaults to 8000
-- @return number|nil  the model hash if loaded, nil if invalid/timed out
function WCLibModel.LoadModel(name, timeoutMs)
  local h = _hash(name)
  if not IsModelValid(h) then return nil end
  RequestModel(h)
  local deadline = GetGameTimer() + (timeoutMs or 8000)
  while not HasModelLoaded(h) and GetGameTimer() < deadline do Wait(50) end
  return HasModelLoaded(h) and h or nil
end

--- Tries a list of model names in order, returns the first that loads.
-- Useful for ped pools where you want variety but any one is fine.
-- @param pool table  list of model names/hashes
-- @param timeoutMs number|nil  per-attempt timeout, defaults to 8000
-- @return number|nil
function WCLibModel.LoadAnyModel(pool, timeoutMs)
  for _, name in ipairs(pool or {}) do
    local h = WCLibModel.LoadModel(name, timeoutMs or 8000)
    if h then return h end
  end
  return nil
end

--- Requests an animation dictionary and waits for it to load.
-- @param dict string
-- @param ms number|nil  defaults to 5000
-- @return boolean  whether the dict loaded in time
function WCLibModel.LoadAnimDictSafe(dict, ms)
  RequestAnimDict(dict)
  local t = GetGameTimer() + (ms or 5000)
  while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(50) end
  return HasAnimDictLoaded(dict)
end
