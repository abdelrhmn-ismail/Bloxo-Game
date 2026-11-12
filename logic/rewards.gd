class_name Rewards
extends RefCounted
## Power-ups and free gifts (no ads): a daily gift and an hourly gift.
## Pure functions so they can be tested; SaveData stores the state.

const KINDS := ["hammer", "bomb", "shuffle", "undo"]
const MAX_EACH := 9
## Every new player starts with one of each.
const STARTER := {"hammer": 1, "bomb": 1, "shuffle": 1, "undo": 1}
## Gift for the first visit of each (local) day.
const DAILY_GIFT := {"hammer": 1, "bomb": 1, "shuffle": 1, "undo": 1}
## Seconds between free hourly gifts (one random power-up each).
const HOURLY_SECONDS := 3600


static func daily_available(last_claim_date: String, today: String) -> bool:
	return last_claim_date != today


## Seconds until the hourly gift is ready (0 = ready now).
## If the clock went backwards, the gift is simply available.
static func hourly_seconds_left(last_claim_time: float, now: float) -> int:
	if last_claim_time <= 0.0 or now < last_claim_time:
		return 0
	return maxi(0, ceili(HOURLY_SECONDS - (now - last_claim_time)))


## Adds to an inventory dictionary, capped at MAX_EACH. Returns the new count.
static func add(inventory: Dictionary, kind: String, amount: int) -> int:
	var value := clampi(int(inventory.get(kind, 0)) + amount, 0, MAX_EACH)
	inventory[kind] = value
	return value


static func random_kind(rng: RandomNumberGenerator) -> String:
	return KINDS[rng.randi_range(0, KINDS.size() - 1)]


## "42:07" style countdown.
static func format_time(seconds: int) -> String:
	return "%d:%02d" % [seconds / 60, seconds % 60]


## The 3x3 block of cells centred on `center` (clipped to the board).
static func bomb_area(center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := center + Vector2i(dx, dy)
			if c.x >= 0 and c.y >= 0 and c.x < Board.SIZE and c.y < Board.SIZE:
				cells.append(c)
	return cells
