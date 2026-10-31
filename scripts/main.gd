extends Node2D
## Plumb Line: travel from town to town and straighten each one's structure.
## Each town adds one new rule and has its own palette, which fades in as you arrive.

enum State { TITLE, MAP, TRAVEL, CARD, PLAY, CLEAR, FAILED, END }

const GROUND_Y := 226.0
const WATER_Y := 208.0
const TRAVEL_TIME := 3.4
const PHYS_DT := 1.0 / 240.0
const WAVE_W := 2.4
const DEFAULT_BAND := 0.3
const DEFAULT_HOLD := 3.0
const DEFAULT_FAIL := 9.0
const DEFAULT_CREEP := 0.08
const DEFAULT_STILL := 0.8
const GUST_K := 0.016
const OUT_OF_MOVES_WAIT := 3.0
const MAP_NODES := [Vector2(40, 180), Vector2(88, 112), Vector2(140, 178), Vector2(190, 96), Vector2(240, 166), Vector2(290, 92), Vector2(340, 172), Vector2(392, 104), Vector2(440, 176)]
const SAVE_PATH := "user://progress.cfg"


class Layer extends Node2D:
	var painter: Callable

	func _draw() -> void:
		if painter.is_valid():
			painter.call(self)


var state := State.TITLE
var town_i := 0
var level_i := 0
var unlocked := 1
var level: Dictionary = {}
var structs: Array = []
var sprites: Array = []
var vports: Array = []
var pivots: Array = []
var bridge_rest := 0.0

var hold := 0.0
var stage := 0
var moves_left := -1
var out_of_moves_t := 0.0
var timers: Array = []
var progress: Array = []
var level_t := 0.0
var phys_acc := 0.0
var drag := {}
var hover := {}
var touched := false
var gust := 0.0
var gust_timer := 3.0
var collapse_i := -1
var collapse_t := 0.0
var landed := false
var clear_t := 0.0
var banner := ""
var banner_t := 99.0

var pal_from := PackedVector3Array()
var pal_to := PackedVector3Array()
var acc_from := Vector3.ZERO
var acc_to := Vector3.ZERO
var pal_blend := 1.0
var pal_dur := 1.0
var pal_desat := false

var travel_t := 0.0
var travel_to := 0
var particles: Array = []
var shake := 0.0
var time_s := 0.0

var bg_tex: ImageTexture
var ground_tex: ImageTexture
var screen_mat: ShaderMaterial
var world: Layer
var ui: Layer


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	randomize()
	_load_progress()
	_make_textures()

	world = Layer.new()
	world.painter = _draw_world
	add_child(world)
	ui = Layer.new()
	ui.painter = _draw_ui
	add_child(ui)

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var rect := ColorRect.new()
	rect.size = Vector2(480, 270)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_mat = ShaderMaterial.new()
	screen_mat.shader = load("res://shaders/screen.gdshader")
	rect.material = screen_mat
	layer.add_child(rect)

	# Fade the first town's colours in from black.
	var black := PackedVector3Array()
	black.resize(10)
	black.fill(Vector3.ZERO)
	pal_from = black
	acc_from = Vector3.ZERO
	_start_palette(0, 2.5, false, true)
	_build_level(0, 0)
	state = State.TITLE


# --- palette ------------------------------------------------------------------

func _ramp_of(t: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for hex in Towns.TOWNS[t]["palette"]:
		var col := Color(str(hex))
		out.append(Vector3(col.r, col.g, col.b))
	return out


func _accent_of(t: int) -> Vector3:
	var col := Color(str(Towns.TOWNS[t]["accent"]))
	return Vector3(col.r, col.g, col.b)


func _shown_ramp() -> PackedVector3Array:
	var e := smoothstep(0.0, 1.0, pal_blend)
	var out := PackedVector3Array()
	for i in pal_to.size():
		out.append(pal_from[i].lerp(pal_to[i], e))
	return out


## Cross-fade from whatever is on screen now to town t's colours.
func _start_palette(t: int, duration: float, desaturate: bool, keep_from: bool = false) -> void:
	if not keep_from:
		pal_from = _shown_ramp()
		acc_from = acc_from.lerp(acc_to, smoothstep(0.0, 1.0, pal_blend))
	pal_to = _ramp_of(t)
	acc_to = _accent_of(t)
	pal_blend = 0.0
	pal_dur = duration
	pal_desat = desaturate
	screen_mat.set_shader_parameter("from_ramp", pal_from)
	screen_mat.set_shader_parameter("to_ramp", pal_to)
	screen_mat.set_shader_parameter("from_accent", acc_from)
	screen_mat.set_shader_parameter("to_accent", acc_to)


func _update_palette(delta: float) -> void:
	pal_blend = minf(1.0, pal_blend + delta / pal_dur)
	screen_mat.set_shader_parameter("blend", smoothstep(0.0, 1.0, pal_blend))
	# While travelling the old colours wash out before the new ones bloom in.
	var desat := 0.85 * sin(PI * pal_blend) if pal_desat else 0.0
	screen_mat.set_shader_parameter("desaturate", desat)


# --- levels -------------------------------------------------------------------

func _build_level(t: int, l: int) -> void:
	town_i = t
	level_i = l
	level = Towns.TOWNS[t]["levels"][l]
	for s in sprites:
		s.queue_free()
	for v in vports:
		v.queue_free()
	structs.clear()
	sprites.clear()
	vports.clear()
	pivots.clear()
	for def in level["structs"]:
		var vp := SubViewport.new()
		vp.size = Vector2i(Structure.VW, Structure.VH)
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		add_child(vp)
		var st := Structure.new()
		vp.add_child(st)
		st.setup(def)
		var sp := Sprite2D.new()
		sp.texture = vp.get_texture()
		sp.centered = false
		sp.offset = -Vector2(Structure.CX, Structure.BY)
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sp)
		move_child(sp, world.get_index())
		structs.append(st)
		sprites.append(sp)
		vports.append(vp)
		pivots.append(Vector2(float(def["x"]), WATER_Y if st.type == "barge" else GROUND_Y))
		st.creep_rate = float(level.get("creep", DEFAULT_CREEP))
		st.settle = deg_to_rad(float(level.get("settle", 0.0))) * _sag_direction(st)
		if level.has("waves"):
			st.wave_amp = st.torque_for_amplitude(deg_to_rad(float(level["waves"])), WAVE_W)
	if structs.size() == 2:
		bridge_rest = _bridge_ends()[0].distance_to(_bridge_ends()[1])
	hold = 0.0
	stage = 0
	moves_left = int(level.get("moves", -1))
	out_of_moves_t = 0.0
	timers.clear()
	for ev in level.get("timed", []):
		timers.append(float(ev["every"]))
	level_t = 0.0
	phys_acc = 0.0
	drag = {}
	hover = {}
	touched = false
	gust = 0.0
	gust_timer = 3.0
	collapse_i = -1
	landed = false
	particles.clear()
	_place_sprites()


