# wc_lib — Documentation

Documentation site for **wc_lib**, Green Studio's shared RedM library that bridges VORP Core and RSG Core behind one API — write a resource once, run it on either framework.

**Live site:** https://docs.greenystudio.site/

## What's here

This repo is just the static documentation site — plain HTML/CSS/JS, no build step, hosted via GitHub Pages. It documents the actual `wc_lib` resource (the Lua library itself lives in your RedM server's `resources` folder, not in this repo).

```
.
├── index.html              Landing page + live VORP/RSG code toggle
├── getting-started.html    Install & setup
├── customizing.html        How to extend wc_lib via _custom/
├── api/                    Function reference, one page per module
│   ├── player.html
│   ├── money.html
│   ├── revive.html
│   ├── callbacks.html
│   ├── lifecycle.html
│   ├── webhook.html
│   ├── notify.html
│   ├── prompts.html
│   ├── entities.html
│   └── distance.html
├── examples/
│   └── full-resource.html  Complete worked example resource
├── css/style.css
└── js/main.js               Framework toggle, copy buttons, mobile nav
```

## Running it locally

No build step — just open `index.html` in a browser, or serve the folder with any static server:

```bash
python3 -m http.server 8000
```

Then visit `http://localhost:8000`.

## Deploying

This repo is set up to serve directly via **GitHub Pages** from the repo root:

1. **Settings → Pages**
2. Source: *Deploy from a branch*
3. Branch: `main`, folder: `/ (root)`
4. Save — GitHub will publish the site at the URL shown on that page within a minute or two.

## Updating the docs

Each API page is hand-written HTML sharing a common sidebar/topbar structure. If you're adding a new page or changing the nav, it's easier to use the fragment + build script (kept separately, not in this repo) rather than hand-editing every page's sidebar — ping the original build tooling if you need it regenerated.

For small content edits (fixing a typo, updating an example), just edit the relevant `.html` file directly and push.

## About wc_lib

wc_lib is maintained alongside [Wild County RP](https://github.com/WILD-COUNTY-RP) RedM resources. It currently bridges:

- **VORP Core** — primary/production framework, full feature fidelity
- **RSG Core** — supported, best-effort fallback where RSG has no native equivalent (see the [Notify](api/notify.html) and [Revive & Heal](api/revive.html) pages for specifics)

---

© Green Studio
