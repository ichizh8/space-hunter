# Pass 1 Build Task — Space Hunter v23

Read ALL of these files fully before making any changes:
- scripts/hunt.gd
- scripts/loadout.gd
- scripts/ship_hub.gd
- scripts/game_data.gd
- scripts/save_data.gd
- scripts/save_manager.gd

This is a major refactor. Implement everything carefully and completely.

---

## 1. SINGLE MAIN WEAPON

Remove multi-weapon system. Replace `active_weapons: Array[Dictionary]` with a single weapon:

```gdscript
var main_weapon: Dictionary = {}
# {id, level, cooldown_timer, mag_ammo, mag_size, reload_timer, mutated, mutation_type}
# mutation_type: "" | "clean" | "void"
```

Remove `weapon_slots` var. Remove all multi-weapon loop code in `_update_weapons`. Replace with single weapon firing.

In `_ready`, set main_weapon from `GameData.starting_weapon`:
```gdscript
var wid: String = GameData.starting_weapon
if wid.is_empty() or not WEAPON_DEFS.has(wid): wid = "sidearm"
var is_baton: bool = wid == "baton"
var base_mag: int = 999 if is_baton else 12
var mag_bonus: int = SaveManager.data.ship_upgrades.get("mag_size", 0) * 3
main_weapon = {id=wid, level=1, cooldown_timer=0.0, mag_ammo=base_mag+mag_bonus, mag_size=base_mag+mag_bonus, reload_timer=0.0, mutated=false, mutation_type=""}
```

Update all references to `active_weapons[0]` -> `main_weapon`. Update HUD weapon display to show single weapon.

---

## 2. XP CURVE

Change leveling threshold: flat 20 -> scaled:
```gdscript
func _xp_needed_for_level(lv: int) -> int:
    if lv <= 5: return 20
    elif lv <= 10: return 35
    else: return 55
```

Track `xp_threshold: int` (current level threshold). Set in `_ready`: `xp_threshold = _xp_needed_for_level(1)`
In `_check_pickups`, change level-up condition:
```gdscript
if essence_collected >= xp_threshold:
    essence_collected -= xp_threshold
    player_level += 1
    xp_threshold = _xp_needed_for_level(player_level)
    _level_up()
```

Update XP bar draw: use `float(essence_collected) / float(xp_threshold)` for fraction.

---

## 3. RUN MODIFIERS

Replace the passive pool with run modifiers. These are more interesting one-time run buffs.

Remove old `ALL_PASSIVES` and `passives_taken`. Replace with:

```gdscript
const RUN_MODIFIERS: Array[Dictionary] = [
    {id="adrenaline",   rarity="rare",   icon="E", name="Adrenaline",    desc="3 kills in 3s: +5% speed stacking (resets on hit)"},
    {id="void_hunger",  rarity="common", icon="V", name="Void Hunger",   desc="Killing void-type enemies restores 1 HP"},
    {id="stalker",      rarity="rare",   icon="S", name="Stalker",       desc="+40% damage to enemies not targeting you"},
    {id="momentum",     rarity="rare",   icon="M", name="Momentum",      desc="+15% bullet speed per consecutive hit, resets on miss"},
    {id="scavenger",    rarity="common", icon="$", name="Scavenger",     desc="Ingredients also drop 1 essence"},
    {id="last_stand",   rarity="rare",   icon="L", name="Last Stand",    desc="Below 3 HP: +50% damage and +30% speed"},
    {id="pack_hunter",  rarity="common", icon="P", name="Pack Hunter",   desc="+8% damage per enemy within 200px"},
    {id="biome_bond",   rarity="rare",   icon="B", name="Biome Bond",    desc="+20% damage while in your starting biome"},
    {id="precision",    rarity="rare",   icon="X", name="Precision",     desc="First shot after reload always crits (2x damage)"},
    {id="void_drain",   rarity="common", icon="D", name="Void Drain",    desc="Killing void enemies reduces corruption by 3"},
    {id="tough",        rarity="common", icon="T", name="Reinforced Suit", desc="+3 max HP, heal to full"},
    {id="speed",        rarity="common", icon="F", name="Thruster Boost", desc="+25 move speed"},
    {id="reload",       rarity="common", icon="R", name="Speed Loader",  desc="Reload time -30%"},
    {id="magplus",      rarity="common", icon="A", name="Extended Mag",  desc="+4 ammo"},
    {id="dodge",        rarity="rare",   icon="G", name="Phase Shift",   desc="10% chance to dodge a hit"},
    {id="vamp",         rarity="rare",   icon="H", name="Blood Harvest", desc="1 in 5 kills restores 1 HP"},
    {id="elite_dmg",    rarity="rare",   icon="K", name="Hunters Mark",  desc="+30% damage vs elites"},
    {id="corruption_resist", rarity="rare", icon="C", name="Void Skin", desc="Corruption gain -25%"},
]
var modifiers_taken: Array[String] = []
```

