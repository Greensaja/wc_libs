-- server/modules/webhook.lua — wc_libs
-- Generalized version of wc_encounter/server/webhook.lua's pattern.
-- Framework-agnostic (uses WCLibPlayer.GetCharacter under the hood,
-- so it works the same on VORP or RSG).
--
-- server_scripts ONLY — never expose webhook URLs or this module to
-- the client. This was a real vulnerability caught and fixed in
-- wc_encounter; wc_libs bakes the rule in by construction (this file
-- is only ever loaded as a server_script in fxmanifest.lua).
--
-- Style preserved from the original: a single code-block embed body
-- built from aligned "Key : value" rows, action -> colour mapping,
-- Discord mention appended as the last line outside the code block,
-- Green Studio branding in the footer.

WCLibWebhook = {}

-- ─────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────

local function getDiscordId(source)
  for _, id in ipairs(GetPlayerIdentifiers(source) or {}) do
    local did = id:match('discord:(%d+)')
    if did then return did end
  end
  return nil
end

local function getCharIdLoose(ch)
  if not ch then return 0 end
  return ch.charIdentifier or ch.identifier or ch.charid or ch.citizenid or ch.id or 0
end

local function displayName(ch, fallback)
  if ch then
    local fn = ch.firstname or (ch.charinfo and ch.charinfo.firstname) or ''
    local ln = ch.lastname  or (ch.charinfo and ch.charinfo.lastname)  or ''
    local n  = (fn .. ' ' .. ln):gsub('^%s+', ''):gsub('%s+$', '')
    if #n > 0 then return n end
  end
  return fallback or 'Unknown'
end

local function dec2(v)
  local n = tonumber(v or 0) or 0
  return math.floor(n * 100 + 0.5) / 100
end

local function money(v)
  return ('$%.2f'):format(dec2(v))
end

local function row(k, v)
  if v == nil then return '' end
  return string.format('%-18s: %s\n', k, tostring(v))
end

--- Raw embed sender. Prefers VORP's Core.AddWebhook when available
-- (matches wc_encounter's existing preference), falls back to a
-- manual POST with a Green Studio branded payload otherwise.
local function sendRaw(source, url, title, description, color)
  if not url or url == '' then return end

  local username = GetPlayerName(source) or 'Unknown'

  if WCLibFramework.Is('vorp') then
    local Core = WCLibRaw.VORP()
    if Core and Core.AddWebhook then
      Core.AddWebhook(username, url, (title or 'wc_libs') .. '\n' .. (description or ''))
      return
    end
  end

  local payload = {
    username = WCLibConfig.Webhook.Branding,
    embeds = { {
      title       = title or 'wc_libs',
      description = description or '',
      color       = tonumber(color) or WCLibConfig.Webhook.DefaultColor,
      footer      = { text = WCLibConfig.Webhook.Branding .. ' • ' .. os.date('%Y-%m-%d %H:%M:%S') },
    } },
  }

  PerformHttpRequest(
    url,
    function(err)
      if err and err ~= 200 and err ~= 204 then
        print(('[wc_libs] Webhook error: %s'):format(tostring(err)))
      end
    end,
    'POST',
    json.encode(payload),
    { ['Content-Type'] = 'application/json' }
  )
end

-- ─────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────

--- Sends a Green Studio styled Discord embed for a player action.
--
-- @param source integer  the player this log entry is about
-- @param url string  the Discord webhook URL to POST to
-- @param resourceLabel string  shown as the embed title prefix, e.g.
--        "Encounter" — title becomes "<resourceLabel> • <Action>"
-- @param action string  short action key, e.g. "complete", "fail" —
--        title-cased automatically for display
-- @param fields table|nil  ARRAY of { key, value } pairs rendered as
--        aligned rows in the embed body, in the order given — e.g.
--        {{"Encounter", "Wagon Breakdown"}, {"Money Earned", 50}}
--        (a plain {key = value} table won't preserve row order in
--        Lua, so this takes an ordered array of pairs instead).
-- @param colorMap table|nil  optional { [action] = hexColor } override.
--        Falls back to WCLibConfig.Webhook.DefaultColor for any
--        action not present in the map.
function WCLibWebhook.Send(source, url, resourceLabel, action, fields, colorMap)
  fields = fields or {}
  colorMap = colorMap or {}
  action = tostring(action or ''):lower()

  if not url or url == '' then return end

  local ch      = WCLibPlayer.GetCharacter(source)
  local cid     = tostring(getCharIdLoose(ch))
  local name    = displayName(ch, GetPlayerName(source))
  local discord = getDiscordId(source)
  local ign     = GetPlayerName(source) or 'Unknown'
  local whenT, whenD = os.date('%H:%M:%S'), os.date('%Y-%m-%d')

  local color = colorMap[action] or WCLibConfig.Webhook.DefaultColor
  local actionTitleCase = action:gsub('^%l', string.upper)
  local title = (resourceLabel or 'wc_libs') .. ' • ' .. actionTitleCase

  local desc = '```'
    .. row('Player',       name)
    .. row('IGN',          ign)
    .. row('Character ID', cid)
    .. row('Action',       action)

  -- Caller-supplied fields, rendered in the exact order given
  for _, pair in ipairs(fields) do
    desc = desc .. row(pair[1], pair[2])
  end

  desc = desc
    .. row('Time', whenT .. '  ' .. whenD)
    .. '```'
    .. 'Discord: ' .. (discord and ('<@' .. discord .. '>') or 'N/A')

  sendRaw(source, url, title, desc, color)
end

-- Expose the money formatter — resources building their own `fields`
-- table often want consistent $X.XX formatting too.
WCLibWebhook.FormatMoney = money
