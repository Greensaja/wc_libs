# wc_libs

Shared framework bridge & utility library for RedM. Write your resource once against `wc_libs`'s API — it calls whichever core framework is actually running underneath.

Built by **Green Studio** for **Wild County RP**.

## Why this exists

Most RedM resources are written hard against one framework's exports — `character.addCurrency(...)` on VORP, `Player.Functions.AddMoney(...)` on RSG. Switch frameworks, or support both at once, and every one of those calls has to be found and rewritten by hand.

`wc_libs` removes that step. Include the bridge file in your resource and call `wc:AddMoney(source, 50)` — `wc_libs` figures out which framework is running and dispatches accordingly.

```lua
-- the same call works on either framework:
wc:AddMoney(source, 50)
wc:Notify({ title = "+$50" })
```

📖 **Full documentation:** https://docs.greenystudio.site/

## Supported frameworks

| Framework | Status |
|---|---|
| **VORP Core** | Primary / production. Full feature fidelity — built and tested against real Wild County RP code. |
| **RSG Core** | Supported. Written against RSG's published docs, with best-effort fallback where RSG has no native equivalent (see *Known gaps* below). **Not yet verified against a live RSG server** — test before trusting in production. |

## Installation

1. Copy the `wc_libs` folder into your server's `resources` directory.
2. In `server.cfg`, `ensure` it **after** your core framework and **before** anything that depends on it:

```cfg
ensure vorp_core
ensure wc_libs
ensure wc_encounter
ensure wc_death
```

3. On start, check your console for:

```
[wc_libs] server ready — framework: vorp — version: 1.0.0
[wc_libs] client ready — framework: vorp — version: 1.0.0
```

If you see `NONE DETECTED`, your core framework either isn't installed or started after `wc_libs` — check your `ensure` order.

### Using wc_libs in your resource

Add the bridge file to your resource's `fxmanifest.lua`:

```lua
shared_scripts { '@wc_libs/init.lua' }
```

This gives every script in your resource a global `wc` proxy. Then call any function directly:

```lua
-- client
wc:Notify({ variant = 'avanced', title = '+$50', icon = 'itemtype_cash', color = 'COLOR_WHITE' })
wc:SpawnPed('mp_u_m_m_hunter_01', x, y, z, heading)

-- server
local player = wc:GetPlayer(source)
wc:AddMoney(source, 50)
wc:SendWebhook(source, WEBHOOK_URL, 'Encounter', 'complete', fields, colorMap)
```

`wc` is a live proxy — calls resolve at call time, so it works correctly on both client and server without any extra setup.

### Forcing the framework

Auto-detection covers almost every setup. Override it explicitly in `shared/config.lua` if you ever run both cores side by side during a migration:

```lua
WCLibConfig.ForceFramework = 'vorp' -- or 'rsg', or nil to auto-detect
```

## What's included

- **Player & character** — `GetPlayer`, `GetCharacter`, `GetJob`
- **Money** — `GetMoney`, `GetBankMoney`, `GetGold`, `AddMoney`, `RemoveMoney`
- **Revive & heal** — `Revive`, `Heal` (no-op + console warning on RSG if the ambulance job resource isn't running)
- **Notify** — all 17 VORP notify variants, `WcNotify`, and `WcTip` toast prompts
- **Progress** — `StartProgress` progressbar wrapper with timer fallback
- **Native prompts** — `CreatePrompt`, `SetPromptVisible`, `IsPromptCompleted`, `DeletePrompt`
- **Flow helpers** — `CreateCleanupBag`, `CleanupEncounter`, `WatchPrompt`, `WatchPlayerNear`, `WatchPlayerAway`, `CreateMissionMarker`
- **Peds, horses & props** — `SpawnPed`, `SpawnHorse`, `SpawnProp`, `DeletePed`, `DeleteVehicle`, `FaceEachOther`, `PlacePedRelative`
- **Distance & proximity** — `GetDistance`, `IsNearCoords`, `IsPlayerNearCoords`
- **Discord webhooks** — `SendWebhook`, Green Studio branded embeds, `server_scripts`-only by construction (webhook URLs never exposed to the client)
- **Callbacks** — server `RegisterCallback` / `TriggerCallback` and client `TriggerCallback`, namespaced under `wc_libs:` to avoid collisions
- **Lifecycle events** — `OnPlayerLoaded`, `OnPlayerUnload`, `OnJobUpdate`
- **Framework introspection** — `Framework.Get()`, `Framework.Is('vorp')`
- **Raw escape hatch** — `Raw.VORP()`, `Raw.RSG()` return the native core object directly for anything not yet wrapped

Full reference and examples for every function: **https://docs.greenystudio.site/**

## Known gaps

Flagged honestly rather than papered over — extend these in `_custom/` if you need them:

- **VORP `onduty` status** isn't exposed on the character object in the docs this was built against, so `GetJob()` / `GetPlayer()` return `nil` for it on VORP. Works correctly on RSG.
- **VORP `OnPlayerUnload`** has no confirmed dedicated server event name, so it currently registers but never fires. Reliable on RSG.
- **RSG `OnJobUpdate`** — the docs only confirmed a *client*-side event name; server-side registration is a no-op + warning. Needs verification against a live RSG server.

- **RSG adapters are unverified against a live server.** Written faithfully from RSG's published docs, but not yet smoke-tested in production. VORP adapters are based on real working Wild County RP code and carry more confidence.

## Extending wc_libs

Don't edit the core module files directly — your changes will be overwritten on the next update. Instead, add to or override functions in:

```
_custom/client.lua
_custom/server.lua
```

These load last, after `WCLib` is fully assembled, so you can safely add new fields or reassign existing ones:

```lua
-- _custom/server.lua
WCLib.GetHonorLevel = function(source)
  local ch = WCLib.GetCharacter(source)
  if not ch or not ch.skills then return 1 end
  return ch.skills["Honor"] and ch.skills["Honor"].Level or 1
end

exports('GetHonorLevel', WCLib.GetHonorLevel)
```

See the [Custom overrides](https://docs.greenystudio.site/customizing.html) page for the full pattern, including how to safely override an existing function.

## Versioning

`wc_libs` follows the same version-checker convention as VORP resources — see `fxmanifest.lua` (`version`, `wc_libs_github`) and `version.lua`. Update `wc_libs_github` in `fxmanifest.lua` to point at this repo once it's pushed, and bump `WCLIB_VERSION` in `version.lua` on each release.

## Folder structure

```
wc_libs/
├── fxmanifest.lua
├── init.lua                   Bridge file — include via @wc_libs/init.lua for the `wc` global
├── version.lua
├── shared/
│   └── config.lua            Framework override, money-type mapping, webhook branding
├── client/
│   ├── init.lua               Detection + WCLib assembly (loads last)
│   ├── adapters/
│   │   ├── vorp.lua
│   │   └── rsg.lua
│   └── modules/
│       ├── model.lua
│       ├── prompt.lua
│       ├── blip.lua
│       ├── gps.lua
│       ├── camera.lua
│       ├── entity.lua
│       ├── distance.lua
│       └── notify.lua
├── server/
│   ├── init.lua
│   ├── adapters/
│   │   ├── vorp.lua
│   │   └── rsg.lua
│   └── modules/
│       ├── player.lua
│       ├── money.lua
│       ├── revive.lua
│       ├── callback.lua
│       ├── lifecycle.lua
│       └── webhook.lua
└── _custom/
    ├── client.lua
    └── server.lua
```

---

© Green Studio — built for Wild County RP