func _restart() -> void:
	_build_level(town_i, level_i)
	state = State.PLAY


## The level to pick a town back up at; a finished town starts over.
func _resume_level(t: int) -> int:
	var reached: int = progress[t]
	return 0 if reached >= Towns.TOWNS[t]["levels"].size() else reached


func _go_to_town(t: int) -> void:
	if t == town_i:
		_build_level(t, _resume_level(t))
		_show_structures(true)
		state = State.CARD
	else:
		travel_to = t
		travel_t = 0.0
		state = State.TRAVEL
		_show_structures(false)
		_start_palette(t, TRAVEL_TIME, true)


func _clear() -> void:
	state = State.CLEAR
	clear_t = 0.0
	_release()
	var levels: Array = Towns.TOWNS[town_i]["levels"]
	progress[town_i] = maxi(int(progress[town_i]), level_i + 1)
	if level_i == levels.size() - 1:
		unlocked = maxi(unlocked, mini(town_i + 2, Towns.TOWNS.size()))
	_save_progress()
	for i in structs.size():
		var top := _world_point(i, Structure.TOP[structs[i].type])
		for _j in 40:
			particles.append({
				"p": top, "v": Vector2(randf_range(-50, 50), randf_range(-70, 10)),
				"life": randf_range(0.7, 1.6), "c": [Pal.PALE, Pal.WHITE, Pal.LIGHT].pick_random(), "g": 70.0,
			})


func _after_clear() -> void:
	var levels: Array = Towns.TOWNS[town_i]["levels"]
	if level_i + 1 < levels.size():
		_build_level(town_i, level_i + 1)
		state = State.PLAY
		banner = "%d / %d" % [level_i + 1, levels.size()]
		banner_t = 0.0
	elif town_i + 1 < Towns.TOWNS.size():
		_go_to_town(town_i + 1)
	else:
		state = State.END
		_show_structures(false)


func _fail(i: int) -> void:
	state = State.FAILED
	collapse_i = i
	collapse_t = 0.0
	landed = false
	_release()


## Completing a hold sets off the level's next event; after the last, it is cleared.
func _next_stage() -> void:
	var events: Array = level.get("events", [])
	if stage >= events.size():
		_clear()
		return
	_fire(events[stage])
	stage += 1
	hold = 0.0
	# The ground starts sagging a new way each stage, if it sags at all.
	var sag := deg_to_rad(float(level.get("settle", 0.0)))
	for st in structs:
		st.settle = sag * _sag_direction(st)


## A random side, unless that would run the player out of room to answer it.
func _sag_direction(st: Structure) -> float:
	var dir := 1.0 if randf() < 0.5 else -1.0
	return dir if st.capacity(-dir) >= st.capacity(dir) * 0.35 else -dir


func _fire(ev: Dictionary) -> void:
	var st: Structure = structs[int(ev.get("s", 0))]
	var say := ""
	match ev["e"]:
		"tremor":
			say = "TREMOR!"
			var dir := _sag_direction(st)
			var mag := minf(float(ev["mag"]), rad_to_deg(st.capacity(-dir) * 0.7 / st.stiff))
			st.kick(dir, mag)
			shake = 4.0
			_dust(pivots[int(ev.get("s", 0))], 24)
		"gust":
			say = "GALE!"
			gust = 1.6 if randf() < 0.5 else -1.6
		"add":
			say = "ADDED!"
			st.add_item(ev["item"])
		"swing":
			for it in st.items:
				if it["kind"] == "load":
					it["phi_v"] += float(ev["v"]) * (1.0 if randf() < 0.5 else -1.0)
		"load":
			for it in st.items:
				if it["kind"] == "load":
					it["m"] = maxf(4.0, float(it["m"]) + float(ev["dm"]))
		"leak":
			say = "LEAK!"
			for it in st.items:
				if it["kind"] == "tank":
					it["leak"] = 0.0
			st.items[int(ev["i"])]["leak"] = float(ev["rate"])
			st.items[int(ev["i"])]["leak_left"] = float(ev.get("amount", 5.0))
		"train":
			for car in ev["cars"]:
				var dir := float(car["dir"])
				var start := -dir * (150.0 + float(car.get("lead", 0.0)))
				st.add_item({"kind": "train", "m": car["m"], "y": 122.0, "x": start, "speed": dir * float(car["speed"])})
			say = "TRAIN >>>" if float(ev["cars"][0]["dir"]) > 0.0 else "<<< TRAIN"
	say = str(ev.get("say", say))
	if not say.is_empty():
		banner = say
		banner_t = 0.0


