# Pass 2 Build Task — Space Hunter v24

Read ALL of these files fully before making any changes:
- scripts/hunt.gd
- scripts/loadout.gd
- scripts/ship_hub.gd
- scripts/game_data.gd
- scripts/save_data.gd
- scripts/save_manager.gd

This is Pass 2 of a major refactor. Pass 1 (v23) already built:
- Single main weapon system
- 14 kits at T1
- Weapon mutations at Lv5
- Run modifier pool (18 modifiers)
- XP curve 20/35/55

Pass 2 adds: Kit T2/T3 tiers with full effects, Mastery perks post-mutation, Resonance perks post-T3,
2 new weapons (Pulse Cannon + Chain Rifle), Ship Hub kit shop, Loadout kit swapping.

---

## 1. KIT T2 AND T3 FULL EFFECTS

Each kit has 3 tiers. T1 is already built. Add T2 and T3 effects.

T3 is a fork: player picks clean or void variant. T3 clean/void is stored in save as kit_t3_choices[kit_id] = "clean" or "void".

Add to save_data.gd:
```gdscript
var kit_t3_choices: Dictionary = {}  # kit_id -> "clean" or "void"
```
Update to_dict/from_dict accordingly.

### T2 effects (apply when kit_tiers[kit_id] >= 2, checked in _activate_kit and update funcs):

- stim_pack T2: cooldown reduced to 5s (was 8s). Also restores 1 extra HP (5 total).
- flash_trap T2: traps chain — if 2 traps within 300px, triggering one triggers both. Implement: when trap triggers, check all other traps within 300px and trigger them too.
- blink_kit T2: blink leaves a stun field at origin pos (stun all enemies within 100px for 1.5s at departure point). Implement: after teleport, add aoe_flash + stun all enemies within 100px of old_pos.
- chain_kit T2: tether arcs to a second enemy automatically (find second nearest enemy within 200px of first target, apply stunned_timer=3.0 to it too).
- charge_kit T2: full charge deals 6 damage + knockback (was 2 damage). Also: can hold longer — detect hold duration, full charge = held >= 1.5s.
- mirage_kit T2: decoy explodes when it dies or timer ends — AOE 40px, 3 damage to all enemies within 40px of decoy pos. Implement in _update_decoys: on timer expire or hp<=0, add aoe explosion.
- turret_kit T2: turret fires in burst mode — 3 shots then 0.5s pause. Track burst_count on turret dict. Also turret lasts 20s (was 12s).
- smoke_kit T2: smoke slows enemies 40% while inside (add slowing=true to smoke zone, apply in _update_smoke: enemies inside get speed * 0.6 this frame).
- anchor_kit T2: beacon pulses twice (4s pull, 1s pause, 4s pull again). Track pulse_phase on gravity_well dict.
- drone_kit T2: player picks path at first T2 upgrade (stored in kit_t3_choices as pre-T3 choice? No — T2 path choice is separate). Add kit_t2_paths[kit_id] = "attack"|"shield"|"harvest" to save_data.
  - attack path: drone fires 2 dmg shots at nearest enemy every 2s (add drone_fire_timer var)
  - shield path: intercept cooldown 2s instead of 4s, also intercepts melee hits (if enemy within 30px of drone_pos: enemy gets pushed back 60px)
  - harvest path: auto-collects essence and ingredients within 200px of drone_pos; 20% chance to duplicate ingredient drops
- familiar_kit T2: familiar attacks — rams nearest enemy for 2 dmg every 2s (reduce from 3s). Also corruption generation every 6s (was 8s).
- pack_kit T2: summon 4 allies (was 2). Allies have pack behavior speed bonus.
- void_surge T2: void surge now emits void aura during burst — damages all enemies within 100px of player for 1 dmg/s during the 3s burst.
- rupture_kit T2: rupture leaves a void pool behind at player_pos (add to void_pools array, radius=80, timer=15.0 for this run-instance pool).

### T3 effects (apply when kit_tiers[kit_id] >= 3, check kit_t3_choices for clean/void):

