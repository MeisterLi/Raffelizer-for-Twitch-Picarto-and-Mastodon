extends Node

signal connected
const twitch_client_id = "0g3zp9jikletk9afwneyw75iobuslx"
const client_secret := "3qxwbsjch7yemq9bh8z0wjufncdt0r"
@onready var gamefield : Node2D = get_parent()
@onready var settings : Control = $/root/Main/Settings
@onready var label : Label = $/root/Main/MainUi/RaffleWordLabel
var trigger_word = ""
var websocket_url = "wss://irc-ws.chat.twitch.tv"
var participating_users = []
var twitch = true
var twitch_name
var twitch_token = ""
var picarto_url = ""
var connection_established = false
var animationNames = ["!rFlip", "!rRainbow", "!rMushroom"]
var started = false
var attempting_connection = false

var _client = WebSocketPeer.new()
var _json = JSON.new()
var user_name = ""

func start():
	started = true
	twitch = settings.twitch
	label.show()
	label.text = "Connecting..."
	if twitch:
		print("Twitch active!")
		twitch_name = settings.twitch_name
		connect_websocket()
	else:
		websocket_url = settings.picarto_url
		connect_websocket()
		
func set_trigger_word(word):
	trigger_word = word
	
func _process(_delta):
	if !started:
		return
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if !connection_established:
			_connected()
			connection_established = true
		while _client.get_available_packet_count():
			_on_received_data()
			print("Packet: ", _client.get_packet())
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED && attempting_connection == true:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		print("Connection failed with " + str(code) + " and reason: " + str(reason))
		attempting_connection = false

func connect_websocket():
	#We need to pretend to be a browser for Picarto to be happy
	_client.set_handshake_headers(["user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36 OPR/89.0.4447.64"])	
	print("Connecting to websocket")
	print(websocket_url)
	var err = _client.connect_to_url(websocket_url, true)
	attempting_connection = true
	if err != OK:
		print(err)

func _connected(proto = ""):
	print("Connected with protocol: ", proto)
	if twitch:
		#On Twitch, we join the IRC with an anonymous account
		get_twitch_token()
		print("Connecting to the Twitch IRC and joining the Channel #%s" % twitch_name.to_lower())
		_client.send_text("PASS SCHMOOPIIE")
		_client.send_text("NICK justinfan25730")
		_client.send_text("USER justinfan25730 8 * :justinfan25730")
		_client.send_text("CAP REQ :twitch.tv/commands twitch.tv/tags")
		_client.send_text("JOIN #" + twitch_name.to_lower())
	else:
		emit_signal("connected")

func get_twitch_token():
	# We need an Auth token to be able to download images later
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_twitch_token_completed)
	var twitch_request_url = "https://id.twitch.tv/oauth2/token"
	var body_parts = PackedStringArray([
		"client_id=%s" % twitch_client_id,
		"client_secret=%s" % client_secret,
		"grant_type=client_credentials"
	])
	var url = twitch_request_url + "?" + "&".join(body_parts)
		
	var http_error = http_request.request(url, ['Content-Type: application/x-www-form-urlencoded'], true,  HTTPClient.METHOD_POST)
	if http_error == OK:
		print("Twitch Token request made")

func _http_twitch_token_completed(_results, _response_code, _headers, body):
	_json.parse(body.get_string_from_utf8())
	var data = _json.get_data()
	twitch_token = data["access_token"]
	print(twitch_token)
	print("Twitch Token obtained")
	emit_signal("connected")

func _on_received_data():
	# Well catch our server messages here.
	var packet = _client.get_packet().get_string_from_utf8()
	if !twitch:
		handle_picarto(packet)
	else:
		handle_twitch(packet)
	print(str(packet))

func handle_twitch(packet):
	var regex = RegEx.new()
	regex.compile("user-type= :(.*?)@(.*?)\\..*?:(.*)")
	if "This channel does not exist or has been suspended." in packet:
		print("Unable to find User with that Name!")
		return
	var result = regex.search(packet)
	if result:
		user_name = result.get_string(2)
		if trigger_word.to_lower() in result.get_string(3).to_lower():
			spawn_avatar(user_name)
		else:
			for item in animationNames:
				if item in result.get_string(3):
					print("Found Flip!")
					trigger_animation(item.replace("!r", ""), user_name)
					print("Sent on as " + item.replace("!r", ""))
					break
			
func spawn_avatar(custom_user_name):
	gamefield.spawn_avatar(custom_user_name, twitch_token, picarto_url)

func handle_picarto(packet):
	var _err = _json.parse(packet)
	var message = _json.get_data()
	print(str(message))
	if message.has('m'):
		if typeof(message["m"]) == TYPE_ARRAY:
			check_for_trigger_word(trigger_word, message["m"][0])
			
func check_for_trigger_word(word, directory):
	if word.to_lower() in directory["m"].to_lower():
		picarto_url = "https://images.picarto.tv/" + directory["i"]
		user_name = directory["n"]
		spawn_avatar(user_name)
	else:
		for item in animationNames:
			if item in directory["m"]:
				user_name = directory["n"]
				trigger_animation(item.replace("!r", ""), user_name)
				break

func trigger_animation(item, custom_user_name):
	gamefield.trigger_animation(item, custom_user_name)
	
func _on_ping_pong_timeout():
	_client.send_text("PING")

func reset():
	_client.close(1000, "Restart")
	attempting_connection = false
	trigger_word = ""
	user_name = ""
	participating_users = []
	connection_established = false
	set_process(true)
