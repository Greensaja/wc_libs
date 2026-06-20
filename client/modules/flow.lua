-- client/modules/flow.lua - wc_libs
-- Small reusable client-flow helpers: cleanup bags, proximity watchers,
-- prompt watchers, and mission marker handles.

WCLibFlow = {}

local activeWatchers = {}

local function watcherOwner(opts)
  opts = opts or {}
  return opts.ownerResource or GetInvokingResource() or GetCurrentResourceName()
end

local function trackWatcher(handle, owner)
  if not owner or owner == GetCurrentResourceName() then return handle end
  activeWatchers[owner] = activeWatchers[owner] or {}
  activeWatchers[owner][handle] = true
  return handle
end

local function untrackWatcher(handle)
  if not handle or not handle.ownerResource then return end
  local bucket = activeWatchers[handle.ownerResource]
  if bucket then
    bucket[handle] = nil
    if next(bucket) == nil then activeWatchers[handle.ownerResource] = nil end
  end
end

AddEventHandler('onResourceStop', function(resourceName)
  local bucket = activeWatchers[resourceName]
  if not bucket then return end
  for handle in pairs(bucket) do
    handle.canceled = true
    handle.reason = 'owner_stopped'
    handle.skipCallbacks = true
  end
  activeWatchers[resourceName] = nil
end)

local function existsEntity(entity)
  return entity and entity ~= 0 and DoesEntityExist(entity)
end

local function getCoords(target)
  if not target then return nil end
  if type(target) == 'vector3' then return target end
  if type(target) == 'table' and target.x and target.y and target.z then
    return vector3(target.x + 0.0, target.y + 0.0, target.z + 0.0)
  end
  if existsEntity(target) then return GetEntityCoords(target) end
  return nil
end

local function shouldStop(opts)
  if not opts then return false end
  if opts.ownerResource and GetResourceState(opts.ownerResource) ~= 'started' then return true end
  if opts.guard and opts.guard() == false then return true end
  if opts.cancelWhenPlayerDead and IsEntityDead(PlayerPedId()) then return true end
  return false
end

local function removeObject(obj)
  if existsEntity(obj) then
    DetachEntity(obj, false, false)
    SetEntityAsMissionEntity(obj, false, true)
    DeleteEntity(obj)
  end
end

local function safeCall(fn, ...)
  if type(fn) ~= 'function' then return false end
  local ok, err = pcall(fn, ...)
  if not ok then
    print(('[wc_libs] cleanup warning: %s'):format(tostring(err)))
  end
  return ok
end