Wire modifier effects in _on_upgrade_chosen "modifier" type (replaces old "passive" type):

Keep applying the old effects that still match (tough, speed, reload, magplus, dodge, vamp, elite_dmg, corruption_resist) using the same weapon_mods patterns already in the code.

Wire NEW modifier effects:
- `adrenaline`: add vars `adrenaline_stack: int = 0`, `adrenaline_last_kill_time: float = 0.0`. In _on_enemy_killed: if "adrenaline" in modifiers_taken: if (hunt_elapsed - adrenaline_last_kill_time) < 3.0: adrenaline_stack += 1 else: adrenaline_stack = 1; adrenaline_last_kill_time = hunt_elapsed. On player hit: reset adrenaline_stack = 0. Apply in _get_effective_player_stats: move_speed_mult *= (1.0 + adrenaline_stack * 0.05)
- `void_hunger`: in _on_enemy_killed: if e.void_type and "void_hunger" in modifiers_taken: player_hp = min(player_hp+1, player_max_hp)
- `stalker`: in _update_bullets player hit vs enemy: if not e.is_aggroed and "stalker" in modifiers_taken: apply_damage = int(apply_damage * 1.4)
- `momentum`: add `momentum_stack: int = 0`. On bullet hit enemy: momentum_stack = min(momentum_stack+1, 10). On bullet expire without hitting: momentum_stack = 0 (track via bullet.missed flag or just decay on miss). Apply as: actual bullet speed at fire time *= (1.0 + momentum_stack * 0.15)
- `scavenger`: in _on_enemy_killed elite: spawn 1 extra essence pickup
- `last_stand`: in _get_effective_player_stats: if player_hp <= 3 and "last_stand" in modifiers_taken: damage_mult *= 1.5; move_speed_mult *= 1.3
- `pack_hunter`: in _update_bullets player hit: count enemies in 200px of player, damage *= (1.0 + count * 0.08)
- `biome_bond`: add `player_start_biome: String = ""`, set in _ready: player_start_biome = _get_biome_at(player_pos). In bullet hit: if _get_biome_at(player_pos) == player_start_biome and "biome_bond" in modifiers_taken: damage *= 1.2
- `precision`: add `next_shot_crit: bool = false`. On reload complete: if "precision" in modifiers_taken: next_shot_crit = true. On fire: if next_shot_crit: damage *= 2; next_shot_crit = false
- `void_drain`: in _on_enemy_killed: if e.void_type and "void_drain" in modifiers_taken: corruption = max(0.0, corruption - 3.0)

In _generate_upgrades, change "passive" type to "modifier" type. Draw from RUN_MODIFIERS excluding modifiers_taken.

---

## 4. KIT SYSTEM (T1 only for Pass 1)

Add kit data structures near top of hunt.gd:

```gdscript
var equipped_kits: Array[String] = []
var kit_states: Dictionary = {}
var kit_tiers: Dictionary = {}

var traps: Array[Dictionary] = []
var decoys: Array[Dictionary] = []
var turrets: Array[Dictionary] = []
var smoke_zones: Array[Dictionary] = []
var gravity_wells: Array[Dictionary] = []
var drone_active: bool = false
var drone_pos: Vector2 = Vector2.ZERO
var drone_intercept_timer: float = 0.0
var familiar_active: bool = false
var familiar_pos: Vector2 = Vector2.ZERO
var familiar_attack_timer: float = 0.0
var familiar_corruption_timer: float = 0.0
```

Kit button layout in HUD: draw up to 2 kit buttons at bottom-right.
- If 1 kit: one button at Vector2(vp_size.x - 90, vp_size.y - 55)
- If 2 kits: buttons at Vector2(vp_size.x - 180, vp_size.y - 55) and Vector2(vp_size.x - 90, vp_size.y - 55)
- Each button: 70x36 rect with kit name + cooldown bar underneath
- The stim_pack kit replaces the old hardcoded stim button

