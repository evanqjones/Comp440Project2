class_name DriveCommand
extends Resource
## One frame of driving input, produced by PlayerController or BotController and
## consumed by Cart.apply_command() (docs/CONTRACTS.md §1.2).
## Drivers may reuse one instance every frame; Cart must not keep a reference to it.

@export_range(0.0, 1.0) var throttle: float = 0.0
## Brakes while moving forward; reverses once stopped.
@export_range(0.0, 1.0) var brake: float = 0.0
## -1 = full left, +1 = full right.
@export_range(-1.0, 1.0) var steer: float = 0.0
@export var boost: bool = false
