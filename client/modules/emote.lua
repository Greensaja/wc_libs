-- client/modules/emote.lua — wc_libs
-- Synchronized player+NPC emotes, looping conversation gestures,
-- and the money-handover reward animation.
-- Framework-agnostic — pure native wrappers extracted from wc_encounter.

WCLibEmote = {}

-- ─────────────────────────────────────────────────────────
-- Emote tables
-- ─────────────────────────────────────────────────────────
-- Resources can override or extend these before calling PlayShare/PlayFail.

WCLibEmote.ShareEmotes = {
  hug = {
    dict = 'script_mp@emotes@handshake@male@unarmed@upper',
    clipPlayer = 'action_alt2', clipNpc = 'action_alt2',
    offsetX = 0.1, offsetY = 1.40, offsetZ = 0.09, rotZ = 180.0,
  },
  handshake = {
    dict = 'mp_char_creation@tutorial@',
    clipPlayer = 'handshake_a', clipNpc = 'handshake_b',
    offsetX = 0.0, offsetY = 0.6, offsetZ = 0.0, rotZ = 180.0,
  },
  hat_tip = {
    dict = 'amb_rest@world_human_stand_impatient@male_a@idle_a',
    clipPlayer = 'idle_a', clipNpc = 'idle_a',
    offsetX = 0.0, offsetY = 1.2, offsetZ = 0.0, rotZ = 180.0,
  },
  wave_thanks = {
    dict = 'amb_rest@world_human_stand_impatient@male_a@idle_a',
    clipPlayer = 'idle_a', clipNpc = 'idle_a',
    offsetX = 0.0, offsetY = 1.2, offsetZ = 0.0, rotZ = 180.0,
  },
  cheer = {
    dict = 'amb_rest@world_human_stand_impatient@male_a@idle_a',
    clipPlayer = 'idle_a', clipNpc = 'idle_a',
    offsetX = 0.0, offsetY = 1.2, offsetZ = 0.0, rotZ = 180.0,
  },
  kneel_grateful = {
    dict = 'mech_busted@unapproved',
    clipPlayer = 'idle_b', clipNpc = 'idle_b',
    offsetX = 0.0, offsetY = 0.8, offsetZ = 0.0, rotZ = 0.0,
  },
}

WCLibEmote.FailEmotes = {
  slap               = { dict = 'rcmpaparazzo_3',                                       clip = 'idle_b'  },
  push               = { dict = 'rcmpaparazzo_3',                                       clip = 'idle_b'  },
  cry_run            = { run   = true },
  cry_turn           = { turn  = true },
  shoo               = { shoo  = true },
  head_shake         = { dict = 'amb_rest@world_human_stand_impatient@male_a@idle_a', clip = 'idle_a'  },
  frustrated_gesture = { dict = 'amb_rest@world_human_stand_impatient@male_a@idle_a', clip = 'idle_a'  },
  ignore             = { ignore = true },
}

-- ─────────────────────────────────────────────────────────
-- Conversation gesture system
-- ─────────────────────────────────────────────────────────

local SPEAKER_DICT  = 'ai_gestures@arthur@standing@speaker'
local SPEAKER_CLIPS = {
  'positive_appease_f_001',
  'positive_appease_f_002',
  'positive_appease_l_001',
  'positive_appease_l_002',
  'positive_appease_l_003',
  'positive_appease_r_001',
}

