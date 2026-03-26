extends Control

# === World ===
const WORLD_W := 1600
const WORLD_H := 1600
const GRID_STEP := 200

# === Player ===
var player_pos := Vector2(800.0, 800.0)
var player_hp := 10
var player_max_hp := 10
var player_speed := 180.0
const PLAYER_RADIUS := 16.0
# === Magazine ===
var mag_size := 12
var mag_ammo := 12
var reload_time := 1.5
var reload_timer := 0.0
var is_reloading := false

# === Attack ===
var attack_cooldown_base := 0.35
var attack_cooldown_timer := 0.0
var bullet_damage := 3

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

# === Contract tracking ===
var target_kills := 0
var target_total := 0
var contract_type := ""

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
	"Void Leech": {radius = 12, color = Color(0.8, 0.2, 0.2), speed = 60, hp = 3, detection = 180, melee_dmg = 1, ranged = false, void_type = false},
	"Shadow Crawler": {radius = 13, color = Color(0.5, 0.1, 0.7), speed = 80, hp = 3, detection = 220, melee_dmg = 1, ranged = false, void_type = false},
	"Abyss Worm": {radius = 14, color = Color(0.3, 0.6, 0.1), speed = 50, hp = 5, detection = 250, melee_dmg = 2, ranged = false, void_type = false},
	"Nether Stalker": {radius = 12, color = Color(0.2, 0.4, 0.9), speed = 55, hp = 4, detection = 300, melee_dmg = 0, ranged = true, ranged_dmg = 2, ranged_cooldown = 2.0, void_type = false},
	"Rift Parasite": {radius = 11, color = Color(0.9, 0.5, 0.1), speed = 90, hp = 4, detection = 220, melee_dmg = 1, ranged = false, void_type = true},
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

const ALL_UPGRADES: Array = [
	{id = "ammo", label = "Piercing Rounds (+1 dmg)"},
	{id = "reload", label = "Quick Reload (faster reload + fire)"},
	{id = "tough", label = "Tougher (+2 HP)"},
	{id = "speed", label = "Speed Boost"},
	{id = "damage", label = "Big Shots (+1)"},
]

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	# Parse contract
	var contract: Dictionary = GameData.current_contract
	contract_type = contract.get("creature_type", "Void Leech")
	var depth: int = contract.get("depth", 1)
	target_total = 3 + depth

	_spawn_obstacles()
	_spawn_enemies(depth)

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

