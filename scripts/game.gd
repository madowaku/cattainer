class_name CattainerGame
extends Control
## Presentation controller; logical rules live in BoardModel / FitSolver.

signal test_finished(success: bool, rank: String)
const DEBUG_UNLOCK_ALL: bool = false
var data: StageLoader = StageLoader.new()
var board: BoardModel = BoardModel.new()
var progress: ProgressStore
var stage_index: int = 0
var busy: bool = false
var last_rank: String = ""
var cat_cards: Array[CatCard] = []
var board_view: BoardView
var audio: GameAudio
var feedback: UIFeedback
var overlay: ResultOverlay
var page: VBoxContainer
var stage_button: Button
var prev_button: Button
var next_button: Button
var undo_button: Button
var reset_button: Button
var test_button: Button
var settings_button: Button
var help_button: Button
var perfect_label: Label
var count_label: Label
var hint_label: Label
var best_label: Label
var cats_row: HBoxContainer
var rank_panels: Array[PanelContainer] = []
var rank_labels: Array[Label] = []
var qa_mode: bool = false

func _ready() -> void:
	qa_mode = OS.get_cmdline_user_args().has("--qa")
	if progress == null:
		progress = ProgressStore.new("user://qa_save.cfg" if qa_mode else "user://save.cfg")
	_build_ui()
	audio = GameAudio.new()
	add_child(audio)
	feedback = UIFeedback.new()
	feedback.top_level = true
	feedback.name = "PaperScraps"
	feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(feedback)
	feedback.hide()
	overlay = preload("res://scenes/result_overlay.tscn").instantiate() as ResultOverlay
	overlay.name = "Overlay"
	overlay.top_level = true
	add_child(overlay)
	overlay.next_pressed.connect(_next_stage)
	overlay.retry_pressed.connect(func() -> void: hint_label.text = "Try another shape. Every perfect box counts.")
	_apply_settings()
	select_stage(0)
	if qa_mode:
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--stage="):
				select_stage(int(argument.get_slice("=", 1)) - 1, true)
			if argument.begins_with("--mask="):
				board.mask = int(argument.get_slice("=", 1))
		_refresh(false)
	resized.connect(_resize_page)
	_resize_page()
	if qa_mode and OS.get_cmdline_user_args().has("--smoke"):
		call_deferred("_export_smoke")

func _export_smoke() -> void:
	# Runs from the exported executable itself; no external test scripts required.
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var music_playing: bool = audio.music.playing
	test_button.pressed.emit()
	await test_finished
	await get_tree().create_timer(0.3).timeout
	var passed: bool = last_rank == "PERFECT" and stage_index == 9 and progress.highest_unlocked == 10 and music_playing
	var result: Dictionary = {"passed": passed, "rank": last_rank, "stage": stage_index + 1, "cells": board.count_cells(), "cats": cat_cards.size(), "music_playing": music_playing, "unlocked": progress.highest_unlocked, "engine": Engine.get_version_info()["string"]}
	var evidence: FileAccess = FileAccess.open("user://export_smoke.json", FileAccess.WRITE)
	evidence.store_string(JSON.stringify(result, "\t"))
	evidence.close()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://export_smoke.png")
	print("EXPORTED_SMOKE ", JSON.stringify(result))
	get_tree().quit(0 if passed else 1)