func _run_timed(dt: float) -> void:
	var list: Array = level.get("timed", [])
	for i in list.size():
		timers[i] -= dt
		if timers[i] <= 0.0:
			timers[i] = float(list[i]["every"]) * randf_range(0.8, 1.2)
			_fire(list[i])


func _show_structures(on: bool) -> void:
	for s in sprites:
		s.visible = on


# --- frame update -------------------------------------------------------------

func _process(delta: float) -> void:
	time_s += delta
	_update_palette(delta)
	for st in structs:
		st.anim_t = time_s
		st.queue_redraw()
	match state:
		State.TRAVEL:
			travel_t += delta
			if travel_t >= TRAVEL_TIME:
				_build_level(travel_to, _resume_level(travel_to))
				_show_structures(true)
				state = State.CARD
		State.PLAY, State.CLEAR, State.CARD, State.TITLE:
			if not drag.is_empty() and drag.has("off"):
				_drag_to(get_local_mouse_position())
			phys_acc += minf(delta, 0.1)
			while phys_acc >= PHYS_DT:
				phys_acc -= PHYS_DT
				_phys_step(PHYS_DT)
				if state != State.PLAY and state != State.CLEAR and state != State.CARD and state != State.TITLE:
					break
		State.FAILED:
			_update_collapse(delta)
	if state == State.CLEAR:
		clear_t += delta
	banner_t += delta
	_update_hover()
	_update_particles(delta)
	shake = maxf(0.0, shake - delta * 9.0)
	position = Vector2(randi_range(-1, 1), randi_range(-1, 1)) * roundf(shake)
	_place_sprites()
	world.queue_redraw()
	ui.queue_redraw()


func _phys_step(dt: float) -> void:
	level_t += dt
	var active := state == State.PLAY
	if active:
		_run_timed(dt)
	if level.get("gusts", false) and state == State.PLAY:
		gust_timer -= dt
		if gust_timer <= 0.0:
			gust = randf_range(0.6, 1.0) * (1.0 if randf() < 0.5 else -1.0)
			gust_timer = randf_range(5.5, 9.0)
	# Outside the if: a "gust" event can also fire in a level with no regular gusts.
	gust = move_toward(gust, 0.0, dt * 1.4)
	for i in structs.size():
		var st: Structure = structs[i]
		var ext := 0.0
		if level.has("waves"):
			ext += st.wave_amp * (sin(WAVE_W * level_t) + 0.5 * sin(WAVE_W * 1.7 * level_t + 1.3))
		ext += gust * st.stiff * float(level.get("gust_k", GUST_K))
		if level.has("couple") and structs.size() == 2:
			var other: Structure = structs[1 - i]
			ext += float(level["couple"]) * minf(st.stiff, other.stiff) * (other.theta - st.theta)
		st.ext_torque = ext
	for st in structs:
		st.step(dt, active)
		st.drop_finished_trains()
	if state != State.PLAY:
		return
	var band := deg_to_rad(float(level.get("band", DEFAULT_BAND)))
	var still := float(level.get("still", DEFAULT_STILL))
	var calm := true
	for st in structs:
		if absf(st.theta) > band or st.has_trains():
			calm = false
		elif not level.has("waves") and absf(rad_to_deg(st.omega)) > still:
			calm = false
	hold = hold + dt if calm else maxf(0.0, hold - dt * 1.5)
	if hold >= float(level.get("hold", DEFAULT_HOLD)):
		_next_stage()
		return
	# Out of moves and it has come to rest crooked: nothing can save it now.
	if moves_left == 0 and drag.is_empty() and not calm:
		out_of_moves_t += dt
		if out_of_moves_t >= OUT_OF_MOVES_WAIT:
			_fail(_worst_index())
			return
	else:
		out_of_moves_t = 0.0
	var fail := deg_to_rad(float(level.get("fail", DEFAULT_FAIL)))
	for i in structs.size():
		if absf(structs[i].theta) > fail:
			_fail(i)
			return


func _update_collapse(delta: float) -> void:
	if collapse_i < 0:
		return
	collapse_t += delta
	var st: Structure = structs[collapse_i]
	if landed:
		return
	var dir := signf(st.theta)
	st.omega += dir * (1.2 + 4.0 * absf(sin(st.theta))) * delta
	st.theta += st.omega * delta
	if randf() < 0.5:
		_dust(pivots[collapse_i] + Vector2(dir * randf_range(0, 24), -1), 1)
	if absf(st.theta) > 1.4:
		landed = true
		collapse_t = 0.0
		sprites[collapse_i].visible = false
		shake = 6.0
		var axis := Vector2(0, -1).rotated(st.theta)
		var h: float = Structure.TOP[st.type].y
		var cols := [Pal.MAIN, Pal.LIGHT, Pal.MID, Pal.PALE, Pal.DEEP]
		for _i in 160:
			var t := randf()
			particles.append({
				"p": pivots[collapse_i] + axis * h * t + Vector2(randf_range(-6, 6), randf_range(-6, 6)),
				"v": Vector2(randf_range(-40, 40) + axis.x * 25.0 * t, randf_range(-90, -10)),
				"life": randf_range(1.5, 3.5), "c": cols.pick_random(), "g": 180.0,
			})


