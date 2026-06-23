-- client/modules/entity.lua — wc_libs
-- Ped/horse/prop spawn helpers, safe deletion, and relative
-- positioning. Extracted from wc_encounter/client/utils.lua
-- (spawnOnePed, spawnEncHorse, spawnEncProp, deletePedSafe,
-- deleteVehicleSafe, faceEachOther, placePedRelative).
--
-- Framework-agnostic — pure native wrappers.

WCLibEntity = {}

local DEFAULT_HORSE_MODELS = { 'a_c_horse_americanstandardbred_black' }

--- Ground-snaps a Z coordinate via ray cast. Used by every spawn
-- helper below to avoid peds/props spawning underground or floating.
-- @return number  adjusted Z
function WCLibEntity.SnapZ(x, y, z)
  local ok, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 50.0, true)
  return (ok and gz and gz > -100.0) and gz + 0.05 or z
end

--- Spawns a single ped at the given coords/heading.
-- @param hash number  loaded model hash (see WCLibModel.LoadModel)
-- @param x number @param y number @param z number @param heading number|nil
-- @param isMission boolean|nil  marks as mission entity (won't be cleaned up by the engine)
-- @param invincible boolean|nil  sets invincible + blocks non-temp events
-- @return number|nil  the ped handle, or nil if spawn failed
function WCLibEntity.SpawnPed(hash, x, y, z, heading, isMission, invincible)
  local ped = CreatePed(hash, x, y, z - 1.0, heading or 0.0, true, true, false, false)
  local deadline = GetGameTimer() + 3000
  while not DoesEntityExist(ped) and GetGameTimer() < deadline do Wait(50) end
  if not DoesEntityExist(ped) then return nil end

  PlaceEntityOnGroundProperly(ped)
  Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- _SET_RANDOM_OUTFIT_VARIATION

  if isMission then SetEntityAsMissionEntity(ped, true, true) end
  if invincible then
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
  end

  SetModelAsNoLongerNeeded(hash)
  return ped
end

--- Spawns an ambient horse ped (not a rideable-vehicle horse — a ped
-- horse, for scenario/decoration use). Always mission-entity +
-- invincible by default since these are typically scene dressing.
-- @param x number @param y number @param z number @param heading number|nil
-- @param modelList table|nil  pool of horse model names to try
-- @return number|nil
function WCLibEntity.SpawnHorse(x, y, z, heading, modelList)
  local hash = WCLibModel.LoadAnyModel(modelList or DEFAULT_HORSE_MODELS)
  if not hash then return nil end

  local horse = CreatePed(hash, x, y, z - 0.95, heading or math.random(0, 359), true, true, true, true)
  local deadline = GetGameTimer() + 3000
  while not DoesEntityExist(horse) and GetGameTimer() < deadline do Wait(50) end
  if not DoesEntityExist(horse) then
    SetModelAsNoLongerNeeded(hash)
    return nil
  end

  Citizen.InvokeNative(0x283978A15512B2FE, horse, true) -- _SET_RANDOM_OUTFIT_VARIATION
  SetEntityAsMissionEntity(horse, true, true)
  PlaceEntityOnGroundProperly(horse)
  SetEntityInvincible(horse, true)
  SetBlockingOfNonTemporaryEvents(horse, true)
  Citizen.InvokeNative(0xD3A7B003ED343FD9, horse, 0x1EE21489, true, true, true) -- breed/variant init
  for i = 0, 22 do SetAttributePoints(horse, i, 9999) end
  SetModelAsNoLongerNeeded(hash)
  return horse
end

--- Spawns a frozen, no-collision prop at world coords (decoration —
-- not meant to be interacted with physically).
-- @param modelName string
-- @param x number @param y number @param z number @param heading number|nil
-- @return number|nil
function WCLibEntity.SpawnProp(modelName, x, y, z, heading)
  local h = GetHashKey(modelName)
  RequestModel(h)
  local t = 0
  while not HasModelLoaded(h) and t < 40 do Wait(50); t = t + 1 end
  if not HasModelLoaded(h) then
    SetModelAsNoLongerNeeded(h)
    return nil
  end

  local ok, gz = GetGroundZFor_3dCoord(x, y, z + 1.0, true)
  local obj = CreateObjectNoOffset(h, x, y, ok and gz or z, true, true, false)
  SetModelAsNoLongerNeeded(h)
  if not (obj and DoesEntityExist(obj)) then return nil end

  SetEntityCollision(obj, false, false)
  SetEntityCompletelyDisableCollision(obj, true)
  FreezeEntityPosition(obj, true)
  SetEntityAsMissionEntity(obj, true, true)
  if heading then SetEntityHeading(obj, heading) end
  return obj
end

--- Safely deletes a ped (unfreezes + unmarks mission entity first, to
-- avoid the engine refusing the delete).
-- @param ped number
function WCLibEntity.DeletePed(ped)
  if DoesEntityExist(ped) then
    FreezeEntityPosition(ped, false)
    SetEntityAsMissionEntity(ped, false, true)
    DeletePed(ped)
  end
end

--- Safely deletes a vehicle.
-- @param veh number
function WCLibEntity.DeleteVehicle(veh)
  if DoesEntityExist(veh) then
    SetEntityAsMissionEntity(veh, false, true)
    DeleteVehicle(veh)
  end
end

--- Turns the player ped and an NPC ped to directly face one another.
-- Standard "start a conversation" framing.
-- @param npcPed number
function WCLibEntity.FaceEachOther(npcPed)
  local playerPed = PlayerPedId()
  ClearPedTasks(npcPed)
  TaskTurnPedToFaceEntity(playerPed, npcPed,   1200)
  TaskTurnPedToFaceEntity(npcPed,   playerPed, 1200)
  Wait(1200)

  local npcPos    = GetEntityCoords(npcPed)
  local playerPos = GetEntityCoords(playerPed)
  local dx        = playerPos.x - npcPos.x
  local dy        = playerPos.y - npcPos.y
  local toPlayer  = (math.deg(math.atan(-dx, dy)) + 360) % 360

  SetEntityHeading(npcPed,   toPlayer)
  SetEntityHeading(playerPed, (toPlayer + 180.0) % 360)
end

--- Gives a weapon to a ped using the RedM GiveWeaponToPed_2 native.
-- @param ped number
-- @param weaponName string  e.g. 'WEAPON_CATTLEMAN_CARBINE'
-- @param ammoHash number    ammo type hash (GetHashKey('AMMO_...'))
-- @param ammoCount number|nil  default 30
function WCLibEntity.ArmPed(ped, weaponName, ammoHash, ammoCount)
  ---@diagnostic disable-next-line: undefined-global
  GiveWeaponToPed_2(ped, GetHashKey(weaponName), ammoCount or 30, true, true, 1, false, 0.5, 1.0, ammoHash, false, 0, false)
end

--- Configures combat behaviour on a ped.
-- All opts fields are optional.
-- @param ped number
-- @param opts table|nil
--   opts.health        number   max + current health (SetEntityMaxHealth + SetEntityHealth)
--   opts.accuracy      number   0-100, default engine value
--   opts.relationGroup string   group name passed through GetHashKey
--   opts.fightToDeath  boolean  combat attr 46 — ped never retreats
--   opts.canFlank      boolean  combat attr 52 — ped flanks its target
--   opts.wontFlee      boolean  combat attr 5 + FleeAttributes 0 — ped stays and fights
--   opts.range         number   SetPedCombatRange (default 2 = medium)
--   opts.movement      number   SetPedCombatMovement (default 3 = defensive)
--   opts.targetPed     number   ped to immediately task to combat
function WCLibEntity.SetupCombatPed(ped, opts)
  opts = opts or {}

  if opts.health then
    SetEntityMaxHealth(ped, opts.health)
    SetEntityHealth(ped, opts.health)
  end

  if opts.accuracy then
    SetPedAccuracy(ped, opts.accuracy)
  end

  if opts.relationGroup then
    SetPedRelationshipGroupHash(ped, GetHashKey(opts.relationGroup))
  end

  if opts.fightToDeath then SetPedCombatAttributes(ped, 46, true) end
  if opts.canFlank     then SetPedCombatAttributes(ped, 52, true) end
  if opts.wontFlee     then
    SetPedCombatAttributes(ped, 5, true)
    SetPedFleeAttributes(ped, 0, false)
  end

  SetPedCombatRange(ped, opts.range or 2)
  SetPedCombatMovement(ped, opts.movement or 3)

  if opts.targetPed then
    TaskCombatPed(ped, opts.targetPed, 0, 16)
  end
end

--- Sends an NPC walking toward a random point ~60 m away from the local player.
-- Used to dismiss NPCs after a conversation or event ends.
-- @param ped number
function WCLibEntity.NpcWalkAway(ped)
  if not DoesEntityExist(ped) then return end
  local pPos = GetEntityCoords(PlayerPedId())
  local ang  = math.random(0, 359) * (math.pi / 180.0)
  local tx   = pPos.x + math.cos(ang) * 60.0
  local ty   = pPos.y + math.sin(ang) * 60.0
  local tz   = WCLibEntity.SnapZ(tx, ty, pPos.z)
  TaskGoToCoordAnyMeans(ped, tx, ty, tz, 1.0, 0, false, 786603, 0.0)
end

--- Positions childPed relative to parentPed using a forward/right/up
-- offset (in metres) plus a heading delta. Used for things like
-- "place this NPC right in front of the player, facing them."
-- @param childPed number
-- @param parentPed number
-- @param offX number  right offset
-- @param offY number  forward offset
-- @param offZ number  up offset
-- @param rotZ number  heading delta applied on top of parent's heading
function WCLibEntity.PlacePedRelative(childPed, parentPed, offX, offY, offZ, rotZ)
  local wp = GetOffsetFromEntityInWorldCoords(parentPed, offX + 0.0, offY + 0.0, offZ + 0.0)
  local gz = WCLibEntity.SnapZ(wp.x, wp.y, wp.z)
  SetEntityCoords(childPed, wp.x, wp.y, gz, false, false, false, true)
  SetEntityHeading(childPed, GetEntityHeading(parentPed) + rotZ)
end