func _build_ui() -> void:
	var background: TextureRect = TextureRect.new()
	background.name = "Room"
	background.texture = load("res://assets/ui/cozy_room.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.offset_top = -40
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.name = "Layout"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	page = VBoxContainer.new()
	page.name = "Page"
	page.custom_minimum_size.x = 328
	page.add_theme_constant_override("separation", 8)
	center.add_child(page)
	var header: VBoxContainer = VBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 6)
	page.add_child(header)
	var utility: HBoxContainer = HBoxContainer.new()
	header.add_child(utility)
	settings_button = _button("⚙", _show_settings, 34)
	settings_button.custom_minimum_size.x = 34
	settings_button.tooltip_text = "Music, sound and motion"
	utility.add_child(settings_button)
	var eyebrow: Label = _label("", 10)
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eyebrow.add_theme_color_override("font_color", Color("fff4dc"))
	eyebrow.add_theme_color_override("font_shadow_color", Color("654626"))
	eyebrow.add_theme_constant_override("shadow_offset_y", 1)
	utility.add_child(eyebrow)
	help_button = _button("?", _show_help, 34)
	help_button.custom_minimum_size.x = 34
	help_button.tooltip_text = "How to play / 遊び方"
	utility.add_child(help_button)
	var title: Label = _label("CATTAINER", 43)
	title.custom_minimum_size.y = 62
	title.add_theme_color_override("font_color", Color("512c18"))
	title.add_theme_color_override("font_shadow_color", Color("edc58d"))
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)
	var navigation: HBoxContainer = HBoxContainer.new()
	navigation.name = "Navigation"
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(navigation)
	prev_button = _button("‹", func() -> void: select_stage(stage_index - 1), 30)
	prev_button.custom_minimum_size.x = 34
	navigation.add_child(prev_button)
	stage_button = _button("STAGE 001  /  010", _show_stages, 30)
	stage_button.custom_minimum_size.x = 202
	navigation.add_child(stage_button)
	next_button = _button("›", func() -> void: select_stage(stage_index + 1), 30)
	next_button.custom_minimum_size.x = 34
	navigation.add_child(next_button)
	var paper: PanelContainer = PanelContainer.new()
	paper.name = "Paper"
	paper.add_theme_stylebox_override("panel", UIFeedback.panel_style(Color("fff0d7"), Color("e5c799"), 22))
	page.add_child(paper)
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Puzzle"
	column.add_theme_constant_override("separation", 6)
	paper.add_child(column)
	var objective: Label = _label("Make the smallest box for every cat.", 15)
	objective.custom_minimum_size.y = 26
	column.add_child(objective)
	var meta: HBoxContainer = HBoxContainer.new()
	meta.name = "Meta"
	column.add_child(meta)
	perfect_label = _label("PERFECT · 5 cells", 11)
	perfect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	perfect_label.add_theme_color_override("font_color", Color("a76a19"))
	meta.add_child(perfect_label)
	count_label = _label("16 cells", 11)
	meta.add_child(count_label)
	var board_center: CenterContainer = CenterContainer.new()
	board_center.name = "BoardSlot"
	column.add_child(board_center)
	board_view = BoardView.new()
	board_view.name = "Board"
	board_center.add_child(board_view)
	board_view.cell_clicked.connect(toggle_cell)
	cats_row = HBoxContainer.new()
	cats_row.name = "Cats"
	cats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cats_row.add_theme_constant_override("separation", 5)
	column.add_child(cats_row)
	var controls: HBoxContainer = HBoxContainer.new()
	controls.name = "Controls"
	controls.add_theme_constant_override("separation", 6)
	column.add_child(controls)
	undo_button = _button("↶ UNDO", undo, 44)
	undo_button.name = "Undo"
	undo_button.add_theme_font_size_override("font_size", 12)
	controls.add_child(undo_button)
	test_button = _button("▶ TEST", run_test, 49)
	test_button.name = "Test"
	test_button.add_theme_font_size_override("font_size", 23)
	test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var green: StyleBoxFlat = UIFeedback.panel_style(Color("478e4e"), Color("2c6637"), 20)
	test_button.add_theme_stylebox_override("normal", green)
	test_button.add_theme_stylebox_override("hover", UIFeedback.panel_style(Color("58a95f"), Color("306c3a"), 20))
	test_button.add_theme_stylebox_override("pressed", UIFeedback.panel_style(Color("33783d"), Color("245b2c"), 20))
	test_button.add_theme_stylebox_override("disabled", UIFeedback.panel_style(Color("8ea782"), Color("617b55"), 20))
	test_button.add_theme_color_override("font_color", Color("fffbe9"))
	test_button.add_theme_color_override("font_hover_color", Color("fffbe9"))
	test_button.add_theme_color_override("font_pressed_color", Color("fffbe9"))
	test_button.add_theme_color_override("font_focus_color", Color("fffbe9"))
	test_button.add_theme_color_override("font_disabled_color", Color("ebe6cd"))
	controls.add_child(test_button)
	reset_button = _button("⟳ RESET", reset, 44)
	reset_button.name = "Reset"
	reset_button.add_theme_font_size_override("font_size", 12)
	controls.add_child(reset_button)
	var ranks: HBoxContainer = HBoxContainer.new()
	ranks.name = "Ranks"
	ranks.add_theme_constant_override("separation", 4)
	column.add_child(ranks)
	for rank: String in ["CLEAR", "GREAT", "PERFECT"]:
		var rank_panel: PanelContainer = PanelContainer.new()
		rank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rank_panel.custom_minimum_size.y = 40
		ranks.add_child(rank_panel)
		var rank_label: Label = _label(rank, 11)
		rank_panel.add_child(rank_label)
		rank_panels.append(rank_panel)
		rank_labels.append(rank_label)
	hint_label = _label("Tap cardboard to cut. Tap again to restore.", 10)
	hint_label.name = "Hint"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size.y = 28
	column.add_child(hint_label)
	best_label = _label("Cats enter one at a time. Same box, every cat.", 10)
	best_label.add_theme_color_override("font_color", Color("fff5dc"))
	best_label.add_theme_color_override("font_shadow_color", Color("69452d"))
	best_label.add_theme_constant_override("shadow_offset_y", 1)
	page.add_child(best_label)

