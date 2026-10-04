class_name CatCard
extends PanelContainer

var cat_id: String = ""
var cat_shape: Array[Vector2i] = []
var tint: Color = Color.WHITE
var art_texture: Texture2D
var status_label: Label
var art: TextureRect
var status: String = "waiting"

func configure(id: String, info: Dictionary, shape: Array[Vector2i]) -> void:
	cat_id = id
	cat_shape = shape
	tint = Color(info["color"])
	var atlas: Texture2D = load("res://assets/cats/cat_atlas.png")
	var sprite: AtlasTexture = AtlasTexture.new()
	sprite.atlas = atlas
	var atlas_index: int = int(info["atlas_index"])
	# Tight source rectangles keep neighboring whiskers out of each sprite.
	var regions: Array[Rect2] = [Rect2(90, 80, 600, 400), Rect2(710, 140, 810, 340), Rect2(60, 525, 740, 470), Rect2(850, 500, 650, 500)]
	sprite.region = regions[atlas_index]
	art_texture = sprite

func _ready() -> void:
	custom_minimum_size = Vector2(64, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UIFeedback.panel_style(Color("fff1d8"), Color("dcb889"), 12))
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	add_child(column)
	art = TextureRect.new()
	art.texture = art_texture
	art.custom_minimum_size = Vector2(0, 37)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(art)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 10)
	column.add_child(status_label)
	var diagram: Control = Control.new()
	diagram.custom_minimum_size = Vector2(0, 12)
	diagram.draw.connect(func() -> void: _draw_shape(diagram))
	column.add_child(diagram)
	set_status("waiting")

func _draw_shape(diagram: Control) -> void:
	var normalized: Array[Vector2i] = FitSolver.normalize(cat_shape)
	var extent: Vector2 = Vector2.ZERO
	for cell: Vector2i in normalized:
		extent = extent.max(Vector2(cell) + Vector2.ONE)
	var unit: float = minf(4.0, 12.0 / extent.y)
	var origin: Vector2 = Vector2((diagram.size.x - extent.x * unit) * 0.5, 0)
	for cell: Vector2i in normalized:
		diagram.draw_rect(Rect2(origin + Vector2(cell) * unit, Vector2.ONE * (unit - 0.7)), Color("926d48"))

func set_status(value: String) -> void:
	status = value
	var mark: String = {"waiting": "", "checking": " …", "fit": " ✓", "fail": " ×"}[value]
	status_label.text = cat_id + mark
	var fill: Color = Color("fff1d8")
	var border: Color = Color("dcb889")
	if value == "checking":
		fill = Color("ffe7a6")
		border = Color("d2a042")
	elif value == "fit":
		fill = Color("e8efce")
		border = Color("86a266")
	elif value == "fail":
		fill = Color("f6d8c3")
		border = Color("c57b61")
	add_theme_stylebox_override("panel", UIFeedback.panel_style(fill, border, 12))
