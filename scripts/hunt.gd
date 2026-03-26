extends Control

# === World ===
const WORLD_W := 1600
const WORLD_H := 1600
const GRID_STEP := 200

# === Weapon definitions ===
const WEAPON_DEFS: Dictionary = {
	"sidearm": {name="Sidearm", desc="Reliable auto-pistol.", fire_rate=0.35, damage=3, bullet_speed=400.0, bullet_radius=5.0, color=Color(1.0,0.9,0.2), range=350.0, pattern="single"},
	"scatter": {name="Scatter Pistol", desc="3-pellet cone. Shreds packs.", fire_rate=0.7, damage=2, bullet_speed=380.0, bullet_radius=4.0, color=Color(1.0,0.5,0.1), range=220.0, pattern="scatter"},
	"lance": {name="Void Lance", desc="Slow piercing shot. Hits all in line.", fire_rate=1.2, damage=6, bullet_speed=280.0, bullet_radius=7.0, color=Color(0.5,0.1,1.0), range=500.0, pattern="piercing"},
	"baton": {name="Shock Baton", desc="Melee AOE pulse. Damages all within 100px.", fire_rate=0.8, damage=4, bullet_speed=0.0, bullet_radius=100.0, color=Color(0.1,0.8,1.0), range=100.0, pattern="melee_aoe"},
	"dart": {name="Homing Dart", desc="Slow seeking projectile.", fire_rate=0.9, damage=3, bullet_speed=200.0, bullet_radius=5.0, color=Color(0.2,1.0,0.5), range=400.0, pattern="homing"}
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
}

# Passive pool — drawn randomly, no repeats per run
const ALL_PASSIVES: Array = [
	{id="tough",       rarity="common", icon="🛡", name="Reinforced Suit",   desc="+3 max HP, heal to full"},
	{id="speed",       rarity="common", icon="💨", name="Thruster Boost",    desc="+25 move speed"},
	{id="xp",          rarity="common", icon="✨", name="Void Attunement",   desc="Essence pickup range +40px"},
	{id="tough2",      rarity="common", icon="❤", name="Adrenaline Gland",  desc="+2 max HP"},
	{id="reload",      rarity="common", icon="🔄", name="Speed Loader",      desc="Reload time -30%"},
	{id="magplus",     rarity="common", icon="📦", name="Extended Mag",      desc="+4 ammo in all weapons"},
	{id="dodge",       rarity="rare",   icon="👻", name="Phase Shift",       desc="10% chance to dodge a hit"},
	{id="burst_move",  rarity="rare",   icon="⚡", name="Sprint Capacitor",  desc="Killing 3 enemies: +50% speed for 3s"},
	{id="vamp",        rarity="rare",   icon="🩸", name="Blood Harvest",     desc="1 in 5 kills restores 1 HP"},
	{id="elite_dmg",   rarity="rare",   icon="⚔", name="Hunter's Mark",     desc="+30% damage vs elites"},
	{id="corruption_resist", rarity="rare", icon="🌑", name="Void Skin",    desc="Corruption gain -25%"},
]
var passives_taken: Array[String] = []  # ids of passives already picked this run

# Runtime weapon modifiers (applied to WEAPON_DEFS at fire time)
var weapon_mods: Dictionary = {}  # weapon_id -> {fire_rate_mult, damage_bonus, extra_pellets, piercing, slow, etc.}

# === Player ===
var player_pos := Vector2(800.0, 800.0)
var player_hp := 10
var player_max_hp := 10
var player_speed := 180.0
const PLAYER_RADIUS := 16.0

# === Weapons ===
var active_weapons: Array[Dictionary] = []
# Each entry: {id: String, level: int, cooldown_timer: float, mag_ammo: int, mag_size: int, reload_timer: float}
var weapon_slots: int = 3

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

# === Game state ===
var paused := false
var dead := false
var dead_timer := 0.0
var hunt_complete := false

