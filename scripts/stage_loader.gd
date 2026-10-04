class_name StageLoader
extends RefCounted

var cats: Dictionary = {}
var stages: Array = []

func _init() -> void:
	cats = JSON.parse_string(FileAccess.get_file_as_string("res://data/cats.json"))
	stages = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages.json"))

func shape(cat_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pair: Array in cats[cat_id]["cells"]:
		result.append(Vector2i(int(pair[0]), int(pair[1])))
	return result

static func rank_for(stage: Dictionary, count: int) -> String:
	if count <= int(stage["perfect_cells"]):
		return "PERFECT"
	if count <= int(stage["great_cells"]):
		return "GREAT"
	if count <= int(stage["clear_cells"]):
		return "CLEAR"
	return "FIT"