--- Starts looping idle-conversation gestures on the player and an NPC ped
-- while a dialogue is open. Returns a stopper function — call it when the
-- dialogue closes to stop the gesture loop.
--
-- @param npcPed number
-- @param skipNpc boolean|nil   true = NPC plays no gestures (e.g. lying on ground)
-- @param skipPlayer boolean|nil true = player plays no gestures (e.g. during a treatment anim)
-- @return function  call to stop the loop
function WCLibEmote.StartConversationGestures(npcPed, skipNpc, skipPlayer)
  local running = true
  if skipNpc and skipPlayer then return function() end end
  local player = PlayerPedId()
  CreateThread(function()
    if not WCLibModel.LoadAnimDictSafe(SPEAKER_DICT, 5000) then return end
    if not skipPlayer then SetCurrentPedWeapon(player, GetHashKey('WEAPON_UNARMED'), true) end
    while running do
      local count = math.random(1, 3)
      for _ = 1, count do
        if not running then break end
        local npcIdx    = math.random(#SPEAKER_CLIPS)
        local playerIdx = math.random(#SPEAKER_CLIPS - 1)
        if playerIdx >= npcIdx then playerIdx = playerIdx + 1 end
        if not skipNpc and DoesEntityExist(npcPed) then
          TaskPlayAnim(npcPed, SPEAKER_DICT, SPEAKER_CLIPS[npcIdx],    3.0, -3.0, 1800, 0, 0, false, false, false)
        end
        if not skipPlayer then
          TaskPlayAnim(player, SPEAKER_DICT, SPEAKER_CLIPS[playerIdx], 3.0, -3.0, 1800, 0, 0, false, false, false)
        end
        Wait(2000)
      end
      if running then Wait(math.random(400, 1200)) end
    end
  end)
  return function() running = false end
end

-- ─────────────────────────────────────────────────────────
-- Synchronized share emote (player + NPC together)
-- ─────────────────────────────────────────────────────────

--- Plays a synchronized emote between the player ped and an NPC.
-- @param emoteKey string  key into WCLibEmote.ShareEmotes (or a custom table)
-- @param npcPed number
-- @param customEmotes table|nil  optional table to look up instead of the default
function WCLibEmote.PlayShare(emoteKey, npcPed, customEmotes)
  local tbl   = customEmotes or WCLibEmote.ShareEmotes
  local emote = tbl[emoteKey]
  if not emote then return end
  if not WCLibModel.LoadAnimDictSafe(emote.dict, 5000) then return end

  local player = PlayerPedId()
  WCLibEntity.PlacePedRelative(npcPed, player, emote.offsetX, emote.offsetY, emote.offsetZ, emote.rotZ)
  Wait(200)

  SetCurrentPedWeapon(player, GetHashKey('WEAPON_UNARMED'), true)
  FreezeEntityPosition(npcPed, true)
  TaskPlayAnim(player, emote.dict, emote.clipPlayer, 8.0, -8.0, 3000, 1, 0, false, false, false)
  TaskPlayAnim(npcPed,  emote.dict, emote.clipNpc,   8.0, -8.0, 3000, 1, 0, false, false, false)
  Wait(3000)
  ClearPedTasks(player)
  FreezeEntityPosition(npcPed, false)
end

-- ─────────────────────────────────────────────────────────
-- Fail emote (NPC reacts negatively to player choice)
-- ─────────────────────────────────────────────────────────

--- Plays a fail-reaction emote on the NPC ped.
-- @param emoteKey string  key into WCLibEmote.FailEmotes (or a custom table)
-- @param npcPed number
-- @param customEmotes table|nil
function WCLibEmote.PlayFail(emoteKey, npcPed, customEmotes)
  local tbl   = customEmotes or WCLibEmote.FailEmotes
  local emote = tbl[emoteKey]
  if not emote then return end

  if emote.run then
    local pPos = GetEntityCoords(PlayerPedId())
    local ang  = math.random(0, 359) * (math.pi / 180.0)
    local tx   = pPos.x + math.cos(ang) * 80.0
    local ty   = pPos.y + math.sin(ang) * 80.0
    TaskGoToCoordAnyMeans(npcPed, tx, ty, WCLibEntity.SnapZ(tx, ty, pPos.z), 2.5, 0, false, 786603, 0.0)
    return
  end

  if emote.turn then
    SetEntityHeading(npcPed, GetEntityHeading(npcPed) + 180.0)
    Wait(300)
    if WCLibModel.LoadAnimDictSafe('mech_busted@unapproved') then
      TaskPlayAnim(npcPed, 'mech_busted@unapproved', 'idle_b', 8.0, -8.0, 3000, 1, 0, false, false, false)
    end
    Wait(2000)
    return
  end

  if emote.shoo or emote.ignore then
    if WCLibModel.LoadAnimDictSafe('amb_rest@world_human_stand_impatient@male_a@idle_a') then
      TaskPlayAnim(npcPed, 'amb_rest@world_human_stand_impatient@male_a@idle_a', 'idle_a', 8.0, -8.0, 3000, 1, 0, false, false, false)
    end
    Wait(2000)
    return
  end

  if emote.dict and emote.clip then
    if WCLibModel.LoadAnimDictSafe(emote.dict) then
      TaskPlayAnim(npcPed, emote.dict, emote.clip, 8.0, -8.0, 2500, 1, 0, false, false, false)
    end
    Wait(2500)
  end
end

-- ─────────────────────────────────────────────────────────
-- Reward handover animation
-- ─────────────────────────────────────────────────────────

--- Plays the money-handover reward animation: NPC hands bills to the player,
-- player takes them. Call this right before awarding money on the server.
-- Blocking — runs the full sequence (~8 seconds) before returning.
-- @param npcPed number
function WCLibEmote.PlayRewardHandover(npcPed)
  local player = PlayerPedId()

  WCLibEntity.FaceEachOther(npcPed)
  Wait(400)
  SetCurrentPedWeapon(player, GetHashKey('WEAPON_UNARMED'), true)

  WCLibEntity.PlacePedRelative(npcPed, player, 0.1, 0.90, 0.09, 180.0)
  TaskStandStill(npcPed, -1)
  TaskStandStill(player, -1)
  Wait(200)

  -- Spawn bill prop
  local billHash = GetHashKey('p_cs_dollarbill3stack01x')
  RequestModel(billHash)
  local t = 0
  while not HasModelLoaded(billHash) and t < 20 do Wait(50); t = t + 1 end

  local billProp = nil
  if HasModelLoaded(billHash) then
    billProp = CreateObject(billHash, 0.0, 0.0, 0.0, true, true, false)
    SetModelAsNoLongerNeeded(billHash)
  end

  if billProp and DoesEntityExist(billProp) then
    local civBone = GetEntityBoneIndexByName(npcPed, 'PH_R_Hand')
    AttachEntityToEntity(billProp, npcPed, civBone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
  end

  if WCLibModel.LoadAnimDictSafe('cnv_camp@handover@stage_03', 5000) then
    TaskPlayAnim(npcPed, 'cnv_camp@handover@stage_03', 'handover_player', 4.0, -4.0, 4000, 0, 0, false, false, false)
  end
  Wait(4000)

  TaskStandStill(npcPed, -1)

  if billProp and DoesEntityExist(billProp) then
    local playerBone = GetEntityBoneIndexByName(player, 'PH_R_Hand')
    AttachEntityToEntity(billProp, player, playerBone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
  end

  if WCLibModel.LoadAnimDictSafe('cnv_camp@handover@dark_alley_stab@handover', 5000) then
    TaskPlayAnim(player, 'cnv_camp@handover@dark_alley_stab@handover', 'take_offer_player', 4.0, -4.0, 4000, 0, 0, false, false, false)
  end
  Wait(4000)

  ClearPedTasksImmediately(player)
  if billProp and DoesEntityExist(billProp) then
    DetachEntity(billProp, true, true)
    DeleteObject(billProp)
  end
  ClearPedTasksImmediately(npcPed)
end