func _update_particles(delta: float) -> void:
	var floor_y := WATER_Y if _is_sea() else GROUND_Y
	for p in particles:
		var v: Vector2 = p["v"]
		var pos: Vector2 = p["p"]
		v.y += float(p["g"]) * delta
		pos += v * delta
		if pos.y > floor_y - 1.0 and v.y > 0.0 and float(p["g"]) > 0.0:
			pos.y = floor_y - 1.0
			v = Vector2(v.x * 0.5, -v.y * 0.25)
		p["v"] = v
		p["p"] = pos
		p["life"] -= delta
	particles = particles.filter(func(p): return p["life"] > 0.0)
	if state == State.TRAVEL and randf() < 0.3:
		particles.append({"p": Vector2(146, 164), "v": Vector2(-30, -12), "life": 1.2, "c": Pal.MID, "g": -4.0})


func _dust(p: Vector2, count: int) -> void:
	for _i in count:
		particles.append({
			"p": p + Vector2(randf_range(-2, 2), 0), "v": Vector2(randf_range(-14, 14), randf_range(-14, -2)),
			"life": randf_range(0.4, 1.0), "c": [Pal.DEEP, Pal.MID, Pal.LIGHT].pick_random(), "g": -6.0,
		})


# --- geometry -----------------------------------------------------------------

func _is_sea() -> bool:
	return not structs.is_empty() and structs[0].type == "barge"


func _pivot(i: int) -> Vector2:
	var p: Vector2 = pivots[i]
	if structs[i].type == "barge":
		p.y += roundf(1.5 * sin(time_s * 1.3))
	return p


func _place_sprites() -> void:
	for i in sprites.size():
		sprites[i].position = _pivot(i)
		sprites[i].rotation = structs[i].theta


## Physics point (x right, y up) on structure i to screen.
func _world_point(i: int, local: Vector2) -> Vector2:
	return _pivot(i) + Vector2(local.x, -local.y).rotated(structs[i].theta)


func _to_local(i: int, m: Vector2) -> Vector2:
	var v := (m - _pivot(i)).rotated(-structs[i].theta)
	return Vector2(v.x, -v.y)


func _bridge_ends() -> Array:
	var a: Vector2 = Structure.BRIDGE[structs[0].type]
	var b: Vector2 = Structure.BRIDGE[structs[1].type]
	return [_world_point(0, a), _world_point(1, Vector2(-b.x, b.y))]


func _worst_index() -> int:
	var worst := 0
	for i in structs.size():
		if absf(structs[i].theta) > absf(structs[worst].theta):
			worst = i
	return worst


func _worst_tilt() -> float:
	var worst := 0.0
	for st in structs:
		if absf(st.theta) > absf(worst):
			worst = st.theta
	return rad_to_deg(worst)


# --- input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press(get_local_mouse_position())
			else:
				_release()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and state in [State.PLAY, State.FAILED]:
			_restart()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		match key.keycode:
			KEY_F11:
				var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_R:
				if state in [State.PLAY, State.FAILED, State.CLEAR]:
					_restart()
			KEY_ESCAPE:
				if state in [State.TITLE, State.MAP]:
					get_tree().quit()
				elif state != State.TRAVEL:
					state = State.MAP
					_release()
					_show_structures(false)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if state != State.PLAY and state != State.MAP:
					_press(Vector2(-100, -100))
				elif state == State.MAP:
					_go_to_town(mini(unlocked - 1, Towns.TOWNS.size() - 1))


func _press(m: Vector2) -> void:
	match state:
		State.TITLE:
			state = State.MAP
			_show_structures(false)
		State.MAP:
			for t in MAP_NODES.size():
				if t < unlocked and m.distance_to(MAP_NODES[t]) < 16.0:
					_go_to_town(t)
		State.CARD:
			state = State.PLAY
		State.CLEAR:
			if clear_t > 0.5:
				_after_clear()
		State.FAILED:
			if landed:
				_restart()
		State.END:
			state = State.MAP
		State.PLAY:
			var h := _hit(m)
			if h.is_empty():
				return
			touched = true
			var st: Structure = structs[h["s"]]
			var it: Dictionary = st.items[h["i"]]
			if it["kind"] == "tank" or it["kind"] == "winch":
				st.pumping = h["i"]
				drag = {"s": h["s"], "i": h["i"]}
			elif moves_left != 0:
				drag = {"s": h["s"], "i": h["i"], "off": float(it["x"]) - _to_local(h["s"], m).x, "start": float(it["tx"])}


## Letting go: a free item stops where it is, a notched one finishes its move.
func _release() -> void:
	if drag.has("off"):
		var it: Dictionary = structs[drag["s"]].items[drag["i"]]
		if float(it.get("notch", 0.0)) > 0.0:
			if moves_left > 0 and absf(float(it["tx"]) - float(drag["start"])) > 0.01:
				moves_left -= 1
		else:
			it["tx"] = it["x"]
	drag = {}
	_end_pump()


func _end_pump() -> void:
	for st in structs:
		st.pumping = -1


func _hit(m: Vector2) -> Dictionary:
	for s in structs.size():
		if s == collapse_i:
			continue
		var i: int = structs[s].hit_item(_to_local(s, m))
		if i >= 0:
			return {"s": s, "i": i}
	return {}


func _drag_to(m: Vector2) -> void:
	var st: Structure = structs[drag["s"]]
	var it: Dictionary = st.items[drag["i"]]
	var target := clampf(_to_local(drag["s"], m).x + float(drag["off"]), it["min"], it["max"])
	var notch := float(it.get("notch", 0.0))
	if notch > 0.0:
		target = clampf(snappedf(target, notch), it["min"], it["max"])
	it["tx"] = target