- stim_pack:
  - clean: stim also gives +20% speed for 5s (add stim_speed_timer var)
  - void: stim cooldown resets on elite kill (track in _on_enemy_killed)

- flash_trap:
  - clean: trapped enemies take +40% damage for 5s after stun (add enemy.marked_timer = 5.0, in bullet hit: if e.marked_timer > 0: damage *= 1.4)
  - void: traps erupt with void energy — enemies within 120px gain 10 corruption, become faster +20% for 3s

- blink_kit:
  - clean: after blink, next shot deals 3x damage (add blink_empowered: bool = false, set true on blink, consume on next shot)
  - void: blink pulls all enemies within 150px WITH you (teleport nearby enemies to new player_pos + random offset 40px)

- chain_kit:
  - clean: chained enemies take +50% damage from all sources (use marked_timer / marked_dmg_bonus)
  - void: tethered enemies drain 2 HP/s into corruption bar (add to _update_enemies: if e.stunned_timer > 0 and has chain_drain: corruption += 2 * delta, player_hp -= 1 per 2s? No — just: for tethered enemies: corruption += 1 * delta)

- charge_kit:
  - clean: knockback distance doubles, enemies stunned 1s after landing
  - void: instead of knockback, you dash forward 300px dealing 3 dmg to everything in path

- mirage_kit:
  - clean: 3 decoys at once (spawn 3 instead of 1)
  - void: decoy is a corruption mirror — enemies near it take void damage 1/s and deal 20% damage to each other (add decoy.void_mirror=true, in _update_decoys: enemies near void_mirror decoy lose hp 1/s)

- turret_kit:
  - clean: turret gains shield (10 hp before dying), lasts 25s
  - void: turret fires void rounds — enemies killed by turret explode 30px AOE chain

- smoke_kit:
  - clean: player moves 50% faster inside own smoke
  - void: smoke is toxic — enemies take 1 dmg/s inside, player gains +3 corruption/s inside

- anchor_kit:
  - clean: beacon emits damage field while pulling — 1 dmg/s to all enemies inside
  - void: after pull ends, beacon explodes for 3 dmg per enemy that was inside (track enemy count during pull)

- drone_kit T3 (builds on T2 path):
  - attack path T3: drone copies your weapon pattern at 50% damage (fire drone bullet when you fire)
  - shield path T3: drone becomes floating barrier — blocks 1 full elite charge once per 30s (track drone_barrier_timer)
  - harvest path T3: guaranteed pristine drops when corruption < 25 (set in ingredient drop logic)

- familiar_kit:
  - clean: familiar absorbs your corruption — corruption gain rate -30% while familiar active (apply in all corruption += lines)
  - void: at corruption >= 60, familiar splits into 2 (add familiar2_active, familiar2_pos vars)

- pack_kit:
  - clean: summoned allies explode on death for 25px AOE 2 dmg (track ally indices, on death add explosion)
  - void: allies drain 5 HP total from player over 15s (player_hp -= 5.0/15.0 per second while allies alive, but allies never die from timer — only from damage)

- void_surge:
  - T3 clean: void surge is free at 60+ corruption (no cost)
  - T3 void: void surge also fires a ring of 8 bullets outward at activation

- rupture_kit:
  - clean: enemies killed in rupture blast drop double ingredients (set a flag rupture_active for this frame, in _on_enemy_killed if rupture_active: drop 2 ingredient pickups)
  - void: rupture leaves permanent void pool at player_pos (add to void_pools with timer=9999)

---

## 2. MASTERY PERKS (post-mutation weapon depth)

When main_weapon.mutated == true and main_weapon.level > 5, weapon slot in level-up shows mastery perks.

Add WEAPON_MASTERY constant:

```gdscript
const WEAPON_MASTERY: Dictionary = {
    "sidearm": {
        "clean": [
            {id="killcam",      icon="K", name="Killcam",      desc="After a kill: next shot fires instantly (no cooldown)."},
            {id="headhunter",   icon="H", name="Headhunter",   desc="+50% damage vs elites."},
            {id="suppressor",   icon="S", name="Suppressor",   desc="Shots don't aggro nearby undetected enemies."},
            {id="armor_pierce", icon="A", name="Armor Pierce", desc="Ignore corrupted-path armor on hit."},
            {id="marksman_reload", icon="R", name="Quick Draw", desc="Reload time -50% for Marksman Rifle."},
        ],
        "void": [
            {id="fragment_magnet", icon="M", name="Fragment Magnet", desc="Fragments home slightly toward nearest enemy."},
            {id="cascade",        icon="C", name="Cascade",          desc="Fragments can fragment once more on hit."},
            {id="entropy_field",  icon="E", name="Entropy Field",    desc="Each fragment leaves a 0.5s damage patch."},
            {id="overheat",       icon="V", name="Overheat",         desc="Every 10th shot fires 2x fragments automatically."},
        ],
    },
    "scatter": {
        "clean": [
            {id="tight_spread",  icon="T", name="Tight Spread",  desc="Cone narrows further, +1 pellet."},
            {id="stagger",       icon="S", name="Stagger",       desc="Each pellet has 15% chance to stun 0.5s."},
            {id="glass_cannon",  icon="G", name="Glass Cannon",  desc="+3 pellet damage, -2 max HP."},
            {id="penetrator",    icon="P", name="Penetrator",    desc="Pellets pierce 1 additional enemy."},
        ],
        "void": [
            {id="feedback",      icon="F", name="Feedback",     desc="Self-chip damage heals at 2x rate."},
            {id="swarm_chaos",   icon="W", name="Swarm Chaos",  desc="Pellets bounce off walls once."},
            {id="contagion",     icon="C", name="Contagion",    desc="Enemies hit by chaos spread 5 corruption to nearby."},
            {id="frenzy",        icon="V", name="Frenzy",       desc="Each enemy in 40px increases fire rate 10%."},
        ],
    },
    "lance": {
        "clean": [
            {id="slow_field_persist", icon="P", name="Persistent Field", desc="Slow fields last 5s (was 3s)."},
            {id="chain_null",         icon="C", name="Chain Null",       desc="Null Spear pierces 2 enemies."},
            {id="aimed_shot",         icon="A", name="Aimed Shot",       desc="Lance damage +50% if player is standing still."},
            {id="field_expand",       icon="E", name="Field Expand",     desc="Slow field radius +40px."},
        ],
        "void": [
            {id="nested_vortex",  icon="N", name="Nested Vortex",  desc="Gravity vortex pulls enemies 50% faster."},
            {id="vortex_damage",  icon="D", name="Vortex Damage",  desc="+50% damage to pulled enemies (stacks)."},
            {id="chain_vortex",   icon="C", name="Chain Vortex",   desc="Killing a pulled enemy spawns mini vortex."},
            {id="void_attractor", icon="V", name="Void Attractor", desc="Vortex lasts 1s longer."},
        ],
    },
    "baton": {
        "clean": [
            {id="field_chain",   icon="C", name="Field Chain",   desc="Arc fields chain to nearest enemy (jump dmg)."},
            {id="field_persist", icon="P", name="Field Persist", desc="Arc fields last 5s (was 3s)."},
            {id="wide_arc",      icon="W", name="Wide Arc",      desc="AOE radius +40px."},
            {id="static_charge", icon="S", name="Static Charge", desc="3rd baton hit in 3s: free AOE pulse."},
        ],
        "void": [
            {id="vortex_speed",  icon="V", name="Vortex Speed",  desc="Vortex expansion 50% faster."},
            {id="deep_drain",    icon="D", name="Deep Drain",    desc="Drain heals +1 HP per 2 enemies."},
            {id="overload_void", icon="O", name="Overload",      desc="Full vortex expansion fires a shockwave."},
            {id="hunger_field",  icon="H", name="Hunger Field",  desc="Vortex zone pulls enemies inward."},
        ],
    },
    "dart": {
        "clean": [
            {id="missile_burst",  icon="B", name="Missile Burst",  desc="On elite kill: fire 2 smart missiles instantly."},
            {id="tracking_plus",  icon="T", name="Tracking Plus",  desc="Missile tracking speed +50%."},
            {id="payload",        icon="P", name="Payload",        desc="Missile explodes on impact 50px AOE."},
            {id="multi_lock",     icon="M", name="Multi-Lock",     desc="Every 3rd missile fires 2 simultaneously."},
        ],
        "void": [
            {id="rapid_spread",   icon="R", name="Rapid Spread",  desc="Parasite spreads to 2 enemies on death."},
            {id="toxic_cloud",    icon="C", name="Toxic Cloud",   desc="Parasite death leaves a 3s poison cloud."},
            {id="deep_parasite",  icon="D", name="Deep Parasite", desc="Parasite duration 6s (was 4s)."},
            {id="void_latch",     icon="V", name="Void Latch",    desc="Parasitized enemies deal 20% less damage."},
        ],
    },
}
```