# === HUD message ===
var hud_message := ""
var hud_message_timer := 0.0

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
}

const CREATURE_INGREDIENTS: Dictionary = {
	"Void Leech": {id = "ingredient_void_extract", name = "Void Extract", symbol = "V", uses = 1, ingredient = true},
	"Shadow Crawler": {id = "ingredient_shadow_membrane", name = "Shadow Membrane", symbol = "S", uses = 1, ingredient = true},
	"Abyss Worm": {id = "ingredient_abyss_flesh", name = "Abyss Flesh", symbol = "A", uses = 1, ingredient = true},
	"Nether Stalker": {id = "ingredient_nether_bile", name = "Nether Bile", symbol = "N", uses = 1, ingredient = true},
	"Rift Parasite": {id = "ingredient_rift_spore", name = "Rift Spore", symbol = "R", uses = 1, ingredient = true},
}

const INGREDIENT_COLORS: Dictionary = {
	"ingredient_void_extract": Color(0.8, 0.2, 0.2),
	"ingredient_shadow_membrane": Color(0.5, 0.1, 0.7),
	"ingredient_abyss_flesh": Color(0.3, 0.6, 0.1),
	"ingredient_nether_bile": Color(0.2, 0.4, 0.9),
	"ingredient_rift_spore": Color(0.9, 0.5, 0.1),
}

