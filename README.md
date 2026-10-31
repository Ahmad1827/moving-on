# Plumb Line

Travel from town to town and straighten each one's leaning structure. Each town adds **one new rule** and has its **own colours**, which fade in as your train arrives.

Getting a structure straight once isn't the end of a level. Hold it there and something else goes wrong: a tremor, a leak, a new bell, a heavier load, another train. The ground also sinks faster the further a structure leans, so doing nothing brings it down.

| Town | Structure | Rule |
|---|---|---|
| Viola | Bell tower | Drag the bells. Heavy ones move slowly |
| Tealbrook | Water tower | Hold a tank to pump water into it. The pipes keep flowing, and tanks spring leaks |
| Greymoor | Clock tower | Puzzle: weights lock into notches and you only get a few moves |
| Amberly | Crane | Slide the counterweights while the load swings and changes weight |
| Verdeport | Lighthouse on a barge | Move the cargo through waves, gusts and rogue waves |
| Ironbridge | Viaduct | Slide the weight back and forth to balance each train as it crosses |
| Rosehill | Twin towers + rope bridge | What you do to one, the other feels |
| Skyreach | Radio mast | It wants to fall. Balance it by hand with two winches |
| Meridian | Everything | All of the above, at once |

Each town has 6 levels. The pips under the tilt readout show how many holds a level asks for. Your place in each town is saved.

## Running

Open the folder in **Godot 4.4** (Import, then select `project.godot`) and press **F5**.

Controls: **mouse** to play, **R** or right-click to retry, **Esc** for the map, **F11** for fullscreen.

## How it works

- `scripts/structure.gd`: each structure is a rigid body on springy ground. The weight of anything that is off-centre tips it, and the P-delta effect makes tall, soft structures more sensitive. Water sloshes and lags in the pipes, crane loads swing like pendulums, and the ground creeps under a lean. It also draws the pixel art.
- `scripts/towns.gd`: all level data, with its keys documented at the top of the file. Each movable item has a start `x` and an `ans`. The body is offset so the structure stands exactly straight when every item is at `ans`.
- `tools/balance_sim.py`: a Python port of the physics that plays every level with bots, to check that each one can be beaten and that doing nothing loses. Run it after changing levels, and keep it in step with the game's physics.
- `shaders/screen.gdshader`: the game is drawn in grey, and this shader maps each grey onto the current town's 10-colour palette. Travelling blends between two palettes, washing out the old colours before the new ones fill in.
- `scripts/main.gd`: title, map, travel, play, and the clear and fail screens.
