extends Node

var config = ConfigFile.new()
@onready var main = $/root/Main
@onready var game_ui = $/root/Main/MainUi
@onready var game = $/root/Main/GameField
@onready var timer : Timer = $AutoTimer
@onready var background = $/root/Main/ParallaxBackground
@onready var color_rect = $/root/Main/ColorRect
signal no_config
signal reset_game
var config_present = true
var state
var twitch_name = ""
var picarto_url = ""
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

enum states {SELECT_MODE, INPUT_TWITCH, INPUT_PICARTO, INPUT_MASTODON, DISABLED, GAME_END, SETTINGS}
enum modes {TWITCH, PICARTO, MASTODON}
	
func _ready():
	timer.stop()
	$FightCooldown.stop()
	var err = config.load("user://raffelizer.ini")
	if err != OK:
		config_present = false
	twitch_name = config.get_value("config", "twitch_name", "")
	picarto_url = config.get_value("config", "picarto_url", "")
	print("auto_timer is " + str(auto_timer))
	
	_change_to_state(states.SELECT_MODE)
	
func _on_twitch_pressed():
	_change_to_state(states.INPUT_TWITCH)
	twitch = true
	mode = modes.TWITCH
	
func _on_picarto_pressed():
	_change_to_state(states.INPUT_PICARTO)
	mode = modes.PICARTO
	
func _on_mastadon_pressed():
	_change_to_state(states.INPUT_MASTODON)
	mode = modes.MASTODON
	
func set_error(error):
	$ErrorText.set_error(error)
	
func _on_button_pressed():
	var input = $InputField2.get_text().strip_edges(true, true)
	var placeholder = $InputField2.get_placeholder().strip_edges(true, true)
	if current_state == states.INPUT_TWITCH:
		if $InputField2.get_text() != "" && input == "":
			print("Please put in a valid username")
			set_error("Please put in a valid username")
			return
		elif input == "":
			twitch_name = placeholder
		else:
			twitch_name = input
	elif current_state == states.INPUT_PICARTO:
		if $InputField2.get_text() != "" && input == "":
			print("Please put in a valid url")
			set_error("Please put in a valid url")
			return
		elif input == "":
			picarto_url = placeholder
		else:
			if !_validate_url(input, false):
				set_error("Please put in a valid picarto Websocket URL!")
				return
			picarto_url = input
	elif current_state == states.INPUT_MASTODON:
		if !_validate_url(input, true):
			set_error("Please put in a valid toot URL")
			return
		else:
			toot_url = input
	config.set_value("config", "picarto_url", picarto_url)
	config.set_value("config", "twitch_name", twitch_name)
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
	else:
		_change_to_state(states.DISABLED)
		game.handle_auto_start()
	
func _on_reset_pressed():
	reset_game.emit()
	print("Mode is: " + str(mode))
	if mode == modes.MASTODON:
		_change_to_state(states.INPUT_MASTODON)
	if mode == modes.TWITCH:
		_change_to_state(states.INPUT_TWITCH)
	if mode == modes.PICARTO:
		_change_to_state(states.INPUT_PICARTO)

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
		color_rect.show()
		$SettingEntry.set_flat(true)
		$ModeSelect/Picarto.set_flat(true)
		$ModeSelect/Twitch.set_flat(true)
		$Button.set_flat(true)
		$Exit.set_flat(true)
		$Reset.set_flat(true)
		game_ui.start_button_button.set_flat(true)
		game_ui.raffle_word.set_flat(true)
		transparency_mode = true
	elif on == false:
		background.show()
		color_rect.hide()
		$SettingEntry.set_flat(false)
		$ModeSelect/Picarto.set_flat(false)
		$ModeSelect/Twitch.set_flat(false)
		$Button.set_flat(false)
		$Exit.set_flat(false)
		$Reset.set_flat(false)
		game_ui.start_button_button.set_flat(false)
		game_ui.raffle_word.set_flat(false)
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
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$InputField2.hide()
			$Button.hide()
			$SettingsLabel.show()
			$StatusLabel.show()
			$Exit.hide()
			$StatusLabel.text = "Select Mode"
			$Reset.hide()
			current_state = states.SELECT_MODE
		states.INPUT_TWITCH:
			$SettingEntry.hide()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Mastadon.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$InputField2.show()
			$Button.show()
			$SettingsLabel.show()
			$Exit.show()
			$InputField2.placeholder_text = twitch_name
			$StatusLabel.show()
			$Reset.hide()
			$StatusLabel.text = "Input Twitch channel name!"
			current_state = states.INPUT_TWITCH
		states.INPUT_PICARTO:
			$SettingEntry.hide()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Mastadon.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$InputField2.show()
			$Button.show()
			$SettingsLabel.show()
			$Exit.show()
			$InputField2.placeholder_text = picarto_url
			$StatusLabel.show()
			$Reset.hide()
			$StatusLabel.text = "Input Picarto chat websocket url!"
			current_state = states.INPUT_PICARTO
		states.INPUT_MASTODON:
			$SettingEntry.hide()
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Mastadon.hide()
			$ModeSelect/MastodonSettings.show()
			$SettingsPanel.hide()
			$InputField2.show()
			$Button.show()
			$SettingsLabel.show()
			$Exit.show()
			$InputField2.placeholder_text = "Input url to Mastodon Toot!"
			$StatusLabel.show()
			$Reset.hide()
			$StatusLabel.text = "Input url to Mastodon Toot!"
			current_state = states.INPUT_MASTODON
		states.DISABLED:
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/Mastadon.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$InputField2.hide()
			$Button.hide()
			$SettingsLabel.hide()
			$StatusLabel.hide()
			$Exit.hide()
			$Reset.hide()
			main.input_raffle_word()
			current_state = states.DISABLED
		states.GAME_END:
			$ModeSelect/Picarto.hide()
			$ModeSelect/Twitch.hide()
			$ModeSelect/MastodonSettings.hide()
			$SettingsPanel.hide()
			$InputField2.hide()
			$Button.hide()
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
			$ModeSelect/MastodonSettings.hide()
			$InputField2.hide()
			$Button.hide()
			$SettingsLabel.show()
			$StatusLabel.hide()
			$Exit.show()
			$StatusLabel.hide()
			$Reset.hide()
			current_state = states.SETTINGS

func _on_following_toggled(_button_pressed):
	mastodon_following = not mastodon_following

func _on_boosted_toggled(_button_pressed):
	mastodon_boosted = not mastodon_boosted

func _on_liked_toggled(_button_pressed):
	mastodon_faved = not mastodon_faved
