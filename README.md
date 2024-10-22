> **Note**  
> This README is still a work in progress, you will find a bit of a mess

# FluidEngine

A small interactive fluid simulation, made with the [Godot Engine](https://godotengine.org/).

#### Interaction

You can create new fluid by holding the left mouse button, and move it around by holding the right mouse button and dragging it around

![Creating and moving fluid](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZWdtb2RobDc5aGtvc3htajlmOGtremphZXJtYzZmcm8yamE0MHhodSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/2c25QYyu0aShPV4yy6/giphy.gif)

## Physics stuff

The project is based on [Real-Time Fluid Dynamics for Games](https://www.researchgate.net/publication/2560062_Real-Time_Fluid_Dynamics_for_Games) and [But How DO Fluid Simulations Work?](https://www.youtube.com/watch?v=qsYE1wMEMPA&t=4s).

The Navier-Stokes equations have been a standard for fluid simulation since the implementation by Foster and Metaxas (1996).

Let's see how they can help us.

$$
\begin{aligned}
& \nabla \cdot \mathbf{u} = 0 \\
& \rho \frac{D\mathbf{u}}{Dt} = -\nabla p + \mu\nabla^2 \mathbf{u} + \rho\mathbf{F}
\end{aligned}
$$

The first one represents mass conservation, that we can express a lack of divergence of the velocity vector field.
The second equation tells us that the acceleration is dependent on 3 factors: internal forces (pressure and viscosity) and external forces. We will translate this concepts by calculating the evolution of the density of the fluid.

The fluid's density is represented as the opacity of squares on a grid, and its evolution only depends on another parameter: velocity.

### Diffusion

Every cell of the fluid will gradually try to reach pressure equilibrium by moving its density to regions with lower density, this phenomenon is called "diffusion". We can use the following parameters to determine the exchange of density between a cell $(x,y)$ and its neighbors:

[ILLUSTRATION OF PROGRESSING DIFFUSION]

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

[ILLUSTRATION OF HYPERBOLIC RELATION]

If we try to substitute the value of $s$ in the formula above, we see that it becomes a system of equations. We can solve this with the Gauss-Seidel Method, which is applicable because of the stricly diagonally dominant matrix of the resulting equation system.

We can finally get the following operation, calculated multiple times to approach a more realistic value of the density of a cell.

$$
\begin{aligned}
& \delta = \text{time elapsed from last frame} \\
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

Advection is how cells transfer properties to other cells according to their velocity. This applies to both the velocity and density of our cells.

The velocity vector of a cell doesn't usually point at the perfect center of another cell, so we interpolate the value between the 4 closest cells by their distance. This works fine, but we can make it a bit cheaper: instead of extracting the sum of all the velocity vectors pointing close to a cell, we can instead invert the vector and subtract velocity to the adjacent cells, this will only take one calculation per cell.

[ILLUSTRATION OF CELLS AND VECTORS]

### Clearing Divergence

Divergence in our vector field would mean that fluid is appearing and disappearing from nothing, we have to get rid of it somehow.

The fundamental theorem of vector calculus states that any sufficiently smooth, rapidly decaying vector field can be decomposed into the sum of a curl-free vector field and a divergence-free vector field. Let's find a curl-free vector field we can subtract from our own to get the desired divergence-free field.

We first calculate the divergence at every cell as:

$$ \nabla \cdot v(x,y) = \frac{v_x(x+1, y)-v_x(x-1, y)+v_y(x, y+1)-v_y(x, y-1)}{2} $$

We can also extract the divergence as the result of a scalar field diffused from the neighboring cells

$$[p(x-1,y)+p(x+1,y)+p(x,y-1)+p(x,y+1)] -4p(x,y) = \nabla\cdot v(x,y)$$

Let's solve to find the divergence

$$ p(x,y) = \frac{[p(x-1,y)+p(x+1,y)+p(x,y-1)+p(x,y+1)] - \nabla\cdot v}{4} $$

We use the Gauss-Seidel Method to find the field. We can then find the gradient vector field:

$$\nabla p(x,y) = \left(\frac{p(x+1,y)-p(x-1,y)}{2} , \frac{p(x,y+1)-p(x,y-1)}{2}\right) $$

We know that the curl of the gradient of a scal field is equal to the zero vector. There is our guy!

We can now subtract this value to every cell of the grid to remove the divergence, this has the side effect of adding curl, which we don't mind (swirls are pretty).

### Vorticity confinment

To create a more realistic effect of secondary swirls it's useful to manually accelerate the velocity in zones with existing curl, due to the failure of numerical discretisation methods to introduce small-scale features of the flow.

The operation is pretty simple, for every cell we get the curl:

$$c(x,y) = v_x(x+1, y)-v_x(x-1, y)+v_y(x, y+1)-v_y(x, y-1)$$

We normalize it by its length and find the 2 components:

$$
\begin{aligned}
& \omega = \text{vorticity} \\
& dx = |c(x, y-1)| - |c(x,y+1)| \\
& dy = |c(x+1, y)| - |c(x-1,y)| \\
& L = \sqrt{(dx)^2 + (dy)^2} + 1 \times 10^{-5} \\
& vx = \frac{\omega}{L \cdot dx} \\
& vy = \frac{\omega}{L \cdot dy}
\end{aligned}
$$

We then add this factor to every cell's velocity, multiplied by its curl

$$ vx\cdot\delta \cdot c(x,y), \ \ \ vy\cdot\delta\cdot c(x,y) $$
