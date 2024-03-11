extends Node

var side: int
var length: int

var array: Array = []

func _init(grid_side: int, initVal):
	side = grid_side
	length = grid_side * grid_side
	for i in range(length):
		array.append(initVal)
		
func getEl(i: int, j: int):
	return array[(i * side) + j]
	
func change(i: int, j: int, newVal):
	array[(i * side) + j] = newVal

func add(i: int, j: int, newVal):
	array[(i * side) + j] += newVal
