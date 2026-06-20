-- server/modules/notify.lua - wc_libs
-- Server-to-client notify bridge. Reuses the client Notify implementation.

WCLibServerNotify = {}

--- Sends a framework notification to one player from the server.
-- @param source number
-- @param opts table
function WCLibServerNotify.Notify(source, opts)
  if not source then return false end
  TriggerClientEvent('wc_libs:client:notify', source, opts or {})
  return true
end

--- Sends a wc_notify message to one player from the server.
-- @param source number
-- @param msg string
-- @param level string|nil
-- @param placement string|nil
function WCLibServerNotify.WcNotify(source, msg, level, placement)
  if not source then return false end
  local event = (WCLibConfig and WCLibConfig.WcNotifyEvent) or 'wc_notify:send'
  TriggerClientEvent(event, source, {
    description = msg,
    placement = placement or 'middle-right',
  }, level or 'INFO')
  return true
end