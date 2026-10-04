extends SceneTree
## Convert the single downloaded track into a non-standalone Godot resource.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		quit(1)
		return
	var stream: AudioStreamMP3 = AudioStreamMP3.new()
	stream.data = FileAccess.get_file_as_bytes(args[0])
	stream.loop = true
	var result: Error = ResourceSaver.save(stream, "res://assets/audio/afternoon.res", ResourceSaver.FLAG_COMPRESS)
	print("Music conversion: ", error_string(result), " duration=", stream.get_length())
	quit(0 if result == OK and stream.get_length() > 200.0 else 1)
