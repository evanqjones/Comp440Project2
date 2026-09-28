extends Area3D
## Store-owned checkout trigger. It queues a registered cart with RoundManager;
## the manager defers taking inventory until Cart finishes the current physics frame.


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Cart:
		RoundManager._request_checkout(body as Cart)