Add vars:
```gdscript
var mastery_taken: Array[String] = []
```

In _generate_upgrades slot 1, when main_weapon.mutated:
- Get mastery pool: WEAPON_MASTERY[main_weapon.id][main_weapon.mutation_type]
- Filter out mastery_taken ids
- Pick one randomly
- Return as card: {type="mastery", id=perk.id, rarity="rare", icon=perk.icon, label=perk.name, desc=perk.desc}

In _on_upgrade_chosen "mastery":
- mastery_taken.append(choice.id)
- Apply effect via _apply_mastery_perk(choice.id)

`_apply_mastery_perk(perk_id: String)`:
Wire the ones that are stat-based via weapon_mods or player vars:
- killcam: weapon_mods[main_weapon.id]["killcam"] = true (check in _on_enemy_killed: if killcam: main_weapon.cooldown_timer = 0)
- headhunter: weapon_mods["_player"]["elite_dmg_bonus"] = get("elite_dmg_bonus",1.0) + 0.5
- suppressor: weapon_mods[main_weapon.id]["suppressor"] = true (in bullet hit vs non-aggroed: skip aggro trigger)
- armor_pierce: weapon_mods[main_weapon.id]["armor_pierce"] = true
- marksman_reload: weapon_mods[main_weapon.id]["reload_mult"] = get("reload_mult",1.0) * 0.5
- fragment_magnet: weapon_mods[main_weapon.id]["fragment_homing"] = true
- cascade: weapon_mods[main_weapon.id]["fragment_cascade"] = true
- overheat: weapon_mods[main_weapon.id]["overheat_counter"] = 0 (track shots, every 10 = double fragments)
- tight_spread: weapon_mods[main_weapon.id]["extra_pellets"] = get + 1; reduce spread angle by 50%
- stagger: weapon_mods[main_weapon.id]["stagger_chance"] = 0.15
- glass_cannon: weapon_mods[main_weapon.id]["damage_bonus"] = get + 3; player_max_hp -= 2; player_hp = min(player_hp, player_max_hp)
- penetrator: weapon_mods[main_weapon.id]["pierce_count"] = get("pierce_count",2) + 1
- slow_field_persist: weapon_mods[main_weapon.id]["slow_field_duration"] = 5.0
- chain_null: weapon_mods[main_weapon.id]["pierce_count"] = get + 1
- aimed_shot: weapon_mods[main_weapon.id]["aimed_shot"] = true (in _update_weapons: track player_moved_this_frame, if not moved: damage * 1.5)
- field_expand: weapon_mods[main_weapon.id]["radius_bonus"] = get + 40
- nested_vortex: weapon_mods[main_weapon.id]["vortex_speed"] = 1.5
- vortex_damage: weapon_mods["_player"]["vortex_dmg_bonus"] = get + 0.5
- vortex_persist: already handled via gravity_well timer
- wide_arc: weapon_mods[main_weapon.id]["radius_bonus"] = get + 40
- static_charge: weapon_mods[main_weapon.id]["static_charge"] = true (track baton_hit_count, every 3 hits in 3s: free AOE)
- vortex_speed_baton: similar to nested_vortex
- deep_drain: weapon_mods[main_weapon.id]["leech_bonus"] = true (heals +1 per 2 enemies instead of per enemy)
- missile_burst: weapon_mods[main_weapon.id]["missile_burst"] = true (in _on_enemy_killed if elite: fire 2 missiles)
- tracking_plus: weapon_mods[main_weapon.id]["tracking_mult"] = get * 1.5
- payload: weapon_mods[main_weapon.id]["explode_on_hit"] = true
- multi_lock: weapon_mods[main_weapon.id]["multi_lock_counter"] = 0
- rapid_spread: weapon_mods[main_weapon.id]["parasite_spread_count"] = 2
- deep_parasite: weapon_mods[main_weapon.id]["parasite_duration"] = 6.0
- void_latch: weapon_mods[main_weapon.id]["void_latch"] = true (parasitized enemy takes -20% damage dealt to player — wait, re-read: "deal 20% less damage" means enemy.latch_dmg_reduce = 0.8, apply in enemy melee and bullet damage)
- toxic_cloud: weapon_mods[main_weapon.id]["toxic_cloud"] = true (on parasite death: add smoke_zone with slowing=true, dmg=1/s at that position)
For complex effects not easily wired, store the flag and add a TODO comment — do not leave the game broken, just skip the effect silently.