func _update_hover() -> void:
	var h := {}
	if state == State.PLAY:
		h = drag if not drag.is_empty() else _hit(get_local_mouse_position())
	for s in structs.size():
		structs[s].hover_item = int(h["i"]) if not h.is_empty() and int(h["s"]) == s else -1
	var over_map := false
	if state == State.MAP:
		for t in mini(unlocked, MAP_NODES.size()):
			if get_local_mouse_position().distance_to(MAP_NODES[t]) < 16.0:
				over_map = true
	var shape := Input.CURSOR_POINTING_HAND if not h.is_empty() or over_map else Input.CURSOR_ARROW
	if not drag.is_empty() and drag.has("off"):
		shape = Input.CURSOR_HSIZE
	Input.set_default_cursor_shape(shape)
	hover = h


# --- textures -----------------------------------------------------------------

func _make_textures() -> void:
	var img := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	for y in 270:
		for x in 480:
			var d := Vector2(x - 240.0, y - 120.0).length() / 300.0
			var col := Pal.BG2.lerp(Pal.BG, clampf(d, 0.0, 1.0))
			if x % 3 == 0 and y % 3 == 0:
				col = col.lerp(Pal.GRID, 0.7)
			img.set_pixel(x, y, col)
	for _i in 70:
		img.set_pixelv(Vector2i(randi_range(4, 475), randi_range(4, 180)), [Pal.DEEP, Pal.MID, Pal.INK].pick_random())
	for _i in 6:
		var p := Vector2i(randi_range(10, 470), randi_range(10, 140))
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			img.set_pixelv(p + o, Pal.MID)
		img.set_pixelv(p, Pal.LIGHT)
	bg_tex = ImageTexture.create_from_image(img)

	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var g := Image.create(480, 44, false, Image.FORMAT_RGBA8)
	for y in 44:
		for x in 480:
			var density := 0.32 - float(y) / 44.0 * 0.25 + 0.06 * sin(y * 0.5 + sin(x * 0.05) * 1.5)
			var b: float = bayer[(y % 4) * 4 + (x % 4)] / 16.0
			g.set_pixel(x, y, Pal.DEEP if b < density else Pal.INK)
	ground_tex = ImageTexture.create_from_image(g)
	queue_redraw()


# --- drawing: world -----------------------------------------------------------

func _draw() -> void:
	if bg_tex:
		draw_texture(bg_tex, Vector2.ZERO)


func _draw_world(c: CanvasItem) -> void:
	if state in [State.MAP, State.TRAVEL, State.END]:
		_draw_particles(c)
		return
	if _is_sea():
		_draw_sea(c)
	else:
		c.draw_texture(ground_tex, Vector2(0, GROUND_Y + 2))
		c.draw_rect(Rect2(0, GROUND_Y, 480, 1), Pal.LIGHT)
		c.draw_rect(Rect2(0, GROUND_Y + 1, 480, 1), Pal.MID)
		for gx in range(0, 480, 7):
			c.draw_rect(Rect2(gx + (gx * 13) % 5, GROUND_Y - 1, 2 + gx % 3, 1), Pal.MID)

	if structs[0].type == "pier":
		_draw_embankments(c)

	# Crane loads hang in world space, below the jib tip.
	for i in structs.size():
		if i == collapse_i and landed:
			continue
		for it in structs[i].items:
			if it["kind"] == "train":
				_draw_train(c, i, it)
			if it["kind"] == "load":
				var hook := _world_point(i, Vector2(it["x"], it["y"] - 3.0))
				var weight_pos := hook + Vector2(sin(it["phi"]), cos(it["phi"])) * float(it["len"])
				c.draw_line(hook, weight_pos, Pal.PALE)
				var r := Rect2(weight_pos.round() + Vector2(-6, 0), Vector2(13, 9))
				c.draw_rect(r, Pal.LIGHT)
				c.draw_rect(r.grow(-1), Pal.MID)
				c.draw_rect(Rect2(r.position.x + 1, r.position.y + 1, 11, 1), Pal.PALE)

	# Rope bridge between the twins.
	if structs.size() == 2 and collapse_i < 0:
		var ends := _bridge_ends()
		var a: Vector2 = ends[0]
		var b: Vector2 = ends[1]
		var sag := clampf(12.0 - (a.distance_to(b) - bridge_rest) * 0.8, 1.0, 22.0)
		var prev := a
		for k in range(1, 21):
			var t := k / 20.0
			var p := a.lerp(b, t) + Vector2(0, sin(t * PI) * sag)
			c.draw_line(prev, p, Pal.LIGHT)
			if k % 2 == 0:
				c.draw_rect(Rect2(p.floor() + Vector2(-1, 0), Vector2(3, 2)), Pal.MID)
			prev = p

	# Plumb lines.
	if state != State.TITLE:
		var band := deg_to_rad(float(level.get("band", DEFAULT_BAND)))
		var fail := deg_to_rad(float(level.get("fail", DEFAULT_FAIL)))
		for i in structs.size():
			if i == collapse_i:
				continue
			var st: Structure = structs[i]
			var top := _world_point(i, Structure.TOP[st.type])
			var base := _world_point(i, Vector2(Structure.TOP[st.type].x, 0))
			var straight := absf(st.theta) < band
			var col := Pal.PALE
			if straight:
				col = Pal.WHITE
			elif absf(st.theta) > fail * 0.7 and int(time_s * 5.0) % 2 == 0:
				col = Pal.WARN
			var fx := roundf(top.x)
			c.draw_rect(Rect2(fx - 1, top.y - 1, 3, 1), col)
			var y := int(top.y) + 3
			while y < int(base.y) - 4:
				c.draw_rect(Rect2(fx, y, 1, 2), col)
				y += 4
			c.draw_rect(Rect2(fx - 1, base.y - 4, 3, 3), col)
			# Target bracket at the base centre.
			var bx := roundf(base.x)
			c.draw_rect(Rect2(bx - 4, base.y + 2, 1, 3), Pal.LIGHT)
			c.draw_rect(Rect2(bx + 4, base.y + 2, 1, 3), Pal.LIGHT)
			c.draw_rect(Rect2(bx - 4, base.y + 4, 9, 1), Pal.WHITE if straight else Pal.MID)

	if level.get("gusts", false) and absf(gust) > 0.2:
		for _i in 3:
			var y := randf_range(60, 190)
			var x := randf_range(0, 480)
			c.draw_rect(Rect2(x, y, 10 + randf() * 14, 1), Color(Pal.PALE, absf(gust) * 0.6))
	_draw_particles(c)


