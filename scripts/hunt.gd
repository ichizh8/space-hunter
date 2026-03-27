extends Control

# === World ===
const WORLD_W := 4800
const WORLD_H := 4800
const GRID_STEP := 300

# === Weapon definitions ===
const WEAPON_DEFS: Dictionary = {
	"sidearm": {name="Pistol", desc="Reliable semi-auto. Good range.", fire_rate=0.35, damage=3, bullet_speed=400.0, bullet_radius=5.0, color=Color(1.0,0.9,0.2), range=350.0, pattern="single"},
	"scatter": {name="Scatter Pistol", desc="3-pellet cone. Shreds packs.", fire_rate=0.7, damage=2, bullet_speed=380.0, bullet_radius=4.0, color=Color(1.0,0.5,0.1), range=220.0, pattern="scatter"},
	"lance": {name="Void Lance", desc="Slow piercing shot. Hits all in line.", fire_rate=1.2, damage=6, bullet_speed=280.0, bullet_radius=7.0, color=Color(0.5,0.1,1.0), range=500.0, pattern="piercing"},
	"baton": {name="Shock Baton", desc="Melee AOE pulse. Damages all within 100px.", fire_rate=0.8, damage=4, bullet_speed=0.0, bullet_radius=100.0, color=Color(0.1,0.8,1.0), range=100.0, pattern="melee_aoe"},
	"dart": {name="Homing Dart", desc="Slow seeking projectile.", fire_rate=0.9, damage=3, bullet_speed=200.0, bullet_radius=5.0, color=Color(0.2,1.0,0.5), range=400.0, pattern="homing"},
	"pulse_cannon": {name="Pulse Cannon", desc="Charge to release knockback blast.", fire_rate=1.4, damage=5, bullet_speed=0.0, bullet_radius=120.0, color=Color(0.3,0.8,1.0), range=120.0, pattern="pulse"},
	"chain_rifle": {name="Chain Rifle", desc="Bullet arcs between nearby enemies.", fire_rate=0.6, damage=3, bullet_speed=380.0, bullet_radius=6.0, color=Color(0.2,1.0,0.4), range=380.0, pattern="chain_shot"},
}

# Per-weapon level-up perks: each level 2-5 has a named perk with icon + description
# Applied in _on_upgrade_chosen, effects tracked via player stat modifiers
const WEAPON_LEVEL_PERKS: Dictionary = {
	"sidearm": {
		2: {icon="⚡", name="Hair Trigger", desc="Fire rate +25%", effect="fire_rate", value=-0.09},
		3: {icon="🎯", name="Hollow Point", desc="+2 damage per shot", effect="damage", value=2},
		4: {icon="💥", name="Overpressure", desc="Bullets pierce 1 enemy", effect="piercing", value=true},
		5: {icon="🌀", name="Rapid Fire", desc="Fire rate +40%, mag +6", effect="fire_rate_mag", value=0.0},
	},
	"scatter": {
		2: {icon="↔", name="Wide Bore", desc="Cone spread +30%, 1 extra pellet", effect="pellets", value=1},
		3: {icon="💥", name="Buckshot", desc="+1 damage per pellet", effect="damage", value=1},
		4: {icon="🔥", name="Incendiary", desc="Pellets slow enemies 20% for 1s", effect="slow", value=true},
		5: {icon="🌪", name="Salvo", desc="Fire rate +30%, 2 extra pellets", effect="pellets_rate", value=0.0},
	},
	"lance": {
		2: {icon="⚡", name="Charged Shot", desc="Projectile speed +30%", effect="bullet_speed", value=84.0},
		3: {icon="💎", name="Void Core", desc="+3 damage", effect="damage", value=3},
		4: {icon="🌀", name="Overload", desc="On kill: fires a 2nd lance automatically", effect="on_kill_lance", value=true},
		5: {icon="💥", name="Singularity", desc="Explosion on impact, 60px AOE", effect="explode", value=true},
	},
	"baton": {
		2: {icon="↔", name="Extended Arc", desc="AOE radius +30px", effect="radius", value=30.0},
		3: {icon="💥", name="Shockwave", desc="+2 damage, knocks enemies back", effect="damage_knockback", value=2},
		4: {icon="❤", name="Life Leech", desc="Each enemy hit restores 0.5 HP", effect="leech", value=true},
		5: {icon="⚡", name="Chain Lightning", desc="Damage arcs to 2 additional enemies", effect="chain", value=true},
	},
	"dart": {
		2: {icon="🎯", name="Lock-On", desc="Tracking speed +50%", effect="tracking", value=1.5},
		3: {icon="💥", name="Detonator", desc="Explodes on hit, 40px AOE", effect="explode", value=true},
		4: {icon="🐍", name="Swarm", desc="Fires 2 darts simultaneously", effect="dual", value=true},
		5: {icon="💀", name="Voidseeker", desc="On kill: splits into 2 new darts", effect="split_on_kill", value=true},
	},
	"pulse_cannon": {
		2: {icon="W", name="Wide Pulse", desc="Blast radius +40px", effect="radius", value=40.0},
		3: {icon="D", name="Damage Core", desc="+3 damage", effect="damage", value=3},
		4: {icon="S", name="Stun Pulse", desc="Enemies hit are stunned 1s", effect="stun_pulse", value=true},
		5: {icon="C", name="Charge Ready", desc="Charge time -30%", effect="fire_rate", value=-0.42},
	},
	"chain_rifle": {
		2: {icon="B", name="Extra Arc", desc="+1 bounce", effect="chain_bounces", value=1},
		3: {icon="D", name="Charged Arcs", desc="+2 damage", effect="damage", value=2},
		4: {icon="A", name="Arc Damage", desc="+30% damage per bounce", effect="arc_damage_ramp", value=true},
		5: {icon="F", name="Full Chain", desc="+1 bounce, fire rate +20%", effect="chain_final", value=0.0},
	},
}

# Run modifiers — drawn randomly, no repeats per run
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
var mastery_taken: Array[String] = []
var resonance_taken: Array[String] = []

# Weapon mutations
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
	"pulse_cannon": {
		"clean": {icon="R", name="Repulsor Field", desc="Release creates a 400px force wall lasting 2s. Nothing passes it."},
		"void":  {icon="I", name="Collapse Shot",  desc="Implosion: sucks enemies 200px inward 1.5s, then burst."},
	},
	"chain_rifle": {
		"clean": {icon="C", name="Arc Conductor",  desc="Each bounce increases damage 30%. Max 5 bounces."},
		"void":  {icon="P", name="Plague Round",   desc="Bullet spreads corruption debuff each bounce. Enemies take +20% dmg and emit void aura."},
	},
}

