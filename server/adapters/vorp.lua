-- server/adapters/vorp.lua — wc_lib
-- VORP-specific server implementations. Never call these directly —
-- go through WCLib.* functions in server/modules/.
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
-- Character / Player access
-- ─────────────────────────────────────────────────────────
-- Mirrors the getCharacter/resolveCharacter pattern duplicated across
-- wc_encounter/server/server.lua and webhook.lua — user.getUsedCharacter
-- can be either a table or a function depending on VORP version, so
-- this normalizes that once, here, instead of in every resource.

function WCLibAdapterVORP.GetCharacter(source)
  if not core() or not core().getUser then return nil end
  local user = core().getUser(source)
  if not user then return nil end
  local c = user.getUsedCharacter
  if type(c) == 'function' then
    local ok, out = pcall(c, user)
    if ok then c = out else c = nil end
  end
  return c
end

--- Returns a flat snapshot table of player data. Built fresh on every
-- call — never cache the result across waits/threads.
function WCLibAdapterVORP.GetPlayer(source)
  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return nil end

  return {
    source      = source,
    charid      = ch.charIdentifier or ch.identifier or ch.charid,
    firstname   = ch.firstname,
    lastname    = ch.lastname,
    job = {
      name  = ch.job,
      label = ch.jobLabel,
      grade = ch.jobGrade,
      -- VORP characters don't expose onduty directly on the character
      -- object in the docs we have — left nil here; resources that
      -- need duty status should check via their job resource directly
      -- or extend this in _custom/server.lua if your server tracks it.
      onduty = nil,
    },
    money = ch.money,
    gold  = ch.gold,
    rol   = ch.rol,
    xp    = ch.xp,
    age   = ch.age,
    gender = ch.gender,
    group = ch.group,
  }
end

function WCLibAdapterVORP.GetJob(source)
  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return nil end
  return {
    name   = ch.job,
    label  = ch.jobLabel,
    grade  = ch.jobGrade,
    onduty = nil, -- see note in GetPlayer above
  }
end

-- ─────────────────────────────────────────────────────────
-- Money
-- ─────────────────────────────────────────────────────────

function WCLibAdapterVORP.GetMoney(source)
  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return nil end
  return ch.money
end

function WCLibAdapterVORP.GetGold(source)
  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return nil end
  return ch.gold
end

function WCLibAdapterVORP.GetBankMoney(source)
  -- VORP core doesn't have a separate "bank" currency in the docs we
  -- have (money/gold/rol only) — warn + return nil rather than
  -- silently returning the wrong value.
  print('[wc_lib] GetBankMoney() called on VORP — VORP has no native bank currency (money/gold/rol only). Returning nil.')
  return nil
end

function WCLibAdapterVORP.AddMoney(source, amount, currencyType)
  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return false end
  ch.addCurrency(currencyType or WCLibConfig.Money.vorp.cash, amount)
  return true
end

function WCLibAdapterVORP.RemoveMoney(source, amount, currencyType)
  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return false end
  ch.removeCurrency(currencyType or WCLibConfig.Money.vorp.cash, amount)
  return true
end

-- ─────────────────────────────────────────────────────────
-- Revive / Heal
-- ─────────────────────────────────────────────────────────
-- VORP exposes these natively on Core.Player.

function WCLibAdapterVORP.Revive(source)
  if not core() or not core().Player or not core().Player.Revive then
    print('[wc_lib] VORP Core.Player.Revive not available — update vorp_core.')
    return false
  end
  core().Player.Revive(source)
  return true
end

function WCLibAdapterVORP.Heal(source)
  if not core() or not core().Player or not core().Player.Heal then
    print('[wc_lib] VORP Core.Player.Heal not available — update vorp_core.')
    return false
  end
  core().Player.Heal(source)
  return true
end

-- ─────────────────────────────────────────────────────────
-- Callbacks
-- ─────────────────────────────────────────────────────────

function WCLibAdapterVORP.RegisterCallback(name, handler)
  core().Callback.Register(name, handler)
end

function WCLibAdapterVORP.TriggerCallback(name, source, cb, ...)
  -- VORP's server->client TriggerAwait/TriggerAsync signature differs
  -- from RSG's TriggerClientCallback — see server/modules/callback.lua
  -- for how this gets normalized at the public-API level.
  core().Callback.TriggerAsync(name, source, cb, ...)
end

-- ─────────────────────────────────────────────────────────
-- Lifecycle events
-- ─────────────────────────────────────────────────────────

function WCLibAdapterVORP.RegisterOnPlayerLoaded(callback)
  AddEventHandler('vorp_core:Server:OnPlayerSpawned', function(source)
    callback(source)
  end)
end

function WCLibAdapterVORP.RegisterOnPlayerUnload(callback)
  -- VORP doesn't expose a single dedicated "unload" server event in
  -- the docs we have. Closest analog available is none confirmed —
  -- left as a documented gap rather than guessing at an event name.
  -- Extend in _custom/server.lua if your VORP build exposes one.
  print('[wc_lib] OnPlayerUnload has no confirmed VORP server event yet — callback registered but will not fire. See server/adapters/vorp.lua.')
end

function WCLibAdapterVORP.RegisterOnJobUpdate(callback)
  AddEventHandler('vorp:playerJobChange', function(source, newjob, oldjob)
    callback(source, newjob, oldjob)
  end)
end