## The valley sides the viaduct's rails run out onto.
func _draw_embankments(c: CanvasItem) -> void:
	var top := GROUND_Y - 120.0
	var cx: float = pivots[0].x
	var left := cx - Structure.DECK_HW
	var right := cx + Structure.DECK_HW
	for r: Rect2 in [Rect2(0, top, left, GROUND_Y - top), Rect2(right, top, 480 - right, GROUND_Y - top)]:
		c.draw_rect(r, Pal.GRID)
		c.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Pal.PALE)
		c.draw_rect(Rect2(r.position + Vector2(0, 1), Vector2(r.size.x, 6)), Pal.INK)


func _draw_train(c: CanvasItem, i: int, it: Dictionary) -> void:
	var p := _world_point(i, Vector2(float(it["x"]), float(it["y"]))).round()
	var back := -signf(float(it["speed"]))
	# Engine and cars; heavier trains are longer.
	var cars := 1 + int(float(it["m"]) / 8.0)
	for k in cars:
		var cx := p.x + back * k * 16.0
		c.draw_rect(Rect2(cx - 7, p.y - 9, 14, 8), Pal.MAIN if k == 0 else Pal.MID)
		c.draw_rect(Rect2(cx - 7, p.y - 9, 14, 1), Pal.PALE)
		c.draw_rect(Rect2(cx - 5, p.y - 1, 3, 2), Pal.DEEP)
		c.draw_rect(Rect2(cx + 2, p.y - 1, 3, 2), Pal.DEEP)
	c.draw_rect(Rect2(p.x - back * 4 - 1, p.y - 13, 3, 4), Pal.LIGHT)
	if randf() < 0.3:
		particles.append({"p": p + Vector2(-back * 4, -14), "v": Vector2(back * 18.0, -14), "life": 0.8, "c": Pal.MID, "g": -4.0})


func _draw_sea(c: CanvasItem) -> void:
	for x in 480:
		var sy := WATER_Y + 2.0 * sin(x * 0.05 + time_s * 1.5) + sin(x * 0.13 - time_s * 2.1)
		sy = roundf(sy)
		c.draw_rect(Rect2(x, sy, 1, 270 - sy), Color(Pal.INK, 0.82))
		c.draw_rect(Rect2(x, sy, 1, 1), Pal.LIGHT)
		if (x + int(time_s * 8.0)) % 23 == 0:
			c.draw_rect(Rect2(x, sy + 6 + (x % 3) * 9, 4, 1), Pal.DEEP)


func _draw_particles(c: CanvasItem) -> void:
	for p in particles:
		var col: Color = p["c"]
		col.a = clampf(float(p["life"]) * 2.0, 0.0, 1.0)
		var pos: Vector2 = p["p"]
		c.draw_rect(Rect2(pos.floor(), Vector2.ONE), col)


# --- drawing: UI --------------------------------------------------------------

func _frame(c: CanvasItem, r: Rect2, col: Color) -> void:
	c.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), col)
	c.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), col)
	c.draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), col)
	c.draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), col)


func _dim(c: CanvasItem, amount: float = 0.7) -> void:
	c.draw_rect(Rect2(-8, -8, 496, 286), Color(Pal.BG, amount))


func _blink(rate: float = 2.0) -> bool:
	return int(time_s * rate) % 2 == 0


func _draw_ui(c: CanvasItem) -> void:
	match state:
		State.TITLE:
			_draw_title(c)
		State.MAP:
			_draw_map(c)
		State.TRAVEL:
			_draw_travel(c)
		State.CARD:
			_draw_hud(c)
			_draw_card(c)
		State.PLAY:
			_draw_hud(c)
		State.CLEAR:
			_draw_hud(c)
			PixelFont.draw_shadowed(c, "STRAIGHT!", Vector2(240 - PixelFont.width("STRAIGHT!", 4) / 2.0, 70), Pal.WHITE, 4)
			if clear_t > 0.5 and _blink():
				PixelFont.draw_centered(c, "CLICK TO CONTINUE", 240, 106, Pal.PALE)
		State.FAILED:
			_draw_hud(c)
			if landed and collapse_t > 0.8:
				PixelFont.draw_shadowed(c, "IT FELL", Vector2(240 - PixelFont.width("IT FELL", 4) / 2.0, 70), Pal.WARN, 4)
				if _blink():
					PixelFont.draw_centered(c, "CLICK TO TRY AGAIN", 240, 106, Pal.PALE)
		State.END:
			_draw_end(c)


