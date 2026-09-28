extends GutTest
## Demo round timing (docs/features/store/02-round-flow/01-spec.md §§2-3, 6-7).

const STORE_SCENE := preload("res://systems/store/store.tscn")

class ResetCart extends Cart:
	var reset_count: int = 0
	var last_spawn := Transform3D.IDENTITY

	func _ready() -> void:
		pass

	func reset_for_round(spawn: Transform3D) -> void:
		reset_count += 1
		last_spawn = spawn


var _saved_phase: GameTypes.Phase
var _saved_round_number: int
var _saved_time_left: float
var _saved_doors_open: bool
var _saved_physics_processing: bool


func before_each() -> void:
	_saved_phase = RoundManager.phase
	_saved_round_number = RoundManager.round_number
	_saved_time_left = RoundManager.time_left
	_saved_doors_open = RoundManager.doors_open
	_saved_physics_processing = RoundManager.is_physics_processing()
	RoundManager.set_physics_process(false)
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager.round_number = 0
	RoundManager.time_left = 0.0
	RoundManager.doors_open = false
	RoundManager._phase_time_left = 0.0
	RoundManager._close_pending = false
	RoundManager._match_running = false


func after_each() -> void:
	RoundManager.phase = _saved_phase
	RoundManager.round_number = _saved_round_number
	RoundManager.time_left = _saved_time_left
	RoundManager.doors_open = _saved_doors_open
	RoundManager._phase_time_left = 0.0
	RoundManager._close_pending = false
	RoundManager._match_running = false
	RoundManager.set_physics_process(_saved_physics_processing)


func test_start_match_begins_once_with_demo_defaults() -> void:
	watch_signals(RoundManager)
	RoundManager.start_match()
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN)
	assert_eq(RoundManager.round_number, 1)
	assert_eq(RoundManager.time_left, 120.0)
	assert_signal_emit_count(RoundManager, "phase_changed", 1)

	RoundManager.start_match()
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN, "an active match ignores duplicate starts")
	assert_signal_emit_count(RoundManager, "phase_changed", 1)


func test_external_fallback_phase_is_not_advanced_by_the_real_clock() -> void:
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	RoundManager._physics_process(5.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN, "Rickey's fallback demo owns its temporary clock")


func test_exact_boundaries_and_signals() -> void:
	watch_signals(RoundManager)
	RoundManager.start_match()
	RoundManager._physics_process(3.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.RUSH)
	assert_eq(RoundManager.time_left, 120.0)
	assert_signal_emitted_with_parameters(RoundManager, "round_started", [1])

	RoundManager._physics_process(100.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.FINAL_CALL)
	assert_eq(RoundManager.time_left, 20.0)
	RoundManager._physics_process(20.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.CLOSED)
	assert_eq(RoundManager.time_left, 0.0)
	assert_signal_not_emitted(RoundManager, "round_ended", "results wait until the frame after close")

	await wait_process_frames(1)
	assert_eq(RoundManager.phase, GameTypes.Phase.RESULTS)
	assert_signal_emit_count(RoundManager, "round_ended", 1)
	var parameters: Array = get_signal_parameters(RoundManager, "round_ended")
	var results := parameters[0] as RoundResults
	assert_not_null(results)
	assert_eq(results.round_number, 1)
	assert_false(results.is_match_over)

	RoundManager._physics_process(10.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.IDLE)
	assert_signal_emit_count(RoundManager, "phase_changed", 6, "every transition emits exactly once")


func test_large_delta_crosses_each_boundary_once() -> void:
	watch_signals(RoundManager)
	RoundManager.start_match()
	RoundManager._physics_process(123.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.CLOSED)
	assert_eq(RoundManager.time_left, 0.0)
	assert_signal_emit_count(RoundManager, "phase_changed", 4, "countdown, rush, final call, closed")
	assert_signal_emit_count(RoundManager, "round_started", 1)
	assert_signal_not_emitted(RoundManager, "round_ended")
	await wait_process_frames(1)
	assert_signal_emit_count(RoundManager, "round_ended", 1)


