-- client/modules/dialogue.lua — wc_libs
-- Generic NUI dialogue system: multi-step trust conversations and
-- simple accept/decline prompts. Extracted and generalized from
-- wc_encounter/client/client_events.lua.
--
-- Requires the NUI page at nui/dialogue/index.html (declared in fxmanifest).
-- All NUI message types are prefixed "wcdialogue:" to avoid collisions
-- with resource-level NUI messages.

WCLibDialogue = {}

-- ─────────────────────────────────────────────────────────
-- Internal state (one dialogue at a time — same constraint as wc_encounter)
-- ─────────────────────────────────────────────────────────

local _active = nil   -- { timerRunning, trust, currentOptions, stepDefs, finalTrust, acceptResult, ownerResource }

-- Push-to-talk bypass: mirrors vorp_progressbar's approach so voice chat
-- still works while the dialogue NUI has focus.
local _pttActive        = false
local _pttKeepEnabled   = false
local _pttControl       = `INPUT_PUSH_TO_TALK`

CreateThread(function()
  while true do
    local sleep = 1000
    if _pttActive then
      sleep = 0
      if SetNuiFocusKeepInput ~= nil and not _pttKeepEnabled then
        SetNuiFocusKeepInput(true)
        _pttKeepEnabled = true
      end
      DisableAllControlActions(0)
      EnableControlAction(0, _pttControl, true)
    else
      if SetNuiFocusKeepInput ~= nil and _pttKeepEnabled then
        SetNuiFocusKeepInput(false)
        _pttKeepEnabled = false
      end
    end
    Wait(sleep)
  end
end)

local function dialogueOwner(opts)
  opts = opts or {}
  return opts.ownerResource or GetInvokingResource() or GetCurrentResourceName()
end

local function ownerStopped(owner)
  return owner and owner ~= GetCurrentResourceName() and GetResourceState(owner) ~= 'started'
end

AddEventHandler('onResourceStop', function(resourceName)
  if _active and _active.ownerResource == resourceName then
    _active.timerRunning = false
    _active.ownerStopped = true
    _pttActive = false
    SendNUIMessage({ type = 'wcdialogue:closeDialogue' })
    SetNuiFocus(false, false)
    WCLibCamera.DisableDialogueCamera()
  end
end)

-- ─────────────────────────────────────────────────────────
-- NUI callbacks (registered once at load time)
-- ─────────────────────────────────────────────────────────

RegisterNUICallback('wcdialogue:selectOption', function(data, cb)
  cb('ok')
  if not _active then return end
  if not _active.currentOptions then return end

  local chosen = _active.currentOptions[(data.optionIndex or 0) + 1]
  if not chosen then return end

  _active.trust = math.max(0, math.min(100, (_active.trust or 50) + (chosen.trustChange or 0)))

  local nextOptions = nil
  local nextStep    = chosen.nextStep

  if nextStep and _active.stepDefs and _active.stepDefs[nextStep] then
    local sd = _active.stepDefs[nextStep]
    nextOptions = {}
    for i, o in ipairs(sd.options or {}) do
      nextOptions[i] = { text = o.text, index = i - 1 }
    end
    _active.currentOptions = sd.options
  else
    _active.timerRunning = false
    _active.finalTrust   = _active.trust
  end

  SendNUIMessage({
    type         = 'wcdialogue:updateDialogue',
    response     = chosen.response or '',
    mood         = chosen.mood or 'neutral',
    trust        = _active.trust,
    playerChoice = chosen.text,
    nextOptions  = nextOptions,
  })
end)

RegisterNUICallback('wcdialogue:acceptMission', function(data, cb)
  cb('ok')
  if _active then _active.acceptResult = data.accepted end
end)

RegisterNUICallback('wcdialogue:closeDialogue', function(_, cb)
  cb('ok')
  if _active then _active.timerRunning = false end
end)

-- ─────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────

local function _close()
  _pttActive = false
  SendNUIMessage({ type = 'wcdialogue:closeDialogue' })
  SetNuiFocus(false, false)
  WCLibCamera.DisableDialogueCamera()
  _active = nil
end

-- ─────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────

