-- client/modules/camera.lua — wc_lib
-- Scripted "dialogue camera" helper: a side-angle shot framing the
-- player and an NPC's head, the way cutscene-style conversations are
-- usually shot. Extracted from wc_encounter/client/utils.lua
-- (EnableDialogueCamera/DisableDialogueCamera) — useful well beyond
-- encounters, since any NPC-dialogue resource wants this exact shot.

WCLibCamera = {}

local _handle = nil

--- Activates a scripted camera framing the player + given NPC ped.
-- Re-entrant: calling this again while already active destroys the
-- previous cam first.
-- @param npcPed number  the NPC ped entity to frame
function WCLibCamera.EnableDialogueCamera(npcPed)
  if _handle then
    DestroyCam(_handle, false)
    _handle = nil
  end

  local npcPos    = GetEntityCoords(npcPed)
  local playerPos = GetEntityCoords(PlayerPedId())

  local headBone = GetEntityBoneIndexByName(npcPed, 'SKEL_Head')
  local headPos
  if headBone ~= -1 then
    headPos = GetWorldPositionOfEntityBone(npcPed, headBone)
  else
    headPos = vector3(npcPos.x, npcPos.y, npcPos.z + 0.65)
  end

  local dx  = npcPos.x - playerPos.x
  local dy  = npcPos.y - playerPos.y
  local len = math.sqrt(dx * dx + dy * dy)
  if len > 0 then dx = dx / len; dy = dy / len end

  local perpX = -dy * 0.6
  local perpY =  dx * 0.6

  local camX = playerPos.x - dx * 0.5 + perpX
  local camY = playerPos.y - dy * 0.5 + perpY
  local camZ = headPos.z - 0.15

  _handle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
  SetCamCoord(_handle, camX, camY, camZ)
  PointCamAtCoord(_handle, headPos.x, headPos.y, headPos.z)
  SetCamFov(_handle, 55.0)
  SetCamActiveWithInterp(_handle, GetRenderingCam(), 800, 1, 1)
  RenderScriptCams(true, true, 800, true, false, 0)
end

--- Deactivates and destroys the dialogue camera, blending back to the
-- gameplay cam.
function WCLibCamera.DisableDialogueCamera()
  if _handle then
    RenderScriptCams(false, true, 800, true, false, 0)
    Wait(850)
    DestroyCam(_handle, false)
    _handle = nil
  end
end

--- @return number|nil  the active dialogue cam handle, if any
function WCLibCamera.GetDialogueCameraHandle()
  return _handle
end