const PRISTINE_NAMES: Dictionary = {
	"void_extract": "Void Extract (Pure)",
	"shadow_membrane": "Shadow Membrane (Intact)",
	"abyss_flesh": "Abyss Flesh (Raw)",
	"nether_bile": "Nether Bile (Distilled)",
	"rift_spore": "Rift Spore",
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
	var start_wep: String = GameData.starting_weapon
	if start_wep.is_empty() or not WEAPON_DEFS.has(start_wep):
		start_wep = "sidearm"
	var is_baton: bool = start_wep == "baton"
	var base_mag: int = 999 if is_baton else 12
	active_weapons = [{id=start_wep, level=1, cooldown_timer=0.0, mag_ammo=base_mag + mag_bonus, mag_size=base_mag + mag_bonus, reload_timer=0.0}]

	# Elite interval: first elite at 3-5 min (shorter at higher depth)
	elite_interval = randf_range(180.0 - depth * 30.0, 300.0 - depth * 30.0)
	elite_timer = elite_interval
	wave_timer = WAVE_INTERVAL_START

	_spawn_obstacles()
	_spawn_wave(depth)

	set_process_input(true)
	queue_redraw()

# =========================================================
# SPAWN
# =========================================================
func _spawn_obstacles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(40):
		var r: float = rng.randf_range(20.0, 50.0)
		var pos := Vector2.ZERO
		for _try in range(20):
			pos = Vector2(rng.randf_range(r, WORLD_W - r), rng.randf_range(r, WORLD_H - r))
			# avoid center 400x400
			if abs(pos.x - 800.0) > 200.0 or abs(pos.y - 800.0) > 200.0:
				break
		obstacles.append({pos = pos, radius = r})

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
		elite_timer = elite_interval * 0.7  # subsequent elites come faster
		var depth: int = GameData.current_contract.get("depth", 1)
		_spawn_elite(depth)

func _spawn_wave(depth: int) -> void:
	wave_current += 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var types_list: Array = CREATURE_DEFS.keys()

	if wave_current > 1:
		_show_message("Wave %d" % wave_current)

	# Filler only — no targets in waves. Ramps: +2 per wave, capped at wave 10.
	var effective_wave: int = min(wave_current, 10)
	var base_fillers: int = 6 + depth * 3
	var filler_count: int = base_fillers + (effective_wave - 1) * 2 + rng.randi_range(0, 2)
	var spawn_start: int = enemies.size()
	for i in range(filler_count):
		var ft: String = types_list[rng.randi_range(0, types_list.size() - 1)]
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

	# Find a spawn point far from player
	var pos := Vector2.ZERO
	for _try in range(40):
		pos = Vector2(rng.randf_range(80.0, WORLD_W - 80.0), rng.randf_range(80.0, WORLD_H - 80.0))
		if pos.distance_to(player_pos) >= 350.0:
			var blocked := false
			for obs in obstacles:
				if pos.distance_to(obs.pos) < obs.radius + 30.0:
					blocked = true
					break
			if not blocked:
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

	_move_player(delta)
	_update_camera()
	_update_weapons(delta)
	_update_enemies(delta)
	_update_bullets(delta)
	_check_pickups()
	_update_hud_message(delta)
	_apply_corruption_effects()
	_update_aoe_flashes(delta)
	_update_waves(delta)

	queue_redraw()

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

	var velocity: Vector2 = move_dir * player_speed * delta
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
	# Find nearest living enemy once for all weapons
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

	for wi in range(active_weapons.size()):
		var w: Dictionary = active_weapons[wi]
		var def: Dictionary = WEAPON_DEFS[w.id]
		var mods_w: Dictionary = weapon_mods.get(w.id, {})
		var damage: int = def.damage + (w.level - 1) + mods_w.get("damage_bonus", 0)
		var w_piercing: bool = mods_w.get("piercing", def.pattern == "piercing")
		var w_fire_rate: float = maxf(0.1, def.fire_rate + mods_w.get("fire_rate_add", 0.0))
		var w_bullet_speed: float = def.bullet_speed + mods_w.get("bullet_speed_bonus", 0.0)
		var w_extra_pellets: int = mods_w.get("extra_pellets", 0)

		# Handle reload
		if w.reload_timer > 0.0:
			w.reload_timer -= delta
			if w.reload_timer <= 0.0:
				w.mag_ammo = w.mag_size
				if wi == 0:
					_show_message("Reloaded!")
			active_weapons[wi] = w
			continue

		# Handle cooldown
		if w.cooldown_timer > 0.0:
			w.cooldown_timer -= delta

		# Out of ammo — start reload
		if w.mag_ammo <= 0 and w.reload_timer <= 0.0:
			w.reload_timer = 1.5
			if wi == 0:
				_show_message("Reloading...")
			active_weapons[wi] = w
			continue

		# Fire if ready
		if w.cooldown_timer <= 0.0 and w.mag_ammo > 0:
			if not nearest_found or nearest_dist > def.range:
				active_weapons[wi] = w
				continue

			var dir: Vector2 = (nearest_pos - player_pos).normalized()
			w.cooldown_timer = w_fire_rate

			match def.pattern:
				"single":
					w.mag_ammo -= 1
					bullets.append({
						pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
						vel = dir * w_bullet_speed,
						radius = def.bullet_radius,
						color = def.color,
						damage = damage,
						lifetime = def.range / maxf(1.0, w_bullet_speed),
						from_player = true,
						piercing = w_piercing,
						hit_ids = [] if w_piercing else [],
					})
				"scatter":
					w.mag_ammo -= 1
					var base_angle: float = dir.angle()
					var pellet_angles: Array = [-15.0, 0.0, 15.0]
					for _ep in range(w_extra_pellets):
						pellet_angles.append(randf_range(-25.0, 25.0))
					for offset_deg in pellet_angles:
						var angle: float = base_angle + deg_to_rad(float(offset_deg))
						var scatter_dir := Vector2(cos(angle), sin(angle))
						bullets.append({
							pos = player_pos + scatter_dir * (PLAYER_RADIUS + 6.0),
							vel = scatter_dir * w_bullet_speed,
							radius = def.bullet_radius,
							color = def.color,
							damage = damage,
							lifetime = def.range / maxf(1.0, w_bullet_speed),
							from_player = true,
						})
				"piercing":
					w.mag_ammo -= 1
					bullets.append({
						pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
						vel = dir * w_bullet_speed,
						radius = def.bullet_radius,
						color = def.color,
						damage = damage,
						lifetime = def.range / maxf(1.0, w_bullet_speed),
						from_player = true,
						piercing = true,
						hit_ids = [],
					})
				"homing":
					w.mag_ammo -= 1
					bullets.append({
						pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
						vel = dir * def.bullet_speed,
						radius = def.bullet_radius,
						color = def.color,
						damage = damage,
						lifetime = def.range / def.bullet_speed,
						from_player = true,
						homing = true,
						bullet_speed = def.bullet_speed,
					})
				"melee_aoe":
					# No bullet — instant AOE damage
					for ei in range(enemies.size()):
						var e: Dictionary = enemies[ei]
						if e.hp <= 0:
							continue
						if player_pos.distance_to(e.pos) < def.range:
							e.hp -= damage
							enemies[ei] = e
							if e.hp <= 0:
								_on_enemy_killed(ei)
					aoe_flashes.append({pos=player_pos, radius=100.0, timer=0.3, color=Color(0.1,0.8,1.0,0.6)})

		active_weapons[wi] = w

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

		var dist_to_player: float = e.pos.distance_to(player_pos)

		# Aggro check
		if not e.is_aggroed:
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

			match e.behavior:
				"charge":
					# Dumb straight-line rush
					if dist_to_player > e.radius + PLAYER_RADIUS:
						move_dir = (player_pos - e.pos).normalized()

				"flank":
					# Circle to the side, then close in
					e.flank_timer -= delta
					if e.flank_timer <= 0.0:
						e.flank_side *= -1.0
						e.flank_timer = randf_range(1.0, 2.5)
					var to_player: Vector2 = (player_pos - e.pos).normalized()
					var perp: Vector2 = Vector2(-to_player.y, to_player.x) * e.flank_side
					if dist_to_player > 80.0:
						move_dir = (to_player + perp * 0.7).normalized()
					else:
						move_dir = to_player  # close enough, just hit

				"burst":
					# Slow stalk, then sudden lunge
					e.burst_timer -= delta
					if e.burst_active:
						move_dir = (player_pos - e.pos).normalized()
						if e.burst_timer <= 0.0:
							e.burst_active = false
							e.burst_timer = randf_range(1.5, 3.0)
					else:
						# Slow stalk toward player
						if dist_to_player > e.radius + PLAYER_RADIUS:
							move_dir = (player_pos - e.pos).normalized() * 0.35
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
					if dist_to_player > e.radius + PLAYER_RADIUS:
						move_dir = (player_pos - e.pos).normalized()
					# Apply pack speed directly here
					if move_dir != Vector2.ZERO:
						var new_pos: Vector2 = e.pos + move_dir.normalized() * e.speed * pack_mult * delta
						new_pos = _avoid_obstacles(e.pos, new_pos, e.radius)
						e.pos = new_pos
					move_dir = Vector2.ZERO  # handled above

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
				var new_pos: Vector2 = e.pos + move_dir.normalized() * spd * delta
				new_pos = _avoid_obstacles(e.pos, new_pos, e.radius)
				e.pos = new_pos

			# Melee
			if e.melee_dmg > 0 and dist_to_player < e.radius + PLAYER_RADIUS + 2.0:
				var cd_key: int = i
				var cd: float = enemy_melee_cooldowns.get(cd_key, 0.0)
				if cd <= 0.0:
					player_hp -= e.melee_dmg
					enemy_melee_cooldowns[cd_key] = 1.0
					_show_message("Hit! -%d HP" % e.melee_dmg)
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

	# Void creature proximity corruption aura
	for e in enemies:
		if e.hp <= 0 or not e.void_type:
			continue
		if player_pos.distance_to(e.pos) < 160.0:
			corruption += 2.0 * delta

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
				var new_dir: Vector2 = b.vel.normalized().lerp((best_pos - b.pos).normalized(), 3.0 * delta)
				b.vel = new_dir.normalized() * b.bullet_speed

		b.pos += b.vel * delta
		b.lifetime -= delta

		if b.lifetime <= 0.0:
			to_remove.append(i)
			bullets[i] = b
			continue

		# Out of world
		if b.pos.x < 0.0 or b.pos.x > WORLD_W or b.pos.y < 0.0 or b.pos.y > WORLD_H:
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
			to_remove.append(i)
			bullets[i] = b
			continue

		if b.from_player:
			# Hit enemies
			var is_piercing: bool = b.get("piercing", false)
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp <= 0:
					continue
				if b.pos.distance_to(e.pos) < e.radius + b.radius:
					if is_piercing:
						var hit_ids: Array = b.hit_ids
						if not hit_ids.has(ei):
							hit_ids.append(ei)
							b.hit_ids = hit_ids
							e.hp -= b.damage
							enemies[ei] = e
							if e.hp <= 0:
								_on_enemy_killed(ei)
					else:
						e.hp -= b.damage
						enemies[ei] = e
						to_remove.append(i)
						if e.hp <= 0:
							_on_enemy_killed(ei)
						break
		else:
			# Hit player
			if b.pos.distance_to(player_pos) < PLAYER_RADIUS + b.radius:
				player_hp -= b.damage
				to_remove.append(i)
				_show_message("Shot! -%d HP" % b.damage)
				if player_hp <= 0:
					_die()
					return

		bullets[i] = b

	# Remove in reverse order
	to_remove.sort()
	for idx in range(to_remove.size() - 1, -1, -1):
		bullets.remove_at(to_remove[idx])

func _on_enemy_killed(idx: int) -> void:
	var e: Dictionary = enemies[idx]
	var death_pos: Vector2 = e.pos

	# Elites: drop ingredient guaranteed + big essence burst
	if e.get("is_elite", false):
		_show_message("Elite down! Ingredient dropped!")
		# Drop a big essence burst
		for _b in range(5):
			pickups.append({pos = death_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), type = "essence"})
		# Drop ingredient based on elite type
		var elite_ingredient_map := {
			"Void Hulk": "void_extract",
			"Phase Hunter": "nether_bile",
			"Brood Mother": "rift_spore",
		}
		var ing_id: String = elite_ingredient_map.get(e.elite_type, "void_extract")
		var ing_color: Color = INGREDIENT_COLORS.get("ingredient_" + ing_id, Color.GOLD)
		ingredient_pickups.append({
			pos = death_pos,
			data = {
				id = "ingredient_" + ing_id + "_pristine",
				name = ing_id.replace("_", " ").capitalize() + " (Pure)",
				is_pristine = true,
				ingredient = true,
				uses = 1,
			},
			collected = false,
			pulse_phase = 0.0,
			color = ing_color,
		})
		# Track contract progress
		target_kills += 1
		_show_message("Ingredients: %d/%d" % [target_kills, target_total])
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
				if essence_collected >= 20:
					essence_collected -= 20
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
	player_level += 1
	paused = true
	_show_message("Level Up!")

	upgrade_choices = _generate_upgrades()

	# Create upgrade panel using call_deferred
	call_deferred("_create_upgrade_panel")

