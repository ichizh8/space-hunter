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
var target_kills := 0
var target_total := 0
var contract_type := ""

# === Wave system ===
var wave_current := 0
var wave_total := 0
var wave_timer := 0.0
const WAVE_INTERVAL := 22.0  # seconds before forcing next wave
var wave_targets_remaining := 0  # contract targets left to assign to waves

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

	wave_total = 2 + depth  # Depth 1: 3 waves, Depth 2: 4, Depth 3: 5
	wave_targets_remaining = target_total
	wave_timer = WAVE_INTERVAL

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
	if wave_current >= wave_total:
		return  # all waves done, just wait for targets to die

	# Count living enemies
	var alive: int = 0
	for e in enemies:
		if e.hp > 0:
			alive += 1

	wave_timer -= delta
	var force_next: bool = wave_timer <= 0.0
	var low_enemies: bool = alive <= 3

	if force_next or low_enemies:
		var depth: int = GameData.current_contract.get("depth", 1)
		_spawn_wave(depth)

func _spawn_wave(depth: int) -> void:
	wave_current += 1
	wave_timer = WAVE_INTERVAL
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var types_list: Array = CREATURE_DEFS.keys()
	var wave_idx: int = wave_current  # 1-based

	# Show wave message (except wave 1 — no announcement at match start)
	if wave_idx > 1:
		_show_message("-- WAVE %d --" % wave_idx)

	# Targets: spread across waves. Wave 1 gets ~half, later waves get remainder evenly.
	var targets_this_wave := 0
	if wave_idx == 1:
		targets_this_wave = max(1, int(ceil(float(wave_targets_remaining) * 0.5)))
	else:
		var waves_left: int = wave_total - wave_idx + 1
		targets_this_wave = max(0, int(ceil(float(wave_targets_remaining) / float(max(waves_left, 1)))))
	targets_this_wave = min(targets_this_wave, wave_targets_remaining)
	wave_targets_remaining -= targets_this_wave
	for i in range(targets_this_wave):
		_spawn_single_enemy(contract_type, true, rng)

	# Filler: scales with wave number and depth
	# Wave 1: base. Each subsequent wave: +4 fillers and faster (5% speed bonus per wave).
	var base_fillers: int = 8 + depth * 4
	var filler_count: int = base_fillers + (wave_idx - 1) * 4 + rng.randi_range(0, 3)
	var filler_types: Array = []
	for t in types_list:
		if t != contract_type:
			filler_types.append(t)
	var spawn_start: int = enemies.size()
	for i in range(filler_count):
		var ft: String = filler_types[rng.randi_range(0, filler_types.size() - 1)]
		_spawn_single_enemy(ft, false, rng)

	# Apply wave speed bonus to newly spawned enemies
	var speed_mult: float = 1.0 + (wave_idx - 1) * 0.08
	for i in range(spawn_start, enemies.size()):
		enemies[i].speed *= speed_mult

	# Pre-aggro ~50% of new wave — they rush immediately
	var new_count: int = enemies.size() - spawn_start
	var aggro_count: int = int(new_count * 0.5)
	for i in range(spawn_start, spawn_start + aggro_count):
		enemies[i].is_aggroed = true
		enemies[i].aggro_origin = enemies[i].pos

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
		var damage: int = def.damage + (w.level - 1)

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
			w.cooldown_timer = def.fire_rate

			match def.pattern:
				"single":
					w.mag_ammo -= 1
					bullets.append({
						pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
						vel = dir * def.bullet_speed,
						radius = def.bullet_radius,
						color = def.color,
						damage = damage,
						lifetime = def.range / def.bullet_speed,
						from_player = true,
					})
				"scatter":
					w.mag_ammo -= 1
					var base_angle: float = dir.angle()
					for offset_deg in [-15.0, 0.0, 15.0]:
						var angle: float = base_angle + deg_to_rad(offset_deg)
						var scatter_dir := Vector2(cos(angle), sin(angle))
						bullets.append({
							pos = player_pos + scatter_dir * (PLAYER_RADIUS + 6.0),
							vel = scatter_dir * def.bullet_speed,
							radius = def.bullet_radius,
							color = def.color,
							damage = damage,
							lifetime = def.range / def.bullet_speed,
							from_player = true,
						})
				"piercing":
					w.mag_ammo -= 1
					bullets.append({
						pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
						vel = dir * def.bullet_speed,
						radius = def.bullet_radius,
						color = def.color,
						damage = damage,
						lifetime = def.range / def.bullet_speed,
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

	# Spawn ingredient pickup (Phase 3 — pristine quality)
	if CREATURE_INGREDIENTS.has(e.type):
		var ing_def: Dictionary = CREATURE_INGREDIENTS[e.type]
		# Extract base ingredient id (strip "ingredient_" prefix)
		var base_id: String = ing_def.id.replace("ingredient_", "")
		_drop_ingredient({
			ingredient_id = base_id,
			void_type = CREATURE_DEFS[e.type].void_type,
			pos = death_pos + Vector2(10, 0),
			color = INGREDIENT_COLORS.get(ing_def.id, Color.WHITE),
		})

	# Spawn essence
	pickups.append({pos = death_pos + Vector2(-10, 0), type = "essence"})

	# Track target kills
	if e.is_target:
		target_kills += 1
		_show_message("Target down! %d/%d" % [target_kills, target_total])
		if target_kills >= target_total and wave_current >= wave_total and not exit_spawned:
			_spawn_exit()

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

	# Upgrade existing weapons (up to 2 offers)
	var upgradeable: Array[Dictionary] = []
	for w in active_weapons:
		if w.level < 5:
			upgradeable.append(w)
	upgradeable.shuffle()
	for w in upgradeable.slice(0, 2):
		var def: Dictionary = WEAPON_DEFS[w.id]
		options.append({
			type="weapon_upgrade", weapon_id=w.id,
			label=def.name + " Lv" + str(w.level) + "->Lv" + str(w.level+1),
			desc=def.desc + " (+" + str(w.level) + " dmg total)"
		})

	# Acquire new weapon if slot open
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
			var def: Dictionary = WEAPON_DEFS[new_id]
			options.append({type="weapon_acquire", weapon_id=new_id, label="Acquire " + def.name, desc=def.desc})

	# Passives
	var passives: Array[Dictionary] = [
		{type="passive", id="tough", label="Reinforced Suit", desc="+2 max HP, heal now"},
		{type="passive", id="speed", label="Thruster Boost", desc="+20 move speed"},
		{type="passive", id="xp", label="Void Attunement", desc="Collect essence from further away"}
	]
	passives.shuffle()
	options.append(passives[0])

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
		var btn := Button.new()
		btn.text = "[%d] %s — %s" % [i + 1, upgrade_choices[i].label, upgrade_choices[i].desc]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_upgrade_chosen.bind(i))
		vbox.add_child(btn)
		upgrade_buttons.append(btn)

	add_child(panel)

func _on_upgrade_chosen(idx: int) -> void:
	var choice: Dictionary = upgrade_choices[idx]
	match choice.type:
		"weapon_upgrade":
			for w in active_weapons:
				if w.id == choice.weapon_id:
					w.level += 1
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
			match choice.id:
				"tough":
					player_max_hp += 2
					player_hp = mini(player_hp + 2, player_max_hp)
				"speed":
					player_speed += 20.0
				"xp":
					essence_collect_radius = essence_collect_radius + 20.0

	paused = false
	upgrade_choices = []
	upgrade_buttons = []
	call_deferred("_remove_upgrade_panel")

func _remove_upgrade_panel() -> void:
	var panel := get_node_or_null("UpgradePanel")
	if panel:
		panel.queue_free()

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
		draw_circle(sp, e.radius, e.color)
		# HP bar above enemy
		var bar_w: float = e.radius * 2.0
		var bar_h := 3.0
		var bar_pos := Vector2(sp.x - bar_w * 0.5, sp.y - e.radius - 8.0)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.3, 0.3, 0.3))
		var hp_frac: float = float(e.hp) / float(e.max_hp)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_frac, bar_h)), Color(0.9, 0.2, 0.2))
		# Target indicator
		if e.is_target:
			draw_arc(sp, e.radius + 4.0, 0.0, TAU, 16, Color(1.0, 1.0, 0.0, 0.6), 1.5)
		# Name label — short name above HP bar
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
	var target_text := "Targets: %d/%d  |  Wave %d/%d" % [target_kills, target_total, wave_current, wave_total]
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
