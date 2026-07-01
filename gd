extends Node

# Replace with your Firebase database URL (make sure it ends with /game_events.json)
const FIREBASE_URL = "https://game-server-4a36c-default-rtdb.firebaseio.com/game_events.json"

@onready var http_request: HTTPRequest = $FirebaseHTTPRequest
@onready var timer: Timer = $Timer

func _ready() -> void:
	# Connect the network signals
	http_request.request_completed.connect(_on_request_completed)
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	# Fetch the database contents periodically
	http_request.request(FIREBASE_URL)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.new()
		var error = json.parse(body.get_string_from_utf8())
		
		if error == OK:
			var data = json.get_data()
			if data != null:
				process_game_events(data)
	else:
		print("Failed to reach Firebase, HTTP Code: ", response_code)

func process_game_events(data: Dictionary) -> void:
	# Handle the 'abuse' node data
	if data.has("abuse"):
		var abuse_data = data["abuse"]
		var text = abuse_data.get("text", "")
		var admin = abuse_data.get("admin", "unknown")
		
		# Put your custom game behavior here
		print("Discord Command Received: Text is '", text, "' and Admin is '", admin, "'")
		
	# Handle the 'rain' node data
	if data.has("rain"):
		var rain_data = data["rain"]
		var rain_type = rain_data.get("type", "")
		
		# Put your game engine event logic here
		if rain_type == "Emerald":
			print("Triggering Emerald Rain inside Godot!")
			# spawn_emerald_rain()
