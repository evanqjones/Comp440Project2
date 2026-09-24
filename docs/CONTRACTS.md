# Contracts: the seams between systems

**Version:** v0.1 **DRAFT** · **Date:** 2026-09-23

These are the interfaces that cross system boundaries. Four people and three different AI agents build against them in parallel, so **nobody changes them casually**. The change protocol is at the bottom.

- Gameplay rules and numbers live in [`GAME_SPEC.md`](GAME_SPEC.md). This file holds **names, types, and signatures**.
- Status: **DRAFT until all four owners sign off** in [`DECISIONS.md`](DECISIONS.md) (entry P-001). Items marked **(v0.1 addition)** are not in the GDD. They were added so the systems can be built and tested in parallel, and they need that sign-off too.
- The foundation feature (`integration/00-foundation`) turns this file into code: the shared scripts in `systems/shared/`, plus stub `Cart` and `RoundManager` scripts that have every signal and method here with empty bodies. Owners then fill in their own stubs.

---

## 1. Shared data (`systems/shared/`, jointly owned)

### 1.1 `GameTypes`: shared enums

```gdscript
# systems/shared/game_types.gd
class_name GameTypes
extends RefCounted

enum Category { PRODUCE, BAKERY, DAIRY, SNACKS, FROZEN, ELECTRONICS, DEAL }
enum Phase { IDLE, COUNTDOWN, RUSH, FINAL_CALL, CLOSED, RESULTS, MATCH_OVER }
```

(v0.1 addition) Use `GameTypes.Phase.RUSH`, never raw integers or strings.

### 1.2 `DriveCommand`: Player/Rivals → Cart

```gdscript
# systems/shared/drive_command.gd
class_name DriveCommand
extends Resource

@export_range(0.0, 1.0) var throttle: float = 0.0
@export_range(0.0, 1.0) var brake: float = 0.0   # brakes while moving forward; reverses once stopped
@export_range(-1.0, 1.0) var steer: float = 0.0  # -1 = full left, +1 = full right
@export var boost: bool = false
```

- One command per cart per physics frame.
- A driver may reuse one `DriveCommand` instance every frame. **Cart reads the values during `apply_command()` and must not keep a reference to it.**

### 1.3 `ItemData`: one grocery item

```gdscript
# systems/shared/item_data.gd
class_name ItemData
extends Resource

@export var item_id: int = -1   # (v0.1 addition) unique for the whole match; assigned by Store at spawn
@export var category: GameTypes.Category = GameTypes.Category.PRODUCE
@export var value: int = 0      # dollars
@export var is_deal: bool = false
@export var mesh: Mesh          # optional; null means "use the category's default look"
```

- **Every spawned item is its own `ItemData` instance**, created with `ItemData.new()` or `duplicate()`. Never share one loaded `.tres` between two items, because identity matters.
- The **same instance** moves between cart, floor, and checkout. Spilling an item keeps its `item_id`, `value`, and `is_deal`.

### 1.4 `CartState`: read-only snapshot of a cart

```gdscript
# systems/shared/cart_state.gd
class_name CartState
extends RefCounted

var cart_id: int               # (v0.1 addition)
var display_name: String       # (v0.1 addition)
var color: Color               # (v0.1 addition)
var position: Vector3          # (v0.1 addition)
var speed: float               # m/s, horizontal
var items: Array[ItemData]     # a copy; mutating it changes nothing
var value: int                 # sum of items' values
var boost_meter: float         # (v0.1 addition) 0.0 empty to 1.0 full
var is_stunned: bool
var is_immune: bool            # (v0.1 addition)
```

Readers: Store (scoring), Rivals (targeting), Player (HUD). Get one with `cart.get_state()`. It's a snapshot, so get a fresh one when you need current values.

### 1.5 `RoundResults`: Store → Player/Rivals at round end

```gdscript
# systems/shared/round_results.gd   (v0.1 addition: the GDD names "results" but doesn't define it)
class_name RoundResults
extends RefCounted

var round_number: int
var banked: Dictionary[int, int]        # cart_id -> dollars checked out this round
var winner_ids: Array[int]              # carts that earned a stamp this round (ties share; empty if nobody banked)
var stamps: Dictionary[int, int]        # cart_id -> total stamps so far
var match_banked: Dictionary[int, int]  # cart_id -> dollars across all rounds so far
var is_match_over: bool
var match_winner_ids: Array[int]        # filled only when is_match_over (exact ties share)
```

### 1.6 `ShopperProfile`: who's driving, for UI and name tags

```gdscript
# systems/shared/shopper_profile.gd   (v0.1 addition)
class_name ShopperProfile
extends Resource

@export var display_name: String        # "Coupon Carl"
@export var tier: String                # "Bronze" | "Silver" | "Gold" | "Platinum"
@export var color: Color                # cart rim, flag, name tag
@export var member_number: String
@export var member_since: int           # year
@export_multiline var blurb: String     # intro and personality text on the ID card
```

