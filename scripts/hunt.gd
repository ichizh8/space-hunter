extends Control

const GRID_SIZE := 15
const TILE_SIZE := 32
const VIEW_RADIUS := 5

enum Tile { WALL, FLOOR, EXIT }

const RANGED_CREATURES := ["Abyss Worm", "Nether Stalker"]

const CREATURE_STATS: Dictionary = {
	"Void Leech":     {detection = 3, leash = 6},
	"Shadow Crawler": {detection = 4, leash = 7},
	"Abyss Worm":     {detection = 4, leash = 8},
	"Nether Stalker": {detection = 5, leash = 10},
	"Rift Parasite":  {detection = 6, leash = 12},
}

const CREATURE_INGREDIENTS: Dictionary = {
	"Void Leech": {id = "ingredient_void_extract", name = "Void Extract", symbol = "V", uses = 1, ingredient = true},
	"Shadow Crawler": {id = "ingredient_shadow_membrane", name = "Shadow Membrane", symbol = "S", uses = 1, ingredient = true},
	"Abyss Worm": {id = "ingredient_abyss_flesh", name = "Abyss Flesh", symbol = "A", uses = 1, ingredient = true},
	"Nether Stalker": {id = "ingredient_nether_bile", name = "Nether Bile", symbol = "N", uses = 1, ingredient = true},
	"Rift Parasite": {id = "ingredient_rift_spore", name = "Rift Spore", symbol = "R", uses = 1, ingredient = true},
}

# Grid data
var grid: Array = []  # 2D array of Tile
var revealed: Array = []  # 2D bool array — ever seen
var tile_visible: Array = []  # 2D bool array — currently in LOS

# Entities
var player_pos := Vector2i.ZERO
var player_hp := 10
var creatures: Array[Dictionary] = []  # {pos, hp, type, is_target, stunned_turns}
var turn_count := 0
var corruption := 0
var target_kills := 0
var target_total := 0
var exit_spawned := false
var sidearm_ammo: int = 12
var stealth_charge: float = 100.0
const STEALTH_MAX: float = 100.0
var stealth_active: bool = false

# Tap-to-move
var move_path: Array[Vector2i] = []
var _pending_step: bool = false

# Inventory (max 3 slots)
var inventory: Array[Dictionary] = []  # {id, name, symbol, uses}
var traps: Array[Vector2i] = []  # positions of placed traps
var _action_bar: HBoxContainer
var inventory_open: bool = false
var _inv_layer: CanvasLayer
var _inv_scroll_content: VBoxContainer

# HP bar
var _hp_bar_bg: ColorRect
var _hp_bar_fg: ColorRect

# Hit flash system: {Vector2i: {color: Color, timer: float}}
var _flashes: Dictionary = {}

# Ranged targeting
var targeting_mode: bool = false

# Screen vignette flash
var _vignette: ColorRect

# UI references
@onready var grid_container: Control = $GridViewport/GridRoot
@onready var hud_label: Label = $HUD/HUDLabel
@onready var message_label: Label = $HUD/MessageLabel
@onready var dpad_up: Button = $DPad/Up
@onready var dpad_down: Button = $DPad/Down
@onready var dpad_left: Button = $DPad/Left
@onready var dpad_right: Button = $DPad/Right

func _ready() -> void:
	_generate_dungeon()
	_spawn_entities()
	_update_visibility()
	_center_camera()
	queue_redraw()
	_update_hud()
	# Hide D-pad so it doesn't consume touch input
	$DPad.hide()
	# Grab focus so WASD/arrow keys work on this Control node
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	# Start with 1 net and 3 darts in inventory
	inventory.append({id = "sidearm", name = "Sidearm", symbol = "G", uses = 999, weapon = true})
	inventory.append({id = "net", name = "Net", symbol = "N", uses = 1})
	# Action bar
	var action_bar := HBoxContainer.new()
	action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_bar.offset_top = -180
	action_bar.z_index = 10
	action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in inventory.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 60)
		btn.name = "ItemBtn%d" % i
		action_bar.add_child(btn)
		btn.pressed.connect(_use_item.bind(i))
	add_child(action_bar)
	_action_bar = action_bar

	# HP bar (background + foreground)
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hp_bar_bg.offset_bottom = 8
	_hp_bar_bg.color = Color(0.15, 0.15, 0.15)
	_hp_bar_bg.z_index = 15
	add_child(_hp_bar_bg)

	_hp_bar_fg = ColorRect.new()
	_hp_bar_fg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hp_bar_fg.offset_bottom = 8
	_hp_bar_fg.color = Color(0.2, 0.8, 0.2)
	_hp_bar_fg.z_index = 16
	add_child(_hp_bar_fg)
	_update_hp_bar()

	# Vignette flash overlay
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(1, 0, 0, 0.3)
	_vignette.z_index = 20
	_vignette.visible = false
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	# Inventory panel (CanvasLayer overlay)
	_inv_layer = CanvasLayer.new()
	_inv_layer.layer = 10
	_inv_layer.visible = false
	add_child(_inv_layer)

	var inv_bg := ColorRect.new()
	inv_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	inv_bg.color = Color(0, 0, 0, 0.75)
	inv_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_inv_layer.add_child(inv_bg)

	var inv_panel := PanelContainer.new()
	inv_panel.set_anchors_preset(Control.PRESET_CENTER)
	inv_panel.anchor_left = 0.1
	inv_panel.anchor_right = 0.9
	inv_panel.anchor_top = 0.1
	inv_panel.anchor_bottom = 0.9
	inv_panel.offset_left = 0
	inv_panel.offset_right = 0
	inv_panel.offset_top = 0
	inv_panel.offset_bottom = 0
	_inv_layer.add_child(inv_panel)

	var inv_vbox := VBoxContainer.new()
	inv_panel.add_child(inv_vbox)

	var inv_title := Label.new()
	inv_title.text = "Inventory"
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_vbox.add_child(inv_title)

	var inv_scroll := ScrollContainer.new()
	inv_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_vbox.add_child(inv_scroll)

	_inv_scroll_content = VBoxContainer.new()
	_inv_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_scroll.add_child(_inv_scroll_content)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 50)
	close_btn.pressed.connect(_toggle_inventory)
	inv_vbox.add_child(close_btn)

