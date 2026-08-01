extends Node
class_name AudioDirector

const MUSIC := {
	"pharmacy": "res://assets/audio/music/pharmacy-ambient.ogg",
	"childhood": "res://assets/audio/music/childhood-ambient.ogg"
}

const MUSIC_VOLUME := {
	"pharmacy": -31.0,
	"childhood": -29.0
}

const SFX := {
	"ui_click": "res://assets/audio/sfx/ui-click.ogg",
	"ui_back": "res://assets/audio/sfx/ui-back.ogg",
	"room_turn": "res://assets/audio/sfx/room-turn.ogg",
	"item_pickup": "res://assets/audio/sfx/item-pickup.ogg",
	"paper_pickup": "res://assets/audio/sfx/paper-pickup.ogg",
	"book_open": "res://assets/audio/sfx/book-open.ogg",
	"page_turn": "res://assets/audio/sfx/page-turn.ogg",
	"drawer_open": "res://assets/audio/sfx/drawer-open.ogg",
	"wardrobe_open": "res://assets/audio/sfx/wardrobe-open.ogg",
	"sewing": "res://assets/audio/sfx/sewing.ogg",
	"soft_place": "res://assets/audio/sfx/soft-place.ogg",
	"wood_connect": "res://assets/audio/sfx/wood-connect.ogg",
	"train_run": "res://assets/audio/sfx/train-run.ogg",
	"metal_click": "res://assets/audio/sfx/metal-click.ogg",
	"lock_latch": "res://assets/audio/sfx/lock-latch.ogg",
	"door_open": "res://assets/audio/sfx/door-open.ogg",
	"keypad_tick": "res://assets/audio/sfx/keypad-tick.ogg",
	"tv_button": "res://assets/audio/sfx/tv-button.ogg",
	"combine": "res://assets/audio/sfx/combine.ogg",
	"crystal": "res://assets/audio/sfx/crystal.ogg",
	"potion": "res://assets/audio/sfx/potion.ogg",
	"error": "res://assets/audio/sfx/error.ogg"
}

const SFX_COOLDOWN_MSEC := {
	"room_turn": 160
}

var music_enabled := true
var sfx_enabled := true
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music_key := ""
var requested_music_key := ""
var music_tween: Tween
var last_sfx_time_msec: Dictionary = {}


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "AmbientMusic"
	add_child(music_player)
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%02d" % index
		add_child(player)
		sfx_players.append(player)


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		music_player.stop()
	elif not requested_music_key.is_empty():
		_start_music(requested_music_key)


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if not enabled:
		for player in sfx_players:
			player.stop()


func set_place(place: String) -> void:
	var next_key := place if MUSIC.has(place) else ""
	requested_music_key = next_key
	if next_key == current_music_key:
		return
	if music_tween != null and music_tween.is_running():
		music_tween.kill()
	if music_player.playing:
		music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", -48.0, 0.55)
		music_tween.tween_callback(_start_music.bind(next_key))
	else:
		_start_music(next_key)


func _start_music(key: String) -> void:
	current_music_key = key
	music_player.stop()
	if key.is_empty() or not music_enabled:
		return
	var stream := load(str(MUSIC[key])) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		(stream as AudioStreamOggVorbis).loop = true
	music_player.stream = stream
	music_player.volume_db = -48.0
	music_player.play()
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", float(MUSIC_VOLUME[key]), 1.4)


func play_sfx(key: String, volume_offset_db: float = 0.0, vary_pitch: bool = true) -> void:
	if not sfx_enabled or not SFX.has(key):
		return
	var now_msec := Time.get_ticks_msec()
	var cooldown_msec := int(SFX_COOLDOWN_MSEC.get(key, 0))
	if cooldown_msec > 0 and now_msec - int(last_sfx_time_msec.get(key, -cooldown_msec)) < cooldown_msec:
		return
	last_sfx_time_msec[key] = now_msec
	var player := _available_sfx_player()
	player.stream = load(str(SFX[key])) as AudioStream
	player.volume_db = -10.0 + volume_offset_db
	player.pitch_scale = randf_range(0.97, 1.03) if vary_pitch else 1.0
	player.play()


func play_sfx_after(key: String, delay: float, volume_offset_db: float = 0.0) -> void:
	if not sfx_enabled:
		return
	await get_tree().create_timer(delay).timeout
	play_sfx(key, volume_offset_db, false)


func _available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]
