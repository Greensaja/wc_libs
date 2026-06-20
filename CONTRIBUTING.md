# Contributing to wc_libs

Thanks for your interest in contributing. Please read this before opening a PR — changes that violate these rules will be rejected.

## Ground Rules

- **One PR, one concern.** Don't mix a bug fix with a new feature in the same PR.
- **No breaking changes to the public API** without opening an issue first to discuss.
- **No framework branching in modules.** All `if vorp then ... else rsg end` logic belongs in `client/adapters/` or `server/adapters/` only — never in modules.
- **No hardcoded resource names, URLs, or server-specific values** in the core lib. Those belong in `_custom/` or the consumer resource's config.

## Adapter Rules

If you're touching an adapter (`client/adapters/vorp.lua`, etc.):
- Both adapters must expose the same function signatures. If you add a function to one, add it to both.
- Verify your changes against the framework's actual event/API names. Wrong event names that silently do nothing are worse than a loud error.
- VORP and RSG handle money, lifecycle, and callbacks differently — read the existing code carefully before changing anything.

## Adding a New Module

1. Create the module in `client/modules/` or `server/modules/` with a single global table (`WCLibFoo = {}`).
2. Wire it into `WCLib` in the matching `init.lua`.
3. Register it in `fxmanifest.lua` **before** `init.lua` in the load order.
4. If the module needs framework-specific behavior, expose it via the adapter interface — don't call adapter globals directly from the module.

## Code Style

- Lua 5.4 (`lua54 'yes'` in fxmanifest).
- No comments that describe *what* the code does — only comments that explain *why* when the reason is non-obvious.
- No print statements left in production code except guarded warnings (e.g. `print('[wc_libs] WARNING: ...')`).
- Use `pcall` around any external export call that could fail silently.

## Pull Request Checklist

Before submitting:
- [ ] Tested on at least one framework (VORP or RSG)
- [ ] Both adapters updated if you touched adapter-level behavior
- [ ] No internal server paths, Discord URLs, or private resource names in the code
- [ ] `fxmanifest.lua` updated if you added a new file
- [ ] PR description explains *why* the change is needed, not just what it does

## What Will Be Rejected

- PRs that add server-specific logic (encounters, jobs, missions) — wc_libs is a utility lib, not a game-mode framework.
- PRs that remove existing public API functions without a deprecation path.
- PRs adding dependencies on external resources without a clear fallback when that resource isn't running.
- Any code that could leak server internals (webhook URLs, admin identifiers, etc.) to the client.

## Opening an Issue First

For anything larger than a bug fix or small improvement, open an issue before writing code. This avoids wasted effort if the direction doesn't fit the project.
