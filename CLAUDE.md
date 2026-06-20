# wc_libs — Claude Code Context

Green Studio's shared utility library for RedM (RDR2 multiplayer). Bridges VORP (`vorp_core`) and RSG (`rsg-core`) so all Green Studio scripts stay framework-agnostic.

## Architecture

**Adapter pattern.** On startup, `detectFramework()` in `client/init.lua` and `server/init.lua` auto-detects the running core (or reads `WCLibConfig.ForceFramework`). The matching adapter (`WCLibAdapterVORP` or `WCLibAdapterRSG`) is injected into every module via `_activeAdapter`. All framework branching lives in the two adapter files — never in modules.

**Load order** (fxmanifest): `shared/config.lua` → adapters → modules → `init.lua` (last) → `_custom/` (very last).

**Extension seam:** `_custom/client.lua` and `_custom/server.lua` are empty files for per-server overrides that survive lib updates.

**NUI:** `nui/dialogue/` — the wcdialogue panel. All NUI message types use the `wcdialogue:` prefix to avoid collision with other resources.

## File Structure

```
wc_libs/
├── shared/
│   └── config.lua          # WCLibConfig — ForceFramework, Money keys, etc.
├── client/
│   ├── adapters/
│   │   ├── vorp.lua        # VORP client adapter
│   │   └── rsg.lua         # RSG client adapter
│   ├── modules/
│   │   ├── notify.lua      # WCLibNotify
│   │   ├── prompt.lua      # WCLibPrompt
│   │   ├── blip.lua        # WCLibBlip
│   │   ├── gps.lua         # WCLibGPS
│   │   ├── camera.lua      # WCLibCamera
│   │   ├── entity.lua      # WCLibEntity
│   │   ├── distance.lua    # WCLibDistance
│   │   ├── model.lua       # WCLibModel
│   │   ├── emote.lua       # WCLibEmote
│   │   ├── zone.lua        # WCLibZone
│   │   ├── wagon.lua       # WCLibWagon
│   │   └── dialogue.lua    # WCLibDialogue
│   └── init.lua            # assembles WCLib table, registers exports
├── server/
│   ├── adapters/
│   │   ├── vorp.lua        # VORP server adapter
│   │   └── rsg.lua         # RSG server adapter
│   ├── modules/
│   │   ├── player.lua      # WCLibPlayer
│   │   ├── money.lua       # WCLibMoney
│   │   ├── revive.lua      # WCLibRevive
│   │   ├── callback.lua    # WCLibCallback
│   │   ├── lifecycle.lua   # WCLibServerLifecycle
│   │   ├── webhook.lua     # WCLibWebhook
│   │   ├── nearby.lua      # WCLibNearby
│   │   ├── skill.lua       # WCLibSkill (VORP only)
│   │   └── battlepass.lua  # WCLibBattlepass
│   └── init.lua            # assembles WCLib table, registers exports
├── nui/
│   └── dialogue/           # index.html, style.css, main.js, font
├── _custom/
│   ├── client.lua          # empty — per-server client overrides
│   └── server.lua          # empty — per-server server overrides
└── fxmanifest.lua
```

## Client API (WCLib.*)

| Function | Module | Notes |
|---|---|---|
| `Notify(opts)` | notify | 17 VORP variants or RSG ox_lib |
| `StartProgress(label, durationMs, cb, style)` | progress | vorp_progressbar with timed fallback |
| `TriggerCallback(name, ...)` | callback | Client -> server callback trigger, auto-prefixed `wc_libs:` |
| `TopNotify(title, msg, header)` | notify | Native UiFeedPostTwoTextShard via DataView |
| `WcNotify(msg, level, placement)` | notify | wc_notify:send wrapper |
| `WcTip(msg, duration, opts)` / `wctip(...)` | notify | wc_libs NUI toast using `nui/image/toast.png` |
| `CreatePrompt / SetPromptVisible / IsPromptCompleted / DeletePrompt` | prompt | |
| `WatchPrompt(prompt, target, radius, onPressed, opts)` | flow | Proximity-gated prompt watcher with timeout, guard, and cancel callback |
| `WatchPlayerNear / WatchPlayerAway` | flow | Reusable proximity watchers for coords, vector3, or entity targets |
| `CreateBlip / RemoveBlip` | blip | |
| `CreateMissionMarker / ClearMissionMarker` | flow | Blip handle wrapper with optional GPS route cleanup |
| `CreateCleanupBag / CleanupEncounter` | flow | Collect and clean prompts, blips, GPS routes, peds, vehicles, objects, and custom cleanup callbacks |
| `SetGPSRoute / ClearGPSRoute` | gps | |
| `EnableDialogueCamera / DisableDialogueCamera / GetDialogueCameraHandle` | camera | |
| `SnapZ / SpawnPed / SpawnHorse / SpawnProp` | entity | |
| `DeletePed / DeleteVehicle / FaceEachOther / PlacePedRelative` | entity | |
| `SetupCombatPed(ped, opts)` | entity | health, accuracy, relationGroup, fightToDeath, canFlank, wontFlee, range, movement, targetPed |
| `ArmPed(ped, weaponName, ammoHash, ammoCount)` | entity | Uses GiveWeaponToPed_2 (RedM native) |
| `GetDistance / SquaredDistance / IsNearCoords / IsPlayerNearCoords` | distance | |
| `LoadModel / LoadAnyModel / LoadAnimDictSafe` | model | |
| `StartConversationGestures(npcPed, skipNpc, skipPlayer)` | emote | Returns stopper function |
| `PlayShareEmote / PlayFailEmote / PlayRewardHandover` | emote | |
| `ShareEmotes / FailEmotes` | emote | Built-in key tables |
| `IsInsideZone(pos, zones) / IsPlayerInsideZone(zones)` | zone | zones = `{ {x,y,z,radius,name?}, ... }` |
| `SpawnWagon(model,x,y,z,heading,opts)` | wagon | opts: broken, isMission, frozen, timeoutMs |
| `DeleteWagon / RepairWagon / FreezeWagon / GetWagonWheelPos` | wagon | |
| `RunDialogue(def, npcPed, timeoutSecs, opts)` | dialogue | Returns "success"\|"partial"\|"fail" |
| `RunAccept(def, npcPed, opts)` | dialogue | Returns bool |
| `WatchIgnore(guard, npcPed, distance, onIgnored)` | dialogue | |
| `OnPlayerLoaded(callback)` | lifecycle | Fires when character is ready |
| `OnPlayerSpawned(callback)` | lifecycle | Fires on spawn (useful after resource restart) |