---

## 3. RESONANCE PERKS (cross-kit combos, post-T3)

Resonance perks appear in level-up slot 2 when BOTH kit slots have T3. They bridge two kits.

Add RESONANCE_POOL constant (10 perks, each requires 2 specific kits at T3):

```gdscript
const RESONANCE_POOL: Array[Dictionary] = [
    {id="linked_fuse",    kits=["flash_trap","blink_kit"],   icon="L", name="Linked Fuse",    desc="Blink teleports you to nearest triggered trap."},
    {id="sympathetic_fire", kits=["drone_kit","blink_kit"],  icon="S", name="Sympathetic Fire", desc="Drone fires when you fire, not on timer."},
    {id="overcharge_drone", kits=["drone_kit","anchor_kit"], icon="O", name="Overcharge",      desc="Drone fires 2x faster after anchor well expires."},
    {id="trap_aggro",     kits=["flash_trap","mirage_kit"],  icon="T", name="Trap Aggro",      desc="Decoy automatically moves toward nearest trap."},
    {id="void_feedback",  kits=["void_surge","rupture_kit"], icon="V", name="Void Feedback",   desc="Rupture recharges void surge instantly."},
    {id="familiar_bond",  kits=["familiar_kit","pack_kit"],  icon="F", name="Familiar Bond",   desc="Familiar buffs your summoned allies (+30% speed)."},
    {id="smoke_blink",    kits=["smoke_kit","blink_kit"],    icon="B", name="Smoke Step",      desc="Blink always lands in a smoke cloud."},
    {id="turret_familiar",kits=["turret_kit","familiar_kit"],icon="U", name="Familiar Link",   desc="Turret gains familiar healing aura (1 HP regen/5s to player while turret active)."},
    {id="chain_anchor",   kits=["chain_kit","anchor_kit"],   icon="C", name="Gravity Chain",   desc="Tethered enemies are also pulled by anchor wells."},
    {id="surge_charge",   kits=["void_surge","charge_kit"],  icon="X", name="Surge Charge",    desc="Void surge resets charge kit cooldown instantly."},
]
var resonance_taken: Array[String] = []
```

In _generate_upgrades slot 2, if both kits have T3:
- Find available resonance perks where both required kits are in equipped_kits
- Filter out resonance_taken
- If any available: offer as kit_tier card with type="resonance"

In _on_upgrade_chosen "resonance":
- resonance_taken.append(choice.id)
- Store flag: weapon_mods["_resonance"] dict, set resonance id = true