# Kit definitions
const KIT_DEFS: Dictionary = {
	"stim_pack":    {name="Stim",     icon="S", desc="T1: +4 HP, +15 corruption. 20s cooldown."},
	"flash_trap":   {name="Trap",     icon="T", desc="T1: 25 dmg + slow. 3 charges, recharge 25s."},
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

# Weapon mastery perks (post-mutation)
const WEAPON_MASTERY: Dictionary = {
	"sidearm": {
		"clean": [
			{id="killcam", icon="K", name="Killcam", desc="After a kill: next shot fires instantly (no cooldown)."},
			{id="headhunter", icon="H", name="Headhunter", desc="+50% damage vs elites."},
			{id="suppressor", icon="S", name="Suppressor", desc="Shots do not aggro nearby undetected enemies."},
			{id="armor_pierce", icon="A", name="Armor Pierce", desc="Ignore corrupted-path armor on hit."},
			{id="marksman_reload", icon="R", name="Quick Draw", desc="Reload time -50% for Marksman Rifle."},
		],
		"void": [
			{id="fragment_magnet", icon="M", name="Fragment Magnet", desc="Fragments home slightly toward nearest enemy."},
			{id="cascade", icon="C", name="Cascade", desc="Fragments can fragment once more on hit."},
			{id="entropy_field", icon="E", name="Entropy Field", desc="Each fragment leaves a 0.5s damage patch."},
			{id="overheat", icon="V", name="Overheat", desc="Every 10th shot fires 2x fragments automatically."},
		],
	},
	"scatter": {
		"clean": [
			{id="tight_spread", icon="T", name="Tight Spread", desc="Cone narrows further, +1 pellet."},
			{id="stagger", icon="S", name="Stagger", desc="Each pellet has 15% chance to stun 0.5s."},
			{id="glass_cannon", icon="G", name="Glass Cannon", desc="+3 pellet damage, -2 max HP."},
			{id="penetrator", icon="P", name="Penetrator", desc="Pellets pierce 1 additional enemy."},
		],
		"void": [
			{id="feedback", icon="F", name="Feedback", desc="Self-chip damage heals at 2x rate."},
			{id="swarm_chaos", icon="W", name="Swarm Chaos", desc="Pellets bounce off walls once."},
			{id="contagion", icon="C", name="Contagion", desc="Enemies hit by chaos spread 5 corruption to nearby."},
			{id="frenzy", icon="V", name="Frenzy", desc="Each enemy in 40px increases fire rate 10%."},
		],
	},
	"lance": {
		"clean": [
			{id="slow_field_persist", icon="P", name="Persistent Field", desc="Slow fields last 5s (was 3s)."},
			{id="chain_null", icon="C", name="Chain Null", desc="Null Spear pierces 2 enemies."},
			{id="aimed_shot", icon="A", name="Aimed Shot", desc="Lance damage +50% if player is standing still."},
			{id="field_expand", icon="E", name="Field Expand", desc="Slow field radius +40px."},
		],
		"void": [
			{id="nested_vortex", icon="N", name="Nested Vortex", desc="Gravity vortex pulls enemies 50% faster."},
			{id="vortex_damage", icon="D", name="Vortex Damage", desc="+50% damage to pulled enemies (stacks)."},
			{id="chain_vortex", icon="C", name="Chain Vortex", desc="Killing a pulled enemy spawns mini vortex."},
			{id="void_attractor", icon="V", name="Void Attractor", desc="Vortex lasts 1s longer."},
		],
	},
	"baton": {
		"clean": [
			{id="field_chain", icon="C", name="Field Chain", desc="Arc fields chain to nearest enemy (jump dmg)."},
			{id="field_persist", icon="P", name="Field Persist", desc="Arc fields last 5s (was 3s)."},
			{id="wide_arc", icon="W", name="Wide Arc", desc="AOE radius +40px."},
			{id="static_charge", icon="S", name="Static Charge", desc="3rd baton hit in 3s: free AOE pulse."},
		],
		"void": [
			{id="vortex_speed", icon="V", name="Vortex Speed", desc="Vortex expansion 50% faster."},
			{id="deep_drain", icon="D", name="Deep Drain", desc="Drain heals +1 HP per 2 enemies."},
			{id="overload_void", icon="O", name="Overload", desc="Full vortex expansion fires a shockwave."},
			{id="hunger_field", icon="H", name="Hunger Field", desc="Vortex zone pulls enemies inward."},
		],
	},
	"dart": {
		"clean": [
			{id="missile_burst", icon="B", name="Missile Burst", desc="On elite kill: fire 2 smart missiles instantly."},
			{id="tracking_plus", icon="T", name="Tracking Plus", desc="Missile tracking speed +50%."},
			{id="payload", icon="P", name="Payload", desc="Missile explodes on impact 50px AOE."},
			{id="multi_lock", icon="M", name="Multi-Lock", desc="Every 3rd missile fires 2 simultaneously."},
		],
		"void": [
			{id="rapid_spread", icon="R", name="Rapid Spread", desc="Parasite spreads to 2 enemies on death."},
			{id="toxic_cloud", icon="C", name="Toxic Cloud", desc="Parasite death leaves a 3s poison cloud."},
			{id="deep_parasite", icon="D", name="Deep Parasite", desc="Parasite duration 6s (was 4s)."},
			{id="void_latch", icon="V", name="Void Latch", desc="Parasitized enemies deal 20% less damage."},
		],
	},
	"pulse_cannon": {
		"clean": [
			{id="wall_persist", icon="W", name="Wall Persist", desc="Repulsor wall lasts 4s (was 2s)."},
			{id="wall_damage", icon="D", name="Wall Damage", desc="Enemies touching wall take 1 dmg/s."},
			{id="bounce_back", icon="B", name="Bounce Back", desc="Wall reflects enemy bullets."},
			{id="double_wall", icon="X", name="Double Wall", desc="Fire creates 2 perpendicular walls."},
		],
		"void": [
			{id="deep_collapse", icon="D", name="Deep Collapse", desc="Implosion range +80px."},
			{id="burst_chain", icon="C", name="Burst Chain", desc="Burst after implosion chains to 3 enemies."},
			{id="void_vortex", icon="V", name="Void Vortex", desc="Implosion creates a gravity well."},
			{id="collapse_amp", icon="A", name="Collapse Amp", desc="+2 damage per enemy pulled in."},
		],
	},
	"chain_rifle": {
		"clean": [
			{id="arc_persist", icon="P", name="Arc Persist", desc="+2 max bounces."},
			{id="arc_stun", icon="S", name="Arc Stun", desc="Final bounce stuns 0.8s."},
			{id="conductor", icon="C", name="Conductor", desc="+50% damage on last bounce."},
			{id="chain_reload", icon="R", name="Chain Reload", desc="5-bounce kill: instant reload."},
		],
		"void": [
			{id="plague_persist", icon="P", name="Plague Persist", desc="Corruption debuff lasts 6s (was 3s)."},
			{id="plague_spread", icon="S", name="Plague Spread", desc="Debuffed enemies spread to 1 nearby."},
			{id="plague_burst", icon="B", name="Plague Burst", desc="Debuffed enemy death: small void AOE."},
			{id="void_charge", icon="V", name="Void Charge", desc="+15% corruption gain from plague rounds."},
		],
	},
}

# Resonance perks (cross-kit combos, post-T3)
const RESONANCE_POOL: Array[Dictionary] = [
	{id="linked_fuse", kits=["flash_trap","blink_kit"], icon="L", name="Linked Fuse", desc="Blink teleports you to nearest triggered trap."},
	{id="sympathetic_fire", kits=["drone_kit","blink_kit"], icon="S", name="Sympathetic Fire", desc="Drone fires when you fire, not on timer."},
	{id="overcharge_drone", kits=["drone_kit","anchor_kit"], icon="O", name="Overcharge", desc="Drone fires 2x faster after anchor well expires."},
	{id="trap_aggro", kits=["flash_trap","mirage_kit"], icon="T", name="Trap Aggro", desc="Decoy automatically moves toward nearest trap."},
	{id="void_feedback", kits=["void_surge","rupture_kit"], icon="V", name="Void Feedback", desc="Rupture recharges void surge instantly."},
	{id="familiar_bond", kits=["familiar_kit","pack_kit"], icon="F", name="Familiar Bond", desc="Familiar buffs your summoned allies (+30% speed)."},
	{id="smoke_blink", kits=["smoke_kit","blink_kit"], icon="B", name="Smoke Step", desc="Blink always lands in a smoke cloud."},
	{id="turret_familiar", kits=["turret_kit","familiar_kit"], icon="U", name="Familiar Link", desc="Turret gains familiar healing aura (1 HP regen/5s to player while turret active)."},
	{id="chain_anchor", kits=["chain_kit","anchor_kit"], icon="C", name="Gravity Chain", desc="Tethered enemies are also pulled by anchor wells."},
	{id="surge_charge", kits=["void_surge","charge_kit"], icon="X", name="Surge Charge", desc="Void surge resets charge kit cooldown instantly."},
]

# Runtime weapon modifiers (applied to WEAPON_DEFS at fire time)
var weapon_mods: Dictionary = {}  # weapon_id -> {fire_rate_mult, damage_bonus, extra_pellets, piercing, slow, etc.}

# === Player ===
var player_pos := Vector2(2400.0, 2400.0)
var player_hp := 10
var player_max_hp := 10
var player_speed := 180.0
const PLAYER_RADIUS := 16.0

# === Single main weapon ===
var main_weapon: Dictionary = {}
# {id, level, cooldown_timer, mag_ammo, mag_size, reload_timer, mutated, mutation_type}

# === Bullets ===
# {pos, vel, radius, color, damage, lifetime, from_player}
var bullets: Array[Dictionary] = []

# === Obstacles ===
# {pos: Vector2, radius: float}
var obstacles: Array[Dictionary] = []

# === Enemies ===
var enemies: Array[Dictionary] = []
var enemy_melee_cooldowns: Dictionary = {} # enemy index -> float

# === Pickups ===
# {pos, type, color, ingredient_data} for ingredients
# {pos, type} for essence
var pickups: Array[Dictionary] = []

# === Ingredient pickups (Phase 3 — pristine quality) ===
var ingredient_pickups: Array[Dictionary] = []

# === Float texts (ingredient drop labels) ===
var float_texts: Array[Dictionary] = []

# === AOE flashes ===
var aoe_flashes: Array[Dictionary] = []

# === Essence collect radius ===
var essence_collect_radius: float = 60.0

# === Contract tracking ===
var target_kills := 0   # elites killed
var target_total := 0   # elites required
var contract_type := ""

# === Wave system (infinite) ===
var wave_current := 0
var wave_timer := 0.0
var hunt_elapsed := 0.0   # total seconds in hunt
const WAVE_INTERVAL_START := 20.0
const WAVE_INTERVAL_MIN   := 8.0

# === Elite system ===
var elite_timer := 0.0
var elite_interval := 0.0   # set on ready: 180-300s
var elite_spawned_count := 0
const ELITE_TYPES: Array = ["Void Hulk", "Phase Hunter", "Brood Mother"]

# === Ingredients collected ===
var run_ingredients: Array[Dictionary] = []

# === Void essence / leveling ===
var essence_collected := 0
var player_level := 1

# === Exit zone ===
var exit_spawned := false
var exit_pos := Vector2.ZERO

# === Camera ===
var camera_offset := Vector2.ZERO

# === Joystick ===
var joy_active := false
var joy_base := Vector2.ZERO
var joy_knob := Vector2.ZERO
var joy_touch_index := -1
const JOY_MAX_DIST := 60.0

# === Corruption ===
var corruption: float = 0.0
var corruption_max: float = 100.0  # visual cap for bar, not hard cap
var corruption_threshold_35 := false
var corruption_threshold_60 := false
var corruption_prev_threshold: int = 0  # 0=CLEAN, 1=VALLEY, 2=CORRUPT, 3=VOID

# === XP curve ===
var xp_threshold: int = 20

# === Kit system ===
var equipped_kits: Array[String] = []
var kit_states: Dictionary = {}
var kit_tiers: Dictionary = {}
var kit_button_rects: Array[Rect2] = []

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
var familiar2_active: bool = false
var familiar2_pos: Vector2 = Vector2.ZERO
var kit_t3_choices: Dictionary = {}
var kit_t2_paths: Dictionary = {}
var drone_fire_timer: float = 0.0
var stim_speed_timer: float = 0.0
var blink_empowered: bool = false
var walls: Array[Dictionary] = []
var overcharge_timer: float = 0.0
var drone_barrier_timer: float = 0.0
var pack_allies: Array[int] = []
var baton_hit_count: int = 0
var baton_hit_timer: float = 0.0

# === Modifier runtime state ===
var adrenaline_stack: int = 0
var adrenaline_last_kill_time: float = 0.0
var momentum_stack: int = 0
var next_shot_crit: bool = false
var player_start_biome: String = ""

# === Game state ===
var paused := false
var dead := false
var dead_timer := 0.0
var hunt_complete := false

# === Perk runtime state ===
var player_hit_flash: float = 0.0
var kill_streak_count: int = 0
var speed_boost_timer: float = 0.0
var leech_accumulator: float = 0.0

# === HUD message ===
var hud_message := ""
var hud_message_timer := 0.0

# === Environments ===
var rivers: Array[Dictionary] = []
var bridges: Array[Dictionary] = []
var caves: Array[Dictionary] = []
var void_pools: Array[Dictionary] = []
var player_in_cave: int = -1

# === Upgrade panel ===
var upgrade_choices: Array[Dictionary] = []
var upgrade_buttons: Array = [] # Node references

# === Creature data ===
const CREATURE_DEFS: Dictionary = {
	# charge: runs straight at player — dumb, fast, cannon fodder
	"Void Leech": {radius = 12, color = Color(0.8, 0.2, 0.2), speed = 100, hp = 3, detection = 280, melee_dmg = 1, ranged = false, void_type = false, behavior = "charge"},
	# flank: tries to circle and approach from the side
	"Shadow Crawler": {radius = 13, color = Color(0.5, 0.1, 0.7), speed = 110, hp = 3, detection = 300, melee_dmg = 1, ranged = false, void_type = false, behavior = "flank"},
	# burst: slow patrol, then sudden 2.5x speed lunge, pauses after
	"Abyss Worm": {radius = 14, color = Color(0.3, 0.6, 0.1), speed = 65, hp = 6, detection = 320, melee_dmg = 2, ranged = false, void_type = false, behavior = "burst"},
	# strafe: ranged, sidesteps perpendicular to player while shooting
	"Nether Stalker": {radius = 12, color = Color(0.2, 0.4, 0.9), speed = 70, hp = 4, detection = 360, melee_dmg = 0, ranged = true, ranged_dmg = 2, ranged_cooldown = 1.4, void_type = false, behavior = "strafe"},
	# pack: faster when allies are nearby, swarming behavior
	"Rift Parasite": {radius = 11, color = Color(0.9, 0.5, 0.1), speed = 100, hp = 4, detection = 300, melee_dmg = 1, ranged = false, void_type = true, behavior = "pack"},
	# lurker: dormant in caves until triggered
	"Cave Lurker": {radius = 15, color = Color(0.25, 0.15, 0.35), speed = 140, hp = 8, detection = 999, melee_dmg = 3, ranged = false, void_type = false, behavior = "lurker"},
	# patrol_river: patrols river banks, ranged
	"Tide Wraith": {radius = 12, color = Color(0.1, 0.5, 0.8), speed = 120, hp = 5, detection = 340, melee_dmg = 0, ranged = true, ranged_dmg = 2, ranged_cooldown = 1.6, void_type = false, behavior = "patrol_river"},
	# pack: void swarm near void pools
	"Void Spawn": {radius = 11, color = Color(0.6, 0.0, 0.9), speed = 95, hp = 4, detection = 280, melee_dmg = 1, ranged = false, void_type = true, behavior = "pack"},
}

const CREATURE_INGREDIENTS: Dictionary = {
	"Void Leech": {id = "ingredient_void_extract", name = "Void Extract", symbol = "V", uses = 1, ingredient = true},
	"Shadow Crawler": {id = "ingredient_shadow_membrane", name = "Shadow Membrane", symbol = "S", uses = 1, ingredient = true},
	"Abyss Worm": {id = "ingredient_abyss_flesh", name = "Abyss Flesh", symbol = "A", uses = 1, ingredient = true},
	"Nether Stalker": {id = "ingredient_nether_bile", name = "Nether Bile", symbol = "N", uses = 1, ingredient = true},
	"Rift Parasite": {id = "ingredient_rift_spore", name = "Rift Spore", symbol = "R", uses = 1, ingredient = true},
	"Cave Lurker": {id = "ingredient_cave_crystal", name = "Cave Crystal", symbol = "C", uses = 1, ingredient = true},
	"Tide Wraith": {id = "ingredient_tide_essence", name = "Tide Essence", symbol = "T", uses = 1, ingredient = true},
	"Void Spawn": {id = "ingredient_void_core", name = "Void Core", symbol = "W", uses = 1, ingredient = true},
}

const INGREDIENT_COLORS: Dictionary = {
	"ingredient_void_extract": Color(0.8, 0.2, 0.2),
	"ingredient_shadow_membrane": Color(0.5, 0.1, 0.7),
	"ingredient_abyss_flesh": Color(0.3, 0.6, 0.1),
	"ingredient_nether_bile": Color(0.2, 0.4, 0.9),
	"ingredient_rift_spore": Color(0.9, 0.5, 0.1),
	"ingredient_cave_crystal": Color(0.25, 0.15, 0.35),
	"ingredient_tide_essence": Color(0.1, 0.5, 0.8),
	"ingredient_void_core": Color(0.6, 0.0, 0.9),
}

const PRISTINE_NAMES: Dictionary = {
	"void_extract": "Void Extract (Pure)",
	"shadow_membrane": "Shadow Membrane (Intact)",
	"abyss_flesh": "Abyss Flesh (Raw)",
	"nether_bile": "Nether Bile (Distilled)",
	"rift_spore": "Rift Spore",
}

const BIOME_ENEMY_POOLS: Dictionary = {
	"open":       ["Void Leech", "Nether Stalker", "Shadow Crawler"],
	"river_bank": ["Abyss Worm", "Tide Wraith", "Nether Stalker"],
	"cave":       ["Cave Lurker", "Shadow Crawler"],
	"void_pool":  ["Rift Parasite", "Void Spawn", "Void Leech"],
}


# =========================================================
# READY
# =========================================================
func _ready() -> void:
	# Parse contract
	var contract: Dictionary = GameData.current_contract
	contract_type = contract.get("creature_type", "Void Leech")
	var depth: int = contract.get("depth", 1)
	target_total = 3 + depth

	# Apply ship upgrades
	var hp_bonus: int = SaveManager.data.ship_upgrades.get("max_hp", 0) * 2
	player_max_hp = 10 + hp_bonus
	player_hp = player_max_hp

	var mag_bonus: int = SaveManager.data.ship_upgrades.get("mag_size", 0) * 3
	var xp_bonus: float = SaveManager.data.ship_upgrades.get("xp_rate", 0) * 0.1
	essence_collect_radius = 60.0 + (60.0 * xp_bonus)

	# Starting weapon from loadout
	var wid: String = GameData.starting_weapon
	if wid.is_empty() or not WEAPON_DEFS.has(wid): wid = "sidearm"
	var is_melee_type: bool = wid == "baton" or wid == "pulse_cannon"
	var base_mag: int = 999 if is_melee_type else 12
	main_weapon = {id=wid, level=1, cooldown_timer=0.0, mag_ammo=base_mag+mag_bonus, mag_size=base_mag+mag_bonus, reload_timer=0.0, mutated=false, mutation_type=""}

	# XP curve
	xp_threshold = _xp_needed_for_level(1)

	# Kit system
	equipped_kits = GameData.equipped_kits.duplicate()
	kit_tiers = GameData.kit_tiers.duplicate()
	kit_t3_choices = GameData.kit_t3_choices.duplicate()
	kit_t2_paths = GameData.kit_t2_paths.duplicate()
	for kid in equipped_kits:
		kit_states[kid] = _init_kit_state(kid)

	# Elite interval: first elite at 3-5 min (shorter at higher depth)
	elite_interval = randf_range(90.0 - depth * 15.0, 150.0 - depth * 15.0)
	elite_timer = elite_interval
	wave_timer = WAVE_INTERVAL_START

	_spawn_obstacles()
	_generate_rivers()
	_generate_bridges()
	_add_river_obstacles()
	_generate_caves()
	_generate_void_pools()
	_spawn_biome_enemies()
	_spawn_wave(depth)

	player_start_biome = _get_biome_at(player_pos)

	# Activate passive kits
	for kid in equipped_kits:
		if kid == "drone_kit":
			drone_active = true
			drone_pos = player_pos + Vector2(50, 0)
		elif kid == "familiar_kit":
			familiar_active = true
			familiar_pos = player_pos + Vector2(60, 0)

	set_process_input(true)
	queue_redraw()

# =========================================================
# SPAWN
# =========================================================
func _spawn_obstacles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(70):
		var r: float = rng.randf_range(20.0, 45.0)
		var pos := Vector2.ZERO
		for _try in range(20):
			pos = Vector2(rng.randf_range(r, WORLD_W - r), rng.randf_range(r, WORLD_H - r))
			# avoid center spawn area 600x600
			if abs(pos.x - 2400.0) > 300.0 or abs(pos.y - 2400.0) > 300.0:
				break
		obstacles.append({pos = pos, radius = r})

func _generate_rivers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var river_width := 50.0
	var center := Vector2(2400.0, 2400.0)

	# River 1: left to right
	var r1_start := Vector2(0.0, rng.randf_range(1000.0, 3800.0))
	var r1_end := Vector2(4800.0, rng.randf_range(1000.0, 3800.0))
	var r1_waypoints: Array[Vector2] = [r1_start]
	var r1_count: int = rng.randi_range(4, 6)
	for wi in range(r1_count):
		var t: float = float(wi + 1) / float(r1_count + 1)
		var base: Vector2 = r1_start.lerp(r1_end, t)
		var perp := Vector2(0.0, rng.randf_range(-400.0, 400.0))
		var wp: Vector2 = base + perp
		# Push away from center spawn area
		if wp.distance_to(center) < 500.0:
			wp = center + (wp - center).normalized() * 520.0
		wp.x = clampf(wp.x, 0.0, 4800.0)
		wp.y = clampf(wp.y, 0.0, 4800.0)
		r1_waypoints.append(wp)
	r1_waypoints.append(r1_end)

	# River 2: top to bottom
	var r2_start := Vector2(rng.randf_range(1000.0, 3800.0), 0.0)
	var r2_end := Vector2(rng.randf_range(1000.0, 3800.0), 4800.0)
	var r2_waypoints: Array[Vector2] = [r2_start]
	var r2_count: int = rng.randi_range(4, 6)
	for wi in range(r2_count):
		var t: float = float(wi + 1) / float(r2_count + 1)
		var base: Vector2 = r2_start.lerp(r2_end, t)
		var perp := Vector2(rng.randf_range(-400.0, 400.0), 0.0)
		var wp: Vector2 = base + perp
		if wp.distance_to(center) < 500.0:
			wp = center + (wp - center).normalized() * 520.0
		wp.x = clampf(wp.x, 0.0, 4800.0)
		wp.y = clampf(wp.y, 0.0, 4800.0)
		r2_waypoints.append(wp)
	r2_waypoints.append(r2_end)

	# Build segment circles for each river
	for waypoints in [r1_waypoints, r2_waypoints]:
		var segs: Array[Dictionary] = []
		for si in range(waypoints.size() - 1):
			var a: Vector2 = waypoints[si]
			var b: Vector2 = waypoints[si + 1]
			var seg_len: float = a.distance_to(b)
			var steps: int = maxi(1, int(seg_len / 50.0))
			for step in range(steps + 1):
				var tf: float = float(step) / float(steps)
				segs.append({pos = a.lerp(b, tf), radius = 25.0})
		rivers.append({points = waypoints, width = river_width, segments = segs})

func _generate_bridges() -> void:
	for ri in range(rivers.size()):
		var river: Dictionary = rivers[ri]
		var pts: Array = river.points
		var mid_idx: int = pts.size() / 2
		var bridge_pos: Vector2 = (Vector2(pts[mid_idx - 1].x, pts[mid_idx - 1].y) + Vector2(pts[mid_idx].x, pts[mid_idx].y)) * 0.5
		var bridge_dir: Vector2 = (Vector2(pts[mid_idx].x, pts[mid_idx].y) - Vector2(pts[mid_idx - 1].x, pts[mid_idx - 1].y)).normalized()
		bridges.append({pos = bridge_pos, dir = bridge_dir, width = 50.0, length = 180.0})

func _add_river_obstacles() -> void:
	# Rivers are NOT physical walls — they are slow/corruption zones only.
	# No obstacles added. Players and enemies can walk through water freely.
	# Walking in water: corruption gain + speed penalty applied in _process.
	pass

func _generate_caves() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var center := Vector2(2400.0, 2400.0)
	for ci in range(3):
		var pos := Vector2.ZERO
		var valid := false
		for _try in range(50):
			pos = Vector2(rng.randf_range(200.0, 4600.0), rng.randf_range(200.0, 4600.0))
			if pos.distance_to(center) < 600.0:
				continue
			var too_close := false
			for c in caves:
				if pos.distance_to(Vector2(c.pos.x, c.pos.y)) < 400.0:
					too_close = true
					break
			if too_close:
				continue
			# Check distance from rivers
			var near_river := false
			for river in rivers:
				for seg in river.segments:
					if pos.distance_to(Vector2(seg.pos.x, seg.pos.y)) < 200.0:
						near_river = true
						break
				if near_river:
					break
			if near_river:
				continue
			valid = true
			break
		if not valid:
			pos = center + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized() * 800.0
		caves.append({pos = pos, radius = rng.randf_range(160.0, 240.0), id = ci})

func _generate_void_pools() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var center := Vector2(2400.0, 2400.0)
	var pool_count: int = rng.randi_range(5, 7)
	for _pi in range(pool_count):
		var pos := Vector2.ZERO
		for _try in range(40):
			pos = Vector2(rng.randf_range(100.0, 4700.0), rng.randf_range(100.0, 4700.0))
			if pos.distance_to(center) < 300.0:
				continue
			var too_close := false
			for c in caves:
				if pos.distance_to(Vector2(c.pos.x, c.pos.y)) < 200.0:
					too_close = true
					break
			if not too_close:
				break
		void_pools.append({pos = pos, radius = rng.randf_range(60.0, 110.0), pulse_phase = rng.randf() * TAU})

func _spawn_biome_enemies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Pre-place Cave Lurkers in each cave
	for cave in caves:
		var count: int = rng.randi_range(3, 4)
		for _ci in range(count):
			var offset := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized() * rng.randf_range(20.0, cave.radius * 0.7)
			_spawn_single_enemy("Cave Lurker", false, rng)
			enemies[-1].pos = Vector2(cave.pos.x, cave.pos.y) + offset
			enemies[-1].aggro_origin = enemies[-1].pos
			enemies[-1].patrol_target = enemies[-1].pos
			enemies[-1].cave_id = cave.id
			enemies[-1].dormant = true
			enemies[-1].is_aggroed = false
	# Pre-place Void Spawns near each void pool
	for pool in void_pools:
		var count: int = rng.randi_range(3, 5)
		for _vi in range(count):
			var offset := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized() * rng.randf_range(20.0, pool.radius + 40.0)
			_spawn_single_enemy("Void Spawn", false, rng)
			enemies[-1].pos = Vector2(pool.pos.x, pool.pos.y) + offset
			enemies[-1].aggro_origin = enemies[-1].pos
			enemies[-1].patrol_target = enemies[-1].pos
	# Pre-place Tide Wraiths along rivers
	var wraith_count: int = rng.randi_range(4, 6)
	for _wi in range(wraith_count):
		var river: Dictionary = rivers[rng.randi_range(0, rivers.size() - 1)]
		var seg: Dictionary = river.segments[rng.randi_range(0, river.segments.size() - 1)]
		var offset := Vector2(rng.randf_range(-80.0, 80.0), rng.randf_range(-80.0, 80.0))
		_spawn_single_enemy("Tide Wraith", false, rng)
		enemies[-1].pos = Vector2(seg.pos.x, seg.pos.y) + offset
		enemies[-1].pos.x = clampf(enemies[-1].pos.x, 60.0, WORLD_W - 60.0)
		enemies[-1].pos.y = clampf(enemies[-1].pos.y, 60.0, WORLD_H - 60.0)
		enemies[-1].aggro_origin = enemies[-1].pos
		enemies[-1].patrol_target = enemies[-1].pos

func _update_waves(delta: float) -> void:
	if exit_spawned or hunt_complete:
		return

	hunt_elapsed += delta

	# Count living non-elite enemies
	var alive: int = 0
	for e in enemies:
		if e.hp > 0 and not e.get("is_elite", false):
			alive += 1

	# Wave timer shrinks over time — ramps up pressure
	wave_timer -= delta
	var wave_interval: float = maxf(WAVE_INTERVAL_MIN, WAVE_INTERVAL_START - wave_current * 1.5)
	var force_next: bool = wave_timer <= 0.0
	var low_enemies: bool = alive <= 3

	if force_next or low_enemies:
		var depth: int = GameData.current_contract.get("depth", 1)
		_spawn_wave(depth)
		wave_timer = wave_interval

	# Elite timer — spawn one elite at interval, then reset
	elite_timer -= delta
	if elite_timer <= 0.0:
		elite_timer = randf_range(45.0, 70.0)  # subsequent elites every 45-70s
		var depth: int = GameData.current_contract.get("depth", 1)
		_spawn_elite(depth)

func _spawn_wave(depth: int) -> void:
	var living_count: int = 0
	for e in enemies:
		if e.hp > 0:
			living_count += 1
	if living_count > 80:
		return  # dont spawn more until map clears out
	wave_current += 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var types_list: Array = CREATURE_DEFS.keys()

	pass  # no wave announcement — elites announce themselves

	# Filler only — no targets in waves. Ramps: +2 per wave, capped at wave 10.
	var effective_wave: int = min(wave_current, 10)
	var base_fillers: int = 14 + depth * 4
	var filler_count: int = base_fillers + (effective_wave - 1) * 2 + rng.randi_range(0, 2)
	var spawn_start: int = enemies.size()
	for i in range(filler_count):
		# Determine spawn position first, then pick biome-appropriate type
		var spawn_pos := Vector2(rng.randf_range(60.0, WORLD_W - 60.0), rng.randf_range(60.0, WORLD_H - 60.0))
		var biome: String = _get_biome_at(spawn_pos)
		var pool: Array = BIOME_ENEMY_POOLS.get(biome, BIOME_ENEMY_POOLS["open"])
		var ft: String
		if not contract_type.is_empty() and CREATURE_DEFS.has(contract_type) and pool.has(contract_type) and rng.randf() < 0.6:
			ft = contract_type
		else:
			ft = pool[rng.randi_range(0, pool.size() - 1)]
		_spawn_single_enemy(ft, false, rng)

	# Each wave is 8% faster than previous, capped at wave 8
	var speed_mult: float = 1.0 + min(effective_wave - 1, 7) * 0.08
	for i in range(spawn_start, enemies.size()):
		enemies[i].speed *= speed_mult

	# Pre-aggro 60% — most rush immediately
	var new_count: int = enemies.size() - spawn_start
	var aggro_count: int = int(new_count * 0.6)
	for i in range(spawn_start, spawn_start + aggro_count):
		enemies[i].is_aggroed = true
		enemies[i].aggro_origin = enemies[i].pos

func _spawn_elite(depth: int) -> void:
	elite_spawned_count += 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Pick elite type — cycle through types, add some randomness
	var elite_type: String = ELITE_TYPES[(elite_spawned_count - 1) % ELITE_TYPES.size()]
	if rng.randf() < 0.3:
		elite_type = ELITE_TYPES[rng.randi_range(0, ELITE_TYPES.size() - 1)]

	_show_message("⚠ ELITE: %s approaching!" % elite_type)

	# Find a spawn point far from player — must not be walled off by rivers
	var pos := Vector2.ZERO
	for _try in range(60):
		pos = Vector2(rng.randf_range(200.0, WORLD_W - 200.0), rng.randf_range(200.0, WORLD_H - 200.0))
		if pos.distance_to(player_pos) < 350.0:
			continue
		# Check not blocked by obstacles
		var blocked := false
		for obs in obstacles:
			if pos.distance_to(obs.pos) < obs.radius + 30.0:
				blocked = true
				break
		if blocked:
			continue
		# Rivers are no longer obstacles — skip river isolation check
		break

	var hp_scale: float = 1.0 + (depth - 1) * 0.5 + elite_spawned_count * 0.2

	var elite: Dictionary = {
		type = elite_type,
		pos = pos,
		hp = int(20.0 * hp_scale),
		max_hp = int(20.0 * hp_scale),
		speed = 55.0 + depth * 10.0,
		radius = 20.0,
		color = Color(1.0, 0.85, 0.1),  # gold
		detection = 600.0,
		melee_dmg = 2 + depth,
		leash = 9999.0,  # never leash — always hunt
		aggro_origin = pos,
		is_aggroed = true,
		ranged = false,
		ranged_dmg = 0,
		ranged_cooldown_base = 2.0,
		ranged_cooldown_timer = 0.0,
		void_type = false,
		is_target = true,
		is_elite = true,
		elite_type = elite_type,
		patrol_target = pos,
		behavior = "elite",
		# behavior state
		burst_timer = 0.0, burst_active = false, burst_cooldown = 2.0,
		flank_side = 1.0, flank_timer = 1.5,
		strafe_dir = 1.0, strafe_timer = 1.0,
		# elite-specific state
		phase_timer = 0.0,    # Phase Hunter teleport
		brood_triggered = false,  # Brood Mother add spawn
		charge_timer = 0.0,   # Void Hulk slam cooldown
	}
	enemies.append(elite)

func _spawn_single_enemy(type_name: String, is_target: bool, rng: RandomNumberGenerator) -> void:
	var def: Dictionary = CREATURE_DEFS[type_name]
	var pos := Vector2.ZERO
	for _try in range(30):
		pos = Vector2(rng.randf_range(60.0, WORLD_W - 60.0), rng.randf_range(60.0, WORLD_H - 60.0))
		if pos.distance_to(player_pos) < 180.0:
			continue
		var blocked := false
		for obs in obstacles:
			if pos.distance_to(obs.pos) < obs.radius + def.radius + 10.0:
				blocked = true
				break
		if not blocked:
			break

	var enemy: Dictionary = {
		type = type_name,
		pos = pos,
		hp = def.hp,
		max_hp = def.hp,
		speed = float(def.speed),
		radius = float(def.radius),
		color = def.color,
		detection = float(def.detection),
		melee_dmg = def.melee_dmg,
		leash = def.detection * 2.5,
		aggro_origin = pos,
		is_aggroed = false,
		ranged = def.ranged,
		ranged_dmg = def.get("ranged_dmg", 0),
		ranged_cooldown_base = def.get("ranged_cooldown", 2.0),
		ranged_cooldown_timer = 0.0,
		void_type = def.void_type,
		is_target = is_target,
		patrol_target = pos,
		behavior = def.get("behavior", "charge"),
		# burst state
		burst_timer = 0.0,
		burst_active = false,
		burst_cooldown = randf_range(1.5, 3.0),
		# flank state
		flank_side = 1.0 if rng.randi() % 2 == 0 else -1.0,
		flank_timer = randf_range(1.0, 2.5),
		# strafe state
		strafe_dir = 1.0 if rng.randi() % 2 == 0 else -1.0,
		strafe_timer = randf_range(0.8, 1.8),
		# environment fields
		cave_id = -1,
		dormant = type_name == "Cave Lurker",
		# patrol_river state
		patrol_river_timer = randf_range(3.0, 4.0),
		# stun / parasite
		stunned_timer = 0.0,
		parasite_timer = 0.0,
		parasite_dmg = 0.0,
	}
	enemies.append(enemy)

# =========================================================
# INPUT
# =========================================================
func _input(event: InputEvent) -> void:
	if dead or hunt_complete:
		return

	# Upgrade panel clicks handled by buttons
	if paused:
		return

	var vp_size := get_viewport_rect().size
	var half_w: float = vp_size.x * 0.5

	if event is InputEventScreenTouch:
		var te: InputEventScreenTouch = event
		if te.pressed:
			# Kit button tap check
			for ki in range(kit_button_rects.size()):
				if ki < equipped_kits.size() and kit_button_rects[ki].has_point(te.position):
					_activate_kit(equipped_kits[ki])
					return
			# First finger down anywhere starts the joystick at that point
			if not joy_active:
				joy_active = true
				joy_base = te.position
				joy_knob = te.position
				joy_touch_index = te.index
		else:
			if te.index == joy_touch_index:
				joy_active = false
				joy_touch_index = -1

	elif event is InputEventScreenDrag:
		var de: InputEventScreenDrag = event
		if de.index == joy_touch_index and joy_active:
			var diff: Vector2 = de.position - joy_base
			if diff.length() > JOY_MAX_DIST:
				diff = diff.normalized() * JOY_MAX_DIST
			joy_knob = joy_base + diff

	# Keyboard fallback for testing
	# Handled in _process via Input.get_vector

# =========================================================
# PROCESS
# =========================================================
func _process(delta: float) -> void:
	if dead:
		dead_timer -= delta
		if dead_timer <= 0.0:
			_finish_hunt(0)
		queue_redraw()
		return

	if hunt_complete or paused:
		queue_redraw()
		return

	if speed_boost_timer > 0.0:
		speed_boost_timer -= delta
	if player_hit_flash > 0.0:
		player_hit_flash -= delta

	_move_player(delta)
	_update_camera()
	_update_cave_state()
	_update_void_pool_corruption(delta)
	_update_weapons(delta)
	_update_enemies(delta)
	_update_bullets(delta)
	_check_pickups()
	_update_hud_message(delta)
	_update_float_texts(delta)
	_apply_corruption_effects()
	_update_aoe_flashes(delta)
	_update_waves(delta)
	_update_kit_cooldowns(delta)
	_update_traps(delta)
	_update_decoys(delta)
	_update_turrets(delta)
	_update_smoke(delta)
	_update_gravity_wells(delta)
	_update_drone(delta)
	_update_familiar(delta)

	queue_redraw()

func _update_cave_state() -> void:
	player_in_cave = -1
	for cave in caves:
		if player_pos.distance_to(Vector2(cave.pos.x, cave.pos.y)) < cave.radius:
			player_in_cave = cave.id
			break

func _update_void_pool_corruption(delta: float) -> void:
	var fam_corr_mult: float = 0.7 if (familiar_active and kit_tiers.get("familiar_kit", 1) >= 3 and kit_t3_choices.get("familiar_kit", "") == "clean") else 1.0
	for pool in void_pools:
		if player_pos.distance_to(Vector2(pool.pos.x, pool.pos.y)) < pool.radius:
			var resist: float = weapon_mods.get("_player", {}).get("corruption_resist", 0.0)
			corruption += 4.0 * delta * (1.0 - resist) * fam_corr_mult

func _player_in_river() -> bool:
	for ri in range(rivers.size()):
		var bridge_pos: Vector2 = bridges[ri].pos if ri < bridges.size() else Vector2(-9999.0, -9999.0)
		for seg in rivers[ri].segments:
			var sp: Vector2 = Vector2(seg.pos.x, seg.pos.y)
			if sp.distance_to(bridge_pos) < 160.0:
				continue  # bridge gap — not water
			if player_pos.distance_to(sp) < seg.radius + 16.0:
				return true
	return false

func _move_player(delta: float) -> void:
	var move_dir := Vector2.ZERO

	# Joystick
	if joy_active:
		var diff: Vector2 = joy_knob - joy_base
		if diff.length() > 5.0:
			move_dir = diff.normalized()

	# Keyboard fallback
	if move_dir == Vector2.ZERO:
		move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if move_dir == Vector2.ZERO:
		return

	var stats: Dictionary = _get_effective_player_stats()
	var effective_speed: float = player_speed * stats.move_speed_mult
	if speed_boost_timer > 0.0 and weapon_mods.get("_player", {}).get("kill_streak_speed", false):
		effective_speed *= 1.5
	# River water: slow to 50% + 1.5 corruption/s
	var in_water: bool = _player_in_river()
	if in_water:
		effective_speed *= 0.5
		var resist: float = weapon_mods.get("_player", {}).get("corruption_resist", 0.0)
		corruption += 1.5 * delta * (1.0 - resist)
	var velocity: Vector2 = move_dir * effective_speed * delta
	var new_pos: Vector2 = player_pos + velocity

	# Obstacle collision
	for obs in obstacles:
		var dist: float = new_pos.distance_to(obs.pos)
		var min_dist: float = obs.radius + PLAYER_RADIUS
		if dist < min_dist:
			var push: Vector2 = (new_pos - obs.pos).normalized()
			new_pos = obs.pos + push * min_dist

	# World bounds
	new_pos.x = clampf(new_pos.x, PLAYER_RADIUS, WORLD_W - PLAYER_RADIUS)
	new_pos.y = clampf(new_pos.y, PLAYER_RADIUS, WORLD_H - PLAYER_RADIUS)

	player_pos = new_pos

	# Check exit zone
	if exit_spawned and player_pos.distance_to(exit_pos) < 40.0 + PLAYER_RADIUS:
		hunt_complete = true
		_complete_hunt()

func _update_camera() -> void:
	var vp_size := get_viewport_rect().size
	var vp_center: Vector2 = vp_size * 0.5
	camera_offset = player_pos - vp_center
	camera_offset.x = clampf(camera_offset.x, 0.0, WORLD_W - vp_size.x)
	camera_offset.y = clampf(camera_offset.y, 0.0, WORLD_H - vp_size.y)

func _update_weapons(delta: float) -> void:
	if main_weapon.is_empty():
		return
	# Find nearest living enemy
	var nearest_dist := 999999.0
	var nearest_pos := Vector2.ZERO
	var nearest_found := false
	for e in enemies:
		if e.hp <= 0:
			continue
		var d: float = player_pos.distance_to(e.pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest_pos = e.pos
			nearest_found = true

	var corr_stats: Dictionary = _get_effective_player_stats()

	var w: Dictionary = main_weapon
	var def: Dictionary = WEAPON_DEFS[w.id]
	var mods_w: Dictionary = weapon_mods.get(w.id, {})
	var damage: int = int(float(def.damage + (w.level - 1) + mods_w.get("damage_bonus", 0)) * corr_stats.damage_mult)
	var w_piercing: bool = mods_w.get("piercing", def.pattern == "piercing")
	var w_fire_rate: float = maxf(0.1, (def.fire_rate + mods_w.get("fire_rate_add", 0.0)) * corr_stats.fire_rate_mult)
	var w_bullet_speed: float = def.bullet_speed + mods_w.get("bullet_speed_bonus", 0.0)
	var w_extra_pellets: int = mods_w.get("extra_pellets", 0)
	var w_range: float = def.range * corr_stats.range_mult * mods_w.get("range_mult", 1.0)

	# Momentum bullet speed modifier
	if "momentum" in modifiers_taken:
		w_bullet_speed *= (1.0 + momentum_stack * 0.15)

	# Handle reload
	if w.reload_timer > 0.0:
		w.reload_timer -= delta
		if w.reload_timer <= 0.0:
			w.mag_ammo = w.mag_size
			_show_message("Reloaded!")
			if "precision" in modifiers_taken:
				next_shot_crit = true
			if mods_w.get("instant_after_reload", false):
				w.cooldown_timer = 0.0
		main_weapon = w
		return

	# Handle cooldown
	if w.cooldown_timer > 0.0:
		w.cooldown_timer -= delta

	# Out of ammo — start reload
	if w.mag_ammo <= 0 and w.reload_timer <= 0.0:
		var reload_mult: float = mods_w.get("reload_mult", 1.0) * corr_stats.reload_mult
		w.reload_timer = 1.5 * reload_mult
		_show_message("Reloading...")
		main_weapon = w
		return

	# Fire if ready
	if w.cooldown_timer <= 0.0 and w.mag_ammo > 0:
		if not nearest_found or nearest_dist > w_range:
			main_weapon = w
			return

		var dir: Vector2 = (nearest_pos - player_pos).normalized()
		w.cooldown_timer = w_fire_rate

		# Precision crit
		var fire_damage: int = damage
		if next_shot_crit:
			fire_damage = damage * 2
			next_shot_crit = false

		# Smart missile mutation (dart clean)
		if mods_w.get("smart_missile", false) and def.pattern == "homing":
			w.mag_ammo -= 1
			bullets.append({
				pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
				vel = dir * 120.0,
				radius = 12.0,
				color = def.color,
				damage = 15,
				lifetime = 4.0,
				from_player = true,
				homing = true,
				bullet_speed = 120.0,
				weapon_id = w.id,
			})
			main_weapon = w
			return

		# Chaos spray mutation (scatter void)
		if mods_w.get("chaos_spray", false) and def.pattern == "scatter":
			w.mag_ammo -= 1
			var base_angle: float = dir.angle()
			for pi in range(8):
				var angle: float = base_angle + deg_to_rad(float(pi) * 33.75)
				var scatter_dir := Vector2(cos(angle), sin(angle))
				var scatter_b: Dictionary = {
					pos = player_pos + scatter_dir * (PLAYER_RADIUS + 6.0),
					vel = scatter_dir * w_bullet_speed,
					radius = def.bullet_radius,
					color = def.color,
					damage = fire_damage,
					lifetime = w_range / maxf(1.0, w_bullet_speed),
					from_player = true,
					homing = true,
					bullet_speed = w_bullet_speed,
					weapon_id = w.id,
				}
				bullets.append(scatter_b)
			# Self chip damage
			if mods_w.get("self_chip", false):
				for e in enemies:
					if e.hp > 0 and player_pos.distance_to(e.pos) < 40.0:
						player_hp -= 1
						if player_hp <= 0:
							_die()
							return
						break
			main_weapon = w
			return

		match def.pattern:
			"single":
				w.mag_ammo -= 1
				var single_b: Dictionary = {
					pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
					vel = dir * w_bullet_speed,
					radius = def.bullet_radius,
					color = def.color,
					damage = fire_damage,
					lifetime = w_range / maxf(1.0, w_bullet_speed),
					from_player = true,
					piercing = w_piercing,
					hit_ids = [] if w_piercing else [],
					weapon_id = w.id,
				}
				if mods_w.get("explode_on_hit", false):
					single_b["explode"] = true
				if mods_w.get("fragment_on_hit", false):
					single_b["fragment_on_hit"] = true
				bullets.append(single_b)
			"scatter":
				w.mag_ammo -= 1
				var base_angle: float = dir.angle()
				var spread_deg: float = 15.0
				if mods_w.get("tight_cone", false):
					spread_deg = 8.0
				var pellet_angles: Array = [-spread_deg, 0.0, spread_deg]
				for _ep in range(w_extra_pellets):
					pellet_angles.append(randf_range(-spread_deg * 1.5, spread_deg * 1.5))
				for offset_deg in pellet_angles:
					var angle: float = base_angle + deg_to_rad(float(offset_deg))
					var scatter_dir := Vector2(cos(angle), sin(angle))
					var scatter_b: Dictionary = {
						pos = player_pos + scatter_dir * (PLAYER_RADIUS + 6.0),
						vel = scatter_dir * w_bullet_speed,
						radius = def.bullet_radius,
						color = def.color,
						damage = fire_damage,
						lifetime = w_range / maxf(1.0, w_bullet_speed),
						from_player = true,
						weapon_id = w.id,
					}
					if mods_w.get("slow_on_hit", false):
						scatter_b["slow_on_hit"] = true
					if mods_w.get("explode_on_hit", false):
						scatter_b["explode"] = true
					if mods_w.get("piercing", false):
						scatter_b["piercing"] = true
						scatter_b["hit_ids"] = []
						scatter_b["pierce_count"] = mods_w.get("pierce_count", 2)
					bullets.append(scatter_b)
			"piercing":
				w.mag_ammo -= 1
				var pierce_b: Dictionary = {
					pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
					vel = dir * w_bullet_speed,
					radius = def.bullet_radius,
					color = def.color,
					damage = fire_damage,
					lifetime = w_range / maxf(1.0, w_bullet_speed),
					from_player = true,
					piercing = true,
					hit_ids = [],
					weapon_id = w.id,
				}
				if mods_w.get("explode_on_hit", false):
					pierce_b["explode"] = true
				if mods_w.get("slow_field_on_land", false):
					pierce_b["slow_field_on_land"] = true
				if mods_w.get("singularity_on_hit", false):
					pierce_b["singularity_on_hit"] = true
				bullets.append(pierce_b)
			"homing":
				w.mag_ammo -= 1
				var dart_count: int = 2 if mods_w.get("dual_dart", false) else 1
				for _di in range(dart_count):
					var dart_offset := Vector2.ZERO
					if dart_count > 1 and _di == 1:
						dart_offset = Vector2(-dir.y, dir.x) * 10.0
					var dart_b: Dictionary = {
						pos = player_pos + dir * (PLAYER_RADIUS + 6.0) + dart_offset,
						vel = dir * def.bullet_speed,
						radius = def.bullet_radius,
						color = def.color,
						damage = fire_damage,
						lifetime = w_range / def.bullet_speed,
						from_player = true,
						homing = true,
						bullet_speed = def.bullet_speed,
						weapon_id = w.id,
					}
					if mods_w.get("explode_on_hit", false):
						dart_b["explode"] = true
					if mods_w.get("parasite", false):
						dart_b["parasite"] = true
					bullets.append(dart_b)
			"melee_aoe":
				# No bullet — instant AOE damage
				var melee_range: float = def.range + mods_w.get("radius_bonus", 0.0)
				var melee_hits: int = 0
				var melee_hit_indices: Array[int] = []
				# Consuming vortex: expand AOE
				var vortex_active: bool = mods_w.get("consuming_vortex", false)
				if vortex_active:
					melee_range += 100.0
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp <= 0:
						continue
					if player_pos.distance_to(e.pos) < melee_range:
						var apply_dmg: int = fire_damage
						e.hp -= apply_dmg
						melee_hits += 1
						melee_hit_indices.append(ei)
						# Knockback (#5)
						if mods_w.get("knockback", false):
							var push_dir: Vector2 = (e.pos - player_pos).normalized()
							e.pos += push_dir * 80.0
						# Consuming vortex drain
						if vortex_active:
							player_hp = mini(player_hp + 1, player_max_hp)
						enemies[ei] = e
						if e.hp <= 0:
							_on_enemy_killed(ei)
				# Chain lightning (#7)
				if mods_w.get("chain", false):
					for hi in melee_hit_indices:
						var hit_e: Dictionary = enemies[hi]
						if hit_e.hp <= 0:
							continue
						var chain_targets: Array[int] = []
						for ci in range(enemies.size()):
							if ci == hi or enemies[ci].hp <= 0:
								continue
							if melee_hit_indices.has(ci):
								continue
							if hit_e.pos.distance_to(enemies[ci].pos) < 150.0:
								chain_targets.append(ci)
						chain_targets.sort_custom(func(a: int, b: int) -> bool: return hit_e.pos.distance_to(enemies[a].pos) < hit_e.pos.distance_to(enemies[b].pos))
						for ct_idx in range(mini(2, chain_targets.size())):
							var ct: int = chain_targets[ct_idx]
							var ce: Dictionary = enemies[ct]
							ce.hp -= fire_damage
							enemies[ct] = ce
							if ce.hp <= 0:
								_on_enemy_killed(ct)
				# Leech (#6)
				if mods_w.get("leech", false) and melee_hits > 0:
					leech_accumulator += float(melee_hits) * 0.5
					while leech_accumulator >= 1.0:
						leech_accumulator -= 1.0
						player_hp = mini(player_hp + 1, player_max_hp)
				aoe_flashes.append({pos=player_pos, radius=melee_range, timer=0.3, color=Color(0.1,0.8,1.0,0.6)})
				# Arc blade mutation: place slow field
				if mods_w.get("arc_fields", false):
					smoke_zones.append({pos=player_pos, radius=80.0, timer=3.0, slowing=true})
				# Static charge mastery: track hits
				if mods_w.get("static_charge", false):
					baton_hit_count += 1
					baton_hit_timer = 3.0
					if baton_hit_count >= 3:
						baton_hit_count = 0
						aoe_flashes.append({pos=player_pos, radius=melee_range + 40.0, timer=0.3, color=Color(0.3,0.9,1.0,0.6)})
						for ei in range(enemies.size()):
							var e_sc: Dictionary = enemies[ei]
							if e_sc.hp > 0 and player_pos.distance_to(e_sc.pos) < melee_range + 40.0:
								e_sc.hp -= fire_damage
								enemies[ei] = e_sc
								if e_sc.hp <= 0:
									_on_enemy_killed(ei)
			"pulse":
				# Pulse cannon: AOE blast with knockback
				var pulse_range: float = def.range + mods_w.get("radius_bonus", 0.0)
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp <= 0:
						continue
					if player_pos.distance_to(e.pos) < pulse_range:
						e.hp -= fire_damage
						var push_dir: Vector2 = (e.pos - player_pos).normalized()
						e.pos += push_dir * 120.0
						# Stun pulse perk
						if mods_w.get("stun_pulse", false):
							e.stunned_timer = 1.0
						enemies[ei] = e
						if e.hp <= 0:
							_on_enemy_killed(ei)
				aoe_flashes.append({pos=player_pos, radius=pulse_range, timer=0.3, color=Color(0.3,0.8,1.0,0.6)})
				w.mag_ammo = 999  # pulse cannon does not use ammo
				# Pulse cannon clean mutation: repulsor wall
				if mods_w.get("repulsor_field", false):
					var wall_dir: Vector2 = dir
					var wall_perp: Vector2 = Vector2(-wall_dir.y, wall_dir.x)
					var wall_dur: float = 2.0
					if mods_w.get("wall_persist", false):
						wall_dur = 4.0
					walls.append({pos=player_pos + dir * pulse_range, dir_perp=wall_perp, length=400.0, timer=wall_dur})
					if mods_w.get("double_wall", false):
						walls.append({pos=player_pos + dir * pulse_range, dir_perp=wall_dir, length=400.0, timer=wall_dur})
				# Pulse cannon void mutation: collapse shot
				if mods_w.get("collapse_shot", false):
					var collapse_radius: float = 200.0 + mods_w.get("collapse_range_bonus", 0.0)
					gravity_wells.append({pos=nearest_pos, radius=collapse_radius, timer=1.5, implode=true})
			"chain_shot":
				w.mag_ammo -= 1
				var chain_bounces: int = 2 + mods_w.get("chain_bounces_bonus", 0)
				var chain_b: Dictionary = {
					pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
					vel = dir * w_bullet_speed,
					radius = def.bullet_radius,
					color = def.color,
					damage = fire_damage,
					lifetime = w_range / maxf(1.0, w_bullet_speed),
					from_player = true,
					weapon_id = w.id,
					chain_shot = true,
					bounces_left = chain_bounces,
					hit_ids = [],
				}
				if mods_w.get("arc_damage_ramp", false):
					chain_b["arc_ramp"] = true
				if mods_w.get("plague", false):
					chain_b["plague"] = true
				bullets.append(chain_b)

		# Resonance: sympathetic_fire — drone fires when player fires
		if weapon_mods.get("_resonance", {}).get("sympathetic_fire", false) and drone_active:
			var drone_dmg: int = maxi(1, int(fire_damage * 0.5))
			if nearest_found:
				var drone_dir: Vector2 = (nearest_pos - drone_pos).normalized()
				bullets.append({pos=drone_pos, vel=drone_dir * 300.0, radius=4.0, color=Color(0.3,0.9,1.0), damage=drone_dmg, lifetime=0.8, from_player=true, weapon_id="drone"})

	main_weapon = w

func _update_aoe_flashes(delta: float) -> void:
	var i := aoe_flashes.size() - 1
	while i >= 0:
		aoe_flashes[i].timer -= delta
		if aoe_flashes[i].timer <= 0:
			aoe_flashes.remove_at(i)
		i -= 1

# =========================================================
# ENEMIES
# =========================================================
func _update_enemies(delta: float) -> void:
	var dead_indices: Array[int] = []

	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		if e.hp <= 0:
			continue

		# Parasite tick
		if e.get("parasite_timer", 0.0) > 0.0:
			e.parasite_timer -= delta
			e.hp -= int(e.get("parasite_dmg", 1.0) * delta + 0.5)
			if e.hp <= 0:
				enemies[i] = e
				_on_enemy_killed(i)
				# Parasite spread
				var nearest_spread_dist: float = 150.0
				var nearest_spread_idx: int = -1
				for si in range(enemies.size()):
					if si == i or enemies[si].hp <= 0:
						continue
					if enemies[si].get("parasite_timer", 0.0) > 0.0:
						continue
					var sd: float = e.pos.distance_to(enemies[si].pos)
					if sd < nearest_spread_dist:
						nearest_spread_dist = sd
						nearest_spread_idx = si
				if nearest_spread_idx >= 0:
					var se: Dictionary = enemies[nearest_spread_idx]
					se.parasite_timer = 4.0
					se.parasite_dmg = 1.0
					enemies[nearest_spread_idx] = se
				continue

		# Marked timer tick
		if e.get("marked_timer", 0.0) > 0.0:
			e["marked_timer"] = e.marked_timer - delta

		# Chain drain: corruption gain from tethered enemies (T3 void chain)
		if e.get("chain_drain", false) and e.get("stunned_timer", 0.0) > 0.0:
			corruption += 1.0 * delta

		# Plagued timer tick (chain rifle void mutation)
		if e.get("plagued_timer", 0.0) > 0.0:
			e["plagued_timer"] = e.plagued_timer - delta

		# Stunned check
		if e.get("stunned_timer", 0.0) > 0.0:
			e.stunned_timer -= delta
			enemies[i] = e
			continue
		# Trap slow timer
		if e.get("slow_timer", 0.0) > 0.0:
			e["slow_timer"] = e["slow_timer"] - delta

		var dist_to_player: float = e.pos.distance_to(player_pos)

		# Skip far non-aggroed enemies to reduce patrol CPU
		if not e.is_aggroed and dist_to_player > 1200.0:
			enemies[i] = e
			continue

		# Aggro check (lurkers handle their own aggro)
		if not e.is_aggroed and e.behavior != "lurker":
			if dist_to_player < e.detection:
				e.is_aggroed = true
				e.aggro_origin = e.pos
		else:
			# Leash check
			var dist_from_origin: float = e.pos.distance_to(e.aggro_origin)
			if dist_to_player > e.leash and dist_from_origin > e.detection:
				e.is_aggroed = false

		if e.is_aggroed:
			var move_dir := Vector2.ZERO

			# Decoy targeting: if decoy is closer than player, move toward decoy
			var move_target: Vector2 = player_pos
			for dc in decoys:
				if dc.get("timer", 0.0) > 0.0:
					var dc_dist: float = e.pos.distance_to(dc.pos)
					if dc_dist < e.detection and dc_dist < e.pos.distance_to(move_target):
						move_target = dc.pos
			# Replace player_pos with move_target in charge-like behaviors below
			var dist_to_target: float = e.pos.distance_to(move_target)

			match e.behavior:
				"charge":
					# Dumb straight-line rush
					if dist_to_target > e.radius + PLAYER_RADIUS:
						move_dir = (move_target - e.pos).normalized()

				"flank":
					# Circle to the side, then close in
					e.flank_timer -= delta
					if e.flank_timer <= 0.0:
						e.flank_side *= -1.0
						e.flank_timer = randf_range(1.0, 2.5)
					var to_player: Vector2 = (move_target - e.pos).normalized()
					var perp: Vector2 = Vector2(-to_player.y, to_player.x) * e.flank_side
					if dist_to_target > 80.0:
						move_dir = (to_player + perp * 0.7).normalized()
					else:
						move_dir = to_player

				"burst":
					# Slow stalk, then sudden lunge
					e.burst_timer -= delta
					if e.burst_active:
						move_dir = (move_target - e.pos).normalized()
						if e.burst_timer <= 0.0:
							e.burst_active = false
							e.burst_timer = randf_range(1.5, 3.0)
					else:
						# Slow stalk toward target
						if dist_to_target > e.radius + PLAYER_RADIUS:
							move_dir = (move_target - e.pos).normalized() * 0.35
						if e.burst_timer <= 0.0:
							e.burst_active = true
							e.burst_timer = 0.55  # lunge duration

				"strafe":
					# Ranged: sidestep while shooting, maintain distance
					e.ranged_cooldown_timer -= delta
					if e.ranged_cooldown_timer <= 0.0 and dist_to_player < e.detection:
						e.ranged_cooldown_timer = e.ranged_cooldown_base
						var shoot_dir: Vector2 = (player_pos - e.pos).normalized()
						bullets.append({
							pos = e.pos + shoot_dir * (e.radius + 5.0),
							vel = shoot_dir * 260.0,
							radius = 5.0,
							color = Color(1.0, 0.3, 0.1),
							damage = e.ranged_dmg,
							lifetime = 1.4,
							from_player = false,
						})
					e.strafe_timer -= delta
					if e.strafe_timer <= 0.0:
						e.strafe_dir *= -1.0
						e.strafe_timer = randf_range(0.8, 1.8)
					var to_p: Vector2 = (player_pos - e.pos).normalized()
					var side: Vector2 = Vector2(-to_p.y, to_p.x) * e.strafe_dir
					if dist_to_player < 130.0:
						move_dir = -to_p + side * 0.5  # back away
					elif dist_to_player > 220.0:
						move_dir = to_p  # close gap
					else:
						move_dir = side  # pure strafe in ideal range

				"pack":
					# Count nearby allies — speed bonus per ally within 160px
					var nearby: int = 0
					for other in enemies:
						if other.hp > 0 and other.type == e.type and other.pos != e.pos:
							if e.pos.distance_to(other.pos) < 160.0:
								nearby += 1
					var pack_mult: float = 1.0 + nearby * 0.25
					if dist_to_target > e.radius + PLAYER_RADIUS:
						move_dir = (move_target - e.pos).normalized()
					# Apply pack speed directly here
					if move_dir != Vector2.ZERO:
						var new_pos: Vector2 = e.pos + move_dir.normalized() * e.speed * pack_mult * delta
						new_pos = _avoid_obstacles(e.pos, new_pos, e.radius)
						e.pos = new_pos
					move_dir = Vector2.ZERO  # handled above

				"lurker":
					# Cave Lurker: dormant until player is close or in same cave
					if e.get("dormant", false):
						if dist_to_player < 200.0 or (e.get("cave_id", -1) >= 0 and player_in_cave == e.cave_id):
							e.dormant = false
							e.is_aggroed = true
							e.aggro_origin = e.pos
						else:
							move_dir = Vector2.ZERO
					if not e.get("dormant", false) and e.is_aggroed:
						# Charge behavior once triggered
						if dist_to_target > e.radius + PLAYER_RADIUS:
							move_dir = (move_target - e.pos).normalized()

				"patrol_river":
					# Tide Wraith: patrol along river, shoot at player
					e.ranged_cooldown_timer -= delta
					if e.ranged_cooldown_timer <= 0.0 and dist_to_player < e.detection:
						e.ranged_cooldown_timer = e.ranged_cooldown_base
						var shoot_dir: Vector2 = (player_pos - e.pos).normalized()
						bullets.append({
							pos = e.pos + shoot_dir * (e.radius + 5.0),
							vel = shoot_dir * 260.0,
							radius = 5.0,
							color = Color(0.1, 0.6, 1.0),
							damage = e.ranged_dmg,
							lifetime = 1.4,
							from_player = false,
						})
					# Patrol movement
					e.patrol_river_timer = e.get("patrol_river_timer", 3.0) - delta
					if e.patrol_river_timer <= 0.0:
						e.patrol_river_timer = randf_range(3.0, 4.0)
						# Pick new patrol point along nearest river direction
						var best_seg_pos: Vector2 = Vector2(e.pos.x, e.pos.y)
						var best_seg_dist: float = 999999.0
						for river in rivers:
							for seg in river.segments:
								var sd: float = e.pos.distance_to(Vector2(seg.pos.x, seg.pos.y))
								if sd < best_seg_dist:
									best_seg_dist = sd
									best_seg_pos = Vector2(seg.pos.x, seg.pos.y)
						var offset := Vector2(randf_range(-300.0, 300.0), randf_range(-300.0, 300.0))
						e.patrol_target = best_seg_pos + offset
						e.patrol_target.x = clampf(e.patrol_target.x, e.radius, WORLD_W - e.radius)
						e.patrol_target.y = clampf(e.patrol_target.y, e.radius, WORLD_H - e.radius)
					# Retreat to river when low HP
					if float(e.hp) / float(e.max_hp) < 0.3:
						var best_seg_pos2: Vector2 = Vector2(e.pos.x, e.pos.y)
						var best_seg_dist2: float = 999999.0
						for river in rivers:
							for seg in river.segments:
								var sd2: float = e.pos.distance_to(Vector2(seg.pos.x, seg.pos.y))
								if sd2 < best_seg_dist2:
									best_seg_dist2 = sd2
									best_seg_pos2 = Vector2(seg.pos.x, seg.pos.y)
						if best_seg_dist2 > 10.0:
							move_dir = (best_seg_pos2 - e.pos).normalized()
					elif e.pos.distance_to(e.patrol_target) > 10.0:
						move_dir = (e.patrol_target - e.pos).normalized()

				"elite":
					var etype: String = e.get("elite_type", "Void Hulk")
					if etype == "Void Hulk":
						# Slow relentless charge + ground slam
						e.charge_timer -= delta
						move_dir = (player_pos - e.pos).normalized()
						if e.charge_timer <= 0.0 and dist_to_player < 120.0:
							e.charge_timer = 4.0
							aoe_flashes.append({pos = e.pos, radius = 100.0, timer = 0.3, color = Color(1.0, 0.3, 0.0, 0.5)})
							player_hp -= 2
							player_hit_flash = 0.2
							_show_message("SLAM! -2 HP")
							if player_hp <= 0:
								_die()
					elif etype == "Phase Hunter":
						# Ranged + teleports every 4s
						e.phase_timer -= delta
						e.ranged_cooldown_timer -= delta
						if e.phase_timer <= 0.0:
							e.phase_timer = 4.0
							var rng2 := RandomNumberGenerator.new()
							rng2.randomize()
							var new_p := Vector2(rng2.randf_range(80.0, WORLD_W - 80.0), rng2.randf_range(80.0, WORLD_H - 80.0))
							if new_p.distance_to(player_pos) < 200.0:
								new_p = player_pos + (new_p - player_pos).normalized() * 280.0
							e.pos = new_p
							aoe_flashes.append({pos = e.pos, radius = 40.0, timer = 0.2, color = Color(0.5, 0.1, 1.0, 0.8)})
						if e.ranged_cooldown_timer <= 0.0:
							e.ranged_cooldown_timer = 1.2
							var shoot_dir: Vector2 = (player_pos - e.pos).normalized()
							for spread_f in [-0.2, 0.0, 0.2]:
								var sd: Vector2 = shoot_dir.rotated(spread_f)
								bullets.append({pos = e.pos + sd * 25.0, vel = sd * 300.0, radius = 6.0,
									color = Color(0.8, 0.2, 1.0), damage = 2, lifetime = 1.5, from_player = false})
						var to_p2: Vector2 = (player_pos - e.pos).normalized()
						move_dir = Vector2(-to_p2.y, to_p2.x)  # orbit
					elif etype == "Brood Mother":
						# Ranged + spawns adds at 50% HP
						e.ranged_cooldown_timer -= delta
						if e.ranged_cooldown_timer <= 0.0:
							e.ranged_cooldown_timer = 1.8
							var sd2: Vector2 = (player_pos - e.pos).normalized()
							bullets.append({pos = e.pos + sd2 * 25.0, vel = sd2 * 220.0, radius = 6.0,
								color = Color(0.9, 0.1, 0.5), damage = 2, lifetime = 1.6, from_player = false})
						if not e.brood_triggered and float(e.hp) / float(e.max_hp) <= 0.5:
							e.brood_triggered = true
							_show_message("Brood Mother calls her spawn!")
							var rng3 := RandomNumberGenerator.new()
							rng3.randomize()
							for _add in range(4):
								_spawn_single_enemy("Rift Parasite", false, rng3)
								enemies[-1].is_aggroed = true
						var to_p3: Vector2 = (player_pos - e.pos).normalized()
						var side3: Vector2 = Vector2(-to_p3.y, to_p3.x)
						if dist_to_player < 200.0:
							move_dir = -to_p3 + side3 * 0.5
						else:
							move_dir = side3

			# Apply movement (non-pack behaviors)
			if move_dir != Vector2.ZERO:
				var spd: float = e.speed
				if e.behavior == "burst" and e.burst_active:
					spd *= 2.5
				# Slow debuff (#1)
				var now_sec: float = Time.get_ticks_msec() * 0.001
				if e.get("slow_until", 0.0) > now_sec:
					spd *= 0.6
				# Trap slow
				if e.get("slow_timer", 0.0) > 0.0:
					spd *= e.get("slow_factor", 0.4)
				# Smoke/slow field speed reduction
				for sz in smoke_zones:
					if sz.get("slowing", false) and e.pos.distance_to(sz.pos) < sz.radius:
						spd *= 0.5
						break
				var new_pos: Vector2 = e.pos + move_dir.normalized() * spd * delta
				new_pos = _avoid_obstacles(e.pos, new_pos, e.radius)
				e.pos = new_pos

			# Melee
			if e.melee_dmg > 0 and dist_to_player < e.radius + PLAYER_RADIUS + 2.0:
				var cd_key: int = i
				var cd: float = enemy_melee_cooldowns.get(cd_key, 0.0)
				if cd <= 0.0:
					# Dodge chance
					var dodge_ch: float = weapon_mods.get("_player", {}).get("dodge_chance", 0.0)
					if dodge_ch > 0.0 and randf() < dodge_ch:
						_show_message("Dodged!")
					else:
						player_hp -= e.melee_dmg
						enemy_melee_cooldowns[cd_key] = 1.0
						player_hit_flash = 0.2
						_show_message("Hit! -%d HP" % e.melee_dmg)
						# Adrenaline reset on hit
						adrenaline_stack = 0
						# Corrupted path melee heal (#17)
						if corruption >= 36.0:
							player_hp = mini(player_hp + 1, player_max_hp)
						if player_hp <= 0:
							_die()
							return
		else:
			# Patrol: random walk near aggro_origin
			if e.pos.distance_to(e.patrol_target) < 5.0:
				var rng_offset := Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0))
				e.patrol_target = e.aggro_origin + rng_offset
				e.patrol_target.x = clampf(e.patrol_target.x, e.radius, WORLD_W - e.radius)
				e.patrol_target.y = clampf(e.patrol_target.y, e.radius, WORLD_H - e.radius)
			var dir: Vector2 = (e.patrol_target - e.pos).normalized()
			var new_pos: Vector2 = e.pos + dir * e.speed * 0.3 * delta
			new_pos = _avoid_obstacles(e.pos, new_pos, e.radius)
			e.pos = new_pos

		enemies[i] = e

	# Decrement melee cooldowns
	var keys_to_remove: Array = []
	for key in enemy_melee_cooldowns:
		enemy_melee_cooldowns[key] -= delta
		if enemy_melee_cooldowns[key] <= 0.0:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		enemy_melee_cooldowns.erase(key)

	# Purge dead enemies every 5 seconds (not every frame — avoid index thrash)
	if int(hunt_elapsed) % 5 == 0 and fmod(hunt_elapsed, 5.0) < delta * 2.0:
		var living: Array[Dictionary] = []
		for e in enemies:
			if e.hp > 0:
				living.append(e)
		enemies = living
		enemy_melee_cooldowns.clear()

	# Void creature proximity corruption aura
	var corr_resist: float = weapon_mods.get("_player", {}).get("corruption_resist", 0.0)
	for e in enemies:
		if e.hp <= 0 or not e.void_type:
			continue
		if player_pos.distance_to(e.pos) < 160.0:
			corruption += 2.0 * delta * (1.0 - corr_resist)

