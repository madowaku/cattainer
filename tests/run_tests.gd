extends SceneTree

var passed: int = 0
var failed: int = 0
var checks: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func check(title: String, value: bool) -> void:
	checks.append({"test": title, "pass": value})
	if value:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", title)

func _run() -> void:
	for script: Script in [preload("res://tests/test_fit_solver.gd"), preload("res://tests/test_board_rules.gd"), preload("res://tests/test_stage_data.gd")]:
		for result: Dictionary in script.run():
			check(result["test"], result["pass"])
	var test_path: String = "user://cattainer_automated_tests.cfg"
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)
	var game: CattainerGame = preload("res://scenes/game.tscn").instantiate() as CattainerGame
	game.progress = ProgressStore.new(test_path)
	game.progress.music_enabled = false
	game.progress.sfx_enabled = false
	root.size = Vector2i(360, 800)
	root.add_child(game)
	await process_frame
	await process_frame
	check("new save stage 001 only", game.progress.highest_unlocked == 1)
	game.select_stage(9)
	check("locked stage cannot be selected", game.stage_index == 0)
	await game.run_test()
	check("16 cells FIT does not clear", game.last_rank == "FIT" and game.progress.highest_unlocked == 1 and not game.overlay.visible)
	game.board.mask = 7
	game._refresh(false)
	game.toggle_cell(1)
	check("UI rejects disconnect", game.board.mask == 7)
	game.board.mask = 1
	game._refresh(false)
	await game.run_test()
	check("failed cat stops test and unlocks input", game.cat_cards[0].status == "fail" and not game.busy and game.last_rank == "")
	game.toggle_cell(15)
	await game.run_test()
	check("island restore does not bypass connectivity", game.board.mask == 32769 and game.last_rank == "" and not game.busy)
	game.reset_button.pressed.emit()
	game.board_view.cells[0].pressed.emit()
	check("cell signal changes board", game.board.count_cells() == 15)
	game.undo_button.pressed.emit()
	check("undo button restores state", game.board.mask == 65535)
	game.board_view.cells[0].pressed.emit()
	game.reset_button.pressed.emit()
	check("reset button restores initial state", game.board.mask == 65535 and game.board.history.is_empty())
	game.board_view.cells[0].grab_focus()
	var space: InputEventKey = InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await process_frame
	check("SPACE tests even when a board cell has focus", game.busy and game.board.mask == 65535)
	await game.test_finished
	check("keyboard TEST follows the normal FIT path", game.last_rank == "FIT")
	for rank_case: Dictionary in [{"mask": 119, "rank": "GREAT"}, {"mask": 383, "rank": "CLEAR"}]:
		game.board.mask = rank_case["mask"]
		game._refresh(false)
		await game.run_test()
		check("runtime " + str(rank_case["rank"]) + " rank", game.last_rank == rank_case["rank"] and game.overlay.visible)
		game.overlay.hide()
	# Drive each real stage through accepted UI edits and its asynchronous TEST.
	var verified: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/verification.json"))
	for i: int in range(10):
		game.select_stage(i)
		check("progress reaches %03d" % (i + 1), game.stage_index == i)
		var target: int = int(verified[i]["example_mask"])
		var safety: int = 32
		while game.board.mask != target and safety > 0:
			var changed: bool = false
			for cell: int in range(16):
				if game.board.mask & (1 << cell) and not target & (1 << cell) and BoardModel.connected(game.board.mask ^ (1 << cell)):
					game.board_view.cells[cell].pressed.emit()
					changed = true
					break
			if not changed:
				break
			safety -= 1
		check("stage %03d editable optimal shape" % (i + 1), game.board.mask == target)
		var undo_depth: int = game.board.history.size()
		game.test_button.pressed.emit()
		await process_frame
		check("stage %03d locks input during test" % (i + 1), game.busy and game.board_view.locked)
		game.toggle_cell(15)
		game.undo()
		game.reset()
		check("busy edits cannot mutate shape", game.board.mask == target)
		await game.test_finished
		check("stage %03d PERFECT" % (i + 1), game.last_rank == "PERFECT" and game.overlay.visible)
		check("TEST adds no undo state", game.board.history.size() == undo_depth)
		var all_fit: bool = true
		for card: CatCard in game.cat_cards:
			all_fit = all_fit and card.status == "fit"
		check("all cats independently checked", all_fit)
		check("progress saved", game.progress.best_counts.has("%03d" % (i + 1)))
		game.overlay.hide()
	var restored: ProgressStore = ProgressStore.new(test_path)
	check("save reload restores 10 stages", restored.highest_unlocked == 10 and restored.best_counts.size() == 10)
	restored.record("001", 8, "CLEAR")
	check("worse replay preserves best", int(restored.best_counts["001"]) == 5 and restored.best_ranks["001"] == "PERFECT")
	game.select_stage(0)
	await process_frame
	await process_frame
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.position = game.board_view.cells[0].global_position + game.board_view.cells[0].size * 0.5
	touch.index = 0
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	touch = touch.duplicate() as InputEventScreenTouch
	touch.pressed = false
	Input.parse_input_event(touch)
	await process_frame
	check("touch emulation toggles cardboard", game.board.count_cells() == 15)
	game.progress.reduced_motion = true
	game._apply_settings()
	game.progress.save()
	check("motion preference persists", ProgressStore.new(test_path).reduced_motion)
	var music: AudioStreamMP3 = load("res://assets/audio/afternoon.res") as AudioStreamMP3
	check("commercial music loaded and loops", music != null and music.loop and music.get_length() > 200.0)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(test_path)
	print("CATTAINER tests: ", passed, " passed, ", failed, " failed")
	var evidence: FileAccess = FileAccess.open("res://docs/qa/test_results.json", FileAccess.WRITE)
	evidence.store_string(JSON.stringify({"passed": passed, "failed": failed, "checks": checks}, "\t"))
	evidence.close()
	quit(0 if failed == 0 else 1)