Wire key resonance effects:
- linked_fuse: in blink activation, after teleport check if any trap within 400px — if yes, teleport to nearest trap pos instead
- void_feedback: in rupture activation, after rupture: kit_states["void_surge"]["cooldown"] = 0
- smoke_blink: in blink activation, spawn smoke_zone at new player_pos after blink
- surge_charge: in void_surge activation: kit_states["charge_kit"]["cooldown"] = 0
- sympathetic_fire: in _update_weapons when player fires, also fire drone bullet if drone_kit equipped and T3
- overcharge_drone: in _update_gravity_wells when well expires: if drone_kit equipped: drone_intercept_timer = 0 for 5s (store overcharge_timer)
Other resonance effects: store flag, apply passively where easy, skip complex ones gracefully.

---

## 4. TWO NEW WEAPONS

Add to WEAPON_DEFS:
```gdscript
"pulse_cannon": {name="Pulse Cannon", desc="Charge to release knockback blast.", fire_rate=1.4, damage=5, bullet_speed=0.0, bullet_radius=120.0, color=Color(0.3,0.8,1.0), range=120.0, pattern="pulse"},
"chain_rifle":  {name="Chain Rifle",  desc="Bullet arcs between nearby enemies.", fire_rate=0.6, damage=3, bullet_speed=380.0, bullet_radius=6.0, color=Color(0.2,1.0,0.4), range=380.0, pattern="chain_shot"},
```

Add weapon perks for each in WEAPON_LEVEL_PERKS:
```gdscript
"pulse_cannon": {
    2: {icon="W", name="Wide Pulse",    desc="Blast radius +40px", effect="radius", value=40.0},
    3: {icon="D", name="Damage Core",   desc="+3 damage", effect="damage", value=3},
    4: {icon="S", name="Stun Pulse",    desc="Enemies hit are stunned 1s", effect="stun_pulse", value=true},
    5: {icon="C", name="Charge Ready",  desc="Charge time -30%", effect="fire_rate", value=-0.42},
},
"chain_rifle": {
    2: {icon="B", name="Extra Arc",     desc="+1 bounce", effect="chain_bounces", value=1},
    3: {icon="D", name="Charged Arcs",  desc="+2 damage", effect="damage", value=2},
    4: {icon="A", name="Arc Damage",    desc="+30% damage per bounce", effect="arc_damage_ramp", value=true},
    5: {icon="F", name="Full Chain",    desc="+1 bounce, fire rate +20%", effect="chain_final", value=0.0},
},
```

Add mutations:
```gdscript
"pulse_cannon": {
    "clean": {icon="R", name="Repulsor Field", desc="Release creates a 400px force wall lasting 2s. Nothing passes it."},
    "void":  {icon="I", name="Collapse Shot",  desc="Implosion: sucks enemies 200px inward 1.5s, then burst."},
},
"chain_rifle": {
    "clean": {icon="C", name="Arc Conductor",  desc="Each bounce increases damage 30%. Max 5 bounces."},
    "void":  {icon="P", name="Plague Round",   desc="Bullet spreads corruption debuff each bounce. Enemies take +20% dmg and emit void aura."},
},
```

