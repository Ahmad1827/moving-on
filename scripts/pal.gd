class_name Pal
extends RefCounted
## Everything is drawn in ten grey levels plus pure red for the accent.
## The screen shader maps those greys onto the current town's palette,
## which is what lets colours cross-fade when you travel.

const BG := Color(0.0, 0.0, 0.0)
const BG2 := Color(0.111, 0.111, 0.111)
const GRID := Color(0.222, 0.222, 0.222)
const INK := Color(0.333, 0.333, 0.333)
const DEEP := Color(0.444, 0.444, 0.444)
const MID := Color(0.556, 0.556, 0.556)
const MAIN := Color(0.667, 0.667, 0.667)
const LIGHT := Color(0.778, 0.778, 0.778)
const PALE := Color(0.889, 0.889, 0.889)
const WHITE := Color(1.0, 1.0, 1.0)
const WARN := Color(1.0, 0.0, 0.0)