func _draw_hud(c: CanvasItem) -> void:
	var tilt := _worst_tilt()
	var band := float(level.get("band", DEFAULT_BAND))
	var straight := absf(tilt) < band
	var box := Rect2(10, 8, 120, 46)
	c.draw_rect(box, Color(Pal.BG, 0.85))
	_frame(c, box, Pal.WHITE if straight else Pal.LIGHT)
	_frame(c, box.grow(-2), Color(Pal.DEEP, 0.8))
	PixelFont.draw(c, "TILT", box.position + Vector2(7, 6), Pal.LIGHT)
	if absf(tilt) >= 0.005:
		PixelFont.draw_right(c, "<<" if tilt < 0.0 else ">>", box.end.x - 7, box.position.y + 6, Pal.LIGHT)
	var col := Pal.WHITE if straight else Pal.PALE
	if absf(tilt) > float(level.get("fail", DEFAULT_FAIL)) * 0.7 and _blink(5.0):
		col = Pal.WARN
	PixelFont.draw_shadowed(c, "%.2f°" % absf(tilt), box.position + Vector2(7, 18), col, 3)
	var frac := clampf(hold / float(level.get("hold", DEFAULT_HOLD)), 0.0, 1.0)
	c.draw_rect(Rect2(10, 57, 120, 2), Pal.INK)
	if frac > 0.0:
		c.draw_rect(Rect2(10, 57, 120 * frac, 2), Pal.WHITE)
	# One pip per hold this level asks for; events strike between them.
	var stages: int = (level.get("events", []) as Array).size() + 1
	if stages > 1:
		for k in stages:
			c.draw_rect(Rect2(10 + k * 7, 62, 5, 3), Pal.PALE if k < stage else (Pal.MID if k == stage else Pal.INK))
	if moves_left >= 0:
		PixelFont.draw(c, "MOVES %d" % moves_left, Vector2(10, 62), Pal.WARN if moves_left == 0 else Pal.PALE)

	var town: Dictionary = Towns.TOWNS[town_i]
	PixelFont.draw_right(c, town["name"], 470, 10, Pal.MAIN, 2)
	var levels: Array = town["levels"]
	for l in levels.size():
		var x := 470.0 - (levels.size() - l) * 9.0 + 2.0
		var done := l < level_i or (l == level_i and state == State.CLEAR)
		c.draw_rect(Rect2(x, 28, 6, 6), Pal.PALE if done else (Pal.MID if l == level_i else Pal.INK))

	if state == State.PLAY or state == State.CARD:
		var lines: Array = []
		if level_i == 0:
			lines = town["rule"]
		elif level.has("hint"):
			lines = [level["hint"]]
		var a := 1.0
		if touched:
			a = clampf(1.0 - (level_t - 6.0) / 2.0, 0.0, 1.0) if level_t > 6.0 else 1.0
		for i in lines.size():
			PixelFont.draw_centered(c, lines[i], 240, 246 + i * 10 - (lines.size() - 1) * 10, Color(Pal.PALE, a))

	if banner_t < 1.6:
		var ba := clampf(1.6 - banner_t, 0.0, 1.0)
		PixelFont.draw_shadowed(c, banner, Vector2(240 - PixelFont.width(banner, 3) / 2.0, 70), Color(Pal.WHITE, ba), 3)
	PixelFont.draw(c, "R RETRY  ESC MAP", Vector2(10, 260), Pal.DEEP)


func _draw_title(c: CanvasItem) -> void:
	PixelFont.draw_shadowed(c, "PLUMB LINE", Vector2(240 - PixelFont.width("PLUMB LINE", 4) / 2.0, 22), Pal.MAIN, 4)
	PixelFont.draw_centered(c, "STRAIGHTEN THE WORLD, ONE TOWN AT A TIME", 240, 58, Pal.LIGHT)
	if _blink():
		PixelFont.draw_centered(c, "CLICK TO BEGIN", 240, 250, Pal.WHITE)


func _draw_map(c: CanvasItem) -> void:
	PixelFont.draw_shadowed(c, "THE JOURNEY", Vector2(240 - PixelFont.width("THE JOURNEY", 3) / 2.0, 16), Pal.MAIN, 3)
	# Dashed road between towns.
	for t in MAP_NODES.size() - 1:
		var a: Vector2 = MAP_NODES[t]
		var b: Vector2 = MAP_NODES[t + 1]
		var n := int(a.distance_to(b) / 5.0)
		for k in n:
			if k % 2 == 0:
				var p := a.lerp(b, float(k) / n).floor()
				c.draw_rect(Rect2(p, Vector2(2, 1)), Pal.LIGHT if t + 1 < unlocked else Pal.INK)
	for t in MAP_NODES.size():
		var p: Vector2 = MAP_NODES[t]
		var town: Dictionary = Towns.TOWNS[t]
		var open := t < unlocked
		var done := t < unlocked - 1
		var col := Pal.PALE if done else (Pal.MAIN if open else Pal.INK)
		c.draw_rect(Rect2(p - Vector2(13, 13), Vector2(27, 27)), Color(Pal.BG, 0.9))
		_frame(c, Rect2(p - Vector2(13, 13), Vector2(27, 27)), col)
		if t == town_i and _blink():
			_frame(c, Rect2(p - Vector2(15, 15), Vector2(31, 31)), Pal.WHITE)
		_draw_icon(c, town["icon"], p + Vector2(0, 9), 1, col)
		PixelFont.draw_centered(c, town["name"] if open else "???", p.x, p.y + 18, col)
	PixelFont.draw_centered(c, "CLICK A TOWN", 240, 250, Pal.MID)


