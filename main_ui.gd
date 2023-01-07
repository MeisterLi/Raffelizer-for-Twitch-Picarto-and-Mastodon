extends Control
signal start_button
signal url_entered
signal raffle_word_entered

@onready var start_button_button : Button = $StartButton
@onready var raffle_word: LineEdit = $RaffleWord
@onready var raffle_word_label: Label = $RaffleWordLabel
@onready var settings = $/root/Main/Settings
@onready var websocket = $/root/Main/GameField/Websocket
@onready var gameField = $/root/Main/GameField
var state
var connected
var raffle_word_text
var toot_response
var own_account
var _json = JSON.new()
var all_followers = []
var all_faves = []
var all_boosts = []
var request_server = ""

enum states {SETTINGS, INPUT_WORD, MASTODON_AUTORUN, WAIT_FOR_START, WAIT_FOR_CONNECTION, GAME_PLAYING, END}

func reset():
	all_followers.clear()
	all_faves.clear()
	all_boosts.clear()
	toot_response = null
	own_account = null
	print("Reset triggered!")

func _ready():
	start_button_button.hide()
	raffle_word.hide()
	raffle_word_label.hide()

func _on_menu_button_pressed():
	emit_signal("start_button")
	start_button_button.hide()
	_change_to_state(states.GAME_PLAYING)

func _on_main_start():
	start_button_button.show()
	raffle_word.hide()
	_change_to_state(states.WAIT_FOR_START)

func _on_raffle_word_text_submitted(new_text):
	emit_signal("raffle_word_entered", new_text)
	raffle_word_text = new_text
	_change_to_state(states.WAIT_FOR_CONNECTION)

func _on_setting_singleton_no_config():
	start_button_button.hide()
	raffle_word.hide()

func _change_to_state(state):
	match state:
		states.SETTINGS:
			settings.show()
			hide()
		states.INPUT_WORD:
			raffle_word.show()
			if settings.mode == settings.modes.MASTODON:
				_change_to_state(states.MASTODON_AUTORUN)
		states.MASTODON_AUTORUN:
			raffle_word.hide()
			start_button_button.hide()
			_fetch_toot(settings.toot_url)
			
func _on_game_field_connected():
	if settings.auto_timer == true:
		raffle_word_label.text = "Raffle Word: \n" + websocket.trigger_word
	else:
		raffle_word_label.text = "Raffle Word: \n" + raffle_word_text
	raffle_word_label.show()
	$RaffleWordLabel/Bounce.play("Bounce and tit")
	settings.timer.start()

func _on_main_wait_for_raffle():
	_change_to_state(states.INPUT_WORD)

func _fetch_toot(url, context = false, reblogs = false, faved = false):
	var regex = RegEx.new()
	regex.compile("https:\\/\\/(.*)\\/@.*\\/(.*)")
	var result = regex.search(url)
	if !result:
		print("Unable to parse Toot URL!")
		settings.set_error("Unable to parse Toot URL!")
		return
	var server = result.get_string(1)
	var toot_id = result.get_string(2)
	request_server = "https://" + server + "/api/v1/"
	var request_url = request_server + "statuses/" + toot_id
	if context:
		request_url += "/context"
	elif reblogs:
		request_url += "/reblogged_by"
	elif faved:
		request_url += "/favourited_by"
	print(request_url)
	var http_request = HTTPRequest.new()
	add_child(http_request)
	if context:
		http_request.request_completed.connect(self._toot_context_fetched)
	elif reblogs:
		http_request.request_completed.connect(self._toot_reblogs_fetched)
	elif faved:
		http_request.request_completed.connect(self._toot_faves_fetched)
	else:
		http_request.request_completed.connect(self._toot_fetched)
	var err = http_request.request(request_url)
	
func _fetch_followers(id):
	var url = request_server + "accounts/" + id + "/followers"
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._followers_fetched)
	var err = http_request.request(url)

func _followers_fetched(results, response_code, headers, body):
	var json = _json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	for entry in data:
		print("Follower: " + entry["url"])
		all_followers.append(entry["id"])
	_fetch_toot(settings.toot_url, false, true)

func _toot_fetched(results, response_code, headers, body):
	var json = _json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	own_account = data["account"]["id"]
	print("Own Account: " + own_account)
	_fetch_followers(own_account)

func _toot_context_fetched(results, response_code, headers, body):
	var json = _json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	var decendants = data["descendants"]
	for entry in decendants:
		var account = entry["account"]
		print("Reply from: " + account["display_name"])
		print("With Account ID: " + account["id"])
		print("And Avatar URL: " + account["avatar"])
	
func _toot_reblogs_fetched(results, response_code, headers, body):
	var json = _json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	for entry in data:
		print("Reblog from: " + entry["url"])
		all_boosts.append(entry["id"])
	_fetch_toot(settings.toot_url, false, false, true)

func _toot_faves_fetched(results, response_code, headers, body):
	var json = _json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	for entry in data:
		print("Faved by: " + entry["url"])
		all_faves.append(entry["id"])
	_evaluate_participants()

func _fetch_user_details(id):
	var url = request_server + "accounts/" + id
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._user_fetched)
	var err = http_request.request(url)

func _user_fetched(results, response_code, headers, body):
	var json = _json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	print("A valid participant is: " + data["display_name"])
	print("Home at: " + data["url"])
	print("And the Avatar url: " + data["avatar"])
	gameField.spawn_avatar(data["display_name"], "", data["avatar"], data["url"])

func _evaluate_participants():
	var boosts = settings.mastodon_boosted
	var following = settings.mastodon_following
	var faved = settings.mastodon_faved
	print("Following: " + str(following) + " Boosted: " + str(boosts) + " Faved: " + str(faved))
	print("All Faves Size:" + str(all_faves.size()))
	if following and boosts and faved:
		for follower in all_followers:
			if follower in all_boosts and follower in all_faves:
				_fetch_user_details(follower)
	if following and not boosts and faved:
		for follower in all_followers:
			if follower in all_faves:
				_fetch_user_details(follower)
	if following and not boosts and not faved:
		for follower in all_followers:
			_fetch_user_details(follower)
	if following and boosts and not faved:
		for follower in all_boosts:
			_fetch_user_details(follower)
	if not following and boosts and faved:
		for follower in all_boosts:
			if follower in all_faves:
				_fetch_user_details(follower)
	if not following and not boosts and faved:
		for follower in all_faves:
			_fetch_user_details(follower)
	if not following and boosts and not faved:
		for follower in all_boosts:
			_fetch_user_details(follower)
	gameField.count_down.start()
