class_name PlayerAudio
extends Node
## Sound effects (docs/features/player/14-sound-effects/FEATURE.md; ASSETS.md §4 event table).
## Each sound is Evan's file when it exists at its ASSETS.md path; until then a stand-in is
## synthesized once from oscillator tones (the Shopping Cart Derby artifact's sounds). Only the
## player's own pickups, steals and checkouts make sounds; round events play for everyone.
## Created by PlayerFeedback with the player's cart.

const MIX_RATE := 44100
const POOL := 8
const VOLUME_DB := -3.0
## The squeak loop: quiet and low when slow, louder and higher when fast.
const WHEEL_MIN_SPEED := 0.5
const WHEEL_FULL_SPEED := 15.0
## How many sounds `played` remembers (tests read it).
const HISTORY := 32

## name -> {"file": Evan's path, "tones": [[f1, f2, seconds, wave, volume, delay], ...]}
## Each tone glides from f1 to f2 Hz while it fades out, like the artifact's WebAudio tone().
const SOUNDS := {
	"pickup": {"file": "res://assets/audio/sfx/pickup_blip.wav", "tones": [[660.0, 990.0, 0.08, "square", 0.04, 0.0]]},
	"crash": {"file": "res://assets/audio/sfx/crash_thud.wav", "tones": [[140.0, 50.0, 0.22, "sawtooth", 0.09, 0.0]]},
	"steal": {"file": "res://assets/audio/sfx/steal_whoosh.wav", "tones": [[300.0, 900.0, 0.25, "triangle", 0.1, 0.0], [600.0, 1200.0, 0.2, "square", 0.03, 0.08]]},
	"robbed": {"file": "", "tones": [[500.0, 120.0, 0.45, "sawtooth", 0.08, 0.0]]},
	"checkout": {"file": "res://assets/audio/sfx/register_ding.wav", "tones": [[880.0, 880.0, 0.12, "sine", 0.12, 0.0], [1320.0, 1320.0, 0.3, "sine", 0.12, 0.12]]},
	"cart_full": {"file": "", "tones": [[330.0, 330.0, 0.09, "square", 0.05, 0.0], [247.0, 247.0, 0.14, "square", 0.05, 0.12]]},
	"beep": {"file": "res://assets/audio/sfx/countdown_beep.wav", "tones": [[440.0, 440.0, 0.12, "square", 0.05, 0.0]]},
	"go": {"file": "res://assets/audio/sfx/countdown_go.wav", "tones": [[880.0, 1760.0, 0.35, "square", 0.06, 0.0]]},
	"doors_open": {"file": "res://assets/audio/pa/doors_open.ogg", "tones": [[784.0, 784.0, 0.3, "sine", 0.09, 0.15], [988.0, 988.0, 0.5, "sine", 0.09, 0.42]]},
	"final_call": {"file": "res://assets/audio/pa/final_call.ogg", "tones": [[988.0, 988.0, 0.25, "sine", 0.1, 0.0], [784.0, 784.0, 0.25, "sine", 0.1, 0.25], [659.0, 659.0, 0.5, "sine", 0.1, 0.5]]},
	"store_closed": {"file": "res://assets/audio/pa/store_closed.ogg", "tones": [[659.0, 659.0, 0.3, "sine", 0.1, 0.0], [523.0, 523.0, 0.6, "sine", 0.1, 0.3]]},
	"deal": {"file": "res://assets/audio/pa/deal_of_the_day.ogg", "tones": [[988.0, 988.0, 0.1, "triangle", 0.08, 0.0], [1319.0, 1319.0, 0.1, "triangle", 0.08, 0.1], [1976.0, 1976.0, 0.25, "triangle", 0.08, 0.2]]},
	"hazard": {"file": "res://assets/audio/pa/hazard_wet_floor.ogg", "tones": [[620.0, 620.0, 0.1, "square", 0.05, 0.0], [620.0, 620.0, 0.1, "square", 0.05, 0.18]]},
	"wheel": {"file": "res://assets/audio/sfx/squeaky_wheel_loop.wav", "tones": [[1700.0, 2300.0, 0.06, "triangle", 0.05, 0.02], [1900.0, 2500.0, 0.05, "triangle", 0.04, 0.27]], "loop": 0.5},
}

## The human's cart.
@export var cart: Cart

## Most recent sound names, oldest first.
var played := PackedStringArray()

static var _cache: Dictionary = {}

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _wheel: AudioStreamPlayer
var _beeps_left := 0
var _beep_timer := 0.0


## Evan's file at `path` if it's in the project, else `tones` rendered.
static func resolve(path: String, tones: Array, loop_seconds: float = 0.0) -> AudioStream:
	if path != "" and ResourceLoader.exists(path):
		return load(path) as AudioStream
	return render(tones, loop_seconds)


## The stream for a sound name (built once and shared).
static func stream_for(sound: String) -> AudioStream:
	if not _cache.has(sound):
		var entry: Dictionary = SOUNDS[sound]
		_cache[sound] = resolve(entry["file"], entry["tones"], entry.get("loop", 0.0))
	return _cache[sound]


static func wheel_pitch(speed: float) -> float:
	return lerpf(0.8, 1.6, clampf(speed / WHEEL_FULL_SPEED, 0.0, 1.0))


