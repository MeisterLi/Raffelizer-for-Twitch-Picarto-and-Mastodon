extends Area2D
class_name Avatar

@onready var sprite : Sprite2D = $AvatarSprite/Sprite2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var particles : GPUParticles2D = $GPUParticles2D
@onready var gamefield : Node2D = get_parent()
@onready var weapon : Sprite2D = $Weapon
@onready var collisionShape: CollisionShape2D = $CollisionShape2D
@onready var remove_button: TextureButton = $RemoveButton

var moving_to_center = false
var knock_position = Vector2.ZERO
var knocked = false
var speed = 200
var move_curve
@onready var screen = get_viewport_rect().size
@onready var center_screen = Vector2(screen / 2)
var user_name = ""
var display_name = ""
var inc = 0
var winner = false
var _json = JSON.new()
var twitch_token = ""
var twitch_client_id = "0g3zp9jikletk9afwneyw75iobuslx"
@onready var participating_users = gamefield.participating_users
var twitch = false
var picarto_image_url
var move_offset
var dodge = false
var waiting = true
var ko = false
var firstRun = false
var custom_animation = ""
var mastodon_home
var avatar_icon

# Called when the node enters the scene tree for the first time.
	
func start():
	hide()
	weapon.hide()
	twitch = $/root/Main/Settings.twitch
	animation_player.play("Bounce")
	global_position = get_free_spawn_location(false)
	gamefield.positions.append(global_position)
	print(str(gamefield.positions))
	if twitch:
		get_twitch_avatar_url()
	elif avatar_icon is Texture2D:
		print("Icon is a Sprite2D!")
		update_texture(avatar_icon)
		manual_start()
	else:
		get_picarto_avatar_url()

func get_free_spawn_location(being_knocked):
	var possible_position = get_spawn_location(being_knocked)
	var overlapping = false
	var attempts = 0
	if gamefield.positions != [] and gamefield.positions.size() <= 24: # After 24 participants, it becomes unrealistic to attempt to find a free space, so let's not
		for point in gamefield.positions:
			print("Checking point {point} for overlap".format({"point" : point}))
			if (possible_position.x < point.x + 64 and 
			possible_position.x + 64 > point.x and 
			possible_position.y < point.y + 64 and 
			possible_position.y + 64 > point.y):
				print("Spawn location {possible_position} overlaps, generating new...".format({"possible_position" : possible_position}))
				attempts = attempts + 1
				overlapping = true
				break
		if overlapping == true:
			possible_position = get_free_spawn_location(being_knocked)
			
	return possible_position

func get_spawn_location(being_knocked):
	randomize()
	var max_value = center_screen - Vector2(27, 15)
	var min_value = max_value - Vector2(50, 50)
	if being_knocked:
		max_value = center_screen - Vector2(50, 50)
		min_value = max_value - Vector2(30, 30)
	var border = center_screen.y / center_screen.x
	var upper = randf() < border
	var pos_x = lerpf(0 if upper else min_value.x, max_value.x, randf())
	var pos_y = lerpf(0 if !upper else min_value.y, max_value.y, randf())
	pos_x = -pos_x if randf() > 0.5 else pos_x
	pos_y = -pos_y if randf() > 0.5 else pos_y
	return Vector2(int(pos_x), int(pos_y)) + center_screen

func get_twitch_avatar_url():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_twitch_info_completed)
	var twitch_request_url = "https://api.twitch.tv/helix/users?login=" + user_name
	var http_error = http_request.request(twitch_request_url, ['Authorization: Bearer ' + twitch_token, 'Client-Id: ' + twitch_client_id])
	print(str(http_error))
	if http_error != OK:
		print("Error fetching Avatar: " + http_error)

func get_picarto_avatar_url():
	download_image(picarto_image_url)
	display_name = user_name
	
func download_image(url):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)
	
	var http_error = http_request.request(url)
	print(str(http_error))
	if http_error != OK:
		print("Error fetching Avatar: " + http_error)

func _http_twitch_info_completed(_results, _response_code, _headers, body):
	_json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	print(str(data))
	var avatar_url = data["data"][0]["profile_image_url"]
	display_name = data["data"][0]["display_name"]
	download_image(avatar_url)
	
