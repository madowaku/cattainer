extends RefCounted

static func run() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var data: StageLoader = StageLoader.new()
	var verified: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/verification.json"))
	var seen: Dictionary = {}
	results.append({"test": "ten stages", "pass": data.stages.size() == 10})
	for i: int in range(data.stages.size()):
		var stage: Dictionary = data.stages[i]
		var id: String = stage["id"]
		results.append({"test": id + " unique ordered ID", "pass": not seen.has(id) and int(id) == i + 1})
		seen[id] = true
		var known_cats: bool = true
		for key: String in stage["cats"]:
			known_cats = known_cats and data.cats.has(key)
		results.append({"test": id + " cats exist", "pass": known_cats})
		results.append({"test": id + " verified minimum", "pass": int(stage["perfect_cells"]) == int(verified[i]["minimum"])})
		var witness: Array[Vector2i] = BoardModel.cells_from_mask(int(verified[i]["example_mask"]))
		for key: String in stage["cats"]:
			results.append({"test": id + " independent fit " + key, "pass": FitSolver.find_fit(witness, data.shape(key))["fits"]})
		for count: int in range(1, 17):
			var expected: String = "FIT"
			if count <= int(stage["perfect_cells"]):
				expected = "PERFECT"
			elif count <= int(stage["great_cells"]):
				expected = "GREAT"
			elif count <= int(stage["clear_cells"]):
				expected = "CLEAR"
			results.append({"test": "%s rank boundary %d" % [id, count], "pass": StageLoader.rank_for(stage, count) == expected})
	return results