Remove the old hardcoded stim button code. Replace with the kit button system.

Store button rects for tap detection: `var kit_button_rects: Array[Rect2] = []` — rebuild in _draw, detect taps in _input.

KIT_DEFS constant:
```gdscript
const KIT_DEFS: Dictionary = {
    "stim_pack":    {name="Stim",     icon="S", desc="T1: +4 HP, +15 corruption. 8s cooldown."},
    "flash_trap":   {name="Trap",     icon="T", desc="T1: Stun trap 80px 2s. 2 charges/hunt."},
    "blink_kit":    {name="Blink",    icon="B", desc="T1: Teleport 200px. 10s cooldown."},
    "chain_kit":    {name="Chain",    icon="C", desc="T1: Tether enemy 3s. 12s cooldown."},
    "charge_kit":   {name="Charge",  icon="X", desc="T1: Knockback 150px. 12s cooldown."},
    "mirage_kit":   {name="Mirage",  icon="M", desc="T1: Decoy draws aggro 6s. 18s cooldown."},
    "turret_kit":   {name="Turret",  icon="R", desc="T1: Auto-turret 12s. 1 charge/hunt."},
    "smoke_kit":    {name="Smoke",   icon="K", desc="T1: Smoke 150px 6s. 14s cooldown."},
    "anchor_kit":   {name="Anchor",  icon="A", desc="T1: Gravity pull 400px 4s. 20s cooldown."},
    "drone_kit":    {name="Drone",   icon="D", desc="T1: Intercepts 1 bullet/4s."},
    "familiar_kit": {name="Familiar",icon="F", desc="T1: Void familiar, rams enemies."},
    "pack_kit":     {name="Pack",    icon="P", desc="T1: Summon 2 allies 15s. 25s cooldown."},
    "void_surge":   {name="Surge",   icon="V", desc="T1: Spend 20 corruption: +80% speed 3s."},
    "rupture_kit":  {name="Rupture", icon="U", desc="T1: Detonate corruption bar AOE."},
}
```

In _ready: load equipped_kits and kit_tiers from GameData. Initialize kit_states.

`_init_kit_state(kit_id: String) -> Dictionary`:
- stim_pack: {cooldown: 0.0, max_cooldown: 8.0}
- flash_trap: {cooldown: 0.0, charges: 2}
- blink_kit: {cooldown: 0.0, max_cooldown: 10.0}
- chain_kit: {cooldown: 0.0, max_cooldown: 12.0}
- charge_kit: {cooldown: 0.0, max_cooldown: 12.0, charging: false}
- mirage_kit: {cooldown: 0.0, max_cooldown: 18.0}
- turret_kit: {charges: 1}
- smoke_kit: {cooldown: 0.0, max_cooldown: 14.0}
- anchor_kit: {cooldown: 0.0, max_cooldown: 20.0}
- drone_kit: {active: true}
- familiar_kit: {active: true}
- pack_kit: {cooldown: 0.0, max_cooldown: 25.0}
- void_surge: {cooldown: 0.0, max_cooldown: 5.0, active: false, timer: 0.0}
- rupture_kit: {cooldown: 0.0, max_cooldown: 30.0}
- default: {cooldown: 0.0, max_cooldown: 15.0}

`_activate_kit(kit_id: String)`:
- stim_pack: player_hp = min(player_hp+4, player_max_hp); corruption += 15; _show_message("Stim! +4HP +15 corruption"); state.cooldown = 8.0
- flash_trap: if charges > 0: place trap at player_pos; charges -= 1
- blink_kit: teleport player 200px in joystick dir (or Vector2.UP if no input); state.cooldown = 10.0
- chain_kit: fire a tether bullet (special bullet dict with tether=true); state.cooldown = 12.0
- charge_kit: if not charging: state.charging = true; _show_message("Charging...") else: release knockback blast (push all enemies in 150px away 200px, deal 2 dmg); state.charging = false; state.cooldown = 12.0
- mirage_kit: decoys.append({pos=player_pos + Vector2(randf_range(-40,40), randf_range(-40,40)), hp=5, timer=6.0}); state.cooldown = 18.0
- turret_kit: if charges > 0: turrets.append({pos=player_pos, timer=12.0, fire_timer=0.0}); charges -= 1
- smoke_kit: smoke_zones.append({pos=player_pos, radius=150.0, timer=6.0}); state.cooldown = 14.0
- anchor_kit: gravity_wells.append({pos=player_pos, radius=400.0, timer=4.0}); state.cooldown = 20.0
- drone_kit: drone_active = true; drone_pos = player_pos + Vector2(50,0)
- familiar_kit: familiar_active = true; familiar_pos = player_pos + Vector2(60,0)
- pack_kit: if state.cooldown <= 0: spawn 2 Rift Parasite allies using _spawn_single_enemy, set is_aggroed=true, cave_id=-1; state.cooldown = 25.0
- void_surge: if corruption >= 20: corruption -= 20; state.active = true; state.timer = 3.0; _show_message("Void Surge!"); state.cooldown = 5.0
- rupture_kit: var dmg = int(corruption / 5.0); for each enemy in 200px: e.hp -= dmg; add aoe_flash; corruption = 0.0; _show_message("RUPTURE! -%d corruption" % dmg); state.cooldown = 30.0

