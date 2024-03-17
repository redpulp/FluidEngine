extends Node

class_name FluidGrid

var squares: Array = []
var velocities: Array = []

var size: int
const DENSITY = 50.
const DIFFUSION_RATE = .03

#Dynamic Detail allocation

func _init(grid_size: int):
	size = grid_size
	squares = []
	for i in range(grid_size): 
		squares.append([])
		velocities.append([])
		for j in range(grid_size):
			squares[i].append(0.)
			velocities[i].append(Vector2(0, 0))
	
	#for j in range(grid_size):
		#for i in range(25, 27):
			#velocities[i][j] = Vector2(30., 0.)
		#for i in range(23, 24):
			#velocities[i][j] = Vector2(20., 0.)
		#for i in range(27, 28):
			#velocities[i][j] = Vector2(20., 0.)
		#for i in range(20, 22):
			#velocities[i][j] = Vector2(5., 0.)
		#for i in range(28, 30):
			#velocities[i][j] = Vector2(5., 0.)
	
func add_density(i: int, j: int, delta: float):
	squares[i][j] += max(delta * DENSITY, 1.)
	
func add_velocity(i: int, j: int, delta: float, vector: Vector2):
	velocities[i][j] += delta * vector
	
func lerp(a,b,k):
	return a + k*(b-a)

func diffuse(delta: float):
	var a = delta * DIFFUSION_RATE
	
	for k in range(20):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				var initial_density = squares[i][j]
				squares[i][j] = (initial_density + a*(squares[i-1][j] + squares[i+1][j] + squares[i][j-1] + squares[i][j+1]))/(1+4*a)
	
func diffuse_v(delta: float):
	var a = delta * DIFFUSION_RATE
	
	for k in range(20):
		for i in range(1, size - 1):
			for j in range(1, size - 1):
				var initial_density = velocities[i][j]
				velocities[i][j] = (initial_density + a*(velocities[i-1][j] + velocities[i+1][j] + velocities[i][j-1] + velocities[i][j+1]))/(1+4*a)

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
			var z1 = lerp(squares[floored.x][floored.y], squares[floored.x + 1][floored.y], frac.x)
			var z2 = lerp(squares[floored.x][floored.y + 1], squares[floored.x + 1][floored.y + 1], frac.x)
			squares[i][j] = lerp(z1, z2, frac.y)
			
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

func update_velocity(delta: float):
	diffuse_v(delta)
	advect_v(delta)
