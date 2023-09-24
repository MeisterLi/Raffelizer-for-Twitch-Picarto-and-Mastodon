extends Node

var config = ConfigFile.new()
@onready var main = $/root/Main
@onready var game_ui = $/root/Main/MainUi
@onready var game = $/root/Main/GameField
@onready var timer : Timer = $AutoTimer
@onready var background = $/root/Main/ParallaxBackground
@onready var color_rect = $/root/Main/ColorRect
@onready var ignore_user_list : ItemList = $SettingsPanel/Ignore_Names/ItemList
signal no_config
signal reset_game
signal exit_to_url
var config_present = true
var state
var twitch_name = ""
var picarto_name = ""
var picarto_token = ""
var toot_url = ""
var twitch = false
var weapons = true
var auto_timer = false
var current_state = ""
var fight_cooldown = 1
var transparency_mode = false
var mode
var mastodon_following = true
var mastodon_boosted = true
var mastodon_faved = true
var ignore_users = []
var json = JSON.new()

enum states {SELECT_MODE, INPUT_TWITCH, INPUT_PICARTO, INPUT_MASTODON, INPUT_WORD, DISABLED, GAME_END, SETTINGS, INPUT_MANUAL, WAITING}
enum modes {TWITCH, PICARTO, MASTODON, MANUAL}
	
func _ready():
	timer.stop()
	$FightCooldown.stop()
	var err = config.load("user://raffelizer.ini")
	if err != OK:
		config_present = false
	twitch_name = config.get_value("config", "twitch_name", "")
	picarto_name = config.get_value("config", "picarto_name", "")
	picarto_token = config.get_value("config", "picarto_token", "")
	ignore_users = config.get_value("config", "ignore_users")
	for item in ignore_users:
		ignore_user_list.add_item(item)
	print("auto_timer is " + str(auto_timer))
	
	_change_to_state(states.SELECT_MODE)
	
func _on_twitch_pressed():
	_change_to_state(states.INPUT_TWITCH)
	twitch = true
	mode = modes.TWITCH

func get_ignored_users():
	var err = config.load("user://raffelizer.ini")
	if err != OK:
		pass
	ignore_users = config.get_value("config", "ignore_users", "")
	return ignore_users
	
func _on_picarto_pressed():
	_change_to_state(states.INPUT_PICARTO)
	mode = modes.PICARTO
	
func _on_mastadon_pressed():
	_change_to_state(states.INPUT_MASTODON)
	mode = modes.MASTODON
	
func _on_manual_pressed():
	_change_to_state(states.INPUT_MANUAL)
	mode = modes.MANUAL
	
func set_error(error):
	$ErrorText.set_error(error)
	
func _on_save_button_pressed():
	var name_input = $NameInput.get_text().strip_edges(true, true)
	var pw_input = $TokenInput.get_text().strip_edges(true, true)
	var placeholder = $NameInput.get_placeholder().strip_edges(true, true)
	if current_state == states.INPUT_TWITCH:
		if $NameInput.get_text() != "" && name_input == "":
			print("Please put in a valid username")
			set_error("Please put in a valid username")
			return
		elif name_input == "":
			twitch_name = placeholder
		else:
			twitch_name = name_input
	elif current_state == states.INPUT_PICARTO:
		if ($NameInput.get_text() != "" && name_input == "") || ($TokenInput.get_text() != "" && pw_input == ""):
			print("Please enter your username and token!")
			set_error("Please enter your username and token!")
			return
		elif name_input == "":
			picarto_name = placeholder
		else:
			picarto_token = pw_input
			picarto_name = name_input
	elif current_state == states.INPUT_MASTODON:
		if !_validate_url(name_input, true):
			set_error("Please put in a valid toot URL")
			return
		else:
			toot_url = name_input
	config.set_value("config", "picarto_name", picarto_name)
	config.set_value("config", "twitch_name", twitch_name)
	config.set_value("config", "picarto_token", picarto_token)
	var err = config.save("user://raffelizer.ini")
	if err != OK:
		print(err)
	$StatusLabel.text = "Saved!"
	
func _validate_url(url, mastodon):
	print("Validating url")
	var regex = RegEx.new()
	if (mastodon):
		regex.compile("https:\\/\\/(.*)\\/@.*\\/(.*)")
		var result = regex.search(url)
		if !result:
			return false
		else:
			if result.get_string(1) != "" && result.get_string(2) != "":
				return true
			else:
				return false
	else:
		regex.compile("wss:\\/\\/chat\\.picarto\\.tv\\/chat\\/token=(.*)")
		var result = regex.search(url)
		if !result:
			return false
		else:
			return true
	
