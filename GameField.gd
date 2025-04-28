extends Node2D
class_name GameField
@export var avatars: PackedScene
@export var debris: PackedScene

signal connected
signal auto_start
var fight_started := false
var debug_turns := 45
var debug_spawned := 0
var spawned_avatars = []
var knocked_avatars = []
var positions = []
var winner = ""
var timer_wait := 1.0
var time_between_rounds := 1.0
var participating_users = []
var debug_timer = false
var rng = RandomNumberGenerator.new()
var fighting = false
var colliding_bodies = 0
@onready var screen = get_viewport_rect().size
@onready var dustcloudParticles1 : CPUParticles2D = $CenterPosition/DustCloud1
@onready var dustcloudParticles2 : CPUParticles2D = $CenterPosition/DustCloud2
@onready var sheepCloud : CPUParticles2D = $CenterPosition/SheepCloud
@onready var puff1 : CPUParticles2D = $CenterPosition/Puff1
@onready var puff2 : CPUParticles2D = $CenterPosition/Puff2
@onready var centerCollider = $CenterPosition/Area2D
@onready var count_down : Timer = $FightCountdown
@onready var knock_out_timer : Timer = $KnockOutTimer
@onready var winner_text : Label = $/root/Main/MainUi/Winner
@onready var settings_node : Node = $/root/Main/Settings
@onready var exit_button : Button = $/root/Main/Settings/Exit
@onready var main_ui : Node = $/root/Main/MainUi
@onready var websocket : Node = $Websocket
@onready var auto_timer = settings_node.auto_timer
@onready var showdown: Node2D = $Showdown
@onready var camera_2d: Camera2D = $/root/Main/Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_node.connect("reset_game", reset)
	reset()
		
func reset() -> void:
	get_tree().get_root().set_transparent_background(true)
	$CenterPosition.position = screen / 2
	$AutoStartTimer.stop()
	camera_2d.zoom = Vector2(1.0, 1.0)
	winner_text.global_position.y = 208.0
	winner_text.text = ""
	if debug_timer:
		$DebugTimer.start()

func handle_auto_start() -> void:
	if settings_node.auto_timer == true:
		print("timer started with " + str(time_between_rounds))
		$AutoStartTimer.start(time_between_rounds)
		
func _on_spwan_timer_timeout() -> void:
	print("Timeout on knockout!")
	if spawned_avatars.size() != 0:
		if knocked_avatars.size() + 2 == spawned_avatars.size() and settings_node.showdown == true:
			var other_character
			for avatar in spawned_avatars:
				if avatar not in knocked_avatars:
					if avatar != winner:
						other_character = avatar
			print("Only two players left")
			showdown.show()
			showdown.start(winner, other_character)
			var camera_tween = get_tree().create_tween()
			camera_tween.tween_property(camera_2d, "zoom", Vector2(1.5, 1.5), 1.0)
			knock_out_timer.stop()
			stop_emitters()
			fighting = false
		elif knocked_avatars.size() + 1 == spawned_avatars.size():
			knock_out_timer.stop()
			stop_emitters()
			fighting = false
			display_winner()
		else:
			print("Knocking looser")
			knock_out_loser()

func display_winner() -> void:
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_property(camera_2d, "zoom", Vector2(1.0, 1.0), 1.0)
	winner_text.text = "Winner: \n" + winner.user_name
	winner_text.z_index = 2
	if winner.mastodon_home != "":
		winner_text.text += "\n" + winner.mastodon_home
		winner_text.global_position.y -= 50
	winner.winner = true
	exit_button.show()
	settings_node._change_to_state(settings.states.GAME_END)
	handle_auto_start()

func spawn_avatar(avatar_name, twitch_token, picarto_image_url, mastodon_home = "", avatar_icon = "") -> void:
	if fight_started:
		pass
	elif avatar_name in participating_users:
		pass
	else:
		var avatar : Area2D = avatars.instantiate()
		
		add_child(avatar)
		avatar.user_name = avatar_name
		avatar.twitch_token = twitch_token
		avatar.picarto_image_url = picarto_image_url
		avatar.mastodon_home = mastodon_home
		avatar.avatar_icon = avatar_icon
		avatar.start()

func spawn_avatar_debug(avatar_name, picarto_image_url) -> void:
	#for debugging
	var avatar : Area2D = avatars.instantiate()
	
	add_child(avatar)
	avatar.user_name = avatar_name
	avatar.picarto_image_url = picarto_image_url
	avatar.start()
	debug_spawned = debug_spawned + 1
	if debug_turns == debug_spawned:
		$DebugTimer.stop()