func _process(delta: float) -> void:
	if inventory_open:
		return
	if _pending_step and not move_path.is_empty():
		_pending_step = false
		var dir: Vector2i = move_path.pop_front()
		_move(dir)
	elif _pending_step:
		_pending_step = false

	# Tick flash timers
	var any_flash := false
	var expired: Array[Vector2i] = []
	for pos: Vector2i in _flashes:
		_flashes[pos]["timer"] -= delta
		if _flashes[pos]["timer"] <= 0:
			expired.append(pos)
		else:
			any_flash = true
	for pos in expired:
		_flashes.erase(pos)
	if any_flash or not expired.is_empty():
		grid_container.queue_redraw()

func _input(event: InputEvent) -> void:
	# Inventory toggle / close
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I or event.keycode == KEY_TAB:
			_toggle_inventory()
			return
		if inventory_open and event.keycode == KEY_ESCAPE:
			_toggle_inventory()
			return
		if inventory_open:
			return  # Block all other keys while inventory is open

	# Cancel targeting with Escape
	if event is InputEventKey and event.pressed and not event.echo:
		if targeting_mode and event.keycode == KEY_ESCAPE:
			_cancel_targeting()
			return

	# Keyboard movement
	if event is InputEventKey and event.pressed and not event.echo:
		if targeting_mode:
			return  # Block movement while targeting
		var dir := Vector2i.ZERO
		if event.keycode == KEY_W or event.keycode == KEY_UP: dir = Vector2i(0, -1)
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN: dir = Vector2i(0, 1)
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT: dir = Vector2i(-1, 0)
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT: dir = Vector2i(1, 0)
		elif event.keycode == KEY_1: _use_item(0); return
		elif event.keycode == KEY_2: _use_item(1); return
		elif event.keycode == KEY_3: _use_item(2); return
		elif event.keycode == KEY_4: _use_item(3); return
		elif event.keycode == KEY_5: _use_item(4); return
		elif event.keycode == KEY_6: _use_item(5); return
		elif event.keycode == KEY_SPACE or event.keycode == KEY_Z: _player_wait(); return
		if dir != Vector2i.ZERO:
			move_path.clear()
			_move(dir)
		return

	# Block taps while inventory is open
	if inventory_open:
		return

	# Touch/mouse tap
	var is_tap := false
	if event is InputEventScreenTouch and not event.pressed:
		is_tap = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_tap = true
	if not is_tap:
		return

	# Use get_mouse_position() — always correct viewport coords in Godot 4
	var tap_pos := get_viewport().get_mouse_position()
	var grid_local := tap_pos - grid_container.position
	var gx := int(floor(grid_local.x / TILE_SIZE))
	var gy := int(floor(grid_local.y / TILE_SIZE))

	# Bounds check
	if gx < 0 or gx >= GRID_SIZE or gy < 0 or gy >= GRID_SIZE:
		return
	# Must be revealed
	if not revealed[gx][gy]:
		return
	# Can't tap walls
	if grid[gx][gy] == Tile.WALL:
		return

	var target := Vector2i(gx, gy)

	# Targeting mode: fire dart at tapped creature
	if targeting_mode:
		var found_creature := -1
		for i in creatures.size():
			if creatures[i]["hp"] > 0 and creatures[i]["pos"] == target and tile_visible[gx][gy]:
				found_creature = i
				break
		if found_creature >= 0:
			_fire_sidearm(found_creature)
		else:
			_cancel_targeting()
		return

	# Check if tapped tile has a visible creature — path to adjacent tile
	var creature_idx := -1
	for i in creatures.size():
		if creatures[i]["hp"] > 0 and creatures[i]["pos"] == target and tile_visible[gx][gy]:
			creature_idx = i
			break

	if creature_idx >= 0:
		# Find path to an adjacent tile, then add attack step
		var adj_dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
		var best_path: Array[Vector2i] = []
		var already_adjacent := false
		for adj_dir in adj_dirs:
			var adj_pos: Vector2i = target + adj_dir
			if adj_pos == player_pos:
				already_adjacent = true
				best_path = [] as Array[Vector2i]
				break
			if adj_pos.x < 0 or adj_pos.x >= GRID_SIZE or adj_pos.y < 0 or adj_pos.y >= GRID_SIZE:
				continue
			if grid[adj_pos.x][adj_pos.y] == Tile.WALL:
				continue
			var path := _bfs_path(player_pos, adj_pos)
			if not path.is_empty() and (best_path.is_empty() or path.size() < best_path.size()):
				best_path = path
		if not already_adjacent and best_path.is_empty():
			return
		# Add the attack direction at the end
		var attack_dir: Vector2i = target - (player_pos if best_path.is_empty() else player_pos + _sum_dirs(best_path))
		best_path.append(attack_dir)
		move_path = best_path
	else:
		if target == player_pos:
			return
		var path := _bfs_path(player_pos, target)
		if path.is_empty():
			return
		move_path = path

	# Execute first step immediately
	var first_dir: Vector2i = move_path.pop_front()
	_move(first_dir)