function WCLibFlow.CreateCleanupBag()
  local bag = {
    peds = {},
    vehicles = {},
    objects = {},
    prompts = {},
    blips = {},
    customs = {},
    gps = false,
    cleaned = false,
  }

  function bag:AddPed(ped) if ped then self.peds[#self.peds + 1] = ped end return ped end
  function bag:AddVehicle(vehicle) if vehicle then self.vehicles[#self.vehicles + 1] = vehicle end return vehicle end
  function bag:AddObject(object) if object then self.objects[#self.objects + 1] = object end return object end
  function bag:AddPrompt(prompt) if prompt then self.prompts[#self.prompts + 1] = prompt end return prompt end
  function bag:AddBlip(blip) if blip then self.blips[#self.blips + 1] = blip end return blip end
  function bag:AddGPS() self.gps = true return self end
  function bag:AddCustom(fn) if type(fn) == 'function' then self.customs[#self.customs + 1] = fn end return fn end

  function bag:Clean()
    if self.cleaned then return end
    self.cleaned = true

    for _, prompt in ipairs(self.prompts) do
      if WCLibPrompt then
        safeCall(WCLibPrompt.SetVisible, prompt, false)
        safeCall(WCLibPrompt.Delete, prompt)
      end
    end

    for _, blip in ipairs(self.blips) do
      safeCall(WCLibFlow.ClearMissionMarker, blip)
    end

    if self.gps and WCLibGPS then
      safeCall(WCLibGPS.ClearRoute)
    end

    for _, fn in ipairs(self.customs) do safeCall(fn) end
    for _, ped in ipairs(self.peds) do
      if WCLibEntity then safeCall(WCLibEntity.DeletePed, ped) else safeCall(removeObject, ped) end
    end
    for _, vehicle in ipairs(self.vehicles) do
      if WCLibEntity then safeCall(WCLibEntity.DeleteVehicle, vehicle) else safeCall(removeObject, vehicle) end
    end
    for _, object in ipairs(self.objects) do safeCall(removeObject, object) end
  end

  return bag
end

function WCLibFlow.CleanupEncounter(ev)
  local bag = WCLibFlow.CreateCleanupBag()
  if not ev then return bag end

  if ev.prompt then bag:AddPrompt(ev.prompt) end
  if ev.prompt2 then bag:AddPrompt(ev.prompt2) end
  if ev.blip then bag:AddBlip(ev.blip) end

  if ev.propBlips then
    for _, blip in pairs(ev.propBlips) do bag:AddBlip(blip) end
  end

  if ev.bearTrap then bag:AddObject(ev.bearTrap) end
  if ev.sackOnWagon then bag:AddObject(ev.sackOnWagon) end

  for _, ped in ipairs(ev.peds or {}) do bag:AddPed(ped) end
  for _, vehicle in ipairs(ev.vehicles or {}) do bag:AddVehicle(vehicle) end
  for _, object in ipairs(ev.objects or {}) do bag:AddObject(object) end

  bag:Clean()
  return bag
end

local function makeWatcher(predicate, onHit, opts)
  opts = opts or {}
  opts.ownerResource = watcherOwner(opts)
  local handle = { canceled = false, hit = false, reason = nil, ownerResource = opts.ownerResource }
  function handle:Cancel(reason)
    self.canceled = true
    self.reason = reason or 'canceled'
  end
  handle.cancel = function(reason) handle:Cancel(reason) end
  trackWatcher(handle, opts.ownerResource)

  CreateThread(function()
    local deadline = opts.timeoutMs and (GetGameTimer() + opts.timeoutMs) or nil
    local tick = opts.tickMs or 250

    while not handle.canceled do
      if shouldStop(opts) then handle:Cancel('stopped'); break end
      if deadline and GetGameTimer() > deadline then handle:Cancel('timeout'); break end

      if predicate() then
        handle.hit = true
        handle.reason = 'hit'
        if onHit and not handle.skipCallbacks then onHit(handle) end
        break
      end

      Wait(tick)
    end

    if handle.canceled and opts.onCancel and not handle.skipCallbacks then opts.onCancel(handle.reason, handle) end
    untrackWatcher(handle)
  end)

  return handle
end

function WCLibFlow.WatchPlayerNear(target, radius, onNear, opts)
  return makeWatcher(function()
    local coords = getCoords(target)
    return coords and (#(GetEntityCoords(PlayerPedId()) - coords) <= (radius or 3.0))
  end, onNear, opts)
end

function WCLibFlow.WatchPlayerAway(target, radius, onAway, opts)
  return makeWatcher(function()
    local coords = getCoords(target)
    return coords and (#(GetEntityCoords(PlayerPedId()) - coords) >= (radius or 20.0))
  end, onAway, opts)
end

function WCLibFlow.WatchPrompt(prompt, target, radius, onPressed, opts)
  opts = opts or {}
  opts.ownerResource = watcherOwner(opts)
  local inRange = false
  local handle = { canceled = false, pressed = false, reason = nil, ownerResource = opts.ownerResource }
  function handle:Cancel(reason)
    self.canceled = true
    self.reason = reason or 'canceled'
  end
  handle.cancel = function(reason) handle:Cancel(reason) end
  trackWatcher(handle, opts.ownerResource)

  CreateThread(function()
    local deadline = opts.timeoutMs and (GetGameTimer() + opts.timeoutMs) or nil
    local nearTick = opts.nearTickMs or 0
    local farTick = opts.farTickMs or opts.tickMs or 250

    while not handle.canceled do
      if shouldStop(opts) then handle:Cancel('stopped'); break end
      if deadline and GetGameTimer() > deadline then handle:Cancel('timeout'); break end

      local coords = getCoords(target)
      local near = coords and (#(GetEntityCoords(PlayerPedId()) - coords) <= (radius or 3.0))

      if near then
        if not inRange then
          inRange = true
          WCLibPrompt.SetVisible(prompt, true)
          if opts.onEnter and not handle.skipCallbacks then opts.onEnter(handle) end
        end

        if WCLibPrompt.IsCompleted(prompt) then
          handle.pressed = true
          handle.reason = 'pressed'
          WCLibPrompt.SetVisible(prompt, false)
          if onPressed and not handle.skipCallbacks then onPressed(handle) end
          break
        end

        Wait(nearTick)
      else
        if inRange then
          inRange = false
          WCLibPrompt.SetVisible(prompt, false)
          if opts.onLeave and not handle.skipCallbacks then opts.onLeave(handle) end
        end
        Wait(farTick)
      end
    end

    if opts.autoHide ~= false then WCLibPrompt.SetVisible(prompt, false) end
    if handle.canceled and opts.onCancel and not handle.skipCallbacks then opts.onCancel(handle.reason, handle) end
    untrackWatcher(handle)
  end)

  return handle
end

function WCLibFlow.CreateMissionMarker(x, y, z, label, opts)
  opts = opts or {}
  local marker = {
    x = x,
    y = y,
    z = z,
    label = label,
    blip = WCLibBlip.Create(x, y, z, label or opts.label or 'Marker', opts.spriteHash, opts.scale),
    hasRoute = opts.route == true,
  }

  if marker.hasRoute then
    WCLibGPS.SetRoute(x, y, z, opts.routeColor)
  end

  function marker:Clear()
    WCLibFlow.ClearMissionMarker(self)
  end

  return marker
end

function WCLibFlow.ClearMissionMarker(marker)
  if not marker then return end

  if type(marker) == 'table' then
    if marker.blip then WCLibBlip.Remove(marker.blip) end
    if marker.hasRoute then WCLibGPS.ClearRoute() end
    marker.blip = nil
    marker.hasRoute = false
    return
  end

  WCLibBlip.Remove(marker)
end
