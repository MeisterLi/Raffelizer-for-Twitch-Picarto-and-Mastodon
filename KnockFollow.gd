extends PathFollow2D
var started = false
var t := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (started):
		offset = t * 20