func _resize_page() -> void:
	page.custom_minimum_size.x = clampf(size.x - 32.0, 300.0, 380.0)

func _button(text_value: String, action: Callable, height: float) -> Button:
	var item: Button = Button.new()
	item.text = text_value
	item.custom_minimum_size.y = height
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(action)
	return item

func _label(text_value: String, font_size: int) -> Label:
	var item: Label = Label.new()
	item.text = text_value
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size", font_size)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func stage() -> Dictionary:
	return data.stages[stage_index]

func select_stage(index: int, force: bool = false) -> void:
	if busy or index < 0 or index >= data.stages.size():
		return
	if not force and not DEBUG_UNLOCK_ALL and index + 1 > progress.highest_unlocked:
		return
	stage_index = index
	board.initial_mask = int(stage().get("initial_mask", BoardModel.FULL))
	board.reset()
	last_rank = ""
	if overlay != null:
		overlay.hide()
	for child: Node in cats_row.get_children():
		cats_row.remove_child(child)
		child.queue_free()
	cat_cards.clear()
	for cat_id: String in stage()["cats"]:
		var card: CatCard = preload("res://scenes/cat_card.tscn").instantiate() as CatCard
		card.name = cat_id
		card.configure(cat_id, data.cats[cat_id], data.shape(cat_id))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cats_row.add_child(card)
		cat_cards.append(card)
	stage_button.text = "STAGE %s  /  010" % stage()["id"]
	perfect_label.text = "PERFECT · %d cells" % int(stage()["perfect_cells"])
	hint_label.text = "Tap cardboard to cut. Tap again to restore."
	_refresh(false)

func _refresh(animate: bool = true) -> void:
	board_view.refresh(board.mask, animate)
	count_label.text = "%d cells" % board.count_cells()
	var potential: String = StageLoader.rank_for(stage(), board.count_cells())
	for i: int in range(3):
		var rank: String = ["CLEAR", "GREAT", "PERFECT"][i]
		var key: String = rank.to_lower() + "_cells"
		rank_labels[i].text = "%s\n≤ %d cells" % [rank, int(stage()[key])]
		var fill: Color = Color("f5e1c1")
		var border: Color = Color("dec198")
		if rank == potential:
			fill = Color("ffe5a1") if rank == "PERFECT" else Color("e2e9c7")
			border = Color("d5a13e") if rank == "PERFECT" else Color("8ca069")
		rank_panels[i].add_theme_stylebox_override("panel", UIFeedback.panel_style(fill, border, 10, false))
	_set_busy(busy)
	var id: String = stage()["id"]
	best_label.text = "BEST · %s / %d cells" % [progress.best_ranks[id], int(progress.best_counts[id])] if progress.best_counts.has(id) else "Cats enter one at a time. Same box, every cat."

