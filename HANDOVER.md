# Space Hunter — Handover Document
**Prepared:** 2026-03-30
**For:** Claude Code (cowork session)
**Prepared by:** Claw (OpenClaw assistant)

---

## The Game

**Space Hunter** is a top-down survivors-like roguelite built in Godot 4.4, exported to HTML5/WebAssembly and hosted on GitHub Pages. Mobile-first. Runs are 10-15 minutes.

**Live:** https://ichizh8.github.io/space-hunter/
**Repo:** https://github.com/ichizh8/space-hunter (public)
**Local:** ~/space-hunter
**Current version:** v47 (after intro bug fix, 2026-03-30)

### Core loop
ShipHub → ContractBoard (3 random contracts) → Loadout → Hunt → Results → ShipHub

### Core design identity
- **Corruption dual-resource system** — corruption rises during combat, clean vs void identity fork shapes the whole run
- **Behavior-first upgrades** — level-up choices create situations, not stat bumps. Stat upgrades belong at Ship Workbench (permanent), not in-run.
- **Level cap 12** — build phase spans the entire 10-min run. Post-cap: quiet secondary stat drip (no choice screens).
- **Clean/void identity** — T3 kit path chosen mid-run (clean or void fork). Mismatch penalty: kit cooldowns ×2 if corruption doesn't match path.

---

## Repository Structure

```
~/space-hunter/
├── scripts/
│   ├── ship_hub.gd       # Main hub screen, intro onboarding, tab system
│   ├── hunt.gd           # Core gameplay — ALL balance values live here
│   ├── loadout.gd        # Pre-hunt kit/weapon selection
│   ├── contract_board.gd # Contract selection screen
│   ├── results.gd        # Post-hunt results screen
│   ├── game_data.gd      # Singleton — runtime game state (class_name, NOT autoload)
│   ├── save_data.gd      # Save data schema
│   └── save_manager.gd   # Singleton — persistence (class_name, NOT autoload)
├── scenes/               # Godot scene files
├── docs/                 # GitHub Pages export output (DO NOT edit manually)
├── art/                  # Art assets
└── project.godot
```

All rendering is done via `_draw()` — no Sprite2D nodes. This is intentional for WASM compatibility.

---

## WASM Critical Rules — Read This First

Godot 4 WASM export has silent crash behaviors not present in native builds. **Violating these will crash the game with no error.**

1. **Never `add_child()`, `queue_free()`, `hide()`, or `set_process()` directly from `_process()` or signal callbacks.**
2. **Never call `call_deferred()` from inside a function that was itself called via `call_deferred()`** (nested deferred = crash).
3. **Never use `Array[X]` typed arrays** — they silently crash on export.
4. **Never use `:=` with `load()`, `Dict.get()`, or any Dictionary subscript** (returns Variant → parse error in release builds).

### The Only Safe Pattern for Node Operations from Signals

```
signal callback → set bool flag → _process() detects flag → call_deferred("_do_xxx") → actual add_child/queue_free
```

All four steps are required. Skipping any one step crashes in WASM.

Example (from ship_hub.gd):
```gdscript
var _intro_pending_close: bool = false

func _on_skip_pressed() -> void:
    _intro_pending_close = true          # step 1: signal just sets flag

func _process(_delta: float) -> void:
    if _intro_pending_close:
        _intro_pending_close = false
        call_deferred("_do_close_intro") # step 2: _process dispatches via call_deferred

func _do_close_intro() -> void:
    var panel := get_node_or_null("IntroPanel")
    if is_instance_valid(panel):
        panel.queue_free()               # step 3: actual node op, safe here
```

---

## Deploy Workflow

```bash
cd ~/space-hunter
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Web" docs/index.html
git add -A && git commit -m "vN: description"
git push origin main
```

GitHub Pages auto-deploys from `docs/` on `main`. Live in ~1 minute after push.

---

## Current State (v47)

### What's fully built
- **11 weapons** with Lv1-5 perks + clean/void mutation fork at Lv5 + mastery perks
- **14 kits** (T1/T2/T3 clean+void paths), all with 2 in-run kit perks
- **5 contract types** (Hunt, Payload Escort, Void Breach, Boss Hunt, Extraction Run)
- **12 enemy types** (8 regular, 4 void variants)
- **12 elites** (8 standard + 4 Apex), 12-affix system
- **4800×4800 map** with rivers, bridges, caves, void pools, biomes
- **Rep tracks** (Contractor, Void Walker, Tactician, Scrapper) + kitchen recipes + ingredient drops
- **Ship Workbench** (permanent upgrades between runs)
- **Level system** (cap 12, post-cap stat drip)
- **28 kit in-run perks** (2 per kit, behavior-only)
- **Sprint 1 psychology** — screen shake, elite names, corruption flavor, Apex warning, camera lookahead, pity cleanse, run-start gift, endowed progress
- **Intro onboarding** (5-slide first-run panel, ? button to replay)
- **Debug tooling** — DBG overlay, event log, localStorage crash persistence