func _segment_intersects_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> bool:
	var ab: Vector2 = b - a
	var ac: Vector2 = center - a
	var t: float = clampf(ac.dot(ab) / ab.length_squared(), 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return closest.distance_to(center) < radius

func _avoid_obstacles(old_pos: Vector2, new_pos: Vector2, radius: float) -> Vector2:
	for obs in obstacles:
		var dist: float = new_pos.distance_to(obs.pos)
		var min_dist: float = obs.radius + radius
		if dist < min_dist:
			var push: Vector2 = (new_pos - obs.pos).normalized()
			new_pos = obs.pos + push * min_dist
	# World bounds
	new_pos.x = clampf(new_pos.x, radius, WORLD_W - radius)
	new_pos.y = clampf(new_pos.y, radius, WORLD_H - radius)
	return new_pos

# =========================================================
# BULLETS
# =========================================================
func _update_bullets(delta: float) -> void:
	var to_remove: Array[int] = []
	var new_bullets: Array[Dictionary] = []

	for i in range(bullets.size()):
		var b: Dictionary = bullets[i]

		# Homing steering
		if b.get("homing", false) and b.from_player:
			var best_dist := 999999.0
			var best_pos := Vector2.ZERO
			var found_target := false
			for e in enemies:
				if e.hp <= 0:
					continue
				var d: float = b.pos.distance_to(e.pos)
				if d < best_dist:
					best_dist = d
					best_pos = e.pos
					found_target = true
			if found_target:
				var track_mult: float = weapon_mods.get(b.get("weapon_id", ""), {}).get("tracking_mult", 1.0)
				var new_dir: Vector2 = b.vel.normalized().lerp((best_pos - b.pos).normalized(), 3.0 * track_mult * delta)
				b.vel = new_dir.normalized() * b.get("bullet_speed", b.vel.length())

		b.pos += b.vel * delta
		b.lifetime -= delta

		if b.lifetime <= 0.0:
			# Slow field on land (lance clean mutation)
			if b.get("slow_field_on_land", false) and b.from_player:
				smoke_zones.append({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
			# Momentum reset on miss
			if b.from_player and "momentum" in modifiers_taken and not b.get("hit_enemy", false):
				momentum_stack = 0
			to_remove.append(i)
			bullets[i] = b
			continue

		# Out of world
		if b.pos.x < 0.0 or b.pos.x > WORLD_W or b.pos.y < 0.0 or b.pos.y > WORLD_H:
			to_remove.append(i)
			bullets[i] = b
			continue

		# Wall collision (repulsor field)
		var hit_wall := false
		for wall in walls:
			var to_bullet: Vector2 = b.pos - wall.pos
			var proj: float = absf(to_bullet.dot(wall.dir_perp))
			var along: float = absf(to_bullet.dot(Vector2(-wall.dir_perp.y, wall.dir_perp.x)))
			if proj < 15.0 and along < wall.length * 0.5:
				if not b.from_player:
					hit_wall = true
				else:
					# Player bullets pass through own walls
					pass
				break
		if hit_wall:
			to_remove.append(i)
			bullets[i] = b
			continue

		# Obstacle collision
		var hit_obs := false
		for obs in obstacles:
			if b.pos.distance_to(obs.pos) < obs.radius + b.radius:
				hit_obs = true
				break
		if hit_obs:
			if b.get("slow_field_on_land", false) and b.from_player:
				smoke_zones.append({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
			to_remove.append(i)
			bullets[i] = b
			continue

		if b.from_player:
			# Tether bullet (chain kit)
			if b.get("tether", false):
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp <= 0:
						continue
					if b.pos.distance_to(e.pos) < e.radius + b.radius:
						e.stunned_timer = 3.0
						enemies[ei] = e
						to_remove.append(i)
						_show_message("Tethered!")
						break
				bullets[i] = b
				continue

			# Hit enemies
			var is_piercing: bool = b.get("piercing", false)
			var b_elite_bonus: float = weapon_mods.get("_player", {}).get("elite_dmg_bonus", 1.0)
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp <= 0:
					continue
				if b.pos.distance_to(e.pos) < e.radius + b.radius:
					var hit_dmg: int = b.damage
					# Blink empowered (T3 clean)
					if blink_empowered:
						hit_dmg *= 3
						blink_empowered = false
					# Marked damage bonus (trap T3 clean, chain T3 clean)
					if e.get("marked_timer", 0.0) > 0.0:
						hit_dmg = int(float(hit_dmg) * e.get("marked_dmg_bonus", 1.0))
					# Plagued damage bonus (chain rifle void)
					if e.get("plagued_timer", 0.0) > 0.0:
						hit_dmg = int(float(hit_dmg) * 1.2)
					# Elite damage bonus
					if e.get("is_elite", false) and b_elite_bonus > 1.0:
						hit_dmg = int(ceil(float(hit_dmg) * b_elite_bonus))
					# Stalker: +40% to non-aggroed
					if not e.is_aggroed and "stalker" in modifiers_taken:
						hit_dmg = int(float(hit_dmg) * 1.4)
					# Pack hunter: +8% per enemy within 200px
					if "pack_hunter" in modifiers_taken:
						var nearby_count: int = 0
						for ne in enemies:
							if ne.hp > 0 and player_pos.distance_to(ne.pos) < 200.0:
								nearby_count += 1
						hit_dmg = int(float(hit_dmg) * (1.0 + nearby_count * 0.08))
					# Biome bond: +20% in starting biome
					if "biome_bond" in modifiers_taken and _get_biome_at(player_pos) == player_start_biome:
						hit_dmg = int(float(hit_dmg) * 1.2)
					# Singularity on hit (lance void mutation)
					if b.get("singularity_on_hit", false):
						gravity_wells.append({pos=b.pos, radius=200.0, timer=2.0})
					# Momentum tracking
					if "momentum" in modifiers_taken:
						momentum_stack = mini(momentum_stack + 1, 10)
					b["hit_enemy"] = true

					if is_piercing:
						var hit_ids: Array = b.hit_ids
						if not hit_ids.has(ei):
							hit_ids.append(ei)
							b.hit_ids = hit_ids
							e.hp -= hit_dmg
							if b.get("slow_on_hit", false):
								e["slow_until"] = Time.get_ticks_msec() * 0.001 + 1.0
							# Parasite dart
							if b.get("parasite", false):
								e.parasite_timer = 4.0
								e.parasite_dmg = 1.0
							enemies[ei] = e
							if b.get("explode", false):
								_bullet_explode(b.pos, hit_dmg)
							if b.get("slow_field_on_land", false):
								smoke_zones.append({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
							if e.hp <= 0:
								_on_enemy_killed(ei, b.get("weapon_id", ""))
							# Pierce count limit for scatter clean
							var max_pierce: int = b.get("pierce_count", 9999)
							if hit_ids.size() >= max_pierce:
								to_remove.append(i)
								break
					else:
						e.hp -= hit_dmg
						if b.get("slow_on_hit", false):
							e["slow_until"] = Time.get_ticks_msec() * 0.001 + 1.0
						if b.get("parasite", false):
							var p_dur: float = weapon_mods.get(b.get("weapon_id", ""), {}).get("parasite_duration", 4.0)
							e.parasite_timer = p_dur
							e.parasite_dmg = 1.0
						# Stagger mastery: 15% stun
						if weapon_mods.get(b.get("weapon_id", ""), {}).get("stagger_chance", 0.0) > 0.0:
							if randf() < weapon_mods.get(b.get("weapon_id", ""), {}).get("stagger_chance", 0.0):
								e.stunned_timer = 0.5
						# Plague on hit (chain rifle void)
						if b.get("plague", false):
							var plague_dur: float = weapon_mods.get(b.get("weapon_id", ""), {}).get("plague_duration", 3.0)
							e["plagued_timer"] = plague_dur
							e["plagued"] = true
						enemies[ei] = e
						# Chain shot bounce (chain rifle)
						if b.get("chain_shot", false) and b.get("bounces_left", 0) > 0:
							var hit_ids: Array = b.get("hit_ids", [])
							hit_ids.append(ei)
							b["hit_ids"] = hit_ids
							b["bounces_left"] = b.bounces_left - 1
							# Arc damage ramp
							if b.get("arc_ramp", false):
								b.damage = int(float(b.damage) * 1.3)
							# Find nearest OTHER enemy
							var next_dist: float = 200.0
							var next_idx: int = -1
							for nei in range(enemies.size()):
								if hit_ids.has(nei) or enemies[nei].hp <= 0:
									continue
								var nd: float = b.pos.distance_to(enemies[nei].pos)
								if nd < next_dist:
									next_dist = nd
									next_idx = nei
							if next_idx >= 0:
								var ndir: Vector2 = (enemies[next_idx].pos - b.pos).normalized()
								b.vel = ndir * b.vel.length()
								b.lifetime = 1.0
								bullets[i] = b
							else:
								to_remove.append(i)
							if e.hp <= 0:
								_on_enemy_killed(ei, b.get("weapon_id", ""))
							break
						# Fragment on hit (sidearm void mutation)
						if b.get("fragment_on_hit", false) and not b.get("is_fragment", false):
							var frag_dmg: int = maxi(1, int(hit_dmg * 0.5))
							for fa in [deg_to_rad(30.0), deg_to_rad(150.0), deg_to_rad(270.0)]:
								var fdir: Vector2 = Vector2(cos(b.vel.angle() + fa), sin(b.vel.angle() + fa))
								new_bullets.append({
									pos = b.pos,
									vel = fdir * 300.0,
									radius = 3.0,
									color = b.color,
									damage = frag_dmg,
									lifetime = 0.3,
									from_player = true,
									weapon_id = b.get("weapon_id", ""),
									is_fragment = true,
								})
						to_remove.append(i)
						if b.get("explode", false):
							_bullet_explode(b.pos, hit_dmg)
						if b.get("slow_field_on_land", false):
							smoke_zones.append({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
						if e.hp <= 0:
							_on_enemy_killed(ei, b.get("weapon_id", ""))
						break
		else:
			# Drone intercept check
			if drone_active and b.pos.distance_to(drone_pos) < 100.0 and drone_intercept_timer <= 0.0:
				drone_intercept_timer = 4.0
				to_remove.append(i)
				aoe_flashes.append({pos=drone_pos, radius=15.0, timer=0.2, color=Color(1.0, 1.0, 1.0, 0.8)})
				bullets[i] = b
				continue
			# Hit player
			if b.pos.distance_to(player_pos) < PLAYER_RADIUS + b.radius:
				var dodge_ch: float = weapon_mods.get("_player", {}).get("dodge_chance", 0.0)
				if dodge_ch > 0.0 and randf() < dodge_ch:
					to_remove.append(i)
					_show_message("Dodged!")
				else:
					var recv_dmg: int = b.damage
					if corruption >= 36.0:
						recv_dmg = maxi(1, recv_dmg - 1)
					player_hp -= recv_dmg
					player_hit_flash = 0.2
					adrenaline_stack = 0
					to_remove.append(i)
					_show_message("Shot! -%d HP" % recv_dmg)
					if player_hp <= 0:
						_die()
						return

		bullets[i] = b

	# Remove in reverse order
	to_remove.sort()
	for idx in range(to_remove.size() - 1, -1, -1):
		bullets.remove_at(to_remove[idx])

	# Add new bullets (fragments etc)
	for nb in new_bullets:
		bullets.append(nb)

func _on_enemy_killed(idx: int, killer_weapon: String = "") -> void:
	var e: Dictionary = enemies[idx]
	var death_pos: Vector2 = e.pos

	# --- Modifier procs on kill ---
	# Vamp chance
	var vamp_ch: float = weapon_mods.get("_player", {}).get("vamp_chance", 0.0)
	if vamp_ch > 0.0 and randf() < vamp_ch:
		player_hp = mini(player_hp + 1, player_max_hp)
		_show_message("+1 HP")

	# Kill streak speed
	if weapon_mods.get("_player", {}).get("kill_streak_speed", false):
		kill_streak_count += 1
		if kill_streak_count >= 3:
			kill_streak_count = 0
			speed_boost_timer = 3.0

	# Adrenaline
	if "adrenaline" in modifiers_taken:
		if (hunt_elapsed - adrenaline_last_kill_time) < 3.0:
			adrenaline_stack += 1
		else:
			adrenaline_stack = 1
		adrenaline_last_kill_time = hunt_elapsed

	# Void hunger: heal from void kills
	if e.void_type and "void_hunger" in modifiers_taken:
		player_hp = mini(player_hp + 1, player_max_hp)

	# Void drain: reduce corruption from void kills
	if e.void_type and "void_drain" in modifiers_taken:
		corruption = maxf(0.0, corruption - 3.0)

	# Stim T3 void: cooldown resets on elite kill
	if e.get("is_elite", false) and kit_tiers.get("stim_pack", 1) >= 3 and kit_t3_choices.get("stim_pack", "") == "void":
		if kit_states.has("stim_pack"):
			kit_states["stim_pack"].cooldown = 0.0

	# Mastery: killcam — next shot fires instantly
	if weapon_mods.get(main_weapon.get("id", ""), {}).get("killcam", false):
		main_weapon.cooldown_timer = 0.0

	# Mastery: missile_burst — on elite kill fire 2 missiles
	if e.get("is_elite", false) and weapon_mods.get(main_weapon.get("id", ""), {}).get("missile_burst", false):
		for _mb in range(2):
			var mb_dir: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			bullets.append({pos=death_pos, vel=mb_dir * 120.0, radius=12.0, color=Color(0.2,1.0,0.5), damage=15, lifetime=4.0, from_player=true, homing=true, bullet_speed=120.0, weapon_id="dart"})

	# Scavenger: elites drop extra essence
	if "scavenger" in modifiers_taken and e.get("is_elite", false):
		pickups.append({pos = death_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), type = "essence"})

	# On-kill lance (#2)
	var lance_mods: Dictionary = weapon_mods.get("lance", {})
	if lance_mods.get("on_kill_lance", false) and main_weapon.get("id", "") == "lance":
		var nearest_e_dist: float = 999999.0
		var nearest_e_pos := Vector2.ZERO
		var found_ne := false
		for ne in enemies:
			if ne.hp <= 0:
				continue
			var nd: float = death_pos.distance_to(ne.pos)
			if nd < nearest_e_dist and nd > 1.0:
				nearest_e_dist = nd
				nearest_e_pos = ne.pos
				found_ne = true
		if found_ne:
			var lance_def: Dictionary = WEAPON_DEFS["lance"]
			var lance_dmg: int = lance_def.damage + lance_mods.get("damage_bonus", 0)
			var lance_dir: Vector2 = (nearest_e_pos - death_pos).normalized()
			var lance_spd: float = lance_def.bullet_speed + lance_mods.get("bullet_speed_bonus", 0.0)
			bullets.append({
				pos = death_pos,
				vel = lance_dir * lance_spd,
				radius = lance_def.bullet_radius,
				color = lance_def.color,
				damage = lance_dmg,
				lifetime = lance_def.range / maxf(1.0, lance_spd),
				from_player = true,
				piercing = true,
				hit_ids = [],
				weapon_id = "lance",
			})

	# Split on kill — dart (#10)
	if killer_weapon == "dart" and weapon_mods.get("dart", {}).get("split_on_kill", false):
		var dart_def: Dictionary = WEAPON_DEFS["dart"]
		var dart_mods: Dictionary = weapon_mods.get("dart", {})
		var dart_dmg: int = dart_def.damage + dart_mods.get("damage_bonus", 0)
		# Find 2 nearest living enemies
		var split_targets: Array[Dictionary] = []
		for se in enemies:
			if se.hp <= 0:
				continue
			var sd: float = death_pos.distance_to(se.pos)
			if sd > 1.0:
				split_targets.append({pos = se.pos, dist = sd})
		split_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.dist < b.dist)
		for sti in range(mini(2, split_targets.size())):
			var st_dir: Vector2 = (split_targets[sti].pos - death_pos).normalized()
			bullets.append({
				pos = death_pos,
				vel = st_dir * dart_def.bullet_speed,
				radius = dart_def.bullet_radius,
				color = dart_def.color,
				damage = dart_dmg,
				lifetime = dart_def.range / dart_def.bullet_speed,
				from_player = true,
				homing = true,
				bullet_speed = dart_def.bullet_speed,
				weapon_id = "dart",
			})

	# Elites: drop biome ingredient + elite_core + big essence burst
	if e.get("is_elite", false):
		# Big essence burst
		for _b in range(5):
			pickups.append({pos = death_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), type = "essence"})
		# Determine biome ingredient based on where elite was killed
		var elite_biome: String = _get_biome_at(death_pos)
		var biome_ingredient_map: Dictionary = {
			"open": "rift_dust",
			"void_pool": "void_crystal",
			"cave": "cave_moss",
			"river_bank": "river_silt",
		}
		var biome_ing: String = biome_ingredient_map.get(elite_biome, "rift_dust")
		# Always drop 1 elite_core
		run_ingredients.append({id = "elite_core", name = "Elite Core", ingredient = true})
		_spawn_float_text(death_pos + Vector2(0, -20), "+elite_core", Color(1.0, 0.85, 0.0))
		# Drop 1 biome ingredient
		var biome_display: String = biome_ing.replace("_", " ").capitalize()
		run_ingredients.append({id = biome_ing, name = biome_display, ingredient = true})
		_spawn_float_text(death_pos + Vector2(0, -40), "+" + biome_ing, Color(0.4, 1.0, 0.6))
		_show_message("Elite down! +%s +elite_core" % biome_ing)
		# Track contract progress
		target_kills += 1
		if target_kills >= target_total and not exit_spawned:
			_spawn_exit()
		return

	# Regular enemies: essence only (no ingredients)
	pickups.append({pos = death_pos + Vector2(-10, 0), type = "essence"})

func _drop_ingredient(enemy: Dictionary) -> void:
	var ing_id: String = enemy.get("ingredient_id", "")
	if ing_id.is_empty():
		return

	var is_void_creature: bool = enemy.get("void_type", false)
	var is_pristine: bool = false

	# Drop chance — not every kill yields an ingredient
	# Common creatures: 30% base. Void creatures: 20% (dangerous, rare reward).
	var drop_chance: float = 0.20 if is_void_creature else 0.30
	if randf() > drop_chance:
		return

	if not is_void_creature and corruption < 15.0:
		is_pristine = randf() < 0.4
	elif not is_void_creature and corruption < 35.0:
		is_pristine = randf() < 0.1

	var display_name: String
	if is_pristine:
		display_name = PRISTINE_NAMES.get(ing_id, ing_id + " (Pure)")
	else:
		display_name = ing_id.replace("_", " ").capitalize()

	var drop: Dictionary = {
		id = "ingredient_" + ing_id + ("_pristine" if is_pristine else ""),
		name = display_name,
		is_pristine = is_pristine,
		ingredient = true,
		uses = 1,
	}

	ingredient_pickups.append({
		pos = enemy.pos,
		data = drop,
		collected = false,
		pulse_phase = randf() * TAU,
		color = enemy.get("color", Color.WHITE),
	})

	_show_message("+ " + display_name)

func _spawn_exit() -> void:
	exit_spawned = true
	# Place exit far from player
	var best_pos := Vector2(100.0, 100.0)
	var best_dist := 0.0
	for _try in range(20):
		var pos := Vector2(randf_range(100.0, WORLD_W - 100.0), randf_range(100.0, WORLD_H - 100.0))
		var d: float = pos.distance_to(player_pos)
		if d > best_dist:
			var blocked := false
			for obs in obstacles:
				if pos.distance_to(obs.pos) < obs.radius + 50.0:
					blocked = true
					break
			if not blocked:
				best_dist = d
				best_pos = pos
	exit_pos = best_pos
	_show_message("Exit spawned! Get to the green zone!")

# =========================================================
# PICKUPS
# =========================================================
func _check_pickups() -> void:
	var to_remove: Array[int] = []

	for i in range(pickups.size()):
		var p: Dictionary = pickups[i]
		var pickup_radius := 20.0
		if p.type == "essence":
			pickup_radius = essence_collect_radius

		if player_pos.distance_to(p.pos) < pickup_radius + PLAYER_RADIUS:
			if p.type == "ingredient":
				run_ingredients.append(p.ingredient_data)
				_show_message("\u2713 " + p.ingredient_data.name)
			elif p.type == "essence":
				essence_collected += 1
				if essence_collected >= xp_threshold:
					essence_collected -= xp_threshold
					player_level += 1
					xp_threshold = _xp_needed_for_level(player_level)
					_level_up()
			to_remove.append(i)

	to_remove.sort()
	for idx in range(to_remove.size() - 1, -1, -1):
		pickups.remove_at(to_remove[idx])

	# Ingredient pickups (Phase 3)
	for i in range(ingredient_pickups.size()):
		var ip: Dictionary = ingredient_pickups[i]
		if ip.collected:
			continue
		if player_pos.distance_to(ip.pos) < 30.0:
			ip.collected = true
			ingredient_pickups[i] = ip
			run_ingredients.append(ip.data)
			var msg_color: Color = Color(0.4, 1.0, 0.6) if ip.data.get("is_pristine", false) else Color(0.4, 1.0, 0.4)
			_show_message("Collected " + ip.data.name)

# =========================================================
# LEVEL UP
# =========================================================
func _level_up() -> void:
	paused = true
	_show_message("Level Up!")

	upgrade_choices = _generate_upgrades()

	# Create upgrade panel using call_deferred
	call_deferred("_create_upgrade_panel")

func _generate_upgrades() -> Array:
	var options: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# --- Slot 1: WEAPON ---
	var w: Dictionary = main_weapon
	if w.level >= 5 and not w.mutated and WEAPON_MUTATIONS.has(w.id):
		# Offer mutation cards based on corruption
		if corruption < 35.0:
			var mut: Dictionary = WEAPON_MUTATIONS[w.id]["clean"]
			options.append({type="mutation", mutation_type="clean", rarity="legendary", icon=mut.icon, label=mut.name, desc=mut.desc, perk={}})
		if corruption > 20.0:
			var mut_v: Dictionary = WEAPON_MUTATIONS[w.id]["void"]
			options.append({type="mutation", mutation_type="void", rarity="legendary", icon=mut_v.icon, label=mut_v.name, desc=mut_v.desc, perk={}})
		# If only 1 mutation card, pad slot 1 with it
		if options.size() == 0:
			# No mutations available, offer mastery
			var wdef_m: Dictionary = WEAPON_DEFS[w.id]
			options.append({type="modifier", id="mastery_dmg", rarity="common", icon="W", label="Mastery: " + wdef_m.name, desc="+2 damage", perk={}})
	elif w.level < 5:
		var next_level: int = w.level + 1
		if WEAPON_LEVEL_PERKS.has(w.id) and WEAPON_LEVEL_PERKS[w.id].has(next_level):
			var perk: Dictionary = WEAPON_LEVEL_PERKS[w.id][next_level]
			var wdef: Dictionary = WEAPON_DEFS[w.id]
			options.append({
				type = "weapon_upgrade",
				weapon_id = w.id,
				rarity = "rare" if next_level >= 4 else "common",
				icon = perk.icon,
				label = wdef.name + " -- " + perk.name,
				desc = perk.desc,
				perk = perk,
			})
		else:
			var wdef2: Dictionary = WEAPON_DEFS[w.id]
			options.append({
				type = "weapon_upgrade", weapon_id = w.id,
				rarity = "common", icon = "W",
				label = wdef2.name + " Lv" + str(w.level + 1),
				desc = "+1 damage",
				perk = {effect = "damage", value = 1},
			})
	else:
		# Mutated, offer mastery perk
		if WEAPON_MASTERY.has(w.id) and WEAPON_MASTERY[w.id].has(w.mutation_type):
			var mastery_pool: Array = WEAPON_MASTERY[w.id][w.mutation_type]
			var available_m: Array[Dictionary] = []
			for mp in mastery_pool:
				if not mastery_taken.has(mp.id):
					available_m.append(mp)
			if available_m.size() > 0:
				available_m.shuffle()
				var perk_m: Dictionary = available_m[0]
				options.append({type="mastery", id=perk_m.id, rarity="rare", icon=perk_m.icon, label=perk_m.name, desc=perk_m.desc, perk={}})
			else:
				var wdef_m2: Dictionary = WEAPON_DEFS[w.id]
				options.append({type="modifier", id="mastery_dmg", rarity="common", icon="W", label="Mastery: " + wdef_m2.name, desc="+2 damage", perk={}})
		else:
			var wdef_m2: Dictionary = WEAPON_DEFS[w.id]
			options.append({type="modifier", id="mastery_dmg", rarity="common", icon="W", label="Mastery: " + wdef_m2.name, desc="+2 damage", perk={}})

	# --- Slot 2: KIT TIER, RESONANCE, OR MODIFIER ---
	var slot2_done := false
	# Check if both kits have T3 — offer resonance
	var both_t3: bool = equipped_kits.size() >= 2 and kit_tiers.get(equipped_kits[0], 1) >= 3 and kit_tiers.get(equipped_kits[1], 1) >= 3
	if both_t3:
		var avail_res: Array[Dictionary] = []
		for rp in RESONANCE_POOL:
			if resonance_taken.has(rp.id):
				continue
			var has_both: bool = true
			for rk in rp.kits:
				if not equipped_kits.has(rk):
					has_both = false
					break
			if has_both:
				avail_res.append(rp)
		if avail_res.size() > 0:
			avail_res.shuffle()
			var rp2: Dictionary = avail_res[0]
			options.append({type="resonance", id=rp2.id, rarity="legendary", icon=rp2.icon, label=rp2.name, desc=rp2.desc, perk={}})
			slot2_done = true
	if not slot2_done:
		for kid in equipped_kits:
			var kt: int = kit_tiers.get(kid, 1)
			if kt < 3:
				var kdef: Dictionary = KIT_DEFS.get(kid, {})
				options.append({
					type = "kit_tier",
					kit_id = kid,
					new_tier = kt + 1,
					rarity = "rare",
					icon = kdef.get("icon", "K"),
					label = kdef.get("name", kid) + " Tier " + str(kt + 1),
					desc = "+1 max HP (tier upgrade)",
					perk = {},
				})
				slot2_done = true
				break
	if not slot2_done:
		var avail2: Array[Dictionary] = []
		for m in RUN_MODIFIERS:
			if not modifiers_taken.has(m.id):
				avail2.append(m)
		avail2.shuffle()
		if avail2.size() > 0:
			var m2: Dictionary = avail2[0]
			options.append({type="modifier", id=m2.id, rarity=m2.rarity, icon=m2.icon, label=m2.name, desc=m2.desc, perk={}})

	# --- Slot 3: MODIFIER ---
	var used_mod_ids: Array[String] = modifiers_taken.duplicate()
	for o in options:
		if o.type == "modifier":
			used_mod_ids.append(o.get("id", ""))
	var avail3: Array[Dictionary] = []
	for m in RUN_MODIFIERS:
		if not used_mod_ids.has(m.id):
			avail3.append(m)
	avail3.shuffle()
	if avail3.size() > 0:
		var m3: Dictionary = avail3[0]
		options.append({type="modifier", id=m3.id, rarity=m3.rarity, icon=m3.icon, label=m3.name, desc=m3.desc, perk={}})

	# --- Guaranteed fallbacks so panel is never empty ---
	if options.size() < 3:
		var fallbacks: Array[Dictionary] = [
			{type="fallback", id="hp_restore",   rarity="common", icon="H", label="Field Medkit",      desc="Restore 3 HP immediately",            perk={}},
			{type="fallback", id="dmg_boost",    rarity="common", icon="D", label="Weapon Calibration", desc="+1 damage",                           perk={}},
			{type="fallback", id="speed_boost",  rarity="common", icon="S", label="Adrenaline Shot",    desc="+20 move speed permanently",          perk={}},
			{type="fallback", id="corr_purge",   rarity="rare",   icon="P", label="Void Purge",         desc="Reduce corruption by 20",             perk={}},
		]
		var existing_ids: Array = []
		for o in options:
			existing_ids.append(o.get("id", o.get("weapon_id", "")))
		fallbacks.shuffle()
		for fb in fallbacks:
			if options.size() >= 3:
				break
			if not existing_ids.has(fb.id):
				options.append(fb)

	if options.size() > 3:
		options = options.slice(0, 3)
	return options

func _create_upgrade_panel() -> void:
	var vp_size := get_viewport_rect().size
	var panel := Panel.new()
	panel.name = "UpgradePanel"
	panel.position = Vector2.ZERO
	panel.size = vp_size

	# Dark overlay background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(vp_size.x * 0.1, vp_size.y * 0.15)
	vbox.size = Vector2(vp_size.x * 0.8, vp_size.y * 0.7)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "LEVEL UP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose an upgrade:"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	vbox.add_child(subtitle)

	upgrade_buttons = []
	for i in range(upgrade_choices.size()):
		var c: Dictionary = upgrade_choices[i]
		var rarity_str: String = c.get("rarity", "common")
		var is_rare: bool = rarity_str == "rare" or rarity_str == "legendary"

		# Card container
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 72)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.08, 0.20, 0.95) if is_rare else Color(0.08, 0.10, 0.16, 0.95)
		card_style.border_color = Color(0.9, 0.7, 0.1) if is_rare else Color(0.4, 0.4, 0.6)
		card_style.border_width_left = 2; card_style.border_width_right = 2
		card_style.border_width_top = 2; card_style.border_width_bottom = 2
		card_style.corner_radius_top_left = 6; card_style.corner_radius_top_right = 6
		card_style.corner_radius_bottom_left = 6; card_style.corner_radius_bottom_right = 6
		card.add_theme_stylebox_override("panel", card_style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)

		# Icon + number
		var icon_lbl := Label.new()
		icon_lbl.text = "  %s" % c.get("icon", "★")
		icon_lbl.add_theme_font_size_override("font_size", 28)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_vbox)

		var name_lbl := Label.new()
		var rarity_tag: String = "  ◆ RARE" if is_rare else ""
		name_lbl.text = "[%d] %s%s" % [i + 1, c.label, rarity_tag]
		name_lbl.add_theme_font_size_override("font_size", 15)
		var name_color: Color = Color(1.0, 0.85, 0.3) if is_rare else Color(0.9, 0.9, 1.0)
		name_lbl.add_theme_color_override("font_color", name_color)
		text_vbox.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = c.desc
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_vbox.add_child(desc_lbl)

		# Invisible button over card
		var btn := Button.new()
		btn.flat = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_upgrade_chosen.bind(i))
		card.add_child(btn)

		vbox.add_child(card)
		upgrade_buttons.append(btn)

	add_child(panel)

func _on_upgrade_chosen(idx: int) -> void:
	var choice: Dictionary = upgrade_choices[idx]
	match choice.type:
		"weapon_upgrade":
			if main_weapon.id == choice.get("weapon_id", ""):
				main_weapon.level += 1
				var perk: Dictionary = choice.get("perk", {})
				_apply_weapon_perk(choice.weapon_id, perk)
		"mutation":
			main_weapon.mutated = true
			main_weapon.mutation_type = choice.mutation_type
			main_weapon.level = 6
			_apply_mutation(main_weapon.id, choice.mutation_type)
		"mastery":
			mastery_taken.append(choice.get("id", ""))
			_apply_mastery_perk(choice.get("id", ""))
		"resonance":
			resonance_taken.append(choice.get("id", ""))
			var res_mods: Dictionary = weapon_mods.get("_resonance", {})
			res_mods[choice.get("id", "")] = true
			weapon_mods["_resonance"] = res_mods
			_show_message("Resonance: " + choice.get("label", ""))
		"kit_tier":
			var kit_id: String = choice.get("kit_id", "")
			var new_tier: int = choice.get("new_tier", 2)
			kit_tiers[kit_id] = new_tier
			player_max_hp += 1
			_show_message(KIT_DEFS.get(kit_id, {}).get("name", kit_id) + " upgraded to Tier " + str(new_tier) + "!")
		"modifier":
			var mod_id: String = choice.get("id", "")
			if mod_id == "mastery_dmg":
				var mods_m: Dictionary = weapon_mods.get(main_weapon.id, {})
				mods_m["damage_bonus"] = mods_m.get("damage_bonus", 0) + 2
				weapon_mods[main_weapon.id] = mods_m
			else:
				modifiers_taken.append(mod_id)
				_apply_modifier(mod_id)
		"fallback":
			match choice.id:
				"hp_restore":
					player_hp = mini(player_hp + 3, player_max_hp)
					_show_message("+3 HP")
				"dmg_boost":
					var mods_fb: Dictionary = weapon_mods.get(main_weapon.id, {})
					mods_fb["damage_bonus"] = mods_fb.get("damage_bonus", 0) + 1
					weapon_mods[main_weapon.id] = mods_fb
				"speed_boost":
					player_speed += 20.0
				"corr_purge":
					corruption = maxf(0.0, corruption - 20.0)
					_show_message("Corruption -20")

	paused = false
	upgrade_choices = []
	upgrade_buttons = []
	# Reset joystick — the panel consumed the touch-release event, finger is stuck
	joy_active = false
	joy_touch_index = -1
	joy_knob = Vector2.ZERO
	call_deferred("_remove_upgrade_panel")

func _remove_upgrade_panel() -> void:
	var panel := get_node_or_null("UpgradePanel")
	if panel:
		panel.queue_free()

func _apply_weapon_perk(wid: String, perk: Dictionary) -> void:
	if perk.is_empty():
		return
	var mods: Dictionary = weapon_mods.get(wid, {})
	match perk.get("effect", ""):
		"fire_rate":
			mods["fire_rate_add"] = mods.get("fire_rate_add", 0.0) + perk.value
		"damage":
			mods["damage_bonus"] = mods.get("damage_bonus", 0) + int(perk.value)
		"piercing":
			mods["piercing"] = true
		"fire_rate_mag":
			mods["fire_rate_add"] = mods.get("fire_rate_add", 0.0) - 0.14
			if main_weapon.id == wid:
				main_weapon.mag_size += 6
				main_weapon.mag_ammo = mini(main_weapon.mag_ammo + 6, main_weapon.mag_size)
		"pellets":
			mods["extra_pellets"] = mods.get("extra_pellets", 0) + int(perk.value)
		"slow":
			mods["slow_on_hit"] = true
		"pellets_rate":
			mods["extra_pellets"] = mods.get("extra_pellets", 0) + 2
			mods["fire_rate_add"] = mods.get("fire_rate_add", 0.0) - 0.21
		"bullet_speed":
			mods["bullet_speed_bonus"] = mods.get("bullet_speed_bonus", 0.0) + perk.value
		"on_kill_lance":
			mods["on_kill_lance"] = true
		"explode":
			mods["explode_on_hit"] = true
		"radius":
			mods["radius_bonus"] = mods.get("radius_bonus", 0.0) + perk.value
		"damage_knockback":
			mods["damage_bonus"] = mods.get("damage_bonus", 0) + int(perk.value)
			mods["knockback"] = true
		"leech":
			mods["leech"] = true
		"chain":
			mods["chain"] = true
		"tracking":
			mods["tracking_mult"] = mods.get("tracking_mult", 1.0) * perk.value
		"dual":
			mods["dual_dart"] = true
		"split_on_kill":
			mods["split_on_kill"] = true
		"stun_pulse":
			mods["stun_pulse"] = true
		"chain_bounces":
			mods["chain_bounces_bonus"] = mods.get("chain_bounces_bonus", 0) + int(perk.value)
		"arc_damage_ramp":
			mods["arc_damage_ramp"] = true
		"chain_final":
			mods["chain_bounces_bonus"] = mods.get("chain_bounces_bonus", 0) + 1
			mods["fire_rate_add"] = mods.get("fire_rate_add", 0.0) - 0.12
	weapon_mods[wid] = mods

# =========================================================
# DEATH & COMPLETION
# =========================================================
func _die() -> void:
	dead = true
	dead_timer = 2.0
	player_hp = 0
	_show_message("DEAD")

func _complete_hunt() -> void:
	var contract: Dictionary = GameData.current_contract
	var reward: int = contract.get("reward", 50)
	var corr: int = int(corruption)
	var pristine_count: int = run_ingredients.filter(func(i): return i.get("is_pristine", false)).size()
	SaveManager.complete_contract(reward, corr)
	GameData.set_hunt_result(reward, corr, run_ingredients.size(), run_ingredients)
	GameData.hunt_result["pristine_count"] = pristine_count
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

func _finish_hunt(credits: int) -> void:
	var corr: int = int(corruption)
	var pristine_count: int = run_ingredients.filter(func(i): return i.get("is_pristine", false)).size()
	if credits == 0:
		SaveManager.complete_contract(0, corr)
		GameData.set_hunt_result(0, corr, 0)
		GameData.hunt_result["pristine_count"] = pristine_count
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

# =========================================================
# HUD MESSAGE
# =========================================================
func _show_message(msg: String) -> void:
	hud_message = msg
	hud_message_timer = 2.0

func _update_hud_message(delta: float) -> void:
	if hud_message_timer > 0.0:
		hud_message_timer -= delta
		if hud_message_timer <= 0.0:
			hud_message = ""

func _spawn_float_text(world_pos: Vector2, text: String, color: Color) -> void:
	float_texts.append({pos = world_pos, text = text, color = color, timer = 2.0})

func _update_float_texts(delta: float) -> void:
	var i := float_texts.size() - 1
	while i >= 0:
		float_texts[i].timer -= delta
		float_texts[i].pos.y -= 30.0 * delta
		if float_texts[i].timer <= 0.0:
			float_texts.remove_at(i)
		i -= 1

# =========================================================
# HELPERS — perk effects
# =========================================================
func _bullet_explode(impact_pos: Vector2, dmg: int) -> void:
	aoe_flashes.append({pos = impact_pos, radius = 60.0, timer = 0.3, color = Color(1.0, 0.6, 0.1, 0.7)})
	for ei2 in range(enemies.size()):
		var ae: Dictionary = enemies[ei2]
		if ae.hp <= 0:
			continue
		if impact_pos.distance_to(ae.pos) < 60.0:
			ae.hp -= dmg
			enemies[ei2] = ae
			if ae.hp <= 0:
				_on_enemy_killed(ei2)

func _get_effective_player_stats() -> Dictionary:
	var move_speed_mult: float = 1.0
	var range_mult: float = 1.0
	var fire_rate_mult: float = 1.0
	var reload_mult: float = 1.0
	var damage_mult: float = 1.0
	if corruption < 15.0:
		move_speed_mult = 1.15
		range_mult = 1.2
		fire_rate_mult = 0.9
		reload_mult = 0.85
	elif corruption >= 36.0:
		move_speed_mult = 1.2
		range_mult = 0.7
	# Adrenaline stacking speed
	if "adrenaline" in modifiers_taken:
		move_speed_mult *= (1.0 + adrenaline_stack * 0.05)
	# Last stand
	if player_hp <= 3 and "last_stand" in modifiers_taken:
		damage_mult *= 1.5
		move_speed_mult *= 1.3
	# Void surge active
	if "void_surge" in equipped_kits and kit_states.has("void_surge"):
		if kit_states["void_surge"].get("active", false):
			move_speed_mult *= 1.8
	# Stim T3 clean speed boost
	if stim_speed_timer > 0.0:
		move_speed_mult *= 1.2
	# Smoke T3 clean: player moves 50% faster inside own smoke
	if kit_tiers.get("smoke_kit", 1) >= 3 and kit_t3_choices.get("smoke_kit", "") == "clean":
		for sz in smoke_zones:
			if player_pos.distance_to(sz.pos) < sz.radius:
				move_speed_mult *= 1.5
				break
	# Familiar T3 clean: corruption gain rate -30%
	# (applied where corruption += lines exist, not here)
	return {move_speed_mult = move_speed_mult, range_mult = range_mult, fire_rate_mult = fire_rate_mult, reload_mult = reload_mult, damage_mult = damage_mult}

# =========================================================
# CORRUPTION
# =========================================================
func _get_biome_at(pos: Vector2) -> String:
	for cave in caves:
		if pos.distance_to(Vector2(cave.pos.x, cave.pos.y)) < cave.radius:
			return "cave"
	for pool in void_pools:
		if pos.distance_to(Vector2(pool.pos.x, pool.pos.y)) < pool.radius:
			return "void_pool"
	for river in rivers:
		for seg in river.segments:
			if pos.distance_to(Vector2(seg.pos.x, seg.pos.y)) < 200.0:
				return "river_bank"
	return "open"

func _apply_corruption_effects():
	# Threshold messages (first time only)
	if corruption >= 36.0 and not corruption_threshold_35:
		corruption_threshold_35 = true
		_show_message("Corruption rising...")
	if corruption >= 60.0 and not corruption_threshold_60:
		corruption_threshold_60 = true
		_show_message("Deeply corrupted")

# =========================================================
# DRAW
# =========================================================
func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# --- World space drawing ---

	# Background
	var bg_screen := _w2s(Vector2.ZERO)
	draw_rect(Rect2(bg_screen, Vector2(WORLD_W, WORLD_H)), Color(0.06, 0.06, 0.1))

	# Grid lines
	var grid_color := Color(0.1, 0.1, 0.15, 0.5)
	for gx in range(0, WORLD_W + 1, GRID_STEP):
		var sx: float = float(gx) - camera_offset.x
		draw_line(Vector2(sx, -camera_offset.y), Vector2(sx, WORLD_H - camera_offset.y), grid_color, 1.0)
	for gy in range(0, WORLD_H + 1, GRID_STEP):
		var sy: float = float(gy) - camera_offset.y
		draw_line(Vector2(-camera_offset.x, sy), Vector2(WORLD_W - camera_offset.x, sy), grid_color, 1.0)

	# Rivers (floor level, before obstacles) — bright blue water, distinct from background
	var water_shimmer: float = 0.75 + 0.15 * sin(hunt_elapsed * 2.2)
	for ri in range(rivers.size()):
		var river: Dictionary = rivers[ri]
		var bridge_pos: Vector2 = bridges[ri].pos
		for seg in river.segments:
			var seg_pos: Vector2 = Vector2(seg.pos.x, seg.pos.y)
			# Match the 160px gap used in obstacle generation
			if seg_pos.distance_to(bridge_pos) < 160.0:
				continue
			var seg_sp: Vector2 = _w2s(seg_pos)
			# Deep water fill
			draw_circle(seg_sp, seg.radius, Color(0.05, 0.35, 0.75, 0.9))
			# Shimmer highlight on top half
			draw_arc(seg_sp, seg.radius * 0.6, TAU * 0.6, TAU * 1.1, 12, Color(0.4, 0.7, 1.0, water_shimmer * 0.5), 2.0)

	# Bridges — wooden plank, clearly passable
	for bridge in bridges:
		var b_sp: Vector2 = _w2s(Vector2(bridge.pos.x, bridge.pos.y))
		var b_dir: Vector2 = Vector2(bridge.dir.x, bridge.dir.y)
		var b_perp: Vector2 = Vector2(-b_dir.y, b_dir.x)
		var half_l: float = bridge.length * 0.5
		var half_w: float = 35.0  # fixed visual width — passable feels
		var c0: Vector2 = b_sp + b_dir * half_l + b_perp * half_w
		var c1: Vector2 = b_sp + b_dir * half_l - b_perp * half_w
		var c2: Vector2 = b_sp - b_dir * half_l - b_perp * half_w
		var c3: Vector2 = b_sp - b_dir * half_l + b_perp * half_w
		# Plank fill
		draw_colored_polygon(PackedVector2Array([c0, c1, c2, c3]), Color(0.45, 0.32, 0.18))
		# Plank border lines (wood grain effect)
		draw_line(c0, c3, Color(0.3, 0.22, 0.12), 1.5)
		draw_line(c1, c2, Color(0.3, 0.22, 0.12), 1.5)
		draw_line(b_sp + b_perp * half_w, b_sp - b_perp * half_w, Color(0.3, 0.22, 0.12, 0.5), 1.0)
		# "BRIDGE" label above
		_draw_text(b_sp + Vector2(-22.0, -half_w - 14.0), "BRIDGE", Color(0.9, 0.8, 0.5, 0.8), 9)

	# Void Pools (floor level, before obstacles)
	for pool in void_pools:
		var pool_sp: Vector2 = _w2s(Vector2(pool.pos.x, pool.pos.y))
		var vp_pulse: float = 0.4 + 0.3 * sin(pool.pulse_phase + hunt_elapsed * 2.5)
		draw_circle(pool_sp, pool.radius, Color(0.25, 0.0, 0.45, vp_pulse * 0.7))
		draw_arc(pool_sp, pool.radius, 0.0, TAU, 32, Color(0.5, 0.0, 0.8, vp_pulse), 2.0)

	# Obstacles
	for obs in obstacles:
		var sp: Vector2 = _w2s(obs.pos)
		draw_circle(sp, obs.radius, Color(0.2, 0.15, 0.25))
		draw_arc(sp, obs.radius, 0.0, TAU, 32, Color(0.4, 0.3, 0.5), 1.5)

	# Exit zone
	if exit_spawned:
		var ep: Vector2 = _w2s(exit_pos)
		var pulse: float = 0.5 + 0.3 * sin(Time.get_ticks_msec() * 0.003)
		draw_circle(ep, 40.0, Color(0.2, 0.9, 0.2, pulse * 0.4))
		draw_arc(ep, 40.0, 0.0, TAU, 32, Color(0.2, 0.9, 0.2, pulse), 2.0)

	# Pickups
	var pulse_alpha: float = 0.3 + 0.3 * sin(Time.get_ticks_msec() * 0.004)
	for p in pickups:
		var sp: Vector2 = _w2s(p.pos)
		if p.type == "ingredient":
			# Pulsing outline
			var outline_size := Vector2(20, 20)
			draw_rect(Rect2(sp - outline_size * 0.5, outline_size), Color(p.color.r, p.color.g, p.color.b, pulse_alpha), false, 1.5)
			# Main square 16x16
			draw_rect(Rect2(sp - Vector2(8, 8), Vector2(16, 16)), p.color)
		elif p.type == "essence":
			# Glow ring
			draw_circle(sp, 14.0, Color(0.5, 0.0, 0.8, 0.3))
			draw_circle(sp, 10.0, Color(0.5, 0.0, 0.8))

	# Ingredient pickups (Phase 3)
	var time_sec: float = Time.get_ticks_msec() * 0.001
	for ip in ingredient_pickups:
		if ip.collected:
			continue
		var sp: Vector2 = _w2s(ip.pos)
		var is_pristine: bool = ip.data.get("is_pristine", false)
		var pickup_color: Color = Color(0.9, 0.9, 0.2) if is_pristine else ip.get("color", Color.WHITE)
		# Main square
		draw_rect(Rect2(sp - Vector2(8, 8), Vector2(16, 16)), pickup_color)
		# Pulsing outline
		var ip_pulse: float = 0.3 + 0.4 * sin(ip.pulse_phase + time_sec * 4.0)
		var outline_size := Vector2(20, 20)
		draw_rect(Rect2(sp - outline_size * 0.5, outline_size), Color(pickup_color.r, pickup_color.g, pickup_color.b, ip_pulse), false, 1.5)
		# Pristine sparkle — 4 orbiting dots
		if is_pristine:
			for si in range(4):
				var angle: float = ip.pulse_phase + time_sec * 2.5 + si * TAU * 0.25
				var sparkle_pos: Vector2 = sp + Vector2(cos(angle), sin(angle)) * 14.0
				draw_circle(sparkle_pos, 2.0, Color(1.0, 1.0, 0.6, 0.8))

	# Enemies
	for e in enemies:
		if e.hp <= 0:
			continue
		# Cave visibility: skip enemies hidden inside caves player is not in
		var enemy_cave: int = e.get("cave_id", -1)
		if enemy_cave >= 0 and player_in_cave != enemy_cave:
			continue
		var sp: Vector2 = _w2s(e.pos)
		var is_elite: bool = e.get("is_elite", false)
		var draw_color: Color = e.color
		# Dormant lurkers draw at 50% alpha
		if e.get("dormant", false):
			draw_color = Color(draw_color.r, draw_color.g, draw_color.b, 0.5)
		draw_circle(sp, e.radius, draw_color)
		if is_elite:
			# Pulsing gold double ring for elites
			var pulse: float = 0.6 + sin(hunt_elapsed * 4.0) * 0.3
			draw_arc(sp, e.radius + 5.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.1, pulse), 2.5)
			draw_arc(sp, e.radius + 10.0, 0.0, TAU, 32, Color(1.0, 0.5, 0.0, pulse * 0.5), 1.5)
		# HP bar — bigger for elites
		var bar_w: float = e.radius * (3.0 if is_elite else 2.0)
		var bar_h: float = 5.0 if is_elite else 3.0
		var bar_pos := Vector2(sp.x - bar_w * 0.5, sp.y - e.radius - 10.0)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.3, 0.3, 0.3))
		var hp_frac: float = float(e.hp) / float(e.max_hp)
		var hp_color: Color = Color(1.0, 0.7, 0.0) if is_elite else Color(0.9, 0.2, 0.2)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_frac, bar_h)), hp_color)
		# Label — elite gets full name in gold, regular gets short name
		if is_elite:
			_draw_text(Vector2(sp.x - e.radius - 10.0, sp.y - e.radius - 22.0), "★ " + e.type, Color(1.0, 0.9, 0.3), 11)
		else:
			var short_name: String = e.type.split(" ")[0]
			_draw_text(Vector2(sp.x - e.radius, sp.y - e.radius - 18.0), short_name, Color(1.0, 1.0, 1.0, 0.75), 10)

	# Cave ceilings (drawn over enemies/world)
	for cave in caves:
		var cave_sp: Vector2 = _w2s(Vector2(cave.pos.x, cave.pos.y))
		if player_in_cave == cave.id:
			# Player inside: translucent border ring + slight atmosphere tint
			draw_arc(cave_sp, cave.radius, 0.0, TAU, 64, Color(0.5, 0.3, 0.7, 0.5), 3.0)
		else:
			# Player outside: dark ceiling hides interior
			draw_circle(cave_sp, cave.radius, Color(0.04, 0.03, 0.06, 0.97))
			draw_arc(cave_sp, cave.radius, 0.0, TAU, 64, Color(0.3, 0.2, 0.4, 0.6), 2.0)

	# Cave atmosphere tint when inside a cave
	if player_in_cave >= 0:
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.1, 0.05, 0.15, 0.18))

	# Kit entities
	for trap in traps:
		if trap.get("active", true):
			var tsp: Vector2 = _w2s(trap.pos)
			var decay_left: float = trap.get("decay_timer", Constants.TRAP_DECAY_TIME)
			var ring_alpha: float = 0.35 if decay_left > 10.0 else clampf(decay_left / 10.0, 0.05, 0.35)
			# Faint circle ring at trigger radius
			draw_arc(tsp, trap.get("radius", Constants.TRAP_RADIUS), 0.0, TAU, 32, Color(1.0, 0.9, 0.1, ring_alpha), 1.5)
			# Diamond center marker
			var diamond_pts := PackedVector2Array([tsp + Vector2(0, -5), tsp + Vector2(5, 0), tsp + Vector2(0, 5), tsp + Vector2(-5, 0)])
			var marker_alpha: float = 1.0 if decay_left > 10.0 else clampf(decay_left / 10.0, 0.2, 1.0)
			draw_colored_polygon(diamond_pts, Color(1.0, 0.9, 0.1, marker_alpha))
	for dc in decoys:
		if dc.get("timer", 0.0) > 0.0:
			var dsp: Vector2 = _w2s(dc.pos)
			draw_circle(dsp, 12.0, Color(0.2, 0.9, 0.2))
	for tr in turrets:
		var tsp2: Vector2 = _w2s(tr.pos)
		draw_rect(Rect2(tsp2 - Vector2(7, 7), Vector2(14, 14)), Color(0.1, 0.8, 0.9))
	for sz in smoke_zones:
		var ssp: Vector2 = _w2s(sz.pos)
		var s_pulse: float = 0.15 + 0.05 * sin(hunt_elapsed * 3.0)
		draw_circle(ssp, sz.radius, Color(0.4, 0.5, 0.6, s_pulse))
		draw_arc(ssp, sz.radius, 0.0, TAU, 32, Color(0.5, 0.6, 0.7, 0.4), 1.5)
	for gw in gravity_wells:
		var gwsp: Vector2 = _w2s(gw.pos)
		var gw_pulse: float = gw.radius + 10.0 * sin(hunt_elapsed * 4.0)
		draw_arc(gwsp, gw_pulse, 0.0, TAU, 32, Color(0.6, 0.1, 0.8, 0.6), 2.0)
	if drone_active:
		var dsp2: Vector2 = _w2s(drone_pos)
		draw_circle(dsp2, 6.0, Color(1.0, 1.0, 1.0))
	if familiar_active:
		var fsp: Vector2 = _w2s(familiar_pos)
		draw_circle(fsp, 6.0, Color(0.6, 0.1, 0.8))

	# Bullets
	for b in bullets:
		var sp: Vector2 = _w2s(b.pos)
		draw_circle(sp, b.radius, b.color)

	# AOE flashes
	for f in aoe_flashes:
		var fsp: Vector2 = _w2s(f.pos)
		var alpha: float = f.timer / 0.3
		draw_arc(fsp, f.radius, 0.0, TAU, 32, Color(f.color.r, f.color.g, f.color.b, alpha * 0.8), 3.0)
		draw_circle(fsp, f.radius, Color(f.color.r, f.color.g, f.color.b, alpha * 0.15))

	# Player
	var pp: Vector2 = _w2s(player_pos)
	var player_color: Color = Color(1.0, 0.2, 0.2) if player_hit_flash > 0.0 else Color(0.2, 0.9, 0.2)
	draw_circle(pp, PLAYER_RADIUS, player_color)

	# --- Screen space HUD ---

	# Joystick
	if joy_active:
		draw_circle(joy_base, JOY_MAX_DIST, Color(1, 1, 1, 0.1))
		draw_arc(joy_base, JOY_MAX_DIST, 0.0, TAU, 32, Color(1, 1, 1, 0.3), 1.5)
		draw_circle(joy_knob, 18.0, Color(1, 1, 1, 0.4))

	# HP bar
	var hp_bar_x := 12.0
	var hp_bar_y := 16.0
	var hp_bar_w := 120.0
	var hp_bar_h := 12.0
	draw_rect(Rect2(hp_bar_x, hp_bar_y, hp_bar_w, hp_bar_h), Color(0.3, 0.1, 0.1))
	var hp_frac: float = clampf(float(player_hp) / float(player_max_hp), 0.0, 1.0)
	draw_rect(Rect2(hp_bar_x, hp_bar_y, hp_bar_w * hp_frac, hp_bar_h), Color(0.2, 0.9, 0.2))

	# Primary weapon ammo text
	if not main_weapon.is_empty():
		var pw: Dictionary = main_weapon
		var pw_reloading: bool = pw.reload_timer > 0.0
		var ammo_color: Color = Color(1.0, 0.8, 0.2) if not pw_reloading else Color(1.0, 0.4, 0.2)
		var ammo_text: String
		if pw.mag_size >= 999:
			ammo_text = WEAPON_DEFS[pw.id].name
		elif pw_reloading:
			ammo_text = "RELOADING..."
		else:
			ammo_text = "%d / %d" % [pw.mag_ammo, pw.mag_size]
		_draw_text(Vector2(hp_bar_x, hp_bar_y + hp_bar_h + 6.0), ammo_text, ammo_color, 13)

	# Target counter (top center)
	var target_text := "Ingredients: %d/%d" % [target_kills, target_total]
	_draw_text(Vector2(vp_size.x * 0.5 - 80.0, 16.0), target_text, Color.WHITE, 14)

	# Corruption meter (top right)
	var corr_x: float = vp_size.x - 92.0
	_draw_text(Vector2(corr_x, 4.0), "CORRUPTION", Color(0.7, 0.4, 0.9, 0.8), 9)
	draw_rect(Rect2(corr_x, 16.0, 80.0, 10.0), Color(0.2, 0.1, 0.2))
	var corr_frac: float = clampf(corruption / corruption_max, 0.0, 1.0)
	var corr_color: Color
	if corruption < 36.0:
		corr_color = Color(0.5, 0.1, 0.8)
	elif corruption < 61.0:
		corr_color = Color(0.8, 0.1, 0.5)
	else:
		corr_color = Color(1.0, 0.1, 0.2)
	if corr_frac > 0.0:
		draw_rect(Rect2(corr_x, 16.0, 80.0 * corr_frac, 10.0), corr_color)

	# Corruption state label + subtext
	var corr_state_label: String
	var corr_state_color: Color
	var corr_subtext: String
	var corr_threshold: int
	if corruption < 15.0:
		corr_state_label = "[CLEAN]"
		corr_state_color = Color(0.3, 0.9, 0.3)
		corr_subtext = "range+  speed+"
		corr_threshold = 0
	elif corruption <= 35.0:
		corr_state_label = "[VALLEY]"
		corr_state_color = Color(0.9, 0.8, 0.2)
		corr_subtext = "debuffs ramp"
		corr_threshold = 1
	elif corruption <= 60.0:
		corr_state_label = "[CORRUPT]"
		corr_state_color = Color(0.9, 0.3, 0.2)
		corr_subtext = "melee+  armor+"
		corr_threshold = 2
	else:
		corr_state_label = "[VOID]"
		corr_state_color = Color(1.0, 0.1, 0.1)
		corr_subtext = "mutating..."
		corr_threshold = 3
	_draw_text(Vector2(corr_x, 28.0), corr_state_label, corr_state_color, 10)
	_draw_text(Vector2(corr_x, 40.0), corr_subtext, Color(0.6, 0.6, 0.6), 9)

	# Corruption threshold transition message
	if corr_threshold != corruption_prev_threshold:
		var transition_msg: String = ""
		match corr_threshold:
			0: transition_msg = "CLEAN — Ranged boosted"
			1: transition_msg = "THE VALLEY — Choose your path"
			2: transition_msg = "CORRUPTED — Melee awakens"
			3: transition_msg = "VOID STATE — Mutations active"
		corruption_prev_threshold = corr_threshold
		if transition_msg != "":
			_show_message(transition_msg)
			hud_message_timer = 3.0

	# Kit buttons (bottom right)
	kit_button_rects.clear()
	for ki in range(equipped_kits.size()):
		var kit_id: String = equipped_kits[ki]
		var kdef: Dictionary = KIT_DEFS.get(kit_id, {})
		var btn_pos: Vector2
		if equipped_kits.size() == 1:
			btn_pos = Vector2(vp_size.x - 90.0, vp_size.y - 55.0)
		else:
			btn_pos = Vector2(vp_size.x - 180.0 + ki * 90.0, vp_size.y - 55.0)
		var btn_rect := Rect2(btn_pos, Vector2(70.0, 36.0))
		kit_button_rects.append(btn_rect)
		var state: Dictionary = kit_states.get(kit_id, {})
		var cd: float = state.get("cooldown", 0.0)
		var charges: int = state.get("charges", -1)
		var can_use: bool = cd <= 0.0 and (charges < 0 or charges > 0)
		var btn_color: Color = Color(0.15, 0.5, 0.15, 0.85) if can_use else Color(0.3, 0.3, 0.3, 0.7)
		draw_rect(btn_rect, btn_color)
		var kit_label: String = kdef.get("name", kit_id)
		if charges >= 0:
			kit_label += " (%d)" % charges
		_draw_text(btn_pos + Vector2(4.0, 6.0), kit_label, Color.WHITE, 11)
		# Cooldown bar + timer text
		if cd > 0.0:
			var max_cd: float = state.get("max_cooldown", 10.0)
			var cd_frac: float = clampf(cd / max_cd, 0.0, 1.0)
			draw_rect(Rect2(btn_pos.x, btn_pos.y + 36.0, 70.0, 4.0), Color(0.2, 0.2, 0.2, 0.6))
			draw_rect(Rect2(btn_pos.x, btn_pos.y + 36.0, 70.0 * cd_frac, 4.0), Color(0.3, 0.8, 0.3, 0.7))
			_draw_text(btn_pos + Vector2(4.0, 22.0), "%ds" % ceili(cd), Color(0.8, 0.8, 0.8, 0.8), 9)

	# XP bar (full width, bottom of screen)
	var xp_bar_y: float = vp_size.y - 20.0
	var xp_bar_h := 8.0
	draw_rect(Rect2(0.0, xp_bar_y, vp_size.x, xp_bar_h), Color(0.1, 0.1, 0.15))
	var xp_frac: float = float(essence_collected) / float(xp_threshold)
	draw_rect(Rect2(0.0, xp_bar_y, vp_size.x * xp_frac, xp_bar_h), Color(0.5, 0.0, 0.9))
	# LV label left of bar
	_draw_text(Vector2(4.0, xp_bar_y - 4.0), "LV %d" % player_level, Color(0.7, 0.5, 1.0), 12)

	# Weapon display (bottom left, above XP bar)
	if not main_weapon.is_empty():
		var wy: float = xp_bar_y - 16.0
		var def: Dictionary = WEAPON_DEFS[main_weapon.id]
		var reload_indicator: String = " (reloading)" if main_weapon.reload_timer > 0 else ""
		var ammo_str: String = "" if main_weapon.mag_size >= 999 else "  %d/%d" % [main_weapon.mag_ammo, main_weapon.mag_size]
		var mut_str: String = ""
		if main_weapon.mutated:
			mut_str = " [%s]" % main_weapon.mutation_type.to_upper()
		_draw_text(Vector2(4.0, wy), def.name + " Lv" + str(main_weapon.level) + mut_str + ammo_str + reload_indicator, Color(0.6,0.7,0.9,0.85), 11)

	# HUD message (center)
	if hud_message != "":
		var msg_alpha: float = clampf(hud_message_timer, 0.0, 1.0)
		_draw_text(Vector2(vp_size.x * 0.5 - 80.0, vp_size.y * 0.5 - 20.0), hud_message, Color(1, 1, 1, msg_alpha), 18)

	# Float texts (ingredient drops, etc.)
	for ft in float_texts:
		var ft_sp: Vector2 = _w2s(ft.pos)
		var ft_alpha: float = clampf(ft.timer, 0.0, 1.0)
		_draw_text(ft_sp, ft.text, Color(ft.color.r, ft.color.g, ft.color.b, ft_alpha), 12)

	# Elite compass — arrow pointing at nearest living elite (hidden when elite is on screen)
	var nearest_elite_pos := Vector2.ZERO
	var found_elite := false
	var nearest_elite_dist := 999999.0
	for e in enemies:
		if e.hp > 0 and e.get("is_elite", false):
			var d: float = player_pos.distance_to(e.pos)
			if d < nearest_elite_dist:
				nearest_elite_dist = d
				nearest_elite_pos = e.pos
				found_elite = true

	if found_elite:
		# Check if elite is currently visible on screen
		var elite_screen_pos: Vector2 = _w2s(nearest_elite_pos)
		var on_screen: bool = (elite_screen_pos.x >= 0.0 and elite_screen_pos.x <= vp_size.x and
							   elite_screen_pos.y >= 0.0 and elite_screen_pos.y <= vp_size.y)
		if not on_screen:
			# Draw compass arrow on screen edge
			var screen_center: Vector2 = vp_size * 0.5
			var dir_to_elite: Vector2 = (nearest_elite_pos - player_pos).normalized()
			# Find intersection with screen edge (margin 28px from edge)
			var margin := 28.0
			var arrow_pos: Vector2
			var tx: float = 999999.0
			var ty: float = 999999.0
			if dir_to_elite.x > 0.001:
				tx = (vp_size.x - margin - screen_center.x) / dir_to_elite.x
			elif dir_to_elite.x < -0.001:
				tx = (margin - screen_center.x) / dir_to_elite.x
			if dir_to_elite.y > 0.001:
				ty = (vp_size.y - margin - screen_center.y) / dir_to_elite.y
			elif dir_to_elite.y < -0.001:
				ty = (margin - screen_center.y) / dir_to_elite.y
			var t: float = minf(tx, ty)
			arrow_pos = screen_center + dir_to_elite * t

			# Pulse based on distance — faster when closer
			var pulse_speed: float = remap(nearest_elite_dist, 100.0, 1200.0, 8.0, 2.0)
			var pulse: float = 0.5 + 0.5 * sin(hunt_elapsed * pulse_speed)
			var arrow_color := Color(1.0, 0.85, 0.1, 0.6 + 0.4 * pulse)

			# Draw triangle arrow
			var arrow_size := 14.0
			var forward: Vector2 = dir_to_elite * arrow_size
			var perp: Vector2 = Vector2(-dir_to_elite.y, dir_to_elite.x) * (arrow_size * 0.5)
			var tip: Vector2 = arrow_pos + forward
			var left: Vector2 = arrow_pos - perp
			var right: Vector2 = arrow_pos + perp
			draw_colored_polygon(PackedVector2Array([tip, left, right]), arrow_color)
			draw_polyline(PackedVector2Array([tip, left, right, tip]), Color(1.0, 1.0, 0.5, 0.9 * pulse), 1.5)

			# Distance label below arrow
			var dist_m: int = int(nearest_elite_dist / 50.0)  # rough "meters"
			_draw_text(arrow_pos + Vector2(-12.0, 10.0), "%dm" % dist_m, Color(1.0, 0.9, 0.3, 0.8 * pulse), 10)

	# Dead overlay
	if dead:
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0, 0, 0, 0.6))
		_draw_text(Vector2(vp_size.x * 0.5 - 40.0, vp_size.y * 0.5 - 20.0), "DEAD", Color(1, 0.2, 0.2), 32)

