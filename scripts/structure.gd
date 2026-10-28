class_name Structure
extends Node2D
## One structure: its rocking physics and its pixel art. The art is drawn
## upright into a SubViewport; the main scene shows it on a rotated sprite.
##
## Physics: a rigid body on springy ground,
##   I*theta'' = M*cos(theta) + Wh*sin(theta) - k*theta - c*theta' + external
## where M = sum(m*x) is the off-centre load and Wh = sum(m*y) the P-delta term.
## Coordinates are pixels from the pivot, x right, y up.

const VW := 200
const VH := 240
const CX := 100
const BY := 222
const BODY_M := 100.0
const BODY_H := {"campanile": 62.0, "watertower": 45.0, "crane": 60.0, "barge": 30.0}
const TOP := {"campanile": Vector2(0, 144), "watertower": Vector2(0, 118), "crane": Vector2(0, 146), "barge": Vector2(8, 108)}
const FOOT := {"campanile": 22.0, "watertower": 28.0, "crane": 16.0, "barge": 46.0}
const BRIDGE := {"campanile": Vector2(22, 100), "watertower": Vector2(34, 86)}
const PENDULUM_G := 400.0
const PUMP_RATE := 8.0
const PIPE_TIME := 0.7

var type := "campanile"
var items: Array = []
var theta := 0.0
var omega := 0.0
var alpha := 0.0
var k := 0.0
var stiff := 1.0
var c := 0.0
var inertia := 1.0
var body_x := 0.0
var body_h := 60.0
var ext_torque := 0.0
var wave_amp := 0.0
var pumping := -1
var hover_item := -1
var anim_t := 0.0


func setup(def: Dictionary) -> void:
	type = def["type"]
	body_h = BODY_H[type]
	items.clear()
	var ans_moment := 0.0
	var wh := BODY_M * body_h
	for src in def["items"]:
		var it: Dictionary = src.duplicate(true)
		for key in ["x", "y", "m", "ans", "min", "max", "cap", "level", "len", "phi", "damp"]:
			if it.has(key):
				it[key] = float(it[key])
		match it["kind"]:
			"tank":
				it["pipe"] = 0.0
				it["slosh"] = 0.0
				it["slosh_v"] = 0.0
				it["inflow"] = 0.0
				ans_moment += it["ans"] * it["x"]
				wh += it["level"] * it["y"]
			"load":
				it["phi_v"] = 0.0
				ans_moment += it["m"] * it["x"]
				wh += it["m"] * it["y"]
			_:
				ans_moment += it["m"] * it["ans"]
				wh += it["m"] * it["y"]
		items.append(it)
	# Offset the body's own weight so the "answer" layout stands exactly upright.
	body_x = -ans_moment / BODY_M
	stiff = wh * (float(def.get("soil", 1.35)) - 1.0)
	k = wh + stiff
	var w := TAU / float(def.get("period", 2.2))
	inertia = stiff / (w * w)
	c = 2.0 * float(def.get("zeta", 0.5)) * sqrt(inertia * stiff)
	theta = _equilibrium()
	omega = 0.0
	queue_redraw()


static func mass_of(it: Dictionary) -> float:
	return it["level"] if it["kind"] == "tank" else it["m"]


func _moments() -> Vector2:
	var mx := BODY_M * body_x
	var wh := BODY_M * body_h
	for it in items:
		var m := mass_of(it)
		var x: float = it["x"]
		match it["kind"]:
			"tank":
				x += it["slosh"]
				wh += it["pipe"] * it["y"]
			"load":
				# Cable tension pulls the jib tip sideways when the load swings.
				mx += m * sin(it["phi"]) * it["y"] * 0.35
		mx += m * x
		wh += m * it["y"]
	return Vector2(mx, wh)


func _equilibrium() -> float:
	var mo := _moments()
	var th := 0.0
	for _i in 30:
		th = (mo.x * cos(th) + mo.y * (sin(th) - th)) / (k - mo.y)
	return th


func torque_for_amplitude(amp_rad: float, w: float) -> float:
	return amp_rad * sqrt(pow(stiff - inertia * w * w, 2.0) + pow(c * w, 2.0))


func step(dt: float) -> void:
	_update_items(dt)
	var mo := _moments()
	var tau := mo.x * cos(theta) + mo.y * sin(theta) - k * theta - c * omega + ext_torque
	alpha = tau / inertia
	omega += alpha * dt
	theta += omega * dt