Cooldown ticking: in _process, call `_update_kit_cooldowns(delta)`:
```gdscript
func _update_kit_cooldowns(delta: float) -> void:
    for kit_id in equipped_kits:
        if not kit_states.has(kit_id): continue
        var state: Dictionary = kit_states[kit_id]
        if state.has("cooldown") and state.cooldown > 0.0:
            state.cooldown -= delta
        if kit_id == "void_surge" and state.get("active", false):
            state.timer -= delta
            if state.timer <= 0.0:
                state.active = false
        kit_states[kit_id] = state
```

Void surge speed: in _get_effective_player_stats, if "void_surge" in equipped_kits and kit_states.void_surge.active: move_speed_mult *= 1.8

Kit entity updates in _process:
- `_update_traps(delta)`: for each trap, check all enemies within stun_radius; if found: enemy.stunned_timer = 2.0, trap.active = false
- `_update_decoys(delta)`: tick timers, remove expired
- `_update_turrets(delta)`: tick timer, fire_timer -= delta; if fire_timer <= 0: fire_timer = 0.125; find nearest enemy, deal 1 dmg (8/s); remove when timer <= 0
- `_update_smoke(delta)`: tick timers, remove expired; enemies inside: is_aggroed = false (only if not aggroed yet)
- `_update_gravity_wells(delta)`: tick timers; pull all living enemies toward well pos at 120px/s
- `_update_drone(delta)`: if drone_active: orbit player_pos; drone_intercept_timer -= delta; if <= 0: find nearest enemy bullet within 100px of drone_pos; if found: remove it, show flash, reset timer to 4.0; drone_pos orbits at 50px radius
- `_update_familiar(delta)`: if familiar_active: orbit player_pos at 60px; familiar_corruption_timer -= delta; if <= 0: corruption += 1.0; familiar_corruption_timer = 8.0; familiar_attack_timer -= delta; if <= 0: find nearest enemy in 120px, deal 2 dmg; familiar_attack_timer = 3.0

Add enemy field: ensure all enemies have `stunned_timer: float = 0.0` (add in _spawn_single_enemy).
In _update_enemies: if e.stunned_timer > 0: e.stunned_timer -= delta; skip movement and attacks for this enemy.

In _update_enemies enemy targeting: if a decoy is alive and within detection range and closer than player, move toward decoy instead of player.

Tether bullet: in _update_bullets, if b.get("tether", false): on hit enemy: enemy.stunned_timer = 3.0 (tethered/immobile); remove bullet.

Draw kit entities in _draw:
- Traps (active only): yellow diamond 10x10 at world pos
- Decoys: green circle radius 12 (player color) at world pos
- Turrets: cyan square 14x14 at world pos, small HP indicator
- Smoke zones: grey-blue circle, fill alpha 0.15, border alpha 0.4, pulsing
- Gravity wells: purple pulsing ring, radius grows/shrinks slightly
- Drone (if active): small white circle radius 6, draw at drone_pos (screen space orbiting)
- Familiar (if active): small purple circle radius 6, draw at familiar_pos

---

## 5. WEAPON MUTATIONS

