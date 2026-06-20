-- client/modules/wagon.lua — wc_libs
-- Wagon (vehicle) spawn/delete/repair helpers and wheel-bone lookup.
-- Framework-agnostic — pure native wrappers.
-- Spawning pattern extracted from wc_encounter/client/wagon_breakdown.lua.

WCLibWagon = {}

-- ─────────────────────────────────────────────────────────
-- Spawn
-- ─────────────────────────────────────────────────────────

--- Spawns a wagon (vehicle) at world coords.
--
-- @param modelName string|number  model name or hash (e.g. "WAGON02X")
-- @param x number @param y number @param z number @param heading number|nil
-- @param opts table|nil
--   opts.broken      boolean  damage body/engine, undriveable, freeze, break front-left wheel
--   opts.isMission   boolean  mark as mission entity
--   opts.frozen      boolean  freeze position (independent of broken)
--   opts.timeoutMs   number   model load timeout, default 10000
-- @return number|nil  vehicle handle, or nil on failure
function WCLibWagon.Spawn(modelName, x, y, z, heading, opts)
  opts = opts or {}
  local h = type(modelName) == 'number' and modelName or GetHashKey(modelName)
  RequestModel(h)
  local deadline = GetGameTimer() + (opts.timeoutMs or 10000)
  while not HasModelLoaded(h) and GetGameTimer() < deadline do Wait(50) end
  if not HasModelLoaded(h) then
    SetModelAsNoLongerNeeded(h)
    return nil
  end

  local gz = WCLibEntity.SnapZ(x, y, z)
  local wagon = CreateVehicle(h, x, y, gz, heading or 0.0, true, false)
  local t = GetGameTimer() + 3000
  while not DoesEntityExist(wagon) and GetGameTimer() < t do Wait(50) end

  if not DoesEntityExist(wagon) then
    SetModelAsNoLongerNeeded(h)
    return nil
  end

  SetModelAsNoLongerNeeded(h)
  SetVehicleOnGroundProperly(wagon)

  if opts.isMission then
    SetEntityAsMissionEntity(wagon, true, true)
  end

  if opts.broken then
    SetVehicleBodyHealth(wagon, 0.0)
    SetVehicleEngineHealth(wagon, 0.0)
    SetVehicleUndriveable(wagon, true)
    SetVehicleEngineOn(wagon, false, true, false)
    FreezeEntityPosition(wagon, true)
    BreakOffVehicleWheel(wagon, 0, true, false, true, false)
  elseif opts.frozen then
    FreezeEntityPosition(wagon, true)
  end

  return wagon
end

-- ─────────────────────────────────────────────────────────
-- Delete
-- ─────────────────────────────────────────────────────────

--- Safely deletes a wagon vehicle.
-- @param wagon number
function WCLibWagon.Delete(wagon)
  if DoesEntityExist(wagon) then
    SetEntityAsMissionEntity(wagon, false, true)
    DeleteVehicle(wagon)
  end
end

-- ─────────────────────────────────────────────────────────
-- Repair
-- ─────────────────────────────────────────────────────────

--- Fully repairs a wagon: fixes damage, restores health, makes driveable.
-- Mirrors the repair sequence in wc_encounter/client/utils.lua.
-- @param wagon number
function WCLibWagon.Repair(wagon)
  if not DoesEntityExist(wagon) then return end
  FreezeEntityPosition(wagon, false)
  SetVehicleFixed(wagon)
  SetVehicleUndriveable(wagon, false)
  SetVehicleEngineOn(wagon, true, true, false)
  SetVehicleBodyHealth(wagon, 1000.0)
  SetVehicleEngineHealth(wagon, 1000.0)
  SetVehiclePetrolTankHealth(wagon, 1000.0)
  SetVehicleDirtLevel(wagon, 0.0)
  Citizen.InvokeNative(0x7263332501E07F52, wagon, false)  -- _SET_VEHICLE_DAMAGED
  Citizen.InvokeNative(0x8B9D6D4C, wagon, 0.0, 0.0, 0.0, 0.0, 0.0)  -- zero velocity
  Citizen.InvokeNative(0xBA8818212633500A, wagon, 6, 0)   -- clear damage flags
  SetVehicleUndriveable(wagon, false)
