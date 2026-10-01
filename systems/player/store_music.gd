class_name StoreMusic
extends Node3D
## Plays the store recording after a user gesture and blends its volume at the doorway.

const INDOOR_VOLUME_DB: float = 0.0
const OUTDOOR_VOLUME_DB: float = -12.0
const VOLUME_BLEND_SECONDS: float = 0.5
const FINAL_CALL_PITCH: float = 1.10

@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _interior_zone: Area3D = $InteriorZone

var _music_started: bool = false
var _player_inside: bool = false
var _volume_tween: Tween


func _ready() -> void:
	_music_player.volume_db = OUTDOOR_VOLUME_DB
	_interior_zone.body_entered.connect(_on_interior_body_entered)
	_interior_zone.body_exited.connect(_on_interior_body_exited)
	RoundManager.phase_changed.connect(_on_phase_changed)


func _input(event: InputEvent) -> void:
	if _music_started or not _is_activation_input(event):
		return
	_music_started = true
	_music_player.play()


func _is_activation_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return false


func _on_interior_body_entered(body: Node3D) -> void:
	if body is Cart and body.cart_id == 0:
		_set_player_inside(true)


func _on_interior_body_exited(body: Node3D) -> void:
	if body is Cart and body.cart_id == 0:
		_set_player_inside(false)


func _set_player_inside(inside: bool) -> void:
	if _player_inside == inside:
		return
	_player_inside = inside
	if _volume_tween != null and _volume_tween.is_running():
		_volume_tween.kill()
	var target_volume_db: float = INDOOR_VOLUME_DB if inside else OUTDOOR_VOLUME_DB
	_volume_tween = create_tween()
	_volume_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_volume_tween.tween_property(_music_player, "volume_db", target_volume_db, VOLUME_BLEND_SECONDS)


func _on_phase_changed(phase: GameTypes.Phase) -> void:
	_music_player.pitch_scale = FINAL_CALL_PITCH if phase == GameTypes.Phase.FINAL_CALL else 1.0