func _w2s(world_pos: Vector2) -> Vector2:
	return world_pos - camera_offset

func _draw_text(pos: Vector2, text: String, color: Color, font_size: int = 16) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

# =========================================================
# XP CURVE
# =========================================================
func _xp_needed_for_level(lv: int) -> int:
	if lv <= 5: return 20
	elif lv <= 10: return 35
	else: return 55

# =========================================================
# KIT SYSTEM
# =========================================================
func _init_kit_state(kit_id: String) -> Dictionary:
	match kit_id:
		"stim_pack": return {cooldown = 0.0, max_cooldown = 20.0}
		"flash_trap": return {cooldown = 0.0, charges = Constants.TRAP_CHARGES_BASE, max_charges = Constants.TRAP_CHARGES_BASE, recharge_timer = 0.0}
		"blink_kit": return {cooldown = 0.0, max_cooldown = 10.0}
		"chain_kit": return {cooldown = 0.0, max_cooldown = 12.0}
		"charge_kit": return {cooldown = 0.0, max_cooldown = 12.0, charging = false}
		"mirage_kit": return {cooldown = 0.0, max_cooldown = 18.0}
		"turret_kit": return {charges = 1}
		"smoke_kit": return {cooldown = 0.0, max_cooldown = 14.0}
		"anchor_kit": return {cooldown = 0.0, max_cooldown = 20.0}
		"drone_kit": return {active = true}
		"familiar_kit": return {active = true}
		"pack_kit": return {cooldown = 0.0, max_cooldown = 25.0}
		"void_surge": return {cooldown = 0.0, max_cooldown = 5.0, active = false, timer = 0.0}
		"rupture_kit": return {cooldown = 0.0, max_cooldown = 30.0}
		_: return {cooldown = 0.0, max_cooldown = 15.0}