### Known issues / TODO

**High priority:**
- **13 kit perk stubs** — these perks are defined but not implemented (stub only): `conductor`, `spotter`, `overheat`, `intercept_link`, `swap`, `copycat`, `chain_reaction`, `lure`, `leash_break`, `redirect`, `target_priority`, `magnet_decoy`, `shepherd`
- **Ship Workbench UI** — permanent upgrades exist in data but have no UI screen yet
- **Kit tree** — 4 slots, prerequisite-gated. Design exists (see DESIGN-PROGRESSION.md), needs building
- **Contract depth scaling** — contracts don't scale with run depth yet
- **Corruption endgame (Phase 8)** — map instability at 91+, void events — not built
- **Weapon rep locking** — all weapons currently unlocked via DEBUG flag; rep gates not enforced

**Sprint 3 (next):**
- DDA (dynamic difficulty adjustment)
- AI Director wave rhythm
- Upgrade pool weighting by playstyle
- Elite flee/charge at low HP (<20% HP behavior switch)

**Post-MVP:**
- Cloud saves + player ID
- Weekly contract system with leaderboard
- Sound effects

---

## Balance Reference

All live balance values are in two places:
1. **`scripts/hunt.gd`** — source of truth for runtime
2. **`projects/space-hunter/BALANCE-SHEET.md`** (in the OpenClaw workspace) — human-readable reference, keep in sync

To change balance values: edit hunt.gd directly OR tell Claw "change X to Y" and Claw will edit hunt.gd and sync the sheet.

### Key numbers at a glance
- Player base HP: 10 | base speed: 160px/s
- Level cap: 12 | XP to cap: ~871 kills (~9-10 min)
- Wave base: 20 + depth×5 enemies | interval: 12s start, 5s min
- Apex first spawn: 10 min | subsequent: 8 min after death
- Corruption: T3 mismatch penalty kicks in at 35 (clean) / 50 (void)

---

## Design Principles — Don't Violate These

1. **Behavior over stats** — every in-run upgrade should create a situation, not adjust a number
2. **The clean/void system is the soul** — every mechanic should amplify or honor the identity fork
3. **90-second rhythm** — something meaningful every 60-90s; no dead time
4. **3 concurrent priorities max** — don't add complexity without removing something
5. **Player feels skilled, not lucky** — RNG must be invisible; decisions must be visible
6. **Stat upgrades belong at the Ship Workbench**, not in-run offer screens

---

## Design Docs (in OpenClaw workspace)

| File | Contents |
|---|---|
| `projects/space-hunter/STATE.md` | Full current project state, architecture notes |
| `projects/space-hunter/BALANCE-SHEET.md` | All live balance values |
| `projects/space-hunter/DESIGN-PSYCHOLOGY-SPACEHUNTER.md` | 21 game psychology techniques prioritized for Space Hunter |
| `projects/space-hunter/DESIGN-PSYCHOLOGY-MASTER.md` | Full 100-technique reference |
| `projects/space-hunter/DESIGN-WEEKLY-CONTRACT.md` | Weekly contract + leaderboard design |
| `projects/space-hunter/DESIGN-PROGRESSION.md` | Rep/kitchen/contracts/weapons progression design |

---

## How Claw Works With This Project

- Claw (OpenClaw assistant) handles git commits, balance edits, bug fixes, and deploys
- Balance changes: edit BALANCE-SHEET.md or tell Claw in plain language → Claw updates hunt.gd
- Design decisions are made by Iurii; implementation is handled by Claw or Claude Code
- MEMORY.md in the OpenClaw workspace (~/.openclaw/MEMORY.md) has long-term project context
- Daily memory files: ~/.openclaw/memory/YYYY-MM-DD.md

---

## Collaboration Notes

- Repo is public. @Memetrix has been invited as a write collaborator (pending accept as of 2026-03-30).
- Claw is the primary committer from the Mac mini. Coordinate on branches if working in parallel to avoid conflicts.
- When pushing: always export first (Godot headless export), then commit, then push. Never commit without exporting — docs/ must stay current.
- If you see `export_presets.cfg` in the repo root: that's correct and required for headless export.
