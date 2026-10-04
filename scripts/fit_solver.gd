class_name FitSolver
extends RefCounted
## Pure, deterministic polyomino placement. Reflections are never generated.

static func normalize(cells: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var origin: Vector2i = Vector2i(10000, 10000)
	for cell: Vector2i in cells:
		origin.x = mini(origin.x, cell.x)
		origin.y = mini(origin.y, cell.y)
	for cell: Vector2i in cells:
		result.append(cell - origin)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return result

static func rotations(cells: Array[Vector2i]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Array[String] = []
	var current: Array[Vector2i] = cells.duplicate()
	for turn: int in range(4):
		var normalized: Array[Vector2i] = normalize(current)
		var signature: String = str(normalized)
		if not seen.has(signature):
			seen.append(signature)
			result.append({"rotation": turn * 90, "cells": normalized})
		var rotated: Array[Vector2i] = []
		for cell: Vector2i in current:
			rotated.append(Vector2i(-cell.y, cell.x))
		current = rotated
	return result

static func find_fit(active: Array[Vector2i], cat: Array[Vector2i], width: int = 4, height: int = 4) -> Dictionary:
	if cat.is_empty() or active.size() < cat.size():
		return {"fits": false}
	var occupied: Dictionary = {}
	for cell: Vector2i in active:
		occupied[cell] = true
	for orientation: Dictionary in rotations(cat):
		var cells: Array[Vector2i] = orientation["cells"]
		var extent: Vector2i = Vector2i.ZERO
		for cell: Vector2i in cells:
			extent.x = maxi(extent.x, cell.x + 1)
			extent.y = maxi(extent.y, cell.y + 1)
		for y: int in range(height - extent.y + 1):
			for x: int in range(width - extent.x + 1):
				var placed: Array[Vector2i] = []
				var valid: bool = true
				for cell: Vector2i in cells:
					var target: Vector2i = cell + Vector2i(x, y)
					if not occupied.has(target):
						valid = false
						break
					placed.append(target)
				if valid:
					return {"fits": true, "rotation": orientation["rotation"], "offset": Vector2i(x, y), "placed_cells": placed}
	return {"fits": false}