func _update_items(dt: float) -> void:
	# Pumping: draw water from the other tanks into a pipe feeding the held tank.
	if pumping >= 0:
		var dst: Dictionary = items[pumping]
		var available := 0.0
		for i in items.size():
			if i != pumping and items[i]["kind"] == "tank":
				available += items[i]["level"]
		var room: float = dst["cap"] - dst["level"] - dst["pipe"]
		var amount := minf(PUMP_RATE * dt, minf(available, room))
		if amount > 0.0:
			for i in items.size():
				if i != pumping and items[i]["kind"] == "tank":
					items[i]["level"] -= amount * items[i]["level"] / available
			dst["pipe"] += amount
	for it in items:
		match it["kind"]:
			"tank":
				var flow: float = it["pipe"] * dt / PIPE_TIME
				it["pipe"] -= flow
				it["level"] += flow
				it["inflow"] = flow / dt
				var acc: float = -36.0 * it["slosh"] - 0.9 * it["slosh_v"] - alpha * 30.0 + it["inflow"] * 0.6
				it["slosh_v"] += acc * dt
				it["slosh"] = clampf(it["slosh"] + it["slosh_v"] * dt, -5.0, 5.0)
			"load":
				var acc: float = -PENDULUM_G / it["len"] * sin(it["phi"]) - it["damp"] * it["phi_v"] - alpha * it["y"] / it["len"]
				it["phi_v"] += acc * dt
				it["phi"] += it["phi_v"] * dt


## Where an item can be grabbed, in physics coordinates.
static func item_center(it: Dictionary) -> Vector2:
	match it["kind"]:
		"bell":
			return Vector2(it["x"], it["y"] - 5.0)
		"crate":
			return Vector2(it["x"], it["y"] + 4.0)
		"counter":
			return Vector2(it["x"], it["y"] - 5.0)
	return Vector2(it["x"], it["y"])


func hit_item(local: Vector2) -> int:
	for i in items.size():
		var it: Dictionary = items[i]
		match it["kind"]:
			"tank":
				if absf(local.x - it["x"]) < 10.0 and absf(local.y - it["y"]) < 14.0:
					return i
			"bell", "crate", "counter":
				if local.distance_to(item_center(it)) < 9.0:
					return i
	return -1


# --- drawing ------------------------------------------------------------------

## Physics coordinates to viewport pixels.
func _p(x: float, y: float) -> Vector2:
	return Vector2(CX + x, BY - y)


func _r(x0: float, y_top: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(CX + x0, BY - y_top, w, h), col)


## Colour across a lit cylinder; u is 0 at the left edge and 1 at the right.
static func shade(u: float, bias: float = 0.0) -> Color:
	var l := cos((u - 0.32) * PI * 0.95) + bias
	if l > 0.93:
		return Pal.PALE
	if l > 0.72:
		return Pal.LIGHT
	if l > 0.35:
		return Pal.MAIN
	if l > 0.0:
		return Pal.MID
	return Pal.DEEP


## A shaded band; neighbouring columns of one colour become one rect.
func _cyl(x0: float, y_top: float, w: int, h: float, bias: float = 0.0) -> void:
	var run_start := 0
	var run_col := shade(0.5 / w, bias)
	for xx in range(1, w + 1):
		var col := run_col if xx == w else shade((xx + 0.5) / w, bias)
		if xx == w or col != run_col:
			_r(x0 + run_start, y_top, xx - run_start, h, run_col)
			run_start = xx
			run_col = col


func _draw() -> void:
	match type:
		"campanile":
			_draw_campanile()
		"watertower":
			_draw_watertower()
		"crane":
			_draw_crane()
		"barge":
			_draw_barge()
	for i in items.size():
		_draw_item(items[i], i == hover_item)


func _ledge(y: float, hw: int) -> void:
	_cyl(-hw, y + 1, hw * 2, 1, 0.25)
	_r(-hw + 1, y, hw * 2 - 2, 1, Color(Pal.INK, 0.7))


func _arcade(top: float, h: float, hw: int, count: int, blind: bool) -> void:
	for j in count:
		var a := -PI / 2.0 + (j + 0.5) * PI / count
		var w := int(round(4.0 * cos(a)))
		if w < 1:
			continue
		var x0 := roundf(sin(a) * (hw - 3.0) - w / 2.0)
		var y0 := top - (6.0 if blind else 4.0)
		var y1 := top - h + (3.0 if blind else 1.0)
		var col := Pal.MID if blind else Pal.INK
		_r(x0, y0 - 1, w, y0 - y1 - 1, col)
		_r(x0 + (1 if w >= 3 else 0), y0, maxi(w - 2, 1), 1, col)
		var edge := x0 - 1 if a < 0.3 else x0 + w
		_r(edge, y0 - 1, 1, y0 - y1 - 1, Pal.PALE if a < -0.4 else Pal.LIGHT)


