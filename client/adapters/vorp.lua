-- client/adapters/vorp.lua — wc_libs
-- VORP-specific implementations. Never call these directly from your
-- resources — go through the WCLib.* functions in client/modules/,
-- which pick the active adapter automatically.
--
-- Escape hatch: WCLib.Raw.VORP() returns the native Core object
-- directly, for anything this adapter doesn't cover yet.

WCLibAdapterVORP = {}

local _core = nil
local function core()
  if not _core then
    _core = exports.vorp_core:GetCore()
  end
  return _core
end

-- ─────────────────────────────────────────────────────────
-- Detection
-- ─────────────────────────────────────────────────────────

function WCLibAdapterVORP.IsPresent()
  return GetResourceState('vorp_core') == 'started'
end

-- ─────────────────────────────────────────────────────────
-- Raw passthrough
-- ─────────────────────────────────────────────────────────

function WCLibAdapterVORP.Raw()
  return core()
end

-- ─────────────────────────────────────────────────────────
-- Notify
-- ─────────────────────────────────────────────────────────
-- Full passthrough of VORP's client notify variants. `opts.variant`
-- selects which Core.Notify* function to call; unknown/omitted
-- variant falls back to NotifyAvanced (the agreed default).
--
-- opts shape (fields used depend on variant):
--   { variant, title, subtitle, dict, icon, color, duration,
--     location, quality, showQuality, audioref, audioname,
--     second_description }

local function nz(v, d) if v == nil then return d end return v end

WCLibAdapterVORP.NotifyVariants = {
  left = function(o)
    core().NotifyLeft(o.title, o.subtitle, o.dict, o.icon, nz(o.duration, 4000), o.color)
  end,
  tip = function(o)
    core().NotifyTip(o.title, nz(o.duration, 4000))
  end,
  righttip = function(o)
    core().NotifyRightTip(o.title, nz(o.duration, 4000))
  end,
  objective = function(o)
    core().NotifyObjective(o.title, nz(o.duration, 4000))
  end,
  top = function(o)
    core().NotifyTop(o.title, o.location, nz(o.duration, 4000))
  end,
  simpletop = function(o)
    core().NotifySimpleTop(o.title, o.subtitle, nz(o.duration, 4000))
  end,
  avanced = function(o)
    core().NotifyAvanced(o.title, o.dict, o.icon, o.color, nz(o.duration, 4000), o.quality, o.showQuality)
  end,
  center = function(o)
    core().NotifyCenter(o.title, nz(o.duration, 4000))
  end,
  bottomright = function(o)
    core().NotifyBottomRight(o.title, nz(o.duration, 4000))
  end,
  fail = function(o)
    core().NotifyFail(o.title, o.subtitle, nz(o.duration, 4000))
  end,
  dead = function(o)
    core().NotifyDead(o.title, o.audioref, o.audioname, nz(o.duration, 4000))
  end,
  update = function(o)
    core().NotifyUpdate(o.title, o.subtitle, nz(o.duration, 4000))
  end,
  warning = function(o)
    core().NotifyWarning(o.title, o.subtitle, o.audioref, o.audioname, nz(o.duration, 4000))
  end,
  leftrank = function(o)
    core().NotifyLeftRank(o.title, o.subtitle, o.dict, o.icon, nz(o.duration, 4000), o.color)
  end,
  onesimpletop = function(o)
    core().NotifyOneSimpleTop(o.title, nz(o.duration, 4000))
  end,
  threesimpletop = function(o)
    core().NotifyThreeSimpleTop(o.title, o.description, o.second_description, nz(o.duration, 4000))
  end,
  leftinteractive = function(o)
    core().NotifyLeftInteractive(o.title, o.subtitle, o.dict, o.icon, nz(o.duration, -1), o.color)
  end,
}

function WCLibAdapterVORP.Notify(opts)
  opts = opts or {}
  local variant = opts.variant or 'avanced'
  local fn = WCLibAdapterVORP.NotifyVariants[variant]
  if not fn then
    print(("[wc_libs] Unknown VORP notify variant '%s', falling back to 'avanced'"):format(tostring(variant)))
    fn = WCLibAdapterVORP.NotifyVariants.avanced
  end
  fn(opts)
end

-- ─────────────────────────────────────────────────────────
function WCLibAdapterVORP.TriggerServerCallback(name, ...)
  return core().Callback.TriggerAwait(name, ...)
end
-- Lifecycle events
-- ─────────────────────────────────────────────────────────
-- VORP doesn't have a single clean "player loaded" client event the
-- way RSG does — the closest is the character-selected event. We
-- normalize on that here; client/init.lua wires this into
-- WCLib.OnPlayerLoaded(callback).

function WCLibAdapterVORP.RegisterOnPlayerLoaded(callback)
  RegisterNetEvent('vorp:SelectedCharacter')
  AddEventHandler('vorp:SelectedCharacter', function()
    callback()
  end)
end

function WCLibAdapterVORP.RegisterOnPlayerSpawned(callback)
  RegisterNetEvent('vorp_core:Client:OnPlayerSpawned')
  AddEventHandler('vorp_core:Client:OnPlayerSpawned', function()
    callback()
  end)
end
