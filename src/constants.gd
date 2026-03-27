class_name Constants
extends RefCounted

# These constants aren't totally necessary but are really convenient to work with.

const TILE_SIZE: int = 16
const HALF_TILE_SIZE: int = int(TILE_SIZE / 2.0)
const TILE_SIZE_VEC2I: Vector2i = Vector2i(TILE_SIZE, TILE_SIZE)
const HALF_TILE_SIZE_VEC2I: Vector2i = Vector2i(HALF_TILE_SIZE, HALF_TILE_SIZE)
const TILE_SIZE_VEC2: Vector2 = Vector2(TILE_SIZE, TILE_SIZE)
const HALF_TILE_SIZE_VEC2: Vector2 = Vector2(HALF_TILE_SIZE, HALF_TILE_SIZE)

# Trap kit constants (Phase A — upgradeable via Tactician rep later)
const TRAP_CHARGES_BASE: int = 3
const TRAP_RECHARGE_TIME: float = 25.0
const TRAP_RADIUS: float = 80.0
const TRAP_MAX_ACTIVE: int = 3
const TRAP_DECAY_TIME: float = 60.0
const TRAP_DAMAGE: int = 25
const TRAP_SLOW_DURATION: float = 2.0
