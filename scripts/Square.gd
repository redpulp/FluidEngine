extends Node2D

const squareSize: float = 10.0
const gridSquares: int = 50
const gridPixelSize = squareSize * gridSquares

const FluidGrid = preload("utils/FluidGrid.gd")
var grid : FluidGrid

var isLeftClicking = false
var isRightClicking = false

var currentSquare = {
	"i": null,
	"j": null
}

# Called when the node enters the scene tree for the first time.
func _ready():
	grid = FluidGrid.new(gridSquares)
	self.position = get_viewport_rect().size/2
	pass

func _draw():
	draw_rect(Rect2(-gridPixelSize/2, -gridPixelSize/2, gridPixelSize, gridPixelSize), Color.BLACK)
	for i in range(gridSquares):
		for j in range(gridSquares):
			draw_rect(
				Rect2(-gridPixelSize/2 + (squareSize * j), -gridPixelSize/2 + (squareSize * i), squareSize, squareSize),
				Color(1, 1, 1, grid.squares[j][i])
			)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (
		isLeftClicking
		and currentSquare.i and currentSquare.i != gridSquares
		and currentSquare.j and currentSquare.j != gridSquares
	):
		grid.add_density(currentSquare.i, currentSquare.j, delta)
	queue_redraw()
	grid.diffuse(delta)
	grid.advect(delta)
	grid.update_velocity(delta)
	pass

func _input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				isLeftClicking = event.pressed
			MOUSE_BUTTON_RIGHT:
				isRightClicking = event.pressed
		
	if (event is InputEventMouseMotion or event is InputEventMouseButton) and isLeftClicking:
		var gridMousePosition = event.position - get_viewport_rect().size/2 + Vector2(gridPixelSize/2, gridPixelSize/2)
		if gridMousePosition.x < 0. || gridMousePosition.y < 0. || gridMousePosition.x >= gridPixelSize || gridMousePosition.y >= gridPixelSize:
			currentSquare.i = null
			currentSquare.j = null
		else:
			currentSquare.i = floor((gridMousePosition.x / gridPixelSize) * gridSquares)
			currentSquare.j = floor((gridMousePosition.y / gridPixelSize) * gridSquares)
			
	if (event is InputEventMouseMotion) and isRightClicking:
		var gridMousePosition = event.position - get_viewport_rect().size/2 + Vector2(gridPixelSize/2, gridPixelSize/2)
		if gridMousePosition.x >= 0. || gridMousePosition.y >= 0. || gridMousePosition.x < gridPixelSize || gridMousePosition.y < gridPixelSize:
			var index_i = floor((gridMousePosition.x / gridPixelSize) * gridSquares)
			var index_j = floor((gridMousePosition.y / gridPixelSize) * gridSquares)
			if index_i != gridSquares and index_j != gridSquares:
				grid.add_velocity(index_i, index_j, 10., event.velocity)
	pass
	
	