func _sum_dirs(dirs: Array[Vector2i]) -> Vector2i:
	var total := Vector2i.ZERO
	for d in dirs:
		total += d
	return total

func _bfs_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if from == to:
		return []
	var max_len := 50
	var visited: Dictionary = {}
	# Queue entries: [position, Array[Vector2i] of directions taken]
	var queue: Array = []
	queue.push_back([from, [] as Array[Vector2i]])
	visited[from] = true
	var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	while not queue.is_empty():
		var entry: Array = queue.pop_front()
		var pos: Vector2i = entry[0]
		var path: Array[Vector2i] = entry[1]
		if path.size() >= max_len:
			continue
		for dir in dirs:
			var np: Vector2i = pos + dir
			if np.x < 0 or np.x >= GRID_SIZE or np.y < 0 or np.y >= GRID_SIZE:
				continue
			if grid[np.x][np.y] == Tile.WALL:
				continue
			if visited.has(np):
				continue
			visited[np] = true
			var new_path: Array[Vector2i] = path.duplicate()
			new_path.append(dir)
			if np == to:
				return new_path
			queue.push_back([np, new_path])
	return [] as Array[Vector2i]

# --- Dungeon Generation ---

func _generate_dungeon() -> void:
	# Initialize all walls
	grid.resize(GRID_SIZE)
	revealed.resize(GRID_SIZE)
	tile_visible.resize(GRID_SIZE)
	for x in GRID_SIZE:
		grid[x] = []
		revealed[x] = []
		tile_visible[x] = []
		grid[x].resize(GRID_SIZE)
		revealed[x].resize(GRID_SIZE)
		tile_visible[x].resize(GRID_SIZE)
		for y in GRID_SIZE:
			grid[x][y] = Tile.WALL
			revealed[x][y] = false
			tile_visible[x][y] = false

	# Carve rooms
	var rooms: Array[Rect2i] = []
	var depth: int = GameData.current_contract.get("depth", 1)
	var num_rooms: int = 4 + depth * 2
	var attempts := 0
	while rooms.size() < num_rooms and attempts < 100:
		attempts += 1
		var w := randi_range(3, 5)
		var h := randi_range(3, 5)
		var rx := randi_range(1, GRID_SIZE - w - 1)
		var ry := randi_range(1, GRID_SIZE - h - 1)
		var room := Rect2i(rx, ry, w, h)
		var overlap := false
		for existing in rooms:
			if room.intersects(existing.grow(1)):
				overlap = true
				break
		if not overlap:
			rooms.append(room)
			for x in range(room.position.x, room.end.x):
				for y in range(room.position.y, room.end.y):
					grid[x][y] = Tile.FLOOR

	# Connect rooms with corridors
	for i in range(1, rooms.size()):
		var from := rooms[i - 1].get_center()
		var to := rooms[i].get_center()
		_carve_corridor(from, to)

	# Ensure connectivity by connecting first and last room
	if rooms.size() >= 2:
		var from := rooms[rooms.size() - 1].get_center()
		var to := rooms[0].get_center()
		_carve_corridor(from, to)

func _carve_corridor(from: Vector2i, to: Vector2i) -> void:
	var pos := from
	while pos.x != to.x:
		if pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE:
			grid[pos.x][pos.y] = Tile.FLOOR
		pos.x += 1 if to.x > pos.x else -1
	while pos.y != to.y:
		if pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE:
			grid[pos.x][pos.y] = Tile.FLOOR
		pos.y += 1 if to.y > pos.y else -1
	if pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE:
		grid[pos.x][pos.y] = Tile.FLOOR

