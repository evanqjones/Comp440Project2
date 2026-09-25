# systems/rivals/bot_personality.gd
class_name BotPersonality
extends Resource

@export var greed: int = 10
@export_range(0.0, 1.0) var base_aggression: float = 0.5
@export_range(0.0, 1.0) var boost_habit: float = 0.5