func _activate_kit(kit_id: String) -> void:
	if not kit_states.has(kit_id):
		return
	var state: Dictionary = kit_states[kit_id]
	var cd: float = state.get("cooldown", 0.0)
	if cd > 0.0:
		return
	var charges: int = state.get("charges", -1)
	if charges == 0:
		return

	var tier: int = kit_tiers.get(kit_id, 1)
	var t3_choice: String = kit_t3_choices.get(kit_id, "")
	var resonance: Dictionary = weapon_mods.get("_resonance", {})

	match kit_id:
		"stim_pack":
			var heal: int = 4 if tier < 2 else 5
			player_hp = mini(player_hp + heal, player_max_hp)
			corruption += 15.0
			var stim_cd: float = 20.0 if tier < 2 else 15.0
			_show_message("Stim! +%dHP +15 corruption" % heal)
			state.cooldown = stim_cd
			# T3 clean: speed boost
			if tier >= 3 and t3_choice == "clean":
				stim_speed_timer = 5.0
		"flash_trap":
			if charges > 0:
				# Enforce max active traps — remove oldest if at cap
				var active_count: int = 0
				for _tr in traps:
					if _tr.get("active", true):
						active_count += 1
				if active_count >= Constants.TRAP_MAX_ACTIVE:
					for _ti in range(traps.size()):
						if traps[_ti].get("active", true):
							traps.remove_at(_ti)
							break
				traps.append({pos = player_pos, radius = Constants.TRAP_RADIUS, active = true, decay_timer = Constants.TRAP_DECAY_TIME, triggered_enemies = []})
				state.charges = charges - 1
				_show_message("Trap placed! (%d charges)" % state.charges)
		"blink_kit":
			var blink_dir: Vector2 = Vector2.UP
			if joy_active:
				var diff: Vector2 = joy_knob - joy_base
				if diff.length() > 5.0:
					blink_dir = diff.normalized()
			var old_pos: Vector2 = player_pos
			# Resonance: linked_fuse — teleport to nearest triggered trap if any within 400px
			var blink_to_trap: bool = false
			if resonance.get("linked_fuse", false):
				var best_trap_dist: float = 400.0
				var best_trap_pos: Vector2 = Vector2.ZERO
				for tr in traps:
					if not tr.get("active", true):
						continue
					var td: float = player_pos.distance_to(tr.pos)
					if td < best_trap_dist:
						best_trap_dist = td
						best_trap_pos = tr.pos
						blink_to_trap = true
				if blink_to_trap:
					player_pos = best_trap_pos
			if not blink_to_trap:
				player_pos += blink_dir * 200.0
			player_pos.x = clampf(player_pos.x, PLAYER_RADIUS, WORLD_W - PLAYER_RADIUS)
			player_pos.y = clampf(player_pos.y, PLAYER_RADIUS, WORLD_H - PLAYER_RADIUS)
			# T2: stun field at departure point
			if tier >= 2:
				aoe_flashes.append({pos=old_pos, radius=100.0, timer=0.3, color=Color(0.8,0.8,1.0,0.5)})
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp > 0 and old_pos.distance_to(e.pos) < 100.0:
						e.stunned_timer = 1.5
						enemies[ei] = e
			# T3 clean: empowered next shot
			if tier >= 3 and t3_choice == "clean":
				blink_empowered = true
			# T3 void: pull enemies with you
			if tier >= 3 and t3_choice == "void":
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp > 0 and old_pos.distance_to(e.pos) < 150.0:
						e.pos = player_pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
						enemies[ei] = e
			# Resonance: smoke_blink — spawn smoke at new pos
			if resonance.get("smoke_blink", false):
				smoke_zones.append({pos=player_pos, radius=150.0, timer=6.0})
			state.cooldown = 10.0
			_show_message("Blink!")
		"chain_kit":
			var chain_dir: Vector2 = Vector2.UP
			var nearest_d: float = 999999.0
			var nearest_idx: int = -1
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp > 0:
					var d: float = player_pos.distance_to(e.pos)
					if d < nearest_d:
						nearest_d = d
						nearest_idx = ei
						chain_dir = (e.pos - player_pos).normalized()
			bullets.append({
				pos = player_pos + chain_dir * (PLAYER_RADIUS + 6.0),
				vel = chain_dir * 350.0,
				radius = 6.0,
				color = Color(0.3, 0.9, 1.0),
				damage = 0,
				lifetime = 1.0,
				from_player = true,
				tether = true,
			})
			# T2: arc to second enemy
			if tier >= 2 and nearest_idx >= 0:
				var first_pos: Vector2 = enemies[nearest_idx].pos
				var second_dist: float = 200.0
				var second_idx: int = -1
				for ei in range(enemies.size()):
					if ei == nearest_idx or enemies[ei].hp <= 0:
						continue
					var d2: float = first_pos.distance_to(enemies[ei].pos)
					if d2 < second_dist:
						second_dist = d2
						second_idx = ei
				if second_idx >= 0:
					enemies[second_idx].stunned_timer = 3.0
			# T3 clean: chained enemies take +50% damage (marked)
			if tier >= 3 and t3_choice == "clean" and nearest_idx >= 0:
				enemies[nearest_idx]["marked_timer"] = 5.0
				enemies[nearest_idx]["marked_dmg_bonus"] = 1.5
			# T3 void: tethered enemies drain corruption
			if tier >= 3 and t3_choice == "void" and nearest_idx >= 0:
				enemies[nearest_idx]["chain_drain"] = true
			state.cooldown = 12.0
		"charge_kit":
			if not state.get("charging", false):
				state.charging = true
				_show_message("Charging...")
			else:
				var charge_dmg: int = 2 if tier < 2 else 6
				# T3 void: dash forward instead of knockback
				if tier >= 3 and t3_choice == "void":
					var dash_dir: Vector2 = Vector2.UP
					if joy_active:
						var diff: Vector2 = joy_knob - joy_base
						if diff.length() > 5.0:
							dash_dir = diff.normalized()
					var dash_end: Vector2 = player_pos + dash_dir * 300.0
					dash_end.x = clampf(dash_end.x, PLAYER_RADIUS, WORLD_W - PLAYER_RADIUS)
					dash_end.y = clampf(dash_end.y, PLAYER_RADIUS, WORLD_H - PLAYER_RADIUS)
					for ei in range(enemies.size()):
						var e: Dictionary = enemies[ei]
						if e.hp <= 0:
							continue
						if _segment_intersects_circle(player_pos, dash_end, e.pos, e.radius + PLAYER_RADIUS):
							e.hp -= 3
							enemies[ei] = e
							if e.hp <= 0:
								_on_enemy_killed(ei)
					player_pos = dash_end
					aoe_flashes.append({pos=player_pos, radius=30.0, timer=0.3, color=Color(0.6,0.0,0.9,0.6)})
				else:
					var kb_mult: float = 2.0 if (tier >= 3 and t3_choice == "clean") else 1.0
					for ei in range(enemies.size()):
						var e: Dictionary = enemies[ei]
						if e.hp <= 0:
							continue
						if player_pos.distance_to(e.pos) < 150.0:
							var push_dir: Vector2 = (e.pos - player_pos).normalized()
							e.pos += push_dir * 200.0 * kb_mult
							e.hp -= charge_dmg
							# T3 clean: stun after knockback
							if tier >= 3 and t3_choice == "clean":
								e.stunned_timer = 1.0
							enemies[ei] = e
							if e.hp <= 0:
								_on_enemy_killed(ei)
					aoe_flashes.append({pos = player_pos, radius = 150.0, timer = 0.3, color = Color(1.0, 0.8, 0.2, 0.6)})
				state.charging = false
				state.cooldown = 12.0
				_show_message("CHARGE!")
		"mirage_kit":
			var decoy_count: int = 1
			if tier >= 3 and t3_choice == "clean":
				decoy_count = 3
			for _dc in range(decoy_count):
				var new_decoy: Dictionary = {pos = player_pos + Vector2(randf_range(-40, 40), randf_range(-40, 40)), hp = 5, timer = 6.0}
				if tier >= 3 and t3_choice == "void":
					new_decoy["void_mirror"] = true
				decoys.append(new_decoy)
			state.cooldown = 18.0
			_show_message("Decoy deployed!")
		"turret_kit":
			if charges > 0:
				var turret_dur: float = 12.0 if tier < 2 else 20.0
				if tier >= 3 and t3_choice == "clean":
					turret_dur = 25.0
				var new_turret: Dictionary = {pos = player_pos, timer = turret_dur, fire_timer = 0.0, burst_count = 0}
				if tier >= 3 and t3_choice == "clean":
					new_turret["shield_hp"] = 10
				if tier >= 3 and t3_choice == "void":
					new_turret["void_rounds"] = true
				turrets.append(new_turret)
				state.charges = charges - 1
				_show_message("Turret deployed!")
		"smoke_kit":
			var new_smoke: Dictionary = {pos = player_pos, radius = 150.0, timer = 6.0}
			if tier >= 2:
				new_smoke["slowing"] = true
			if tier >= 3 and t3_choice == "void":
				new_smoke["toxic"] = true
			smoke_zones.append(new_smoke)
			state.cooldown = 14.0
			_show_message("Smoke!")
		"anchor_kit":
			var gw: Dictionary = {pos = player_pos, radius = 400.0, timer = 4.0}
			if tier >= 2:
				gw["pulse_phase"] = 0  # 0=pull1, 1=pause, 2=pull2
				gw["total_timer"] = 9.0  # 4s pull + 1s pause + 4s pull
				gw.timer = 9.0
			if tier >= 3 and t3_choice == "clean":
				gw["damage_field"] = true
			if tier >= 3 and t3_choice == "void":
				gw["explode_on_end"] = true
				gw["enemies_inside"] = 0
			gravity_wells.append(gw)
			state.cooldown = 20.0
			_show_message("Gravity well!")
		"drone_kit":
			drone_active = true
			drone_pos = player_pos + Vector2(50, 0)
		"familiar_kit":
			familiar_active = true
			familiar_pos = player_pos + Vector2(60, 0)
		"pack_kit":
			if state.cooldown <= 0.0:
				var rng := RandomNumberGenerator.new()
				rng.randomize()
				var ally_count: int = 2 if tier < 2 else 4
				pack_allies.clear()
				for _a in range(ally_count):
					_spawn_single_enemy("Rift Parasite", false, rng)
					var ally_idx: int = enemies.size() - 1
					enemies[ally_idx].is_aggroed = true
					enemies[ally_idx].cave_id = -1
					enemies[ally_idx].pos = player_pos + Vector2(randf_range(-60, 60), randf_range(-60, 60))
					enemies[ally_idx]["is_ally"] = true
					pack_allies.append(ally_idx)
				state.cooldown = 25.0
				_show_message("Allies summoned!")
		"void_surge":
			var cost: int = 20
			# T3 clean: free at 60+ corruption
			if tier >= 3 and t3_choice == "clean" and corruption >= 60.0:
				cost = 0
			if corruption >= cost:
				corruption -= cost
				state.active = true
				state.timer = 3.0
				state.cooldown = 5.0
				# Resonance: surge_charge resets charge kit cooldown
				if resonance.get("surge_charge", false) and kit_states.has("charge_kit"):
					kit_states["charge_kit"].cooldown = 0.0
				# T3 void: fire ring of 8 bullets
				if tier >= 3 and t3_choice == "void":
					for bi in range(8):
						var angle: float = float(bi) * TAU / 8.0
						var bdir: Vector2 = Vector2(cos(angle), sin(angle))
						bullets.append({pos=player_pos + bdir * 20.0, vel=bdir * 300.0, radius=5.0, color=Color(0.6,0.0,0.9), damage=3, lifetime=0.8, from_player=true, weapon_id="void_surge"})
				_show_message("Void Surge!")
		"rupture_kit":
			var dmg: int = int(corruption / 5.0)
			var rupture_active: bool = true
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp <= 0:
					continue
				if player_pos.distance_to(e.pos) < 200.0:
					e.hp -= dmg
					enemies[ei] = e
					if e.hp <= 0:
						_on_enemy_killed(ei)
			aoe_flashes.append({pos = player_pos, radius = 200.0, timer = 0.3, color = Color(0.6, 0.0, 0.9, 0.7)})
			# T2: leave void pool at player pos
			if tier >= 2:
				var pool_timer: float = 15.0
				if tier >= 3 and t3_choice == "void":
					pool_timer = 9999.0
				void_pools.append({pos=player_pos, radius=80.0, pulse_phase=0.0, timer=pool_timer, runtime=true})
			# Resonance: void_feedback recharges void surge
			if resonance.get("void_feedback", false) and kit_states.has("void_surge"):
				kit_states["void_surge"].cooldown = 0.0
			corruption = 0.0
			state.cooldown = 30.0
			_show_message("RUPTURE! -%d corruption" % dmg)

	kit_states[kit_id] = state