func _spawn_enemies(depth: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var types_list: Array = CREATURE_DEFS.keys()

	# Spawn target creatures
	var target_count: int = target_total
	for i in range(target_count):
		_spawn_single_enemy(contract_type, true, rng)

	# Spawn 4 filler creatures of other types
	var filler_types: Array = []
	for t in types_list:
		if t != contract_type:
			filler_types.append(t)
	for i in range(4):
		var ft: String = filler_types[rng.randi_range(0, filler_types.size() - 1)]
		_spawn_single_enemy(ft, false, rng)

func _spawn_single_enemy(type_name: String, is_target: bool, rng: RandomNumberGenerator) -> void:
	var def: Dictionary = CREATURE_DEFS[type_name]
	var pos := Vector2.ZERO
	for _try in range(30):
		pos = Vector2(rng.randf_range(60.0, WORLD_W - 60.0), rng.randf_range(60.0, WORLD_H - 60.0))
		if pos.distance_to(player_pos) < 300.0:
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
			if te.position.x < half_w:
				# Start joystick
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
	_auto_attack(delta)
	_update_enemies(delta)
	_update_bullets(delta)
	_check_pickups()
	_update_hud_message(delta)

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

func _auto_attack(delta: float) -> void:
	# Handle reload
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			is_reloading = false
			mag_ammo = mag_size
			_show_message("Reloaded!")
		return

	attack_cooldown_timer -= delta
	if attack_cooldown_timer > 0.0:
		return

	# Out of ammo — start reload
	if mag_ammo <= 0:
		is_reloading = true
		reload_timer = reload_time
		_show_message("Reloading...")
		return

	# Find nearest enemy
	var nearest_dist := 999999.0
	var nearest_pos := Vector2.ZERO
	var found := false
	for e in enemies:
		if e.hp <= 0:
			continue
		var d: float = player_pos.distance_to(e.pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest_pos = e.pos
			found = true

	if not found or nearest_dist > 350.0:
		return

	# Fire bullet
	mag_ammo -= 1
	attack_cooldown_timer = attack_cooldown_base
	var dir: Vector2 = (nearest_pos - player_pos).normalized()
	bullets.append({
		pos = player_pos + dir * (PLAYER_RADIUS + 6.0),
		vel = dir * 400.0,
		radius = 5.0,
		color = Color(1.0, 0.9, 0.2),
		damage = bullet_damage,
		lifetime = 0.8,
		from_player = true,
	})

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
			# Ranged enemies stay back
			var min_range := 0.0
			if e.ranged:
				min_range = 150.0
				# Shoot
				e.ranged_cooldown_timer -= delta
				if e.ranged_cooldown_timer <= 0.0 and dist_to_player < e.detection:
					e.ranged_cooldown_timer = e.ranged_cooldown_base
					var dir: Vector2 = (player_pos - e.pos).normalized()
					bullets.append({
						pos = e.pos + dir * (e.radius + 5.0),
						vel = dir * 250.0,
						radius = 5.0,
						color = Color(1.0, 0.3, 0.1),
						damage = e.ranged_dmg,
						lifetime = 1.2,
						from_player = false,
					})

			if dist_to_player > min_range + e.radius:
				var dir: Vector2 = (player_pos - e.pos).normalized()
				var new_pos: Vector2 = e.pos + dir * e.speed * delta
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
		b.pos += b.vel * delta
		b.lifetime -= delta

		if b.lifetime <= 0.0:
			to_remove.append(i)
			continue

		# Out of world
		if b.pos.x < 0.0 or b.pos.x > WORLD_W or b.pos.y < 0.0 or b.pos.y > WORLD_H:
			to_remove.append(i)
			continue

		# Obstacle collision
		var hit_obs := false
		for obs in obstacles:
			if b.pos.distance_to(obs.pos) < obs.radius + b.radius:
				hit_obs = true
				break
		if hit_obs:
			to_remove.append(i)
			continue

		if b.from_player:
			# Hit enemies
			for ei in range(enemies.size()):
				var e: Dictionary = enemies[ei]
				if e.hp <= 0:
					continue
				if b.pos.distance_to(e.pos) < e.radius + b.radius:
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

	# Spawn ingredient pickup
	if CREATURE_INGREDIENTS.has(e.type):
		var ing_data: Dictionary = CREATURE_INGREDIENTS[e.type].duplicate()
		var ing_color: Color = INGREDIENT_COLORS.get(ing_data.id, Color.WHITE)
		pickups.append({pos = death_pos + Vector2(10, 0), type = "ingredient", color = ing_color, ingredient_data = ing_data})

	# Spawn essence
	pickups.append({pos = death_pos + Vector2(-10, 0), type = "essence"})

	# Track target kills
	if e.is_target:
		target_kills += 1
		_show_message("Target down! %d/%d" % [target_kills, target_total])
		if target_kills >= target_total and not exit_spawned:
			_spawn_exit()

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
			pickup_radius = 40.0

		if player_pos.distance_to(p.pos) < pickup_radius + PLAYER_RADIUS:
			if p.type == "ingredient":
				run_ingredients.append(p.ingredient_data)
				_show_message("Picked up " + p.ingredient_data.name)
			elif p.type == "essence":
				essence_collected += 1
				if essence_collected >= 50:
					essence_collected -= 50
					_level_up()
			to_remove.append(i)

	to_remove.sort()
	for idx in range(to_remove.size() - 1, -1, -1):
		pickups.remove_at(to_remove[idx])

# =========================================================
# LEVEL UP
# =========================================================
func _level_up() -> void:
	player_level += 1
	paused = true
	_show_message("Level Up!")

	# Pick 3 random upgrades
	var shuffled: Array = ALL_UPGRADES.duplicate()
	shuffled.shuffle()
	upgrade_choices = []
	for idx in range(mini(3, shuffled.size())):
		upgrade_choices.append(shuffled[idx])

	# Create upgrade panel using call_deferred
	call_deferred("_create_upgrade_panel")

func _create_upgrade_panel() -> void:
	var vp_size := get_viewport_rect().size
	var panel := Panel.new()
	panel.name = "UpgradePanel"
	panel.position = Vector2(vp_size.x * 0.1, vp_size.y * 0.3)
	panel.size = Vector2(vp_size.x * 0.8, vp_size.y * 0.35)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(panel.size.x - 20, panel.size.y - 20)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Level Up! Choose an upgrade:"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	upgrade_buttons = []
	for i in range(upgrade_choices.size()):
		var btn := Button.new()
		btn.text = upgrade_choices[i].label
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_upgrade_chosen.bind(i))
		vbox.add_child(btn)
		upgrade_buttons.append(btn)

	add_child(panel)

func _on_upgrade_chosen(idx: int) -> void:
	var choice: Dictionary = upgrade_choices[idx]
	match choice.id:
		"ammo":
			bullet_damage += 1
		"reload":
			reload_time = maxf(reload_time - 0.25, 0.5)
			attack_cooldown_base = maxf(attack_cooldown_base - 0.03, 0.15)
		"tough":
			player_max_hp += 2
			player_hp = mini(player_hp + 2, player_max_hp)
		"speed":
			player_speed += 20.0
		"damage":
			bullet_damage += 1

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
	SaveManager.complete_contract(reward, 0)
	GameData.set_hunt_result(reward, 0, run_ingredients.size(), run_ingredients)
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

func _finish_hunt(credits: int) -> void:
	if credits == 0:
		SaveManager.complete_contract(0, 0)
		GameData.set_hunt_result(0, 0, 0)
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
	for p in pickups:
		var sp: Vector2 = _w2s(p.pos)
		if p.type == "ingredient":
			draw_rect(Rect2(sp - Vector2(6, 6), Vector2(12, 12)), p.color)
		elif p.type == "essence":
			draw_circle(sp, 8.0, Color(0.5, 0.0, 0.8))

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

	# Ammo text
	var ammo_color: Color = Color(1.0, 0.8, 0.2) if not is_reloading else Color(1.0, 0.4, 0.2)
	var ammo_text: String = "RELOADING..." if is_reloading else "%d / %d" % [mag_ammo, mag_size]
	_draw_text(Vector2(hp_bar_x, hp_bar_y + hp_bar_h + 6.0), ammo_text, ammo_color, 13)

	# Target counter (top center)
	var target_text := "Targets: %d/%d" % [target_kills, target_total]
	_draw_text(Vector2(vp_size.x * 0.5 - 50.0, 16.0), target_text, Color.WHITE, 14)

	# Corruption meter (top right)
	var corr_x: float = vp_size.x - 92.0
	draw_rect(Rect2(corr_x, 16.0, 80.0, 12.0), Color(0.15, 0.1, 0.2))
	# corruption is 0 for now

	# Essence/level (bottom center)
	var level_text := "LV %d | Essence: %d/50" % [player_level, essence_collected]
	_draw_text(Vector2(vp_size.x * 0.5 - 70.0, vp_size.y - 30.0), level_text, Color(0.7, 0.5, 1.0), 14)

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