func _on_exit_pressed():
	if current_state == states.SETTINGS:
		_change_to_state(states.SELECT_MODE)
	elif current_state == states.WAITING:
		reset_game.emit()
		if mode == modes.TWITCH:
			_change_to_state(states.INPUT_TWITCH)
			exit_to_url.emit()
		elif mode == modes.PICARTO:
			_change_to_state(states.INPUT_PICARTO)
			exit_to_url.emit()
	elif current_state == states.DISABLED:
		reset_game.emit()
		if mode == modes.TWITCH:
			_change_to_state(states.INPUT_TWITCH)
			exit_to_url.emit()
		elif mode == modes.PICARTO:
			_change_to_state(states.INPUT_PICARTO)
			exit_to_url.emit()
	elif current_state in [states.INPUT_MANUAL, states.INPUT_MASTODON, states.INPUT_PICARTO, states.INPUT_TWITCH]:
		_change_to_state(states.SELECT_MODE)
	
func _on_reset_pressed():
	reset_game.emit()
	print("Mode is: " + str(mode))
	if mode == modes.MASTODON:
		_change_to_state(states.INPUT_MASTODON)
	if mode == modes.TWITCH:
		_change_to_state(states.DISABLED)
	if mode == modes.PICARTO:
		_change_to_state(states.DISABLED)
	if mode == modes.MANUAL:
		_change_to_state(states.INPUT_MANUAL)
		$/root/Main/ManualMode.reset()

func _on_setting_entry_pressed():
	_change_to_state(states.SETTINGS)

func _on_line_edit_text_submitted(new_text):
	$AutoTimer.set_wait_time(new_text.to_int() * 60)
	
func _on_time_before_restart_text_submitted(new_text):
	fight_cooldown = new_text.to_int()
	
func _on_check_box_toggled(button_pressed):
	auto_timer = button_pressed
	print("auto_timer is " + str(auto_timer))
	
func _on_transparency_mode_toggled(button_pressed):
	set_transparency(button_pressed)
	
func toggle_transparency():
	if transparency_mode == false:
		set_transparency(true)
	else:
		set_transparency(false)
		
func set_transparency(on):
	if on == true:
		background.hide()
		color_rect.hide()
		get_tree().get_root().set_transparent_background(true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
		transparency_mode = true
	elif on == false:
		background.show()
		color_rect.hide()
		get_tree().get_root().set_transparent_background(false)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, false, 0)
		transparency_mode = false
	
func _on_auto_timer_timeout():
	if auto_timer:
		print("Auto Timer Timeout triggered")
		$FightCooldown.start(fight_cooldown * 60)
		game.count_down.start()
	
func _on_fight_cooldown_timeout():
	reset_game.emit()
	game.handle_auto_start()