func _spawn_entities() -> void:
	var floor_tiles: Array[Vector2i] = []
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			if grid[x][y] == Tile.FLOOR:
				floor_tiles.append(Vector2i(x, y))
	floor_tiles.shuffle()

	# Player gets first floor tile
	player_pos = floor_tiles.pop_back()

	# Spawn creatures
	var contract := GameData.current_contract
	var creature_type: String = contract.get("creature_type", "Void Leech")
	var depth: int = contract.get("depth", 1)
	var num_creatures: int = depth + 1  # 2-4
	target_total = num_creatures

	for i in num_creatures:
		if floor_tiles.is_empty():
			break
		var pos: Vector2i = floor_tiles.pop_back()
		creatures.append({
			"pos": pos,
			"hp": 3,
			"type": creature_type,
			"is_target": true,
		})

# --- Visibility / Fog of War ---

func _update_visibility() -> void:
	# Clear current visibility
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			tile_visible[x][y] = false

	# Simple raycasting FOV
	for angle in range(0, 360, 2):
		var rad := deg_to_rad(angle)
		var dx := cos(rad)
		var dy := sin(rad)
		var fx := float(player_pos.x) + 0.5
		var fy := float(player_pos.y) + 0.5
		for step in VIEW_RADIUS + 1:
			var cx := int(fx)
			var cy := int(fy)
			if cx < 0 or cx >= GRID_SIZE or cy < 0 or cy >= GRID_SIZE:
				break
			tile_visible[cx][cy] = true
			revealed[cx][cy] = true
			if grid[cx][cy] == Tile.WALL:
				break
			fx += dx
			fy += dy

# --- Movement & Turn Logic ---

func _move(dir: Vector2i) -> void:
	if player_hp <= 0:
		return
	var new_pos := player_pos + dir
	if new_pos.x < 0 or new_pos.x >= GRID_SIZE or new_pos.y < 0 or new_pos.y >= GRID_SIZE:
		return
	if grid[new_pos.x][new_pos.y] == Tile.WALL:
		return

	# Check for creature at destination
	var hit_creature := -1
	for i in creatures.size():
		if creatures[i]["pos"] == new_pos and creatures[i]["hp"] > 0:
			hit_creature = i
			break

	if hit_creature >= 0:
		var c := creatures[hit_creature]

		if stealth_active:
			# Stealth kill — silent, no gunshot alert
			stealth_charge -= 20.0
			var assumed_max_hp := 5
			if c["hp"] <= 3:
				c["hp"] = 0
			else:
				c["hp"] -= int(assumed_max_hp * 0.8)
			if c["hp"] <= 0:
				if c["is_target"]:
					target_kills += 1
				_show_message("Silent kill!")
				_flashes[c["pos"]] = {color = Color.WHITE, timer = 0.3}
				_drop_ingredient(c["type"])
				_check_exit_spawn()
			else:
				_show_message("Silent strike! (%d HP left)" % c["hp"])
				_flashes[c["pos"]] = {color = Color.YELLOW, timer = 0.2}
			if stealth_charge <= 0.0:
				_deactivate_stealth()
		elif sidearm_ammo > 0:
			# Sidearm shot
			sidearm_ammo -= 1
			c["hp"] -= 3
			if c["hp"] <= 0:
				if c["is_target"]:
					target_kills += 1
				_show_message("Bang! Hit %s for 3! Killed!" % c["type"])
				_flashes[c["pos"]] = {color = Color.WHITE, timer = 0.3}
				_drop_ingredient(c["type"])
				_check_exit_spawn()
			else:
				_show_message("Bang! Hit %s for 3! (%d HP left)" % [c["type"], c["hp"]])
				_flashes[c["pos"]] = {color = Color.YELLOW, timer = 0.2}
			_gunshot_alert()
			if stealth_active:
				_deactivate_stealth()
		else:
			# Desperation melee — no ammo
			c["hp"] -= 2
			if c["hp"] <= 0:
				if c["is_target"]:
					target_kills += 1
				_show_message("No ammo! Desperate strike! Killed %s!" % c["type"])
				_flashes[c["pos"]] = {color = Color.WHITE, timer = 0.3}
				_drop_ingredient(c["type"])
				_check_exit_spawn()
			else:
				_show_message("No ammo! Desperate strike! (%d HP left)" % c["hp"])
				_flashes[c["pos"]] = {color = Color.YELLOW, timer = 0.2}
			# Creature retaliates for 2 damage
			player_hp -= 2
			_update_hp_bar()
			_flashes[player_pos] = {color = Color.RED, timer = 0.2}
			if stealth_active:
				_deactivate_stealth()
			if player_hp <= 0:
				_show_message("You died!")
				_game_over()
				return
	else:
		# Move player
		player_pos = new_pos

	# Check exit
	if grid[player_pos.x][player_pos.y] == Tile.EXIT:
		_complete_hunt()
		return

	# Advance turn
	turn_count += 1
	_tick_stealth()

	# Creature AI
	_move_creatures()

	_update_visibility()
	_center_camera()
	grid_container.queue_redraw()
	_update_hud()

	# Auto-step: schedule next path step if path remains
	if not move_path.is_empty():
		# Cancel path if player took damage (creature retaliated or attacked)
		if player_hp <= 0:
			move_path.clear()
		else:
			_pending_step = true

