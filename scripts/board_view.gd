class_name BoardView
extends Control

signal cell_clicked(index: int)
var cells: Array[BoardCell] = []
var locked: bool = false
var cat_layer: Control
var reduced_motion: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(264, 264)
	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Inner"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 9)
	add_child(margin)
	var grid: GridContainer = GridContainer.new()
	grid.name = "Grid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	margin.add_child(grid)
	for i: int in range(16):
		var cell: BoardCell = preload("res://scenes/board_cell.tscn").instantiate() as BoardCell
		cell.name = "Cell%02d" % i
		cell.index = i
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.pressed.connect(func() -> void: if not locked: cell_clicked.emit(i))
		grid.add_child(cell)
		cells.append(cell)
	cat_layer = Panel.new()
	(cat_layer as Panel).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cat_layer.name = "CatPlacement"
	cat_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cat_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cat_layer)

func _draw() -> void:
	draw_style_box(UIFeedback.panel_style(Color("be8a53"), Color("815432"), 12), Rect2(Vector2.ZERO, size))
	for i: int in range(int(size.x / 4.0)):
		draw_line(Vector2(5 + i * 4, 3), Vector2(5 + i * 4, 7), Color("ecc492"), 1.0)

func refresh(mask: int, animate: bool = true) -> void:
	for i: int in range(16):
		cells[i].reduced_motion = reduced_motion
		cells[i].set_active(bool(mask & (1 << i)), animate)
		cells[i].highlight = Color.TRANSPARENT

func set_locked(value: bool) -> void:
	locked = value
	for cell: BoardCell in cells:
		cell.disabled = value

func show_placement(placed: Array[Vector2i], tint: Color, texture: Texture2D) -> void:
	clear_placement()
	var bounds: Rect2 = Rect2()
	for grid_cell: Vector2i in placed:
		var cell: BoardCell = cells[grid_cell.y * 4 + grid_cell.x]
		cell.highlight = Color(tint, 0.66)
		cell.queue_redraw()
		var rect: Rect2 = Rect2(cell.global_position - global_position, cell.size)
		bounds = rect if bounds.size == Vector2.ZERO else bounds.merge(rect)
	var art: TextureRect = TextureRect.new()
	art.name = "VisitingCat"
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = bounds.position
	art.size = bounds.size
	art.modulate.a = 0.9
	cat_layer.add_child(art)
	art.pivot_offset = art.size * 0.5
	if not reduced_motion:
		art.position.y -= 16
		art.scale = Vector2(0.75, 0.75)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(art, "position", bounds.position, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(art, "scale", Vector2.ONE, 0.27).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func clear_placement() -> void:
	for child: Node in cat_layer.get_children():
		child.queue_free()
	for cell: BoardCell in cells:
		cell.highlight = Color.TRANSPARENT
		cell.queue_redraw()
