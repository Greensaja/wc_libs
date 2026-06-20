-- client/init.lua — wc_libs
-- Loads last on the client side (see fxmanifest.lua ordering).
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

-- Wire modules that need the active adapter
WCLibNotify._activeAdapter = _adapter
WCLibClientCallback._activeAdapter = _adapter

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
-- Lifecycle events (normalized)
-- ─────────────────────────────────────────────────────────

WCLibLifecycle = {}

--- Registers a callback that fires once the player has loaded into
-- the server, regardless of which framework is active. Internally
-- listens to vorp:SelectedCharacter on VORP or
-- RSGCore:Client:OnPlayerLoaded on RSG.
-- @param callback function
function WCLibLifecycle.OnPlayerLoaded(callback)
  if not _adapter then
    print('[wc_libs] OnPlayerLoaded registered before a framework was detected — callback will never fire.')
    return
  end
  _adapter.RegisterOnPlayerLoaded(callback)
end

--- Registers a callback for the player-spawned moment (useful when a
-- resource restarts mid-session and the "loaded" event won't fire
-- again). On RSG this is currently aliased to OnPlayerLoaded — see
-- client/adapters/rsg.lua for the caveat.
-- @param callback function
function WCLibLifecycle.OnPlayerSpawned(callback)
  if not _adapter then
    print('[wc_libs] OnPlayerSpawned registered before a framework was detected — callback will never fire.')
    return
  end
  _adapter.RegisterOnPlayerSpawned(callback)
end

-- ─────────────────────────────────────────────────────────
-- Assemble the public WCLib table
-- ─────────────────────────────────────────────────────────

WCLib = {
  -- framework introspection
  Framework = WCLibFramework,
  Raw       = WCLibRaw,

  -- lifecycle
  OnPlayerLoaded  = WCLibLifecycle.OnPlayerLoaded,
  OnPlayerSpawned = WCLibLifecycle.OnPlayerSpawned,

  -- notify
  Notify = WCLibNotify.Notify,
  StartProgress = WCLibProgress.Start,
  TriggerCallback = WCLibClientCallback.TriggerCallback,

  -- models / anims
  LoadModel        = WCLibModel.LoadModel,
  LoadAnyModel     = WCLibModel.LoadAnyModel,
  LoadAnimDictSafe = WCLibModel.LoadAnimDictSafe,

  -- prompts
  CreatePrompt    = WCLibPrompt.Create,
  SetPromptVisible = WCLibPrompt.SetVisible,
  IsPromptCompleted = WCLibPrompt.IsCompleted,
  DeletePrompt    = WCLibPrompt.Delete,

  -- blips
  CreateBlip = WCLibBlip.Create,
  RemoveBlip = WCLibBlip.Remove,

  -- gps
  SetGPSRoute   = WCLibGPS.SetRoute,
  ClearGPSRoute = WCLibGPS.ClearRoute,

  -- camera
  EnableDialogueCamera  = WCLibCamera.EnableDialogueCamera,
  DisableDialogueCamera = WCLibCamera.DisableDialogueCamera,
  GetDialogueCameraHandle = WCLibCamera.GetDialogueCameraHandle,

  -- entities
  SnapZ            = WCLibEntity.SnapZ,
  SpawnPed         = WCLibEntity.SpawnPed,
  SpawnHorse       = WCLibEntity.SpawnHorse,
  SpawnProp        = WCLibEntity.SpawnProp,
  DeletePed        = WCLibEntity.DeletePed,
  DeleteVehicle    = WCLibEntity.DeleteVehicle,
  FaceEachOther    = WCLibEntity.FaceEachOther,
  PlacePedRelative = WCLibEntity.PlacePedRelative,
  SetupCombatPed   = WCLibEntity.SetupCombatPed,
  ArmPed           = WCLibEntity.ArmPed,

  -- distance
  GetDistance        = WCLibDistance.GetDistance,
  SquaredDistance    = WCLibDistance.SquaredDistance,
  IsNearCoords       = WCLibDistance.IsNearCoords,
  IsPlayerNearCoords = WCLibDistance.IsPlayerNearCoords,

  -- notify (extended)
  TopNotify = WCLibNotify.TopNotify,
  WcNotify  = WCLibNotify.WcNotify,

  -- emotes
  ShareEmotes                = WCLibEmote.ShareEmotes,
  FailEmotes                 = WCLibEmote.FailEmotes,
  StartConversationGestures  = WCLibEmote.StartConversationGestures,
  PlayShareEmote             = WCLibEmote.PlayShare,
  PlayFailEmote              = WCLibEmote.PlayFail,
  PlayRewardHandover         = WCLibEmote.PlayRewardHandover,

  -- zones
  IsInsideZone       = WCLibZone.IsInside,
  IsPlayerInsideZone = WCLibZone.IsPlayerInside,

  -- wagons
  SpawnWagon      = WCLibWagon.Spawn,
  DeleteWagon     = WCLibWagon.Delete,
  RepairWagon     = WCLibWagon.Repair,
  FreezeWagon     = WCLibWagon.Freeze,
  GetWagonWheelPos = WCLibWagon.GetWheelPos,

  -- dialogue (NUI)
  RunDialogue  = WCLibDialogue.Run,
  RunAccept    = WCLibDialogue.RunAccept,
  WatchIgnore  = WCLibDialogue.WatchIgnore,

  -- version
  GetVersion = WCLib_GetVersion,
}

-- ─────────────────────────────────────────────────────────
-- Exports
-- ─────────────────────────────────────────────────────────
-- Other resources call this as: exports.wc_libs:GetMoney(source), etc.
-- We expose every WCLib function individually rather than one single
-- "GetTable" export, since per-function exports give better
-- autocomplete/intellisense in editors and match how vorp_core/
-- rsg-core resources are typically consumed.

for fnName, fn in pairs(WCLib) do
  if type(fn) == 'function' then
    exports(fnName, fn)
  end
end

-- Nested tables (Framework, Raw) need their members exported too,
-- since the loop above only catches top-level functions.
for fnName, fn in pairs(WCLibFramework) do
  if type(fn) == 'function' then
    exports('Framework_' .. fnName, fn)
  end
end

CreateThread(function()
  Wait(0)
  print(('[wc_libs] client ready — framework: %s — version: %s'):format(
    tostring(_framework or 'NONE DETECTED'), WCLib_GetVersion()))
end)
