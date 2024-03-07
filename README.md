# FluidEngine

A small interactive fluid simulation, made with the [Godot Engine](https://godotengine.org/).

#### Interaction

You can create new fluid by holding the left mouse button, and move it around by holding the right mouse button and dragging it around

![Creating and moving fluid](https://giphy.com/gifs/4oQKdrIbijxkAgAZIQ)

## Physics stuff

The project is based on [Real-Time Fluid Dynamics for Games](https://www.researchgate.net/publication/2560062_Real-Time_Fluid_Dynamics_for_Games), which uses the Navier-Stokes equations to calculate the motion of the fluid.

The fluid's density is represented as the opacity of squares on a grid, and its evolution only depends on density and velocity.

#### Diffusion

The fluid will gradually diffuse by approaching the average density value of the neighbouring cells. We can use the following parameters to determine the change of density in the cell $(x,y)$ :

$d_0(x,y)$ = density of cell (x,y)
$s(x,y) = \frac{d_1(x+1, y) + d_1(x-1, y) + d_1(x, y+1) + d_1(x, y-1)}{4}$
$k$ = amount of change

We can extract the following value of the density as:
$$d_1 = d_0 + k(s - d_0)$$

...
README.md is a work in progress
