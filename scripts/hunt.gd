extends Control

const GRID_SIZE := 15
const TILE_SIZE := 32
const VIEW_RADIUS := 5

enum Tile { WALL, FLOOR, EXIT }

# Grid data
var grid: Array = []  # 2D array of Tile
var revealed: Array = []  # 2D bool array — ever seen
var tile_visible: Array = []  # 2D bool array — currently in LOS

# Entities
var player_pos := Vector2i.ZERO
var player_hp := 10
var creatures: Array[Dictionary] = []  # {pos, hp, type, is_target}
var turn_count := 0
var corruption := 0
var target_kills := 0
var target_total := 0
var exit_spawned := false

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
	_connect_dpad()

func _connect_dpad() -> void:
	dpad_up.pressed.connect(_move.bind(Vector2i(0, -1)))
	dpad_down.pressed.connect(_move.bind(Vector2i(0, 1)))
	dpad_left.pressed.connect(_move.bind(Vector2i(-1, 0)))
	dpad_right.pressed.connect(_move.bind(Vector2i(1, 0)))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_move(Vector2i(0, -1))
	elif event.is_action_pressed("move_down"):
		_move(Vector2i(0, 1))
	elif event.is_action_pressed("move_left"):
		_move(Vector2i(-1, 0))
	elif event.is_action_pressed("move_right"):
		_move(Vector2i(1, 0))

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
		# Combat: player attacks creature
		creatures[hit_creature]["hp"] -= 1
		var c := creatures[hit_creature]
		if c["hp"] <= 0:
			if c["is_target"]:
				target_kills += 1
			_show_message("Killed %s!" % c["type"])
			_check_exit_spawn()
		else:
			_show_message("Hit %s! (%d HP left)" % [c["type"], c["hp"]])
		# Creature retaliates
		player_hp -= 1
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
	if turn_count % 5 == 0:
		corruption += 1

	# Creature AI
	_move_creatures()

	_update_visibility()
	_center_camera()
	grid_container.queue_redraw()
	_update_hud()

func _move_creatures() -> void:
	var directions := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for creature in creatures:
		if creature["hp"] <= 0:
			continue
		# Random walk
		directions.shuffle()
		for dir in directions:
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
				_show_message("%s attacks you! (%d HP)" % [creature["type"], player_hp])
				if player_hp <= 0:
					_show_message("You died!")
					_game_over()
					return
			else:
				creature["pos"] = new_pos
			break

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
	GameData.set_hunt_result(reward, corruption, 0)
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

	# Draw creatures (only if visible)
	for creature in creatures:
		if creature["hp"] <= 0:
			continue
		var pos: Vector2i = creature["pos"]
		if tile_visible[pos.x][pos.y]:
			var rect := Rect2(pos.x * TILE_SIZE + 2, pos.y * TILE_SIZE + 2, TILE_SIZE - 5, TILE_SIZE - 5)
			grid_container.draw_rect(rect, Color(0.9, 0.2, 0.2))

	# Draw player
	var player_rect := Rect2(player_pos.x * TILE_SIZE + 2, player_pos.y * TILE_SIZE + 2, TILE_SIZE - 5, TILE_SIZE - 5)
	grid_container.draw_rect(player_rect, Color(0.2, 0.9, 0.2))

func _update_hud() -> void:
	var contract := GameData.current_contract
	hud_label.text = "HP: %d | Turn: %d | Corruption: %d\nTarget: %s (%d/%d)" % [
		player_hp, turn_count, corruption,
		contract.get("creature_type", "?"), target_kills, target_total
	]

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