Add mastery pools for new weapons in WEAPON_MASTERY:
```gdscript
"pulse_cannon": {
    "clean": [
        {id="wall_persist",  icon="W", name="Wall Persist",  desc="Repulsor wall lasts 4s (was 2s)."},
        {id="wall_damage",   icon="D", name="Wall Damage",   desc="Enemies touching wall take 1 dmg/s."},
        {id="bounce_back",   icon="B", name="Bounce Back",   desc="Wall reflects enemy bullets."},
        {id="double_wall",   icon="X", name="Double Wall",   desc="Fire creates 2 perpendicular walls."},
    ],
    "void": [
        {id="deep_collapse", icon="D", name="Deep Collapse", desc="Implosion range +80px."},
        {id="burst_chain",   icon="C", name="Burst Chain",   desc="Burst after implosion chains to 3 enemies."},
        {id="void_vortex",   icon="V", name="Void Vortex",   desc="Implosion creates a gravity well."},
        {id="collapse_amp",  icon="A", name="Collapse Amp",  desc="+2 damage per enemy pulled in."},
    ],
},
"chain_rifle": {
    "clean": [
        {id="arc_persist",   icon="P", name="Arc Persist",   desc="+2 max bounces."},
        {id="arc_stun",      icon="S", name="Arc Stun",      desc="Final bounce stuns 0.8s."},
        {id="conductor",     icon="C", name="Conductor",     desc="+50% damage on last bounce."},
        {id="chain_reload",  icon="R", name="Chain Reload",  desc="5-bounce kill: instant reload."},
    ],
    "void": [
        {id="plague_persist",icon="P", name="Plague Persist",desc="Corruption debuff lasts 6s (was 3s)."},
        {id="plague_spread", icon="S", name="Plague Spread", desc="Debuffed enemies spread to 1 nearby."},
        {id="plague_burst",  icon="B", name="Plague Burst",  desc="Debuffed enemy death: small void AOE."},
        {id="void_charge",   icon="V", name="Void Charge",   desc="+15% corruption gain from plague rounds."},
    ],
},
```

Wire pulse_cannon pattern in _update_weapons:
- "pulse" pattern: works like melee_aoe but has a charge mechanic
  - When firing with pattern=="pulse": if weapon_mods has "pulse_charged"=true: do full pulse (radius from def.range + radius_bonus, damage, knockback all enemies); clear pulse_charged; else: set pulse_charged=true after 1.0s charge (track with pulse_charge_timer on main_weapon or in weapon_mods). Actually simpler: just fire the AOE blast immediately but with base damage. The "charge" upgrade just reduces cooldown.
  - Pulse fires as AOE: deal damage to all enemies in radius, add aoe_flash, push enemies away from player 120px

Wire chain_rifle pattern in _update_weapons:
- "chain_shot" pattern: fire a bullet. When that bullet hits an enemy, bounce to nearest OTHER enemy within 200px, deal same damage. Track bounces_left on bullet dict (default 2, upgradeable). Each bounce reduces bounces_left. On final bounce: consume bullet.
- In _update_bullets: after player chain_shot bullet hits enemy, if b.bounces_left > 0: find nearest living enemy within 200px that b.hit_ids does not contain; teleport bullet to that enemy pos - dir*20; reduce bounces_left; add hit_id.
- arc_damage_ramp: if mastery taken, each bounce: damage *= 1.3

Add mutations wire:
- pulse_cannon clean (repulsor_field): on fire, place a "wall" struct: a line perpendicular to fire direction, 400px wide, 2s duration. In _update_bullets: bullets from enemies that cross this wall are destroyed. In enemy movement: enemies cannot move through wall (add wall collision check). Store in `var walls: Array[Dictionary] = []`, each wall: {pos, dir_perp, length, timer}
- pulse_cannon void (collapse_shot): on fire, create gravity_well at nearest enemy pos (radius=200, timer=1.5, implode=true). After timer: big AOE burst (damage = 3 * enemies_pulled_in_count).
- chain_rifle clean (arc_conductor): arc_damage_ramp * 1.3 per bounce as above
- chain_rifle void (plague_round): bullets with plague=true: on each bounce hit, set enemy.plagued_timer=3.0, enemy.plagued=true. In _update_enemies: if e.plagued_timer > 0: e.plagued_timer -= delta; enemy emits void aura (corruption aura like void creatures). Plagued enemies take +20% damage (check in _update_bullets: if e.get("plagued",false): damage *= 1.2).

---

## 5. SHIP HUB KIT SHOP TAB

Add a third tab "KITS" to ship_hub.gd (alongside SHIP and UPGRADES).