func _update_kit_cooldowns(delta: float) -> void:
	for kit_id in equipped_kits:
		if not kit_states.has(kit_id): continue
		var state: Dictionary = kit_states[kit_id]
		if state.has("cooldown") and state.cooldown > 0.0:
			state.cooldown -= delta
		if kit_id == "void_surge" and state.get("active", false):
			state.timer -= delta
			# T2: void aura during burst
			if kit_tiers.get("void_surge", 1) >= 2:
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp > 0 and player_pos.distance_to(e.pos) < 100.0:
						e.hp -= maxi(1, int(delta))
						enemies[ei] = e
						if e.hp <= 0:
							_on_enemy_killed(ei)
			if state.timer <= 0.0:
				state.active = false
		kit_states[kit_id] = state
	# Stim speed timer
	if stim_speed_timer > 0.0:
		stim_speed_timer -= delta
	# Baton hit timer for static_charge mastery
	if baton_hit_timer > 0.0:
		baton_hit_timer -= delta
		if baton_hit_timer <= 0.0:
			baton_hit_count = 0
	# Update runtime void pools (from rupture T2)
	var vpi := void_pools.size() - 1
	while vpi >= 0:
		if void_pools[vpi].get("runtime", false):
			var t: float = void_pools[vpi].get("timer", 9999.0) - delta
			void_pools[vpi]["timer"] = t
			if t <= 0.0:
				void_pools.remove_at(vpi)
		vpi -= 1
	# Update walls
	var wi := walls.size() - 1
	while wi >= 0:
		walls[wi].timer -= delta
		if walls[wi].timer <= 0.0:
			walls.remove_at(wi)
		wi -= 1

