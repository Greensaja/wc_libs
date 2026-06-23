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

--- Sends a VORP icon-badge popup to a player (the "+$50 / item received" style).
-- On RSG or if vorp_core is unavailable, falls back to WcNotify.
-- @param source   number
-- @param text     string   e.g. "+$50"
-- @param icon     string   item icon key e.g. 'itemtype_cash'
-- @param color    string|nil  VORP color constant e.g. 'COLOR_WHITE' (default)
-- @param duration number|nil  ms, default 3000
-- @param dict     string|nil  texture dict, default 'itemtype_textures'
function WCLibServerNotify.NotifyIcon(source, text, icon, color, duration, dict)
  if not source then return false end
  local ok = pcall(function()
    local core = exports.vorp_core:GetCore()
    if core and core.NotifyAvanced then
      core.NotifyAvanced(source, text,
        dict or 'itemtype_textures',
        icon or 'default',
        color or 'COLOR_WHITE',
        duration or 3000)
    end
  end)
  if not ok then
    WCLibServerNotify.WcNotify(source, text)
  end
  return true
end