-- client/modules/callback.lua - wc_libs
-- Client-side server callback trigger helper, normalized across VORP and RSG.

WCLibClientCallback = {}
WCLibClientCallback._activeAdapter = nil

local PREFIX = 'wc_libs:'

local function namespaced(name)
  if string.sub(name, 1, #PREFIX) == PREFIX then return name end
  return PREFIX .. name
end

--- Triggers a server callback and waits for the result.
-- Callback names are auto-prefixed with wc_libs: to match server RegisterCallback.
--
-- IMPORTANT: VORP's promise system resolves only a SINGLE value.
-- If the server callback calls cb() with multiple arguments, only the
-- first is returned. Always use a table on the server side:
--   server: cb({ job = 'sheriff', grade = 2 })
--   client: local r = WCLib.TriggerCallback('name'); r.job, r.grade
--
-- @param name string
-- @param ... any
-- @return any
function WCLibClientCallback.TriggerCallback(name, ...)
  if not WCLibClientCallback._activeAdapter then
    print('[wc_libs] client TriggerCallback called before framework adapter was initialized.')
    return nil
  end
  return WCLibClientCallback._activeAdapter.TriggerServerCallback(namespaced(name), ...)
end