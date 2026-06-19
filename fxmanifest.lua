fx_version "adamant"
game "rdr3"

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name        'wc_lib'
description 'Green Studio — Shared Framework Bridge & Utility Library (VORP / RSG)'
author      'Green Studio'
version     '1.0.0'

-- ─────────────────────────────────────────────────────────
-- Version checker (mirrors VORP's vorp_checker convention)
-- Update wc_lib_github to point at your actual repo once created.
-- The version.file in that repo's root should contain a line like
-- <1.0.0> followed by changelog bullets — see version.lua for the
-- local-side check that reads this.
-- ─────────────────────────────────────────────────────────
wc_lib_checker 'yes'
wc_lib_name   '^5wc_lib ^4Version Check^3'
wc_lib_github 'https://github.com/REPLACE_ME/wc_lib'

shared_scripts {
  '@ox_lib/init.lua', -- safe to keep even if not installed; guarded with pcall where used
  'shared/config.lua',
  'version.lua',
}

client_scripts {
  'client/adapters/vorp.lua',
  'client/adapters/rsg.lua',
  'client/modules/model.lua',
  'client/modules/prompt.lua',
  'client/modules/blip.lua',
  'client/modules/gps.lua',
  'client/modules/camera.lua',
  'client/modules/entity.lua',
  'client/modules/distance.lua',
  'client/modules/notify.lua',
  'client/init.lua', -- must load last: wires adapters + modules into WCLib and registers exports
  '_custom/client.lua',
}

server_scripts {
  'server/adapters/vorp.lua',
  'server/adapters/rsg.lua',
  'server/modules/player.lua',
  'server/modules/money.lua',
  'server/modules/revive.lua',
  'server/modules/callback.lua',
  'server/modules/lifecycle.lua',
  'server/modules/webhook.lua',
  'server/init.lua', -- must load last
  '_custom/server.lua',
}

exports {
  'WCLib',
}
