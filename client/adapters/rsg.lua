-- client/adapters/rsg.lua — wc_libs
-- RSG-specific implementations. Written against RSG Core's published
-- docs (rsg.mintlify.app) — NOT yet verified against a live RSG
-- server. Test against a real RSG install before trusting in
-- production; flag/fix anything that doesn't match actual behaviour.
--
-- Escape hatch: WCLib.Raw.RSG() returns the native RSGCore object
-- directly, for anything this adapter doesn't cover yet.

WCLibAdapterRSG = {}

local _core = nil
local function core()
  if not _core then
    _core = exports['rsg-core']:GetCoreObject()
  end
  return _core
end

-- ─────────────────────────────────────────────────────────
-- Detection
-- ─────────────────────────────────────────────────────────

function WCLibAdapterRSG.IsPresent()
  return GetResourceState('rsg-core') == 'started'
end

-- ─────────────────────────────────────────────────────────
-- Raw passthrough
-- ─────────────────────────────────────────────────────────

function WCLibAdapterRSG.Raw()
  return core()
end

-- ─────────────────────────────────────────────────────────
-- Notify
-- ─────────────────────────────────────────────────────────
-- RSG Core has no native notify variants of its own — it delegates to
-- ox_lib's lib.notify (confirmed via RSG's own docs/examples, which
-- call 'ox_lib:notify' directly). So every VORP variant collapses
-- down to ox_lib's single notify with a best-fit `type`.
--
-- This means visual fidelity is lower on RSG than on VORP by design —
-- see the design discussion: VORP is the richer "main" experience,
-- RSG gets best-effort fallback rather than the other way around.

local VARIANT_TO_TYPE = {
  left            = 'inform',
  tip             = 'inform',
  righttip        = 'inform',
  objective       = 'inform',
  top             = 'inform',
  simpletop       = 'inform',
  avanced         = 'success',
  center          = 'inform',
  bottomright     = 'inform',
  fail            = 'error',
  dead            = 'error',
  update          = 'success',
  warning         = 'error',
  leftrank        = 'success',
  onesimpletop    = 'inform',
  threesimpletop  = 'inform',
  leftinteractive = 'inform',
}

function WCLibAdapterRSG.Notify(opts)
  opts = opts or {}
  local variant = opts.variant or 'avanced'
  local notifyType = VARIANT_TO_TYPE[variant] or 'inform'

  -- description: prefer subtitle, then second_description, then nothing
  local description = opts.subtitle or opts.second_description or nil

  local ok = pcall(function()
    if lib and lib.notify then
      lib.notify({
        title = opts.title,
        description = description,
        type = notifyType,
        duration = opts.duration or 4000,
      })
    else
      TriggerEvent('ox_lib:notify', {
        title = opts.title,
        description = description,
        type = notifyType,
        duration = opts.duration or 4000,
      })
    end
  end)

  if not ok then
    print(("[wc_libs] RSG notify failed — is ox_lib started? title=%s"):format(tostring(opts.title)))
  end
end

-- ─────────────────────────────────────────────────────────
-- Lifecycle events
-- ─────────────────────────────────────────────────────────

function WCLibAdapterRSG.RegisterOnPlayerLoaded(callback)
  RegisterNetEvent('RSGCore:Client:OnPlayerLoaded')
  AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    callback()
  end)
end

function WCLibAdapterRSG.RegisterOnPlayerSpawned(callback)
  -- RSG doesn't have a distinct "spawned" event separate from
  -- OnPlayerLoaded in the docs we have — alias to the same hook.
  WCLibAdapterRSG.RegisterOnPlayerLoaded(callback)
end