func test_gameplay_is_active_only_during_rush_and_final_call() -> void:
	for inactive_phase: GameTypes.Phase in [
		GameTypes.Phase.IDLE,
		GameTypes.Phase.COUNTDOWN,
		GameTypes.Phase.CLOSED,
		GameTypes.Phase.RESULTS,
		GameTypes.Phase.MATCH_OVER,
	]:
		RoundManager.phase = inactive_phase
		assert_false(RoundManager.is_gameplay_active(), "%s is inactive" % GameTypes.Phase.keys()[inactive_phase])
	for active_phase: GameTypes.Phase in [GameTypes.Phase.RUSH, GameTypes.Phase.FINAL_CALL]:
		RoundManager.phase = active_phase
		assert_true(RoundManager.is_gameplay_active(), "%s is active" % GameTypes.Phase.keys()[active_phase])


func test_demo_can_restart_explicitly_after_results() -> void:
	RoundManager.start_match()
	RoundManager._physics_process(123.0)
	await wait_process_frames(1)
	RoundManager._physics_process(10.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.IDLE)

	RoundManager.start_match()
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN)
	assert_eq(RoundManager.round_number, 1, "the Demo starts a new single-round match")
	assert_eq(RoundManager.time_left, 120.0)


func test_start_match_resets_registered_carts_at_matching_store_starts_once() -> void:
	var store := STORE_SCENE.instantiate() as Store
	add_child_autofree(store)
	var player := ResetCart.new()
	player.cart_id = 0
	add_child_autofree(player)
	var rita := ResetCart.new()
	rita.cart_id = 3
	add_child_autofree(rita)
	RoundManager.register_cart(player)
	RoundManager.register_cart(rita)
	var starts := store.get_start_transforms()

	RoundManager.start_match()
	assert_eq(player.reset_count, 1)
	assert_eq(rita.reset_count, 1)
	assert_eq(player.last_spawn, starts[0])
	assert_eq(rita.last_spawn, starts[3])
	RoundManager.start_match()
	assert_eq(player.reset_count, 1, "a duplicate start does not reset carts again")
	assert_eq(rita.reset_count, 1)
	RoundManager._match_running = false
	RoundManager._set_phase(GameTypes.Phase.IDLE)
	RoundManager.start_match()
	assert_eq(player.reset_count, 2, "an explicit new match resets carts again")
	assert_eq(rita.reset_count, 2)


func test_store_doors_open_for_gameplay_and_close_at_zero() -> void:
	var store := STORE_SCENE.instantiate() as Store
	add_child_autofree(store)
	await wait_process_frames(1)
	var left := store.get_node("Doors/LeftDoor") as Node3D
	var right := store.get_node("Doors/RightDoor") as Node3D
	var left_collision := left.get_node("Body/CollisionShape3D") as CollisionShape3D
	var right_collision := right.get_node("Body/CollisionShape3D") as CollisionShape3D
	assert_false(RoundManager.doors_open)
	assert_false(left_collision.disabled)
	assert_false(right_collision.disabled)

	RoundManager.start_match()
	RoundManager._physics_process(3.0)
	await wait_physics_frames(40)
	assert_true(RoundManager.doors_open)
	assert_almost_eq(left.position.x, -6.0, 0.01)
	assert_almost_eq(right.position.x, 6.0, 0.01)
	assert_true(left_collision.disabled)
	assert_true(right_collision.disabled)

	RoundManager._physics_process(120.0)
	await wait_physics_frames(40)
	assert_false(RoundManager.doors_open)
	assert_almost_eq(left.position.x, -2.0, 0.01)
	assert_almost_eq(right.position.x, 2.0, 0.01)
	assert_false(left_collision.disabled)
	assert_false(right_collision.disabled)


func test_stale_deferred_close_cannot_end_a_restarted_match() -> void:
	watch_signals(RoundManager)
	RoundManager.start_match()
	RoundManager._physics_process(123.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.CLOSED)
	RoundManager._match_running = false
	RoundManager._set_phase(GameTypes.Phase.IDLE)
	RoundManager.start_match()
	await wait_process_frames(1)
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN)
	assert_signal_not_emitted(RoundManager, "round_ended", "the prior match's deferred close is ignored")
