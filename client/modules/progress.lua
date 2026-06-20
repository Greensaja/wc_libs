-- client/modules/progress.lua - wc_libs
-- Framework/resource-safe progress helper with a timer fallback.

WCLibProgress = {}

local activeProgress = {}

local function progressOwner()
  return GetInvokingResource() or GetCurrentResourceName()
end

local function trackProgress(handle, owner)
  if not owner or owner == GetCurrentResourceName() then return handle end
  activeProgress[owner] = activeProgress[owner] or {}
  activeProgress[owner][handle] = true
  return handle
end

local function untrackProgress(handle)
  if not handle or not handle.ownerResource then return end
  local bucket = activeProgress[handle.ownerResource]
  if bucket then
    bucket[handle] = nil
    if next(bucket) == nil then activeProgress[handle.ownerResource] = nil end
  end
end

AddEventHandler('onResourceStop', function(resourceName)
  local bucket = activeProgress[resourceName]
  if not bucket then return end
  for handle in pairs(bucket) do
    handle.canceled = true
    handle.skipCallback = true
    if type(handle.cancel) == 'function' then pcall(handle.cancel) end
    if type(handle.stop) == 'function' then pcall(handle.stop) end
  end
  activeProgress[resourceName] = nil
end)

--- Starts a progress bar when vorp_progressbar is available, otherwise runs a timed fallback.
-- Returns a handle with cancel()/stop() when possible.
-- @param label string
-- @param durationMs number
-- @param cb function|nil
-- @param style string|nil
-- @return table|nil
function WCLibProgress.Start(label, durationMs, cb, style)
  durationMs = tonumber(durationMs) or 0
  local owner = progressOwner()
  local handle = { canceled = false, ownerResource = owner }
  local function done()
    if not handle.canceled and not handle.skipCallback then
      if not (owner and owner ~= GetCurrentResourceName() and GetResourceState(owner) ~= 'started') then
        if cb then cb() end
      end
    end
    untrackProgress(handle)
  end

  local ok, progressbar = pcall(function()
    if GetResourceState('vorp_progressbar') ~= 'started' then return nil end
    return exports.vorp_progressbar:initiate()
  end)

  if ok and progressbar and progressbar.start then
    progressbar.start(label, durationMs, done, style or 'innercircle')
    handle.cancel = function()
      handle.canceled = true
      if type(progressbar.cancel) == 'function' then progressbar.cancel()
      elseif type(progressbar.stop) == 'function' then progressbar.stop() end
    end
    handle.stop = handle.cancel
    return trackProgress(handle, owner)
  end

  function handle.cancel() handle.canceled = true end
  function handle.stop() handle.canceled = true end

  CreateThread(function()
    local endTime = GetGameTimer() + durationMs
    while not handle.canceled and GetGameTimer() < endTime do Wait(100) end
    done()
  end)

  return trackProgress(handle, owner)
end