func _draw_campanile() -> void:
	var hw := 22
	_cyl(-hw, 26, hw * 2, 26)
	_arcade(26, 26, hw, 5, true)
	_r(-3, 12, 6, 12, Pal.INK)
	var y := 26.0
	for _t in 5:
		_cyl(-hw, y + 20, hw * 2, 20)
		_arcade(y + 20, 20, hw, 6, false)
		_ledge(y, hw + 2)
		y += 20.0
	_ledge(y, hw + 2)
	var bhw := 16
	_cyl(-bhw, y + 18, bhw * 2, 18)
	_arcade(y + 18, 18, bhw, 5, false)
	_ledge(y + 18, bhw + 2)
	for i in range(-bhw - 1, bhw + 1, 3):
		_r(i, y + 22, 2, 2, shade((i + bhw + 2.0) / (bhw * 2.0 + 4.0), 0.2))
	_cyl(-hw - 2, 2, hw * 2 + 4, 2, -0.1)


func _draw_watertower() -> void:
	# Legs with cross bracing.
	for side in [-1.0, 1.0]:
		draw_line(_p(side * 28, 0), _p(side * 18, 84), Pal.LIGHT, 2.0)
		draw_line(_p(side * 14, 0), _p(side * 8, 84), Pal.MID, 1.0)
	for band in 3:
		var y0 := band * 28.0
		var y1 := y0 + 28.0
		var w0 := 28.0 - y0 / 84.0 * 10.0
		var w1 := 28.0 - y1 / 84.0 * 10.0
		draw_line(_p(-w0, y0), _p(w1, y1), Pal.MID)
		draw_line(_p(w0, y0), _p(-w1, y1), Pal.MID)
		_r(-w1, y1, w1 * 2, 1, Pal.LIGHT)
	_cyl(-34, 88, 68, 4, 0.1)
	_r(-34, 84, 68, 1, Pal.INK)
	# Pipe along the platform.
	var tanks := []
	for it in items:
		if it["kind"] == "tank":
			tanks.append(it)
	if tanks.size() > 1:
		var x0: float = tanks[0]["x"]
		var x1: float = tanks[-1]["x"]
		_r(x0, 91, x1 - x0, 2, Pal.DEEP)
		for it in tanks:
			if it["pipe"] > 0.05:
				# Flow dots running towards the tank being filled.
				var dir := 1.0 if it["x"] > (x0 + x1) * 0.5 else -1.0
				for d in range(0, int(x1 - x0), 6):
					var px := x0 + fposmod(d + dir * anim_t * 30.0, x1 - x0)
					_r(px, 91, 2, 1, Pal.WHITE)


func _draw_crane() -> void:
	_cyl(-16, 3, 32, 3, -0.1)
	# Lattice mast.
	_r(-5, 120, 1, 120, Pal.LIGHT)
	_r(4, 120, 1, 120, Pal.MID)
	for y in range(0, 120, 8):
		draw_line(_p(-5, y), _p(4, y + 8), Pal.MID)
		draw_line(_p(4, y), _p(-5, y + 8), Pal.DEEP)
	# Cab.
	_r(5, 122, 11, 12, Pal.MAIN)
	_r(7, 120, 7, 5, Pal.PALE)
	_r(5, 122, 11, 1, Pal.LIGHT)
	# Jib truss.
	_r(-46, 130, 114, 1, Pal.LIGHT)
	_r(-46, 124, 114, 1, Pal.MID)
	for x in range(-46, 68, 6):
		draw_line(_p(x, 124), _p(x + 3, 130), Pal.MID)
		draw_line(_p(x + 3, 130), _p(x + 6, 124), Pal.DEEP)
	# Apex and ties.
	_r(-1, 146, 2, 16, Pal.LIGHT)
	draw_line(_p(0, 146), _p(-46, 130), Pal.MID)
	draw_line(_p(0, 146), _p(66, 130), Pal.MID)
	# Load trolley.
	for it in items:
		if it["kind"] == "load":
			_r(it["x"] - 3, 124, 7, 3, Pal.PALE)


func _draw_barge() -> void:
	# Hull, narrowing below the waterline.
	for y in range(-10, 7):
		var hw := 46 - maxi(0, -y - 4) * 2
		_cyl(-hw, y + 1, hw * 2, 1, -0.3 if y < 0 else 0.0)
	_r(-46, 8, 92, 2, Pal.PALE)
	_r(-44, 3, 88, 1, Pal.DEEP)
	# Lighthouse on the deck.
	for y in range(8, 90):
		var f := (y - 8.0) / 82.0
		var hw := int(round(lerpf(9.0, 6.0, f)))
		var dark := int((y - 8) / 10.0) % 2 == 1
		_cyl(8 - hw, y + 1, hw * 2, 1, -0.35 if dark else 0.0)
	_r(6, 26, 3, 5, Pal.INK)
	_r(6, 56, 3, 5, Pal.INK)
	_cyl(-2, 92, 20, 2, 0.2)
	var glow := 0.5 + 0.5 * sin(anim_t * 2.4)
	_r(3, 102, 10, 10, Pal.PALE.lerp(Pal.WHITE, glow))
	_r(5, 102, 1, 10, Pal.DEEP)
	_r(10, 102, 1, 10, Pal.DEEP)
	for r in 5:
		_cyl(8 - (5 - r), 103 + r, (5 - r) * 2, 1, 0.1)
	_r(8, 109, 1, 2, Pal.LIGHT)