func _change_to_state(new_state):
	match new_state:
		states.SELECT_MODE:
			$SettingEntry.show()
			$ModeSelect/MastodonSettings.hide()
			$ModeSelect/Picarto.show()
			$ModeSelect/Twitch.show()
			$ModeSelect/Mastodon.show()
			$ModeSelect/Manual.show()
			$SettingsPanel.hide()
			$NameInput.hide()
			$TokenInput.hide()
			$TokenButton.hide()
			$SaveButton.hide()
			$StartButton.hide()
			$SettingsLabel.show()
			$StatusLabel.show()
			$Exit.hide()
			$StatusLabel.text = "Select Mode"
			$Reset.hide()
			current_state = states.SELECT_MODE
		states.INPUT_TWITCH:
			$SettingEntry.hide()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Manual.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Mastodon.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$NameInput.show()
			$TokenInput.hide()
			$TokenButton.hide()
			$SaveButton.show()
			$StartButton.show()
			$StartButton.set_position(Vector2(512, 504))
			$SettingsLabel.show()
			$Exit.show()
			$NameInput.placeholder_text = twitch_name
			$StatusLabel.show()
			$Reset.hide()
			$StatusLabel.text = "Input Twitch channel name!"
			current_state = states.INPUT_TWITCH
		states.INPUT_PICARTO:
			$SettingEntry.hide()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Mastodon.hide()
			$ModeSelect/Manual.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$NameInput.show()
			$TokenInput.show()
			$TokenButton.show()
			$SaveButton.show()
			$StartButton.show()
			$StartButton.set_position(Vector2(512, 504))
			$SettingsLabel.show()
			$Exit.show()
			$NameInput.placeholder_text = picarto_name
			$StatusLabel.show()
			$Reset.hide()
			$StatusLabel.text = "Input Picarto username and token!"
			current_state = states.INPUT_PICARTO
		states.INPUT_MASTODON:
			$SettingEntry.hide()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Manual.hide()
			$ModeSelect/Mastodon.hide()
			$ModeSelect/MastodonSettings.show()
			$SettingsPanel.hide()
			$NameInput.show()
			$TokenInput.hide()
			$TokenButton.hide()
			$SaveButton.hide()
			$StartButton.show()
			$StartButton.set_position(Vector2(384, 504))
			$SettingsLabel.show()
			$Exit.show()
			$NameInput.placeholder_text = "Input url to Mastodon Toot!"
			$StatusLabel.show()
			$Reset.hide()
			$StatusLabel.text = "Input url to Mastodon Toot!"
			current_state = states.INPUT_MASTODON
		states.DISABLED:
			print("Disabled UI")
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Manual.hide()
			$ModeSelect/Mastodon.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$NameInput.hide()
			$TokenInput.hide()
			$TokenButton.hide()
			$SaveButton.hide()
			$StartButton.hide()
			$SettingsLabel.hide()
			$StatusLabel.hide()
			$Exit.show()
			$Reset.hide()
			main.input_raffle_word()
			current_state = states.DISABLED
		states.GAME_END:
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Manual.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$NameInput.hide()
			$TokenInput.hide()
			$TokenButton.hide()
			$SaveButton.hide()
			$StartButton.hide()
			$SettingsLabel.hide()
			$StatusLabel.hide()
			$Exit.hide()
			$Reset.show()
			current_state = states.GAME_END
		states.SETTINGS:
			$SettingsPanel.show()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Mastodon.hide()
			$ModeSelect/Manual.hide()
			$ModeSelect/MastodonSettings.hide()
			$NameInput.hide()
			$TokenInput.hide()
			$TokenButton.hide()
			$SaveButton.hide()
			$StartButton.hide()
			$SettingsLabel.show()
			$StatusLabel.hide()
			$Exit.show()
			$StatusLabel.hide()
			$Reset.hide()
			current_state = states.SETTINGS
		states.INPUT_MANUAL:
			$SettingEntry.hide()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Mastodon.hide()
			$ModeSelect/Manual.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$NameInput.hide()
			$TokenInput.hide()
			$TokenButton.hide()
			$SaveButton.hide()
			$StartButton.hide()
			$SettingsLabel.hide()
			$Exit.hide()
			$NameInput.hide()
			$StatusLabel.hide()
			$Reset.hide()
			$StatusLabel.hide()
			$/root/Main/ManualMode.show()
			current_state = states.INPUT_MANUAL

func _on_following_toggled(_button_pressed):
	mastodon_following = not mastodon_following

func _on_boosted_toggled(_button_pressed):
	mastodon_boosted = not mastodon_boosted

func _on_liked_toggled(_button_pressed):
	mastodon_faved = not mastodon_faved

func _on_link_button_down():
	OS.shell_open("https://manikobunneh.itch.io/")

func _on_start_button_pressed():
	if mode == modes.TWITCH or mode == modes.PICARTO:
		_change_to_state(states.DISABLED)
	elif mode == modes.MASTODON:
		var name_input = $NameInput.get_text().strip_edges(true, true)
		if !_validate_url(name_input, true):
			set_error("Please put in a valid toot URL")
			return
		else:
			toot_url = name_input
			_change_to_state(states.DISABLED)
	else:
		_change_to_state(states.DISABLED)
		game.handle_auto_start()

func _on_token_button_pressed():
	OS.shell_open("https://oauth.picarto.tv/chat/bot")

func _on_main_wait_for_raffle():
	current_state = states.WAITING

func _on_button_pressed():
	var item = $SettingsPanel/Ignore_Names/LineEdit.get_text()
	if item != "":
		ignore_user_list.add_item(item)

func _on_button_2_pressed():
	var items = []
	var item_number = ignore_user_list.get_item_count()
	for item in range(item_number):
		items.append(ignore_user_list.get_item_text(item))
	config.set_value("config", "ignore_users", items)
	var err = config.save("user://raffelizer.ini")
	if err != OK:
		print(err)
	$StatusLabel.text = "Saved!"

func _on_button_3_pressed():
	var selected_items = ignore_user_list.get_selected_items()
	for item in selected_items:
		ignore_user_list.remove_item(item)
