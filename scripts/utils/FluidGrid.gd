extends Node

class_name FluidGrid

var densities: Array = []
var velocities: Array = []
var divergence: Array = []
var p: Array = []

var size: int
const DENSITY = 50.
const DIFFUSION_RATE = .03

# Iterations of Gauss-Seidel method
const diffuse_density_iterations = 10
const diffuse_velocity_iterations = 10
const divergence_iterations = 10

#Dynamic Detail allocation

func _init(grid_size: int):
	size = grid_size
	densities = []
	for i in range(grid_size): 
		densities.append([])
		velocities.append([])
		divergence.append([])
		p.append([])
		for j in range(grid_size):
			densities[i].append(0.)
			velocities[i].append(Vector2(0, 0))
			divergence[i].append(0.)
			p[i].append(0.)
			
func getEl(array: Array, i: int, j: int):
	return array[(i * size) + j]
	
func add_density(i: int, j: int, delta: float):
	densities[i][j] += max(delta * DENSITY, 1.)
	
func add_velocity(i: int, j: int, delta: float, vector: Vector2):
	velocities[i][j] += delta * vector
	
func lerp(a,b,k):
	return a + k*(b-a)

func diffuse(delta: float):
	var a = delta * DIFFUSION_RATE
	
	for k in range(diffuse_density_iterations):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				var initial_density = densities[i][j]
				densities[i][j] = (initial_density + a*(densities[i-1][j] + densities[i+1][j] + densities[i][j-1] + densities[i][j+1]))/(1+4*a)
		
		set_bounds()
	
func diffuse_v(delta: float):
	var a = delta * DIFFUSION_RATE
	
	for k in range(diffuse_velocity_iterations):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				var initial_density = velocities[i][j]
				velocities[i][j] = (initial_density + a*(velocities[i-1][j] + velocities[i+1][j] + velocities[i][j-1] + velocities[i][j+1]))/(1+4*a)
				
		set_bounds_v()
		
func bound_index(value: float):
	var result = value
	if value < 0.5:
		result = 0.5
	if value >= size - 1.5:
		result = size - 2.5
	return result

func advect(delta: float):
	for i in range(1, size - 1):
		for j in range(1, size - 1):
			var f = Vector2(i, j) - velocities[i][j]*delta
			var bound = Vector2(bound_index(f.x), bound_index(f.y))
			var floored = floor(bound)
			var frac = bound - floored
			var z1 = lerp(densities[floored.x][floored.y], densities[floored.x + 1][floored.y], frac.x)
			var z2 = lerp(densities[floored.x][floored.y + 1], densities[floored.x + 1][floored.y + 1], frac.x)
			densities[i][j] = lerp(z1, z2, frac.y)
			
	set_bounds()
			
func advect_v(delta: float):
	for i in range(1, size - 1):
		for j in range(1, size - 1):
			var f = Vector2(i, j) - velocities[i][j]*delta
			var bound = Vector2(bound_index(f.x), bound_index(f.y))
			var floored = floor(bound)
			var frac = bound - floored
			var z1 = lerp(velocities[floored.x][floored.y], velocities[floored.x + 1][floored.y], frac.x)
			var z2 = lerp(velocities[floored.x][floored.y + 1], velocities[floored.x + 1][floored.y + 1], frac.x)
			velocities[i][j] = lerp(z1, z2, frac.y)
			
	set_bounds_v()


func get_line(i1, j1, i2, j2):
	var points = []
	# Calculate differences and absolute differences
	var dx = i2 - i1
	var dy = j2 - j1
	var dx1 = abs(dx)
	var dy1 = abs(dy)

	# Determine the direction of the line
	var sx = 1 if dx > 0 else -1
	var sy = 1 if dy > 0 else -1

	# Initialize error variables
	var x = i1
	var y = j1
	var err = (dx1 if dx1 > dy1 else -dy1) / 2.0

	while true:
		# Add the current point to the result
		points.append(Vector2(x, y))

		# Check if we reached the end point
		if x == i2 and y == j2:
			break

		# Update error term and coordinates
		var e2 = err
		if e2 > -dx1:
			err -= dy1
			x += sx
		if e2 < dy1:
			err += dx1
			y += sy

	return points
	
func clear_divergence():
	for i in range(1, size - 1):
		for j in range(1, size - 1):
			p[i][j] = 0.
			divergence[i][j] = -(velocities[i+1][j].x - velocities[i-1][j].x + velocities[i][j+1].y - velocities[i][j-1].y)/(2 * size)
	for z in range(divergence_iterations):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				p[i][j] = (divergence[i][j] + p[i-1][j] + p[i+1][j] + p[i][j-1] + p[i][j+1])/4;
	for i in range(1, size - 1):
		for j in range(1, size - 1):
			velocities[i][j] -= Vector2(
				(p[i+1][j] - p[i-1][j])*(size/2),
				(p[i][j+1] - p[i][j-1])*(size/2)	
			)
	
	set_bounds_v()
	

func set_bounds():
	
	for i in range(1, size - 1):
		densities[0][i] = densities[1][i]
		densities[size - 1][i] = densities[size - 2][i]
		densities[i][0] = densities[i][1]
		densities[i][size - 1] = densities[i][size - 2]
		
	densities[0][0] = (densities[1][0] + densities[0][1])/2
	densities[0][size - 1] = (densities[1][size - 1] + densities[0][size - 2])/2
	densities[size - 1][0] = (densities[size - 2][0] + densities[size - 1][1])/2
	densities[size - 1][size - 1] = (densities[size - 2][size - 1] + densities[size - 1][size - 2])/2

func set_bounds_v():
	
	for i in range(1, size - 1):
		velocities[0][i] = Vector2(-velocities[1][i].x, velocities[1][i].y)
		velocities[size - 1][i] = Vector2(-velocities[size - 2][i].x, -velocities[size - 2][i].y)
		velocities[i][0] = Vector2(velocities[i][1].x, -velocities[i][1].y)
		velocities[i][size - 1] = Vector2(velocities[i][size - 2].x, -velocities[i][size - 2].y)
		
	velocities[0][0] = (velocities[1][0] + velocities[0][1])/2
	velocities[0][size - 1] = (velocities[1][size - 1] + velocities[0][size - 2])/2
	velocities[size - 1][0] = (velocities[size - 2][0] + velocities[size - 1][1])/2
	velocities[size - 1][size - 1] = (velocities[size - 2][size - 1] + velocities[size - 1][size - 2])/2
	
