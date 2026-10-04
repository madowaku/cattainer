extends Node
## Dedicated QA scene, isolated from the player's save file.
var game: CattainerGame
var mask: int = 383:
	set(value):
		mask = value
		if game != null:
			game.board.mask = value
			game._refresh(false)

func _ready() -> void:
	game = preload("res://scenes/game.tscn").instantiate() as CattainerGame
	game.name = "Game"
	game.progress = ProgressStore.new("user://cattainer_screenshots.cfg")
	game.progress.music_enabled = false
	game.progress.sfx_enabled = false
	add_child(game)
	game.select_stage(9, true)
	game.board.mask = mask
	game._refresh(false)