func determine_winner() -> Avatar:
	spawned_avatars.shuffle()
	winner = randi_range(0, spawned_avatars.size() - 1)
	return spawned_avatars[winner]
	
func knock_out_loser() -> void:
	for avatar in spawned_avatars:
		if avatar == winner:
			continue
		elif avatar in knocked_avatars:
			continue
		else:
			avatar.knock()
			knocked_avatars.append(avatar)
			break

func fight() -> void:
	spawned_avatars = get_tree().get_nodes_in_group("avatar")
	print("all spawned avatars" + str(spawned_avatars.size()))
	if spawned_avatars.size() < 10:
		timer_wait = 1.0
		print("Regular wait time")
	else:
		timer_wait = 30.0 / spawned_avatars.size()
		print("Adjusted Wait time " + str(timer_wait))
	knock_out_timer.set_wait_time(timer_wait)
	for avatar in spawned_avatars:
		avatar.fight()
	var ignored_users = settings_node.get_ignored_users()
	var determined_winner = ""
	while determined_winner is String || determined_winner.user_name in ignored_users:
		print("Found user to ignore, silently choosing another...")
		determined_winner = determine_winner()
	winner = determined_winner
	
	$DebugTimer.stop()
	$DustTimer.start()
	exit_button.hide()

func _on_fight_countdown_timeout() -> void:
	spawned_avatars = get_tree().get_nodes_in_group("avatar")
	if spawned_avatars.size() >= 2:
		fight()
		fight_started = true
		$WalkTimer.start()
		$DustTimer.start()
	else:
		print("No contest")
		winner_text.text = "No contest!"
		handle_auto_start()
		websocket.reset()
		if settings_node.auto_timer != true:
			settings_node._change_to_state(settings.states.GAME_END)

func spawn_debris() -> void:
	if fighting:
		var debrisSprite : Sprite2D = debris.instantiate()
		add_child(debrisSprite)
		debrisSprite.start()
		$DebrisTimer.start(randf_range(0.3, 0.6))

func check_emitters() -> void:
	if colliding_bodies >= 2 and fight_started:
		dustcloudParticles1.set_emitting(true)
		dustcloudParticles2.set_emitting(true)
		$SheepTimer.start(randi_range(4, 6))
		puff1.set_emitting(true)
		puff2.set_emitting(true)
		spawn_debris()

func stop_emitters() -> void:
	fight_started = false
	dustcloudParticles1.emitting = false
	dustcloudParticles2.emitting = false
	$SheepTimer.stop()
	puff1.emitting = false
	puff2.emitting = false
	
func _on_ui_start_button() -> void:
	count_down.start()

func _on_websocket_connected() -> void:
	emit_signal("connected")

func _on_walk_timer_timeout() -> void:
	print("Started Knockout timer")
	knock_out_timer.start()

func _on_debug_timer_timeout() -> void:
	spawn_avatar_debug("Maniko", "https://images.picarto.tv/ptvimages/1/14/149097/avatars/9fcd28ab332af81bbcfcc923.jpeg")

func trigger_animation(item, user_name) -> void:
	spawned_avatars = get_tree().get_nodes_in_group("avatar")
	print("Animation triggered from: " + user_name + " with item: " + item)
	for avatar in spawned_avatars:
		if avatar.user_name == user_name:
			avatar.custom_animation = item

func _on_settings_reset_game() -> void:
	spawned_avatars = get_tree().get_nodes_in_group("avatar")
	for avatar in spawned_avatars:
		avatar.queue_free()
	winner = ""
	spawned_avatars = []
	knocked_avatars = []
	participating_users = []
	fighting = false
	fight_started = false
	colliding_bodies = 0
	winner_text.text = ""
	websocket.reset()
	main_ui.reset()

func _on_auto_start_timer_timeout() -> void:
	print("GameField autostart timer timeout")
	$AutoStartTimer.stop()
	_on_settings_reset_game()
	auto_start.emit()

func _on_dust_timer_timeout() -> void:
	if fight_started:
		if fighting == false:
			fighting = true

func _on_sheep_timer_timeout() -> void:
	sheepCloud.set_emitting(true)

func remove_user(user_name) -> void:
	spawned_avatars = get_tree().get_nodes_in_group("avatar")
	for avatar in spawned_avatars:
		if avatar.user_name == user_name:
			spawned_avatars.erase(avatar)
			avatar.queue_free()

func _on_area_2d_area_entered(_area: Area2D) -> void:
	colliding_bodies += 1
	check_emitters()

func _on_debris_timer_timeout() -> void:
	spawn_debris()
