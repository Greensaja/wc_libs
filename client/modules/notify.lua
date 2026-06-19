-- client/modules/notify.lua — wc_libs
-- Public notify entry point. Dispatches to whichever framework
-- adapter is active (set by client/init.lua after detection).
--
-- This file intentionally contains NO framework-specific logic —
-- all of that lives in client/adapters/vorp.lua and
-- client/adapters/rsg.lua. This just routes.

WCLibNotify = {}

-- Populated by client/init.lua once the active framework is known.
-- Either WCLibAdapterVORP or WCLibAdapterRSG.
WCLibNotify._activeAdapter = nil

--- Sends a notification using the active framework's notify system.
--
-- On VORP: routes to one of Core's 17 Notify* variants. Pass
-- opts.variant to pick one explicitly (e.g. 'righttip', 'fail',
-- 'dead'); omit it and it defaults to 'avanced' (NotifyAvanced),
-- matching wc_encounter's existing money/reward notification style.
--
-- On RSG: there's no native variant system (RSG Core delegates to
-- ox_lib), so every variant collapses to a best-fit lib.notify call.
-- Visual fidelity is intentionally lower here — VORP is the richer
-- "main" experience this lib is built around.
--
-- @param opts table  { variant, title, subtitle, dict, icon, color,
--                       duration, location, quality, showQuality,
--                       audioref, audioname, second_description }
function WCLibNotify.Notify(opts)
  if not WCLibNotify._activeAdapter then
    print('[wc_libs] Notify called before framework adapter was initialized.')
    return
  end
  WCLibNotify._activeAdapter.Notify(opts or {})
end
