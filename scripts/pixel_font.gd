class_name PixelFont
extends RefCounted
## 5x7 bitmap font drawn with rects, so text stays pixel-exact at any scale.
## Each glyph is 7 rows of 5 bits (MSB = leftmost pixel).

const ADVANCE := 6
const HEIGHT := 7

const GLYPHS := {
	"A": [14, 17, 17, 31, 17, 17, 17], "B": [30, 17, 17, 30, 17, 17, 30],
	"C": [14, 17, 16, 16, 16, 17, 14], "D": [30, 17, 17, 17, 17, 17, 30],
	"E": [31, 16, 16, 30, 16, 16, 31], "F": [31, 16, 16, 30, 16, 16, 16],
	"G": [14, 17, 16, 23, 17, 17, 15], "H": [17, 17, 17, 31, 17, 17, 17],
	"I": [14, 4, 4, 4, 4, 4, 14], "J": [7, 2, 2, 2, 2, 18, 12],
	"K": [17, 18, 20, 24, 20, 18, 17], "L": [16, 16, 16, 16, 16, 16, 31],
	"M": [17, 27, 21, 21, 17, 17, 17], "N": [17, 17, 25, 21, 19, 17, 17],
	"O": [14, 17, 17, 17, 17, 17, 14], "P": [30, 17, 17, 30, 16, 16, 16],
	"Q": [14, 17, 17, 17, 21, 18, 13], "R": [30, 17, 17, 30, 20, 18, 17],
	"S": [15, 16, 16, 14, 1, 1, 30], "T": [31, 4, 4, 4, 4, 4, 4],
	"U": [17, 17, 17, 17, 17, 17, 14], "V": [17, 17, 17, 17, 17, 10, 4],
	"W": [17, 17, 17, 21, 21, 21, 10], "X": [17, 17, 10, 4, 10, 17, 17],
	"Y": [17, 17, 10, 4, 4, 4, 4], "Z": [31, 1, 2, 4, 8, 16, 31],
	"0": [14, 17, 19, 21, 25, 17, 14], "1": [4, 12, 4, 4, 4, 4, 14],
	"2": [14, 17, 1, 2, 4, 8, 31], "3": [31, 2, 4, 2, 1, 17, 14],
	"4": [2, 6, 10, 18, 31, 2, 2], "5": [31, 16, 30, 1, 1, 17, 14],
	"6": [6, 8, 16, 30, 17, 17, 14], "7": [31, 1, 2, 4, 8, 8, 8],
	"8": [14, 17, 17, 14, 17, 17, 14], "9": [14, 17, 17, 15, 1, 2, 12],
	" ": [0, 0, 0, 0, 0, 0, 0], ".": [0, 0, 0, 0, 0, 12, 12],
	",": [0, 0, 0, 0, 12, 4, 8], ":": [0, 12, 12, 0, 12, 12, 0],
	"-": [0, 0, 0, 31, 0, 0, 0], "+": [0, 4, 4, 31, 4, 4, 0],
	"/": [1, 1, 2, 4, 8, 16, 16], "°": [12, 18, 18, 12, 0, 0, 0],
	"%": [24, 25, 2, 4, 8, 19, 3], "!": [4, 4, 4, 4, 4, 0, 4],
	"?": [14, 17, 1, 2, 4, 0, 4], "(": [2, 4, 8, 8, 8, 4, 2],
	")": [8, 4, 2, 2, 2, 4, 8], "<": [2, 4, 8, 16, 8, 4, 2],
	">": [8, 4, 2, 1, 2, 4, 8], "=": [0, 0, 31, 0, 31, 0, 0],
	"[": [14, 8, 8, 8, 8, 8, 14], "]": [14, 2, 2, 2, 2, 2, 14],
	"'": [4, 4, 8, 0, 0, 0, 0], "#": [10, 10, 31, 10, 31, 10, 10],
	"*": [0, 4, 21, 14, 21, 4, 0], "_": [0, 0, 0, 0, 0, 0, 31],
	"~": [0, 0, 8, 21, 2, 0, 0], "|": [4, 4, 4, 4, 4, 4, 4],
	"±": [4, 4, 31, 4, 4, 0, 31],
}


static func width(text: String, scale: int = 1) -> int:
	if text.is_empty():
		return 0
	return (text.length() * ADVANCE - 1) * scale


static func draw(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale: int = 1) -> void:
	var x := floorf(pos.x)
	var y := floorf(pos.y)
	for ch in text.to_upper():
		var rows = GLYPHS.get(ch)
		if rows != null:
			for r in HEIGHT:
				var bits: int = rows[r]
				var c := 0
				# Merge horizontal runs of lit pixels into one rect.
				while c < 5:
					if (bits & (1 << (4 - c))) != 0:
						var start := c
						while c < 5 and (bits & (1 << (4 - c))) != 0:
							c += 1
						ci.draw_rect(Rect2(x + start * scale, y + r * scale, (c - start) * scale, scale), color)
					else:
						c += 1
		x += ADVANCE * scale


## Text with a one-pixel drop shadow, used for most UI labels.
static func draw_shadowed(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale: int = 1, shadow: Color = Pal.BG) -> void:
	draw(ci, text, pos + Vector2(scale, scale), shadow, scale)
	draw(ci, text, pos, color, scale)


static func draw_centered(ci: CanvasItem, text: String, center_x: float, y: float, color: Color, scale: int = 1) -> void:
	draw(ci, text, Vector2(center_x - width(text, scale) / 2.0, y), color, scale)


static func draw_right(ci: CanvasItem, text: String, right_x: float, y: float, color: Color, scale: int = 1) -> void:
	draw(ci, text, Vector2(right_x - width(text, scale), y), color, scale)
