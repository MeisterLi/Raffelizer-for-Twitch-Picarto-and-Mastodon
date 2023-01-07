extends Node

@onready var websocket : Node = $/root/Main/GameField/Websocket
@onready var settings : Node = $/root/Main/Settings
signal no_config
signal start
signal wait_for_raffle

func _process(_delta):
	if Input.is_action_just_pressed("transparency toggle"):
		settings.toggle_transparency()
		
func input_raffle_word():
	emit_signal("wait_for_raffle")

func start_game():
	print("Start game called from main.gd")
	websocket.start()
	emit_signal("start")
	if settings.auto_timer == true:
		$/root/Main/Settings/FightCooldown.start(280)

func _on_ui_raffle_word_entered(word):
	print("Raffle word set to " + word)
	websocket.set_trigger_word(word)
	start_game()

func _on_game_field_auto_start():
	randomize()
	var words = ["Grow", "Embiggen", "Enlarge", "Huge", "Big", "Macro"]
	websocket.set_trigger_word(words[randi() % words.size()])
	start_game()
