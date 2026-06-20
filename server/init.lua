-- server/init.lua — wc_libs
-- Loads last on the server side (see fxmanifest.lua ordering).
-- Detects which framework is running, wires the matching adapter,
-- and assembles the final WCLib table that gets exported.

local function detectFramework()
  if WCLibConfig.ForceFramework == 'vorp' or WCLibConfig.ForceFramework == 'rsg' then
    return WCLibConfig.ForceFramework
  end

  local vorpUp = WCLibAdapterVORP.IsPresent()
  local rsgUp  = WCLibAdapterRSG.IsPresent()

  if vorpUp and rsgUp then
    print('[wc_libs] WARNING: both vorp_core and rsg-core are running. Defaulting to VORP — set WCLibConfig.ForceFramework to override.')
    return 'vorp'
  elseif vorpUp then
    return 'vorp'
  elseif rsgUp then
    return 'rsg'
  end

  print('[wc_libs] WARNING: no supported framework detected (vorp_core / rsg-core). Framework-dependent WCLib functions will not work until WCLibConfig.ForceFramework is set or a core resource is started.')
  return nil
end

local _framework = detectFramework()
local _adapter = (_framework == 'vorp' and WCLibAdapterVORP)
              or (_framework == 'rsg'  and WCLibAdapterRSG)
              or nil

-- Wire every module to the active adapter
WCLibPlayer._activeAdapter           = _adapter
WCLibMoney._activeAdapter            = _adapter
WCLibRevive._activeAdapter           = _adapter
WCLibCallback._activeAdapter         = _adapter
WCLibServerLifecycle._activeAdapter  = _adapter
WCLibSkill._activeAdapter            = _adapter

-- ─────────────────────────────────────────────────────────
-- Framework introspection
-- ─────────────────────────────────────────────────────────

WCLibFramework = {}

function WCLibFramework.Get()
  return _framework
end

function WCLibFramework.Is(name)
  return _framework == string.lower(tostring(name))
end

-- ─────────────────────────────────────────────────────────
-- Raw escape hatch
-- ─────────────────────────────────────────────────────────

WCLibRaw = {}

function WCLibRaw.VORP()
  if not WCLibAdapterVORP.IsPresent() then
    print('[wc_libs] WCLib.Raw.VORP() called but vorp_core is not running.')
    return nil
  end
  return WCLibAdapterVORP.Raw()
end

function WCLibRaw.RSG()
  if not WCLibAdapterRSG.IsPresent() then
    print('[wc_libs] WCLib.Raw.RSG() called but rsg-core is not running.')
    return nil
  end
  return WCLibAdapterRSG.Raw()
end

-- ─────────────────────────────────────────────────────────
-- Assemble the public WCLib table
-- ─────────────────────────────────────────────────────────

WCLib = {
  -- framework introspection
  Framework = WCLibFramework,
  Raw       = WCLibRaw,

  -- player / character / job
  GetPlayer    = WCLibPlayer.GetPlayer,
  GetCharacter = WCLibPlayer.GetCharacter,
  GetJob       = WCLibPlayer.GetJob,

  -- money
  GetMoney     = WCLibMoney.GetMoney,
  GetBankMoney = WCLibMoney.GetBankMoney,
  GetGold      = WCLibMoney.GetGold,
  AddMoney     = WCLibMoney.AddMoney,
  RemoveMoney  = WCLibMoney.RemoveMoney,

  -- revive / heal
  Revive = WCLibRevive.Revive,
  Heal   = WCLibRevive.Heal,

  -- callbacks
  RegisterCallback = WCLibCallback.RegisterCallback,
  TriggerCallback  = WCLibCallback.TriggerCallback,

  -- lifecycle
  OnPlayerLoaded = WCLibServerLifecycle.OnPlayerLoaded,
  OnPlayerUnload = WCLibServerLifecycle.OnPlayerUnload,
  OnJobUpdate    = WCLibServerLifecycle.OnJobUpdate,

  -- webhook
  SendWebhook  = WCLibWebhook.Send,
  FormatMoney  = WCLibWebhook.FormatMoney,

  -- nearby
  GetPlayersInRadius = WCLibNearby.GetPlayersInRadius,

  -- skills (VORP-only; warns + returns defaults on RSG)
  GetSkillInfo  = WCLibSkill.GetInfo,
  GiveSkillXP   = WCLibSkill.GiveXP,
  ApplySkillBonus = WCLibSkill.ApplyBonus,

  -- battlepass
  AddBattlepassXP          = WCLibBattlepass.AddXP,
  AddBattlepassXPForPlayer = WCLibBattlepass.AddXPForPlayer,

  -- version
  GetVersion = WCLib_GetVersion,
}

-- ─────────────────────────────────────────────────────────
-- Exports
-- ─────────────────────────────────────────────────────────

for fnName, fn in pairs(WCLib) do
  if type(fn) == 'function' then
    exports(fnName, fn)
  end
end

for fnName, fn in pairs(WCLibFramework) do
  if type(fn) == 'function' then
    exports('Framework_' .. fnName, fn)
  end
end

CreateThread(function()
  Wait(0)
  print(('[wc_libs] server ready — framework: %s — version: %s'):format(
    tostring(_framework or 'NONE DETECTED'), WCLib_GetVersion()))
end)
