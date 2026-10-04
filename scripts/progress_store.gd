class_name ProgressStore
extends RefCounted

var highest_unlocked: int = 1
var best_counts: Dictionary = {}
var best_ranks: Dictionary = {}
var music_enabled: bool = true
var sfx_enabled: bool = true
var reduced_motion: bool = false
var save_path: String = "user://save.cfg"

func _init(path: String = "user://save.cfg") -> void:
	save_path = path
	var config: ConfigFile = ConfigFile.new()
	if config.load(save_path) == OK:
		highest_unlocked = clampi(int(config.get_value("progress", "highest_unlocked", 1)), 1, 10)
		best_counts = config.get_value("progress", "best_counts", {})
		best_ranks = config.get_value("progress", "best_ranks", {})
		music_enabled = bool(config.get_value("settings", "music", true))
		sfx_enabled = bool(config.get_value("settings", "sfx", true))
		reduced_motion = bool(config.get_value("settings", "reduced_motion", false))

func record(stage_id: String, count: int, rank: String) -> void:
	if rank == "FIT":
		return
	if not best_counts.has(stage_id) or count < int(best_counts[stage_id]):
		best_counts[stage_id] = count
		best_ranks[stage_id] = rank
	highest_unlocked = maxi(highest_unlocked, mini(int(stage_id) + 1, 10))
	save()

func save() -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "highest_unlocked", highest_unlocked)
	config.set_value("progress", "best_counts", best_counts)
	config.set_value("progress", "best_ranks", best_ranks)
	config.set_value("settings", "music", music_enabled)
	config.set_value("settings", "sfx", sfx_enabled)
	config.set_value("settings", "reduced_motion", reduced_motion)
	var result: Error = config.save(save_path)
	if result != OK:
		push_warning("Could not save progress: %s" % error_string(result))
	return result
