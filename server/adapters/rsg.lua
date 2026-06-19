-- server/adapters/rsg.lua — wc_libs
-- RSG-specific server implementations. Written against RSG Core's
-- published docs (rsg.mintlify.app) — NOT yet verified against a
-- live RSG server. Test before trusting in production.
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
-- Player access
-- ─────────────────────────────────────────────────────────

local function getRSGPlayer(source)
  if not core() or not core().Functions or not core().Functions.GetPlayer then return nil end
  return core().Functions.GetPlayer(source)
end

-- RSG doesn't separate "user" from "character" the way VORP does, so
-- GetCharacter is just an alias to GetPlayer here for API symmetry —
-- resources calling WCLib.GetCharacter(source) get a consistent shape
-- back on either framework.
function WCLibAdapterRSG.GetCharacter(source)
  return getRSGPlayer(source)
end

function WCLibAdapterRSG.GetPlayer(source)
  local Player = getRSGPlayer(source)
  if not Player or not Player.PlayerData then return nil end
  local pd = Player.PlayerData

  return {
    source    = source,
    charid    = pd.citizenid,
    firstname = pd.charinfo and pd.charinfo.firstname,
    lastname  = pd.charinfo and pd.charinfo.lastname,
    job = {
      name   = pd.job and pd.job.name,
      label  = pd.job and pd.job.label,
      grade  = pd.job and pd.job.grade and pd.job.grade.level,
      onduty = pd.job and pd.job.onduty,
    },
    money = pd.money and pd.money[WCLibConfig.Money.rsg.cash],
    gold  = nil, -- see GetGold() — RSG has no native gold currency
    rol   = nil, -- VORP-only concept, always nil on RSG
    xp    = nil, -- not part of RSG's PlayerData in the docs we have
    age   = nil,
    gender = nil,
    group  = nil,
  }
end

function WCLibAdapterRSG.GetJob(source)
  local Player = getRSGPlayer(source)
  if not Player or not Player.PlayerData or not Player.PlayerData.job then return nil end
  local job = Player.PlayerData.job
  return {
    name   = job.name,
    label  = job.label,
    grade  = job.grade and job.grade.level,
    onduty = job.onduty,
  }
end

-- ─────────────────────────────────────────────────────────
-- Money
-- ─────────────────────────────────────────────────────────

function WCLibAdapterRSG.GetMoney(source)
  local Player = getRSGPlayer(source)
  if not Player or not Player.PlayerData or not Player.PlayerData.money then return nil end
  return Player.PlayerData.money[WCLibConfig.Money.rsg.cash]
end

function WCLibAdapterRSG.GetBankMoney(source)
  local Player = getRSGPlayer(source)
  if not Player or not Player.PlayerData or not Player.PlayerData.money then return nil end
  return Player.PlayerData.money[WCLibConfig.Money.rsg.bank]
end

function WCLibAdapterRSG.GetGold(source)
  local goldKey = WCLibConfig.Money.rsg.gold
  if not goldKey then
    print('[wc_libs] GetGold() called on RSG — no gold currency configured (WCLibConfig.Money.rsg.gold is nil). Returning 0.')
    return 0
  end
  local Player = getRSGPlayer(source)
  if not Player or not Player.PlayerData or not Player.PlayerData.money then return 0 end
  return Player.PlayerData.money[goldKey] or 0
end

function WCLibAdapterRSG.AddMoney(source, amount, moneyKey)
  local Player = getRSGPlayer(source)
  if not Player or not Player.Functions or not Player.Functions.AddMoney then return false end
  Player.Functions.AddMoney(moneyKey or WCLibConfig.Money.rsg.cash, amount)
  return true
end

function WCLibAdapterRSG.RemoveMoney(source, amount, moneyKey)
  local Player = getRSGPlayer(source)
  if not Player or not Player.Functions or not Player.Functions.RemoveMoney then return false end
  Player.Functions.RemoveMoney(moneyKey or WCLibConfig.Money.rsg.cash, amount)
  return true
end

-- ─────────────────────────────────────────────────────────
-- Revive / Heal
-- ─────────────────────────────────────────────────────────
-- RSG Core has no native Revive/Heal — normally owned by an
-- ambulance/EMS job resource. No-op + warn if it's missing, per the
-- design decision we locked in earlier.

function WCLibAdapterRSG.Revive(source)
  local res = WCLibConfig.RSGAmbulanceResource
  if GetResourceState(res) ~= 'started' then
    print(("[wc_libs] Revive() called on RSG but '%s' is not running — no-op."):format(res))
    return false
  end
  local ok = pcall(function()
    exports[res][WCLibConfig.RSGAmbulanceReviveExport](source)
  end)
  if not ok then
    print(("[wc_libs] Revive() failed calling exports['%s']:%s(source) — check WCLibConfig.RSGAmbulanceReviveExport matches your ambulance job's actual export name."):format(res, WCLibConfig.RSGAmbulanceReviveExport))
    return false
  end
  return true
end

function WCLibAdapterRSG.Heal(source)
  local res = WCLibConfig.RSGAmbulanceResource
  if GetResourceState(res) ~= 'started' then
    print(("[wc_libs] Heal() called on RSG but '%s' is not running — no-op."):format(res))
    return false
  end
  local ok = pcall(function()
    exports[res][WCLibConfig.RSGAmbulanceHealExport](source)
  end)
  if not ok then
    print(("[wc_libs] Heal() failed calling exports['%s']:%s(source) — check WCLibConfig.RSGAmbulanceHealExport matches your ambulance job's actual export name."):format(res, WCLibConfig.RSGAmbulanceHealExport))
    return false
  end
  return true
end

-- ─────────────────────────────────────────────────────────
-- Callbacks
-- ─────────────────────────────────────────────────────────

function WCLibAdapterRSG.RegisterCallback(name, handler)
  core().Functions.CreateCallback(name, handler)
end

function WCLibAdapterRSG.TriggerCallback(name, source, cb, ...)
  core().Functions.TriggerClientCallback(name, source, cb, ...)
end

-- ─────────────────────────────────────────────────────────
-- Lifecycle events
-- ─────────────────────────────────────────────────────────

function WCLibAdapterRSG.RegisterOnPlayerLoaded(callback)
  AddEventHandler('RSGCore:Server:OnPlayerLoaded', function(source)
    callback(source)
  end)
end

function WCLibAdapterRSG.RegisterOnPlayerUnload(callback)
  AddEventHandler('RSGCore:Server:OnPlayerUnload', function(source)
    callback(source)
  end)
end

function WCLibAdapterRSG.RegisterOnJobUpdate()
  -- RSGCore:Client:OnJobUpdate is a client-side event and will never
  -- fire here. No confirmed server-side equivalent exists in the docs.
  -- No-op + warn, same pattern as VORP's OnPlayerUnload gap.
  print('[wc_libs] RegisterOnJobUpdate() on RSG: no confirmed server-side job-update event. Callback will not fire. Use WCLib.Raw.RSG() and listen to RSGCore:Server:* events manually if your RSG version exposes one.')
end
