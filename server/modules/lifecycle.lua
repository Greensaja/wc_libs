-- server/modules/lifecycle.lua — wc_libs
-- Public lifecycle event registration, normalized across frameworks.
-- One event name per lifecycle moment — resources never need an
-- if/else framework check for "when did this player load in."

WCLibServerLifecycle = {}
WCLibServerLifecycle._activeAdapter = nil

--- Fires when a player finishes loading into the server (after
-- character selection on VORP, after RSGCore:Server:OnPlayerLoaded
-- on RSG).
-- @param callback function(source)
function WCLibServerLifecycle.OnPlayerLoaded(callback)
  if not WCLibServerLifecycle._activeAdapter then
    print('[wc_libs] OnPlayerLoaded registered before a framework was detected.')
    return
  end
  WCLibServerLifecycle._activeAdapter.RegisterOnPlayerLoaded(callback)
end

--- Fires when a player logs out / returns to character select.
-- See server/adapters/vorp.lua for a known gap: VORP has no
-- confirmed dedicated server-side "unload" event in the docs we
-- have, so this currently only reliably fires on RSG. Flagged
-- clearly rather than silently no-op'd.
-- @param callback function(source)
function WCLibServerLifecycle.OnPlayerUnload(callback)
  if not WCLibServerLifecycle._activeAdapter then
    print('[wc_libs] OnPlayerUnload registered before a framework was detected.')
    return
  end
  WCLibServerLifecycle._activeAdapter.RegisterOnPlayerUnload(callback)
end

--- Fires when a player's job changes.
-- @param callback function(source, newJob, oldJob)
function WCLibServerLifecycle.OnJobUpdate(callback)
  if not WCLibServerLifecycle._activeAdapter then
    print('[wc_libs] OnJobUpdate registered before a framework was detected.')
    return
  end
  WCLibServerLifecycle._activeAdapter.RegisterOnJobUpdate(callback)
end
