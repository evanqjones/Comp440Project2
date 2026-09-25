extends GutTest

func test_personality_resource_defaults() -> void:
	var personality = BotPersonality.new()
	assert_eq(personality.greed, 10, "Default greed should be 10")
	assert_eq(personality.base_aggression, 0.5, "Default base_aggression should be 0.5")
	assert_eq(personality.boost_habit, 0.5, "Default boost_habit should be 0.5")
