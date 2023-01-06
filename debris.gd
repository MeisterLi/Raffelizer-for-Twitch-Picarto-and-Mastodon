extends Sprite2D

@onready var screen = get_viewport_rect().size
@onready var center_screen = Vector2(screen / 2)
var speed = 5
var velocity

func _ready():
	hide()

func start():
	position = center_screen
	speed = randi_range(200, 550)
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	_select_sprite()
	show()

func _select_sprite():
	var all_weapons = ["bat", "katana", "morningstar", "raygun", "brick", "foldingchair", "bomb", "newspaper", "fryingpan", "rollingpin", "bottle"]
	var selectedWeapon = all_weapons[randi() % all_weapons.size()]
	var weapon_texture = "res://%s.png" % selectedWeapon
	weapon_texture = load(weapon_texture)
	texture = weapon_texture
	
func _process(delta):
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	$AnimationPlayer.play("whirl")
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
