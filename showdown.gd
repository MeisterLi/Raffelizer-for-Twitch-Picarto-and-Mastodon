extends Node2D
@onready var avatar2: Node2D = $AnimationContainer/Avatar2
@onready var avatar1: Node2D = $AnimationContainer/Avatar1
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var kamehameha: Node2D = $AnimationContainer/Kamehameha
@onready var animation_container: Node2D = $AnimationContainer
@onready var speed_lines: Sprite2D = $SpeedLines
@onready var weapon: Sprite2D = $AnimationContainer/Avatar1/weapon
@onready var settings_node : settings = $/root/Main/Settings

@export var raygun : Texture2D
@export var basey : Texture2D

var mirrored := true
var animations : Array[String] = ["mushroom", "KirbyThrow", "baseball_bat", "kamehameright", "shrink_ray"]
var selected_animation
var winner_avatar : Avatar
var loser_avatar : Avatar

func reset() -> void:
	weapon.hide()
	avatar2.position = Vector2(512, 320)
	avatar2.rotation_degrees = 0
	avatar2.scale = Vector2(1.0, 1.0)
	avatar1.z_index = 0
	avatar1.position = Vector2(512, 320)
	avatar1.rotation_degrees = 0
	avatar1.scale = Vector2(1.0, 1.0)
	for child in avatar1.get_children():
		if child is Avatar:
			child.queue_free()
	for child in avatar2.get_children():
		if child is Avatar:
			child.queue_free()
	mirrored = true
	winner_avatar = null
	loser_avatar = null
	selected_animation = null

func start(winner: Avatar, loser: Avatar) -> void:
	settings_node.reset_game.connect(reset)
	reset()
	kamehameha.hide()
	speed_lines.show()
	selected_animation = animations.pick_random()
	if randi() % 2:
		mirrored = false
	winner.reparent(avatar1)
	loser.reparent(avatar2)
	winner.stop()
	loser.stop()
	winner_avatar = avatar1.get_child(2)
	loser_avatar = avatar2.get_child(0)
	if mirrored:
		animation_container.scale = Vector2(-1.0, 1.0)
		animation_container.position = Vector2(1024, 0)
	winner_avatar.animation_player.stop()
	loser_avatar.animation_player.stop()
	animation_player.play("seperate")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "seperate":
		animation_player.play(selected_animation)
		if selected_animation == "shrink_ray":
			weapon.texture = raygun
		elif selected_animation == "baseball_bat":
			weapon.texture = basey
	else:
		loser_avatar.ko = true
		var final_location_winner = winner_avatar.global_position
		var final_location_loser = loser_avatar.global_position
		avatar1.z_index = 1
		animation_player.stop()
		winner_avatar.global_position = final_location_winner
		loser_avatar.global_position = final_location_loser
		loser_avatar.custom_animation = ""
		if anim_name == "shrink_ray":
			loser_avatar.hide()
		elif anim_name == "mushroom":
			weapon.hide()
		get_parent().display_winner()
		kamehameha.hide()
		speed_lines.hide()
