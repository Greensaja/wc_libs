-- version.lua — wc_lib
-- Single source of truth for the lib's current version.
-- Mirrors VORP's vorp_checker convention: fxmanifest.lua declares
-- `version '1.0.0'` and `wc_lib_github '...'`, and on resource start
-- this checks the version.file at the repo root and warns to console
-- if a newer version is available, printing the changelog lines.
--
-- This file just exposes WCLib.GetVersion() / WCLib.GetVersionInfo()
-- for any resource that wants to print/log which wc_lib build it's
-- running against. The actual GitHub fetch + comparison happens in
-- client/init.lua and server/init.lua (each side checks once).

WCLIB_VERSION = '1.0.0'

function WCLib_GetVersion()
  return WCLIB_VERSION
end
