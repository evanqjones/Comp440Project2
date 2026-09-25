class_name DemoRoundClock
extends RefCounted
## Round timing for the FALLBACK demo only (docs/features/player/02-demo-round/FEATURE.md).
## Store's RoundManager owns the real round flow and replaces this. Numbers: GAME_SPEC.md §3.1.

const COUNTDOWN := 3.0
const ROUND := 120.0
const FINAL_CALL := 20.0


## Phase `elapsed` seconds after the demo starts (the countdown begins at 0).
static func phase_at(elapsed: float) -> GameTypes.Phase:
	if elapsed < COUNTDOWN:
		return GameTypes.Phase.COUNTDOWN
	var played := elapsed - COUNTDOWN
	if played < ROUND - FINAL_CALL:
		return GameTypes.Phase.RUSH
	if played < ROUND:
		return GameTypes.Phase.FINAL_CALL
	return GameTypes.Phase.CLOSED


## Seconds left on the round clock (2:00 during the countdown, never negative).
static func time_left(elapsed: float) -> float:
	return clampf(ROUND - (elapsed - COUNTDOWN), 0.0, ROUND)