func _move_creatures() -> void:
	var directions := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for creature in creatures:
		if creature["hp"] <= 0:
			continue
		# Stunned creatures skip their turn
		var stunned: int = creature.get("stunned_turns", 0)
		if stunned > 0:
			creature["stunned_turns"] = stunned - 1
			continue

		# Decrement alert_turns
		var alert_turns: int = creature.get("alert_turns", 0)
		if alert_turns > 0:
			creature["alert_turns"] = alert_turns - 1

		# Detection/leash stats
		var ctype: String = creature["type"]
		var stats: Dictionary = CREATURE_STATS.get(ctype, {detection = 4, leash = 8})
		var detection: int = stats["detection"]
		var leash: int = stats["leash"]
		var alerted_detection: int = detection * 2 if creature.get("alert_turns", 0) > 0 else detection

		var cpos: Vector2i = creature["pos"]
		var dist := maxi(absi(cpos.x - player_pos.x), absi(cpos.y - player_pos.y))

		# Stealth: player invisible to detection unless already alerted
		var player_detectable: bool = not stealth_active
		var can_see_player: bool = tile_visible[cpos.x][cpos.y] if (cpos.x >= 0 and cpos.x < GRID_SIZE and cpos.y >= 0 and cpos.y < GRID_SIZE) else false

		# Aggro check
		var chasing: bool = creature.get("alerted", false)
		if not chasing and player_detectable and dist <= alerted_detection and can_see_player:
			chasing = true
			creature["alerted"] = true
			creature["aggro_origin"] = cpos
			creature["leash_msg_shown"] = false
		creature["chasing"] = chasing

		# Leash check
		if chasing and creature.has("aggro_origin"):
			var origin: Vector2i = creature["aggro_origin"]
			var leash_dist := maxi(absi(player_pos.x - origin.x), absi(player_pos.y - origin.y))
			if leash_dist > leash and dist > detection:
				creature["alerted"] = false
				creature["chasing"] = false
				creature.erase("aggro_origin")
				chasing = false
				if not creature.get("leash_msg_shown", false):
					creature["leash_msg_shown"] = true
					_show_message("%s lost you..." % ctype)

		if chasing:
			# Ranged creatures: shoot if within 3 tiles and player visible
			if creature["type"] in RANGED_CREATURES and dist <= 3 and tile_visible[player_pos.x][player_pos.y] and not stealth_active:
				player_hp -= 2
				_update_hp_bar()
				if stealth_active:
					_deactivate_stealth()
				_flashes[player_pos] = {color = Color.RED, timer = 0.2}
				_flash_vignette()
				_show_message("%s fires at you!" % creature["type"])
				if player_hp <= 0:
					_show_message("You died!")
					_game_over()
					return
			else:
				# Sort directions by distance to player (greedy chase)
				var sorted_dirs := directions.duplicate()
				sorted_dirs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
					var pa: Vector2i = cpos + a
					var pb: Vector2i = cpos + b
					var da := maxi(absi(pa.x - player_pos.x), absi(pa.y - player_pos.y))
					var db := maxi(absi(pb.x - player_pos.x), absi(pb.y - player_pos.y))
					return da < db
				)
				_try_creature_move(creature, sorted_dirs)
		else:
			creature["chasing"] = false
			# Random walk
			directions.shuffle()
			_try_creature_move(creature, directions)

func _try_creature_move(creature: Dictionary, dirs: Array) -> void:
	for dir in dirs:
		var new_pos: Vector2i = creature["pos"] + dir
		if new_pos.x < 0 or new_pos.x >= GRID_SIZE or new_pos.y < 0 or new_pos.y >= GRID_SIZE:
			continue
		if grid[new_pos.x][new_pos.y] == Tile.WALL:
			continue
		# Don't walk into other creatures
		var blocked := false
		for other in creatures:
			if other != creature and other["hp"] > 0 and other["pos"] == new_pos:
				blocked = true
				break
		if blocked:
			continue
		# Check if walking into player
		if new_pos == player_pos:
			player_hp -= 1
			_update_hp_bar()
			if stealth_active:
				_deactivate_stealth()
			_flashes[player_pos] = {color = Color.RED, timer = 0.2}
			_flash_vignette()
			_show_message("%s attacks you! (%d HP)" % [creature["type"], player_hp])
			if player_hp <= 0:
				_show_message("You died!")
				_game_over()
				return
		else:
			creature["pos"] = new_pos
			# Check if creature stepped on a trap
			if new_pos in traps:
				traps.erase(new_pos)
				creature["stunned_turns"] = 3
				_show_message("%s stepped on a trap!" % creature["type"])
		break

