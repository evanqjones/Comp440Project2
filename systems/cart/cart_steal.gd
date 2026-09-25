class_name CartSteal
extends RefCounted
## Pure ram-steal rules (docs/features/cart/04-ram-steal/01-spec.md §3, GAME_SPEC.md §5).
## `speed` in each CartState must be the planar speed just before the contact.

enum Outcome { NONE, BOUNCE, A_WINS, B_WINS }


## Who inherits: the faster cart needs >= steal_min_speed and >= steal_margin more speed,
## must not be stunned, and the slower cart must not be immune and must have items.
static func outcome(t: CartTuning, a: CartState, b: CartState) -> Outcome:
	if is_equal_approx(a.speed, b.speed):
		return Outcome.BOUNCE
	var a_faster := a.speed > b.speed
	var fast := a if a_faster else b
	var slow := b if a_faster else a
	var qualifies := fast.speed >= t.steal_min_speed \
		and fast.speed - slow.speed >= t.steal_margin \
		and not fast.is_stunned \
		and not slow.is_immune \
		and slow.items.size() > 0
	if not qualifies:
		return Outcome.BOUNCE
	return Outcome.A_WINS if a_faster else Outcome.B_WINS


## The first winner_free_slots items (oldest first) transfer; the rest spill.
## Returns [transferred: Array[ItemData], spilled: Array[ItemData]].
static func split(loser_items: Array[ItemData], winner_free_slots: int) -> Array:
	var free := clampi(winner_free_slots, 0, loser_items.size())
	var transferred: Array[ItemData] = []
	transferred.assign(loser_items.slice(0, free))
	var spilled: Array[ItemData] = []
	spilled.assign(loser_items.slice(free))
	return [transferred, spilled]