Profiles live in `systems/shared/profiles/` (`player.tres`, `carl.tres`, `bev.tres`, `rita.tres`). Player screens read them; Cart uses `display_name` and `color`. Bot **behavior** values (greed, aggression, boost habit) are not here. They belong to Rivals (`systems/rivals/`).

---

## 2. Cart API (`systems/cart/cart.gd`, owner Rickey)

```gdscript
class_name Cart
extends CharacterBody3D   # or RigidBody3D; Rickey decides in cart/01-movement (see DECISIONS.md).
                          # Must be a PhysicsBody3D on the "carts" layer so Store's Area3D zones detect it.

signal item_collected(cart: Cart, item: ItemData)
signal cart_robbed(winner: Cart, loser: Cart, items: Array[ItemData], spilled: Array[ItemData])
signal cart_full(cart: Cart)

@export var cart_id: int                  # 0 = human, 1..3 = bots; set in Main.tscn
@export var profile: ShopperProfile       # (v0.1 addition)

func apply_command(cmd: DriveCommand) -> void      # called by the driver every physics frame
func try_add_item(item: ItemData) -> bool          # false if full, or gameplay is not active
func take_all_items() -> Array[ItemData]           # empties the cart and returns what it held (Store's checkout)
func reset_for_round(spawn: Transform3D) -> void   # empty cart, full boost, no stun or immunity, placed at spawn
func get_state() -> CartState
func apply_slip(duration: float) -> void           # (v0.1 addition, Final) wet floor: steering ignored for duration
```

| Signal | Emitted when | Listeners |
|---|---|---|
| `item_collected(cart, item)` | `try_add_item()` accepted `item` | Store (bookkeeping), Player (pickup sound) |
| `cart_robbed(winner, loser, items, spilled)` | A qualifying contact finished resolving: **both inventories are already updated**. `items` = what actually moved into `winner`; `spilled` = overflow Store must spawn. Emitted **by the loser's or winner's Cart, exactly once per steal** (Rickey picks which cart and documents it). | Store (spawn `spilled` at `loser.global_position`), Player (popup, feed, shake), Rivals (retarget) |
| `cart_full(cart)` | The cart reaches 24 items | Player (HUD flash), Rivals (go bank) |

---

## 3. RoundManager API (autoload `RoundManager`, owner Anthony)

```gdscript
# systems/store/round_manager.gd, registered as autoload "RoundManager".
# No class_name on this script: it would clash with the autoload name.
extends Node

signal phase_changed(phase: GameTypes.Phase)   # (v0.1 addition) HUD red timer, muzak, PA
signal round_started(round_number: int)        # controls become active
signal round_ended(results: RoundResults)      # controls stop
signal checked_out(cart: Cart, value: int)
signal hazard_spawned(hazard: Node3D)          # Final
signal deal_spawned(pickup: Pickup)            # (v0.1 addition, Final) PA announcement, bots notice

var phase: GameTypes.Phase = GameTypes.Phase.IDLE   # read-only for other systems
var round_number: int = 0                            # 1..3; 0 before the first round
var time_left: float = 0.0                           # seconds left in the current round
var doors_open: bool = false

func register_cart(cart: Cart) -> void               # Main.tscn wiring calls this for all 4 carts
func get_carts() -> Array[Cart]
func get_pickups() -> Array[Pickup]                  # items currently on the floor
func get_checkout_position() -> Vector3              # where bots drive to bank
func is_gameplay_active() -> bool                    # true only in RUSH and FINAL_CALL
func get_round_banked(cart_id: int) -> int
func get_match_banked(cart_id: int) -> int
func get_stamps(cart_id: int) -> int
func get_banked_items(cart_id: int) -> Array[ItemData]   # (v0.1 addition) this round; receipt + conservation tests
func start_match() -> void                           # (v0.1 addition) called by Player's title/intro flow (Final);
                                                     # for the Demo, Store calls it itself when main.tscn loads
```

**Naming note:** use `round_number`, never `round`. `round` shadows GDScript's built-in `round()` function.

### 3.1 `Pickup` (`systems/store/pickup.gd`, owner Anthony)

```gdscript
class_name Pickup
extends Area3D

var item: ItemData
```

**Pickup flow:** a `Pickup` detects a `Cart` entering → if `RoundManager.is_gameplay_active()`, it calls `cart.try_add_item(item)` → if that returns `true`, the pickup marks itself taken, ignores every later body, and frees itself. **Cart never looks for pickups; Store's pickup calls into Cart.**

### 3.2 Checkout flow

Store's checkout `Area3D` detects a `Cart` → **deferred with `call_deferred`**, so any steal in the same physics frame resolves first → `var items := cart.take_all_items()` → if it's not empty, bank the sum **once** and emit `checked_out(cart, value)`.

---

## 4. Drivers (Player and Rivals)

