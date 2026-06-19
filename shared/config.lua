-- shared/config.lua — wc_libs
-- Shared configuration. Loaded before everything else on both sides.

WCLibConfig = {}

-- ─────────────────────────────────────────────────────────
-- Framework detection
-- ─────────────────────────────────────────────────────────
-- Leave as nil to auto-detect (checks for vorp_core / rsg-core resources).
-- Set explicitly only if you need to force one side, e.g. during a
-- migration where both cores might be present on the server at once.
--
-- Valid values: 'vorp', 'rsg', or nil (auto-detect)
WCLibConfig.ForceFramework = nil

-- ─────────────────────────────────────────────────────────
-- Money type keys
-- ─────────────────────────────────────────────────────────
-- VORP uses fixed currency *indices* (0 = money, 1 = gold, 2 = rol).
-- RSG uses a *named* money table (commonly 'cash', 'bank', etc).
-- These let wc_libs map GetMoney/GetBankMoney/GetGold consistently
-- across both without hardcoding magic numbers/strings in adapters.
WCLibConfig.Money = {
  vorp = {
    cash = 0,
    gold = 1,
    rol  = 2,
  },
  rsg = {
    cash = 'cash',
    bank = 'bank',
    gold = nil, -- RSG has no native gold currency; GetGold() will warn + return 0
                -- Set this to a custom money-type key (e.g. 'gold') if your
                -- RSG server's shared/items or config defines one.
  },
}

-- ─────────────────────────────────────────────────────────
-- Revive / Heal fallback behaviour
-- ─────────────────────────────────────────────────────────
-- RSG Core has no native Revive/Heal — it's normally owned by an
-- ambulance/EMS job resource. Configure the export wc_libs should try
-- to call on RSG. If the resource isn't running, wc_libs will warn to
-- console and no-op rather than erroring.
WCLibConfig.RSGAmbulanceResource = 'rsg-ambulancejob'
WCLibConfig.RSGAmbulanceReviveExport = 'Revive'
WCLibConfig.RSGAmbulanceHealExport   = 'Heal'

-- ─────────────────────────────────────────────────────────
-- Webhook defaults (Green Studio branding)
-- ─────────────────────────────────────────────────────────
-- Per-resource code should still call WCLib.Webhook.Send(...) with its
-- own colour map / fields; these are just the shared footer/branding
-- defaults applied to every embed regardless of which resource sends it.
WCLibConfig.Webhook = {
  Branding = 'Green Studio',
  -- Default colour used when a resource doesn't supply its own colorMap
  -- entry for a given action.
  DefaultColor = 0x3498DB,
}
