extends Control

# === World ===
const WORLD_W := 4800
const WORLD_H := 4800
const GRID_STEP := 300

# === Weapon definitions ===
const WEAPON_DEFS: Dictionary = {
	# Sidearm: safe, balanced, no gimmick — pure reliability
	"sidearm": {name="Pistol", desc="Reliable semi-auto. Aim carefully — has spread.", fire_rate=0.45, damage=2, bullet_speed=420.0, bullet_radius=4.0, color=Color(1.0,0.9,0.2), range=220.0, pattern="single"},
	# Scatter: high spread, low range — must get close, big payoff in packs
	"scatter": {name="Scatter", desc="3-pellet burst. Weak at range, deadly close.", fire_rate=0.8, damage=1, bullet_speed=360.0, bullet_radius=4.0, color=Color(1.0,0.5,0.1), range=180.0, pattern="scatter"},
	# Lance: slow, high damage, pierces — punishes lined-up enemies
	"lance": {name="Lance", desc="Slow pierce. Hits everything in line.", fire_rate=1.6, damage=5, bullet_speed=260.0, bullet_radius=7.0, color=Color(0.5,0.1,1.0), range=500.0, pattern="piercing"},
	# Baton: melee only — risky, high reward, needs corruption/perk investment
	"baton": {name="Baton", desc="Melee AOE. High risk, scales with corruption.", fire_rate=1.0, damage=3, bullet_speed=0.0, bullet_radius=90.0, color=Color(0.1,0.8,1.0), range=90.0, pattern="melee_aoe"},
	# Dart: homing, auto-aim — lowest damage but never misses
	"dart": {name="Dart", desc="Homing. Tracks enemies. Low damage.", fire_rate=1.1, damage=2, bullet_speed=180.0, bullet_radius=5.0, color=Color(0.2,1.0,0.5), range=400.0, pattern="homing"},
	# Flamethrower: continuous fire cone, short range, high DPS
	"flamethrower": {name="Flamer", desc="Continuous fire cone. Short range, high DPS.", fire_rate=0.12, damage=1, bullet_speed=180.0, bullet_radius=5.0, color=Color(1.0,0.4,0.0), range=140.0, pattern="cone_stream"},
	# Grenade Launcher: lobbed explosive, big AOE, slow reload
	"grenade_launcher": {name="Grenade", desc="Lobbed explosive. Big AOE, slow reload.", fire_rate=2.5, damage=8, bullet_speed=220.0, bullet_radius=8.0, color=Color(0.4,0.9,0.2), range=300.0, pattern="arc_aoe"},
	# Entropy Cannon: corruption-scaling damage
	"entropy_cannon": {name="Entropy", desc="Corruption-scaling damage. Trash at CLEAN, terrifying at VOID.", fire_rate=2.0, damage=3, bullet_speed=300.0, bullet_radius=8.0, color=Color(0.6,0.0,1.0), range=380.0, pattern="single"},
	# Pulse Cannon: bouncing projectile
	"pulse_cannon": {name="Pulse", desc="Bouncing projectile. Each hit bounces to nearest enemy within 150px, max 4 bounces.", fire_rate=1.0, damage=3, bullet_speed=320.0, bullet_radius=6.0, color=Color(0.0,0.8,1.0), range=350.0, pattern="bounce"},
	# Sniper Carbine: high damage, slow fire, headshot bonus
	"sniper_carbine": {name="Sniper", desc="High damage, slow fire. Headshots on elites deal 3x.", fire_rate=2.5, damage=8, bullet_speed=600.0, bullet_radius=5.0, color=Color(1.0,0.85,0.0), range=600.0, pattern="single"},
	# Chain Rifle: rapid-fire suppression with slow
	"chain_rifle": {name="Chain", desc="Rapid-fire suppression. Low per-bullet damage, very high rate. Slows enemies.", fire_rate=0.1, damage=1, bullet_speed=450.0, bullet_radius=3.0, color=Color(0.9,0.9,0.9), range=280.0, pattern="single"},
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
	"flamethrower": {
		2: {icon="F", name="Fuel Tank", desc="Range +30px", effect="range_bonus", value=30.0},
		3: {icon="N", name="Napalm", desc="Burning: +1 dmg/s for 3s on hit", effect="burning", value=true},
		4: {icon="P", name="Pressurized", desc="Fire rate +30%", effect="fire_rate", value=-0.036},
		5: {icon="T", name="Fork", desc="Clean: Cryo Flamer (freeze, no dmg, 2s stun) | Void: Corruption Spray (+5 corr/s, 3x dmg)", effect="flamer_fork", value=true},
	},
	"grenade_launcher": {
		2: {icon="H", name="Heavy Ordinance", desc="+3 AOE damage", effect="damage", value=3},
		3: {icon="C", name="Cluster Bomb", desc="Explosion spawns 3 mini grenades", effect="cluster", value=true},
		4: {icon="S", name="Stagger", desc="Explosion knocks enemies back 80px", effect="grenade_knockback", value=true},
		5: {icon="A", name="Fork", desc="Clean: Airburst (explodes at max range, hits all) | Void: Void Grenade (corruption zone 5s)", effect="grenade_fork", value=true},
	},
	"entropy_cannon": {
		2: {icon="D", name="Overcharge", desc="+1 base damage", effect="damage", value=1},
		3: {icon="R", name="Rapid Decay", desc="Rate of fire +20%", effect="fire_rate", value=-0.4},
		4: {icon="P", name="Penetrating", desc="Penetrating rounds (pierce 1)", effect="piercing", value=true},
		5: {icon="F", name="Fork", desc="Clean: Stabilized (damage ignores corruption, stays at 3x) | Void: Resonance (corruption gain +50%, triple scaling)", effect="entropy_fork", value=true},
	},
	"pulse_cannon": {
		2: {icon="B", name="Extra Bounce", desc="+1 bounce (5 total)", effect="bounce_extra", value=1},
		3: {icon="D", name="Impact", desc="+1 damage", effect="damage", value=1},
		4: {icon="R", name="Wide Bounce", desc="Bounce radius +60px", effect="bounce_radius", value=60.0},
		5: {icon="F", name="Fork", desc="Clean: Overclock (fire rate +50%, 3 bounces) | Void: Void Chain (each bounce adds +2 corruption to enemy)", effect="pulse_fork", value=true},
	},
	"sniper_carbine": {
		2: {icon="D", name="High Caliber", desc="+3 damage", effect="damage", value=3},
		3: {icon="R", name="Long Barrel", desc="Range +100px, speed +100", effect="sniper_range", value=true},
		4: {icon="P", name="AP Rounds", desc="Penetrates 2 enemies", effect="piercing", value=true},
		5: {icon="F", name="Fork", desc="Clean: Killshot (one-shots under 20% HP) | Void: Void Slug (leaves corruption trail)", effect="sniper_fork", value=true},
	},
	"chain_rifle": {
		2: {icon="D", name="Hardened Rounds", desc="+1 damage", effect="damage", value=1},
		3: {icon="S", name="Suppression", desc="Slow +20%, stacks higher", effect="chain_slow_boost", value=true},
		4: {icon="C", name="Auto-Crit", desc="Every 10th bullet auto-crits (3x)", effect="chain_autocrit", value=true},
		5: {icon="F", name="Fork", desc="Clean: Precision Mode (rate halved, 4x dmg, no slow) | Void: Suppressor (slowed +30% from all, +50% corruption)", effect="chain_fork", value=true},
	},
}

# Run modifiers — drawn randomly, no repeats per run
const RUN_MODIFIERS: Array = [
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
var modifiers_taken: Array = []
var mastery_taken: Array = []
var resonance_taken: Array = []

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
	"flamethrower": {
		"clean": {icon="C", name="Cryo Flamer",      desc="Freezes enemies. No damage, 2s stun per hit."},
		"void":  {icon="V", name="Corruption Spray",  desc="+5 corruption/s to player while firing, triple damage."},
	},
	"grenade_launcher": {
		"clean": {icon="A", name="Airburst",        desc="Explodes at max range regardless. Hits everything in 80px."},
		"void":  {icon="V", name="Void Grenade",     desc="Explosion leaves a corruption zone for 5s."},
	},
	"entropy_cannon": {
		"clean": {icon="S", name="Stabilized",      desc="Damage ignores corruption state, stays at 3x multiplier."},
		"void":  {icon="R", name="Resonance",        desc="Corruption gain from kills +50%, triple scaling."},
	},
	"pulse_cannon": {
		"clean": {icon="O", name="Overclock",       desc="Fire rate +50%, limited to 3 bounces."},
		"void":  {icon="V", name="Void Chain",       desc="Each bounce adds +2 corruption to enemy, no self damage."},
	},
	"sniper_carbine": {
		"clean": {icon="K", name="Killshot",         desc="One-shots enemies under 20% HP."},
		"void":  {icon="V", name="Void Slug",        desc="Leaves corruption trail along bullet path."},
	},
	"chain_rifle": {
		"clean": {icon="P", name="Precision Mode",   desc="Fire rate halved, each bullet does 4x damage, no slow."},
		"void":  {icon="S", name="Suppressor",        desc="Slowed enemies take +30% from all sources, +50% corruption on hit."},
	},
}

# Kit definitions
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
	"flamethrower": {
		"clean": [
			{id="cryo_range", icon="R", name="Cryo Range", desc="Freeze cone range +40px."},
			{id="deep_freeze", icon="D", name="Deep Freeze", desc="Stun duration 3s (was 2s)."},
			{id="shatter", icon="S", name="Shatter", desc="Frozen enemies take +50% damage from other sources."},
			{id="cryo_aura", icon="A", name="Cryo Aura", desc="Enemies near frozen targets are slowed 30%."},
		],
		"void": [
			{id="corr_efficiency", icon="E", name="Corruption Efficiency", desc="Corruption cost reduced to +3/s."},
			{id="void_flames", icon="V", name="Void Flames", desc="Flame projectiles pierce 1 enemy."},
			{id="corruption_burst", icon="B", name="Corruption Burst", desc="At 80 corruption: next flame burst deals 5x."},
			{id="siphon", icon="S", name="Siphon", desc="Kill with flames restores 1 HP."},
		],
	},
	"grenade_launcher": {
		"clean": [
			{id="wide_burst", icon="W", name="Wide Burst", desc="Airburst radius +30px."},
			{id="carpet_bomb", icon="C", name="Carpet Bomb", desc="Fire 2 grenades side-by-side."},
			{id="concussion", icon="X", name="Concussion", desc="Airburst stuns 1s."},
			{id="barrage", icon="B", name="Barrage", desc="Fire rate +25%."},
		],
		"void": [
			{id="corr_zone_expand", icon="E", name="Zone Expand", desc="Corruption zone radius +40px."},
			{id="zone_damage", icon="D", name="Zone Damage", desc="Corruption zone deals 2 dmg/s."},
			{id="void_pull", icon="P", name="Void Pull", desc="Corruption zone pulls enemies inward."},
			{id="cascade_void", icon="V", name="Cascade", desc="Enemies killed in zone spawn mini zone."},
		],
	},
	"entropy_cannon": {
		"clean": [
			{id="stable_focus", icon="F", name="Stable Focus", desc="Fire rate +15%."},
			{id="stable_pierce", icon="P", name="Stable Pierce", desc="Pierce 2 enemies."},
			{id="stable_range", icon="R", name="Stable Range", desc="Range +60px."},
			{id="stable_crit", icon="C", name="Stable Crit", desc="Every 5th shot crits (2x)."},
		],
		"void": [
			{id="res_scaling", icon="S", name="Deep Resonance", desc="Corruption scaling x4 instead of x3."},
			{id="res_aura", icon="A", name="Corruption Aura", desc="Kills spread +5 corruption to nearby enemies."},
			{id="res_leech", icon="L", name="Void Leech", desc="Kills at 60+ corruption heal 1 HP."},
			{id="res_burst", icon="B", name="Entropy Burst", desc="At 80+ corruption, shots explode 40px AOE."},
		],
	},
	"pulse_cannon": {
		"clean": [
			{id="oc_speed", icon="S", name="Quick Pulse", desc="Bullet speed +25%."},
			{id="oc_damage", icon="D", name="Heavy Pulse", desc="+2 damage per bounce."},
			{id="oc_range", icon="R", name="Extended Reach", desc="Range +80px."},
			{id="oc_chain", icon="C", name="Chain Reaction", desc="Final bounce explodes 40px AOE."},
		],
		"void": [
			{id="vc_corrupt", icon="C", name="Deep Chain", desc="Bounce corruption +3 (5 total)."},
			{id="vc_slow", icon="S", name="Chain Slow", desc="Each bounce slows enemy 20% for 1s."},
			{id="vc_extra", icon="E", name="Extra Bounce", desc="+2 bounces."},
			{id="vc_drain", icon="D", name="Void Drain", desc="Each bounce heals 0.5 HP."},
		],
	},
	"sniper_carbine": {
		"clean": [
			{id="ks_execute", icon="E", name="Execute", desc="Killshot threshold raised to 30% HP."},
			{id="ks_reload", icon="R", name="Quick Scope", desc="Reload time -40%."},
			{id="ks_crit", icon="C", name="Vital Shot", desc="Headshot zone +15px radius."},
			{id="ks_chain", icon="X", name="Chain Kill", desc="Killshot resets fire cooldown."},
		],
		"void": [
			{id="vs_trail", icon="T", name="Lingering Trail", desc="Corruption trail lasts 4s."},
			{id="vs_damage", icon="D", name="Void Penetration", desc="+4 damage to corrupted enemies."},
			{id="vs_slow", icon="S", name="Entropic Slug", desc="Trail slows enemies 30%."},
			{id="vs_burst", icon="B", name="Void Impact", desc="Headshots on elites create 60px corruption burst."},
		],
	},
	"chain_rifle": {
		"clean": [
			{id="pm_damage", icon="D", name="Heavy Rounds", desc="+2 damage in precision mode."},
			{id="pm_pierce", icon="P", name="AP Rounds", desc="Precision shots pierce 1 enemy."},
			{id="pm_range", icon="R", name="Extended Barrel", desc="Range +60px."},
			{id="pm_crit", icon="C", name="Focused Fire", desc="Every 5th shot crits (2x)."},
		],
		"void": [
			{id="sp_slow", icon="S", name="Deep Suppression", desc="Slow cap raised to 70%."},
			{id="sp_damage", icon="D", name="Void Rounds", desc="+1 damage to slowed enemies."},
			{id="sp_corrupt", icon="C", name="Corruption Feed", desc="Slowed enemies gain +3 corruption/s."},
			{id="sp_burst", icon="B", name="Suppression Wave", desc="Every 20th bullet: AOE slow 100px."},
		],
	},
}

