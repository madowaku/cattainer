extends RefCounted

static func run() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var model: BoardModel = BoardModel.new()
	results.append({"test": "remove edge", "pass": model.toggle(0) and model.count_cells() == 15})
	results.append({"test": "undo exact state", "pass": model.undo() and model.mask == BoardModel.FULL})
	model.mask = 7
	results.append({"test": "reject articulation", "pass": not model.toggle(1) and model.mask == 7 and model.history.is_empty()})
	model.mask = 1
	results.append({"test": "reject empty", "pass": not model.toggle(0) and model.mask == 1})
	results.append({"test": "restore always allowed", "pass": model.toggle(15) and model.mask == 32769})
	results.append({"test": "island is not testable", "pass": not BoardModel.connected(model.mask)})
	results.append({"test": "diagonal is disconnected", "pass": not BoardModel.connected(33)})
	model.reset()
	results.append({"test": "reset clears history", "pass": model.mask == BoardModel.FULL and model.history.is_empty()})
	results.append({"test": "invalid index rejected", "pass": not model.toggle(-1) and not model.toggle(16)})
	return results
