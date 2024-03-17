# FluidEngine

A small interactive fluid simulation, made with the [Godot Engine](https://godotengine.org/).

#### Interaction

You can create new fluid by holding the left mouse button, and move it around by holding the right mouse button and dragging it around

![Creating and moving fluid](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZWdtb2RobDc5aGtvc3htajlmOGtremphZXJtYzZmcm8yamE0MHhodSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/2c25QYyu0aShPV4yy6/giphy.gif)

## Physics stuff

The project is based on [Real-Time Fluid Dynamics for Games](https://www.researchgate.net/publication/2560062_Real-Time_Fluid_Dynamics_for_Games), which uses the Navier-Stokes equations to calculate the motion of the fluid.

The fluid's density is represented as the opacity of squares on a grid, and its evolution only depends on density and velocity.

### Diffusion

The fluid will gradually diffuse by approaching the average density value of the neighbouring cells. We can use the following parameters to determine the change of density in the cell $(x,y)$.

$$
\begin{aligned}
& d_0(x,y) = \text{density of cell } (x,y) \\
& s(x,y) = \frac{d_1(x+1, y) + d_1(x-1, y) + d_1(x, y+1) + d_1(x, y-1)}{4} \\
& k = \text{amount of change}
\end{aligned}
$$

We can extract the following value of the density as:
$$d_1 = d_0 + k(s - d_0)$$

The formula can be reversed to backtrack the solution:
$$d_0 = d_1 - k(s - d_1)$$

This makes the solution of $d_1$ hyperbolic in relation with k, which helps avoid overshooting the $s$ target value.
$$d_1 = \frac{d_0 + ks}{1+k}$$

If we try to substitute the value of $s$ in the formula above, we see that it becomes a system of equations. We can solve this with the Gauss-Seidel Method, which is applicable because of the stricly diagonally dominant matrix of the resulting equation system.

We can finally get the following operation, calculated multiple times to approach a more realistic value of the density of a cell.

$$
\begin{aligned}
& \delta = \text{time elapsed from last frame}\\
& a = k\delta  \\
& d_1(x,y) = d_0(x,y) + a(\\
& \ \ \ \ \ \ d_0(x-1,y) + d_0(x+1,y) + \\
& \ \ \ \ \ \ d_0(x,y-1) + d_0(x,y+1) - \\
& \ \ \ \ \ \ 4d_0(x,y) \\
& )/(1 + 4a)
\end{aligned}
$$

Please note that this can also be used to diffuse other properties, especially velocity.

### Advection

WIP
