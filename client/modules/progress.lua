-- client/modules/progress.lua - wc_libs
-- Framework/resource-safe progress helper with a timer fallback.

WCLibProgress = {}

--- Starts a progress bar when vorp_progressbar is available, otherwise runs a timed fallback.
-- Returns a handle with cancel()/stop() when possible.
-- @param label string
-- @param durationMs number
-- @param cb function|nil
-- @param style string|nil
-- @return table|nil
function WCLibProgress.Start(label, durationMs, cb, style)
  durationMs = tonumber(durationMs) or 0
  local ok, progressbar = pcall(function()
    if GetResourceState('vorp_progressbar') ~= 'started' then return nil end
    return exports.vorp_progressbar:initiate()
  end)

  if ok and progressbar and progressbar.start then
    progressbar.start(label, durationMs, cb, style or 'innercircle')
    return progressbar
  end

  local handle = { canceled = false }
  function handle.cancel() handle.canceled = true end
  function handle.stop() handle.canceled = true end

  CreateThread(function()
    local endTime = GetGameTimer() + durationMs
    while not handle.canceled and GetGameTimer() < endTime do Wait(100) end
    if not handle.canceled and cb then cb() end
  end)

  return handle
end