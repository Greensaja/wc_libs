-- client/modules/notify.lua — wc_libs
-- Public notify entry point. Dispatches to whichever framework
-- adapter is active (set by client/init.lua after detection).
--
-- Also provides:
--   WCLibNotify.TopNotify(title, msg)  — cinematic two-line top-of-screen
--                                        native notification (UiFeedPostTwoTextShard).
--   WCLibNotify.WcNotify(msg, level)   — wc_notify TriggerEvent wrapper.
--
-- This file intentionally contains NO framework-specific logic in Notify() —
-- all of that lives in client/adapters/vorp.lua and
-- client/adapters/rsg.lua. This just routes.

WCLibNotify = {}

-- Populated by client/init.lua once the active framework is known.
-- Either WCLibAdapterVORP or WCLibAdapterRSG.
WCLibNotify._activeAdapter = nil

-- ─────────────────────────────────────────────────────────
-- DataView — pure-Lua binary buffer used by TopNotify
-- ─────────────────────────────────────────────────────────

---@diagnostic disable-next-line: undefined-field
local _strblob = rawget(string, 'blob') or function(length)
  return string.rep('\0', math.max(41, length))
end

local DataView = {
  EndBig = '>', EndLittle = '<',
  Types = {
    Int8   = { code = 'i1', size = 1 }, Uint8   = { code = 'I1', size = 1 },
    Int16  = { code = 'i2', size = 2 }, Uint16  = { code = 'I2', size = 2 },
    Int32  = { code = 'i4', size = 4 }, Uint32  = { code = 'I4', size = 4 },
    Int64  = { code = 'i8', size = 8 }, Uint64  = { code = 'I8', size = 8 },
    LuaInt = { code = 'j',  size = 8 }, UluaInt = { code = 'J',  size = 8 },
    LuaNum = { code = 'n',  size = 8 }, Float32 = { code = 'f',  size = 4 },
    Float64 = { code = 'd', size = 8 }, String  = { code = 'z',  size = -1 },
  },
  FixedTypes = {
    String = { code = 'c', size = -1 },
    Int    = { code = 'i', size = -1 },
    Uint   = { code = 'I', size = -1 },
  },
}
DataView.__index = DataView

local function _ib(o, l, t)  return (t.size < 0) or (o + (t.size - 1) <= l) end
local function _ef(big)      return big and DataView.EndBig or DataView.EndLittle end
local _SetFixed

function DataView.ArrayBuffer(length)
  return setmetatable({ offset = 1, length = length, blob = _strblob(length) }, DataView)
end
function DataView.Wrap(blob)
  return setmetatable({ offset = 1, blob = blob, length = blob:len() }, DataView)
end
function DataView:Buffer()     return self.blob   end
function DataView:ByteLength() return self.length end

---@diagnostic disable: assign-type-mismatch
for label, dt in pairs(DataView.Types) do
  DataView['Get' .. label] = function(self, offset, endian)
    local o = self.offset + offset
    if _ib(o, self.length, dt) then
      local v = string.unpack(_ef(endian) .. dt.code, self.blob, o)
      return v
    end
    return nil
  end
  DataView['Set' .. label] = function(self, offset, value, endian)
    local o = self.offset + offset
    if _ib(o, self.length, dt) then
      return _SetFixed(self, o, value, _ef(endian) .. dt.code)
    end
    return self
  end
end
---@diagnostic enable: assign-type-mismatch

