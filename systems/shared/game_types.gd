class_name GameTypes
extends RefCounted
## Shared enums used across systems (docs/CONTRACTS.md §1.1).
## Always refer to values by name, e.g. GameTypes.Phase.RUSH, never by raw integer.

enum Category { PRODUCE, BAKERY, DAIRY, SNACKS, FROZEN, ELECTRONICS, DEAL }
enum Phase { IDLE, COUNTDOWN, RUSH, FINAL_CALL, CLOSED, RESULTS, MATCH_OVER }
