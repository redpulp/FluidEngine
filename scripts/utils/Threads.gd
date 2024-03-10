extends Node
var threads: Array
var numOfThreads: int

# Called when the node enters the scene tree for the first time.
func _init():
	for i in range(OS.get_processor_count() * 0.5):
		threads.append(Thread.new())
		
	numOfThreads = threads.size()
	
func offload(function, index):
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
