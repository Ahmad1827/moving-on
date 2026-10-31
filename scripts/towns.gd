class_name Towns
extends RefCounted
## The journey: nine towns, each with its own palette, structure and one new rule.
##
## Structure coordinates are pixels from the pivot, x right, y up.
## Movable items have a start "x" and an "ans": the structure stands exactly
## straight when every item sits at its "ans" (tanks use "level" / "ans" for water).
##   soil   > 1; closer to 1 = softer ground, more sensitive and slower
##   period seconds per sway, zeta damping (lower = wobblier)
##
## Level keys:
##   band, hold   how close (degrees) and for how long (seconds) counts as straight
##   fail         the tilt (degrees) at which it falls
##   creep        how fast a lean feeds itself, per second
##   settle       steady sag in degrees per second; its direction changes each stage
##   events       each hold completed fires the next event, then you must hold again
##   gust_k       how hard gusts push, in radians of lean (default 0.016)
##   timed        events that recur every "every" seconds whatever you are doing
##   moves        limited moves (puzzle levels); pair with notched items and no creep
##
## Events ("e"): tremor(mag), gust, add(s, item), swing(v), load(dm), leak(i, rate, amount),
## train(cars: dir, m, speed, lead). "s" picks the structure, default 0.

const TOWNS := [
	{
		"name": "VIOLA", "subtitle": "THE BELL TOWER", "icon": "campanile",
		"rule": ["DRAG THE BELLS. HEAVY ONES MOVE SLOWLY.", "THE GROUND SINKS FASTER THE MORE IT LEANS."],
		"palette": ["0a0715", "130e26", "1b1536", "221a44", "352a69", "5442a4", "7b68da", "a394ef", "cec4ff", "f1edff"],
		"accent": "ff5d8f",
		"levels": [
			{"band": 0.4, "hold": 2.5, "creep": 0.05, "events": [{"e": "tremor", "mag": 0.8}],
			 "structs": [{"type": "campanile", "x": 240, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
				{"kind": "bell", "m": 14, "y": 116, "x": 14, "ans": 0, "min": -18, "max": 18}]}]},
			{"band": 0.3, "hold": 3.0, "creep": 0.06, "settle": 0.05, "hint": "SMALL BELLS ARE FOR FINE TUNING.",
			 "events": [{"e": "tremor", "mag": 1.0}, {"e": "tremor", "mag": 1.2}],
			 "structs": [{"type": "campanile", "x": 240, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
				{"kind": "bell", "m": 14, "y": 116, "x": -15, "ans": 2, "min": -18, "max": 18},
				{"kind": "bell", "m": 6, "y": 56, "x": 15, "ans": -4, "min": -18, "max": 18}]}]},
			{"band": 0.25, "hold": 3.0, "creep": 0.08, "settle": 0.08, "hint": "SOFT GROUND. THEY KEEP HANGING NEW BELLS.",
			 "events": [{"e": "tremor", "mag": 1.0},
				{"e": "add", "say": "NEW BELL!", "item": {"kind": "bell", "m": 10, "y": 96, "x": 14, "ans": 0, "min": -18, "max": 18}},
				{"e": "tremor", "mag": 1.2}],
			 "structs": [{"type": "campanile", "x": 240, "soil": 1.22, "period": 2.8, "zeta": 0.5, "items": [
				{"kind": "bell", "m": 18, "y": 116, "x": 2, "ans": -7, "min": -18, "max": 18},
				{"kind": "bell", "m": 5, "y": 56, "x": 15, "ans": 6, "min": -18, "max": 18}]}]},
			{"band": 0.25, "hold": 3.0, "creep": 0.1, "settle": 0.08, "hint": "THE EARTH WILL NOT WAIT FOR YOU.",
			 "timed": [{"e": "tremor", "mag": 0.5, "every": 12.0}], "events": [{"e": "tremor", "mag": 1.0}, {"e": "tremor", "mag": 1.0}],
			 "structs": [{"type": "campanile", "x": 240, "soil": 1.2, "period": 2.8, "zeta": 0.3, "items": [
				{"kind": "bell", "m": 14, "y": 116, "x": -4, "ans": 5, "min": -18, "max": 18},
				{"kind": "bell", "m": 8, "y": 96, "x": 12, "ans": 3, "min": -18, "max": 18},
				{"kind": "bell", "m": 4, "y": 56, "x": -10, "ans": 2, "min": -18, "max": 18}]}]},
			{"band": 0.35, "hold": 3.0, "creep": 0.08, "settle": 0.05, "hint": "A HUGE BELL. THE SMALL ONE MUST DO THE WORK.",
			 "timed": [{"e": "tremor", "mag": 0.4, "every": 15.0}],
			 "events": [{"e": "tremor", "mag": 1.0},
				{"e": "add", "say": "NEW BELL!", "item": {"kind": "bell", "m": 6, "y": 76, "x": -9, "ans": 0, "min": -18, "max": 18}},
				{"e": "tremor", "mag": 1.0}],
			 "structs": [{"type": "campanile", "x": 240, "soil": 1.22, "period": 2.8, "zeta": 0.45, "items": [
				{"kind": "bell", "m": 20, "y": 116, "x": 3, "ans": -2, "min": -18, "max": 18},
				{"kind": "bell", "m": 4, "y": 56, "x": 12, "ans": 2, "min": -18, "max": 18}]}]},
			{"band": 0.22, "hold": 3.0, "creep": 0.12, "settle": 0.1, "fail": 8, "hint": "THE WHOLE TOWN IS WATCHING.",
			 "timed": [{"e": "tremor", "mag": 0.5, "every": 11.0}],
			 "events": [{"e": "tremor", "mag": 1.2}, {"e": "tremor", "mag": 1.4}, {"e": "gust"}, {"e": "tremor", "mag": 1.6}],
			 "gusts": true,
			 "structs": [{"type": "campanile", "x": 240, "soil": 1.16, "period": 3.0, "zeta": 0.3, "items": [
				{"kind": "bell", "m": 18, "y": 116, "x": 5, "ans": -3, "min": -18, "max": 18},
				{"kind": "bell", "m": 10, "y": 96, "x": -6, "ans": 4, "min": -18, "max": 18},
				{"kind": "bell", "m": 6, "y": 76, "x": 12, "ans": 3, "min": -18, "max": 18},
				{"kind": "bell", "m": 3, "y": 56, "x": -14, "ans": -2, "min": -18, "max": 18}]}]},
		],
	},
	{
		"name": "TEALBROOK", "subtitle": "THE WATER TOWER", "icon": "watertower",
		"rule": ["HOLD A TANK TO PUMP WATER INTO IT.", "THE PIPES KEEP FLOWING AFTER YOU LET GO."],
		"palette": ["050f12", "0a1d22", "0f2a30", "123840", "1a5560", "23808a", "35b0b0", "6ad6cc", "b0f0e4", "eafff9"],
		"accent": "ffb36b",
		"levels": [
			{"band": 0.4, "hold": 2.5, "creep": 0.05, "hint": "SHORT TAPS. THE WATER IS STILL COMING.",
			 "events": [{"e": "tremor", "mag": 0.8}],
			 "structs": [{"type": "watertower", "x": 240, "soil": 1.4, "period": 1.9, "zeta": 0.4, "items": [
				{"kind": "tank", "x": -22, "y": 98, "cap": 24, "level": 14, "ans": 10},
				{"kind": "tank", "x": 22, "y": 98, "cap": 24, "level": 8, "ans": 12}]}]},
			{"band": 0.3, "hold": 3.0, "creep": 0.06, "settle": 0.05, "hint": "THE MIDDLE TANK DOES NOT TIP ANYTHING.",
			 "events": [{"e": "tremor", "mag": 1.0}, {"e": "tremor", "mag": 1.0}],
			 "structs": [{"type": "watertower", "x": 240, "soil": 1.4, "period": 1.9, "zeta": 0.4, "items": [
				{"kind": "tank", "x": -28, "y": 98, "cap": 20, "level": 2, "ans": 3},
				{"kind": "tank", "x": 0, "y": 98, "cap": 20, "level": 16, "ans": 5},
				{"kind": "tank", "x": 28, "y": 98, "cap": 20, "level": 2, "ans": 12}]}]},
			{"band": 0.3, "hold": 3.0, "creep": 0.08, "settle": 0.05, "hint": "A TANK HAS SPRUNG A LEAK.",
			 "events": [{"e": "leak", "i": 0, "rate": 0.25}, {"e": "leak", "i": 1, "rate": 0.3}],
			 "structs": [{"type": "watertower", "x": 240, "soil": 1.3, "period": 2.2, "zeta": 0.35, "items": [
				{"kind": "tank", "x": -22, "y": 112, "cap": 24, "level": 15, "ans": 12},
				{"kind": "tank", "x": 24, "y": 86, "cap": 24, "level": 12, "ans": 15}]}]},
			{"band": 0.3, "hold": 3.0, "creep": 0.08, "settle": 0.05, "hint": "HIGHER WATER LEANS HARDER.",
			 "events": [{"e": "tremor", "mag": 1.0}, {"e": "leak", "i": 2, "rate": 0.3}, {"e": "tremor", "mag": 1.2}],
			 "structs": [{"type": "watertower", "x": 240, "soil": 1.25, "period": 2.2, "zeta": 0.3, "items": [
				{"kind": "tank", "x": -28, "y": 112, "cap": 20, "level": 6, "ans": 7},
				{"kind": "tank", "x": 0, "y": 98, "cap": 20, "level": 10, "ans": 8},
				{"kind": "tank", "x": 28, "y": 86, "cap": 20, "level": 10, "ans": 11}]}]},
			{"band": 0.3, "hold": 3.0, "creep": 0.08, "settle": 0.05, "hint": "THE GROUND SHAKES AND THE TOWER WEEPS.",
			 "timed": [{"e": "tremor", "mag": 0.4, "every": 13.0}],
			 "events": [{"e": "leak", "i": 0, "rate": 0.2}, {"e": "leak", "i": 2, "rate": 0.2}, {"e": "tremor", "mag": 1.2}],
			 "structs": [{"type": "watertower", "x": 240, "soil": 1.22, "period": 2.4, "zeta": 0.28, "items": [
				{"kind": "tank", "x": -28, "y": 106, "cap": 20, "level": 13, "ans": 10},
				{"kind": "tank", "x": 8, "y": 98, "cap": 20, "level": 6, "ans": 6},
				{"kind": "tank", "x": 28, "y": 92, "cap": 20, "level": 9, "ans": 12}]}]},
			{"band": 0.28, "hold": 3.0, "creep": 0.1, "settle": 0.06, "fail": 8, "gusts": true, "hint": "EVERYTHING LEAKS. KEEP IT UPRIGHT ANYWAY.",
			 "timed": [{"e": "tremor", "mag": 0.4, "every": 13.0}],
			 "events": [{"e": "leak", "i": 1, "rate": 0.2}, {"e": "tremor", "mag": 1.2}, {"e": "leak", "i": 0, "rate": 0.22}, {"e": "tremor", "mag": 1.4}],
			 "structs": [{"type": "watertower", "x": 240, "soil": 1.2, "period": 2.4, "zeta": 0.25, "items": [
				{"kind": "tank", "x": -30, "y": 112, "cap": 22, "level": 11, "ans": 13},
				{"kind": "tank", "x": -8, "y": 98, "cap": 22, "level": 9, "ans": 7},
				{"kind": "tank", "x": 30, "y": 90, "cap": 22, "level": 14, "ans": 14}]}]},
		],
	},
	{
		"name": "GREYMOOR", "subtitle": "THE CLOCK TOWER", "icon": "clock",
		"rule": ["WEIGHTS ONLY LOCK INTO THE NOTCHES.", "YOU HAVE A FEW MOVES. THINK FIRST."],
		"palette": ["07090d", "10141b", "171d27", "1f2733", "2f3b4d", "4a5a72", "6f829c", "9dafc4", "cdd9e4", "f2f6fa"],
		"accent": "ffd34d",
		"levels": [
			{"band": 0.1, "hold": 1.5, "creep": 0.0, "moves": 2, "hint": "EACH MOVE COUNTS. THE TILT TELLS YOU HOW FAR OFF YOU ARE.",
			 "structs": [{"type": "clock", "x": 240, "soil": 1.35, "period": 2.0, "zeta": 0.6, "items": [
				{"kind": "bell", "m": 14, "y": 110, "x": 12, "ans": -6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 5, "y": 60, "x": -12, "ans": 12, "min": -18, "max": 18, "notch": 6, "rate": 40}]}]},
			{"band": 0.1, "hold": 1.5, "creep": 0.0, "moves": 2, "hint": "THE BIG WEIGHT JUMPS. THE LITTLE ONES SETTLE IT.",
			 "structs": [{"type": "clock", "x": 240, "soil": 1.35, "period": 2.0, "zeta": 0.6, "items": [
				{"kind": "bell", "m": 14, "y": 110, "x": -18, "ans": 6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 9, "y": 90, "x": 18, "ans": -6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 5, "y": 60, "x": 0, "ans": 12, "min": -18, "max": 18, "notch": 6, "rate": 40}]}]},
			{"band": 0.1, "hold": 1.5, "creep": 0.0, "moves": 2, "hint": "THREE WEIGHTS, TWO MOVES. ONE IS ALREADY RIGHT.",
			 "structs": [{"type": "clock", "x": 240, "soil": 1.3, "period": 2.0, "zeta": 0.6, "items": [
				{"kind": "bell", "m": 14, "y": 110, "x": 6, "ans": 6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 9, "y": 90, "x": -12, "ans": 12, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 5, "y": 60, "x": 18, "ans": -18, "min": -18, "max": 18, "notch": 6, "rate": 40}]}]},
			{"band": 0.09, "hold": 1.5, "creep": 0.0, "moves": 2, "hint": "FOUR WEIGHTS. COUNT BEFORE YOU TOUCH ANYTHING.",
			 "structs": [{"type": "clock", "x": 240, "soil": 1.28, "period": 2.0, "zeta": 0.6, "items": [
				{"kind": "bell", "m": 14, "y": 110, "x": -12, "ans": 6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 9, "y": 90, "x": 6, "ans": 6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 7, "y": 74, "x": 18, "ans": -6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 5, "y": 60, "x": -6, "ans": 18, "min": -18, "max": 18, "notch": 6, "rate": 40}]}]},
			{"band": 0.09, "hold": 2.0, "creep": 0.0, "moves": 4, "couple": 0.5, "hint": "TWO CLOCKS, ONE ROPE, FOUR MOVES.",
			 "structs": [
				{"type": "clock", "x": 160, "soil": 1.32, "period": 2.0, "zeta": 0.6, "items": [
					{"kind": "bell", "m": 14, "y": 110, "x": 12, "ans": -6, "min": -18, "max": 18, "notch": 6, "rate": 40},
					{"kind": "bell", "m": 5, "y": 60, "x": -18, "ans": 6, "min": -18, "max": 18, "notch": 6, "rate": 40}]},
				{"type": "clock", "x": 320, "soil": 1.32, "period": 2.0, "zeta": 0.6, "items": [
					{"kind": "bell", "m": 11, "y": 110, "x": -6, "ans": 12, "min": -18, "max": 18, "notch": 6, "rate": 40},
					{"kind": "bell", "m": 7, "y": 60, "x": 12, "ans": -12, "min": -18, "max": 18, "notch": 6, "rate": 40}]}]},
			{"band": 0.08, "hold": 2.0, "creep": 0.0, "moves": 3, "hint": "FIVE WEIGHTS, THREE MOVES. DO THE SUM FIRST.",
			 "structs": [{"type": "clock", "x": 240, "soil": 1.25, "period": 2.0, "zeta": 0.6, "items": [
				{"kind": "bell", "m": 16, "y": 116, "x": -18, "ans": -6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 11, "y": 98, "x": 12, "ans": 6, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 7, "y": 80, "x": 0, "ans": 12, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 5, "y": 62, "x": -12, "ans": -12, "min": -18, "max": 18, "notch": 6, "rate": 40},
				{"kind": "bell", "m": 3, "y": 44, "x": 0, "ans": 18, "min": -18, "max": 18, "notch": 6, "rate": 40}]}]},
		],
	},
	{
		"name": "AMBERLY", "subtitle": "THE CRANE", "icon": "crane",
		"rule": ["SLIDE THE COUNTERWEIGHT.", "MIND THE SWINGING LOAD."],
		"palette": ["120a04", "21140a", "2c1c0e", "3a2611", "5a3a16", "8a5a1e", "c08530", "e8b050", "ffd890", "fff4dc"],
		"accent": "5ad0ff",
		"levels": [
			{"band": 0.4, "hold": 2.5, "creep": 0.05, "events": [{"e": "load", "dm": 3, "say": "HEAVIER LOAD!"}],
			 "structs": [{"type": "crane", "x": 228, "soil": 1.3, "period": 2.4, "zeta": 0.5, "items": [
				{"kind": "load", "m": 14, "x": 58, "y": 124, "len": 34, "phi": 0.0, "damp": 0.6},
				{"kind": "counter", "m": 30, "y": 124, "x": -18, "ans": -27, "min": -44, "max": -6, "rate": 8}]}]},
			{"band": 0.35, "hold": 3.0, "creep": 0.06, "settle": 0.05, "hint": "WAIT FOR THE SWING TO CALM DOWN.",
			 "events": [{"e": "swing", "v": 0.7}, {"e": "load", "dm": -3, "say": "LOAD DROPPED!"}],
			 "structs": [{"type": "crane", "x": 228, "soil": 1.3, "period": 2.4, "zeta": 0.5, "items": [
				{"kind": "load", "m": 14, "x": 58, "y": 124, "len": 34, "phi": 0.3, "damp": 0.6},
				{"kind": "counter", "m": 30, "y": 124, "x": -34, "ans": -24, "min": -44, "max": -6, "rate": 8}]}]},
			{"band": 0.3, "hold": 3.0, "creep": 0.08, "settle": 0.06, "hint": "A HEAVIER LOAD ON SOFTER GROUND.",
			 "events": [{"e": "load", "dm": 3, "say": "HEAVIER LOAD!"}, {"e": "swing", "v": 0.7}, {"e": "load", "dm": -4, "say": "LOAD DROPPED!"}],
			 "structs": [{"type": "crane", "x": 228, "soil": 1.2, "period": 2.8, "zeta": 0.5, "items": [
				{"kind": "load", "m": 22, "x": 62, "y": 124, "len": 40, "phi": 0.15, "damp": 0.8},
				{"kind": "counter", "m": 36, "y": 124, "x": -35, "ans": -38, "min": -48, "max": -6, "rate": 8}]}]},
			{"band": 0.3, "hold": 3.0, "creep": 0.1, "settle": 0.08, "hint": "THE ENGINE KICKS WHEN IT HOISTS.",
			 "timed": [{"e": "swing", "v": 0.35, "every": 10.0}], "events": [{"e": "tremor", "mag": 1.0}, {"e": "load", "dm": 3, "say": "HEAVIER LOAD!"}],
			 "structs": [{"type": "crane", "x": 228, "soil": 1.2, "period": 2.8, "zeta": 0.35, "items": [
				{"kind": "load", "m": 20, "x": 60, "y": 124, "len": 44, "phi": 0.2, "damp": 0.9},
				{"kind": "counter", "m": 36, "y": 124, "x": -30, "ans": -33, "min": -48, "max": -6, "rate": 8},
				{"kind": "counter", "m": 6, "y": 124, "x": -14, "ans": -10, "min": -24, "max": 0, "rate": 14}]}]},
			{"band": 0.28, "hold": 3.0, "creep": 0.1, "settle": 0.07, "gusts": true, "hint": "A SECOND WEIGHT FOR THE FINE WORK. AND WIND.",
			 "timed": [{"e": "swing", "v": 0.35, "every": 10.0}],
			 "events": [{"e": "load", "dm": 3, "say": "HEAVIER LOAD!"}, {"e": "gust"}, {"e": "load", "dm": -4, "say": "LOAD DROPPED!"}],
			 "structs": [{"type": "crane", "x": 228, "soil": 1.17, "period": 3.0, "zeta": 0.35, "items": [
				{"kind": "load", "m": 22, "x": 62, "y": 124, "len": 46, "phi": 0.2, "damp": 0.9},
				{"kind": "counter", "m": 36, "y": 124, "x": -37, "ans": -39, "min": -48, "max": -6, "rate": 8},
				{"kind": "counter", "m": 5, "y": 124, "x": -6, "ans": -4, "min": -24, "max": 0, "rate": 14}]}]},
			{"band": 0.32, "hold": 3.0, "creep": 0.09, "settle": 0.05, "fail": 9, "gusts": true, "hint": "THE LAST LIFT OF THE DAY.",
			 "timed": [{"e": "swing", "v": 0.35, "every": 10.0}, {"e": "tremor", "mag": 0.4, "every": 14.0}],
			 "events": [{"e": "load", "dm": 3, "say": "HEAVIER LOAD!"}, {"e": "tremor", "mag": 0.9}, {"e": "load", "dm": -4, "say": "LOAD DROPPED!"}, {"e": "tremor", "mag": 1.0}],
			 "structs": [{"type": "crane", "x": 228, "soil": 1.18, "period": 3.0, "zeta": 0.38, "items": [
				{"kind": "load", "m": 22, "x": 62, "y": 124, "len": 48, "phi": 0.2, "damp": 0.9},
				{"kind": "counter", "m": 36, "y": 124, "x": -37, "ans": -39, "min": -50, "max": -6, "rate": 8},
				{"kind": "counter", "m": 5, "y": 124, "x": -8, "ans": -4, "min": -24, "max": 0, "rate": 14}]}]},
		],
	},
	{
		"name": "VERDEPORT", "subtitle": "THE HARBOUR LIGHT", "icon": "barge",
		"rule": ["DRAG THE CARGO ALONG THE DECK.", "RIDE OUT THE WAVES."],
		"palette": ["04100b", "0a1d14", "10281b", "153524", "1e5236", "2f7d4c", "4cae68", "86d68c", "c6f2c0", "f0fff0"],
		"accent": "ff6b8a",
		"levels": [
			{"waves": 0.3, "band": 0.6, "hold": 3.5, "fail": 12, "creep": 0.04, "events": [{"e": "tremor", "mag": 1.0, "say": "ROGUE WAVE!"}],
			 "structs": [{"type": "barge", "x": 240, "soil": 1.6, "period": 3.0, "zeta": 0.18, "items": [
				{"kind": "crate", "m": 8, "y": 8, "x": 10, "ans": -10, "min": -40, "max": 40}]}]},
			{"waves": 0.45, "band": 0.65, "hold": 4.0, "fail": 12, "creep": 0.05, "settle": 0.05, "hint": "AIM FOR THE MIDDLE OF THE ROCKING.",
			 "events": [{"e": "tremor", "mag": 1.2, "say": "ROGUE WAVE!"}, {"e": "add", "say": "NEW CARGO!", "item": {"kind": "crate", "m": 6, "y": 8, "x": 14, "ans": 0, "min": -40, "max": 40}}],
			 "structs": [{"type": "barge", "x": 240, "soil": 1.6, "period": 3.0, "zeta": 0.18, "items": [
				{"kind": "crate", "m": 8, "y": 8, "x": -4, "ans": 6, "min": -40, "max": 40},
				{"kind": "crate", "m": 8, "y": 8, "x": 2, "ans": 14, "min": -40, "max": 40}]}]},
			{"waves": 0.5, "gusts": true, "band": 0.7, "hold": 4.0, "fail": 12, "creep": 0.06, "settle": 0.06, "hint": "WATCH OUT FOR GUSTS.",
			 "events": [{"e": "tremor", "mag": 1.4, "say": "ROGUE WAVE!"}, {"e": "gust"}],
			 "structs": [{"type": "barge", "x": 240, "soil": 1.5, "period": 3.0, "zeta": 0.16, "items": [
				{"kind": "crate", "m": 8, "y": 8, "x": -2, "ans": -12, "min": -40, "max": 40},
				{"kind": "crate", "m": 8, "y": 8, "x": 12, "ans": 4, "min": -40, "max": 40},
				{"kind": "crate", "m": 6, "y": 8, "x": -22, "ans": -10, "min": -40, "max": 40}]}]},
			{"waves": 0.5, "gusts": true, "band": 0.72, "hold": 4.0, "fail": 11, "creep": 0.06, "settle": 0.04, "hint": "THE DOCKERS KEEP LOADING YOU.",
			 "events": [{"e": "add", "say": "NEW CARGO!", "item": {"kind": "crate", "m": 8, "y": 8, "x": -14, "ans": 0, "min": -40, "max": 40}},
				{"e": "tremor", "mag": 1.6, "say": "ROGUE WAVE!"},
				{"e": "add", "say": "NEW CARGO!", "item": {"kind": "crate", "m": 6, "y": 8, "x": 14, "ans": 0, "min": -40, "max": 40}}],
			 "structs": [{"type": "barge", "x": 240, "soil": 1.45, "period": 3.0, "zeta": 0.15, "items": [
				{"kind": "crate", "m": 8, "y": 8, "x": 8, "ans": -6, "min": -40, "max": 40},
				{"kind": "crate", "m": 6, "y": 8, "x": -16, "ans": 2, "min": -40, "max": 40}]}]},
			{"waves": 0.5, "gusts": true, "band": 0.72, "hold": 4.0, "fail": 11, "creep": 0.07, "settle": 0.05, "hint": "HEAVY SEAS. BOTH HANDS ON THE CARGO.",
			 "timed": [{"e": "tremor", "mag": 0.5, "every": 16.0, "say": "ROGUE WAVE!"}],
			 "events": [{"e": "tremor", "mag": 1.6, "say": "ROGUE WAVE!"}, {"e": "gust"}, {"e": "tremor", "mag": 1.8, "say": "ROGUE WAVE!"}],
			 "structs": [{"type": "barge", "x": 240, "soil": 1.4, "period": 3.2, "zeta": 0.14, "items": [
				{"kind": "crate", "m": 9, "y": 8, "x": -10, "ans": 8, "min": -40, "max": 40},
				{"kind": "crate", "m": 6, "y": 8, "x": 26, "ans": 6, "min": -40, "max": 40},
				{"kind": "crate", "m": 4, "y": 8, "x": -20, "ans": -6, "min": -40, "max": 40}]}]},
			{"waves": 0.55, "gusts": true, "band": 0.78, "hold": 4.0, "fail": 10, "creep": 0.08, "settle": 0.05, "hint": "THE STORM OF THE YEAR.",
			 "timed": [{"e": "tremor", "mag": 0.5, "every": 16.0, "say": "ROGUE WAVE!"}],
			 "events": [{"e": "add", "say": "NEW CARGO!", "item": {"kind": "crate", "m": 7, "y": 8, "x": 14, "ans": 0, "min": -40, "max": 40}},
				{"e": "tremor", "mag": 1.8, "say": "ROGUE WAVE!"}, {"e": "gust"}, {"e": "tremor", "mag": 1.2, "say": "ROGUE WAVE!"}],
			 "structs": [{"type": "barge", "x": 240, "soil": 1.38, "period": 3.2, "zeta": 0.13, "items": [
				{"kind": "crate", "m": 9, "y": 8, "x": 12, "ans": -4, "min": -40, "max": 40},
				{"kind": "crate", "m": 7, "y": 8, "x": -22, "ans": 4, "min": -40, "max": 40},
				{"kind": "crate", "m": 4, "y": 8, "x": 24, "ans": 10, "min": -40, "max": 40}]}]},
		],
	},
	{
		"name": "IRONBRIDGE", "subtitle": "THE VIADUCT", "icon": "viaduct",
		"rule": ["TRAINS CROSS THE BRIDGE ON ONE PIER.", "THEY PULL HARDEST HALFWAY ALONG EACH SPAN."],
		"palette": ["120806", "211009", "2d160d", "3b1d11", "5c2d19", "8a4324", "ba6232", "de8f55", "f6c49c", "fff0e4"],
		"accent": "6be0d0",
		"levels": [
			{"band": 0.4, "hold": 2.0, "fail": 6, "creep": 0.03, "hint": "SLIDE THE WEIGHT OPPOSITE THE TRAIN, THEN BACK.",
			 "events": [{"e": "train", "cars": [{"dir": 1, "m": 22, "speed": 30}]}],
			 "structs": [{"type": "pier", "x": 240, "soil": 1.6, "period": 2.0, "zeta": 0.6, "items": [
				{"kind": "counter", "m": 34, "y": 104, "x": 4, "ans": 0, "min": -80, "max": 80, "rate": 40}]}]},
			{"band": 0.4, "hold": 2.0, "fail": 6, "creep": 0.04, "hint": "HERE COMES THE RETURN SERVICE.",
			 "events": [{"e": "train", "cars": [{"dir": 1, "m": 25, "speed": 32}]}, {"e": "train", "cars": [{"dir": -1, "m": 25, "speed": 32}]}],
			 "structs": [{"type": "pier", "x": 240, "soil": 1.6, "period": 2.0, "zeta": 0.55, "items": [
				{"kind": "counter", "m": 34, "y": 104, "x": -4, "ans": 0, "min": -80, "max": 80, "rate": 40}]}]},
			{"band": 0.35, "hold": 2.0, "fail": 5, "creep": 0.05, "settle": 0.04, "hint": "THE COAL TRAIN IS FAST AND HEAVY.",
			 "events": [{"e": "train", "cars": [{"dir": -1, "m": 21, "speed": 38}]}, {"e": "train", "cars": [{"dir": 1, "m": 28, "speed": 28}]}, {"e": "train", "cars": [{"dir": -1, "m": 18, "speed": 44}]}],
			 "structs": [{"type": "pier", "x": 240, "soil": 1.6, "period": 2.2, "zeta": 0.5, "items": [
				{"kind": "counter", "m": 34, "y": 104, "x": 4, "ans": 0, "min": -80, "max": 80, "rate": 40}]}]},
			{"band": 0.35, "hold": 2.0, "fail": 6, "creep": 0.05, "settle": 0.04, "hint": "TWO TRAINS PASS. WATCH WHO IS HEAVIER.",
			 "events": [{"e": "train", "cars": [{"dir": 1, "m": 23, "speed": 34}, {"dir": -1, "m": 22, "speed": 34}]},
				{"e": "train", "cars": [{"dir": 1, "m": 26, "speed": 30}, {"dir": -1, "m": 19, "speed": 42, "lead": 40}]},
				{"e": "train", "cars": [{"dir": -1, "m": 22, "speed": 36}]}],
			 "structs": [{"type": "pier", "x": 240, "soil": 1.6, "period": 2.2, "zeta": 0.5, "items": [
				{"kind": "counter", "m": 34, "y": 104, "x": -4, "ans": 0, "min": -80, "max": 80, "rate": 40}]}]},
			{"band": 0.35, "hold": 2.5, "fail": 6, "creep": 0.05, "settle": 0.06, "gusts": true, "hint": "RUSH HOUR, WITH A CROSSWIND.",
			 "events": [{"e": "train", "cars": [{"dir": 1, "m": 20, "speed": 40}]},
				{"e": "train", "cars": [{"dir": -1, "m": 22, "speed": 36}, {"dir": -1, "m": 22, "speed": 36, "lead": 80}]},
				{"e": "train", "cars": [{"dir": 1, "m": 25, "speed": 32}, {"dir": -1, "m": 17, "speed": 46, "lead": 30}]},
				{"e": "tremor", "mag": 1.0}],
			 "structs": [{"type": "pier", "x": 240, "soil": 1.6, "period": 2.4, "zeta": 0.45, "items": [
				{"kind": "counter", "m": 34, "y": 104, "x": 4, "ans": 0, "min": -80, "max": 80, "rate": 40}]}]},
			{"band": 0.35, "hold": 2.5, "fail": 5.5, "creep": 0.06, "settle": 0.05, "gusts": true, "hint": "THE EXPRESS DOES NOT SLOW DOWN.",
			 "timed": [{"e": "tremor", "mag": 0.3, "every": 11.0}],
			 "events": [{"e": "train", "cars": [{"dir": -1, "m": 17, "speed": 46}]},
				{"e": "train", "cars": [{"dir": 1, "m": 20, "speed": 40}, {"dir": 1, "m": 20, "speed": 40, "lead": 90}]},
				{"e": "train", "cars": [{"dir": -1, "m": 23, "speed": 34}, {"dir": 1, "m": 17, "speed": 46, "lead": 50}]},
				{"e": "tremor", "mag": 1.0},
				{"e": "train", "cars": [{"dir": 1, "m": 17, "speed": 46}]}],
			 "structs": [{"type": "pier", "x": 240, "soil": 1.6, "period": 2.5, "zeta": 0.42, "items": [
				{"kind": "counter", "m": 34, "y": 104, "x": -4, "ans": 0, "min": -80, "max": 80, "rate": 40}]}]},
		],
	},
	{
		"name": "ROSEHILL", "subtitle": "THE TWIN TOWERS", "icon": "twins",
		"rule": ["TWO TOWERS, ONE BRIDGE.", "WHAT YOU DO TO ONE, THE OTHER FEELS."],
		"palette": ["12060c", "210c17", "2c1120", "3a162a", "5e2242", "8e3462", "c2527f", "e886a6", "ffc4d6", "fff0f5"],
		"accent": "7ff0ff",
		"levels": [
			{"couple": 0.6, "band": 0.35, "hold": 2.5, "creep": 0.06, "events": [{"e": "tremor", "mag": 0.8}],
			 "structs": [
				{"type": "campanile", "x": 160, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": 12, "ans": 0, "min": -18, "max": 18}]},
				{"type": "campanile", "x": 320, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": -4, "ans": 0, "min": -18, "max": 18}]}]},
			{"couple": 0.7, "band": 0.3, "hold": 3.0, "creep": 0.07, "settle": 0.05,
			 "events": [{"e": "tremor", "mag": 1.0}, {"e": "tremor", "mag": 1.0, "s": 1}],
			 "structs": [
				{"type": "campanile", "x": 160, "soil": 1.35, "period": 2.2, "zeta": 0.45, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": -10, "ans": 4, "min": -18, "max": 18},
					{"kind": "bell", "m": 6, "y": 56, "x": 10, "ans": -6, "min": -18, "max": 18}]},
				{"type": "campanile", "x": 320, "soil": 1.35, "period": 2.2, "zeta": 0.45, "items": [
					{"kind": "bell", "m": 14, "y": 96, "x": 8, "ans": -6, "min": -18, "max": 18}]}]},
			{"couple": 0.7, "band": 0.28, "hold": 3.0, "creep": 0.09, "settle": 0.06, "hint": "BELLS AND WATER, TOGETHER.",
			 "events": [{"e": "tremor", "mag": 1.0}, {"e": "leak", "i": 0, "rate": 0.25, "s": 1}, {"e": "tremor", "mag": 1.2}],
			 "structs": [
				{"type": "campanile", "x": 160, "soil": 1.35, "period": 2.2, "zeta": 0.45, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": 8, "ans": -4, "min": -18, "max": 18},
					{"kind": "bell", "m": 5, "y": 56, "x": -8, "ans": 2, "min": -18, "max": 18}]},
				{"type": "watertower", "x": 320, "soil": 1.4, "period": 1.9, "zeta": 0.4, "items": [
					{"kind": "tank", "x": -22, "y": 98, "cap": 24, "level": 11, "ans": 14},
					{"kind": "tank", "x": 22, "y": 98, "cap": 24, "level": 13, "ans": 10}]}]},
			{"couple": 0.9, "band": 0.25, "hold": 3.0, "creep": 0.1, "settle": 0.08, "hint": "A TIGHTER ROPE. IT PULLS HARD NOW.",
			 "timed": [{"e": "tremor", "mag": 0.4, "every": 10.0}],
			 "events": [{"e": "tremor", "mag": 1.2}, {"e": "tremor", "mag": 1.2, "s": 1}],
			 "structs": [
				{"type": "clock", "x": 160, "soil": 1.26, "period": 2.5, "zeta": 0.35, "items": [
					{"kind": "bell", "m": 16, "y": 116, "x": 5, "ans": -4, "min": -18, "max": 18},
					{"kind": "bell", "m": 5, "y": 56, "x": -10, "ans": 4, "min": -18, "max": 18}]},
				{"type": "campanile", "x": 320, "soil": 1.26, "period": 2.5, "zeta": 0.35, "items": [
					{"kind": "bell", "m": 16, "y": 116, "x": -3, "ans": 3, "min": -18, "max": 18},
					{"kind": "bell", "m": 5, "y": 56, "x": 9, "ans": -6, "min": -18, "max": 18}]}]},
			{"couple": 0.9, "band": 0.32, "hold": 3.0, "creep": 0.08, "settle": 0.04, "gusts": true, "hint": "A CRANE ON THE ROPE. WHO THOUGHT OF THIS?",
			 "timed": [{"e": "swing", "v": 0.3, "every": 11.0, "s": 1}],
			 "events": [{"e": "tremor", "mag": 1.2}, {"e": "load", "dm": 3, "s": 1, "say": "HEAVIER LOAD!"}, {"e": "tremor", "mag": 1.2, "s": 1}],
			 "structs": [
				{"type": "campanile", "x": 150, "soil": 1.28, "period": 2.5, "zeta": 0.35, "items": [
					{"kind": "bell", "m": 16, "y": 116, "x": 6, "ans": 2, "min": -18, "max": 18},
					{"kind": "bell", "m": 5, "y": 56, "x": -8, "ans": -2, "min": -18, "max": 18}]},
				{"type": "crane", "x": 300, "soil": 1.22, "period": 2.8, "zeta": 0.4, "items": [
					{"kind": "load", "m": 16, "x": 58, "y": 124, "len": 40, "phi": 0.15, "damp": 0.8},
					{"kind": "counter", "m": 30, "y": 124, "x": -32, "ans": -30, "min": -44, "max": -6, "rate": 8},
					{"kind": "counter", "m": 5, "y": 124, "x": -8, "ans": -10, "min": -24, "max": 0, "rate": 14}]}]},
			{"couple": 1.0, "band": 0.32, "hold": 3.0, "creep": 0.09, "settle": 0.04, "fail": 8, "gusts": true, "hint": "THE HILL IS SLIDING. BOTH OF THEM KNOW IT.",
			 "timed": [{"e": "tremor", "mag": 0.4, "every": 15.0}, {"e": "tremor", "mag": 0.4, "every": 19.0, "s": 1}],
			 "events": [{"e": "tremor", "mag": 1.4}, {"e": "leak", "i": 0, "rate": 0.3, "s": 1}, {"e": "tremor", "mag": 1.4, "s": 1}, {"e": "gust"}],
			 "structs": [
				{"type": "campanile", "x": 160, "soil": 1.22, "period": 2.6, "zeta": 0.32, "items": [
					{"kind": "bell", "m": 18, "y": 116, "x": 5, "ans": -2, "min": -18, "max": 18},
					{"kind": "bell", "m": 7, "y": 80, "x": -8, "ans": 2, "min": -18, "max": 18},
					{"kind": "bell", "m": 3, "y": 56, "x": 10, "ans": -4, "min": -18, "max": 18}]},
				{"type": "watertower", "x": 320, "soil": 1.28, "period": 2.2, "zeta": 0.3, "items": [
					{"kind": "tank", "x": -24, "y": 104, "cap": 24, "level": 13, "ans": 14},
					{"kind": "tank", "x": 24, "y": 94, "cap": 24, "level": 15, "ans": 14}]}]},
		],
	},
	{
		"name": "SKYREACH", "subtitle": "THE RADIO MAST", "icon": "mast",
		"rule": ["THE MAST WANTS TO FALL. IT ALWAYS DOES.", "HOLD A WINCH TO PULL. PAST THE POINT OF NO RETURN, IT IS GONE."],
		"palette": ["040a14", "0a1526", "0f1e36", "142846", "1e3f6e", "2d62a2", "4a8cd0", "80b8ea", "bcdcf6", "eef7ff"],
		"accent": "ff8a5c",
		"levels": [
			{"band": 1.0, "hold": 4.0, "still": 8, "creep": 0.0, "gust_k": 0.012, "hint": "SMALL PULLS, EARLY. DO NOT WAIT FOR IT TO LEAN.",
			 "structs": [{"type": "mast", "x": 240, "soil": 1.35, "period": 5.0, "zeta": 0.5, "unstable": 0.35, "lean": 0.6, "items": [
				{"kind": "winch", "side": -1, "x": -60, "y": 8, "force": 2.5},
				{"kind": "winch", "side": 1, "x": 60, "y": 8, "force": 2.5}]}]},
			{"band": 0.9, "hold": 4.5, "still": 8, "creep": 0.0, "gust_k": 0.012, "hint": "IT FALLS FASTER THE FURTHER IT GOES.",
			 "events": [{"e": "tremor", "mag": 0.15}],
			 "structs": [{"type": "mast", "x": 240, "soil": 1.35, "period": 5.0, "zeta": 0.4, "unstable": 0.5, "lean": 0.8, "items": [
				{"kind": "winch", "side": -1, "x": -60, "y": 8, "force": 2.5},
				{"kind": "winch", "side": 1, "x": 60, "y": 8, "force": 2.5}]}]},
			{"band": 0.8, "hold": 5.0, "still": 8, "creep": 0.0, "gust_k": 0.012, "gusts": true, "hint": "AND NOW THE WIND.",
			 "events": [{"e": "tremor", "mag": 0.2}],
			 "structs": [{"type": "mast", "x": 240, "soil": 1.35, "period": 4.6, "zeta": 0.4, "unstable": 0.55, "lean": -0.8, "items": [
				{"kind": "winch", "side": -1, "x": -60, "y": 8, "force": 3.0},
				{"kind": "winch", "side": 1, "x": 60, "y": 8, "force": 3.0}]}]},
			{"band": 0.8, "hold": 5.0, "still": 8, "creep": 0.0, "gust_k": 0.008, "settle": 0.0, "hint": "ONE WINCH IS WEAKER THAN THE OTHER.",
			 "gusts": true, "events": [{"e": "tremor", "mag": 0.2}, {"e": "tremor", "mag": 0.25}],
			 "structs": [{"type": "mast", "x": 240, "soil": 1.35, "period": 4.4, "zeta": 0.35, "unstable": 0.6, "lean": 1.0, "items": [
				{"kind": "winch", "side": -1, "x": -60, "y": 8, "force": 3.2},
				{"kind": "winch", "side": 1, "x": 60, "y": 8, "force": 2.0}]}]},
			{"band": 0.8, "hold": 5.0, "still": 8, "creep": 0.0, "gust_k": 0.008, "gusts": true, "hint": "A TALLER, HUNGRIER MAST.",
			 "timed": [{"e": "tremor", "mag": 0.1, "every": 7.0}], "events": [{"e": "tremor", "mag": 0.25}, {"e": "tremor", "mag": 0.3}],
			 "structs": [{"type": "mast", "x": 240, "soil": 1.35, "period": 4.2, "zeta": 0.32, "unstable": 0.7, "lean": -1.0, "items": [
				{"kind": "winch", "side": -1, "x": -60, "y": 8, "force": 3.2},
				{"kind": "winch", "side": 1, "x": 60, "y": 8, "force": 3.2}]}]},
			{"band": 0.8, "hold": 5.0, "still": 8, "creep": 0.0, "gust_k": 0.008, "gusts": true, "hint": "THE STORM TAKES THE TOP OF THE WORLD.",
			 "timed": [{"e": "tremor", "mag": 0.12, "every": 5.0}], "events": [{"e": "tremor", "mag": 0.3}, {"e": "gust"}, {"e": "tremor", "mag": 0.35}],
			 "structs": [{"type": "mast", "x": 240, "soil": 1.35, "period": 4.0, "zeta": 0.3, "unstable": 0.8, "lean": 1.2, "items": [
				{"kind": "winch", "side": -1, "x": -60, "y": 8, "force": 3.4},
				{"kind": "winch", "side": 1, "x": 60, "y": 8, "force": 3.4}]}]},
		],
	},
	{
		"name": "MERIDIAN", "subtitle": "THE LAST TOWN", "icon": "meridian",
		"rule": ["EVERYTHING YOU LEARNED, ALL AT ONCE.", "NOTHING HERE STANDS STILL."],
		"palette": ["09061a", "130d2c", "1b1340", "271a55", "3f2a7a", "6a3f96", "a45e8e", "e09a6a", "ffd98a", "fff8e0"],
		"accent": "6bfff0",
		"levels": [
			{"couple": 0.9, "band": 0.32, "hold": 3.0, "creep": 0.09, "settle": 0.04, "gusts": true, "hint": "A TOWER AND A CRANE ON ONE ROPE.",
			 "timed": [{"e": "swing", "v": 0.35, "every": 10.0, "s": 1}, {"e": "tremor", "mag": 0.4, "every": 16.0}],
			 "events": [{"e": "tremor", "mag": 1.2}, {"e": "load", "dm": 3, "s": 1, "say": "HEAVIER LOAD!"}, {"e": "tremor", "mag": 1.4, "s": 1}],
			 "structs": [
				{"type": "campanile", "x": 150, "soil": 1.22, "period": 2.6, "zeta": 0.32, "items": [
					{"kind": "bell", "m": 18, "y": 116, "x": 5, "ans": 2, "min": -18, "max": 18},
					{"kind": "bell", "m": 5, "y": 56, "x": -9, "ans": -2, "min": -18, "max": 18}]},
				{"type": "crane", "x": 300, "soil": 1.18, "period": 2.9, "zeta": 0.34, "items": [
					{"kind": "load", "m": 18, "x": 58, "y": 124, "len": 44, "phi": 0.2, "damp": 0.9},
					{"kind": "counter", "m": 34, "y": 124, "x": -32, "ans": -30, "min": -46, "max": -6, "rate": 8},
					{"kind": "counter", "m": 5, "y": 124, "x": -8, "ans": -10, "min": -24, "max": 0, "rate": 14}]}]},
			{"waves": 0.55, "gusts": true, "band": 0.78, "hold": 4.0, "fail": 9, "creep": 0.08, "settle": 0.05, "hint": "THE HARBOUR, AT ITS WORST.",
			 "timed": [{"e": "tremor", "mag": 0.5, "every": 15.0, "say": "ROGUE WAVE!"}],
			 "events": [{"e": "add", "say": "NEW CARGO!", "item": {"kind": "crate", "m": 8, "y": 8, "x": -14, "ans": 0, "min": -40, "max": 40}},
				{"e": "tremor", "mag": 1.2, "say": "ROGUE WAVE!"},
				{"e": "add", "say": "NEW CARGO!", "item": {"kind": "crate", "m": 6, "y": 8, "x": 14, "ans": 0, "min": -40, "max": 40}},
				{"e": "tremor", "mag": 1.2, "say": "ROGUE WAVE!"}],
			 "structs": [{"type": "barge", "x": 240, "soil": 1.38, "period": 3.2, "zeta": 0.15, "items": [
				{"kind": "crate", "m": 9, "y": 8, "x": 10, "ans": -4, "min": -40, "max": 40},
				{"kind": "crate", "m": 7, "y": 8, "x": -20, "ans": 4, "min": -40, "max": 40},
				{"kind": "crate", "m": 4, "y": 8, "x": 22, "ans": 10, "min": -40, "max": 40}]}]},
			{"band": 0.35, "hold": 2.5, "fail": 5.5, "creep": 0.06, "settle": 0.05, "gusts": true, "hint": "THE LAST TRAINS OUT.",
			 "timed": [{"e": "tremor", "mag": 0.3, "every": 9.0}],
			 "events": [{"e": "train", "cars": [{"dir": 1, "m": 17, "speed": 46}]},
				{"e": "train", "cars": [{"dir": -1, "m": 18, "speed": 44}, {"dir": 1, "m": 17, "speed": 46, "lead": 60}]},
				{"e": "tremor", "mag": 1.0},
				{"e": "train", "cars": [{"dir": -1, "m": 19, "speed": 42}, {"dir": -1, "m": 19, "speed": 42, "lead": 80}, {"dir": 1, "m": 20, "speed": 40, "lead": 40}]},
				{"e": "train", "cars": [{"dir": 1, "m": 17, "speed": 46}]}],
			 "structs": [{"type": "pier", "x": 240, "soil": 1.6, "period": 2.6, "zeta": 0.4, "items": [
				{"kind": "counter", "m": 36, "y": 104, "x": 8, "ans": 0, "min": -80, "max": 80, "rate": 40}]}]},
			{"couple": 1.0, "band": 0.32, "hold": 3.0, "creep": 0.09, "settle": 0.04, "gusts": true, "fail": 8, "hint": "THE WATER TOWER AND THE CLOCK.",
			 "timed": [{"e": "tremor", "mag": 0.4, "every": 15.0, "s": 1}],
			 "events": [{"e": "leak", "i": 0, "rate": 0.3}, {"e": "tremor", "mag": 1.4, "s": 1}, {"e": "leak", "i": 2, "rate": 0.35}, {"e": "tremor", "mag": 1.4}],
			 "structs": [
				{"type": "watertower", "x": 160, "soil": 1.25, "period": 2.3, "zeta": 0.28, "items": [
					{"kind": "tank", "x": -28, "y": 106, "cap": 20, "level": 12, "ans": 10},
					{"kind": "tank", "x": 6, "y": 98, "cap": 20, "level": 6, "ans": 6},
					{"kind": "tank", "x": 28, "y": 92, "cap": 20, "level": 10, "ans": 12}]},
				{"type": "clock", "x": 320, "soil": 1.2, "period": 2.7, "zeta": 0.3, "items": [
					{"kind": "bell", "m": 16, "y": 116, "x": 4, "ans": -3, "min": -18, "max": 18},
					{"kind": "bell", "m": 7, "y": 80, "x": -8, "ans": 2, "min": -18, "max": 18},
					{"kind": "bell", "m": 3, "y": 56, "x": 10, "ans": -4, "min": -18, "max": 18}]}]},
			{"band": 0.8, "hold": 6.0, "still": 8, "creep": 0.0, "gust_k": 0.008, "gusts": true, "hint": "THE TALLEST THING ANYONE HAS EVER BUILT.",
			 "timed": [{"e": "tremor", "mag": 0.1, "every": 6.0}], "events": [{"e": "tremor", "mag": 0.3}, {"e": "gust"}, {"e": "tremor", "mag": 0.3}],
			 "structs": [{"type": "mast", "x": 240, "soil": 1.35, "period": 4.2, "zeta": 0.32, "unstable": 0.72, "lean": -1.2, "items": [
				{"kind": "winch", "side": -1, "x": -60, "y": 8, "force": 3.6},
				{"kind": "winch", "side": 1, "x": 60, "y": 8, "force": 3.6}]}]},
			{"couple": 1.1, "band": 0.32, "hold": 3.5, "creep": 0.1, "settle": 0.05, "gusts": true, "fail": 8, "hint": "THE LAST ONE. MAKE THE WORLD STRAIGHT.",
			 "timed": [{"e": "swing", "v": 0.35, "every": 10.0, "s": 0}, {"e": "tremor", "mag": 0.4, "every": 15.0, "s": 1}],
			 "events": [{"e": "load", "dm": 3, "say": "HEAVIER LOAD!"}, {"e": "leak", "i": 0, "rate": 0.3, "s": 1}, {"e": "tremor", "mag": 1.0},
				{"e": "load", "dm": -4, "say": "LOAD DROPPED!"}, {"e": "tremor", "mag": 1.0, "s": 1}],
			 "structs": [
				{"type": "crane", "x": 150, "soil": 1.16, "period": 3.0, "zeta": 0.3, "items": [
					{"kind": "load", "m": 20, "x": 58, "y": 124, "len": 46, "phi": 0.2, "damp": 0.9},
					{"kind": "counter", "m": 36, "y": 124, "x": -33, "ans": -32, "min": -48, "max": -6, "rate": 8},
					{"kind": "counter", "m": 5, "y": 124, "x": -8, "ans": -6, "min": -24, "max": 0, "rate": 14}]},
				{"type": "watertower", "x": 330, "soil": 1.22, "period": 2.4, "zeta": 0.26, "items": [
					{"kind": "tank", "x": -28, "y": 106, "cap": 22, "level": 11, "ans": 12},
					{"kind": "tank", "x": 6, "y": 98, "cap": 22, "level": 8, "ans": 6},
					{"kind": "tank", "x": 28, "y": 92, "cap": 22, "level": 11, "ans": 12}]}]},
		],
	},
]