_SetFixed = function(self, offset, value, code)
  local fmt, vals = {}, {}
  if self.offset < offset then
    local size = offset - self.offset
    fmt[#fmt + 1]  = 'c' .. tostring(size)
    vals[#vals + 1] = self.blob:sub(self.offset, size)
  end
  fmt[#fmt + 1]  = code
  vals[#vals + 1] = value
  local ps = string.packsize(fmt[#fmt])
  if (offset + ps) <= self.length then
    local newoff    = offset + ps
    fmt[#fmt + 1]  = 'c' .. tostring(self.length - newoff + 1)
    vals[#vals + 1] = self.blob:sub(newoff, self.length)
  end
  self.blob   = string.pack(table.concat(fmt, ''), table.unpack(vals))
  self.length = self.blob:len()
  return self
end

local function _bigInt(text)
  local buf = DataView.ArrayBuffer(16)
  buf:SetInt64(0, text)
  return buf:GetInt64(0)
end

-- ─────────────────────────────────────────────────────────
-- TopNotify — cinematic two-line mission-header notification
-- ─────────────────────────────────────────────────────────

local _UiFeedPostTwoTextShard = function(...)
  return Citizen.InvokeNative(0xA6F4216AB10EB08E, ...)
end

--- Shows the native RedM top-of-screen two-line notification
-- (the cinematic mission header style, not a framework popup).
-- @param title string  large upper line — or the full message if `msg` is omitted
-- @param msg string|nil  smaller lower line
-- @param headerFallback string|nil  label shown in the upper slot when only `title` is passed (default "Wild County")
function WCLibNotify.TopNotify(title, msg, headerFallback)
  local hasMsg = msg and msg ~= ''
  local slot1  = hasMsg and title or (headerFallback or 'Wild County')
  local slot2  = hasMsg and msg   or title

  local structConfig = DataView.ArrayBuffer(8 * 7)
  structConfig:SetInt32(8 * 0, 5000)

  local structData = DataView.ArrayBuffer(8 * 7)
  structData:SetInt64(8 * 1, _bigInt(VarString(10, 'LITERAL_STRING', slot1)))
  structData:SetInt64(8 * 2, _bigInt(VarString(10, 'LITERAL_STRING', slot2 or ' ')))

  _UiFeedPostTwoTextShard(structConfig:Buffer(), structData:Buffer(), 1, 1)
end

-- ─────────────────────────────────────────────────────────
-- WcNotify — wc_notify resource TriggerEvent wrapper
-- ─────────────────────────────────────────────────────────

--- Fires the wc_notify:send event used by the wc_notify resource.
-- The event name is configurable via WCLibConfig.WcNotifyEvent.
-- No-ops gracefully if wc_notify is not installed (the event simply goes unheard).
-- @param msg string
-- @param level string|nil  "INFO" | "SUCCESS" | "WARNING" | "ERROR" — defaults to "INFO"
-- @param placement string|nil  e.g. "middle-right" — defaults to "middle-right"
function WCLibNotify.WcNotify(msg, level, placement)
  local event = (WCLibConfig and WCLibConfig.WcNotifyEvent) or 'wc_notify:send'
  TriggerEvent(event, {
    description = msg,
    placement   = placement or 'middle-right',
  }, level or 'INFO')
end

-- ─────────────────────────────────────────────────────────
-- Framework notify (original)
-- ─────────────────────────────────────────────────────────

--- Sends a notification using the active framework's notify system.
--
-- On VORP: routes to one of Core's 17 Notify* variants. Pass
-- opts.variant to pick one explicitly (e.g. 'righttip', 'fail',
-- 'dead'); omit it and it defaults to 'avanced' (NotifyAvanced),
-- matching wc_encounter's existing money/reward notification style.
--
-- On RSG: there's no native variant system (RSG Core delegates to
-- ox_lib), so every variant collapses to a best-fit lib.notify call.
-- Visual fidelity is intentionally lower here — VORP is the richer
-- "main" experience this lib is built around.
--
-- @param opts table  { variant, title, subtitle, dict, icon, color,
--                       duration, location, quality, showQuality,
--                       audioref, audioname, second_description }
function WCLibNotify.Notify(opts)
  if not WCLibNotify._activeAdapter then
    print('[wc_libs] Notify called before framework adapter was initialized.')
    return
  end
  WCLibNotify._activeAdapter.Notify(opts or {})
end

RegisterNetEvent('wc_libs:client:notify')
AddEventHandler('wc_libs:client:notify', function(opts)
  WCLibNotify.Notify(opts or {})
end)