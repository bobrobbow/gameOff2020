extends Node

export var initial_zoom_level: int = 3
export var quiet_volumn_db:int = -48
export var no_music := false

var _tween: Tween
var _stream_length: float
var _current_position: float
var _original_sound_fx_volume_db := {}


func _ready():
	SignalMgr.register_subscriber(self, "zoom_step_change_initiated", "_on_zoom_step_change_initiated")
	_tween = Tween.new()
	add_child(_tween)
	#start music and get it's stream length
	var initial_zoom_level_audio_player := _get_zoom_level_music_audio_stream_player(initial_zoom_level)
	if !initial_zoom_level_audio_player.autoplay && !no_music:
		initial_zoom_level_audio_player.play()
	_stream_length = initial_zoom_level_audio_player.stream.get_length()
	
	#start sound fx sounds
	var initial_zoom_level_fx_parent_node = _get_zoom_level_parent_node(initial_zoom_level, false)
	if initial_zoom_level_fx_parent_node == null:
		return
	for c in initial_zoom_level_fx_parent_node.get_children():
		if !c.autoplay:
			c.play()


func _process(delta):
	_current_position += delta
	if _current_position > _stream_length:
		_current_position = _current_position - _stream_length


func _on_zoom_step_change_initiated(from_zoom_step: int, to_zoom_step: int, zoom_speed: float) -> void:
	var from_audio_player := _get_zoom_level_music_audio_stream_player(from_zoom_step+1)
	var max_volume_db = from_audio_player.volume_db
	var to_audio_player := _get_zoom_level_music_audio_stream_player(to_zoom_step+1)
	_tween.interpolate_property(from_audio_player, "volume_db", max_volume_db, quiet_volumn_db, zoom_speed,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tween.interpolate_property(to_audio_player, "volume_db", quiet_volumn_db, max_volume_db, zoom_speed,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	if !no_music:
		to_audio_player.play(_current_position)
	_fade_in_out_zoom_level_sound_effects(from_zoom_step+1, false, zoom_speed)
	_fade_in_out_zoom_level_sound_effects(to_zoom_step+1, true, zoom_speed)
	_tween.start()
	yield(_tween, "tween_all_completed")
	from_audio_player.stop()
	_stop_all_zoom_level_sound_effects(from_zoom_step+1)


func _fade_in_out_zoom_level_sound_effects(zoom_level: int, fade_in: bool, zoom_speed: float) -> void:
	var sound_fx_parent_node = _get_zoom_level_parent_node(zoom_level, false)
	for c in sound_fx_parent_node.get_children():
		if !_original_sound_fx_volume_db.has(c):
			_original_sound_fx_volume_db[c] = c.volume_db
		if fade_in:
			c.play()
			_tween.interpolate_property(c, "volume_db", quiet_volumn_db, _original_sound_fx_volume_db[c], zoom_speed,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		else:
			_tween.interpolate_property(c, "volume_db", _original_sound_fx_volume_db[c], quiet_volumn_db, zoom_speed,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)

func _stop_all_zoom_level_sound_effects(zoom_level: int) -> void:
	var sound_fx_parent_node = _get_zoom_level_parent_node(zoom_level, false)
	for c in sound_fx_parent_node.get_children():
		c.stop()


func _get_zoom_level_music_audio_stream_player(zoom_level: int) -> AudioStreamPlayer:
	var parent_node = _get_zoom_level_parent_node(zoom_level, true)
	return parent_node.get_child(0)

func _get_zoom_level_parent_node(zoom_level: int, music:bool) -> Node:
	var node_name = "Zoom" + str(zoom_level)
	if music:
		node_name += "Music"
	else:
		node_name += "Sound"
	
	return get_node_or_null(node_name)

