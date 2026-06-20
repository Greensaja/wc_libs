fx_version "adamant"
game "rdr3"

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name        'wc_libs'
description 'Green Studio — Shared Framework Bridge & Utility Library (VORP / RSG)'
author      'Green Studio'
version     '1.0.0'

-- ─────────────────────────────────────────────────────────
-- Version checker (mirrors VORP's vorp_checker convention)
-- Update wc_libs_github to point at your actual repo once created.
-- The version.file in that repo's root should contain a line like
-- <1.0.0> followed by changelog bullets — see version.lua for the
-- local-side check that reads this.
-- ─────────────────────────────────────────────────────────
wc_libs_checker 'yes'
wc_libs_name   '^5wc_libs ^4Version Check^3'
wc_libs_github 'https://github.com/REPLACE_ME/wc_libs'

ui_page 'nui/dialogue/index.html'

files {
  'init.lua', -- bridge file: other resources include @wc_libs/init.lua to get the wc global
  'nui/dialogue/index.html',
  'nui/dialogue/style.css',
  'nui/dialogue/main.js',
  'nui/dialogue/RDR_Lino_Regular.ttf',
  'nui/image/toast.png',
  'nui/image/toast-rtl.png',
}

shared_scripts {
  -- ox_lib is optional. If it is installed and started before wc_libs,
  -- the RSG notify adapter will use lib.notify; otherwise it falls back
  -- to TriggerEvent('ox_lib:notify'). Do NOT add '@ox_lib/init.lua'
  -- here — FiveM crashes at resource-parse time if ox_lib is absent.
  'shared/config.lua',
  'version.lua',
}

client_scripts {
  'client/adapters/vorp.lua',
  'client/adapters/rsg.lua',
  'client/modules/model.lua',
  'client/modules/anim.lua',
  'client/modules/prompt.lua',
  'client/modules/blip.lua',
  'client/modules/gps.lua',
  'client/modules/camera.lua',
  'client/modules/entity.lua',
  'client/modules/distance.lua',
  'client/modules/notify.lua',
  'client/modules/progress.lua',
  'client/modules/callback.lua',
  'client/modules/flow.lua',
  'client/modules/emote.lua',
  'client/modules/zone.lua',
  'client/modules/wagon.lua',
  'client/modules/dialogue.lua',  -- must come after emote + camera
  'client/init.lua', -- must load last: wires adapters + modules into WCLib and registers exports
  '_custom/client.lua',
}

server_scripts {
  'server/adapters/vorp.lua',
  'server/adapters/rsg.lua',
  'server/modules/player.lua',
  'server/modules/money.lua',
  'server/modules/notify.lua',
  'server/modules/revive.lua',
  'server/modules/callback.lua',
  'server/modules/lifecycle.lua',
  'server/modules/webhook.lua',
  'server/modules/nearby.lua',
  'server/modules/skill.lua',
  'server/modules/battlepass.lua',
  'server/init.lua', -- must load last
  '_custom/server.lua',
}

-- Exports are registered at runtime in client/init.lua and server/init.lua
-- via individual exports(fnName, fn) calls for each WCLib function.
-- No manifest export block needed with fx_version "adamant".
