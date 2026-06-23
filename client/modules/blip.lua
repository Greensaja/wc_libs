-- client/modules/blip.lua — wc_libs
-- Blip creation/removal helper.
-- Extracted from wc_encounter/client/utils.lua. Framework-agnostic —
-- raw RedM blip natives, wrapped behind named functions instead of
-- bare hex hashes so call sites stay readable.

WCLibBlip = {}

--- Creates a simple coord blip with a label.
-- @param x number
-- @param y number
-- @param z number
-- @param label string|nil  defaults to "Marker"
-- @param spriteHash number|nil  defaults to the blip dot sprite used
--        across wc_encounter (-570710357)
-- @param scale number|nil  defaults to 0.18
-- @return number  the blip handle
function WCLibBlip.Create(x, y, z, label, spriteHash, scale)
  local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z)
  SetBlipSprite(blip, spriteHash or -570710357, 1)
  SetBlipScale(blip, scale or 0.18)
  Citizen.InvokeNative(0x662D364ABF16DE2F, blip, 1)
  Citizen.InvokeNative(0x9CB1A1623062F402, blip,
    CreateVarString(10, 'LITERAL_STRING', label or 'Marker'))
  return blip
end

--- Removes a blip if it exists. Always safe to call, even on nil/0.
-- @param blip number
function WCLibBlip.Remove(blip)
  if blip and DoesBlipExist(blip) then
    RemoveBlip(blip)
  end
end

--- Creates a coord blip that tracks a moving entity every 100 ms.
-- The blip handle is identical to Create — pass it to Remove to stop tracking.
-- The background thread exits automatically when the blip or entity is gone.
-- @param entity number  ped/vehicle/object handle
-- @param label  string|nil
-- @return number|nil  blip handle, or nil if entity doesn't exist
function WCLibBlip.CreateEntityBlip(entity, label)
  if not entity or not DoesEntityExist(entity) then return nil end
  local pos  = GetEntityCoords(entity)
  local blip = WCLibBlip.Create(pos.x, pos.y, pos.z, label)
  if not blip then return nil end
  CreateThread(function()
    while DoesBlipExist(blip) and DoesEntityExist(entity) do
      Wait(100)
      local p = GetEntityCoords(entity)
      SetBlipCoords(blip, p.x, p.y, p.z)
    end
  end)
  return blip
end
