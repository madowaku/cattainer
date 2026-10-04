class_name GameAudio
extends Node

var music: AudioStreamPlayer
var players: Array[AudioStreamPlayer] = []
var cursor: int = 0
var enabled: bool = true
var sounds: Dictionary = {}

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.volume_db = -20.0
	add_child(music)
	if ResourceLoader.exists("res://assets/audio/afternoon.res"):
		music.stream = load("res://assets/audio/afternoon.res")
	for key: String in ["cut", "restore", "bump", "fit", "perfect"]:
		sounds[key] = load("res://assets/audio/" + key + ".ogg")
	for i: int in range(5):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -13.0
		add_child(player)
		players.append(player)

func set_music(value: bool) -> void:
	# A headless logic run has no speaker; avoid starting dummy-driver playback.
	if DisplayServer.get_name() == "headless":
		return
	if value and music.stream != null:
		if not music.playing:
			music.play()
	else:
		music.stop()

func play(key: String) -> void:
	if not enabled or not sounds.has(key):
		return
	var player: AudioStreamPlayer = players[cursor]
	cursor = (cursor + 1) % players.size()
	player.stream = sounds[key]
	player.pitch_scale = 0.95 if key == "cut" else 1.0
	player.play()

func _exit_tree() -> void:
	# Release looping playback before the audio server tears down.
	if music != null:
		music.stop()
		music.stream = null
	for player: AudioStreamPlayer in players:
		player.stop()
		player.stream = null
	sounds.clear()
