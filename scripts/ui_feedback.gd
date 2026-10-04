class_name UIFeedback
extends Control
## Short, deterministic paper scraps and golden celebration marks.

var particles: Array[Dictionary] = []
var clock_time: float = 0.0
var reduced_motion: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func burst(origin: Vector2, tint: Color, amount: int = 8) -> void:
	if reduced_motion:
		return
	for i: int in range(amount):
		var angle: float = float(i) * TAU / float(amount) - 1.2
		particles.append({"origin": origin, "velocity": Vector2(cos(angle), sin(angle)) * (24.0 + float(i % 4) * 12.0), "time": clock_time, "tint": tint, "angle": angle})

func celebrate() -> void:
	for i: int in range(5):
		burst(Vector2(size.x * (0.2 + float(i) * 0.15), size.y * 0.4), Color("e9b440"), 9)

func _process(delta: float) -> void:
	clock_time += delta
	var had_particles: bool = not particles.is_empty()
	particles = particles.filter(func(p: Dictionary) -> bool: return clock_time - float(p["time"]) < 0.85)
	if had_particles:
		queue_redraw()

func _draw() -> void:
	for particle: Dictionary in particles:
		var age: float = clock_time - float(particle["time"])
		var point: Vector2 = particle["origin"] + particle["velocity"] * age + Vector2(0, 55.0 * age * age)
		var tint: Color = particle["tint"]
		tint.a = 1.0 - age / 0.85
		draw_set_transform(point, age * 3.0 + float(particle["angle"]))
		draw_rect(Rect2(-2, -2, 4, 4), tint)
	draw_set_transform(Vector2.ZERO)

static func panel_style(fill: Color, border: Color, radius: int = 16, shadow: bool = true) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.border_width_bottom = 2
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	if shadow:
		box.shadow_color = Color(0.2, 0.1, 0.04, 0.16)
		box.shadow_size = 5
		box.shadow_offset = Vector2(0, 3)
	return box
