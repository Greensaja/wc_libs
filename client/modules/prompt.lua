-- client/modules/prompt.lua — wc_libs
-- Native RedM UI prompt wrapper.
-- Extracted from wc_encounter/client/utils.lua. This is engine-level
-- (UiPrompt* natives), not framework-level — VORP/RSG don't matter
-- here, it works identically regardless of which core is running.

WCLibPrompt = {}

local function CV(p0, p1, t)
  return Citizen.InvokeNative(0xFA925AC00EB830B9, p0, p1, t, Citizen.ResultAsLong())
end

-- Default key: G (0x760A9C6F). Pass a different control hash as the
-- second argument if you need a different bound key.
local DEFAULT_CONTROL_ACTION = 0x760A9C6F

--- Creates a native UI prompt (the bottom-right "[G] Action Text" style).
-- @param text string  label shown next to the key
-- @param controlAction number|nil  control hash, defaults to G
-- @return number  the prompt handle
function WCLibPrompt.Create(text, controlAction)
  local p = UiPromptRegisterBegin()
  UiPromptSetControlAction(p, controlAction or DEFAULT_CONTROL_ACTION)
  UiPromptSetText(p, CV(10, 'LITERAL_STRING', text))
  UiPromptSetStandardMode(p, true)
  UiPromptSetEnabled(p, false)
  UiPromptSetVisible(p, false)
  UiPromptRegisterEnd(p)
  return p
end

--- Shows or hides a prompt (both enabled + visible toggle together).
-- @param prompt number
-- @param on boolean
function WCLibPrompt.SetVisible(prompt, on)
  if not prompt then return end
  UiPromptSetEnabled(prompt, on and true or false)
  UiPromptSetVisible(prompt, on and true or false)
end

--- @param prompt number
-- @return boolean  whether the player has completed the prompt's hold/press
function WCLibPrompt.IsCompleted(prompt)
  if not prompt then return false end
  return UiPromptHasStandardModeCompleted(prompt)
end

--- Safely deletes a prompt handle. Always call this once you're done
-- with a prompt, or it leaks for the rest of the session.
-- @param prompt number
function WCLibPrompt.Delete(prompt)
  if prompt and prompt ~= 0 then
    pcall(UiPromptDelete, prompt)
  end
end
