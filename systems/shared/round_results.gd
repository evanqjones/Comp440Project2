class_name RoundResults
extends RefCounted
## Store → Player/Rivals at the end of each round, via RoundManager.round_ended (docs/CONTRACTS.md §1.5).

var round_number: int = 0
## cart_id -> dollars checked out this round.
var banked: Dictionary[int, int] = {}
## Carts that earned a stamp this round (ties share; empty if nobody banked).
var winner_ids: Array[int] = []
## cart_id -> total stamps so far.
var stamps: Dictionary[int, int] = {}
## cart_id -> dollars across all rounds so far.
var match_banked: Dictionary[int, int] = {}
var is_match_over: bool = false
## Filled only when is_match_over (exact ties share).
var match_winner_ids: Array[int] = []