func _update_traps(delta: float) -> void:
	var flash_tier: int = kit_tiers.get("flash_trap", 1)
	var flash_t3: String = kit_t3_choices.get("flash_trap", "")

	# Recharge trap charges over time
	if kit_states.has("flash_trap"):
		var fs: Dictionary = kit_states["flash_trap"]
		var max_ch: int = fs.get("max_charges", Constants.TRAP_CHARGES_BASE)
		if fs.get("charges", 0) < max_ch:
			fs["recharge_timer"] = fs.get("recharge_timer", 0.0) + delta
			if fs["recharge_timer"] >= Constants.TRAP_RECHARGE_TIME:
				fs["recharge_timer"] = 0.0
				fs["charges"] = fs.get("charges", 0) + 1
		else:
			fs["recharge_timer"] = 0.0
		kit_states["flash_trap"] = fs

	# Update traps: decay, trigger
	var i := traps.size() - 1
	while i >= 0:
		var trap: Dictionary = traps[i]
		if not trap.get("active", true):
			traps.remove_at(i)
			i -= 1
			continue
		# Decay timer
		trap["decay_timer"] = trap.get("decay_timer", Constants.TRAP_DECAY_TIME) - delta
		if trap["decay_timer"] <= 0.0:
			traps.remove_at(i)
			i -= 1
			continue
		# Check enemies in trigger radius
		var triggered_enemies: Array = trap.get("triggered_enemies", [])
		for ei in range(enemies.size()):
			var e: Dictionary = enemies[ei]
			if e.hp <= 0:
				continue
			if triggered_enemies.has(ei):
				continue
			if e.pos.distance_to(trap.pos) < trap.get("radius", Constants.TRAP_RADIUS):
				# Apply damage + slow (one trigger per enemy per trap)
				e.hp -= Constants.TRAP_DAMAGE
				e["slow_timer"] = Constants.TRAP_SLOW_DURATION
				e["slow_factor"] = 0.4
				triggered_enemies.append(ei)
				# T3 clean: marked for +40% damage
				if flash_tier >= 3 and flash_t3 == "clean":
					e["marked_timer"] = 5.0
					e["marked_dmg_bonus"] = 1.4
				# T3 void: void energy — corruption + speed boost
				if flash_tier >= 3 and flash_t3 == "void":
					for ei2 in range(enemies.size()):
						var e2: Dictionary = enemies[ei2]
						if e2.hp > 0 and trap.pos.distance_to(e2.pos) < 120.0:
							corruption += 10.0
							e2.speed *= 1.2
							enemies[ei2] = e2
				enemies[ei] = e
				if e.hp <= 0:
					_on_enemy_killed(ei)
				aoe_flashes.append({pos = trap.pos, radius = Constants.TRAP_RADIUS, timer = 0.3, color = Color(1.0, 0.9, 0.1, 0.5)})
		trap["triggered_enemies"] = triggered_enemies
		traps[i] = trap
		i -= 1
	# T2: chain trigger — if 2 traps within 300px, one triggering causes nearby to also fire
	if flash_tier >= 2:
		for ti in range(traps.size()):
			var t_triggered: Array = traps[ti].get("triggered_enemies", [])
			if t_triggered.is_empty():
				continue
			var t_pos: Vector2 = traps[ti].pos
			for tj in range(traps.size()):
				if tj == ti:
					continue
				if traps[tj].get("active", true) and t_pos.distance_to(traps[tj].pos) < 300.0:
					var tj_triggered: Array = traps[tj].get("triggered_enemies", [])
					for ei in range(enemies.size()):
						var e: Dictionary = enemies[ei]
						if e.hp > 0 and not tj_triggered.has(ei) and e.pos.distance_to(traps[tj].pos) < Constants.TRAP_RADIUS:
							e.hp -= Constants.TRAP_DAMAGE
							e["slow_timer"] = Constants.TRAP_SLOW_DURATION
							e["slow_factor"] = 0.4
							tj_triggered.append(ei)
							enemies[ei] = e
							if e.hp <= 0:
								_on_enemy_killed(ei)
					traps[tj]["triggered_enemies"] = tj_triggered
					aoe_flashes.append({pos=traps[tj].pos, radius=Constants.TRAP_RADIUS, timer=0.3, color=Color(1.0,0.9,0.1,0.5)})