static func wheel_volume_db(speed: float) -> float:
	return lerpf(-28.0, -14.0, clampf(speed / WHEEL_FULL_SPEED, 0.0, 1.0))


static func wheel_audible(speed: float, gameplay: bool) -> bool:
	return gameplay and speed >= WHEEL_MIN_SPEED


## Mixes the tones into one 16-bit mono clip; `loop_seconds` > 0 makes a clip of that length that loops.
static func render(tones: Array, loop_seconds: float = 0.0) -> AudioStreamWAV:
	var length := loop_seconds
	if length <= 0.0:
		for tone: Array in tones:
			length = maxf(length, tone[5] + tone[2] + 0.02)
	var count := int(ceil(length * MIX_RATE))
	var mix := PackedFloat32Array()
	mix.resize(count)
	for tone: Array in tones:
		_add_tone(mix, tone[0], tone[1], tone[2], tone[3], tone[4], tone[5])
	var data := PackedByteArray()
	data.resize(count * 2)
	for i: int in count:
		data.encode_s16(i * 2, int(clampf(mix[i] * 2.0, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	if loop_seconds > 0.0:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream


static func _add_tone(mix: PackedFloat32Array, f1: float, f2: float, seconds: float, wave: String, volume: float, delay: float) -> void:
	var start := int(delay * MIX_RATE)
	var stop := mini(mix.size(), int((delay + seconds + 0.02) * MIX_RATE))
	var phase := 0.0
	for i: int in range(start, stop):
		var t := float(i - start) / MIX_RATE
		var k := minf(t / seconds, 1.0)
		var freq := f1 * pow(f2 / f1, k)
		var gain := volume * pow(0.0001 / volume, k)
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		mix[i] += gain * _wave(wave, phase)


static func _wave(wave: String, phase: float) -> float:
	match wave:
		"square":
			return 1.0 if phase < 0.5 else -1.0
		"sawtooth":
			return 2.0 * phase - 1.0
		"triangle":
			return 1.0 - 4.0 * absf(phase - 0.5)
	return sin(TAU * phase)


func _ready() -> void:
	for i: int in POOL:
		var player := AudioStreamPlayer.new()
		player.volume_db = VOLUME_DB
		add_child(player)
		_players.append(player)
	_wheel = AudioStreamPlayer.new()
	_wheel.stream = stream_for("wheel")
	add_child(_wheel)
	RoundManager.checked_out.connect(_on_checked_out)
	RoundManager.phase_changed.connect(_on_phase_changed)
	RoundManager.deal_spawned.connect(func(_pickup: Pickup) -> void: play("deal"))
	RoundManager.hazard_spawned.connect(func(_hazard: Node3D) -> void: play("hazard"))
	if cart != null:
		cart.item_collected.connect(_on_item_collected)
		cart.cart_full.connect(func(_full: Cart) -> void: play("cart_full"))
	_watch_registered()


func _process(delta: float) -> void:
	_watch_registered() # carts can register after this node is ready
	if _beeps_left > 0:
		_beep_timer -= delta
		if _beep_timer <= 0.0:
			_beep()
	_update_wheel()


func play(sound: String) -> void:
	played.append(sound)
	if played.size() > HISTORY:
		played = played.slice(played.size() - HISTORY)
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream_for(sound)
	player.play()


func last_played() -> String:
	return played[played.size() - 1] if not played.is_empty() else ""


## Hear steals involving `other` (safe to call more than once). The LOSER emits cart_robbed.
func watch(other: Cart) -> void:
	if other != null and not other.cart_robbed.is_connected(_on_cart_robbed):
		other.cart_robbed.connect(_on_cart_robbed)


func _watch_registered() -> void:
	watch(cart)
	for other: Cart in RoundManager.get_carts():
		watch(other)


func _on_item_collected(_who: Cart, _item: ItemData) -> void:
	play("pickup")


func _on_checked_out(who: Cart, _value: int) -> void:
	if who != null and who == cart:
		play("checkout")


func _on_cart_robbed(winner: Cart, loser: Cart, _items: Array[ItemData], _spilled: Array[ItemData]) -> void:
	if cart == null:
		return
	if winner == cart:
		play("crash")
		play("steal")
	elif loser == cart:
		play("crash")
		play("robbed")


func _on_phase_changed(next_phase: GameTypes.Phase) -> void:
	match next_phase:
		GameTypes.Phase.COUNTDOWN:
			_beeps_left = 3
			_beep()
		GameTypes.Phase.RUSH:
			_beeps_left = 0
			play("go")
			play("doors_open")
		GameTypes.Phase.FINAL_CALL:
			play("final_call")
		GameTypes.Phase.CLOSED:
			play("store_closed")


func _beep() -> void:
	play("beep")
	_beeps_left -= 1
	_beep_timer = 1.0


func _update_wheel() -> void:
	var speed := 0.0
	if cart != null:
		speed = Vector2(cart.velocity.x, cart.velocity.z).length()
	if not wheel_audible(speed, RoundManager.is_gameplay_active()):
		if _wheel.playing:
			_wheel.stop()
		return
	_wheel.pitch_scale = wheel_pitch(speed)
	_wheel.volume_db = wheel_volume_db(speed)
	if not _wheel.playing:
		_wheel.play()
