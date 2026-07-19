extends Node

@onready var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE := 6

var _sounds: Dictionary = {}

func _ready() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

	_load_if_exists("spawn", "res://assets/audio/sfx/confirmation_001.ogg")
	_load_if_exists("merge", "res://assets/audio/sfx/confirmation_001.ogg")
	_load_if_exists("destroy", "res://assets/audio/sfx/confirmation_001.ogg")
	_load_if_exists("freeze_break", "res://assets/audio/sfx/confirmation_001.ogg")
	_load_if_exists("void_fall", "res://assets/audio/sfx/confirmation_001.ogg")
	_load_if_exists("ui_click", "res://assets/audio/sfx/glitch_001.ogg")
	_load_if_exists("win", "res://assets/audio/sfx/confirmation_001.ogg")
	_load_if_exists("game_over", "res://assets/audio/sfx/confirmation_001.ogg")

func _load_if_exists(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_sounds[key] = load(path)

func _play(key: String) -> void:
	if not _sounds.has(key):
		return # sound not added yet — silently skip, no crash
	for player in _players:
		if not player.playing:
			player.stream = _sounds[key]
			player.play()
			return
	_players[0].stream = _sounds[key]
	_players[0].play()

func play_spawn() -> void: _play("spawn")
func play_merge() -> void: _play("merge")
func play_destroy() -> void: _play("destroy")
func play_freeze_break() -> void: _play("freeze_break")
func play_void_fall() -> void: _play("void_fall")
func play_ui_click() -> void: _play("ui_click")
func play_win() -> void: _play("win")
func play_game_over() -> void: _play("game_over")