func _generate_upgrades() -> Array:
	var options: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# --- Weapon upgrades: offer named perk for each held weapon ---
	var upgradeable: Array[Dictionary] = []
	for w in active_weapons:
		if w.level < 5:
			upgradeable.append(w)
	upgradeable.shuffle()
	for w in upgradeable.slice(0, 2):
		var next_level: int = w.level + 1
		if WEAPON_LEVEL_PERKS.has(w.id) and WEAPON_LEVEL_PERKS[w.id].has(next_level):
			var perk: Dictionary = WEAPON_LEVEL_PERKS[w.id][next_level]
			var wdef: Dictionary = WEAPON_DEFS[w.id]
			options.append({
				type = "weapon_upgrade",
				weapon_id = w.id,
				rarity = "rare" if next_level >= 4 else "common",
				icon = perk.icon,
				label = wdef.name + " — " + perk.name,
				desc = perk.desc,
				perk = perk,
			})
		else:
			# Fallback generic upgrade
			var wdef2: Dictionary = WEAPON_DEFS[w.id]
			options.append({
				type = "weapon_upgrade", weapon_id = w.id,
				rarity = "common", icon = "⬆",
				label = wdef2.name + " Lv" + str(w.level + 1),
				desc = "+1 damage",
				perk = {effect = "damage", value = 1},
			})

	# --- New weapon acquisition if slot open ---
	if active_weapons.size() < weapon_slots:
		var held: Array[String] = []
		for w in active_weapons:
			held.append(w.id)
		var available: Array[String] = []
		for k in WEAPON_DEFS.keys():
			if not held.has(k):
				available.append(k)
		if not available.is_empty():
			available.shuffle()
			var new_id: String = available[0]
			var wdef3: Dictionary = WEAPON_DEFS[new_id]
			options.append({
				type = "weapon_acquire", weapon_id = new_id,
				rarity = "rare", icon = "🔫",
				label = "Acquire: " + wdef3.name,
				desc = wdef3.desc,
				perk = {},
			})

	# --- Passives: pick from pool, exclude already taken ---
	var available_passives: Array[Dictionary] = []
	for p in ALL_PASSIVES:
		if not passives_taken.has(p.id):
			available_passives.append(p)
	available_passives.shuffle()
	# Always offer at least 1 passive, prefer rare if level is high
	var passive_count: int = 1 if options.size() >= 2 else 2
	for p in available_passives.slice(0, passive_count):
		options.append({
			type = "passive", id = p.id,
			rarity = p.rarity, icon = p.icon,
			label = p.name, desc = p.desc,
			perk = {},
		})

	options.shuffle()
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
		var is_rare: bool = c.get("rarity", "common") == "rare"

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
			for wi in range(active_weapons.size()):
				var w: Dictionary = active_weapons[wi]
				if w.id == choice.weapon_id:
					w.level += 1
					active_weapons[wi] = w
					# Apply perk effect to weapon_mods
					var perk: Dictionary = choice.get("perk", {})
					_apply_weapon_perk(choice.weapon_id, perk)
					break
		"weapon_acquire":
			var is_baton: bool = choice.weapon_id == "baton"
			var acq_mag_bonus: int = SaveManager.data.ship_upgrades.get("mag_size", 0) * 3
			var acq_base: int = 999 if is_baton else 12 + acq_mag_bonus
			active_weapons.append({
				id=choice.weapon_id, level=1,
				cooldown_timer=0.0,
				mag_ammo=acq_base,
				mag_size=acq_base,
				reload_timer=0.0
			})
		"passive":
			passives_taken.append(choice.id)
			match choice.id:
				"tough":
					player_max_hp += 3
					player_hp = player_max_hp  # full heal
				"tough2":
					player_max_hp += 2
					player_hp = mini(player_hp + 2, player_max_hp)
				"speed":
					player_speed += 25.0
				"xp":
					essence_collect_radius += 40.0
				"reload":
					for wi2 in range(active_weapons.size()):
						var w2: Dictionary = active_weapons[wi2]
						# Stored in weapon_mods for fire logic to read
						var mods: Dictionary = weapon_mods.get(w2.id, {})
						mods["reload_mult"] = mods.get("reload_mult", 1.0) * 0.7
						weapon_mods[w2.id] = mods
				"magplus":
					for wi3 in range(active_weapons.size()):
						var w3: Dictionary = active_weapons[wi3]
						w3.mag_size += 4
						w3.mag_ammo = mini(w3.mag_ammo + 4, w3.mag_size)
						active_weapons[wi3] = w3
				"dodge":
					var mods_d: Dictionary = weapon_mods.get("_player", {})
					mods_d["dodge_chance"] = mods_d.get("dodge_chance", 0.0) + 0.1
					weapon_mods["_player"] = mods_d
				"burst_move":
					var mods_bm: Dictionary = weapon_mods.get("_player", {})
					mods_bm["kill_streak_speed"] = true
					weapon_mods["_player"] = mods_bm
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

	paused = false
	upgrade_choices = []
	upgrade_buttons = []
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
			for wi in range(active_weapons.size()):
				if active_weapons[wi].id == wid:
					var w: Dictionary = active_weapons[wi]
					w.mag_size += 6
					w.mag_ammo = mini(w.mag_ammo + 6, w.mag_size)
					active_weapons[wi] = w
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