Kit shop displays:
- All 14 kits with unlock cost
- For owned kits: show current tier and upgrade cost to T2/T3
- For T3: show a fork choice (clean vs void) — on click, sets kit_t3_choices[kit_id] and upgrades tier to 3

UNLOCK_COSTS:
```gdscript
const KIT_UNLOCK_COSTS: Dictionary = {
    "stim_pack": 0, "flash_trap": 0,
    "blink_kit": 120, "chain_kit": 150, "charge_kit": 120, "mirage_kit": 180,
    "turret_kit": 150, "smoke_kit": 100, "anchor_kit": 180,
    "drone_kit": 200, "familiar_kit": 160, "pack_kit": 180,
    "void_surge": 220, "rupture_kit": 250,
}
const KIT_TIER_COSTS: Dictionary = {
    "stim_pack": [0,60,120], "flash_trap": [0,80,160],
    "blink_kit": [120,100,200], "chain_kit": [150,120,220], "charge_kit": [120,100,200],
    "mirage_kit": [180,140,260], "turret_kit": [150,120,220], "smoke_kit": [100,80,180],
    "anchor_kit": [180,150,280], "drone_kit": [200,150,300], "familiar_kit": [160,130,250],
    "pack_kit": [180,150,280], "void_surge": [220,180,320], "rupture_kit": [250,200,380],
}
```

Kit rows in shop:
- Show kit name, description, current tier (if owned)
- "Unlock" button if not owned (costs unlock price)
- "Upgrade T2" button if owned and tier < 2
- "Upgrade T3 (Clean)" and "Upgrade T3 (Void)" buttons if tier == 2 (both shown side by side)
- "MAXED" if tier == 3

Also add: equipped kit display at top of kit tab — show "Slot 1: [kit]  Slot 2: [kit]" with swap buttons.
Tapping an unlocked kit while a slot is highlighted assigns it. Simple: tap kit row to put in slot 1, long-press (or a toggle button) for slot 2. Actually simplest: two "assign to slot 1/2" buttons on each kit row when owned.

Save: kit ownership = kit in unlocked_kits. Tier in kit_tiers. T3 fork in kit_t3_choices.
T2 path for drone (attack/shield/harvest) stored in kit_t2_paths.

Add to save_data.gd:
```gdscript
var kit_t3_choices: Dictionary = {}
var kit_t2_paths: Dictionary = {}  # kit_id -> "attack"|"shield"|"harvest"
```

---

## 6. LOADOUT SCREEN KIT SWAPPING

In loadout.gd, upgrade the kit section:
- Show 2 kit slots with currently equipped kit names and tiers
- Button per slot: "Change" — opens inline kit picker (show unlocked kits as a scrollable list)
- Selecting from list assigns to that slot
- Show kit tier and short description

Pass to GameData on GO HUNT:
```gdscript
GameData.equipped_kits = [slot1_kit, slot2_kit]
GameData.kit_tiers = SaveManager.data.kit_tiers.duplicate()
GameData.kit_t3_choices = SaveManager.data.kit_t3_choices.duplicate()
GameData.kit_t2_paths = SaveManager.data.kit_t2_paths.duplicate()
```

Add to game_data.gd:
```gdscript
var kit_t3_choices: Dictionary = {}
var kit_t2_paths: Dictionary = {}
```

In hunt.gd _ready: load kit_t3_choices and kit_t2_paths from GameData.

---

## IMPORTANT CONSTRAINTS
- No .tscn changes
- No nested call_deferred
- Keep WASM-safe patterns
- All existing v23 features must still work
- Preserve save compatibility — use .get() with defaults everywhere
- Do NOT use single quotes inside GDScript string literals — use double quotes always
- For complex effects that are hard to wire cleanly: store the flag/mod, apply a basic version, and add a comment. Do not break the game trying to wire every edge case perfectly.
- Keep hunt.gd compiling cleanly — test with godot --check-only if available

When completely done, run:
openclaw system event --text "Done: Space Hunter v24 kit T2/T3, mastery, resonance, pulse cannon, chain rifle, kit shop" --mode now