func _http_request_completed(_results, _response_code, _headers, body):
	var image_parsed = false
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)

	if image_error != OK:
		print("Image parse as png did not work, trying jpg method")
		image_error = image.load_jpg_from_buffer(body)
	else:
		image_parsed = true
	
	if image_error != OK:
		print("Image parse as jpg did not work, using placeholder")
		$AvatarSprite/Sprite2D/Label.text = display_name
	else:
		image_parsed = true
	
	if image_parsed:
		image.resize(64,64,Image.INTERPOLATE_LANCZOS)
		
		var texture = ImageTexture.create_from_image(image)
		update_texture(texture)
	
	participating_users.append(user_name)
	show()
	arm()
	
func manual_start():
	participating_users.append(user_name)
	show()
	arm()
	
func update_texture(texture):
	sprite.texture = texture
	
func arm():
	var all_weapons = ["bat", "katana", "morningstar", "raygun", "brick", "foldingchair", "bomb", "newspaper", "fryingpan", "rollingpin", "bottle"]
	var selectedWeapon = all_weapons[randi() % all_weapons.size()]
	var weapon_texture = "res://Images/%s.png" % selectedWeapon
	weapon_texture = load(weapon_texture)
	weapon.texture = weapon_texture
	weapon.set_rotation(randf_range(-0.1, 0.6))
	if selectedWeapon in ["raygun", "bomb", "foldingchair", "brick"]:
		weapon.set_position(Vector2(37, 30))
	weapon.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_animation_state()
	if moving_to_center:
		if global_position.distance_to(center_screen) < 16:
			global_position = center_screen
			moving_to_center = false
			weapon.hide()
		else:
			global_position = global_position.move_toward(center_screen, delta * speed)
			firstRun = false
	elif knocked:
		if global_position.distance_to(Vector2(knock_position)) < 16:
			global_position = knock_position
			knocked = false
			ko = true
			firstRun = false
		else:
			global_position = global_position.move_toward(knock_position, delta * (speed * 3))
			firstRun = false
	elif dodge:
		global_position = global_position.move_toward(global_position - move_offset, delta *(speed * 4))
	global_position.x = clamp(global_position.x, 32, screen.x - 32)
	global_position.y = clamp(global_position.y, 32, screen.y - 32)
		
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
	
func fight():
	$DodgeTimer.stop()
	dodge = false
	moving_to_center = true
	waiting = false
	
func check_animation_state():
	if winner:
		if animation_player.get_current_animation() == "Bounce":
			animation_player.stop()
		animation_player.play("Winner")
		remove_button.hide()
	elif custom_animation == "Flip":
		animation_player.play("Backflip")
		custom_animation = ""
	elif custom_animation == "Rainbow":
		animation_player.play("Rainbow")
		custom_animation = ""
	elif custom_animation == "Stop":
		animation_player.stop()
	elif custom_animation == "Mushroom":
		print("Playing Mushroom animation")
		animation_player.play("Mushroom")
		custom_animation = "Waiting"
	elif custom_animation == "Removeme":
		remove_self()
	elif custom_animation == "" and animation_player.get_current_animation() == "" and not knocked and not ko and not winner:
		animation_player.play("Bounce")
		print("Triggering bounce from custom animation")
	elif moving_to_center:
		if animation_player.get_current_animation() == "Bounce":
			animation_player.stop()
		animation_player.play("Walk")
	elif ko and not firstRun:
		var rotationvalue = randi_range(-92, -85) if randf() > 0.5  else randi_range(92, 85)
		sprite.set_rotation(deg_to_rad(rotationvalue))
		remove_button.hide()
		animation_player.stop()
		$Stars.show()
		$Stars.play("stars")
		firstRun = true
	
func stop():
	custom_animation = "Stop"

func knock():
	knocked = true
	knock_position = get_free_spawn_location(knocked)
	
func _on_avatar_area_entered():
	if waiting: 
		$DodgeTimer.start()
		move_offset = Vector2(randi_range(-8, 8), randi_range(-8, 8))
		dodge = true

func _on_dodge_timer_timeout():
	dodge = false

func _on_animation_player_animation_finished(_animation_name):
	print("Animation done playing!")
	if not ko and not moving_to_center and not winner and not custom_animation == "Waiting" and not custom_animation == "Stop":
		animation_player.play("Bounce")
		print("Triggering bounce from animation finished")
	elif custom_animation == "Waiting":
		$ShrinkTimer.start(5)
	elif custom_animation == "Stop":
		animation_player.stop()

func _on_shrink_timer_timeout():
	animation_player.play_backwards("Mushroom")
	custom_animation = ""

func _on_remove_button_pressed():
	remove_self()
	
func remove_self():
	gamefield.remove_user(user_name)

func flip():
	sprite.flip_h = true
