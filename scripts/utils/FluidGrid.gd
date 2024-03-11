extends Node

class_name FluidGrid

var densities: Array = []
var velocities: Array = []
var divergence: Array = []
var p: Array = []

var size: int
var length: int
const DENSITY = 50.
const DIFFUSION_RATE = .03

# Iterations of Gauss-Seidel method
const diffuse_density_iterations = 5
const diffuse_velocity_iterations = 20
const divergence_iterations = 10

#Dynamic Detail allocation

func _init(grid_size: int):
	size = grid_size
	length = size * size
	for i in range(length): 
		densities.append(0.)
		velocities.append(Vector2(0, 0))
		divergence.append(0.)
		p.append(0.)
			
	
func add_density(i: int, j: int, delta: float):
	densities[(i * size) + j] += max(delta * DENSITY, 1.)
	
func add_velocity(i: int, j: int, delta: float, vector: Vector2):
	velocities[(i * size) + j] += delta * vector
	
func lerp(a,b,k):
	return a + k*(b-a)

func diffuse(delta: float):
	var a = delta * DIFFUSION_RATE
	
	for k in range(diffuse_density_iterations):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				var initial_density = densities[(i * size) + j]
				densities[(i * size) + j] = (
					initial_density + a*(
						densities[((i - 1) * size) + j] +
						densities[((i + 1) * size) + j] +
						densities[(i * size) + j - 1] +
						densities[(i * size) + j + 1])
					)/(1+4*a)
		
		set_bounds()
	
func diffuse_v(delta: float):
	var a = delta * DIFFUSION_RATE
	
	for k in range(diffuse_velocity_iterations):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				var initial_velocity = velocities[(i * size) + j]
				velocities[(i * size) + j] = (
					initial_velocity + a*(
						velocities[((i - 1) * size) + j] +
						velocities[((i + 1) * size) + j] +
						velocities[(i * size) + j - 1] +
						velocities[(i * size) + j + 1])
					)/(1+4*a)
				
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
			var f = Vector2(i, j) - velocities[(i * size) + j]*delta
			var bound = Vector2(bound_index(f.x), bound_index(f.y))
			var floored = floor(bound)
			var frac = bound - floored
			var z1 = lerp(
				densities[(floored.x * size) + floored.y],
				densities[((floored.x + 1) * size) + floored.y],
				frac.x
			)
			var z2 = lerp(
				densities[(floored.x * size) + floored.y + 1],
				densities[((floored.x + 1) * size) + floored.y + 1],
				frac.x
			)
			densities[(i * size) + j] = lerp(z1, z2, frac.y)
			
	set_bounds()
			
func advect_v(delta: float):
	for i in range(1, size - 1):
		for j in range(1, size - 1):
			var f = Vector2(i, j) - velocities[(i * size) + j]*delta
			var bound = Vector2(bound_index(f.x), bound_index(f.y))
			var floored = floor(bound)
			var frac = bound - floored
			var z1 = lerp(
				velocities[(floored.x * size) + floored.y],
				velocities[((floored.x + 1) * size) + floored.y],
				frac.x
			)
			var z2 = lerp(
				velocities[(floored.x * size) + floored.y + 1],
				velocities[((floored.x + 1) * size) + floored.y + 1],
				frac.x
			)
			velocities[(i * size) + j] = lerp(z1, z2, frac.y)
			
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
			p[(i * size) + j] = 0.
			divergence[(i * size) + j] = -(
				velocities[((i+1) * size) + j].x -
				velocities[(i-1) * size  + j].x +
				velocities[(i * size) + j+1].y -
				velocities[i*size + j-1].y
			)/(2 * size)
	for z in range(divergence_iterations):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				p[(i * size) + j] = (
					divergence[(i * size) + j] +
					p[(i-1) * size  + j] +
					p[(i+1)*size + j] +
					p[i*size + j-1] +
					p[(i * size) + j+1]
				)/4;
	for i in range(1, size - 1):
		for j in range(1, size - 1):
			velocities[(i * size) + j] -= Vector2(
				(p[(i+1)*size + j] - p[(i-1) * size  + j])*(size/2),
				(p[(i * size) + j+1] - p[i*size + j-1])*(size/2)	
			)
	
	set_bounds_v()
	

func set_bounds():
	
	for i in range(1, size - 1):
		densities[i] = densities[size + i]
		densities[(size - 1)*size + i] = densities[(size - 2)*size + i]
		densities[i*size] = densities[i*size + 1]
		densities[i*size + size - 1] = densities[i*size + size - 2]
		
	densities[0] = (densities[size] + densities[1])/2
	densities[size - 1] = (densities[size + size - 1] + densities[size - 2])/2
	densities[(size - 1)* size] = (
		densities[(size - 2)*size] +
		densities[(size - 1)*size + 1]
	)/2
	densities[(size - 1)*size + size - 1] = (
		densities[(size - 2)*size + size - 1] + 
		densities[(size - 1)*size + size - 2]
	)/2

func set_bounds_v():
	
	for i in range(1, size - 1):
		velocities[i] = Vector2(
			-velocities[size+ i].x,
			velocities[size + i].y
		)
		velocities[(size - 1)*size + i] = Vector2(
			-velocities[(size - 2)*size + i].x,
			-velocities[(size - 2)*size + i].y
		)
		velocities[i*size] = Vector2(
			velocities[i*size + 1].x,
			-velocities[i*size + 1].y
		)
		velocities[i*size + size - 1] = Vector2(
			velocities[i*size + size - 2].x,
			-velocities[i*size + size - 2].y
		)
		
	velocities[0] = (velocities[size] + velocities[1])/2
	velocities[size - 1] = (velocities[size + size - 1] + velocities[size - 2])/2
	velocities[(size - 1)* size] = (velocities[(size - 2)*size] + velocities[(size - 1)*size + 1])/2
	velocities[(size - 1)*size + size - 1] = (velocities[(size - 2)*size + size - 1] + velocities[(size - 1)*size + size - 2])/2
	