# Resonance perks (cross-kit combos, post-T3)
const RESONANCE_POOL: Array = [
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
var bullets: Array = []

# === Obstacles ===
# {pos: Vector2, radius: float}
var obstacles: Array = []

# === Enemies ===
var enemies: Array = []
var pending_enemy_spawns: Array = []
var enemy_melee_cooldowns: Dictionary = {} # enemy index -> float

# === Pickups ===
# {pos, type, color, ingredient_data} for ingredients
# {pos, type} for essence
var pickups: Array = []

# === Ingredient pickups (Phase 3 — pristine quality) ===
var ingredient_pickups: Array = []

# === AOE flashes ===
var aoe_flashes: Array = []

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
var purge_timer := 0.0    # timer for dead enemy cleanup
var rage_sweep_timer: float = 30.0  # force-aggro idle enemies periodically
const WAVE_INTERVAL_START := 20.0
const WAVE_INTERVAL_MIN   := 8.0

# === Elite system ===
var elite_timer := 0.0
var elite_interval := 0.0   # set on ready: 180-300s
var elite_spawned_count := 0
# Apex elite system
var apex_timer := 600.0  # first apex at 10 min
var apex_active := false
var apex_spawned_count := 0
var affix_spawn_label_timer := 0.0
var affix_spawn_label_text: String = ""
const ELITE_TYPES: Array = ["Void Hulk", "Phase Hunter", "Brood Mother", "Rift Colossus", "Null Wraith", "Stone Sentinel", "Tide Reaper", "Current Stalker"]
const APEX_TYPES: Array = ["Rift Sovereign", "The Hollow", "Ancient Brood", "Abyssal Tide"]

# === Ingredients collected ===
var run_ingredients: Array = []

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
var equipped_kits: Array = []
var kit_states: Dictionary = {}
var kit_tiers: Dictionary = {}
var kit_button_rects: Array = []

var traps: Array = []
var decoys: Array = []
var turrets: Array = []
var smoke_zones: Array = []
var smoke_interact_timer: float = 0.0
var draw_timer: float = 0.0
var gravity_wells: Array = []
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
var walls: Array = []
var overcharge_timer: float = 0.0
var drone_barrier_timer: float = 0.0
var pack_allies: Array = []
var baton_hit_count: int = 0
var baton_hit_timer: float = 0.0
var chain_rifle_shot_count: int = 0

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
var rivers: Array = []
var bridges: Array = []
var caves: Array = []
var void_pools: Array = []
var player_in_cave: int = -1

# === Upgrade panel ===
var upgrade_choices: Array = []
var upgrade_buttons: Array = [] # Node references

# Contract mode state
var contract_mode: String = "hunt"
# Payload Escort
var pod_pos: Vector2 = Vector2.ZERO
var pod_target: Vector2 = Vector2.ZERO
var pod_hp: int = 200
var pod_max_hp: int = 200
var pod_speed: float = 40.0
var pod_active: bool = false
# Void Breach
var rift_pos: Vector2 = Vector2.ZERO
var rift_hold_time: float = 180.0
var rift_time_held: float = 0.0
var rift_time_outside: float = 0.0
var rift_active: bool = false
var rift_radius: float = 400.0
# Boss Hunt
var boss_name: String = ""
var boss_spawned: bool = false
var boss_killed: bool = false
var boss_timer: float = 480.0
# Extraction Run
var extraction_caches: Array = []
var caches_collected: int = 0
var cache_total: int = 3
var cache_channel_time: float = 2.0

# === DEBUG OVERLAY ===
const DEBUG_OVERLAY_ENABLED: bool = true   # master switch — set false for release builds
var debug_overlay_visible: bool = false
var debug_log: Array = []                  # rolling event log
const DEBUG_LOG_MAX: int = 10
var debug_btn_rect: Rect2 = Rect2(0, 0, 44, 24)  # updated each draw
var abandon_btn_rect: Rect2 = Rect2(0, 0, 60, 28)  # updated each draw
var debug_snap_timer: float = 0.0
const DEBUG_SNAP_INTERVAL: float = 2.0
var crash_log: String = ""    # loaded from localStorage on ready
var crash_snap: String = ""   # loaded from localStorage on ready

# === Creature data ===
const CREATURE_DEFS: Dictionary = {
	# charge: runs straight at player — dumb, fast, cannon fodder
	"Void Leech": {radius = 12, color = Color(0.8, 0.2, 0.2), speed = 100, hp = 5, detection = 280, melee_dmg = 1, ranged = false, void_type = false, behavior = "charge"},
	# flank: tries to circle and approach from the side
	"Shadow Crawler": {radius = 13, color = Color(0.5, 0.1, 0.7), speed = 110, hp = 5, detection = 300, melee_dmg = 1, ranged = false, void_type = false, behavior = "flank"},
	# burst: slow patrol, then sudden 2.5x speed lunge, pauses after
	"Abyss Worm": {radius = 14, color = Color(0.3, 0.6, 0.1), speed = 65, hp = 9, detection = 320, melee_dmg = 2, ranged = false, void_type = false, behavior = "burst"},
	# strafe: ranged, sidesteps perpendicular to player while shooting
	"Nether Stalker": {radius = 12, color = Color(0.2, 0.4, 0.9), speed = 70, hp = 6, detection = 360, melee_dmg = 0, ranged = true, ranged_dmg = 2, ranged_cooldown = 1.4, void_type = false, behavior = "strafe"},
	# pack: faster when allies are nearby, swarming behavior
	"Rift Parasite": {radius = 11, color = Color(0.9, 0.5, 0.1), speed = 100, hp = 6, detection = 300, melee_dmg = 1, ranged = false, void_type = true, behavior = "pack"},
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
	contract_mode = contract.get("type", "hunt")
	var depth: int = contract.get("depth", 1)
	if contract_mode == "hunt" or contract_mode == "":
		target_total = 3 + depth
	else:
		target_total = 9999

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
	var is_melee_type: bool = wid == "baton"
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
	_init_contract_mode(contract)

	# Load crash data from previous session (WASM only)
	if DEBUG_OVERLAY_ENABLED and OS.get_name() == "Web":
		var prev_log = JavaScriptBridge.eval("localStorage.getItem('sh_debug_log')")
		var prev_snap = JavaScriptBridge.eval("localStorage.getItem('sh_debug_snap')")
		if typeof(prev_log) == TYPE_STRING and prev_log != "":
			crash_log = prev_log
		if typeof(prev_snap) == TYPE_STRING and prev_snap != "":
			crash_snap = prev_snap
		# Clear so we don't show stale data next time
		JavaScriptBridge.eval("localStorage.removeItem('sh_debug_log'); localStorage.removeItem('sh_debug_snap');")

func _init_contract_mode(contract: Dictionary) -> void:
	match contract_mode:
		"payload_escort":
			pod_pos = player_pos + Vector2(100, 0)
			pod_target = Vector2(randf_range(300, WORLD_W - 300), randf_range(300, WORLD_H - 300))
			# Make sure target is far from start
			while pod_target.distance_to(pod_pos) < 2000.0:
				pod_target = Vector2(randf_range(300, WORLD_W - 300), randf_range(300, WORLD_H - 300))
			pod_hp = 200
			pod_max_hp = 200
			pod_active = true
			_show_message("Escort the pod to the target zone!")
		"void_breach":
			# Pick rift position 400-700px from player — visible on screen or just off
			var rng_vb := RandomNumberGenerator.new()
			rng_vb.randomize()
			var vb_angle: float = rng_vb.randf() * TAU
			var vb_dist: float = rng_vb.randf_range(400.0, 700.0)
			rift_pos = player_pos + Vector2(cos(vb_angle), sin(vb_angle)) * vb_dist
			rift_pos.x = clampf(rift_pos.x, 200.0, WORLD_W - 200.0)
			rift_pos.y = clampf(rift_pos.y, 200.0, WORLD_H - 200.0)
			rift_hold_time = contract.get("hold_time", 180.0)
			rift_active = true
			_show_message("Get to the rift and hold position!")
		"boss_hunt":
			boss_name = contract.get("boss_name", "Void Overlord")
			boss_timer = 480.0
			boss_spawned = false
			boss_killed = false
			_show_message("Hunt the " + boss_name + "!")
		"extraction_run":
			_spawn_caches()
			_show_message("Find and collect 3 caches!")

func _spawn_caches() -> void:
	extraction_caches.clear()
	var rng2 = RandomNumberGenerator.new()
	rng2.randomize()
	var placed: int = 0
	# Try to place near void pools first
	for pool in void_pools:
		if placed >= cache_total:
			break
		var cpos: Vector2 = Vector2(pool.pos.x + rng2.randf_range(-80, 80), pool.pos.y + rng2.randf_range(-80, 80))
		cpos.x = clampf(cpos.x, 100, WORLD_W - 100)
		cpos.y = clampf(cpos.y, 100, WORLD_H - 100)
		extraction_caches.append({pos=cpos, biome="void_pool", collected=false, channel_timer=0.0, channeling=false})
		placed += 1
	# Then near caves
	for cave in caves:
		if placed >= cache_total:
			break
		var cpos2: Vector2 = Vector2(cave.pos.x + rng2.randf_range(-60, 60), cave.pos.y + rng2.randf_range(-60, 60))
		cpos2.x = clampf(cpos2.x, 100, WORLD_W - 100)
		cpos2.y = clampf(cpos2.y, 100, WORLD_H - 100)
		extraction_caches.append({pos=cpos2, biome="cave", collected=false, channel_timer=0.0, channeling=false})
		placed += 1
	# Then near rivers
	for river in rivers:
		if placed >= cache_total:
			break
		if river.segments.size() > 0:
			var seg: Dictionary = river.segments[rng2.randi_range(0, river.segments.size() - 1)]
			var cpos3: Vector2 = Vector2(seg.pos.x + rng2.randf_range(-60, 60), seg.pos.y + rng2.randf_range(-60, 60))
			cpos3.x = clampf(cpos3.x, 100, WORLD_W - 100)
			cpos3.y = clampf(cpos3.y, 100, WORLD_H - 100)
			extraction_caches.append({pos=cpos3, biome="river_bank", collected=false, channel_timer=0.0, channeling=false})
			placed += 1
	# Fill remaining with random positions
	while placed < cache_total:
		var rpos: Vector2 = Vector2(rng2.randf_range(200, WORLD_W - 200), rng2.randf_range(200, WORLD_H - 200))
		extraction_caches.append({pos=rpos, biome="random", collected=false, channel_timer=0.0, channeling=false})
		placed += 1

func _update_contract_mode(delta: float) -> void:
	match contract_mode:
		"payload_escort":
			_update_payload_escort(delta)
		"void_breach":
			_update_void_breach(delta)
		"boss_hunt":
			_update_boss_hunt(delta)
		"extraction_run":
			_update_extraction_run(delta)

func _update_payload_escort(delta: float) -> void:
	if not pod_active:
		return
	# Pod moves toward target when player is within 400px
	var player_dist: float = player_pos.distance_to(pod_pos)
	if player_dist < 400.0:
		var dir: Vector2 = (pod_target - pod_pos).normalized()
		pod_pos += dir * pod_speed * delta
	# Check if pod reached target
	if pod_pos.distance_to(pod_target) < 50.0:
		_show_message("Pod delivered! Hunt complete!")
		_complete_hunt()
		return
	# Enemies damage pod
	for e in enemies:
		if e.hp <= 0:
			continue
		if e.pos.distance_to(pod_pos) < 30.0:
			pod_hp -= int(1.0 * delta + 0.5)
	if pod_hp <= 0:
		_show_message("Pod destroyed!")
		_finish_hunt(0)

func _update_void_breach(delta: float) -> void:
	if not rift_active:
		return
	var player_dist: float = player_pos.distance_to(rift_pos)
	if player_dist < rift_radius:
		rift_time_held += delta
		# Extra corruption while in rift zone
		corruption += 3.0 * delta
		rift_time_outside = 0.0
	else:
		# Only accumulate outside time after player has reached rift at least once
		if rift_time_held > 0.0:
			rift_time_outside += delta
		if rift_time_outside >= 10.0:
			_show_message("Left rift too long! Failed!")
			_finish_hunt(0)
			return
	if rift_time_held >= rift_hold_time:
		_show_message("Rift sealed! Hunt complete!")
		_complete_hunt()

func _update_boss_hunt(delta: float) -> void:
	boss_timer -= delta
	if not boss_spawned:
		boss_spawned = true
		# Spawn the boss using existing elite spawn, but override the type
		var depth: int = GameData.current_contract.get("depth", 1)
		_spawn_elite(depth)
		# Mark the last spawned enemy as the boss
		if enemies.size() > 0:
			var boss_enemy: Dictionary = enemies[enemies.size() - 1]
			boss_enemy.type = boss_name
			boss_enemy.elite_type = boss_name
			boss_enemy.hp = int(boss_enemy.hp * 2.5)
			boss_enemy.max_hp = boss_enemy.hp
			enemies[enemies.size() - 1] = boss_enemy
		_show_message("TARGET: " + boss_name + " has appeared!")
	# Check if boss is dead
	var boss_alive: bool = false
	for e in enemies:
		if e.get("elite_type", "") == boss_name and e.hp > 0:
			boss_alive = true
			break
	if boss_spawned and not boss_alive:
		boss_killed = true
		_show_message(boss_name + " eliminated!")
		_complete_hunt()
		return
	if boss_timer <= 0.0:
		_show_message("Time's up! " + boss_name + " escaped!")
		_finish_hunt(0)

func _update_extraction_run(delta: float) -> void:
	for ci in range(extraction_caches.size()):
		var cache: Dictionary = extraction_caches[ci]
		if cache.collected:
			continue
		var dist: float = player_pos.distance_to(cache.pos)
		if dist < 40.0:
			cache.channeling = true
			cache.channel_timer += delta
			if cache.channel_timer >= cache_channel_time:
				cache.collected = true
				cache.channeling = false
				caches_collected += 1
				_show_message("Cache collected! %d/%d" % [caches_collected, cache_total])
		else:
			if cache.channeling:
				cache.channel_timer = 0.0
				cache.channeling = false
		extraction_caches[ci] = cache
	if caches_collected >= cache_total:
		_show_message("All caches collected! Hunt complete!")
		_complete_hunt()

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
	var r1_waypoints: Array = [r1_start]
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
	var r2_waypoints: Array = [r2_start]
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
		var segs: Array = []
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

	# Rage sweep: force-aggro idle enemies, frequency scales with time + corruption
	rage_sweep_timer -= delta
	var rage_interval: float = maxf(8.0, 30.0 - (hunt_elapsed / 30.0) - (corruption / 10.0))
	if rage_sweep_timer <= 0.0:
		rage_sweep_timer = rage_interval
		var aggro_range: float = 600.0 + minf(hunt_elapsed / 10.0, 800.0) + corruption * 4.0
		for i in range(enemies.size()):
			var e: Dictionary = enemies[i]
			if e.hp > 0 and not e.get("is_ally", false) and not e.is_aggroed:
				if e.pos.distance_to(player_pos) < aggro_range:
					e.is_aggroed = true
					e.aggro_origin = e.pos
					enemies[i] = e

	# Elite timer — spawn one elite at interval, then reset
	elite_timer -= delta
	if elite_timer <= 0.0:
		elite_timer = randf_range(45.0, 70.0)  # subsequent elites every 45-70s
		var depth: int = GameData.current_contract.get("depth", 1)
		_spawn_elite(depth)

	# Apex elite timer
	if not apex_active:
		apex_timer -= delta
		if apex_timer <= 0.0:
			var depth: int = GameData.current_contract.get("depth", 1)
			_spawn_apex_elite(depth)

	# Affix label timer
	if affix_spawn_label_timer > 0.0:
		affix_spawn_label_timer -= delta

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

	# Filler only — no targets in waves. Ramps with wave, time, and corruption.
	var effective_wave: int = min(wave_current, 10)
	var time_bonus: int = int(hunt_elapsed / 60.0)                         # +1 per minute
	var corr_bonus: int = int(corruption / 25.0)                           # +1 per 25% corruption
	var base_fillers: int = 14 + depth * 4
	var filler_count: int = base_fillers + (effective_wave - 1) * 2 + time_bonus + corr_bonus + rng.randi_range(0, 2)
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

	# Speed ramps with wave, time, and corruption
	var time_spd: float = minf(hunt_elapsed / 60.0 * 0.03, 0.20)          # up to +20% over ~7 min
	var corr_spd: float = minf(corruption / 100.0 * 0.15, 0.15)           # up to +15% at full corruption
	var speed_mult: float = 1.0 + min(effective_wave - 1, 7) * 0.08 + time_spd + corr_spd
	for i in range(spawn_start, enemies.size()):
		enemies[i].speed *= speed_mult

	# Pre-aggro 60% — most rush immediately
	var new_count: int = enemies.size() - spawn_start
	var aggro_count: int = int(new_count * 0.6)
	for i in range(spawn_start, spawn_start + aggro_count):
		enemies[i].is_aggroed = true
		enemies[i].aggro_origin = enemies[i].pos

func _find_elite_spawn_pos(rng: RandomNumberGenerator) -> Vector2:
	var pos := Vector2.ZERO
	for _try in range(60):
		pos = Vector2(rng.randf_range(200.0, WORLD_W - 200.0), rng.randf_range(200.0, WORLD_H - 200.0))
		if pos.distance_to(player_pos) < 350.0:
			continue
		var blocked := false
		for obs in obstacles:
			if pos.distance_to(obs.pos) < obs.radius + 30.0:
				blocked = true
				break
		if not blocked:
			break
	return pos

func _make_base_elite(elite_type: String, pos: Vector2, hp_val: int, spd: float, rad: float, col: Color, m_dmg: int) -> Dictionary:
	return {
		type = elite_type,
		pos = pos,
		hp = hp_val,
		max_hp = hp_val,
		speed = spd,
		radius = rad,
		color = col,
		detection = 600.0,
		melee_dmg = m_dmg,
		leash = 9999.0,
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
		burst_timer = 0.0, burst_active = false, burst_cooldown = 2.0,
		flank_side = 1.0, flank_timer = 1.5,
		strafe_dir = 1.0, strafe_timer = 1.0,
		phase_timer = 0.0,
		phase_jumping = false,
		phase_jump_from = Vector2.ZERO,
		phase_jump_to = Vector2.ZERO,
		phase_jump_progress = 0.0,
		brood_triggered = false,
		charge_timer = 0.0,
		shockwave_timer = 6.0,
		sentinel_charging = false,
		sentinel_charge_dist = 0.0,
		sentinel_target = Vector2.ZERO,
		sentinel_pause = 0.0,
		dash_timer = 8.0,
		has_split = false,
		is_apex = false,
		apex_spawn_timer = 15.0,
		void_trail_timer = 3.0,
		affixes = {},
		affix_list = [],
		elite_biome = "",
	}

func _spawn_elite(depth: int) -> void:
	elite_spawned_count += 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var elite_type: String = ELITE_TYPES[(elite_spawned_count - 1) % ELITE_TYPES.size()]
	if rng.randf() < 0.3:
		elite_type = ELITE_TYPES[rng.randi_range(0, ELITE_TYPES.size() - 1)]

	_show_message("ELITE: %s approaching!" % elite_type)

	var pos: Vector2 = _find_elite_spawn_pos(rng)
	var hp_scale: float = 1.0 + (depth - 1) * 0.5 + elite_spawned_count * 0.2
	var base_hp: int = int(20.0 * hp_scale)
	var base_spd: float = 55.0 + depth * 10.0
	var base_rad: float = 20.0
	var base_color: Color = Color(1.0, 0.85, 0.1)
	var base_dmg: int = 2 + depth

	# Override stats for new elite types
	match elite_type:
		"Rift Colossus":
			base_hp = int(250.0 * hp_scale)
			base_spd = 40.0
			base_rad = 35.0
			base_color = Color(0.3, 0.0, 0.5)
		"Null Wraith":
			base_hp = int(90.0 * hp_scale)
			base_spd = 110.0
			base_rad = 12.0
			base_color = Color(0.2, 0.1, 0.3)
		"Stone Sentinel":
			base_hp = int(200.0 * hp_scale)
			base_spd = 0.0  # stationary until triggered
			base_rad = 22.0
			base_color = Color(0.5, 0.5, 0.5)
		"Tide Reaper":
			base_hp = int(120.0 * hp_scale)
			base_spd = 70.0
			base_rad = 16.0
			base_color = Color(0.1, 0.2, 0.6)
		"Current Stalker":
			base_hp = int(80.0 * hp_scale)
			base_spd = 85.0
			base_rad = 14.0
			base_color = Color(0.0, 0.8, 0.7)

	var elite: Dictionary = _make_base_elite(elite_type, pos, base_hp, base_spd, base_rad, base_color, base_dmg)
	elite.elite_biome = _get_biome_at(pos)

	# Roll affixes
	var affix_count: int = 1
	if hunt_elapsed > 600.0:
		affix_count = rng.randi_range(2, 3)
	elif hunt_elapsed > 300.0:
		affix_count = rng.randi_range(1, 2)
	_roll_affixes(elite, affix_count, rng)

	enemies.append(elite)
	debug_log_push("Elite spawned: %s [%s]" % [elite_type, ",".join(elite.get("affixes", []))])

func _spawn_apex_elite(depth: int) -> void:
	apex_spawned_count += 1
	apex_active = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var apex_type: String = APEX_TYPES[(apex_spawned_count - 1) % APEX_TYPES.size()]
	if rng.randf() < 0.3:
		apex_type = APEX_TYPES[rng.randi_range(0, APEX_TYPES.size() - 1)]

	_show_message("!! APEX: %s !!" % apex_type)
	var pos: Vector2 = _find_elite_spawn_pos(rng)
	var hp_scale: float = 1.0 + (depth - 1) * 0.5

	var base_hp: int = 400
	var base_spd: float = 55.0 + depth * 10.0
	var base_rad: float = 28.0
	var base_color: Color = Color(1.0, 0.85, 0.1)
	var base_dmg: int = 3 + depth

	match apex_type:
		"Rift Sovereign":
			base_hp = int(400.0 * hp_scale)
			base_rad = 26.0
		"The Hollow":
			base_hp = int(500.0 * hp_scale)
			base_rad = 30.0
			base_color = Color(0.4, 0.0, 0.6)
		"Ancient Brood":
			base_hp = int(350.0 * hp_scale)
			base_spd = 0.0
			base_rad = 30.0
			base_color = Color(0.6, 0.3, 0.1)
		"Abyssal Tide":
			base_hp = int(300.0 * hp_scale)
			base_spd = 80.0
			base_rad = 24.0
			base_color = Color(0.05, 0.15, 0.5)

	var elite: Dictionary = _make_base_elite(apex_type, pos, base_hp, base_spd, base_rad, base_color, base_dmg)
	elite.is_apex = true
	elite.elite_biome = _get_biome_at(pos)

	# Apex always 2-3 affixes, never multiplier
	var affix_count: int = rng.randi_range(2, 3)
	_roll_affixes(elite, affix_count, rng, true)

	enemies.append(elite)
	debug_log_push("APEX spawned: %s [%s]" % [apex_type, ",".join(elite.get("affixes", []))])

	# Screen flash
	_add_aoe_flash({pos = player_pos, radius = 400.0, timer = 0.5, color = Color(1.0, 0.85, 0.0, 0.3)})

const ALL_AFFIXES: Array = ["extra_fast", "vampiric", "shielded", "teleporter", "venomous", "berserker", "spectral", "multiplier", "magnetic", "voidbound", "armored", "corrupting"]
const BANNED_COMBOS: Array = [["voidbound", "teleporter"], ["multiplier", "spectral"]]

func _roll_affixes(elite: Dictionary, count: int, rng: RandomNumberGenerator, is_apex: bool = false) -> void:
	var available: Array = ALL_AFFIXES.duplicate()
	# voidbound only for void_pool biome
	if elite.get("elite_biome", "") != "void_pool":
		available.erase("voidbound")
	# Apex never gets multiplier
	if is_apex:
		available.erase("multiplier")
	var chosen: Array = []
	for _i in range(count):
		if available.is_empty():
			break
		var idx: int = rng.randi_range(0, available.size() - 1)
		var affix: String = available[idx]
		chosen.append(affix)
		available.erase(affix)
		# Remove banned combos
		for combo in BANNED_COMBOS:
			if chosen.has(combo[0]) and available.has(combo[1]):
				available.erase(combo[1])
			if chosen.has(combo[1]) and available.has(combo[0]):
				available.erase(combo[0])
	# Apply affixes
	for affix in chosen:
		elite.affixes[affix] = true
		match affix:
			"extra_fast":
				elite.speed *= 1.5
			"shielded":
				elite["shield_hp"] = int(float(elite.max_hp) * 0.3)
			"teleporter":
				elite["tp_timer"] = 8.0
			"venomous":
				elite["venom_trail"] = []
			"magnetic":
				elite["magnetic_timer"] = 5.0
	elite.affix_list = chosen
	if not chosen.is_empty():
		affix_spawn_label_text = ", ".join(chosen)
		affix_spawn_label_timer = 2.0

func _spawn_single_enemy(type_name: String, is_target: bool, rng: RandomNumberGenerator) -> void:
	var def: Dictionary = CREATURE_DEFS[type_name]
	var pos := Vector2.ZERO
	for _try in range(30):
		pos = Vector2(rng.randf_range(200.0, WORLD_W - 200.0), rng.randf_range(200.0, WORLD_H - 200.0))
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
			# Debug overlay toggle
			if DEBUG_OVERLAY_ENABLED and debug_btn_rect.has_point(te.position):
				debug_overlay_visible = !debug_overlay_visible
				return
			# Abandon button
			if abandon_btn_rect.has_point(te.position):
				debug_log_push("Hunt abandoned by player")
				_finish_hunt(0)
				return
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

	# Debug overlay toggle (F1) + abandon (Escape)
	if event is InputEventKey:
		var ke: InputEventKey = event
		if ke.pressed:
			if DEBUG_OVERLAY_ENABLED and ke.keycode == KEY_F1:
				debug_overlay_visible = !debug_overlay_visible
				return
			if ke.keycode == KEY_ESCAPE:
				debug_log_push("Hunt abandoned by player")
				_finish_hunt(0)
				return

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
		draw_timer += delta
		if draw_timer >= 0.033:
			draw_timer = 0.0
			queue_redraw()
		return

	if hunt_complete or paused:
		draw_timer += delta
		if draw_timer >= 0.033:
			draw_timer = 0.0
			queue_redraw()
		return

	if speed_boost_timer > 0.0:
		speed_boost_timer -= delta
	if player_hit_flash > 0.0:
		player_hit_flash -= delta

	# Debug watchdog: write state snapshot to localStorage every 2s
	if DEBUG_OVERLAY_ENABLED:
		debug_snap_timer += delta
		if debug_snap_timer >= DEBUG_SNAP_INTERVAL:
			debug_snap_timer = 0.0
			_debug_write_snap()

	_move_player(delta)
	_update_camera()
	_update_cave_state()
	_update_void_pool_corruption(delta)
	_update_weapons(delta)
	_update_enemies(delta)
	_update_bullets(delta)
	_check_pickups()
	_update_hud_message(delta)
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
	_update_contract_mode(delta)
	_update_affix_trails(delta)

	# Flush pending enemy spawns (never append during iteration)
	if not pending_enemy_spawns.is_empty():
		for _pe in pending_enemy_spawns:
			enemies.append(_pe)
		pending_enemy_spawns.clear()

	draw_timer += delta
	if draw_timer >= 0.033:
		draw_timer = 0.0
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

		# Entropy cannon damage scaling
		if w.id == "entropy_cannon":
			var entropy_mods: Dictionary = weapon_mods.get("entropy_cannon", {})
			if entropy_mods.get("stabilized", false):
				fire_damage = int(float(def.damage + (w.level - 1) + mods_w.get("damage_bonus", 0)) * 3.0)
			else:
				var scaling: float = 1.0 + float(corruption) / 30.0
				if entropy_mods.get("resonance", false):
					scaling = 1.0 + float(corruption) / 10.0  # triple scaling
				fire_damage = int(float(def.damage + (w.level - 1) + mods_w.get("damage_bonus", 0)) * scaling)

		# Chain rifle: track bullet count for auto-crit
		if w.id == "chain_rifle":
			chain_rifle_shot_count += 1

		match def.pattern:
			"single":
				w.mag_ammo -= 1
				# Sidearm has spread — not perfect auto-aim
				var fire_dir: Vector2 = dir
				if w.id == "sidearm":
					var spread_rad: float = deg_to_rad(12.0)
					if mods_w.get("tight_aim", false):
						spread_rad = deg_to_rad(5.0)
					fire_dir = dir.rotated(randf_range(-spread_rad, spread_rad))
				var single_b: Dictionary = {
					pos = player_pos + fire_dir * (PLAYER_RADIUS + 6.0),
					vel = fire_dir * w_bullet_speed,
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
				# Chain rifle: slow on hit + auto-crit
				if w.id == "chain_rifle":
					single_b["chain_slow_on_hit"] = true
					var chain_mods: Dictionary = weapon_mods.get("chain_rifle", {})
					if chain_mods.get("precision_mode", false):
						single_b["chain_slow_on_hit"] = false
					if chain_mods.get("chain_autocrit", false) and chain_rifle_shot_count % 10 == 0:
						single_b.damage = fire_damage * 3
				# Sniper carbine: headshot flag
				if w.id == "sniper_carbine":
					single_b["sniper_headshot"] = true
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
				var melee_hit_indices: Array = []
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
						var chain_targets: Array = []
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
				_add_aoe_flash({pos=player_pos, radius=melee_range, timer=0.3, color=Color(0.1,0.8,1.0,0.6)})
				# Arc blade mutation: place slow field
				if mods_w.get("arc_fields", false):
					_add_smoke_zone({pos=player_pos, radius=80.0, timer=3.0, slowing=true})
				# Static charge mastery: track hits
				if mods_w.get("static_charge", false):
					baton_hit_count += 1
					baton_hit_timer = 3.0
					if baton_hit_count >= 3:
						baton_hit_count = 0
						_add_aoe_flash({pos=player_pos, radius=melee_range + 40.0, timer=0.3, color=Color(0.3,0.9,1.0,0.6)})
						for ei in range(enemies.size()):
							var e_sc: Dictionary = enemies[ei]
							if e_sc.hp > 0 and player_pos.distance_to(e_sc.pos) < melee_range + 40.0:
								e_sc.hp -= fire_damage
								enemies[ei] = e_sc
								if e_sc.hp <= 0:
									_on_enemy_killed(ei)
			"cone_stream":
				# Flamethrower: fire 4 projectiles in a ±25 degree forward cone
				w.mag_ammo -= 1
				var cone_half_deg: float = 25.0
				var cone_range: float = w_range + mods_w.get("range_bonus_flat", 0.0)
				var is_cryo: bool = mods_w.get("cryo_flamer", false)
				var is_corr_spray: bool = mods_w.get("corruption_spray", false)
				var cone_dmg: int = fire_damage
				if is_corr_spray:
					cone_dmg = fire_damage * 3
					corruption += 5.0 * w_fire_rate  # +5 corruption/s scaled by fire rate
				var base_angle: float = dir.angle()
				for _fp in range(4):
					var offset_deg: float = randf_range(-cone_half_deg, cone_half_deg)
					var angle: float = base_angle + deg_to_rad(offset_deg)
					var flame_dir := Vector2(cos(angle), sin(angle))
					var flame_b: Dictionary = {
						pos = player_pos + flame_dir * (PLAYER_RADIUS + 6.0),
						vel = flame_dir * w_bullet_speed,
						radius = def.bullet_radius,
						color = Color(1.0, 0.3, 0.0) if not is_cryo else Color(0.3, 0.8, 1.0),
						damage = 0 if is_cryo else cone_dmg,
						lifetime = cone_range / maxf(1.0, w_bullet_speed),
						from_player = true,
						weapon_id = w.id,
						flame = true,
					}
					if is_cryo:
						flame_b["cryo_stun"] = 2.0
					if mods_w.get("burning", false) and not is_cryo:
						flame_b["apply_burning"] = true
					if mods_w.get("cone_slow", false):
						flame_b["slow_on_hit"] = true
					bullets.append(flame_b)
				# Brief cone flash
				_add_aoe_flash({pos=player_pos + dir * 40.0, radius=30.0, timer=0.1, color=Color(1.0, 0.4, 0.0, 0.5) if not is_cryo else Color(0.3, 0.8, 1.0, 0.5)})
			"arc_aoe":
				# Grenade launcher: single slow projectile that explodes at range or on hit
				w.mag_ammo -= 1
				var grenade_b: Dictionary = {
					pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
					vel = dir * w_bullet_speed,
					radius = 10.0,
					color = Color(0.4, 0.9, 0.2),
					damage = fire_damage,
					lifetime = w_range / maxf(1.0, w_bullet_speed),
					from_player = true,
					weapon_id = w.id,
					grenade = true,
					exploded = false,
				}
				if mods_w.get("sticky", false):
					grenade_b["sticky"] = true
				bullets.append(grenade_b)
			"bounce":
				# Pulse cannon: bouncing projectile
				w.mag_ammo -= 1
				var max_bounces: int = 4 + mods_w.get("bounce_extra", 0)
				var bounce_radius: float = 150.0 + mods_w.get("bounce_radius_bonus", 0.0)
				var pulse_mods: Dictionary = weapon_mods.get("pulse_cannon", {})
				if pulse_mods.get("overclock", false):
					max_bounces = 3
				var bounce_b: Dictionary = {
					pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
					vel = dir * w_bullet_speed,
					radius = def.bullet_radius,
					color = def.color,
					damage = fire_damage,
					lifetime = w_range / maxf(1.0, w_bullet_speed) * 3.0,
					from_player = true,
					weapon_id = w.id,
					bounce = true,
					bounce_count = 0,
					max_bounces = max_bounces,
					bounce_radius = bounce_radius,
					bounce_hit_ids = [],
					void_chain = pulse_mods.get("void_chain", false),
				}
				bullets.append(bounce_b)

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
	var dead_indices: Array = []

	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		if e.hp <= 0:
			continue

		# Allies: move toward nearest enemy, skip all player interaction
		if e.get("is_ally", false):
			var nearest_dist: float = 9999.0
			var nearest_pos: Vector2 = Vector2.ZERO
			var found: bool = false
			for oe in enemies:
				if oe.get("is_ally", false) or oe.hp <= 0:
					continue
				var d: float = e.pos.distance_to(oe.pos)
				if d < nearest_dist:
					nearest_dist = d
					nearest_pos = oe.pos
					found = true
			if found and nearest_dist > e.radius + 4.0:
				var dir: Vector2 = (nearest_pos - e.pos).normalized()
				e.pos += dir * e.speed * delta
			# Ally melee attack on nearby enemy
			if found and nearest_dist < e.radius + 16.0:
				var acd: float = enemy_melee_cooldowns.get(-(i+1), 0.0)
				if acd <= 0.0:
					for ei2 in range(enemies.size()):
						if enemies[ei2].get("is_ally", false) or enemies[ei2].hp <= 0:
							continue
						if e.pos.distance_to(enemies[ei2].pos) < e.radius + enemies[ei2].radius + 4.0:
							enemies[ei2].hp -= e.melee_dmg
							enemy_melee_cooldowns[-(i+1)] = 1.2
							break
			enemies[i] = e
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

		# Burn tick (flamethrower napalm)
		if e.get("burn_timer", 0.0) > 0.0:
			e["burn_timer"] = e.burn_timer - delta
			e.hp -= maxi(1, int(e.get("burn_dmg", 1.0) * delta + 0.5))
			if e.hp <= 0:
				enemies[i] = e
				_on_enemy_killed(i)
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

		# Chain slow timer decay
		if e.get("chain_slow_timer", 0.0) > 0.0:
			e["chain_slow_timer"] = e.get("chain_slow_timer", 0.0) - delta
			if e.get("chain_slow_timer", 0.0) <= 0.0:
				e["chain_slow_factor"] = 0.0

		# Stunned check
		if e.get("stunned_timer", 0.0) > 0.0:
			e.stunned_timer -= delta
			enemies[i] = e
			continue

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
			# Payload escort: 50% chance enemies target pod instead of player
			if contract_mode == "payload_escort" and pod_active and randf() < 0.5:
				move_target = pod_pos
				dist_to_target = e.pos.distance_to(move_target)

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
							_add_aoe_flash({pos = e.pos, radius = 100.0, timer = 0.3, color = Color(1.0, 0.3, 0.0, 0.5)})
							player_hp -= 2
							player_hit_flash = 0.2
							_show_message("SLAM! -2 HP")
							if player_hp <= 0:
								_die()
					elif etype == "Phase Hunter":
						# Jump toward player every 6-9s, visible arc
						e.ranged_cooldown_timer -= delta
						if e.get("phase_jumping", false):
							# Mid-jump: advance progress
							e.phase_jump_progress = minf(e.phase_jump_progress + delta * 2.5, 1.0)
							var jfrom: Vector2 = e.get("phase_jump_from", e.pos)
							var jto: Vector2 = e.get("phase_jump_to", e.pos)
							e.pos = jfrom.lerp(jto, e.phase_jump_progress)
							if e.phase_jump_progress >= 1.0:
								e.phase_jumping = false
								e.phase_timer = randf_range(6.0, 9.0)
								# Landing impact flash
								_add_aoe_flash({pos = e.pos, radius = 60.0, timer = 0.3, color = Color(0.5, 0.1, 1.0, 0.7)})
								# Landing damage if very close
								if e.pos.distance_to(player_pos) < 50.0:
									player_hp -= 2
									player_hit_flash = 0.2
									if player_hp <= 0:
										_die()
						else:
							e.phase_timer -= delta
							if e.phase_timer <= 0.0:
								# Start jump toward player
								var rng2 := RandomNumberGenerator.new()
								rng2.randomize()
								var angle: float = rng2.randf() * TAU
								var tdist: float = rng2.randf_range(150.0, 250.0)
								var jto := player_pos + Vector2(cos(angle), sin(angle)) * tdist
								jto.x = clampf(jto.x, 80.0, WORLD_W - 80.0)
								jto.y = clampf(jto.y, 80.0, WORLD_H - 80.0)
								e.phase_jump_from = e.pos
								e.phase_jump_to = jto
								e.phase_jump_progress = 0.0
								e.phase_jumping = true
								# Warning flash at landing zone
								_add_aoe_flash({pos = jto, radius = 55.0, timer = 0.4, color = Color(0.6, 0.2, 1.0, 0.5)})
							# Walk toward player while not jumping
							var to_p2: Vector2 = (player_pos - e.pos).normalized()
							move_dir = to_p2
						if e.ranged_cooldown_timer <= 0.0 and not e.get("phase_jumping", false):
							e.ranged_cooldown_timer = 1.4
							var shoot_dir: Vector2 = (player_pos - e.pos).normalized()
							for spread_f in [-0.2, 0.0, 0.2]:
								var sd: Vector2 = shoot_dir.rotated(spread_f)
								bullets.append({pos = e.pos + sd * 25.0, vel = sd * 280.0, radius = 6.0,
									color = Color(0.8, 0.2, 1.0), damage = 2, lifetime = 1.5, from_player = false})
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
					elif etype == "Rift Colossus":
						# Slow charge + shockwave AOE every 6s
						move_dir = (player_pos - e.pos).normalized()
						e.shockwave_timer = e.get("shockwave_timer", 6.0) - delta
						if e.shockwave_timer <= 0.0:
							e.shockwave_timer = 6.0
							_add_aoe_flash({pos = e.pos, radius = 60.0, timer = 0.5, color = Color(1.0, 1.0, 1.0, 0.6)})
							if dist_to_player < 60.0:
								player_hp -= 18
								player_hit_flash = 0.2
								_show_message("SHOCKWAVE! -18 HP")
								if player_hp <= 0:
									_die()
					elif etype == "Null Wraith":
						# Invisible until close, corruption burst on death handled in _on_enemy_killed
						move_dir = (player_pos - e.pos).normalized()
					elif etype == "Stone Sentinel":
						# Stationary until player within 300px, then charges
						if e.get("sentinel_pause", 0.0) > 0.0:
							e["sentinel_pause"] = e.sentinel_pause - delta
							move_dir = Vector2.ZERO
						elif e.get("sentinel_charging", false):
							move_dir = (e.get("sentinel_target", player_pos) - e.pos).normalized()
							e["sentinel_charge_dist"] = e.get("sentinel_charge_dist", 0.0) + 160.0 * delta
							if e.sentinel_charge_dist >= 400.0:
								e.sentinel_charging = false
								e["sentinel_pause"] = 2.0
								e["sentinel_charge_dist"] = 0.0
							e.speed = 160.0
						elif dist_to_player < 300.0:
							e.sentinel_charging = true
							e["sentinel_target"] = Vector2(player_pos.x, player_pos.y)
							e["sentinel_charge_dist"] = 0.0
							e.speed = 160.0
						else:
							move_dir = Vector2.ZERO
							e.speed = 0.0
					elif etype == "Tide Reaper":
						# Fast in rivers, normal elsewhere. Dash + knockback every 8s
						var in_river: bool = _get_biome_at(e.pos) == "river_bank"
						e.speed = 150.0 if in_river else 70.0
						move_dir = (player_pos - e.pos).normalized()
						e.dash_timer = e.get("dash_timer", 8.0) - delta
						if e.dash_timer <= 0.0 and dist_to_player < 350.0:
							e.dash_timer = 8.0
							# Dash toward player
							var dash_dir: Vector2 = (player_pos - e.pos).normalized()
							e.pos += dash_dir * 150.0
							e.pos.x = clampf(e.pos.x, 60.0, WORLD_W - 60.0)
							e.pos.y = clampf(e.pos.y, 60.0, WORLD_H - 60.0)
							if e.pos.distance_to(player_pos) < 60.0:
								var kb_dir: Vector2 = (player_pos - e.pos).normalized()
								player_pos += kb_dir * 100.0
								player_pos.x = clampf(player_pos.x, 20.0, WORLD_W - 20.0)
								player_pos.y = clampf(player_pos.y, 20.0, WORLD_H - 20.0)
								player_hp -= 2
								player_hit_flash = 0.2
								if player_hp <= 0:
									_die()
					elif etype == "Current Stalker":
						# Medium speed charge, splits on first death
						move_dir = (player_pos - e.pos).normalized()
					# --- Apex elites ---
					elif etype == "Rift Sovereign":
						# Phase Hunter behavior but jumps every 4s, spawns adds every 15s
						e.ranged_cooldown_timer -= delta
						if e.get("phase_jumping", false):
							e.phase_jump_progress = minf(e.phase_jump_progress + delta * 2.5, 1.0)
							var jfrom: Vector2 = e.get("phase_jump_from", e.pos)
							var jto: Vector2 = e.get("phase_jump_to", e.pos)
							e.pos = jfrom.lerp(jto, e.phase_jump_progress)
							if e.phase_jump_progress >= 1.0:
								e.phase_jumping = false
								e.phase_timer = 4.0
								_add_aoe_flash({pos = e.pos, radius = 60.0, timer = 0.3, color = Color(1.0, 0.85, 0.0, 0.7)})
								if e.pos.distance_to(player_pos) < 50.0:
									player_hp -= 3
									player_hit_flash = 0.2
									if player_hp <= 0:
										_die()
						else:
							e.phase_timer -= delta
							if e.phase_timer <= 0.0:
								var rng_rs := RandomNumberGenerator.new()
								rng_rs.randomize()
								var jto := player_pos + Vector2(cos(rng_rs.randf() * TAU), sin(rng_rs.randf() * TAU)) * rng_rs.randf_range(120.0, 200.0)
								jto.x = clampf(jto.x, 80.0, WORLD_W - 80.0)
								jto.y = clampf(jto.y, 80.0, WORLD_H - 80.0)
								e.phase_jump_from = e.pos
								e.phase_jump_to = jto
								e.phase_jump_progress = 0.0
								e.phase_jumping = true
							move_dir = (player_pos - e.pos).normalized()
						# Spawn adds every 15s
						e.apex_spawn_timer = e.get("apex_spawn_timer", 15.0) - delta
						if e.apex_spawn_timer <= 0.0:
							e.apex_spawn_timer = 15.0
							var rng_a := RandomNumberGenerator.new()
							rng_a.randomize()
							var types_a: Array = CREATURE_DEFS.keys()
							for _si in range(2):
								var stype: String = types_a[rng_a.randi_range(0, types_a.size() - 1)]
								_spawn_single_enemy(stype, false, rng_a)
								enemies[-1].is_aggroed = true
								enemies[-1].pos = e.pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
					elif etype == "The Hollow":
						# Void Hulk behavior but doubled corruption aura, leaves void pools
						e.charge_timer -= delta
						move_dir = (player_pos - e.pos).normalized()
						# Doubled corruption aura
						if dist_to_player < 120.0:
							corruption += 6.0 * delta
						# Ground slam
						if e.charge_timer <= 0.0 and dist_to_player < 120.0:
							e.charge_timer = 4.0
							_add_aoe_flash({pos = e.pos, radius = 120.0, timer = 0.3, color = Color(0.4, 0.0, 0.6, 0.5)})
							player_hp -= 3
							player_hit_flash = 0.2
							if player_hp <= 0:
								_die()
						# Leave void trail pools every 3s
						e.void_trail_timer = e.get("void_trail_timer", 3.0) - delta
						if e.void_trail_timer <= 0.0:
							e.void_trail_timer = 3.0
							var _hollow_count: int = 0
							for _sz in smoke_zones:
								if _sz.get("source", "") == "hollow":
									_hollow_count += 1
							if _hollow_count >= 5:
								for _szi in range(smoke_zones.size()):
									if smoke_zones[_szi].get("source", "") == "hollow":
										smoke_zones.remove_at(_szi)
										break
							_add_smoke_zone({pos = Vector2(e.pos.x, e.pos.y), radius = 40.0, timer = 20.0, slowing = false, corruption_zone = true, corruption_rate = 10.0, source = "hollow"})
					elif etype == "Ancient Brood":
						# Stationary, spawns buffed adds
						move_dir = Vector2.ZERO
						e.ranged_cooldown_timer -= delta
						if e.ranged_cooldown_timer <= 0.0:
							e.ranged_cooldown_timer = 2.0
							var sd_ab: Vector2 = (player_pos - e.pos).normalized()
							bullets.append({pos = e.pos + sd_ab * 25.0, vel = sd_ab * 220.0, radius = 6.0,
								color = Color(0.9, 0.1, 0.5), damage = 3, lifetime = 1.6, from_player = false})
						if not e.brood_triggered and float(e.hp) / float(e.max_hp) <= 0.5:
							e.brood_triggered = true
							_show_message("Ancient Brood calls buffed spawn!")
							var rng_ab := RandomNumberGenerator.new()
							rng_ab.randomize()
							for _add in range(6):
								_spawn_single_enemy("Rift Parasite", false, rng_ab)
								enemies[-1].is_aggroed = true
								enemies[-1].hp *= 2
								enemies[-1].max_hp *= 2
								enemies[-1].melee_dmg = int(float(enemies[-1].melee_dmg) * 1.5)
					elif etype == "Abyssal Tide":
						# Tide Reaper but faster dash, bigger knockback
						var in_river_at: bool = _get_biome_at(e.pos) == "river_bank"
						e.speed = 180.0 if in_river_at else 80.0
						move_dir = (player_pos - e.pos).normalized()
						e.dash_timer = e.get("dash_timer", 5.0) - delta
						if e.dash_timer <= 0.0 and dist_to_player < 400.0:
							e.dash_timer = 5.0
							var dash_d: Vector2 = (player_pos - e.pos).normalized()
							e.pos += dash_d * 200.0
							e.pos.x = clampf(e.pos.x, 60.0, WORLD_W - 60.0)
							e.pos.y = clampf(e.pos.y, 60.0, WORLD_H - 60.0)
							if e.pos.distance_to(player_pos) < 80.0:
								var kb_d: Vector2 = (player_pos - e.pos).normalized()
								player_pos += kb_d * 150.0
								player_pos.x = clampf(player_pos.x, 20.0, WORLD_W - 20.0)
								player_pos.y = clampf(player_pos.y, 20.0, WORLD_H - 20.0)
								player_hp -= 3
								player_hit_flash = 0.2
								if player_hp <= 0:
									_die()
					else:
						# Unknown elite — just charge
						move_dir = (player_pos - e.pos).normalized()

					# === AFFIX EFFECTS (per-tick) ===
					if e.get("is_elite", false):
						var afxs: Dictionary = e.get("affixes", {})
						# Teleporter
						if afxs.get("teleporter", false):
							e["tp_timer"] = e.get("tp_timer", 8.0) - delta
							if e.tp_timer <= 0.0 and dist_to_player > 250.0:
								e["tp_timer"] = 8.0
								var tp_dir: Vector2 = (player_pos - e.pos).normalized()
								e.pos = player_pos - tp_dir * 80.0
								_add_aoe_flash({pos = e.pos, radius = 30.0, timer = 0.2, color = Color(0.5, 0.0, 1.0, 0.6)})
						# Venomous trail
						if afxs.get("venomous", false):
							var vt: Array = e.get("venom_trail", [])
							vt.append({pos = Vector2(e.pos.x, e.pos.y), timer = 4.0})
							if vt.size() > 15:
								vt.remove_at(0)
							e["venom_trail"] = vt
						# Magnetic pull
						if afxs.get("magnetic", false):
							e["magnetic_timer"] = e.get("magnetic_timer", 5.0) - delta
							if e.magnetic_timer <= 0.0:
								e["magnetic_timer"] = 5.0
								var pull_dir: Vector2 = (e.pos - player_pos).normalized()
								player_pos += pull_dir * 80.0
								player_pos.x = clampf(player_pos.x, 20.0, WORLD_W - 20.0)
								player_pos.y = clampf(player_pos.y, 20.0, WORLD_H - 20.0)
						# Berserker
						if afxs.get("berserker", false) and float(e.hp) / float(e.max_hp) < 0.3:
							e.speed *= 1.3
						# Spectral: immune to slow
						if afxs.get("spectral", false):
							e["slow_until"] = 0.0
							e["chain_slow_timer"] = 0.0
							e["chain_slow_factor"] = 0.0

			# Apply movement (non-pack behaviors)
			if move_dir != Vector2.ZERO:
				var spd: float = e.speed
				if e.behavior == "burst" and e.burst_active:
					spd *= 2.5
				# Slow debuff (#1)
				var now_sec: float = Time.get_ticks_msec() * 0.001
				if e.get("slow_until", 0.0) > now_sec:
					spd *= 0.6
				# Chain rifle slow
				if e.get("chain_slow_timer", 0.0) > 0.0:
					spd *= (1.0 - e.get("chain_slow_factor", 0.0))
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

		# Clamp enemies within world bounds
		e.pos.x = clampf(e.pos.x, 50.0, WORLD_W - 50.0)
		e.pos.y = clampf(e.pos.y, 50.0, WORLD_H - 50.0)

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
		var living: Array = []
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

	# Purge dead enemies every 5s to keep array lean
	purge_timer -= delta
	if purge_timer <= 0.0:
		purge_timer = 5.0
		var alive: Array = []
		for e in enemies:
			if e.hp > 0:
				alive.append(e)
		enemies = alive

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
	var to_remove: Array = []
	var new_bullets: Array = []

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
			# Grenade explosion on expiry
			if b.get("grenade", false) and not b.get("exploded", false):
				b["exploded"] = true
				_grenade_explode(b.pos, b.damage, b.get("weapon_id", ""), b.get("mini_grenade", false))
			# Slow field on land (lance clean mutation)
			if b.get("slow_field_on_land", false) and b.from_player:
				_add_smoke_zone({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
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
				_add_smoke_zone({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
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
				if e.get("is_ally", false):
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
							hit_dmg = _apply_affix_damage(e, hit_dmg, true)
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
								_add_smoke_zone({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
							if e.hp <= 0:
								_on_enemy_killed(ei, b.get("weapon_id", ""))
							# Pierce count limit for scatter clean
							var max_pierce: int = b.get("pierce_count", 9999)
							if hit_ids.size() >= max_pierce:
								to_remove.append(i)
								break
					else:
						# Grenade: explode on hit instead of direct damage
						if b.get("grenade", false) and not b.get("exploded", false):
							b["exploded"] = true
							_grenade_explode(b.pos, b.damage, b.get("weapon_id", ""), b.get("mini_grenade", false))
							to_remove.append(i)
							bullets[i] = b
							break
						# Cryo flamer: stun instead of damage
						if b.get("cryo_stun", 0.0) > 0.0:
							var stun_dur: float = weapon_mods.get(b.get("weapon_id", ""), {}).get("cryo_stun_duration", b.get("cryo_stun", 2.0))
							e.stunned_timer = stun_dur
							# Shatter mastery: frozen enemies take +50% from other sources
							if weapon_mods.get(b.get("weapon_id", ""), {}).get("shatter", false):
								e["marked_timer"] = stun_dur
								e["marked_dmg_bonus"] = 1.5
							enemies[ei] = e
							to_remove.append(i)
							bullets[i] = b
							break
						# Sniper carbine headshot: 3x to elites in center zone
						if b.get("sniper_headshot", false) and e.get("is_elite", false):
							var headshot_radius: float = 30.0
							if b.pos.distance_to(e.pos) < headshot_radius:
								hit_dmg *= 3
								_show_message("HEADSHOT! x3")
							# Killshot mutation: one-shot under 20% HP
							var sniper_mods: Dictionary = weapon_mods.get("sniper_carbine", {})
							var ks_threshold: float = 0.2
							if sniper_mods.get("killshot_30", false):
								ks_threshold = 0.3
							if sniper_mods.get("killshot", false) and float(e.hp) / float(e.max_hp) <= ks_threshold:
								hit_dmg = e.hp
						# Chain rifle slow on hit
						if b.get("chain_slow_on_hit", false):
							var cur_slow: float = e.get("chain_slow_factor", 0.0)
							var slow_add: float = 0.1
							var slow_cap: float = 0.5
							var chain_m: Dictionary = weapon_mods.get("chain_rifle", {})
							if chain_m.get("chain_slow_boost", false):
								slow_add = 0.12
								slow_cap = 0.6
							if chain_m.get("deep_suppression", false):
								slow_cap = 0.7
							e["chain_slow_factor"] = minf(slow_cap, cur_slow + slow_add)
							e["chain_slow_timer"] = 0.5
							# Suppressor mutation: slowed enemies take +30% from all sources
							if chain_m.get("suppressor", false) and e.get("chain_slow_factor", 0.0) > 0.0:
								e["marked_timer"] = 0.5
								e["marked_dmg_bonus"] = 1.3
						# Bounce bullet: redirect to nearest enemy
						if b.get("bounce", false):
							var b_hit_ids: Array = b.get("bounce_hit_ids", [])
							b_hit_ids.append(ei)
							b["bounce_hit_ids"] = b_hit_ids
							hit_dmg = _apply_affix_damage(e, hit_dmg, true)
							e.hp -= hit_dmg
							if b.get("void_chain", false):
								e["burn_timer"] = 1.0
								e["burn_dmg"] = 2.0
							enemies[ei] = e
							if e.hp <= 0:
								_on_enemy_killed(ei, b.get("weapon_id", ""))
							if b.get("bounce_count", 0) < b.get("max_bounces", 4):
								# Find nearest enemy not already hit
								var best_bounce_dist: float = b.get("bounce_radius", 150.0)
								var best_bounce_idx: int = -1
								for bei in range(enemies.size()):
									if enemies[bei].hp <= 0 or b_hit_ids.has(bei):
										continue
									var bd: float = b.pos.distance_to(enemies[bei].pos)
									if bd < best_bounce_dist:
										best_bounce_dist = bd
										best_bounce_idx = bei
								if best_bounce_idx >= 0:
									b["bounce_count"] = b.get("bounce_count", 0) + 1
									var bounce_dir: Vector2 = (enemies[best_bounce_idx].pos - b.pos).normalized()
									b.vel = bounce_dir * b.vel.length()
									b.lifetime = best_bounce_dist / maxf(1.0, b.vel.length()) + 0.5
									bullets[i] = b
								else:
									to_remove.append(i)
							else:
								to_remove.append(i)
							break
						# Apply affix damage modifiers
						hit_dmg = _apply_affix_damage(e, hit_dmg, true)
						e.hp -= hit_dmg
						# Burning (flamethrower napalm perk)
						if b.get("apply_burning", false):
							e["burn_timer"] = 3.0
							e["burn_dmg"] = 1.0
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
						enemies[ei] = e
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
						# Flame siphon: kill with flames restores 1 HP
						if b.get("flame", false) and weapon_mods.get(b.get("weapon_id", ""), {}).get("flame_siphon", false) and e.hp <= 0:
							player_hp = mini(player_hp + 1, player_max_hp)
						to_remove.append(i)
						if b.get("explode", false):
							_bullet_explode(b.pos, hit_dmg)
						if b.get("slow_field_on_land", false):
							_add_smoke_zone({pos=b.pos, radius=80.0, timer=3.0, slowing=true})
						if e.hp <= 0:
							_on_enemy_killed(ei, b.get("weapon_id", ""))
						break
		else:
			# Drone intercept check
			if drone_active and b.pos.distance_to(drone_pos) < 100.0 and drone_intercept_timer <= 0.0:
				drone_intercept_timer = 4.0
				to_remove.append(i)
				_add_aoe_flash({pos=drone_pos, radius=15.0, timer=0.2, color=Color(1.0, 1.0, 1.0, 0.8)})
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

	# Current Stalker: split on first death
	if e.get("elite_type", "") == "Current Stalker" and not e.get("has_split", false):
		e.has_split = true
		e.hp = int(float(e.max_hp) * 0.3)
		enemies[idx] = e
		# Spawn a copy offset perpendicular
		var perp: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 60.0
		var copy: Dictionary = e.duplicate()
		copy.pos = death_pos + perp
		copy.hp = int(float(e.max_hp) * 0.3)
		copy.has_split = true
		pending_enemy_spawns.append(copy)
		_show_message("Current Stalker splits!")
		return

	# Null Wraith: corruption burst on death
	if e.get("elite_type", "") == "Null Wraith":
		corruption += 20.0
		_show_message("Wraith dies: +20 corruption!")

	# Multiplier affix: spawn 2 copies at 30% HP (no affixes, no drops)
	if e.get("affixes", {}).get("multiplier", false) and not e.get("is_multiplier_copy", false):
		for _mc in range(2):
			var mc_copy: Dictionary = e.duplicate()
			mc_copy.hp = int(float(e.max_hp) * 0.3)
			mc_copy.max_hp = mc_copy.hp
			mc_copy.pos = death_pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			mc_copy.affixes = {}
			mc_copy.affix_list = []
			mc_copy["is_multiplier_copy"] = true
			mc_copy["no_drops"] = true
			pending_enemy_spawns.append(mc_copy)

	# Apex death: reset timer
	if e.get("is_apex", false):
		apex_active = false
		apex_timer = 480.0  # 8 min after death

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
			bullets.append({pos=death_pos, vel=mb_dir * 120.0, radius=12.0, color=Color(0.2,1.0,0.5), damage=15, lifetime=4.0, from_player=true, homing=true, bullet_speed=120.0, weapon_id="missile", is_missile=true})

	# Scavenger: elites drop extra essence
	if "scavenger" in modifiers_taken and e.get("is_elite", false):
		_add_pickup({pos = death_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), type = "essence"})

	# On-kill lance (#2) — only triggers from player-fired lances, not from auto-lances
	var lance_mods: Dictionary = weapon_mods.get("lance", {})
	if lance_mods.get("on_kill_lance", false) and main_weapon.get("id", "") == "lance" and killer_weapon != "auto_lance":
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
				weapon_id = "auto_lance",
			})

	# Split on kill — dart (#10) — skip for missile_burst missiles (killer_weapon="missile")
	if killer_weapon == "dart" and weapon_mods.get("dart", {}).get("split_on_kill", false):
		var dart_def: Dictionary = WEAPON_DEFS["dart"]
		var dart_mods: Dictionary = weapon_mods.get("dart", {})
		var dart_dmg: int = dart_def.damage + dart_mods.get("damage_bonus", 0)
		# Find 2 nearest living enemies
		var split_targets: Array = []
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

	# Elites: drop ingredient guaranteed + big essence burst
	if e.get("is_elite", false) and not e.get("no_drops", false):
		_show_message("Elite down! Ingredient dropped!")
		# Drop a big essence burst
		for _b in range(5):
			_add_pickup({pos = death_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), type = "essence"})
		# Biome-based ingredient drop
		var elite_biome: String = e.get("elite_biome", _get_biome_at(death_pos))
		var biome_ingredient_map: Dictionary = {
			"open": "rift_dust",
			"void_pool": "void_crystal",
			"cave": "cave_moss",
			"river_bank": "river_silt",
		}
		var ing_id: String = biome_ingredient_map.get(elite_biome, "rift_dust")
		var biome_ing_colors: Dictionary = {
			"rift_dust": Color(0.8, 0.6, 0.2),
			"void_crystal": Color(0.5, 0.0, 0.8),
			"cave_moss": Color(0.3, 0.7, 0.4),
			"river_silt": Color(0.3, 0.6, 0.9),
			"elite_core": Color(1.0, 0.85, 0.0),
		}
		# Drop biome ingredient
		ingredient_pickups.append({
			pos = death_pos,
			data = {id = ing_id, name = ing_id.replace("_", " ").capitalize(), is_pristine = false, ingredient = true, uses = 1},
			collected = false, pulse_phase = 0.0, color = biome_ing_colors.get(ing_id, Color.GOLD),
		})
		# Always also drop 1 elite_core
		ingredient_pickups.append({
			pos = death_pos + Vector2(15, 0),
			data = {id = "elite_core", name = "Elite Core", is_pristine = false, ingredient = true, uses = 1},
			collected = false, pulse_phase = 0.0, color = biome_ing_colors.get("elite_core", Color.GOLD),
		})
		# Track contract progress
		target_kills += 1
		if contract_mode == "hunt" or contract_mode == "":
			_show_message("Ingredients: %d/%d" % [target_kills, target_total])
		else:
			_show_message("Ingredients: %d" % target_kills)
		if target_kills >= target_total and not exit_spawned:
			_spawn_exit()
			return
		return

	# Regular enemies: essence + rare HP/cleanse drops
	_add_pickup({pos = death_pos + Vector2(-10, 0), type = "essence"})
	# ~8% chance: health pack (green cross) — only if below max HP, favors clean builds
	var hp_drop_chance: float = 0.08 if corruption < 35.0 else 0.04
	if player_hp < player_max_hp and randf() < hp_drop_chance:
		_add_pickup({pos = death_pos + Vector2(10, 0), type = "health"})
	# ~6% chance: cleanse shard — reduces corruption by 10, only spawns at >20% corruption
	if corruption > 20.0 and randf() < 0.06:
		_add_pickup({pos = death_pos + Vector2(0, 10), type = "cleanse"})

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
	var to_remove: Array = []

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
			elif p.type == "health":
				player_hp = mini(player_hp + 2, player_max_hp)
				_show_message("+2 HP")
				debug_log_push("Picked up health pack")
			elif p.type == "cleanse":
				corruption = maxf(0.0, corruption - 10.0)
				_show_message("Corruption -10")
				debug_log_push("Picked up cleanse shard")
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
	var options: Array = []
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
			var available_m: Array = []
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
		var avail_res: Array = []
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
		var avail2: Array = []
		for m in RUN_MODIFIERS:
			if not modifiers_taken.has(m.id):
				avail2.append(m)
		avail2.shuffle()
		if avail2.size() > 0:
			var m2: Dictionary = avail2[0]
			options.append({type="modifier", id=m2.id, rarity=m2.rarity, icon=m2.icon, label=m2.name, desc=m2.desc, perk={}})

	# --- Slot 3: MODIFIER ---
	var used_mod_ids: Array = modifiers_taken.duplicate()
	for o in options:
		if o.type == "modifier":
			used_mod_ids.append(o.get("id", ""))
	var avail3: Array = []
	for m in RUN_MODIFIERS:
		if not used_mod_ids.has(m.id):
			avail3.append(m)
	avail3.shuffle()
	if avail3.size() > 0:
		var m3: Dictionary = avail3[0]
		options.append({type="modifier", id=m3.id, rarity=m3.rarity, icon=m3.icon, label=m3.name, desc=m3.desc, perk={}})

	# --- Guaranteed fallbacks so panel is never empty ---
	if options.size() < 3:
		var fallbacks: Array = [
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
		"range_bonus":
			mods["range_bonus_flat"] = mods.get("range_bonus_flat", 0.0) + perk.value
		"burning":
			mods["burning"] = true
		"cone_slow":
			mods["cone_slow"] = true
		"flamer_fork":
			pass  # handled via mutation system at level 5
		"cluster":
			mods["cluster"] = true
		"grenade_knockback":
			mods["grenade_knockback"] = true
		"grenade_fork":
			pass  # handled via mutation system at level 5
	weapon_mods[wid] = mods

# =========================================================
# DEATH & COMPLETION
# =========================================================
func _die() -> void:
	dead = true
	dead_timer = 2.0
	player_hp = 0
	_show_message("DEAD")
	debug_log_push("Player DIED | corr %.0f%% | wave %d | kills %d/%d" % [corruption, wave_current, target_kills, target_total])

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

# =========================================================
# HELPERS — perk effects
# =========================================================
func _bullet_explode(impact_pos: Vector2, dmg: int) -> void:
	_add_aoe_flash({pos = impact_pos, radius = 60.0, timer = 0.3, color = Color(1.0, 0.6, 0.1, 0.7)})
	for ei2 in range(enemies.size()):
		var ae: Dictionary = enemies[ei2]
		if ae.hp <= 0:
			continue
		if impact_pos.distance_to(ae.pos) < 60.0:
			ae.hp -= dmg
			enemies[ei2] = ae
			if ae.hp <= 0:
				_on_enemy_killed(ei2)

func _apply_affix_damage(e: Dictionary, dmg: int, is_ranged: bool = true) -> int:
	var afxs: Dictionary = e.get("affixes", {})
	var actual_dmg: int = dmg
	# Armored: -60% ranged damage
	if afxs.get("armored", false) and is_ranged:
		actual_dmg = int(float(dmg) * 0.4)
	# Shielded: damage shield first
	if afxs.get("shielded", false) and e.get("shield_hp", 0) > 0:
		var shield: int = e.get("shield_hp", 0)
		if actual_dmg <= shield:
			e["shield_hp"] = shield - actual_dmg
			return 0
		else:
			actual_dmg -= shield
			e["shield_hp"] = 0
	# Vampiric: heal 15% of damage dealt
	if afxs.get("vampiric", false):
		var heal: int = maxi(1, int(float(actual_dmg) * 0.15))
		e.hp = mini(e.hp + heal, e.max_hp)
	# Corrupting: add corruption on hit to player
	if afxs.get("corrupting", false):
		corruption += 5.0
	return actual_dmg

func _grenade_explode(impact_pos: Vector2, dmg: int, wid: String, is_mini: bool = false) -> void:
	var mods_g: Dictionary = weapon_mods.get(wid, {})
	var aoe_radius: float = 80.0 + mods_g.get("aoe_radius_bonus", 0.0)
	_add_aoe_flash({pos = impact_pos, radius = aoe_radius, timer = 0.3, color = Color(0.4, 0.9, 0.2, 0.7)})
	for ei2 in range(enemies.size()):
		var ae: Dictionary = enemies[ei2]
		if ae.hp <= 0:
			continue
		if impact_pos.distance_to(ae.pos) < aoe_radius:
			ae.hp -= dmg
			# Stagger perk: knockback 80px
			if mods_g.get("grenade_knockback", false):
				var kb_dir: Vector2 = (ae.pos - impact_pos).normalized()
				ae.pos += kb_dir * 80.0
			# Concussion mastery: stun 1s
			if mods_g.get("concussion_stun", false):
				ae.stunned_timer = 1.0
			enemies[ei2] = ae
			if ae.hp <= 0:
				_on_enemy_killed(ei2)
	# Cluster bomb perk: spawn 3 mini grenades (only from parent grenade, not from minis)
	if mods_g.get("cluster", false) and not is_mini:
		for _ci in range(3):
			var cluster_angle: float = randf() * TAU
			var cluster_dir: Vector2 = Vector2(cos(cluster_angle), sin(cluster_angle))
			bullets.append({
				pos = impact_pos,
				vel = cluster_dir * 150.0,
				radius = 6.0,
				color = Color(0.5, 1.0, 0.3),
				damage = maxi(1, int(dmg * 0.4)),
				lifetime = 0.5,
				from_player = true,
				weapon_id = wid,
				grenade = true,
				exploded = false,
				mini_grenade = true,
			})
	# Void grenade mutation: leave corruption zone
	if mods_g.get("void_grenade", false):
		var zone_radius: float = 80.0 + mods_g.get("corr_zone_radius_bonus", 0.0)
		_add_smoke_zone({pos=impact_pos, radius=zone_radius, timer=5.0, toxic=true, slowing=false})

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
			if not _is_on_screen(seg_pos):
				continue
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
		if not _is_on_screen(Vector2(pool.pos.x, pool.pos.y)):
			continue
		var pool_sp: Vector2 = _w2s(Vector2(pool.pos.x, pool.pos.y))
		var vp_pulse: float = 0.4 + 0.3 * sin(pool.pulse_phase + hunt_elapsed * 2.5)
		draw_circle(pool_sp, pool.radius, Color(0.25, 0.0, 0.45, vp_pulse * 0.7))
		draw_arc(pool_sp, pool.radius, 0.0, TAU, 32, Color(0.5, 0.0, 0.8, vp_pulse), 2.0)

	# Obstacles
	for obs in obstacles:
		if not _is_on_screen(obs.pos):
			continue
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
		if not _is_on_screen(p.pos):
			continue
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
		elif p.type == "health":
			# Green cross
			draw_rect(Rect2(sp + Vector2(-6, -2), Vector2(12, 4)), Color(0.2, 0.9, 0.3))
			draw_rect(Rect2(sp + Vector2(-2, -6), Vector2(4, 12)), Color(0.2, 0.9, 0.3))
			draw_circle(sp, 9.0, Color(0.2, 0.9, 0.3, 0.25))
		elif p.type == "cleanse":
			# Cyan diamond
			draw_line(sp + Vector2(0, -8), sp + Vector2(8, 0), Color(0.2, 0.9, 1.0), 2.0)
			draw_line(sp + Vector2(8, 0), sp + Vector2(0, 8), Color(0.2, 0.9, 1.0), 2.0)
			draw_line(sp + Vector2(0, 8), sp + Vector2(-8, 0), Color(0.2, 0.9, 1.0), 2.0)
			draw_line(sp + Vector2(-8, 0), sp + Vector2(0, -8), Color(0.2, 0.9, 1.0), 2.0)
			draw_circle(sp, 9.0, Color(0.2, 0.9, 1.0, 0.2))

	# Ingredient pickups (Phase 3)
	var time_sec: float = Time.get_ticks_msec() * 0.001
	for ip in ingredient_pickups:
		if ip.collected:
			continue
		if not _is_on_screen(ip.pos):
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
		if not _is_on_screen(e.pos):
			continue
		var sp: Vector2 = _w2s(e.pos)
		var is_elite: bool = e.get("is_elite", false)
		var draw_color: Color = e.color
		# Dormant lurkers draw at 50% alpha
		if e.get("dormant", false):
			draw_color = Color(draw_color.r, draw_color.g, draw_color.b, 0.5)
		# Null Wraith: invisible until close
		if e.get("elite_type", "") == "Null Wraith":
			var nw_dist: float = player_pos.distance_to(e.pos)
			var nw_alpha: float = 0.15
			if nw_dist < 200.0:
				nw_alpha = lerpf(1.0, 0.15, nw_dist / 200.0)
			draw_color = Color(draw_color.r, draw_color.g, draw_color.b, nw_alpha)
		# Phase Hunter / Rift Sovereign mid-jump: scale up and add motion trail
		var draw_radius: float = e.radius
		var etype_draw: String = e.get("elite_type", "")
		if (etype_draw == "Phase Hunter" or etype_draw == "Rift Sovereign") and e.get("phase_jumping", false):
			var jp: float = e.get("phase_jump_progress", 0.0)
			var arc_scale: float = 1.0 + sin(jp * PI) * 0.6
			draw_radius = e.radius * arc_scale
			draw_color = Color(0.8, 0.3, 1.0, 0.9) if etype_draw == "Phase Hunter" else Color(1.0, 0.8, 0.2, 0.9)
			draw_circle(sp, e.radius * 0.5, Color(0.3, 0.0, 0.5, 0.3))
		# Rift Colossus: dark purple with lighter ring
		if etype_draw == "Rift Colossus":
			draw_circle(sp, draw_radius, Color(0.2, 0.0, 0.35))
			draw_arc(sp, draw_radius, 0.0, TAU, 32, Color(0.5, 0.2, 0.7, 0.8), 3.0)
		# Stone Sentinel: grey diamond shape
		elif etype_draw == "Stone Sentinel":
			var diamond_pts := PackedVector2Array([sp + Vector2(0, -draw_radius), sp + Vector2(draw_radius, 0), sp + Vector2(0, draw_radius), sp + Vector2(-draw_radius, 0)])
			draw_colored_polygon(diamond_pts, Color(0.5, 0.5, 0.5))
			draw_polyline(PackedVector2Array([sp + Vector2(0, -draw_radius), sp + Vector2(draw_radius, 0), sp + Vector2(0, draw_radius), sp + Vector2(-draw_radius, 0), sp + Vector2(0, -draw_radius)]), Color(0.7, 0.7, 0.7), 2.0)
		# Tide Reaper / Abyssal Tide: elongated dark blue
		elif etype_draw == "Tide Reaper" or etype_draw == "Abyssal Tide":
			var tr_col: Color = Color(0.1, 0.2, 0.6) if etype_draw == "Tide Reaper" else Color(0.05, 0.15, 0.5)
			draw_circle(sp, draw_radius * 0.7, tr_col)
			draw_circle(sp + Vector2(0, -draw_radius * 0.4), draw_radius * 0.5, tr_col)
			if etype_draw == "Abyssal Tide":
				var glow_p: float = 0.5 + 0.3 * sin(hunt_elapsed * 3.0)
				draw_arc(sp, draw_radius + 4.0, 0.0, TAU, 32, Color(0.2, 0.4, 1.0, glow_p), 2.0)
		else:
			draw_circle(sp, draw_radius, draw_color)
		if is_elite:
			var is_apex: bool = e.get("is_apex", false)
			if is_apex:
				# Gold accent ring for apex
				var pulse: float = 0.7 + sin(hunt_elapsed * 5.0) * 0.3
				draw_arc(sp, e.radius + 5.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.0, pulse), 3.0)
				draw_arc(sp, e.radius + 10.0, 0.0, TAU, 32, Color(1.0, 0.6, 0.0, pulse * 0.6), 2.0)
				draw_arc(sp, e.radius + 15.0, 0.0, TAU, 32, Color(1.0, 0.4, 0.0, pulse * 0.3), 1.5)
			else:
				# Pulsing gold double ring for standard elites
				var pulse: float = 0.6 + sin(hunt_elapsed * 4.0) * 0.3
				draw_arc(sp, e.radius + 5.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.1, pulse), 2.5)
				draw_arc(sp, e.radius + 10.0, 0.0, TAU, 32, Color(1.0, 0.5, 0.0, pulse * 0.5), 1.5)
			# Shield bar if shielded affix
			if e.get("affixes", {}).get("shielded", false) and e.get("shield_hp", 0) > 0:
				var shield_frac: float = float(e.get("shield_hp", 0)) / (float(e.max_hp) * 0.3)
				draw_arc(sp, e.radius + 3.0, 0.0, TAU * shield_frac, 32, Color(0.3, 0.7, 1.0, 0.8), 2.0)
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
			var label_color: Color = Color(1.0, 0.85, 0.0) if e.get("is_apex", false) else Color(1.0, 0.9, 0.3)
			var prefix: String = "!! " if e.get("is_apex", false) else "* "
			_draw_text(Vector2(sp.x - e.radius - 10.0, sp.y - e.radius - 22.0), prefix + e.type, label_color, 11)
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
			if not _is_on_screen(trap.pos):
				continue
			var tsp: Vector2 = _w2s(trap.pos)
			var decay_left: float = trap.get("decay_timer", 60.0)
			# Radius ring — fades when <10s remaining
			var ring_alpha: float = 0.35 if decay_left > 10.0 else (decay_left / 10.0) * 0.35
			draw_arc(tsp, trap.get("radius", 80.0), 0.0, TAU, 32, Color(1.0, 0.9, 0.1, ring_alpha), 1.5)
			# Center diamond
			var diamond_pts := PackedVector2Array([tsp + Vector2(0, -6), tsp + Vector2(6, 0), tsp + Vector2(0, 6), tsp + Vector2(-6, 0)])
			draw_colored_polygon(diamond_pts, Color(1.0, 0.9, 0.1))
			draw_arc(tsp, 7.0, 0.0, TAU, 8, Color(1.0, 0.6, 0.0), 1.5)
	for dc in decoys:
		if dc.get("timer", 0.0) > 0.0:
			var dsp: Vector2 = _w2s(dc.pos)
			draw_circle(dsp, 12.0, Color(0.2, 0.9, 0.2))
	for tr in turrets:
		var tsp2: Vector2 = _w2s(tr.pos)
		draw_rect(Rect2(tsp2 - Vector2(7, 7), Vector2(14, 14)), Color(0.1, 0.8, 0.9))
	for sz in smoke_zones:
		if not _is_on_screen(sz.pos):
			continue
		var ssp: Vector2 = _w2s(sz.pos)
		var s_pulse: float = 0.15 + 0.05 * sin(hunt_elapsed * 3.0)
		draw_circle(ssp, sz.radius, Color(0.4, 0.5, 0.6, s_pulse))
		draw_arc(ssp, sz.radius, 0.0, TAU, 32, Color(0.5, 0.6, 0.7, 0.4), 1.5)
	for gw in gravity_wells:
		if not _is_on_screen(gw.pos):
			continue
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
		if not _is_on_screen(b.pos):
			continue
		var sp: Vector2 = _w2s(b.pos)
		draw_circle(sp, b.radius, b.color)

	# AOE flashes
	for f in aoe_flashes:
		if not _is_on_screen(f.pos):
			continue
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
	var target_text: String = ""
	if contract_mode == "hunt" or contract_mode == "":
		target_text = "Ingredients: %d/%d" % [mini(target_kills, target_total), target_total]
	else:
		target_text = "Ingredients: %d" % target_kills
	_draw_text(Vector2(vp_size.x * 0.5 - 80.0, 16.0), target_text, Color.WHITE, 14)
	_draw_contract_ui(vp_size)

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
		# Cooldown bar
		if cd > 0.0:
			var max_cd: float = state.get("max_cooldown", 10.0)
			var cd_frac: float = clampf(cd / max_cd, 0.0, 1.0)
			draw_rect(Rect2(btn_pos.x, btn_pos.y + 36.0, 70.0, 4.0), Color(0.2, 0.2, 0.2, 0.6))
			draw_rect(Rect2(btn_pos.x, btn_pos.y + 36.0, 70.0 * cd_frac, 4.0), Color(0.3, 0.8, 0.3, 0.7))

	# Abandon button (bottom-left)
	var ab_w: float = 64.0
	var ab_h: float = 28.0
	abandon_btn_rect = Rect2(4.0, vp_size.y - ab_h - 4.0, ab_w, ab_h)
	draw_rect(abandon_btn_rect, Color(0.5, 0.1, 0.1, 0.8))
	_draw_text(Vector2(8.0, vp_size.y - ab_h + 6.0), "Abandon", Color(1.0, 0.5, 0.5), 11)

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

	# Affix spawn label (top center, briefly)
	if affix_spawn_label_timer > 0.0 and affix_spawn_label_text != "":
		var af_alpha: float = clampf(affix_spawn_label_timer, 0.0, 1.0)
		_draw_text(Vector2(vp_size.x * 0.5 - 60.0, 60.0), "Affixes: " + affix_spawn_label_text, Color(1.0, 0.7, 0.2, af_alpha), 12)

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

	_draw_debug_overlay()

func _draw_contract_ui(vp_size: Vector2) -> void:
	match contract_mode:
		"payload_escort":
			if pod_active:
				# Draw pod as cyan box
				var pod_sp: Vector2 = _w2s(pod_pos)
				draw_rect(Rect2(pod_sp - Vector2(12, 12), Vector2(24, 24)), Color(0.1, 0.9, 0.9))
				# Glow
				draw_arc(pod_sp, 16.0, 0.0, TAU, 16, Color(0.1, 0.9, 0.9, 0.5), 2.0)
				# HP bar above pod
				var bar_w: float = 40.0
				var bar_pos: Vector2 = Vector2(pod_sp.x - bar_w * 0.5, pod_sp.y - 20.0)
				draw_rect(Rect2(bar_pos, Vector2(bar_w, 4.0)), Color(0.3, 0.3, 0.3))
				var hp_frac: float = clampf(float(pod_hp) / float(pod_max_hp), 0.0, 1.0)
				draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_frac, 4.0)), Color(0.1, 0.9, 0.9))
				# Draw target as green circle
				var tgt_sp: Vector2 = _w2s(pod_target)
				var tgt_pulse: float = 0.4 + 0.3 * sin(hunt_elapsed * 3.0)
				draw_arc(tgt_sp, 40.0, 0.0, TAU, 32, Color(0.2, 0.9, 0.2, tgt_pulse), 2.0)
				draw_circle(tgt_sp, 8.0, Color(0.2, 0.9, 0.2, 0.6))
				# Proximity circle around pod (400px)
				draw_arc(pod_sp, 400.0, 0.0, TAU, 64, Color(0.1, 0.9, 0.9, 0.15), 1.0)
				# HUD text
				_draw_text(Vector2(vp_size.x * 0.5 - 60.0, 34.0), "Pod HP: %d/%d" % [pod_hp, pod_max_hp], Color(0.1, 0.9, 0.9), 12)
		"void_breach":
			if rift_active:
				# Draw rift as pulsing purple circle
				var rift_sp: Vector2 = _w2s(rift_pos)
				var rift_pulse: float = 25.0 + 8.0 * sin(hunt_elapsed * 3.5)
				draw_circle(rift_sp, rift_pulse, Color(0.5, 0.0, 0.8, 0.6))
				draw_arc(rift_sp, 30.0, 0.0, TAU, 32, Color(0.7, 0.2, 1.0, 0.8), 2.5)
				# Hold radius
				draw_arc(rift_sp, rift_radius, 0.0, TAU, 64, Color(0.5, 0.0, 0.8, 0.2), 1.5)
				# Compass arrow when rift is off-screen
				var rift_on_screen: bool = (rift_sp.x >= 0.0 and rift_sp.x <= vp_size.x and rift_sp.y >= 0.0 and rift_sp.y <= vp_size.y)
				if not rift_on_screen:
					var rift_screen_center: Vector2 = vp_size * 0.5
					var dir_to_rift: Vector2 = (rift_pos - player_pos).normalized()
					var rift_margin := 28.0
					var rift_arrow_pos: Vector2
					var rift_tx: float = 999999.0
					var rift_ty: float = 999999.0
					if dir_to_rift.x > 0.001:
						rift_tx = (vp_size.x - rift_margin - rift_screen_center.x) / dir_to_rift.x
					elif dir_to_rift.x < -0.001:
						rift_tx = (rift_margin - rift_screen_center.x) / dir_to_rift.x
					if dir_to_rift.y > 0.001:
						rift_ty = (vp_size.y - rift_margin - rift_screen_center.y) / dir_to_rift.y
					elif dir_to_rift.y < -0.001:
						rift_ty = (rift_margin - rift_screen_center.y) / dir_to_rift.y
					var rift_t: float = minf(rift_tx, rift_ty)
					rift_arrow_pos = rift_screen_center + dir_to_rift * rift_t
					var rift_dist: float = player_pos.distance_to(rift_pos)
					var rift_pulse_spd: float = remap(rift_dist, 100.0, 1200.0, 8.0, 2.0)
					var rift_p: float = 0.5 + 0.5 * sin(hunt_elapsed * rift_pulse_spd)
					var rift_arrow_color := Color(0.6, 0.1, 0.9, 0.6 + 0.4 * rift_p)
					var rift_arrow_sz := 14.0
					var rift_fwd: Vector2 = dir_to_rift * rift_arrow_sz
					var rift_perp: Vector2 = Vector2(-dir_to_rift.y, dir_to_rift.x) * (rift_arrow_sz * 0.5)
					var rift_tip: Vector2 = rift_arrow_pos + rift_fwd
					var rift_left: Vector2 = rift_arrow_pos - rift_perp
					var rift_right: Vector2 = rift_arrow_pos + rift_perp
					draw_colored_polygon(PackedVector2Array([rift_tip, rift_left, rift_right]), rift_arrow_color)
					draw_polyline(PackedVector2Array([rift_tip, rift_left, rift_right, rift_tip]), Color(0.7, 0.3, 1.0, 0.9 * rift_p), 1.5)
					var rift_dist_m: int = int(rift_dist / 50.0)
					_draw_text(rift_arrow_pos + Vector2(-12.0, 10.0), "%dm" % rift_dist_m, Color(0.7, 0.3, 1.0, 0.8 * rift_p), 10)
				# HUD: hold timer
				var hold_text: String = "Hold: %.1fs / %.0fs" % [rift_time_held, rift_hold_time]
				_draw_text(Vector2(vp_size.x * 0.5 - 80.0, 34.0), hold_text, Color(0.7, 0.3, 1.0), 12)
				# Outside timer warning
				if rift_time_outside > 0.0:
					var outside_color: Color = Color(1.0, 0.3, 0.3) if rift_time_outside > 6.0 else Color(1.0, 0.8, 0.3)
					var outside_text: String = "Outside: %.1fs / 10s" % rift_time_outside
					_draw_text(Vector2(vp_size.x * 0.5 - 70.0, 50.0), outside_text, outside_color, 12)
		"boss_hunt":
			# Target name
			_draw_text(Vector2(vp_size.x * 0.5 - 80.0, 34.0), "TARGET: " + boss_name, Color(1.0, 0.6, 0.1), 13)
			# Countdown
			var mins: int = int(boss_timer) / 60
			var secs: int = int(boss_timer) % 60
			var time_color: Color = Color(1.0, 0.3, 0.3) if boss_timer < 60.0 else Color(1.0, 0.9, 0.3)
			_draw_text(Vector2(vp_size.x * 0.5 - 40.0, 50.0), "Time: %d:%02d" % [mins, secs], time_color, 12)
		"extraction_run":
			# HUD: cache count
			_draw_text(Vector2(vp_size.x * 0.5 - 50.0, 34.0), "Caches: %d/%d" % [caches_collected, cache_total], Color(1.0, 0.9, 0.2), 13)
			# Draw each cache
			for cache in extraction_caches:
				if cache.collected:
					continue
				var csp: Vector2 = _w2s(cache.pos)
				# Yellow diamond
				var diamond_pts: PackedVector2Array = PackedVector2Array([
					csp + Vector2(0, -10), csp + Vector2(10, 0),
					csp + Vector2(0, 10), csp + Vector2(-10, 0)
				])
				draw_colored_polygon(diamond_pts, Color(1.0, 0.9, 0.2))
				draw_polyline(PackedVector2Array([csp + Vector2(0, -10), csp + Vector2(10, 0), csp + Vector2(0, 10), csp + Vector2(-10, 0), csp + Vector2(0, -10)]), Color(1.0, 1.0, 0.5), 1.5)
				# Channel progress arc
				if cache.channeling:
					var progress: float = clampf(cache.channel_timer / cache_channel_time, 0.0, 1.0)
					draw_arc(csp, 18.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color(0.2, 1.0, 0.2), 3.0)

func _w2s(world_pos: Vector2) -> Vector2:
	return world_pos - camera_offset

func _is_on_screen(world_pos: Vector2) -> bool:
	var sp: Vector2 = world_pos - camera_offset
	var vp_size: Vector2 = get_viewport_rect().size
	return sp.x > -100.0 and sp.x < vp_size.x + 100.0 and sp.y > -100.0 and sp.y < vp_size.y + 100.0

func _add_smoke_zone(zone: Dictionary) -> void:
	if smoke_zones.size() >= 20:
		return
	smoke_zones.append(zone)

func _add_aoe_flash(flash: Dictionary) -> void:
	if aoe_flashes.size() >= 30:
		aoe_flashes.remove_at(0)
	aoe_flashes.append(flash)

func _add_pickup(pickup: Dictionary) -> void:
	if pickups.size() >= 60 and pickup.type == "essence":
		# Drop oldest essence pickup
		for pi in range(pickups.size()):
			if pickups[pi].type == "essence":
				pickups.remove_at(pi)
				break
	if pickups.size() >= 60:
		return
	pickups.append(pickup)

func _draw_text(pos: Vector2, text: String, color: Color, font_size: int = 16) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

# =========================================================
# XP CURVE
# =========================================================
func _xp_needed_for_level(lv: int) -> int:
	# Early: linear 3-kill steps (lv1→2 = 3, lv2→3 = 6, lv3→4 = 9...)
	# Mid: hyperbolic ramp — meaningful upgrades still available
	# Late: plateau — upgrades exhausted, only stat bumps remain; very slow grind
	if lv <= 12:
		return lv * 3              # 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36
	elif lv <= 20:
		# Accelerating curve: starts at ~50, reaches ~140 by lv20
		var t: float = float(lv - 12) / 8.0   # 0.0 → 1.0
		return int(50.0 + 90.0 * t * t)
	else:
		# Plateau: hyperbolic — each level costs significantly more
		# lv21=160, lv25=240, lv30=340, lv40=540 — slow but never stops
		return int(160.0 + float(lv - 20) * 20.0)

# =========================================================
# KIT SYSTEM
# =========================================================
func _init_kit_state(kit_id: String) -> Dictionary:
	match kit_id:
		"stim_pack": return {cooldown = 0.0, max_cooldown = 8.0}
		"flash_trap": return {cooldown = 0.0, charges = 3, max_charges = 3, recharge_timer = 0.0}
		"blink_kit": return {cooldown = 0.0, max_cooldown = 10.0}
		"chain_kit": return {cooldown = 0.0, max_cooldown = 12.0}
		"charge_kit": return {cooldown = 0.0, max_cooldown = 12.0, charging = false}
		"mirage_kit": return {cooldown = 0.0, max_cooldown = 18.0}
		"turret_kit": return {charges = 1, max_charges = 2, recharge_timer = 0.0}
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

	debug_log_push("Kit: %s" % kit_id)
	var tier: int = kit_tiers.get(kit_id, 1)
	var t3_choice: String = kit_t3_choices.get(kit_id, "")
	var resonance: Dictionary = weapon_mods.get("_resonance", {})

	match kit_id:
		"stim_pack":
			var heal: int = 4 if tier < 2 else 5
			player_hp = mini(player_hp + heal, player_max_hp)
			corruption += 15.0
			var stim_cd: float = 8.0 if tier < 2 else 5.0
			_show_message("Stim! +%dHP +15 corruption" % heal)
			state.cooldown = stim_cd
			# T3 clean: speed boost
			if tier >= 3 and t3_choice == "clean":
				stim_speed_timer = 5.0
		"flash_trap":
			if charges > 0:
				# Max 3 active at once — remove oldest if at cap
				var active_count: int = 0
				for tr in traps:
					if tr.get("active", true): active_count += 1
				if active_count >= 3:
					for tridx in range(traps.size()):
						if traps[tridx].get("active", true):
							traps.remove_at(tridx)
							break
				traps.append({pos = player_pos, radius = 80.0, active = true, decay_timer = 60.0})
				state.charges = charges - 1
				state.recharge_timer = 0.0
				_show_message("Trap placed! [%d charges]" % (charges - 1))
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
				_add_aoe_flash({pos=old_pos, radius=100.0, timer=0.3, color=Color(0.8,0.8,1.0,0.5)})
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
				_add_smoke_zone({pos=player_pos, radius=150.0, timer=6.0})
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
					_add_aoe_flash({pos=player_pos, radius=30.0, timer=0.3, color=Color(0.6,0.0,0.9,0.6)})
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
					_add_aoe_flash({pos = player_pos, radius = 150.0, timer = 0.3, color = Color(1.0, 0.8, 0.2, 0.6)})
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
			_add_smoke_zone(new_smoke)
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
			_add_aoe_flash({pos = player_pos, radius = 200.0, timer = 0.3, color = Color(0.6, 0.0, 0.9, 0.7)})
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

	# Recharge charges over time
	if kit_states.has("flash_trap"):
		var fs: Dictionary = kit_states["flash_trap"]
		var max_ch: int = fs.get("max_charges", 3)
		if fs.get("charges", 0) < max_ch:
			fs["recharge_timer"] = fs.get("recharge_timer", 0.0) + delta
			if fs["recharge_timer"] >= 25.0:
				fs["recharge_timer"] = 0.0
				fs["charges"] = fs.get("charges", 0) + 1
		kit_states["flash_trap"] = fs

	var triggered_indices: Array = []
	var i := traps.size() - 1
	while i >= 0:
		var trap: Dictionary = traps[i]
		# Decay timer
		if trap.has("decay_timer"):
			trap["decay_timer"] = trap["decay_timer"] - delta
			if trap["decay_timer"] <= 0.0:
				traps.remove_at(i)
				i -= 1
				continue
			traps[i] = trap
		if not trap.get("active", true):
			traps.remove_at(i)
			i -= 1
			continue
		for ei in range(enemies.size()):
			var e: Dictionary = enemies[ei]
			if e.hp <= 0:
				continue
			if e.pos.distance_to(trap.pos) < trap.get("radius", 80.0):
				e.stunned_timer = 2.0
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
				trap.active = false
				traps[i] = trap
				_add_aoe_flash({pos = trap.pos, radius = 80.0, timer = 0.3, color = Color(1.0, 0.9, 0.1, 0.5)})
				triggered_indices.append(i)
				break
		i -= 1
	# T2: chain trigger — if 2 traps within 300px, triggering one triggers both
	if flash_tier >= 2 and triggered_indices.size() > 0:
		for ti in triggered_indices:
			if ti >= traps.size():
				continue
			var t_pos: Vector2 = traps[ti].pos
			for tj in range(traps.size()):
				if tj == ti:
					continue
				if traps[tj].get("active", true) and t_pos.distance_to(traps[tj].pos) < 300.0:
					traps[tj].active = false
					_add_aoe_flash({pos=traps[tj].pos, radius=80.0, timer=0.3, color=Color(1.0,0.9,0.1,0.5)})
					for ei in range(enemies.size()):
						var e: Dictionary = enemies[ei]
						if e.hp > 0 and e.pos.distance_to(traps[tj].pos) < 80.0:
							e.stunned_timer = 2.0
							enemies[ei] = e

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
				_add_aoe_flash({pos=dpos, radius=40.0, timer=0.3, color=Color(1.0,0.6,0.2,0.6)})
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
	# Turret charge recharge
	if kit_states.has("turret_kit"):
		var ts: Dictionary = kit_states["turret_kit"]
		var max_ch: int = ts.get("max_charges", 2)
		var cur_ch: int = ts.get("charges", 0)
		if cur_ch < max_ch:
			ts["recharge_timer"] = ts.get("recharge_timer", 0.0) + delta
			if ts.recharge_timer >= 30.0:
				ts["charges"] = cur_ch + 1
				ts["recharge_timer"] = 0.0
				_show_message("Turret recharged!")
			kit_states["turret_kit"] = ts
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
				var turret_bullet: Dictionary = {
					pos = tr.pos,
					vel = (e.pos - tr.pos).normalized() * 500.0,
					damage = 1,
					radius = 4.0,
					color = Color(1.0, 0.8, 0.0),
					pierce = false,
					weapon_id = "turret_kit",
					lifetime = 0.8,
					from_player = true,
					source = "turret",
				}
				if turret_tier >= 2:
					turret_bullet.damage = 2
				if tr.get("void_rounds", false):
					turret_bullet["explode"] = true
				bullets.append(turret_bullet)
		turrets[i] = tr
		i -= 1

func _update_affix_trails(delta: float) -> void:
	# Process venomous trails and corruption zones from smoke_zones
	for ei in range(enemies.size()):
		var e: Dictionary = enemies[ei]
		if e.hp <= 0 or not e.get("is_elite", false):
			continue
		var afxs: Dictionary = e.get("affixes", {})
		# Venomous: decay trail, check player overlap
		if afxs.get("venomous", false):
			var vt: Array = e.get("venom_trail", [])
			var new_vt: Array = []
			for trail in vt:
				trail.timer -= delta
				if trail.timer > 0.0:
					new_vt.append(trail)
					if player_pos.distance_to(trail.pos) < 20.0:
						corruption += 2.0 * delta
			e["venom_trail"] = new_vt
			enemies[ei] = e
	# Corruption zones in smoke_zones
	for sz in smoke_zones:
		if sz.get("corruption_zone", false) and sz.timer > 0.0:
			if player_pos.distance_to(sz.pos) < sz.radius:
				corruption += sz.get("corruption_rate", 10.0) * delta

func _update_smoke(delta: float) -> void:
	var smoke_tier: int = kit_tiers.get("smoke_kit", 1)
	var smoke_t3: String = kit_t3_choices.get("smoke_kit", "")
	smoke_interact_timer -= delta
	var run_interactions: bool = smoke_interact_timer <= 0.0
	if run_interactions:
		smoke_interact_timer = 0.5
	var i := smoke_zones.size() - 1
	while i >= 0:
		smoke_zones[i].timer -= delta
		if smoke_zones[i].timer <= 0.0:
			smoke_zones.remove_at(i)
		else:
			if run_interactions:
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
					var grenade_mods: Dictionary = weapon_mods.get("grenade_launcher", {})
					var pull_active: bool = grenade_mods.get("corr_zone_pull", false)
					var zone_dmg_active: bool = grenade_mods.get("corr_zone_damage", false)
					for ei in range(enemies.size()):
						var e: Dictionary = enemies[ei]
						if e.hp <= 0 or e.get("is_ally", false):
							continue
						var dist_sz: float = e.pos.distance_to(sz.pos)
						if dist_sz < sz.radius:
							# Base toxic damage
							var tdmg: int = 2 if zone_dmg_active else 1
							e.hp -= maxi(tdmg, int(float(tdmg) * delta + 0.5))
							# Void pull: drag enemies toward zone center
							if pull_active and dist_sz > 4.0:
								var pull_dir: Vector2 = (sz.pos - e.pos).normalized()
								e.pos += pull_dir * 60.0 * delta
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
				_add_aoe_flash({pos=gw_end.pos, radius=gw_end.radius * 0.5, timer=0.3, color=Color(0.6,0.0,0.9,0.7)})
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

	# Drone basic attack — fires at nearest enemy every 2.5s (T1), enhanced at T2+ attack path
	drone_fire_timer -= delta
	var drone_fire_interval: float = 2.5
	if drone_tier >= 2 and drone_path == "attack":
		drone_fire_interval = 2.0
	if overcharge_timer > 0.0:
		drone_fire_interval *= 0.5
	if drone_fire_timer <= 0.0:
		drone_fire_timer = drone_fire_interval
		var drone_attack_range: float = 200.0
		if drone_tier >= 2 and drone_path == "attack":
			drone_attack_range = 300.0
		var best_dist: float = drone_attack_range
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
			_add_aoe_flash({pos=drone_pos, radius=8.0, timer=0.1, color=Color(0.3,0.9,1.0,0.8)})
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
	familiar_pos = player_pos + Vector2(cos(orbit_angle), sin(orbit_angle)) * 55.0
	# T3 void: at corruption >= 60, familiar splits into 2
	if fam_tier >= 3 and fam_t3 == "void" and corruption >= 60.0 and not familiar2_active:
		familiar2_active = true
	if familiar2_active:
		var orbit2: float = fmod(hunt_elapsed * 1.5 + PI + PI, TAU)
		familiar2_pos = player_pos + Vector2(cos(orbit2), sin(orbit2)) * 55.0
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
		var positions: Array = [familiar_pos]
		if familiar2_active:
			positions.append(familiar2_pos)
		for fpos in positions:
			var best_dist: float = 150.0
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
		"flamethrower":
			if mtype == "clean":
				mods["cryo_flamer"] = true
			elif mtype == "void":
				mods["corruption_spray"] = true
		"grenade_launcher":
			if mtype == "clean":
				mods["airburst"] = true
			elif mtype == "void":
				mods["void_grenade"] = true
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
		# Flamethrower clean
		"cryo_range": mods["range_bonus_flat"] = mods.get("range_bonus_flat", 0.0) + 40.0
		"deep_freeze": mods["cryo_stun_duration"] = 3.0
		"shatter": mods["shatter"] = true
		"cryo_aura": mods["cryo_aura"] = true
		# Flamethrower void
		"corr_efficiency": mods["corr_cost_mult"] = 0.6
		"void_flames": mods["flame_pierce"] = true
		"corruption_burst": mods["corruption_burst"] = true
		"siphon": mods["flame_siphon"] = true
		# Grenade launcher clean
		"wide_burst": mods["aoe_radius_bonus"] = mods.get("aoe_radius_bonus", 0.0) + 30.0
		"carpet_bomb": mods["carpet_bomb"] = true
		"concussion": mods["concussion_stun"] = true
		"barrage": mods["fire_rate_add"] = mods.get("fire_rate_add", 0.0) - 0.625
		# Grenade launcher void
		"corr_zone_expand": mods["corr_zone_radius_bonus"] = 40.0
		"zone_damage": mods["corr_zone_damage"] = true
		"void_pull": mods["corr_zone_pull"] = true
		"cascade_void": mods["cascade_void"] = true
	weapon_mods[wid] = mods
	_show_message("Mastery: " + perk_id.replace("_", " ").capitalize())

# =========================================================
# DEBUG OVERLAY
# =========================================================

func debug_log_push(msg: String) -> void:
	if not DEBUG_OVERLAY_ENABLED:
		return
	var mins: int = int(hunt_elapsed) / 60
	var secs: int = int(hunt_elapsed) % 60
	debug_log.append("[%d:%02d] %s" % [mins, secs, msg])
	if debug_log.size() > DEBUG_LOG_MAX:
		debug_log.pop_front()
	# Persist to localStorage so crash/freeze doesn't lose the log
	if OS.get_name() == "Web":
		var joined: String = "\n".join(debug_log)
		JavaScriptBridge.eval("try{localStorage.setItem('sh_debug_log',%s)}catch(e){}" % JSON.stringify(joined))

func _debug_write_snap() -> void:
	if not DEBUG_OVERLAY_ENABLED or OS.get_name() != "Web":
		return
	var mins: int = int(hunt_elapsed) / 60
	var secs: int = int(hunt_elapsed) % 60
	var active_elites: Array = []
	for e in enemies:
		if e.get("is_elite", false):
			active_elites.append(e.get("elite_type", "?") + str(e.get("affixes", [])))
	var snap: String = "[%d:%02d] FPS:%d E:%d B:%d corr:%.0f%% HP:%d/%d wave:%d kills:%d/%d elites:%s" % [
		mins, secs,
		Engine.get_frames_per_second(),
		enemies.size(), bullets.size(),
		corruption, player_hp, player_max_hp,
		wave_current, target_kills, target_total,
		"|".join(active_elites) if active_elites.size() > 0 else "none"
	]
	JavaScriptBridge.eval("try{localStorage.setItem('sh_debug_snap',%s)}catch(e){}" % JSON.stringify(snap))

func _draw_debug_overlay() -> void:
	if not DEBUG_OVERLAY_ENABLED:
		return

	var vp_size := get_viewport_rect().size

	# --- DBG toggle button (always visible when overlay enabled) ---
	var btn_w: float = 44.0
	var btn_h: float = 24.0
	var btn_x: float = vp_size.x - btn_w - 4.0
	var btn_y: float = 4.0
	debug_btn_rect = Rect2(btn_x, btn_y, btn_w, btn_h)
	var btn_bg: Color = Color(0.2, 0.7, 0.2, 0.85) if debug_overlay_visible else Color(0.15, 0.15, 0.15, 0.75)
	draw_rect(debug_btn_rect, btn_bg)
	draw_string(ThemeDB.fallback_font, Vector2(btn_x + 6.0, btn_y + btn_h - 6.0), "DBG",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	if not debug_overlay_visible:
		return
	var font: Font = ThemeDB.fallback_font
	var pad: float = 8.0
	var line_h: float = 14.0
	var fs: int = 11

	# --- HUD panel (top-right) ---
	var active_elites: Array = []
	for e in enemies:
		if e.get("is_elite", false):
			var ename: String = e.get("elite_type", "?")
			var affixes: Array = e.get("affixes", [])
			active_elites.append(ename + (" [" + ",".join(affixes) + "]" if affixes.size() > 0 else ""))

	var apex_str: String = ""
	if apex_active:
		apex_str = "  APEX ACTIVE"

	var lines: Array = [
		"--- DEBUG (F1 toggle) ---",
		"FPS: %d | T: %d:%02d" % [Engine.get_frames_per_second(), int(hunt_elapsed) / 60, int(hunt_elapsed) % 60],
		"Enemies: %d | Bullets: %d | Pickups: %d" % [enemies.size(), bullets.size(), pickups.size() + ingredient_pickups.size()],
		"AOEflashes: %d/30 | Smoke: %d/20" % [aoe_flashes.size(), smoke_zones.size()],
		"VoidPools: %d | Turrets: %d | Traps: %d" % [void_pools.size(), turrets.size(), traps.size()],
		"Player: (%d,%d) | HP: %d/%d" % [int(player_pos.x), int(player_pos.y), player_hp, player_max_hp],
		"Corruption: %.1f%% | Biome: %s" % [corruption, _get_biome_at(player_pos)],
		"Weapon: %s Lv%d | Ammo: %d/%d" % [WEAPON_DEFS.get(main_weapon.get("id","?"), {}).get("name","?"), main_weapon.get("level",1), main_weapon.get("mag_ammo",0), main_weapon.get("mag_size",0)],
		"Wave: %d | Kills: %d/%d | XP: %d/%d" % [wave_current, target_kills, target_total, essence_collected, xp_threshold],
		"Elites: %d spawned | %s%s" % [elite_spawned_count, (", ".join(active_elites) if active_elites.size() > 0 else "none active"), apex_str],
	]

	# Background rect
	var panel_w: float = 320.0
	var panel_h: float = float(lines.size()) * line_h + pad * 2.0
	var panel_x: float = vp_size.x - panel_w - pad
	var panel_y: float = 36.0  # below DBG button
	draw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0, 0, 0, 0.72))

	for i in range(lines.size()):
		var col: Color = Color(0.4, 1.0, 0.4) if i == 0 else Color(0.9, 0.9, 0.9)
		draw_string(font, Vector2(panel_x + pad, panel_y + pad + float(i) * line_h + line_h), lines[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	# --- Event log (bottom-left) ---
	if debug_log.size() > 0:
		var log_x: float = pad
		var log_y: float = vp_size.y - float(debug_log.size()) * line_h - pad * 2.0
		var log_w: float = 360.0
		var log_h: float = float(debug_log.size()) * line_h + pad * 2.0
		draw_rect(Rect2(log_x, log_y, log_w, log_h), Color(0, 0, 0, 0.65))
		for i in range(debug_log.size()):
			var alpha: float = 0.5 + 0.5 * (float(i + 1) / float(debug_log.size()))
			draw_string(font, Vector2(log_x + pad, log_y + pad + float(i) * line_h + line_h),
				debug_log[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.85, 0.4, alpha))

	# --- Crash log (bottom-right, red) — shown only if previous session data exists ---
	if crash_log != "" or crash_snap != "":
		var crash_lines: Array = ["== LAST CRASH =="]
		if crash_snap != "":
			crash_lines.append(crash_snap)
		if crash_log != "":
			for l in crash_log.split("\n"):
				if l.strip_edges() != "":
					crash_lines.append(l)
		var cl_w: float = 360.0
		var cl_h: float = float(crash_lines.size()) * line_h + pad * 2.0
		var cl_x: float = vp_size.x - cl_w - pad
		var cl_y: float = vp_size.y - cl_h - pad
		draw_rect(Rect2(cl_x, cl_y, cl_w, cl_h), Color(0.3, 0.0, 0.0, 0.8))
		for i in range(crash_lines.size()):
			var col: Color = Color(1.0, 0.3, 0.3) if i == 0 else Color(1.0, 0.7, 0.7, 0.85)
			draw_string(font, Vector2(cl_x + pad, cl_y + pad + float(i) * line_h + line_h),
				crash_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