Add constant:
```gdscript
const WEAPON_MUTATIONS: Dictionary = {
    "sidearm": {
        "clean": {icon="G", name="Marksman Rifle", desc="Fire rate halved, damage x3, +50% range. First shot after reload: instant."},
        "void":  {icon="V", name="Entropy Gun",    desc="Each bullet splits into 3 fragments on hit. Fragments bounce off walls once."},
    },
    "scatter": {
        "clean": {icon="G", name="Flechette",      desc="Tighter cone, pellets pierce 2 enemies."},
        "void":  {icon="V", name="Chaos Spray",    desc="270 degree cone, pellets home slightly. Chip dmg to self if enemies in 40px."},
    },
    "lance": {
        "clean": {icon="G", name="Null Spear",     desc="Fire rate x2, leaves a 3s slow field where it lands."},
        "void":  {icon="V", name="Singularity",    desc="On hit: 2s gravity vortex. Your bullets deal +50% to pulled enemies."},
    },
    "baton": {
        "clean": {icon="G", name="Arc Blade",      desc="Melee leaves 3s slow fields on the ground."},
        "void":  {icon="V", name="Consuming Vortex", desc="AOE expands 1.5s. Drains HP from enemies, heals you."},
    },
    "dart": {
        "clean": {icon="G", name="Smart Missile",  desc="Single large slow missile. Massive damage, perfect tracking."},
        "void":  {icon="V", name="Parasite Swarm", desc="Darts latch on, drain HP 4s. Spreads to 1 nearby enemy on death."},
    },
}
```

In _generate_upgrades: if main_weapon.level >= 5 and not main_weapon.mutated:
- Check available mutations based on corruption
- If corruption < 35: add clean mutation card
- If corruption > 20: add void mutation card
- These go in slot 1 (weapon slot), replacing the weapon perk

Mutation card:
```gdscript
{type="mutation", mutation_type="clean", rarity="legendary", icon=mut.clean.icon,
 label=mut.clean.name, desc=mut.clean.desc, perk={}}
```

In _on_upgrade_chosen match:
```
"mutation":
    main_weapon.mutated = true
    main_weapon.mutation_type = choice.mutation_type
    main_weapon.level = 6
    _apply_mutation(main_weapon.id, choice.mutation_type)
```

`_apply_mutation(wid: String, mtype: String)`:
- sidearm clean: mods fire_rate_add to halve rate, mods damage_bonus = main_weapon damage * 2, mods range_mult = 1.5, mods instant_after_reload = true
- sidearm void: mods fragment_on_hit = true
- scatter clean: mods tight_cone = true, mods piercing = true, mods pierce_count = 2
- scatter void: mods chaos_spray = true, mods self_chip = true
- lance clean: mods fire_rate to 2x faster, mods slow_field_on_land = true
- lance void: mods singularity_on_hit = true
- baton clean: mods arc_fields = true
- baton void: mods consuming_vortex = true
- dart clean: mods smart_missile = true
- dart void: mods parasite = true

Wire mutation effects in _update_weapons and _update_bullets:
- fragment_on_hit: on bullet hit, create 3 angled bullets (±30, ±150 deg) with 50% damage, lifetime 0.3, no fragment flag
- singularity_on_hit: on bullet land/hit, create gravity_well at impact pos (radius 200, timer 2.0)
- smart_missile: when firing dart pattern with smart_missile, fire 1 bullet: damage=15, radius=12, speed=120, homing=true, lifetime=4.0, mag costs 1
- chaos_spray: when firing scatter with chaos_spray, spread = 270 degrees, fire 8 pellets evenly. After firing, if any enemy within 40px: player_hp -= 1
- slow_field_on_land: when lance bullet expires or hits something, create smoke_zone at final pos (radius=80, timer=3.0) that slows enemies (add "slowing" flag to smoke_zone, enemies inside get speed * 0.5)
- consuming_vortex: when baton fires with consuming_vortex, AOE expands over 1.5s (animate radius from base to base+100), each enemy hit drains 0.5 HP and heals player 0.5 HP per tick
- arc_fields: when baton fires, also place a slow smoke_zone (radius=80, timer=3.0, slowing=true) at player_pos
- parasite: dart bullets with parasite=true: on hit enemy, set enemy.parasite_timer=4.0, enemy.parasite_dmg=1.0/s (enemy loses 1 HP/s for 4s). On parasite-killed enemy death, find nearest living enemy within 150px, set parasite_timer=4.0 on it. Track in _update_enemies.
- instant_after_reload: already have next_shot_crit flag — set main_weapon cooldown_timer = 0 on next shot instead of crit

---