func _clear_results() -> void:
	last_rank = ""
	for card: CatCard in cat_cards:
		card.set_status("waiting")

func toggle_cell(index: int) -> void:
	if busy or overlay.visible:
		return
	var was_active: bool = bool(board.mask & (1 << index))
	if not board.toggle(index):
		board_view.cells[index].reject()
		audio.play("bump")
		hint_label.text = "Keep the box connected. No floating pieces."
		return
	_clear_results()
	_refresh()
	audio.play("cut" if was_active else "restore")
	if was_active:
		feedback.show()
		feedback.burst(board_view.cells[index].global_position + board_view.cells[index].size * 0.5, Color("bd8a51"), 7)
	hint_label.text = "Connect the restored piece before TEST." if not BoardModel.connected(board.mask) else "Fewer cells, happier cats. Press TEST when ready."

func undo() -> void:
	if busy or overlay.visible:
		return
	if board.undo():
		_clear_results()
		_refresh()
		audio.play("restore")
		hint_label.text = "One cut undone."

func reset() -> void:
	if busy or overlay.visible:
		return
	board.reset()
	_clear_results()
	_refresh()
	audio.play("restore")
	hint_label.text = "A fresh piece of cardboard."

func _set_busy(value: bool) -> void:
	busy = value
	board_view.set_locked(value)
	test_button.disabled = value
	test_button.text = "… TEST" if value else "▶ TEST"
	undo_button.disabled = value or board.history.is_empty()
	reset_button.disabled = value
	settings_button.disabled = value
	help_button.disabled = value
	stage_button.disabled = value
	prev_button.disabled = value or stage_index == 0
	next_button.disabled = value or stage_index == 9 or (not DEBUG_UNLOCK_ALL and stage_index + 2 > progress.highest_unlocked)
	cats_row.modulate.a = 1.0
	for panel: PanelContainer in rank_panels:
		panel.modulate.a = 0.7 if value else 1.0

func run_test() -> void:
	if busy or overlay.visible:
		return
	_clear_results()
	if not BoardModel.connected(board.mask):
		hint_label.text = "Connect every cardboard cell before TEST."
		audio.play("bump")
		test_finished.emit(false, "")
		return
	_set_busy(true)
	var active: Array[Vector2i] = board.active_cells()
	var all_fit: bool = true
	await get_tree().create_timer(0.08).timeout
	for card: CatCard in cat_cards:
		card.set_status("checking")
		hint_label.text = "%s is trying the box…" % card.cat_id
		var fit: Dictionary = FitSolver.find_fit(active, card.cat_shape)
		if fit["fits"]:
			var placed: Array[Vector2i] = fit["placed_cells"]
			board_view.show_placement(placed, card.tint, card.art_texture)
			hint_label.text = "%s · %d° rotation · FIT!" % [card.cat_id, int(fit["rotation"])]
			await get_tree().create_timer(0.54 if not progress.reduced_motion else 0.3).timeout
			card.set_status("fit")
			audio.play("fit")
			board_view.clear_placement()
			await get_tree().create_timer(0.08).timeout
		else:
			card.set_status("fail")
			audio.play("bump")
			board_view.cells[0].reject()
			hint_label.text = "%s needs a different shape. Restore a cell and try again." % card.cat_id
			await get_tree().create_timer(0.4).timeout
			all_fit = false
			break
	_set_busy(false)
	if all_fit:
		last_rank = StageLoader.rank_for(stage(), board.count_cells())
		if last_rank == "FIT":
			hint_label.text = "ALL CATS FIT! Make the box smaller."
		else:
			progress.record(stage()["id"], board.count_cells(), last_rank)
			_refresh(false)
			hint_label.text = "Every cat fits. Your tiny box is ready!"
			audio.play("perfect")
			overlay.present(last_rank, board.count_cells(), stage_index == 9, cat_cards[0].art_texture)
	test_finished.emit(all_fit, last_rank)

