class_name ShopperIdCard
## Builds a Shopper ID card (GAME_SPEC.md §2.1) from a ShopperProfile, filling Evan's
## assets/ui/id_card_layout.tscn by its % names (ASSETS.md §4). Until that file exists, a placeholder
## with the same names is used (docs/features/player/09-title/FEATURE.md).

const EVAN_LAYOUT := "res://assets/ui/id_card_layout.tscn"
const PLACEHOLDER_LAYOUT := "res://systems/player/screens/placeholder_id_card_layout.tscn"
## A match is best of 3, so a card has 3 stamp slots.
const STAMP_SLOTS := 3


static func layout_path() -> String:
	return EVAN_LAYOUT if ResourceLoader.exists(EVAN_LAYOUT) else PLACEHOLDER_LAYOUT


## A filled card. `name_override` replaces the profile's name (Grandma's card on the title screen).
static func make(profile: ShopperProfile, name_override: String = "", stamps: int = 0) -> Control:
	var card := (load(layout_path()) as PackedScene).instantiate() as Control
	_fill(card, "Name", name_override if name_override != "" else profile.display_name)
	_fill(card, "TierBadge", profile.tier.to_upper())
	_fill(card, "MemberNumber", "No. %s" % profile.member_number)
	_fill(card, "MemberSince", "Member since %d" % profile.member_since)
	_fill(card, "Barcode", barcode(profile.member_number))
	_fill(card, "LifetimeSavings", "Lifetime savings $%s" % _thousands(lifetime_savings(profile)))
	_fill(card, "StampRow", stamp_row(stamps))
	var photo := card.get_node_or_null("%Photo")
	if photo is ColorRect:
		(photo as ColorRect).color = profile.color
	elif photo is CanvasItem:
		(photo as CanvasItem).self_modulate = profile.color
	return card


## "★ ★ –": earned stamps, then empty slots.
static func stamp_row(stamps: int) -> String:
	var slots: PackedStringArray = []
	for i: int in STAMP_SLOTS:
		slots.append("★" if i < stamps else "–")
	return " ".join(slots)


## Bars from the member number's digits (flavor for the card back).
static func barcode(number: String) -> String:
	var bars := ""
	for character: String in number:
		bars += ("|".repeat(int(character) % 3 + 1) + " ") if character.is_valid_int() else "  "
	return bars.strip_edges()


## Flavor number: longer membership, bigger savings.
static func lifetime_savings(profile: ShopperProfile) -> int:
	return maxi(0, 2026 - profile.member_since) * 911


static func _thousands(value: int) -> String:
	var digits := str(value)
	var out := ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return out


static func _fill(card: Control, part: String, text: String) -> void:
	var label := card.get_node_or_null("%" + part) as Label
	if label != null:
		label.text = text
