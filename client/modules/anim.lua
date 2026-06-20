-- client/modules/anim.lua — wc_libs
-- Animation and scenario playback helpers for RedM (RDR2).
-- Depends on WCLibModel.LoadAnimDictSafe (model.lua must load first).

WCLibAnim = {}

local BLEND_IN  = 8.0
local BLEND_OUT = -8.0

-- ─────────────────────────────────────────────────────────
-- Animations
-- ─────────────────────────────────────────────────────────

--- Load dict + play animation once. Returns true if anim started.
-- opts: blendIn, blendOut, duration (-1=full clip), flags, rate,
--       wait (bool — block until clip ends), waitTimeout (ms, default 10000),
--       loop (shorthand for flags=1), dictTimeout (ms, default 5000)
--
-- Common flags:
--   0  = play once and stop
--   1  = loop
--   2  = hold last frame
--   16 = allow player control during anim
--   48 = no player control + uninterruptible
function WCLibAnim.Play(ped, dict, clip, opts)
  if not DoesEntityExist(ped) then return false end
  opts = opts or {}
  if not WCLibModel.LoadAnimDictSafe(dict, opts.dictTimeout or 5000) then return false end

  local flags = opts.flags or (opts.loop and 1) or 0

  TaskPlayAnim(ped, dict, clip,
    opts.blendIn  or BLEND_IN,
    opts.blendOut or BLEND_OUT,
    opts.duration or -1,
    flags,
    opts.rate     or 1.0,
    opts.p8 == true,
    opts.p9 or 0,
    opts.p10 == true,
    opts.taskFilter or "",
    opts.p12 == true)

  if opts.wait then
    local deadline = GetGameTimer() + (opts.waitTimeout or 10000)
    Wait(0)
    while DoesEntityExist(ped) and IsEntityPlayingAnim(ped, dict, clip, 3) and GetGameTimer() < deadline do
      Wait(100)
    end
  end

  return true
end

--- Play a looping animation. Returns a stopper function.
-- Call the returned function to stop the loop cleanly.
function WCLibAnim.PlayLooped(ped, dict, clip, opts)
  opts = opts or {}
  opts.loop     = true
  opts.duration = -1
  WCLibAnim.Play(ped, dict, clip, opts)

  return function()
    if DoesEntityExist(ped) then
      StopAnimTask(ped, dict, clip, opts.blendOut or BLEND_OUT)
    end
  end
end

--- Play animation at a specific world position and rotation.
-- pos and rot are vector3 (or tables with .x .y .z fields).
-- opts: same as Play() minus wait.
function WCLibAnim.PlayAt(ped, dict, clip, pos, rot, opts)
  if not DoesEntityExist(ped) then return false end
  opts = opts or {}
  if not WCLibModel.LoadAnimDictSafe(dict, opts.dictTimeout or 5000) then return false end

  rot = rot or vector3(0.0, 0.0, 0.0)

  TaskPlayAnimAdvanced(ped, dict, clip,
    pos.x, pos.y, pos.z,
    rot.x, rot.y, rot.z,
    opts.blendIn  or BLEND_IN,
    opts.blendOut or BLEND_OUT,
    opts.duration or -1,
    opts.flags    or 0,
    opts.rate     or 1.0,
    0, 0)

  return true
end

--- Returns true if the ped is currently playing the given dict+clip.
function WCLibAnim.IsPlaying(ped, dict, clip)
  if not DoesEntityExist(ped) then return false end
  return IsEntityPlayingAnim(ped, dict, clip, 3)
end

--- Stop the current animation on a ped (smooth blend out).
function WCLibAnim.Stop(ped)
  if DoesEntityExist(ped) then
    ClearPedTasks(ped)
  end
end

--- Stop the current animation immediately (no blend).
function WCLibAnim.StopNow(ped)
  if DoesEntityExist(ped) then
    ClearPedTasksImmediately(ped)
  end
end

-- ─────────────────────────────────────────────────────────
-- Scenarios
-- ─────────────────────────────────────────────────────────

--- Play a scenario in place. Loops until stopped.
-- Returns a stopper function.
-- @param playEnterAnim boolean  play the entry animation (default false = snap instantly)
function WCLibAnim.PlayScenario(ped, scenario, opts)
  if not DoesEntityExist(ped) then return function() end end
  local playEnterAnim = false
  local duration = 0
  if type(opts) == 'table' then
    playEnterAnim = opts.playEnterAnim == true
    duration = opts.duration or 0
  else
    playEnterAnim = opts == true
  end
  TaskStartScenarioInPlace(ped, scenario, duration, playEnterAnim)
  return function()
    if DoesEntityExist(ped) then ClearPedTasks(ped) end
  end
end

--- Play a scenario at a specific world position.
-- Returns a stopper function.
-- opts: duration (-1 = indefinite), standing (bool, default true), playEnterAnim (bool, default false)
function WCLibAnim.PlayScenarioAt(ped, scenario, x, y, z, heading, opts)
  if not DoesEntityExist(ped) then return function() end end
  opts = opts or {}
  TaskStartScenarioAtPosition(ped, scenario,
    x, y, z,
    heading          or 0.0,
    opts.duration    or -1,
    opts.standing    ~= false,    -- default true
    opts.playEnterAnim == true)   -- default false
  return function()
    if DoesEntityExist(ped) then ClearPedTasks(ped) end
  end
end

--- Stop the current scenario on a ped.
function WCLibAnim.StopScenario(ped)
  if DoesEntityExist(ped) then
    ClearPedTasks(ped)
  end
end
