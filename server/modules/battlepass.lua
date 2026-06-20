-- server/modules/battlepass.lua — wc_libs
-- Wrapper around exports.vlab_battlepass:AddExpToCharacter.
-- Guarded with pcall so a missing or restarted vlab_battlepass
-- never crashes the calling resource.

WCLibBattlepass = {}

--- Adds XP to a character's battlepass progress.
-- @param charIdentifier number|string  charIdentifier from the character object
-- @param xp number  XP amount to add
-- @return boolean  true if the call succeeded, false if vlab_battlepass was unavailable
function WCLibBattlepass.AddXP(charIdentifier, xp)
  if GetResourceState('vlab_battlepass') ~= 'started' then
    return false
  end

  local ok, err = pcall(function()
    exports.vlab_battlepass:AddExpToCharacter(charIdentifier, xp)
  end)

  if not ok then
    print('[wc_libs] WCLibBattlepass.AddXP() error: ' .. tostring(err))
    return false
  end

  return true
end

--- Convenience wrapper: resolves charIdentifier from a player source
-- and awards battlepass XP. Requires vorp_core or rsg-core to be running
-- (uses WCLibPlayer.GetCharacter).
-- @param source number
-- @param xp number
-- @return boolean
function WCLibBattlepass.AddXPForPlayer(source, xp)
  ---@diagnostic disable-next-line: undefined-global
  local ch = WCLibPlayer.GetCharacter(source)
  if not ch then
    print('[wc_libs] WCLibBattlepass.AddXPForPlayer() could not resolve character for source ' .. tostring(source))
    return false
  end

  local cid = ch.charIdentifier or ch.identifier or ch.charid
  if not cid then
    print('[wc_libs] WCLibBattlepass.AddXPForPlayer() charIdentifier is nil for source ' .. tostring(source))
    return false
  end

  return WCLibBattlepass.AddXP(cid, xp)
end
