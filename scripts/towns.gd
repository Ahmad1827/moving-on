class_name Towns
extends RefCounted
## The journey: five towns, each with its own palette, structure and one new rule.
##
## Structure coordinates are pixels from the pivot, x right, y up.
## Movable items have a start "x" and an "ans": the structure stands exactly
## straight when every item sits at its "ans", so each level is guaranteed
## solvable (tanks use "level" / "ans" for their water instead).
##   soil   > 1; closer to 1 = softer ground, more sensitive and slower
##   period seconds per sway, zeta damping (lower = wobblier)

const TOWNS := [
	{
		"name": "VIOLA", "subtitle": "THE BELL TOWER", "icon": "campanile",
		"rule": ["DRAG THE BELLS SIDEWAYS.", "MAKE THE TOWER STAND STRAIGHT."],
		"palette": ["0a0715", "130e26", "1b1536", "221a44", "352a69", "5442a4", "7b68da", "a394ef", "cec4ff", "f1edff"],
		"accent": "ff5d8f",
		"levels": [
			{"structs": [{"type": "campanile", "x": 240, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
				{"kind": "bell", "m": 14, "y": 116, "x": 16, "ans": 0, "min": -18, "max": 18}]}]},
			{"structs": [{"type": "campanile", "x": 240, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
				{"kind": "bell", "m": 14, "y": 116, "x": -15, "ans": 6, "min": -18, "max": 18},
				{"kind": "bell", "m": 6, "y": 56, "x": 17, "ans": -4, "min": -18, "max": 18}]}],
			 "hint": "SMALL BELLS ARE FOR FINE TUNING."},
			{"structs": [{"type": "campanile", "x": 240, "soil": 1.2, "period": 2.8, "zeta": 0.5, "items": [
				{"kind": "bell", "m": 18, "y": 116, "x": 12, "ans": -10, "min": -18, "max": 18},
				{"kind": "bell", "m": 10, "y": 96, "x": -16, "ans": 2, "min": -18, "max": 18},
				{"kind": "bell", "m": 5, "y": 56, "x": 15, "ans": 9, "min": -18, "max": 18}]}],
			 "hint": "SOFT GROUND. EVERYTHING MATTERS MORE."},
		],
	},
	{
		"name": "TEALBROOK", "subtitle": "THE WATER TOWER", "icon": "watertower",
		"rule": ["HOLD A TANK TO PUMP WATER INTO IT.", "THE PIPES KEEP FLOWING AFTER YOU LET GO."],
		"palette": ["050f12", "0a1d22", "0f2a30", "123840", "1a5560", "23808a", "35b0b0", "6ad6cc", "b0f0e4", "eafff9"],
		"accent": "ffb36b",
		"levels": [
			{"structs": [{"type": "watertower", "x": 240, "soil": 1.4, "period": 1.9, "zeta": 0.4, "items": [
				{"kind": "tank", "x": -22, "y": 98, "cap": 24, "level": 18, "ans": 10},
				{"kind": "tank", "x": 22, "y": 98, "cap": 24, "level": 4, "ans": 12}]}]},
			{"structs": [{"type": "watertower", "x": 240, "soil": 1.4, "period": 1.9, "zeta": 0.4, "items": [
				{"kind": "tank", "x": -28, "y": 98, "cap": 20, "level": 0, "ans": 3},
				{"kind": "tank", "x": 0, "y": 98, "cap": 20, "level": 20, "ans": 5},
				{"kind": "tank", "x": 28, "y": 98, "cap": 20, "level": 0, "ans": 12}]}],
			 "hint": "THE MIDDLE TANK DOES NOT TIP ANYTHING."},
			{"structs": [{"type": "watertower", "x": 240, "soil": 1.25, "period": 2.2, "zeta": 0.35, "items": [
				{"kind": "tank", "x": -22, "y": 112, "cap": 24, "level": 16, "ans": 9},
				{"kind": "tank", "x": 24, "y": 86, "cap": 24, "level": 8, "ans": 15}]}],
			 "hint": "HIGHER WATER LEANS HARDER."},
		],
	},
	{
		"name": "AMBERLY", "subtitle": "THE CRANE", "icon": "crane",
		"rule": ["SLIDE THE COUNTERWEIGHT.", "MIND THE SWINGING LOAD."],
		"palette": ["120a04", "21140a", "2c1c0e", "3a2611", "5a3a16", "8a5a1e", "c08530", "e8b050", "ffd890", "fff4dc"],
		"accent": "5ad0ff",
		"levels": [
			{"structs": [{"type": "crane", "x": 228, "soil": 1.3, "period": 2.4, "zeta": 0.5, "items": [
				{"kind": "load", "m": 14, "x": 58, "y": 124, "len": 34, "phi": 0.0, "damp": 0.6},
				{"kind": "counter", "m": 30, "y": 124, "x": -8, "ans": -27, "min": -42, "max": -6}]}]},
			{"structs": [{"type": "crane", "x": 228, "soil": 1.3, "period": 2.4, "zeta": 0.5, "items": [
				{"kind": "load", "m": 14, "x": 58, "y": 124, "len": 34, "phi": 0.35, "damp": 0.25},
				{"kind": "counter", "m": 30, "y": 124, "x": -40, "ans": -24, "min": -42, "max": -6}]}],
			 "hint": "WAIT FOR THE SWING TO CALM DOWN.", "band": 0.6, "hold": 1.5},
			{"structs": [{"type": "crane", "x": 228, "soil": 1.18, "period": 2.8, "zeta": 0.5, "items": [
				{"kind": "load", "m": 22, "x": 62, "y": 124, "len": 40, "phi": 0.15, "damp": 0.25},
				{"kind": "counter", "m": 30, "y": 124, "x": -28, "ans": -36, "min": -44, "max": -6}]}],
			 "hint": "A HEAVIER LOAD ON SOFTER GROUND.", "band": 0.6, "hold": 1.5},
		],
	},
	{
		"name": "VERDEPORT", "subtitle": "THE HARBOUR LIGHT", "icon": "barge",
		"rule": ["DRAG THE CARGO ALONG THE DECK.", "RIDE OUT THE WAVES."],
		"palette": ["04100b", "0a1d14", "10281b", "153524", "1e5236", "2f7d4c", "4cae68", "86d68c", "c6f2c0", "f0fff0"],
		"accent": "ff6b8a",
		"levels": [
			{"structs": [{"type": "barge", "x": 240, "soil": 1.6, "period": 3.0, "zeta": 0.18, "items": [
				{"kind": "crate", "m": 8, "y": 8, "x": 30, "ans": -10, "min": -40, "max": 40}]}],
			 "waves": 0.3, "band": 1.0, "hold": 2.5, "fail": 16},
			{"structs": [{"type": "barge", "x": 240, "soil": 1.6, "period": 3.0, "zeta": 0.18, "items": [
				{"kind": "crate", "m": 8, "y": 8, "x": -20, "ans": 6, "min": -40, "max": 40},
				{"kind": "crate", "m": 8, "y": 8, "x": -8, "ans": 14, "min": -40, "max": 40}]}],
			 "waves": 0.5, "band": 1.0, "hold": 2.5, "fail": 16, "hint": "BIGGER WAVES. AIM FOR THE MIDDLE OF THE ROCKING."},
			{"structs": [{"type": "barge", "x": 240, "soil": 1.6, "period": 3.0, "zeta": 0.18, "items": [
				{"kind": "crate", "m": 8, "y": 8, "x": 20, "ans": -12, "min": -40, "max": 40},
				{"kind": "crate", "m": 8, "y": 8, "x": 30, "ans": 4, "min": -40, "max": 40},
				{"kind": "crate", "m": 6, "y": 8, "x": -36, "ans": -10, "min": -40, "max": 40}]}],
			 "waves": 0.6, "gusts": true, "band": 1.2, "hold": 2.5, "fail": 16, "hint": "WATCH OUT FOR GUSTS."},
		],
	},
	{
		"name": "ROSEHILL", "subtitle": "THE TWIN TOWERS", "icon": "twins",
		"rule": ["TWO TOWERS, ONE BRIDGE.", "WHAT YOU DO TO ONE, THE OTHER FEELS."],
		"palette": ["12060c", "210c17", "2c1120", "3a162a", "5e2242", "8e3462", "c2527f", "e886a6", "ffc4d6", "fff0f5"],
		"accent": "7ff0ff",
		"levels": [
			{"couple": 0.6, "structs": [
				{"type": "campanile", "x": 160, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": 16, "ans": 0, "min": -18, "max": 18}]},
				{"type": "campanile", "x": 320, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": 0, "ans": 0, "min": -18, "max": 18}]}]},
			{"couple": 0.6, "structs": [
				{"type": "campanile", "x": 160, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": -14, "ans": 4, "min": -18, "max": 18},
					{"kind": "bell", "m": 6, "y": 56, "x": 10, "ans": -6, "min": -18, "max": 18}]},
				{"type": "campanile", "x": 320, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
					{"kind": "bell", "m": 14, "y": 96, "x": 12, "ans": -8, "min": -18, "max": 18}]}]},
			{"couple": 0.6, "hint": "BELLS AND WATER, TOGETHER.", "structs": [
				{"type": "campanile", "x": 160, "soil": 1.35, "period": 2.2, "zeta": 0.5, "items": [
					{"kind": "bell", "m": 14, "y": 116, "x": 14, "ans": -4, "min": -18, "max": 18}]},
				{"type": "watertower", "x": 320, "soil": 1.4, "period": 1.9, "zeta": 0.4, "items": [
					{"kind": "tank", "x": -22, "y": 98, "cap": 24, "level": 6, "ans": 14},
					{"kind": "tank", "x": 22, "y": 98, "cap": 24, "level": 18, "ans": 10}]}]},
		],
	},
]
