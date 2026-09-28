extends Node3D
## Visual inspection scene for Store's real Demo clock and door lifecycle.

@onready var _readout: Label = $Readout


func _ready() -> void:
	call_deferred("_start_round")


func _process(_delta: float) -> void:
	var phase_name := GameTypes.Phase.keys()[RoundManager.phase] as String
	_readout.text = "Phase: %s\nTime left: %.1f\nDoors: %s" % [
		phase_name,
		RoundManager.time_left,
		"OPEN" if RoundManager.doors_open else "CLOSED",
	]


func _start_round() -> void:
	if RoundManager.phase == GameTypes.Phase.IDLE:
		RoundManager.start_match()
