extends SceneTree
## Whole-project parse/load check, independent of any installed plugin.
var checked: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	for directory: String in ["res://scripts", "res://scenes", "res://tests", "res://tools", "res://assets/ui"]:
		_scan(directory)
	print(JSON.stringify({"checked": checked, "failed": failures, "ok": failures.is_empty()}))
	quit(0 if failures.is_empty() else 1)

func _scan(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		failures.append(path)
		return
	for file: String in directory.get_files():
		if file.get_extension() not in ["gd", "tscn", "tres", "gdshader"]:
			continue
		var resource_path: String = path.path_join(file)
		var resource: Resource = load(resource_path)
		checked += 1
		if resource == null:
			failures.append(resource_path)
		elif resource is PackedScene:
			var instance: Node = (resource as PackedScene).instantiate()
			if instance == null:
				failures.append(resource_path)
			else:
				instance.free()
	for subdirectory: String in directory.get_directories():
		_scan(path.path_join(subdirectory))