func _use_item(slot: int) -> void:
	if slot >= inventory.size():
		_show_message("Empty slot!")
		return
	var item: Dictionary = inventory[slot]
	if item["id"] == "sidearm":
		# Enter targeting mode with sidearm
		if sidearm_ammo <= 0:
			_show_message("No ammo! Reload at ship.")
			return
		var has_visible := false
		for creature in creatures:
			if creature["hp"] > 0 and tile_visible[creature["pos"].x][creature["pos"].y]:
				has_visible = true
				break
		if not has_visible:
			_show_message("No targets in range!")
			return
		targeting_mode = true
		_show_message("Select a target to shoot!")
		grid_container.queue_redraw()
		return
	elif item["id"] == "net":
		# Immobilize adjacent creature for 2 turns
		var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
		var netted := false
		for dir in dirs:
			var adj: Vector2i = player_pos + dir
			for creature in creatures:
				if creature["hp"] > 0 and creature["pos"] == adj:
					creature["stunned_turns"] = 2
					_show_message("Netted %s!" % creature["type"])
					netted = true
					break
			if netted:
				break
		if not netted:
			_show_message("No adjacent creature to net!")
			return
	elif item["id"] == "trap":
		# Place trap on current tile
		if player_pos in traps:
			_show_message("Trap already here!")
			return
		traps.append(player_pos)
		_show_message("Trap placed!")
	item["uses"] -= 1
	if item["uses"] <= 0:
		inventory.remove_at(slot)
	_update_hud()

func _drop_ingredient(creature_type: String) -> void:
	if not CREATURE_INGREDIENTS.has(creature_type):
		return
	if inventory.size() >= 6:
		return
	var ingredient: Dictionary = CREATURE_INGREDIENTS[creature_type].duplicate()
	inventory.append(ingredient)
	_show_message("%s dropped!" % ingredient["name"])
	_update_hud()

func _check_exit_spawn() -> void:
	if target_kills >= target_total and not exit_spawned:
		exit_spawned = true
		# Find a floor tile far from player for exit
		var best_pos := Vector2i.ZERO
		var best_dist := 0.0
		for x in GRID_SIZE:
			for y in GRID_SIZE:
				if grid[x][y] == Tile.FLOOR:
					var dist := Vector2(x - player_pos.x, y - player_pos.y).length()
					if dist > best_dist:
						# Make sure no creature is there
						var occupied := false
						for c in creatures:
							if c["pos"] == Vector2i(x, y) and c["hp"] > 0:
								occupied = true
								break
						if not occupied:
							best_dist = dist
							best_pos = Vector2i(x, y)
		grid[best_pos.x][best_pos.y] = Tile.EXIT
		_show_message("All targets eliminated! Exit appeared!")

func _complete_hunt() -> void:
	var reward: int = GameData.current_contract.get("reward", 100)
	SaveManager.complete_contract(reward, corruption)
	var ingredients: Array[Dictionary] = []
	for item in inventory:
		if item.get("ingredient", false):
			ingredients.append(item)
	GameData.set_hunt_result(reward, corruption, 0, ingredients)
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

func _game_over() -> void:
	GameData.set_hunt_result(0, corruption, 0)
	# Short delay then results
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

# --- Rendering ---

func _center_camera() -> void:
	var viewport_size := get_viewport_rect().size
	# Account for HUD at top (approx 80px) and DPad at bottom (approx 180px)
	var available_height := viewport_size.y - 260.0
	var available_width := viewport_size.x
	var grid_pixel_size := GRID_SIZE * TILE_SIZE
	var offset_x := (available_width - grid_pixel_size) / 2.0 - (player_pos.x - GRID_SIZE / 2) * TILE_SIZE
	var offset_y := 80.0 + (available_height - grid_pixel_size) / 2.0 - (player_pos.y - GRID_SIZE / 2) * TILE_SIZE
	grid_container.position = Vector2(offset_x, offset_y)

