class_name ShopperProfile
extends Resource
## Who's driving a cart, for UI, name tags, and cart colors (docs/CONTRACTS.md §1.6).
## Bot behavior values (greed, aggression, boost habit) live in Rivals, not here.

## For example "Coupon Carl".
@export var display_name: String = ""
## "Bronze" | "Silver" | "Gold" | "Platinum"
@export var tier: String = ""
## Cart rim, flag, and name tag color. Must match the cart palette in docs/ASSETS.md §3.
@export var color: Color = Color()
@export var member_number: String = ""
## Year.
@export var member_since: int = 0
## Intro and personality text on the Shopper ID card.
@export_multiline var blurb: String = ""
