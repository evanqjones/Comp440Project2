extends GutTest
## Tests for the shared contract classes in systems/shared/ (docs/CONTRACTS.md §1).


func test_game_types_enums() -> void:
	assert_eq(
		GameTypes.Category.keys(),
		["PRODUCE", "BAKERY", "DAIRY", "SNACKS", "FROZEN", "ELECTRONICS", "DEAL"],
		"Category order matches CONTRACTS.md §1.1"
	)
	assert_eq(
		GameTypes.Phase.keys(),
		["IDLE", "COUNTDOWN", "RUSH", "FINAL_CALL", "CLOSED", "RESULTS", "MATCH_OVER"],
		"Phase order matches CONTRACTS.md §1.1"
	)


func test_drive_command_defaults() -> void:
	var cmd := DriveCommand.new()
	assert_eq(cmd.throttle, 0.0)
	assert_eq(cmd.brake, 0.0)
	assert_eq(cmd.steer, 0.0)
	assert_false(cmd.boost)


func test_item_data_defaults() -> void:
	var item := ItemData.new()
	assert_eq(item.item_id, -1, "item_id is unassigned until Store spawns the item")
	assert_eq(item.category, GameTypes.Category.PRODUCE)
	assert_eq(item.value, 0)
	assert_false(item.is_deal)
	assert_null(item.mesh)


func test_item_data_instances_are_independent() -> void:
	var a := ItemData.new()
	var b := ItemData.new()
	a.item_id = 1
	a.value = 40
	a.category = GameTypes.Category.ELECTRONICS
	assert_eq(b.item_id, -1)
	assert_eq(b.value, 0)
	assert_eq(b.category, GameTypes.Category.PRODUCE)