```gdscript
# systems/player/player_controller.gd (Rickey) and systems/rivals/bot_controller.gd (John)
@export var cart: Cart
var _cmd := DriveCommand.new()

func _physics_process(_delta: float) -> void:
    # fill _cmd from input (Player) or AI (Rivals), then:
    cart.apply_command(_cmd)
```

- Drivers start sending real input on `round_started` and send neutral commands (all zero) after `round_ended`.
- `BotController` also has `@export var personality: BotPersonality`, a Rivals-owned resource with greed, aggression and boost habit.

---

## 5. Input actions (`project.godot`, integration owner)

`drive_gas`, `drive_brake`, `steer_left`, `steer_right`, `boost`, `pause`. Key and pad bindings are in [`GAME_SPEC.md` §8](GAME_SPEC.md#8-controls-and-camera).

## 6. Physics layers (`project.godot`, integration owner) (v0.1 addition)

| Layer | Name | Contains |
|---|---|---|
| 1 | `world` | Floor, shelves, walls, doors |
| 2 | `carts` | Every `Cart` |
| 3 | `pickups` | Every `Pickup` (Area3D) |
| 4 | `hazards` | Pallet jack, falling display, wet-floor zones |
| 5 | `zones` | Checkout zone and other triggers |

## 7. Scene wiring and assets

### 7.1 `Main.tscn` wiring (Anthony)

```
Main (Node3D)
├── Store            ← instance of systems/store/store.tscn (aisles, doors, checkout, spawn points, NavigationRegion3D)
├── Carts (Node3D)
│   ├── PlayerCart   ← cart.tscn, cart_id 0, profile player.tres
│   │   └── PlayerController (cart = ..)
│   ├── CarlCart     ← cart.tscn, cart_id 1, profile carl.tres
│   │   └── BotController (cart = .., personality carl)
│   ├── BevCart      ← cart_id 2 … BotController
│   └── RitaCart     ← cart_id 3 … BotController
├── ChaseCamera      ← systems/player/chase_camera.tscn (target = PlayerCart)
└── HUD              ← systems/player/hud.tscn (CanvasLayer, instances assets/ui/hud_layout.tscn)
```

### 7.2 Visual scenes and assets (Evan)

Art and audio reach the game through **fixed paths and named nodes** in `assets/`, defined in [`ASSETS.md`](ASSETS.md). Summary of the contract:

- Every gameplay scene has a child named `Visual` that instances the object's visual scene (for example, `cart.tscn` → `Visual` = `assets/models/cart/cart_visual.tscn`). It's a placeholder until Evan replaces the file **in place**.
- Visual scenes contain no scripts, collision, or lights. Gameplay code may touch only the **named parts** listed in the `ASSETS.md` manifest (for example, the cart's `Rim`, `Handle`, `Flag`, `ItemStack`, `NameTag`, or the doors' `LeftDoor` / `RightDoor`).
- UI layouts expose scene-unique `%Name` nodes; Player code fills them.
- Renaming a path or a named part follows the change protocol (§9).

---

## 8. Invariants (every owner's tests must respect these)

1. **Conservation.** At every moment, each `item_id` is in exactly one place: one cart's inventory, one `Pickup` on the floor, or banked. The total value of the items in play changes only when Store spawns an item or banks one.
2. **One steal per contact.** Each qualifying contact resolves once. The loser's immunity (1.6 s) blocks another steal from any cart. `cart_robbed` is emitted once per steal, after both inventories are updated.
3. **Steal before checkout.** A steal and a checkout in the same physics frame resolve steal-first (checkout is deferred).
4. **Nothing after close.** Once `phase` leaves `FINAL_CALL`, no new pickup, steal, or checkout is accepted. Checkouts already deferred from the last gameplay frame are banked. RoundManager builds `RoundResults` **one frame after** entering `CLOSED` (deferred), so those are counted.
5. **Single writer.** Only Cart changes `items[]`. Only RoundManager changes phase, time, scores, and floor pickups. Everyone else reads.
6. **Store spawns only `spilled`.** It never re-creates the items that moved into the winner.

The GUT test for [`GAME_SPEC.md` §11.2](GAME_SPEC.md#112-which-seam-breaks-first-and-how-we-test-it) checks invariants 1, 2, 3, 4 and 6 directly.

---

## 9. Change protocol

1. **Propose it** in your feature's `01-spec.md` under "Contract changes". Don't just edit the code.
2. **Log it** as a `Proposed` entry in [`DECISIONS.md`](DECISIONS.md), with the exact before/after signatures.
3. **Get sign-off.** Every owner whose system uses the changed item adds their name to the entry. A purely additive change (a new signal or a new optional method) needs only the owner of the providing system plus Anthony as integration owner.
4. **Land it in one PR** on an `integration/<slug>` branch: this file, `systems/shared/` code, the stubs, and the tests together. Bump the version at the top of this file.
5. **Announce it** with a handoff note in every affected section of [`PROGRESS.md`](PROGRESS.md).

Agents: if a task seems to need a contract change, **stop and tell the human**. Never change a signature silently to make your own code compile.