func _next_stage() -> void:
	if stage_index == 9:
		_show_stages()
	else:
		select_stage(stage_index + 1)

func _apply_settings() -> void:
	audio.enabled = progress.sfx_enabled
	audio.set_music(progress.music_enabled)
	feedback.reduced_motion = progress.reduced_motion
	board_view.reduced_motion = progress.reduced_motion
	overlay.reduced_motion = progress.reduced_motion

func _show_help() -> void:
	if busy:
		return
	overlay.begin()
	overlay.label("ONE BOX, EVERY CAT", 22)
	overlay.label("1. Tap cardboard to cut it away.\nTap an empty cell to restore it.\n\n2. Keep your box connected.\n\n3. TEST each cat, one at a time.\nCats can turn, but cannot mirror.\n\n4. Trim to the rank target to clear.", 14)
	overlay.label("ねこは1匹ずつ、同じ箱に入ります。\nマスを減らして小さな箱を作ろう。\n回転はOK。裏返しはできません。", 12)
	overlay.label("SPACE · test   /   Ctrl+Z · undo\nR · reset   /   Esc · close", 11)
	overlay.button("LET’S MAKE A BOX", overlay.hide).grab_focus()

func _show_settings() -> void:
	if busy:
		return
	var content: VBoxContainer = overlay.begin()
	overlay.label("A QUIET LITTLE CORNER", 21)
	for setting: String in ["music_enabled", "sfx_enabled", "reduced_motion"]:
		var toggle: CheckButton = CheckButton.new()
		toggle.text = {"music_enabled": "Music", "sfx_enabled": "Sound effects", "reduced_motion": "Reduced motion"}[setting]
		toggle.button_pressed = bool(progress.get(setting))
		toggle.toggled.connect(func(value: bool) -> void: progress.set(setting, value); progress.save(); _apply_settings())
		content.add_child(toggle)
	overlay.label("Music · 昼下がり気分 / KK\nOpenTracks · commercial game use\nSFX · Kenney / CC0\nArt · Imagegen", 11)
	overlay.button("BACK TO THE BOX", overlay.hide).grab_focus()

func _show_stages() -> void:
	if busy:
		return
	var content: VBoxContainer = overlay.begin()
	overlay.label("TEN LITTLE BOXES", 23)
	overlay.label("%d / 10 stages cleared" % progress.best_counts.size(), 12)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	content.add_child(grid)
	for i: int in range(10):
		var id: String = data.stages[i]["id"]
		var item: Button = _button(id + "  " + str(progress.best_ranks.get(id, "—")), func() -> void: select_stage(i), 37)
		item.add_theme_font_size_override("font_size", 12)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.disabled = not DEBUG_UNLOCK_ALL and i + 1 > progress.highest_unlocked
		grid.add_child(item)
	overlay.button("BACK", overlay.hide).grab_focus()

func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		if overlay.visible:
			overlay.hide()
		get_viewport().set_input_as_handled()
		return
	if busy or overlay.visible:
		return
	if key.keycode == KEY_SPACE:
		# Let focused UI buttons receive their normal Space activation.
		# Board cells deliberately keep Space as the global TEST shortcut.
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused is BaseButton and not (focused is BoardCell):
			return
		run_test()
	elif key.keycode == KEY_Z and key.ctrl_pressed:
		undo()
	elif key.keycode == KEY_R:
		reset()
	else:
		return
	get_viewport().set_input_as_handled()
