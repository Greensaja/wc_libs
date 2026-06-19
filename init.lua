-- init.lua — wc_libs bridge
-- Consuming resources include this file to get the `wc` shorthand global.
--
-- In your resource's fxmanifest.lua add:
--
--   shared_scripts { '@wc_libs/init.lua' }
--
-- Then call any wc_libs function as:
--
--   wc:Notify({ variant = 'avanced', title = '+$50', icon = 'itemtype_cash', color = 'COLOR_WHITE' })
--   wc:GetPlayer(source)
--   wc:AddMoney(source, 50)
--   -- etc.
--
-- `wc` is a live proxy to exports['wc_libs'] — calls resolve at call time,
-- not at load time, so it works correctly on both client and server.

wc = exports['wc_libs']