# =========================================================
# CORRUPTION
# =========================================================
func _apply_corruption_effects():
	# Threshold messages (first time only)
	if corruption >= 36.0 and not corruption_threshold_35:
		corruption_threshold_35 = true
		_show_message("Corruption rising...")
	if corruption >= 60.0 and not corruption_threshold_60:
		corruption_threshold_60 = true
		_show_message("Deeply corrupted")
	# Visual thresholds only for now — Phase 6 adds mechanical effects
	# 36+: melee heals (Phase 6)
	# 60+: void mutations more likely (Phase 6)
	# Field stim corruption: consumables not built yet — Phase 3+

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
		var sp: Vector2 = _w2s(e.pos)
		var is_elite: bool = e.get("is_elite", false)
		draw_circle(sp, e.radius, e.color)
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
	draw_circle(pp, PLAYER_RADIUS, Color(0.2, 0.9, 0.2))

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

	# Primary weapon ammo text (first weapon)
	if active_weapons.size() > 0:
		var pw: Dictionary = active_weapons[0]
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
	var target_text := "Ingredients: %d/%d  |  Wave %d" % [target_kills, target_total, wave_current]
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

	# XP bar (full width, bottom of screen)
	var xp_bar_y: float = vp_size.y - 20.0
	var xp_bar_h := 8.0
	draw_rect(Rect2(0.0, xp_bar_y, vp_size.x, xp_bar_h), Color(0.1, 0.1, 0.15))
	var xp_frac: float = float(essence_collected) / 20.0
	draw_rect(Rect2(0.0, xp_bar_y, vp_size.x * xp_frac, xp_bar_h), Color(0.5, 0.0, 0.9))
	# LV label left of bar
	_draw_text(Vector2(4.0, xp_bar_y - 4.0), "LV %d" % player_level, Color(0.7, 0.5, 1.0), 12)

	# Weapon list (bottom left, above XP bar)
	var wy: float = xp_bar_y - 16.0
	for w in active_weapons:
		var def: Dictionary = WEAPON_DEFS[w.id]
		var reload_indicator: String = " (reloading)" if w.reload_timer > 0 else ""
		var ammo_str: String = "" if w.mag_size >= 999 else "  %d/%d" % [w.mag_ammo, w.mag_size]
		_draw_text(Vector2(4.0, wy), def.name + " Lv" + str(w.level) + ammo_str + reload_indicator, Color(0.6,0.7,0.9,0.85), 11)
		wy -= 15.0

	# HUD message (center)
	if hud_message != "":
		var msg_alpha: float = clampf(hud_message_timer, 0.0, 1.0)
		_draw_text(Vector2(vp_size.x * 0.5 - 80.0, vp_size.y * 0.5 - 20.0), hud_message, Color(1, 1, 1, msg_alpha), 18)

	# Dead overlay
	if dead:
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0, 0, 0, 0.6))
		_draw_text(Vector2(vp_size.x * 0.5 - 40.0, vp_size.y * 0.5 - 20.0), "DEAD", Color(1, 0.2, 0.2), 32)

func _w2s(world_pos: Vector2) -> Vector2:
	return world_pos - camera_offset

func _draw_text(pos: Vector2, text: String, color: Color, font_size: int = 16) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