func _draw_grid() -> void:
	# This is called on grid_container
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1)
			var color: Color

			if not revealed[x][y]:
				color = Color.BLACK
			elif not tile_visible[x][y]:
				# Revealed but not currently visible — dim
				match grid[x][y]:
					Tile.WALL:
						color = Color(0.15, 0.15, 0.15)
					Tile.FLOOR:
						color = Color(0.3, 0.3, 0.3)
					Tile.EXIT:
						color = Color(0.4, 0.4, 0.1)
			else:
				match grid[x][y]:
					Tile.WALL:
						color = Color(0.25, 0.25, 0.25)
					Tile.FLOOR:
						color = Color(0.6, 0.6, 0.6)
					Tile.EXIT:
						color = Color(0.9, 0.9, 0.1)

			grid_container.draw_rect(rect, color)

	# Draw traps (only if visible or revealed)
	for trap_pos in traps:
		if tile_visible[trap_pos.x][trap_pos.y] or revealed[trap_pos.x][trap_pos.y]:
			var trap_color := Color(0.9, 0.7, 0.1) if tile_visible[trap_pos.x][trap_pos.y] else Color(0.5, 0.4, 0.1)
			var trap_rect := Rect2(trap_pos.x * TILE_SIZE + 6, trap_pos.y * TILE_SIZE + 6, TILE_SIZE - 13, TILE_SIZE - 13)
			grid_container.draw_rect(trap_rect, trap_color)

	# Draw creatures (visible, or all if scan active)
	for creature in creatures:
		if creature["hp"] <= 0:
			continue
		var pos: Vector2i = creature["pos"]
		if tile_visible[pos.x][pos.y]:
			var creature_color := Color(0.9, 0.2, 0.2)
			if creature.get("stunned_turns", 0) > 0:
				creature_color = Color(0.5, 0.5, 0.9)  # Blue tint for stunned
			# Flash override
			if _flashes.has(pos) and _flashes[pos]["timer"] > 0:
				creature_color = _flashes[pos]["color"]
			var rect := Rect2(pos.x * TILE_SIZE + 2, pos.y * TILE_SIZE + 2, TILE_SIZE - 5, TILE_SIZE - 5)
			grid_container.draw_rect(rect, creature_color)
			# Targeting mode: cyan border on visible creatures
			if targeting_mode and tile_visible[pos.x][pos.y]:
				var border_rect := Rect2(pos.x * TILE_SIZE + 2, pos.y * TILE_SIZE + 2, TILE_SIZE - 5, TILE_SIZE - 5)
				grid_container.draw_rect(border_rect, Color(0, 1, 1, 0.8), false, 2.0)

	# Draw player
	var player_color := Color(0.2, 0.6, 0.9) if stealth_active else Color(0.2, 0.9, 0.2)
	if _flashes.has(player_pos) and _flashes[player_pos]["timer"] > 0:
		player_color = _flashes[player_pos]["color"]
	var player_rect := Rect2(player_pos.x * TILE_SIZE + 2, player_pos.y * TILE_SIZE + 2, TILE_SIZE - 5, TILE_SIZE - 5)
	grid_container.draw_rect(player_rect, player_color)

func _update_hud() -> void:
	var contract := GameData.current_contract
	var inv_text := ""
	for i in 6:
		if i < inventory.size():
			inv_text += "[%d]%s " % [i + 1, inventory[i]["symbol"]]
		else:
			inv_text += "[%d]- " % [i + 1]
	var sc_text := "STEALTH" if stealth_active else "%d%%" % int(stealth_charge)
	hud_label.text = "HP: %d | Ammo: %d | SC: %s | Turn: %d | Corruption: %d\nTarget: %s (%d/%d) | %s" % [
		player_hp, sidearm_ammo, sc_text, turn_count, corruption,
		contract.get("creature_type", "?"), target_kills, target_total, inv_text.strip_edges()
	]
	# Refresh action bar buttons (rebuild dynamically)
	if _action_bar:
		for child in _action_bar.get_children():
			child.queue_free()
		var btn_count := mini(inventory.size(), 6)
		for i in btn_count:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(80, 60)
			btn.name = "ItemBtn%d" % i
			var item := inventory[i]
			var display_count: int = sidearm_ammo if item.get("id","") == "sidearm" else item.get("uses", 0)
			btn.text = "%s\n%s (%d)" % [item.get("symbol","?"), item.get("name","?"), display_count]
			btn.pressed.connect(_use_item.bind(i))
			_action_bar.add_child(btn)

func _update_hp_bar() -> void:
	if _hp_bar_fg:
		var ratio := clampf(float(player_hp) / 10.0, 0.0, 1.0)
		_hp_bar_fg.anchor_right = ratio

func _fire_sidearm(creature_idx: int) -> void:
	if sidearm_ammo <= 0:
		_show_message("Out of ammo!")
		targeting_mode = false
		grid_container.queue_redraw()
		return
	sidearm_ammo -= 1
	if stealth_active:
		_deactivate_stealth()
	var c := creatures[creature_idx]
	c["hp"] -= 3
	_gunshot_alert()
	if c["hp"] <= 0:
		if c["is_target"]:
			target_kills += 1
		_show_message("Bang! %s down!" % c["type"])
		_flashes[c["pos"]] = {color = Color.WHITE, timer = 0.3}
		_drop_ingredient(c["type"])
		_check_exit_spawn()
	else:
		_show_message("Bang! Hit %s! (%d HP left)" % [c["type"], c["hp"]])
		_flashes[c["pos"]] = {color = Color.YELLOW, timer = 0.2}
	targeting_mode = false
	grid_container.queue_redraw()
	_move_creatures()
	_update_visibility()
	_center_camera()
	_update_hud()

