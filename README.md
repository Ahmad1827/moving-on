# Plumb Line

Travel from town to town and straighten each one's leaning structure.
Each town adds **one new rule** and has its **own colours**, which fade in as your train arrives.

| Town | Structure | Rule |
|---|---|---|
| Viola (violet) | Bell tower | Drag the bells sideways |
| Tealbrook (teal) | Water tower | Hold a tank to pump water into it. The pipes keep flowing after you let go |
| Amberly (amber) | Crane | Slide the counterweight while the load swings |
| Verdeport (green) | Lighthouse on a barge | Move the cargo and ride out the waves (and gusts) |
| Rosehill (rose) | Twin towers + rope bridge | What you do to one, the other feels |

Each town has 3 levels. A level is cleared when the tilt stays inside the target for a moment.

## Running

Open the folder in **Godot 4.4** (Import, then select `project.godot`) and press **F5**.

Controls: **mouse** to play, **R** or right-click to retry, **Esc** for the map, **F11** for fullscreen.

## How it works

- `scripts/structure.gd`: each structure is a rigid body on springy ground. The weight of anything that is off-centre tips it, and the P-delta effect makes tall, soft structures more sensitive. Water sloshes and lags in the pipes, and crane loads swing like pendulums. It also draws the pixel art.
- `scripts/towns.gd`: all level data. Each movable item has a start `x` and an `ans`. The body is offset so the structure stands exactly straight when every item is at `ans`, so every level can be solved.
- `shaders/screen.gdshader`: the game is drawn in grey, and this shader maps each grey onto the current town's 10-colour palette. Travelling blends between two palettes, washing out the old colours before the new ones fill in.
- `scripts/main.gd`: title, map, travel, play, and the clear and fail screens.