## Tiny silhouette of a town's structure, base centred on `base`.
func _draw_icon(c: CanvasItem, icon: String, base: Vector2, s: int, col: Color) -> void:
	var r := func(x: float, y: float, w: float, h: float) -> void:
		c.draw_rect(Rect2(base.x + x * s, base.y - (y + h) * s, w * s, h * s), col)
	match icon:
		"campanile":
			r.call(-3, 0, 7, 15)
			r.call(-4, 5, 9, 1)
			r.call(-4, 10, 9, 1)
			r.call(-2, 15, 5, 2)
		"watertower":
			r.call(-5, 0, 1, 9)
			r.call(5, 0, 1, 9)
			r.call(-6, 9, 13, 1)
			r.call(-5, 10, 11, 7)
		"crane":
			r.call(-1, 0, 2, 16)
			r.call(-6, 15, 18, 1)
			r.call(-6, 12, 3, 3)
			r.call(10, 9, 1, 6)
			r.call(9, 7, 3, 2)
		"barge":
			r.call(-9, 0, 19, 3)
			r.call(1, 3, 3, 11)
			r.call(0, 14, 5, 2)
		"twins":
			r.call(-8, 0, 5, 15)
			r.call(4, 0, 5, 15)
			r.call(-3, 10, 7, 1)
		"clock":
			r.call(-4, 0, 9, 13)
			r.call(-3, 13, 7, 2)
			r.call(-1, 15, 3, 2)
		"viaduct":
			r.call(-10, 11, 21, 2)
			r.call(-2, 0, 5, 11)
			r.call(-7, 13, 9, 3)
		"mast":
			r.call(0, 0, 1, 17)
			for k in 3:
				r.call(-3 + k, k * 6, 7 - k * 2, 1)
		"meridian":
			r.call(0, 0, 1, 17)
			r.call(-7, 8, 15, 1)
			r.call(-2, 3, 5, 2)


func _draw_travel(c: CanvasItem) -> void:
	var t := travel_t / TRAVEL_TIME
	var town: Dictionary = Towns.TOWNS[travel_to]
	# Rolling hills, rails and the destination growing on the horizon.
	for x in 480:
		var hy := 170.0 + 8.0 * sin((x + travel_t * 40.0) * 0.03) + 4.0 * sin((x + travel_t * 40.0) * 0.07)
		c.draw_rect(Rect2(x, roundf(hy), 1, 186 - roundf(hy)), Pal.INK)
	var dest_x := lerpf(560.0, 330.0, smoothstep(0.0, 1.0, t))
	_draw_icon(c, town["icon"], Vector2(dest_x, 186), 4, Pal.DEEP)
	c.draw_rect(Rect2(0, 186, 480, 1), Pal.LIGHT)
	c.draw_rect(Rect2(0, 190, 480, 1), Pal.MID)
	var off := fposmod(travel_t * 140.0, 12.0)
	for i in 42:
		c.draw_rect(Rect2(i * 12 - off, 187, 2, 3), Pal.DEEP)
	# Little engine.
	var bob := roundf(sin(travel_t * 18.0) * 0.6)
	var ex := 140.0
	c.draw_rect(Rect2(ex, 172 + bob, 30, 10), Pal.MAIN)
	c.draw_rect(Rect2(ex + 18, 164 + bob, 12, 8), Pal.LIGHT)
	c.draw_rect(Rect2(ex + 21, 166 + bob, 6, 4), Pal.PALE)
	c.draw_rect(Rect2(ex + 4, 166 + bob, 4, 6), Pal.MID)
	c.draw_rect(Rect2(ex, 172 + bob, 30, 1), Pal.PALE)
	for wx in [ex + 5, ex + 15, ex + 25]:
		c.draw_rect(Rect2(wx - 2, 182, 5, 4), Pal.DEEP)
		c.draw_rect(Rect2(wx - 1, 183, 3, 2), Pal.LIGHT)
	c.draw_rect(Rect2(ex - 26, 174 + bob, 22, 8), Pal.MID)
	c.draw_rect(Rect2(ex - 26, 174 + bob, 22, 1), Pal.LIGHT)
	for wx in [ex - 20, ex - 10]:
		c.draw_rect(Rect2(wx - 2, 182, 5, 4), Pal.DEEP)
	var a := clampf(t * 3.0, 0.0, 1.0)
	PixelFont.draw_centered(c, "NEXT STOP", 240, 60, Color(Pal.LIGHT, a))
	PixelFont.draw_shadowed(c, town["name"], Vector2(240 - PixelFont.width(town["name"], 4) / 2.0, 74), Color(Pal.MAIN, a), 4)


func _draw_card(c: CanvasItem) -> void:
	_dim(c, 0.6)
	var town: Dictionary = Towns.TOWNS[town_i]
	PixelFont.draw_shadowed(c, town["name"], Vector2(240 - PixelFont.width(town["name"], 4) / 2.0, 70), Pal.MAIN, 4)
	PixelFont.draw_centered(c, town["subtitle"], 240, 104, Pal.LIGHT)
	var rule: Array = town["rule"]
	for i in rule.size():
		PixelFont.draw_centered(c, rule[i], 240, 126 + i * 11, Pal.PALE)
	if _blink():
		PixelFont.draw_centered(c, "CLICK TO START", 240, 196, Pal.WHITE)


func _draw_end(c: CanvasItem) -> void:
	PixelFont.draw_shadowed(c, "ALL STRAIGHT", Vector2(240 - PixelFont.width("ALL STRAIGHT", 4) / 2.0, 90), Pal.MAIN, 4)
	PixelFont.draw_centered(c, "EVERY TOWN STANDS TALL. THANKS FOR PLAYING.", 240, 128, Pal.LIGHT)
	if _blink():
		PixelFont.draw_centered(c, "CLICK FOR THE MAP", 240, 200, Pal.WHITE)


# --- save -----------------------------------------------------------------

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked = clampi(int(cfg.get_value("journey", "unlocked", 1)), 1, Towns.TOWNS.size())
		progress = cfg.get_value("journey", "levels", [])
	progress.resize(Towns.TOWNS.size())
	for t in progress.size():
		progress[t] = int(progress[t]) if progress[t] != null else 0


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("journey", "unlocked", unlocked)
	cfg.set_value("journey", "levels", progress)
	cfg.save(SAVE_PATH)
