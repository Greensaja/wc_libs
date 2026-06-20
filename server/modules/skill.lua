-- server/modules/skill.lua — wc_libs
-- VORP skill helpers: read levels/XP and award XP.
-- RSG has no equivalent skill system — calls on RSG log a warning
-- and return safe defaults rather than crashing.

WCLibSkill = {}

WCLibSkill._activeAdapter = nil

-- ─────────────────────────────────────────────────────────
-- GetInfo
-- ─────────────────────────────────────────────────────────

--- Returns current level and XP for a skill on the player's active character.
-- @param source number
-- @param skillName string  e.g. 'hunting', 'fishing'
-- @return table|nil  { level = number, xp = number } or nil if unavailable
function WCLibSkill.GetInfo(source, skillName)
  if WCLibSkill._activeAdapter ~= WCLibAdapterVORP then
    print('[wc_libs] WCLibSkill.GetInfo() is VORP-only — RSG has no skill system.')
    return { level = 0, xp = 0 }
  end

  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return nil end

  local skills = ch.skills
  if not skills or not skills[skillName] then return nil end

  return {
    level = skills[skillName].Level or 0,
    xp    = skills[skillName].Exp   or 0,
  }
end

-- ─────────────────────────────────────────────────────────
-- GiveXP
-- ─────────────────────────────────────────────────────────

--- Awards XP to a skill on the player's active character.
-- @param source number
-- @param skillName string
-- @param amount number
-- @return boolean  true if XP was granted, false otherwise
function WCLibSkill.GiveXP(source, skillName, amount)
  if WCLibSkill._activeAdapter ~= WCLibAdapterVORP then
    print('[wc_libs] WCLibSkill.GiveXP() is VORP-only — RSG has no skill system.')
    return false
  end

  local ch = WCLibAdapterVORP.GetCharacter(source)
  if not ch then return false end

  local ok, err = pcall(function()
    ch.setSkills(skillName, amount)
  end)

  if not ok then
    print('[wc_libs] WCLibSkill.GiveXP() error: ' .. tostring(err))
    return false
  end

  return true
end

-- ─────────────────────────────────────────────────────────
-- ApplyBonus
-- ─────────────────────────────────────────────────────────

--- Awards XP to a skill and fires a wc_notify to the player.
-- Convenience wrapper used by the encounter reward flow.
-- @param source number
-- @param skillName string
-- @param amount number
-- @param notifyMsg string|nil  notification text (omit to skip notify)
function WCLibSkill.ApplyBonus(source, skillName, amount, notifyMsg)
  local ok = WCLibSkill.GiveXP(source, skillName, amount)
  if ok and notifyMsg then
    local event = (WCLibConfig and WCLibConfig.WcNotifyEvent) or 'wc_notify:send'
    TriggerClientEvent(event, source, {
      description = notifyMsg,
      placement   = 'middle-right',
    }, 'SUCCESS')
  end
  return ok
end
