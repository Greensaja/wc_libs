-- server/modules/money.lua — wc_libs
-- Public money access/mutation. Dispatches to the active adapter.
--
-- Reads (GetMoney/GetBankMoney/GetGold) and writes (AddMoney/
-- RemoveMoney) are kept as separate explicit functions rather than
-- one function with a currency-type parameter — keeps call sites
-- unambiguous (locked design decision).

WCLibMoney = {}
WCLibMoney._activeAdapter = nil

--- Cash balance only.
-- @param source integer
-- @return number|nil
function WCLibMoney.GetMoney(source)
  if not WCLibMoney._activeAdapter then return nil end
  return WCLibMoney._activeAdapter.GetMoney(source)
end

--- Bank balance. VORP has no native "bank" currency (money/gold/rol
-- only) — calling this on VORP warns to console and returns nil.
-- @param source integer
-- @return number|nil
function WCLibMoney.GetBankMoney(source)
  if not WCLibMoney._activeAdapter then return nil end
  return WCLibMoney._activeAdapter.GetBankMoney(source)
end

--- Gold balance. RSG has no native gold currency unless you've
-- configured WCLibConfig.Money.rsg.gold to point at a custom
-- money-type key — otherwise warns and returns 0 on RSG.
-- @param source integer
-- @return number
function WCLibMoney.GetGold(source)
  if not WCLibMoney._activeAdapter then return 0 end
  return WCLibMoney._activeAdapter.GetGold(source)
end

--- Adds cash (or a specific VORP currency index / RSG money key if
-- you pass currencyType explicitly).
-- @param source integer
-- @param amount number
-- @param currencyType number|string|nil  framework-specific override
-- @return boolean  success
function WCLibMoney.AddMoney(source, amount, currencyType)
  if not WCLibMoney._activeAdapter then return false end
  return WCLibMoney._activeAdapter.AddMoney(source, amount, currencyType)
end

--- Removes cash (or a specific currency type, see AddMoney).
-- @param source integer
-- @param amount number
-- @param currencyType number|string|nil
-- @return boolean  success
function WCLibMoney.RemoveMoney(source, amount, currencyType)
  if not WCLibMoney._activeAdapter then return false end
  return WCLibMoney._activeAdapter.RemoveMoney(source, amount, currencyType)
end