--- Runs a multi-step trust dialogue using the wc_libs NUI panel.
-- Returns "success" (trust ≥ 70), "partial" (trust ≥ 40), or "fail".
--
-- @param def table
--   def.header       string    panel title
--   def.npcName      string    NPC name shown in panel
--   def.trustLabel   string    label on trust bar (default "Trust")
--   def.intro        table     { text, mood }
--   def.steps        table     array: { options = { {text, nextStep, trustChange, mood, response}, ... } }
-- @param npcPed number
-- @param timeoutSecs number|nil  defaults to 60
-- @param opts table|nil
--   opts.skipFaceEachOther  boolean
--   opts.skipNpcGestures    boolean
--   opts.skipPlayerGestures boolean
-- @return string  "success" | "partial" | "fail"
function WCLibDialogue.Run(def, npcPed, timeoutSecs, opts)
  if not def then return 'fail' end
  opts = opts or {}
  local owner = dialogueOwner(opts)

  local timerLeft = timeoutSecs or 60
  local outcome   = nil

  local step1   = def.steps and def.steps[1]
  local options = step1 and step1.options or {}

  _active = {
    timerRunning   = true,
    trust          = def.startTrust or 50,
    currentOptions = options,
    stepDefs       = def.steps,
    ownerResource  = owner,
  }

  if not opts.skipFaceEachOther then WCLibEntity.FaceEachOther(npcPed) end
  WCLibCamera.EnableDialogueCamera(npcPed)
  Wait(400)

  local stopGestures = WCLibEmote.StartConversationGestures(npcPed, opts.skipNpcGestures, opts.skipPlayerGestures)

  local nuiOptions = {}
  for i, o in ipairs(options) do nuiOptions[i] = { text = o.text, index = i - 1 } end

  SendNUIMessage({
    type       = 'wcdialogue:openDialogue',
    header     = def.header     or 'Conversation',
    npcName    = def.npcName    or 'Stranger',
    trustLabel = def.trustLabel or 'Trust',
    trust      = _active.trust,
    intro      = def.intro and def.intro.text or '',
    mood       = def.intro and def.intro.mood or 'neutral',
    options    = nuiOptions,
    timeLeft   = timerLeft,
  })
  SetNuiFocus(true, true)
  _pttActive = true

  CreateThread(function()
    while _active and _active.timerRunning do
      Wait(1000)
      if ownerStopped(owner) then
        if _active then
          _active.timerRunning = false
          _active.ownerStopped = true
        end
        break
      end
      timerLeft = timerLeft - 1
      if _active then
        SendNUIMessage({ type = 'wcdialogue:timerUpdate', timeLeft = timerLeft })
      end
      if timerLeft <= 0 then
        if _active then
          _active.timerRunning = false
          outcome = 'timeout'
        end
        break
      end
    end
  end)

  while not outcome and (_active and _active.timerRunning) do
    if ownerStopped(owner) then
      _active.ownerStopped = true
      break
    end
    Wait(100)
  end

  local finalTrust = (_active and (_active.finalTrust or _active.trust)) or 50
  local stopped = _active and _active.ownerStopped

  stopGestures()
  _close()

  if stopped then return 'fail' end
  if outcome == 'timeout' then return 'fail' end
  if finalTrust >= 70 then return 'success'
  elseif finalTrust >= 40 then return 'partial'
  else return 'fail'
  end
end

--- Shows a simple accept / decline NUI panel. Returns true (accepted) or false.
--
-- @param def table
--   def.header   string
--   def.npcName  string
--   def.intro    table  { text, mood }
--   def.options  table  { accept = {text, response}, decline = {text, response} }
-- @param npcPed number
-- @param opts table|nil  same skip flags as Run()
-- @return boolean
function WCLibDialogue.RunAccept(def, npcPed, opts)
  if not def then return true end
  opts = opts or {}
  local owner = dialogueOwner(opts)

  local result = nil

  if not opts.skipFaceEachOther then WCLibEntity.FaceEachOther(npcPed) end
  WCLibCamera.EnableDialogueCamera(npcPed)
  Wait(400)

  local stopGestures = WCLibEmote.StartConversationGestures(npcPed, opts.skipNpcGestures, opts.skipPlayerGestures)

  _active = { timerRunning = true, acceptResult = nil, ownerResource = owner }

  SendNUIMessage({
    type    = 'wcdialogue:openAccept',
    header  = def.header  or 'Someone needs help!',
    npcName = def.npcName or 'Stranger',
    intro   = def.intro and def.intro.text or '',
    mood    = def.intro and def.intro.mood or 'neutral',
    accept  = def.options and def.options.accept  and def.options.accept.text  or 'Help them.',
    decline = def.options and def.options.decline and def.options.decline.text or 'Walk away.',
  })
  SetNuiFocus(true, true)
  _pttActive = true

  local deadline = GetGameTimer() + 30000
  while result == nil and GetGameTimer() < deadline do
    if ownerStopped(owner) then
      if _active then _active.ownerStopped = true end
      break
    end
    Wait(100)
    if _active and _active.acceptResult ~= nil then
      result = _active.acceptResult and 'accept' or 'decline'
    end
  end

  local stopped = _active and _active.ownerStopped

  stopGestures()
  _close()

  if stopped then return false end
  return result == 'accept'
end

--- Spawns a background thread that fires onIgnored() if the player
-- walks more than `distance` metres from npcPed while `guard.done` is false.
-- Pass the same guard table you use for your encounter so the thread
-- exits cleanly when the encounter ends.
--
-- @param guard table     must have a `done` field (set to true to end the watch)
-- @param npcPed number
-- @param distance number|nil  metres, defaults to 80
-- @param onIgnored function
function WCLibDialogue.WatchIgnore(guard, npcPed, distance, onIgnored)
  local dist = distance or 80.0
  CreateThread(function()
    while not guard.done do
      Wait(1000)
      if not DoesEntityExist(npcPed) then break end
      if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(npcPed)) > dist then
        guard.done = true
        if onIgnored then onIgnored() end
        break
      end
    end
  end)
end
