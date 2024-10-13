extends Node2D

const squareSize: float = 10.0
const gridSquares: int = 70
const gridPixelSize = squareSize * gridSquares


const FluidGrid = preload("utils/FluidGrid.gd")
var grid : FluidGrid

var isLeftClicking = false
var isRightClicking = false

const nullSquare = {
	"i": null,
	"j": null
}
var previousSquare = nullSquare.duplicate()
var currentSquare = nullSquare.duplicate()

var previousPos = Vector2(0., 0.)
var currentPos = Vector2(0., 0.)
var currentVelocity: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	grid = FluidGrid.new(gridSquares)
	DisplayServer.window_set_size(Vector2i(gridPixelSize, gridPixelSize))
	self.position = get_viewport_rect().size/2

func _draw():
	draw_rect(Rect2(-gridPixelSize/2, -gridPixelSize/2, gridPixelSize, gridPixelSize), Color.BLACK)
	for i in range(gridSquares):
		for j in range(gridSquares):
			draw_rect(
				Rect2(-gridPixelSize/2 + (squareSize * j), -gridPixelSize/2 + (squareSize * i), squareSize, squareSize),
				Color(1, 1, 1, grid.densities[(j * gridSquares) + i])
			)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (
		previousSquare.i and previousSquare.j and
		currentSquare.i and currentSquare.i != gridSquares and
		currentSquare.j and currentSquare.j != gridSquares
	):
		if abs(currentSquare.i - previousSquare.i) <= 1 and abs(currentSquare.j - previousSquare.j) <= 1:
			if isRightClicking:
				grid.add_velocity(currentSquare.i, currentSquare.j, 10., currentVelocity)
			if isLeftClicking:
				grid.add_density(currentSquare.i, currentSquare.j, delta)
		else:
			var walkedCells = grid.get_line(previousSquare.i, previousSquare.j, currentSquare.i, currentSquare.j)
			var cellsLength = walkedCells.size()
			if isLeftClicking:
				for cell in walkedCells:
					grid.add_density(cell.x, cell.y, delta/cellsLength)
					
			if isRightClicking:
				for cell in walkedCells:
					grid.add_velocity(cell.x, cell.y,  5., currentVelocity/cellsLength)

	queue_redraw()
	grid.diffuse(delta)
	grid.diffuse_v(delta)
	grid.clear_divergence()
	grid.vorticity_confinment(delta)
	grid.advect(delta)
	grid.advect_v(delta)

func _input(event):
	if event is InputEventMouseButton:
		if not event.pressed:
			previousSquare = nullSquare.duplicate()
			currentSquare = nullSquare.duplicate()
			currentVelocity = Vector2(0., 0.)
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				isLeftClicking = event.pressed
			MOUSE_BUTTON_RIGHT:
				isRightClicking = event.pressed
				
	previousSquare = currentSquare.duplicate()
	
	previousPos = currentPos
	currentPos = get_global_mouse_position()
				
	if (event is InputEventMouseMotion or event is InputEventMouseButton) and (isLeftClicking or isRightClicking):
		var gridMousePosition = event.position - get_viewport_rect().size/2 + Vector2(gridPixelSize/2, gridPixelSize/2)
		if gridMousePosition.x < 0. || gridMousePosition.y < 0. || gridMousePosition.x >= gridPixelSize || gridMousePosition.y >= gridPixelSize:
			currentSquare.i = null
			currentSquare.j = null
		else:
			currentSquare.i = floor((gridMousePosition.x / gridPixelSize) * gridSquares)
			currentSquare.j = floor((gridMousePosition.y / gridPixelSize) * gridSquares)
			
	if (event is InputEventMouseMotion) and isRightClicking:
		currentVelocity = (currentPos - previousPos) * 5