## 6. LEVEL-UP CARD GENERATION REWORK

Rewrite _generate_upgrades to always produce exactly 3 slots:

Slot 1 — WEAPON:
- If level >= 5 and not mutated and WEAPON_MUTATIONS has weapon id: return mutation card(s) based on corruption
- If level < 5: return named weapon perk (existing WEAPON_LEVEL_PERKS logic)
- If level > 5 and mutated: return a "Mastery" card — for Pass 1 just offer a stat bonus card: {type="modifier", ...} with label "Mastery: [weapon name]" and a small bonus (e.g. +2 damage, described as mastery perk)

Slot 2 — KIT OR MODIFIER:
- Check if any equipped kit has tier < 3 (compare kit_tiers[kit_id] vs 3)
- If yes: offer kit tier upgrade card (stub for Pass 1 — show tier 2 description but just apply a small stat bonus when chosen, full T2 comes in Pass 2)
- If no: draw a modifier from RUN_MODIFIERS not in modifiers_taken

Slot 3 — MODIFIER:
- Always draw from RUN_MODIFIERS not in modifiers_taken, different from slot 2

Handle kit_tier card in _on_upgrade_chosen:
```
"kit_tier":
    var kit_id = choice.kit_id
    var new_tier = choice.new_tier
    if kit_tiers.has(kit_id):
        kit_tiers[kit_id] = new_tier
    else:
        kit_tiers[kit_id] = new_tier
    # Apply a generic bonus for Pass 1
    player_max_hp += 1
    _show_message(KIT_DEFS[kit_id].name + " upgraded to Tier 2!")
```

---

## 7. SAVE DATA UPDATES

In save_data.gd, add these fields:
```gdscript
var equipped_kits: Array[String] = ["stim_pack", "flash_trap"]
var kit_tiers: Dictionary = {"stim_pack": 1, "flash_trap": 1}
var unlocked_kits: Array[String] = ["stim_pack", "flash_trap"]
```

Add to to_dict():
```gdscript
"equipped_kits": equipped_kits.duplicate(),
"kit_tiers": kit_tiers.duplicate(),
"unlocked_kits": unlocked_kits.duplicate(),
```

Add to from_dict():
```gdscript
var raw_kits: Variant = data.get("equipped_kits", [])
if raw_kits is Array:
    equipped_kits.clear()
    for k in raw_kits: equipped_kits.append(str(k))
if equipped_kits.is_empty(): equipped_kits = ["stim_pack", "flash_trap"]

var raw_kit_tiers: Variant = data.get("kit_tiers", {})
if raw_kit_tiers is Dictionary: kit_tiers = (raw_kit_tiers as Dictionary).duplicate()
if kit_tiers.is_empty(): kit_tiers = {"stim_pack": 1, "flash_trap": 1}

var raw_unlocked_kits: Variant = data.get("unlocked_kits", [])
if raw_unlocked_kits is Array:
    unlocked_kits.clear()
    for k in raw_unlocked_kits: unlocked_kits.append(str(k))
if unlocked_kits.is_empty(): unlocked_kits = ["stim_pack", "flash_trap"]
```

In game_data.gd, add:
```gdscript
var equipped_kits: Array[String] = ["stim_pack", "flash_trap"]
var kit_tiers: Dictionary = {}
```

---

## 8. LOADOUT SCREEN

In loadout.gd, add a kit display section after the weapon section:
- Title: "Equipped Kits:"
- Show kit slot 1 and slot 2 with their names from KIT_DEFS (load from SaveData)
- For Pass 1: just display current equipped kits, no swapping UI yet
- Pass that info to GameData in _on_go_hunt:

```gdscript
GameData.equipped_kits = SaveManager.data.equipped_kits.duplicate()
GameData.kit_tiers = SaveManager.data.kit_tiers.duplicate()
```

---

## IMPORTANT CONSTRAINTS
- No .tscn changes
- No nested call_deferred
- Keep WASM-safe patterns
- All existing features must still work (enemies, elites, caves, rivers, etc.)
- Preserve save compatibility — use .get() with defaults everywhere
- weapon_mods dict key "sidearm" still works (internal key unchanged)
- Do NOT use single quotes inside GDScript string literals — use double quotes always
- Check for unmatched quotes/brackets before finishing

When completely done, run:
openclaw system event --text "Done: Space Hunter v23 single weapon kit system mutations run modifiers XP curve" --mode now