func _update_decoys(delta: float) -> void:
	var mirage_tier: int = kit_tiers.get("mirage_kit", 1)
	var i := decoys.size() - 1
	while i >= 0:
		decoys[i].timer -= delta
		var should_remove: bool = decoys[i].timer <= 0.0 or decoys[i].get("hp", 5) <= 0
		# T3 void: void mirror — enemies near it take 1 dmg/s
		if decoys[i].get("void_mirror", false):
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp > 0 and e.pos.distance_to(decoys[i].pos) < 60.0:
					e.hp -= maxi(1, int(delta))
					enemies[ei] = e
					if e.hp <= 0:
						_on_enemy_killed(ei)
		if should_remove:
			# T2: decoy explodes on death/expire
			if mirage_tier >= 2:
				var dpos: Vector2 = decoys[i].pos
				aoe_flashes.append({pos=dpos, radius=40.0, timer=0.3, color=Color(1.0,0.6,0.2,0.6)})
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp > 0 and dpos.distance_to(e.pos) < 40.0:
						e.hp -= 3
						enemies[ei] = e
						if e.hp <= 0:
							_on_enemy_killed(ei)
			decoys.remove_at(i)
		i -= 1

func _update_turrets(delta: float) -> void:
	var turret_tier: int = kit_tiers.get("turret_kit", 1)
	var resonance: Dictionary = weapon_mods.get("_resonance", {})
	var i := turrets.size() - 1
	while i >= 0:
		var tr: Dictionary = turrets[i]
		tr.timer -= delta
		if tr.timer <= 0.0:
			turrets.remove_at(i)
			i -= 1
			continue
		# Resonance: turret_familiar healing aura
		if resonance.get("turret_familiar", false):
			var heal_timer: float = tr.get("heal_timer", 5.0)
			heal_timer -= delta
			if heal_timer <= 0.0:
				heal_timer = 5.0
				player_hp = mini(player_hp + 1, player_max_hp)
			tr["heal_timer"] = heal_timer
		tr.fire_timer -= delta
		if tr.fire_timer <= 0.0:
			# T2: burst mode — 3 shots then 0.5s pause
			if turret_tier >= 2:
				var bc: int = tr.get("burst_count", 0)
				if bc < 3:
					tr.fire_timer = 0.1
					tr["burst_count"] = bc + 1
				else:
					tr.fire_timer = 0.5
					tr["burst_count"] = 0
					turrets[i] = tr
					i -= 1
					continue
			else:
				tr.fire_timer = 0.125
			# Find nearest enemy
			var best_dist: float = 300.0
			var best_idx: int = -1
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp <= 0:
					continue
				var d: float = tr.pos.distance_to(e.pos)
				if d < best_dist:
					best_dist = d
					best_idx = ei
			if best_idx >= 0:
				var e: Dictionary = enemies[best_idx]
				# T3 clean: turret has shield
				if tr.get("shield_hp", 0) > 0:
					pass  # shield absorbs damage passively
				e.hp -= 1
				enemies[best_idx] = e
				if e.hp <= 0:
					# T3 void: killed enemies explode
					if tr.get("void_rounds", false):
						aoe_flashes.append({pos=e.pos, radius=30.0, timer=0.2, color=Color(0.6,0.0,0.9,0.5)})
						for ei2 in range(enemies.size()):
							if ei2 == best_idx or enemies[ei2].hp <= 0:
								continue
							if e.pos.distance_to(enemies[ei2].pos) < 30.0:
								enemies[ei2].hp -= 1
								if enemies[ei2].hp <= 0:
									_on_enemy_killed(ei2)
					_on_enemy_killed(best_idx)
		turrets[i] = tr
		i -= 1

func _update_smoke(delta: float) -> void:
	var smoke_tier: int = kit_tiers.get("smoke_kit", 1)
	var smoke_t3: String = kit_t3_choices.get("smoke_kit", "")
	var i := smoke_zones.size() - 1
	while i >= 0:
		smoke_zones[i].timer -= delta
		if smoke_zones[i].timer <= 0.0:
			smoke_zones.remove_at(i)
		else:
			var sz: Dictionary = smoke_zones[i]
			# Enemies inside smoke lose aggro (if not slowing-only zone)
			if not sz.get("slowing", false):
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp > 0 and not e.is_aggroed:
						continue
					if e.hp > 0 and e.pos.distance_to(sz.pos) < sz.radius:
						e.is_aggroed = false
						enemies[ei] = e
			# T3 void: toxic smoke — enemies take 1 dmg/s, player gains corruption
			if sz.get("toxic", false):
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp > 0 and e.pos.distance_to(sz.pos) < sz.radius:
						e.hp -= maxi(1, int(delta))
						enemies[ei] = e
						if e.hp <= 0:
							_on_enemy_killed(ei)
				if player_pos.distance_to(sz.pos) < sz.radius:
					corruption += 3.0 * delta
		i -= 1

func _update_gravity_wells(delta: float) -> void:
	var anchor_tier: int = kit_tiers.get("anchor_kit", 1)
	var resonance: Dictionary = weapon_mods.get("_resonance", {})
	var i := gravity_wells.size() - 1
	while i >= 0:
		gravity_wells[i].timer -= delta
		if gravity_wells[i].timer <= 0.0:
			var gw_end: Dictionary = gravity_wells[i]
			# T3 void: explode on end
			if gw_end.get("explode_on_end", false):
				var count: int = gw_end.get("enemies_inside", 0)
				var explode_dmg: int = 3 * maxi(1, count)
				aoe_flashes.append({pos=gw_end.pos, radius=gw_end.radius * 0.5, timer=0.3, color=Color(0.6,0.0,0.9,0.7)})
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp > 0 and e.pos.distance_to(gw_end.pos) < gw_end.radius * 0.5:
						e.hp -= explode_dmg
						enemies[ei] = e
						if e.hp <= 0:
							_on_enemy_killed(ei)
			# Resonance: overcharge_drone
			if resonance.get("overcharge_drone", false) and drone_active:
				overcharge_timer = 5.0
			gravity_wells.remove_at(i)
		else:
			var gw: Dictionary = gravity_wells[i]
			# T2: pulse behavior — determine if currently pulling
			var pulling: bool = true
			if gw.has("pulse_phase"):
				var elapsed: float = gw.get("total_timer", 9.0) - gw.timer
				if elapsed >= 4.0 and elapsed < 5.0:
					pulling = false  # 1s pause between pulses
			if pulling:
				var pull_speed: float = 120.0
				# Mastery: nested_vortex pulls faster
				if weapon_mods.get(main_weapon.get("id", ""), {}).get("vortex_speed", 0.0) > 1.0:
					pull_speed *= weapon_mods.get(main_weapon.get("id", ""), {}).get("vortex_speed", 1.0)
				var enemy_count: int = 0
				for ei in range(enemies.size()):
					var e: Dictionary = enemies[ei]
					if e.hp <= 0:
						continue
					var d: float = e.pos.distance_to(gw.pos)
					if d < gw.radius and d > 5.0:
						var pull_dir: Vector2 = (gw.pos - e.pos).normalized()
						e.pos += pull_dir * pull_speed * delta
						enemy_count += 1
						# T3 clean: damage field
						if gw.get("damage_field", false):
							e.hp -= maxi(1, int(delta))
							if e.hp <= 0:
								enemies[ei] = e
								_on_enemy_killed(ei)
								continue
						enemies[ei] = e
				if gw.has("enemies_inside"):
					gw["enemies_inside"] = maxi(gw.get("enemies_inside", 0), enemy_count)
			gravity_wells[i] = gw
		i -= 1

func _update_drone(delta: float) -> void:
	if not drone_active:
		return
	# Orbit player
	var orbit_angle: float = fmod(hunt_elapsed * 2.0, TAU)
	drone_pos = player_pos + Vector2(cos(orbit_angle), sin(orbit_angle)) * 50.0
	drone_intercept_timer -= delta
	if drone_barrier_timer > 0.0:
		drone_barrier_timer -= delta
	if overcharge_timer > 0.0:
		overcharge_timer -= delta

	var drone_tier: int = kit_tiers.get("drone_kit", 1)
	var drone_path: String = kit_t2_paths.get("drone_kit", "")

	# T2: shield path — reduced intercept cooldown
	if drone_tier >= 2 and drone_path == "shield":
		if drone_intercept_timer > 2.0:
			drone_intercept_timer = minf(drone_intercept_timer, 2.0)
		# Melee intercept: push back enemies within 30px
		for ei in range(enemies.size()):
			var e: Dictionary = enemies[ei]
			if e.hp > 0 and drone_pos.distance_to(e.pos) < 30.0:
				var push: Vector2 = (e.pos - drone_pos).normalized()
				e.pos += push * 60.0
				enemies[ei] = e

	# T2: attack path — fire at nearest enemy every 2s
	if drone_tier >= 2 and drone_path == "attack":
		drone_fire_timer -= delta
		var fire_interval: float = 2.0
		if overcharge_timer > 0.0:
			fire_interval = 1.0
		if drone_fire_timer <= 0.0:
			drone_fire_timer = fire_interval
			var best_dist: float = 300.0
			var best_idx: int = -1
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp <= 0:
					continue
				var d: float = drone_pos.distance_to(e.pos)
				if d < best_dist:
					best_dist = d
					best_idx = ei
			if best_idx >= 0:
				var e: Dictionary = enemies[best_idx]
				e.hp -= 2
				enemies[best_idx] = e
				aoe_flashes.append({pos=drone_pos, radius=8.0, timer=0.1, color=Color(0.3,0.9,1.0,0.8)})
				if e.hp <= 0:
					_on_enemy_killed(best_idx)

	# T2: harvest path — auto-collect nearby essence/ingredients
	if drone_tier >= 2 and drone_path == "harvest":
		# Auto-collect essence pickups within 200px of drone
		for pi in range(pickups.size() - 1, -1, -1):
			var p: Dictionary = pickups[pi]
			if p.type == "essence" and drone_pos.distance_to(p.pos) < 200.0:
				essence_collected += 1
				if essence_collected >= xp_threshold:
					essence_collected -= xp_threshold
					player_level += 1
					xp_threshold = _xp_needed_for_level(player_level)
					_level_up()
				pickups.remove_at(pi)
		# Auto-collect ingredient pickups within 200px
		for ipi in range(ingredient_pickups.size()):
			var ip: Dictionary = ingredient_pickups[ipi]
			if not ip.collected and drone_pos.distance_to(ip.pos) < 200.0:
				ip.collected = true
				ingredient_pickups[ipi] = ip
				run_ingredients.append(ip.data)

func _update_familiar(delta: float) -> void:
	if not familiar_active:
		return
	var fam_tier: int = kit_tiers.get("familiar_kit", 1)
	var fam_t3: String = kit_t3_choices.get("familiar_kit", "")
	# Orbit player
	var orbit_angle: float = fmod(hunt_elapsed * 1.5 + PI, TAU)
	familiar_pos = player_pos + Vector2(cos(orbit_angle), sin(orbit_angle)) * 60.0
	# T3 void: at corruption >= 60, familiar splits into 2
	if fam_tier >= 3 and fam_t3 == "void" and corruption >= 60.0 and not familiar2_active:
		familiar2_active = true
	if familiar2_active:
		var orbit2: float = fmod(hunt_elapsed * 1.5 + PI + PI, TAU)
		familiar2_pos = player_pos + Vector2(cos(orbit2), sin(orbit2)) * 60.0
	# Corruption cost
	familiar_corruption_timer -= delta
	var corr_interval: float = 8.0 if fam_tier < 2 else 6.0
	if familiar_corruption_timer <= 0.0:
		corruption += 1.0
		familiar_corruption_timer = corr_interval
	# Attack nearby enemy
	familiar_attack_timer -= delta
	var atk_interval: float = 3.0 if fam_tier < 2 else 2.0
	if familiar_attack_timer <= 0.0:
		familiar_attack_timer = atk_interval
		var positions: Array[Vector2] = [familiar_pos]
		if familiar2_active:
			positions.append(familiar2_pos)
		for fpos in positions:
			var best_dist: float = 120.0
			var best_idx: int = -1
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp <= 0:
					continue
				var d: float = fpos.distance_to(e.pos)
				if d < best_dist:
					best_dist = d
					best_idx = ei
			if best_idx >= 0:
				var e: Dictionary = enemies[best_idx]
				e.hp -= 2
				enemies[best_idx] = e
				if e.hp <= 0:
					_on_enemy_killed(best_idx)

# =========================================================
# MODIFIER APPLICATION
# =========================================================
func _apply_modifier(mod_id: String) -> void:
	match mod_id:
		"tough":
			player_max_hp += 3
			player_hp = player_max_hp
		"speed":
			player_speed += 25.0
		"reload":
			var mods: Dictionary = weapon_mods.get(main_weapon.id, {})
			mods["reload_mult"] = mods.get("reload_mult", 1.0) * 0.7
			weapon_mods[main_weapon.id] = mods
		"magplus":
			main_weapon.mag_size += 4
			main_weapon.mag_ammo = mini(main_weapon.mag_ammo + 4, main_weapon.mag_size)
		"dodge":
			var mods_d: Dictionary = weapon_mods.get("_player", {})
			mods_d["dodge_chance"] = mods_d.get("dodge_chance", 0.0) + 0.1
			weapon_mods["_player"] = mods_d
		"vamp":
			var mods_v: Dictionary = weapon_mods.get("_player", {})
			mods_v["vamp_chance"] = mods_v.get("vamp_chance", 0.0) + 0.2
			weapon_mods["_player"] = mods_v
		"elite_dmg":
			var mods_e: Dictionary = weapon_mods.get("_player", {})
			mods_e["elite_dmg_bonus"] = mods_e.get("elite_dmg_bonus", 1.0) + 0.3
			weapon_mods["_player"] = mods_e
		"corruption_resist":
			var mods_cr: Dictionary = weapon_mods.get("_player", {})
			mods_cr["corruption_resist"] = mods_cr.get("corruption_resist", 0.0) + 0.25
			weapon_mods["_player"] = mods_cr
		# Other modifiers (adrenaline, void_hunger, stalker, momentum, scavenger,
		# last_stand, pack_hunter, biome_bond, precision, void_drain) are
		# checked inline where they apply — no setup needed here.

# =========================================================
# MUTATION APPLICATION
# =========================================================
func _apply_mutation(wid: String, mtype: String) -> void:
	var mods: Dictionary = weapon_mods.get(wid, {})
	match wid:
		"sidearm":
			if mtype == "clean":
				mods["fire_rate_add"] = mods.get("fire_rate_add", 0.0) + 0.175
				mods["damage_bonus"] = mods.get("damage_bonus", 0) + WEAPON_DEFS["sidearm"].damage * 2
				mods["range_mult"] = 1.5
				mods["instant_after_reload"] = true
			elif mtype == "void":
				mods["fragment_on_hit"] = true
		"scatter":
			if mtype == "clean":
				mods["tight_cone"] = true
				mods["piercing"] = true
				mods["pierce_count"] = 2
			elif mtype == "void":
				mods["chaos_spray"] = true
				mods["self_chip"] = true
		"lance":
			if mtype == "clean":
				mods["fire_rate_add"] = mods.get("fire_rate_add", 0.0) - 0.6
				mods["slow_field_on_land"] = true
			elif mtype == "void":
				mods["singularity_on_hit"] = true
		"baton":
			if mtype == "clean":
				mods["arc_fields"] = true
			elif mtype == "void":
				mods["consuming_vortex"] = true
		"dart":
			if mtype == "clean":
				mods["smart_missile"] = true
			elif mtype == "void":
				mods["parasite"] = true
		"pulse_cannon":
			if mtype == "clean":
				mods["repulsor_field"] = true
			elif mtype == "void":
				mods["collapse_shot"] = true
		"chain_rifle":
			if mtype == "clean":
				mods["arc_damage_ramp"] = true
				mods["chain_bounces_bonus"] = mods.get("chain_bounces_bonus", 0) + 3  # max 5 bounces
			elif mtype == "void":
				mods["plague"] = true
	weapon_mods[wid] = mods

func _apply_mastery_perk(perk_id: String) -> void:
	var wid: String = main_weapon.get("id", "")
	var mods: Dictionary = weapon_mods.get(wid, {})
	match perk_id:
		# Sidearm clean
		"killcam": mods["killcam"] = true
		"headhunter":
			var pm: Dictionary = weapon_mods.get("_player", {})
			pm["elite_dmg_bonus"] = pm.get("elite_dmg_bonus", 1.0) + 0.5
			weapon_mods["_player"] = pm
		"suppressor": mods["suppressor"] = true
		"armor_pierce": mods["armor_pierce"] = true
		"marksman_reload": mods["reload_mult"] = mods.get("reload_mult", 1.0) * 0.5
		# Sidearm void
		"fragment_magnet": mods["fragment_homing"] = true
		"cascade": mods["fragment_cascade"] = true
		"entropy_field": mods["entropy_field"] = true
		"overheat": mods["overheat_counter"] = 0
		# Scatter clean
		"tight_spread":
			mods["extra_pellets"] = mods.get("extra_pellets", 0) + 1
		"stagger": mods["stagger_chance"] = 0.15
		"glass_cannon":
			mods["damage_bonus"] = mods.get("damage_bonus", 0) + 3
			player_max_hp -= 2
			player_hp = mini(player_hp, player_max_hp)
		"penetrator": mods["pierce_count"] = mods.get("pierce_count", 2) + 1
		# Scatter void
		"feedback": mods["feedback_heal"] = true
		"swarm_chaos": mods["wall_bounce"] = true
		"contagion": mods["contagion"] = true
		"frenzy": mods["frenzy"] = true
		# Lance clean
		"slow_field_persist": mods["slow_field_duration"] = 5.0
		"chain_null": mods["pierce_count"] = mods.get("pierce_count", 1) + 1
		"aimed_shot": mods["aimed_shot"] = true
		"field_expand": mods["radius_bonus"] = mods.get("radius_bonus", 0.0) + 40.0
		# Lance void
		"nested_vortex": mods["vortex_speed"] = 1.5
		"vortex_damage":
			var pm2: Dictionary = weapon_mods.get("_player", {})
			pm2["vortex_dmg_bonus"] = pm2.get("vortex_dmg_bonus", 0.0) + 0.5
			weapon_mods["_player"] = pm2
		"chain_vortex": mods["chain_vortex"] = true
		"void_attractor": mods["vortex_duration_bonus"] = 1.0
		# Baton clean
		"field_chain": mods["field_chain"] = true
		"field_persist": mods["slow_field_duration"] = 5.0
		"wide_arc": mods["radius_bonus"] = mods.get("radius_bonus", 0.0) + 40.0
		"static_charge": mods["static_charge"] = true
		# Baton void
		"vortex_speed": mods["vortex_speed"] = 1.5
		"deep_drain": mods["leech_bonus"] = true
		"overload_void": mods["overload_void"] = true
		"hunger_field": mods["hunger_field"] = true
		# Dart clean
		"missile_burst": mods["missile_burst"] = true
		"tracking_plus": mods["tracking_mult"] = mods.get("tracking_mult", 1.0) * 1.5
		"payload": mods["explode_on_hit"] = true
		"multi_lock": mods["multi_lock_counter"] = 0
		# Dart void
		"rapid_spread": mods["parasite_spread_count"] = 2
		"toxic_cloud": mods["toxic_cloud"] = true
		"deep_parasite": mods["parasite_duration"] = 6.0
		"void_latch": mods["void_latch"] = true
		# Pulse cannon clean
		"wall_persist": mods["wall_persist"] = true
		"wall_damage": mods["wall_damage"] = true
		"bounce_back": mods["bounce_back"] = true
		"double_wall": mods["double_wall"] = true
		# Pulse cannon void
		"deep_collapse": mods["collapse_range_bonus"] = mods.get("collapse_range_bonus", 0.0) + 80.0
		"burst_chain": mods["burst_chain"] = true
		"void_vortex": mods["void_vortex"] = true
		"collapse_amp": mods["collapse_amp"] = true
		# Chain rifle clean
		"arc_persist": mods["chain_bounces_bonus"] = mods.get("chain_bounces_bonus", 0) + 2
		"arc_stun": mods["arc_stun"] = true
		"conductor": mods["conductor"] = true
		"chain_reload": mods["chain_reload"] = true
		# Chain rifle void
		"plague_persist": mods["plague_duration"] = 6.0
		"plague_spread": mods["plague_spread"] = true
		"plague_burst": mods["plague_burst"] = true
		"void_charge": mods["void_charge"] = true
	weapon_mods[wid] = mods
	_show_message("Mastery: " + perk_id.replace("_", " ").capitalize())