end

-- ─────────────────────────────────────────────────────────
-- Freeze
-- ─────────────────────────────────────────────────────────

--- Freezes or unfreezes a wagon's position.
-- @param wagon number
-- @param freeze boolean
function WCLibWagon.Freeze(wagon, freeze)
  if DoesEntityExist(wagon) then
    FreezeEntityPosition(wagon, freeze and true or false)
  end
end

-- ─────────────────────────────────────────────────────────
-- Wheel position lookup
-- ─────────────────────────────────────────────────────────
-- Bone names vary across wagon models; falls back to calculated offsets.

local _BONE_SETS = {
  lf = { 'wheel_lf', 'wheel_front_left',  'wheel_lf_side', 'wheel_lf_dummy' },
  lr = { 'wheel_lr', 'wheel_rear_left',   'wheel_lr_side', 'wheel_lr_dummy' },
  rr = { 'wheel_rr', 'wheel_rear_right',  'wheel_rr_side', 'wheel_rr_dummy' },
}

local _FALLBACK = {
  lf = {  1.5,  1.5 },
  lr = {  1.5, -1.5 },
  rr = { -1.5, -1.5 },
}

--- Returns the world position of a wheel bone on a wagon.
-- which: 'lf' (front-left), 'lr' (rear-left), 'rr' (rear-right), 'rf' (front-right, mirrored from lf)
-- @param wagon number
-- @param which string
-- @return vector3|nil
function WCLibWagon.GetWheelPos(wagon, which)
  if not DoesEntityExist(wagon) then return nil end

  local center  = GetEntityCoords(wagon)
  local heading = GetEntityHeading(wagon)
  local rad     = math.rad(heading)

  if which == 'rf' then
    -- Mirror the lf bone position across the wagon's forward axis
    local lfPos = nil
    for _, boneName in ipairs(_BONE_SETS.lf) do
      local idx = GetEntityBoneIndexByName(wagon, boneName)
      if idx ~= -1 and idx ~= 0 then
        local pos = GetWorldPositionOfEntityBone(wagon, idx)
        if pos and pos.x ~= 0.0 and pos.y ~= 0.0 then lfPos = pos; break end
      end
    end
    if not lfPos then
      lfPos = vector3(
        center.x + (1.5 * math.cos(rad) - 1.5 * math.sin(rad)),
        center.y + (1.5 * math.sin(rad) + 1.5 * math.cos(rad)),
        center.z)
    end
    local dx = lfPos.x - center.x
    local dy = lfPos.y - center.y
    local lx =  math.cos(-rad) * dx - math.sin(-rad) * dy
    local ly =  math.sin(-rad) * dx + math.cos(-rad) * dy
    lx = -lx
    return vector3(
      center.x + (math.cos(rad) * lx - math.sin(rad) * ly),
      center.y + (math.sin(rad) * lx + math.cos(rad) * ly),
      lfPos.z)
  end

  local list = _BONE_SETS[which]
  if list then
    for _, boneName in ipairs(list) do
      local idx = GetEntityBoneIndexByName(wagon, boneName)
      if idx ~= -1 and idx ~= 0 then
        local pos = GetWorldPositionOfEntityBone(wagon, idx)
        if pos and pos.x ~= 0.0 and pos.y ~= 0.0 then return pos end
      end
    end
  end

  local off = _FALLBACK[which] or { 0.0, 0.0 }
  return vector3(
    center.x + (off[1] * math.cos(rad) - off[2] * math.sin(rad)),
    center.y + (off[1] * math.sin(rad) + off[2] * math.cos(rad)),
    center.z)
end