## Server API (WCLib.*)

| Function | Module | Notes |
|---|---|---|
| `GetPlayer(source)` | player | Returns normalized player snapshot |
| `GetCharacter(source)` | player | |
| `GetJob(source)` | player | |
| `GetMoney / GetBankMoney / GetGold` | money | GetBankMoney on VORP returns nil (no bank currency) |
| `AddMoney / RemoveMoney` | money | |
| `Revive / Heal` | revive | RSG delegates to ambulance resource via config |
| `RegisterCallback / TriggerCallback` | callback | Server callbacks auto-prefixed `wc_libs:` |
| `OnPlayerLoaded / OnPlayerUnload / OnJobUpdate` | lifecycle | OnPlayerUnload is a no-op on VORP (no confirmed event) |
| `SendWebhook / FormatMoney` | webhook | Server-only — keeps Discord URLs off client |
| `GetPlayersInRadius(source, radius)` | nearby | Returns array of source IDs, excludes self |
| `GetSkillInfo / GiveSkillXP / ApplySkillBonus` | skill | VORP only — warns + returns nil on RSG |
| `AddBattlepassXP / AddBattlepassXPForPlayer` | battlepass | Requires `vlab_battlepass` resource |
| `Framework.Get() / Framework.Is(name)` | framework | |
| `Raw.VORP() / Raw.RSG()` | raw | Returns native core object as escape hatch |

## Using wc_libs from another resource

```lua
-- fxmanifest.lua
dependency 'wc_libs'

-- any server script
local wc = exports.wc_libs

-- client
wc:OnPlayerLoaded(function()
  wc:Notify({ header = 'Ready', msg = 'Character loaded.' })
end)

-- server
wc:OnPlayerLoaded(function(source)
  local player = wc:GetPlayer(source)
  print(player.firstname, player.lastname)
end)
```

## Design Decisions (do not change without good reason)

- **VORP is primary.** RSG support is best-effort — notify collapses to ox_lib, skills/bank are no-ops with warnings.
- **No framework branching in modules.** All `if vorp then / else rsg` lives in adapters only.
- **Exports are per-function**, not a single `GetTable()` export. Better editor autocomplete.
- **Callbacks auto-prefixed** with `wc_libs:` to avoid name collisions.
- **Webhook is server-only** — Discord URLs must never reach the client.
- **NUI prefix is `wcdialogue:`** — not `encounter:` or anything resource-specific, so multiple Green scripts can run simultaneously without NUI message collision.
- **Money functions are separate** (`GetMoney`, `GetBankMoney`, `GetGold`) not one function with a currency param — explicit is safer.
- **`_custom/` files survive updates** — per-server overrides go there, never in the core modules.
- **VORP server `OnPlayerLoaded`** listens to both `vorp_CharSelectedCharacter` (existing char) and `vorp_NewCharacter` (new char). The `source` is read from the global `source` inside the handler.
- **RSG money reads** use `Player.Functions.GetMoney(key)` (official API), not direct `PlayerData.money[key]`.
- **`GiveWeaponToPed_2`** is a RedM-specific native not known to LuaLS — suppress with `---@diagnostic disable-next-line: undefined-global`.

## Extending the lib

- Add a new module in `client/modules/` or `server/modules/`, declare a global table (`WCLibFoo = {}`), then wire it into the `WCLib` table in the matching `init.lua`.
- Register it in `fxmanifest.lua` before `init.lua` in the load order.
- Add an entry in `_custom/client.lua` or `_custom/server.lua` if the feature needs per-server config.
- Update `D:\lib documentation web\wc_lib-docs\` with the new API page and sidebar entries.
