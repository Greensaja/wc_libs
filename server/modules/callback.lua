-- server/modules/callback.lua — wc_libs
-- Public callback registration/triggering, normalized across VORP
-- and RSG's different callback systems.
--
-- All callback names registered through this module are namespaced
-- with a fixed 'wc_libs:' prefix to avoid colliding with any
-- resource's own callback names (locked design decision). Pass your
-- own name and it gets prefixed automatically — you don't need to
-- type the prefix yourself.

WCLibCallback = {}
WCLibCallback._activeAdapter = nil

local PREFIX = 'wc_libs:'

local function namespaced(name)
  if string.sub(name, 1, #PREFIX) == PREFIX then return name end
  return PREFIX .. name
end

--- Registers a server callback. Works the same way regardless of
-- framework. Call this on the server, then trigger it from the client
-- with WCLib.TriggerCallback using the unprefixed callback name.
--
-- IMPORTANT: VORP's promise system resolves only a SINGLE value.
-- Always call cb() with ONE argument. Use a table for multiple values:
--   cb({ job = 'sheriff', grade = 2 })   -- correct
--   cb('sheriff', 2)                     -- WRONG: grade is silently dropped
--
-- @param name string  callback name (will be auto-prefixed with 'wc_libs:')
-- @param handler function(source, cb, ...)
function WCLibCallback.RegisterCallback(name, handler)
  if not WCLibCallback._activeAdapter then
    print('[wc_libs] RegisterCallback called before a framework was detected.')
    return
  end
  WCLibCallback._activeAdapter.RegisterCallback(namespaced(name), handler)
end

--- Triggers a client callback from the server (server -> client ->
-- server round trip). Signature is normalized across VORP's
-- TriggerAsync and RSG's TriggerClientCallback.
-- @param name string  callback name (auto-prefixed)
-- @param source integer
-- @param cb function(result)
-- @param ... any  extra args passed to the client-side handler
function WCLibCallback.TriggerCallback(name, source, cb, ...)
  if not WCLibCallback._activeAdapter then
    print('[wc_libs] TriggerCallback called before a framework was detected.')
    return
  end
  WCLibCallback._activeAdapter.TriggerCallback(namespaced(name), source, cb, ...)
end
