# Examples

Each folder is a complete Solar2D project with its own copy of the library: open its `main.lua` in the Solar2D Simulator.

| | |
|---|---|
| <img src="screenshots/dmc-trajectory-basic.png" width="240" alt="dmc-trajectory-basic: a blue ball in the air between a green start point and a red end point, and the text Tap Me Here! below"> | **dmc-trajectory-basic**: tap "Tap Me Here!" and a blue ball flies from the green point to the red one in a low arc, then starts again. |
| <img src="screenshots/dmc-trajectory-direction.png" width="240" alt="dmc-trajectory-direction: a grid of white points, a red target at the top right, and an orange arrow in the air above it"> | **dmc-trajectory-direction**: projectiles fly from the center to a random point of the grid, at a random height and speed, one after another. Some are drawn facing left, some right; `direction` tells `rotate` which, and `Trajectory.calculate()` points each one before it flies. |
| <img src="screenshots/dmc-trajectory-multiple.png" width="240" alt="dmc-trajectory-multiple: a grid of points, green start and red end points, and a blue ball, a magenta bar and a yellow bar in the air"> | **dmc-trajectory-multiple**: several moves at once, between random points of the grid: a blue ball, then a magenta bar after 10 seconds and a yellow bar after 20, the bars turning along their paths. |
