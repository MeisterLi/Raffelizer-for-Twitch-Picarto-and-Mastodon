extends Position2D

var rotating = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if rotating:
		set_rotation(randf_range(0, deg2rad(360)))

func start():
	rotating = true
