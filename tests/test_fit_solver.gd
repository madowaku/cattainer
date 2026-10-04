extends RefCounted

static func run() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var data: StageLoader = StageLoader.new()
	var loaf: Array[Vector2i] = data.shape("LOAF")
	var exact: Dictionary = FitSolver.find_fit(loaf, loaf)
	results.append({"test": "exact match", "pass": exact["fits"] and exact["rotation"] == 0})
	var rotated: Array[Vector2i] = FitSolver.rotations(loaf)[1]["cells"]
	var fit: Dictionary = FitSolver.find_fit(rotated, loaf)
	results.append({"test": "rotation 90", "pass": fit["fits"] and fit["rotation"] == 90})
	var tiny: Array[Vector2i] = [Vector2i.ZERO]
	results.append({"test": "no fit", "pass": not FitSolver.find_fit(tiny, loaf)["fits"]})
	var mirror: Array[Vector2i] = []
	for cell: Vector2i in loaf:
		mirror.append(Vector2i(-cell.x, cell.y))
	mirror = FitSolver.normalize(mirror)
	results.append({"test": "reflection rejected", "pass": not FitSolver.find_fit(mirror, loaf)["fits"]})
	var full: Dictionary = FitSolver.find_fit(BoardModel.cells_from_mask(65535), loaf)
	results.append({"test": "first placement deterministic", "pass": full["rotation"] == 0 and full["offset"] == Vector2i.ZERO and full["placed_cells"] == FitSolver.normalize(loaf)})
	for cat_id: String in data.cats:
		var shape: Array[Vector2i] = data.shape(cat_id)
		for orientation: Dictionary in FitSolver.rotations(shape):
			var placed: Array[Vector2i] = orientation["cells"]
			results.append({"test": "%s rotation %d" % [cat_id, int(orientation["rotation"])], "pass": FitSolver.find_fit(placed, shape)["fits"]})
	return results
