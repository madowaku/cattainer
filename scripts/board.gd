class_name BoardModel
extends RefCounted

const FULL: int = 65535
var mask: int = FULL
var initial_mask: int = FULL
var history: Array[int] = []

static func cells_from_mask(value: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(4):
		for x: int in range(4):
			if value & (1 << (y * 4 + x)):
				cells.append(Vector2i(x, y))
	return cells

static func connected(value: int) -> bool:
	var cells: Array[Vector2i] = cells_from_mask(value)
	if cells.is_empty():
		return false
	var remaining: Array[Vector2i] = cells.duplicate()
	var queue: Array[Vector2i] = [remaining.pop_back()]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + direction
			if remaining.has(neighbor):
				remaining.erase(neighbor)
				queue.append(neighbor)
	return remaining.is_empty()

func toggle(index: int) -> bool:
	if index < 0 or index >= 16:
		return false
	var bit: int = 1 << index
	var proposed: int = mask ^ bit
	if mask & bit and not connected(proposed):
		return false
	history.append(mask)
	mask = proposed
	return true

func undo() -> bool:
	if history.is_empty():
		return false
	mask = history.pop_back()
	return true

func reset() -> void:
	mask = initial_mask
	history.clear()

func active_cells() -> Array[Vector2i]:
	return cells_from_mask(mask)

func count_cells() -> int:
	return active_cells().size()