func _bell(p: Vector2, size: int, col: Color) -> void:
	# size 0 small, 1 medium, 2 large
	var w := 3 + size * 2
	draw_rect(Rect2(p.x - w / 2.0 + 1, p.y, w - 2, 1), col)
	draw_rect(Rect2(p.x - w / 2.0, p.y + 1, w, 2 + size), col)
	draw_rect(Rect2(p.x - w / 2.0 - 1, p.y + 3 + size, w + 2, 1), col)
	draw_rect(Rect2(p.x - w / 2.0, p.y + 1, 1, 2 + size), Pal.WHITE)
	draw_rect(Rect2(p.x, p.y + 4 + size, 1, 1), Pal.INK)


func _draw_item(it: Dictionary, lit: bool) -> void:
	var blink := lit and int(anim_t * 6.0) % 2 == 0
	match it["kind"]:
		"bell":
			var y: float = it["y"]
			# Track the bell slides along.
			for x in range(int(it["min"]), int(it["max"]) + 1, 3):
				_r(x, y, 1, 1, Pal.PALE if lit else Pal.DEEP)
			var size := 2 if it["m"] >= 16 else (1 if it["m"] >= 10 else 0)
			var p := _p(roundf(it["x"]), y)
			draw_rect(Rect2(p.x, p.y, 1, 2), Pal.LIGHT)
			# Dark backing so the bell reads against the masonry.
			draw_rect(Rect2(p.x - 3 - size, p.y + 1, 7 + size * 2, 6 + size), Color(Pal.INK, 0.8))
			_bell(p + Vector2(0, 2), size, Pal.WHITE if blink else Pal.PALE)
		"crate":
			var w := 9.0 if it["m"] >= 8 else 7.0
			var p := _p(roundf(it["x"]) - floorf(w / 2.0), it["y"] + 8.0)
			var r := Rect2(p, Vector2(w, 8))
			draw_rect(r, Pal.WHITE if blink else Pal.LIGHT)
			draw_rect(r.grow(-1), Pal.MAIN)
			draw_line(r.position + Vector2(1, 1), r.end - Vector2(2, 2), Pal.LIGHT)
			draw_line(Vector2(r.position.x + 1, r.end.y - 2), Vector2(r.end.x - 2, r.position.y + 1), Pal.LIGHT)
		"counter":
			var p := _p(roundf(it["x"]) - 5.0, it["y"] - 1.0)
			for x in range(int(it["min"]), int(it["max"]) + 1, 3):
				_r(x, it["y"] - 1.0, 1, 1, Pal.PALE if lit else Pal.DEEP)
			draw_rect(Rect2(p, Vector2(11, 9)), Pal.WHITE if blink else Pal.LIGHT)
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(9, 7)), Pal.MID)
			for sx in range(1, 10, 3):
				draw_rect(Rect2(p + Vector2(sx, 1), Vector2(1, 7)), Pal.DEEP)
		"tank":
			var x: float = it["x"]
			var y: float = it["y"]
			var cap: float = it["cap"]
			# Stand up from the platform if the tank sits high.
			if y - 12.0 > 92.0:
				_r(x - 6, y - 12.0, 1, y - 104.0, Pal.LIGHT)
				_r(x + 5, y - 12.0, 1, y - 104.0, Pal.MID)
			var top := _p(x - 8, y + 12)
			var r := Rect2(top, Vector2(16, 24))
			draw_rect(r, Pal.WHITE if blink else Pal.LIGHT)
			draw_rect(r.grow(-1), Pal.INK)
			var fill := clampf(it["level"] / cap, 0.0, 1.0) * 22.0
			var slosh: float = it["slosh"]
			for col in 14:
				var h := clampf(fill + slosh * (col - 6.5) / 6.5, 0.0, 22.0)
				if h >= 1.0:
					draw_rect(Rect2(r.position.x + 1 + col, r.end.y - 1 - h, 1, h), Pal.MAIN)
					draw_rect(Rect2(r.position.x + 1 + col, r.end.y - 1 - h, 1, 1), Pal.PALE)
			# Roof.
			for row in 4:
				draw_rect(Rect2(r.position.x + row * 2, r.position.y - 1 - row, 16 - row * 4, 1), Pal.LIGHT if row % 2 == 0 else Pal.MAIN)
			if lit:
				draw_rect(Rect2(r.position.x + 6, r.position.y - 7, 4, 1), Pal.WHITE)
		"load":
			pass  # hangs in world space; drawn by the main scene
