extends GutTest
## Fallback demo round timing (docs/features/player/02-demo-round/FEATURE.md §2).


func test_phases_over_a_round() -> void:
	assert_eq(DemoRoundClock.phase_at(0.0), GameTypes.Phase.COUNTDOWN)
	assert_eq(DemoRoundClock.phase_at(2.9), GameTypes.Phase.COUNTDOWN)
	assert_eq(DemoRoundClock.phase_at(3.0), GameTypes.Phase.RUSH, "GO after the 3 s countdown")
	assert_eq(DemoRoundClock.phase_at(3.0 + 99.9), GameTypes.Phase.RUSH)
	assert_eq(DemoRoundClock.phase_at(3.0 + 100.0), GameTypes.Phase.FINAL_CALL, "last 20 s")
	assert_eq(DemoRoundClock.phase_at(3.0 + 120.0), GameTypes.Phase.CLOSED, "closes at 2:00")


func test_time_left() -> void:
	assert_eq(DemoRoundClock.time_left(0.0), 120.0, "full 2:00 during the countdown")
	assert_eq(DemoRoundClock.time_left(63.0), 60.0)
	assert_eq(DemoRoundClock.time_left(500.0), 0.0, "never negative")