func _cancel_targeting() -> void:
	targeting_mode = false
	_show_message("Targeting cancelled.")
	grid_container.queue_redraw()

func _flash_vignette() -> void:
	if not _vignette:
		return
	_vignette.visible = true
	_vignette.color = Color(1, 0, 0, 0.3)
	var tween := create_tween()
	tween.tween_property(_vignette, "color:a", 0.0, 0.15)
	tween.tween_callback(func(): _vignette.visible = false)

func _gunshot_alert() -> void:
	var any_alerted := false
	for creature in creatures:
		if creature["hp"] <= 0:
			continue
		var cpos: Vector2i = creature["pos"]
		var dist := maxi(absi(cpos.x - player_pos.x), absi(cpos.y - player_pos.y))
		if dist <= 4:
			if not creature.get("alerted", false):
				creature["alerted"] = true
				creature["aggro_origin"] = cpos
			creature["alert_turns"] = 10
			any_alerted = true
	if any_alerted:
		_show_message("Gunshot echoes!")

func _tick_stealth() -> void:
	if stealth_active:
		stealth_charge -= 3.0
		if stealth_charge <= 0.0:
			_deactivate_stealth()
	else:
		if corruption < 16:
			stealth_charge = minf(stealth_charge + 5.0, STEALTH_MAX)
		elif corruption < 36:
			stealth_charge = minf(stealth_charge + 2.0, STEALTH_MAX)

func _deactivate_stealth() -> void:
	stealth_active = false
	stealth_charge = maxf(stealth_charge, 0.0)
	_show_message("Stealth field collapsed!")
	# Aggro nearby creatures with LOS
	for creature in creatures:
		if creature["hp"] <= 0:
			continue
		var cpos: Vector2i = creature["pos"]
		var stats: Dictionary = CREATURE_STATS.get(creature["type"], {detection = 4, leash = 8})
		var det: int = stats["detection"]
		var dist := maxi(absi(cpos.x - player_pos.x), absi(cpos.y - player_pos.y))
		if dist <= det and tile_visible[cpos.x][cpos.y]:
			creature["alerted"] = true
			if not creature.has("aggro_origin"):
				creature["aggro_origin"] = cpos

func _player_wait() -> void:
	if player_hp <= 0:
		return
	# Toggle stealth field
	if stealth_active:
		_deactivate_stealth()
	elif stealth_charge >= 10.0:
		stealth_charge -= 10.0
		stealth_active = true
		_show_message("Stealth field active!")
	else:
		_show_message("Stealth field depleted!")
	# Advance turn
	turn_count += 1
	_tick_stealth()
	_move_creatures()
	_update_visibility()
	_center_camera()
	queue_redraw()
	grid_container.queue_redraw()
	_update_hud()

func _toggle_inventory() -> void:
	inventory_open = not inventory_open
	_inv_layer.visible = inventory_open
	if inventory_open:
		_refresh_inventory_panel()

func _refresh_inventory_panel() -> void:
	# Clear existing rows
	for child in _inv_scroll_content.get_children():
		child.queue_free()
	# Build rows for each inventory item
	for i in inventory.size():
		var item: Dictionary = inventory[i]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var symbol_label := Label.new()
		symbol_label.text = item.get("symbol", "?")
		symbol_label.custom_minimum_size = Vector2(30, 0)
		row.add_child(symbol_label)

		var name_label := Label.new()
		var display_count: int = sidearm_ammo if item.get("id", "") == "sidearm" else item.get("uses", 0)
		name_label.text = "%s (%d)" % [item.get("name", "?"), display_count]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		# Use button — hide for ingredients
		var use_btn := Button.new()
		use_btn.text = "Use"
		use_btn.custom_minimum_size = Vector2(60, 40)
		if item.get("ingredient", false):
			use_btn.visible = false
		else:
			use_btn.pressed.connect(_inv_use_item.bind(i))
		row.add_child(use_btn)

		# Drop button — hide for sidearm
		var drop_btn := Button.new()
		drop_btn.text = "Drop"
		drop_btn.custom_minimum_size = Vector2(60, 40)
		if item.get("id", "") == "sidearm":
			drop_btn.visible = false
		else:
			drop_btn.pressed.connect(_inv_drop_item.bind(i))
		row.add_child(drop_btn)

		_inv_scroll_content.add_child(row)

	if inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_inv_scroll_content.add_child(empty_label)

func _inv_use_item(slot: int) -> void:
	_use_item(slot)
	if inventory_open:
		_refresh_inventory_panel()

func _inv_drop_item(slot: int) -> void:
	if slot < inventory.size():
		var item: Dictionary = inventory[slot]
		if item.get("id", "") == "sidearm":
			return  # Safety check
		inventory.remove_at(slot)
		_update_hud()
		_refresh_inventory_panel()

func _show_message(msg: String) -> void:
	message_label.text = msg
	# Auto-clear after a bit via tween
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		message_label.text = ""
		message_label.modulate.a = 1.0
	)
