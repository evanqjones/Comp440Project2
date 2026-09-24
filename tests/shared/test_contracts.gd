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


func test_cart_state_defaults() -> void:
	var state := CartState.new()
	assert_eq(state.speed, 0.0)
	assert_eq(state.items.size(), 0)
	assert_eq(state.value, 0)
	assert_eq(state.boost_meter, 0.0)
	assert_false(state.is_stunned)
	assert_false(state.is_immune)


func test_round_results_defaults() -> void:
	var results := RoundResults.new()
	assert_eq(results.round_number, 0)
	assert_eq(results.banked.size(), 0)
	assert_eq(results.winner_ids.size(), 0)
	assert_eq(results.stamps.size(), 0)
	assert_eq(results.match_banked.size(), 0)
	assert_false(results.is_match_over)
	assert_eq(results.match_winner_ids.size(), 0)


func test_profiles_load() -> void:
	var expected := {
		"player": ["You", "Platinum"],
		"carl": ["Coupon Carl", "Gold"],
		"bev": ["Aunt Bev", "Platinum"],
		"rita": ["Rolling Rita", "Silver"],
	}
	for key: String in expected:
		var profile := load("res://systems/shared/profiles/%s.tres" % key) as ShopperProfile
		assert_not_null(profile, "%s.tres loads as a ShopperProfile" % key)
		if profile == null:
			continue
		assert_eq(profile.display_name, expected[key][0])
		assert_eq(profile.tier, expected[key][1])
		assert_ne(profile.color, Color(), "%s has a color" % key)
		assert_ne(profile.blurb, "", "%s has a blurb" % key)
