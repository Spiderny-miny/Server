extends Control

# Your explicit Firebase Realtime Database URL
const FIREBASE_URL = "https://game-server-4a36c-default-rtdb.firebaseio.com/game_events.json"

@onready var http_request: HTTPRequest = $FirebaseHTTPRequest
@onready var timer: Timer = $Timer
@onready var event_label: Label = $EventLabel

func _ready() -> void:
	# Style the label a bit so it's easy to read on screen
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	event_label.text = "Waiting for Discord data..."
	
	# Connect signals using Godot 4 syntax
	http_request.request_completed.connect(_on_request_completed)
	timer.timeout.connect(_on_timer_timeout)
	
	# Fire the first check immediately instead of waiting 2 seconds
	_on_timer_timeout()

func _on_timer_timeout() -> void:
	# Fetch the database contents tracking our Discord commands
	var error = http_request.request(FIREBASE_URL)
	if error != OK:
		print("An error occurred making the HTTP request.")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# 200 means a successful connection to Firebase
	if response_code == 200:
		var raw_text: String = body.get_string_from_utf8()
		
		# If the database path is completely empty (null)
		if raw_text == "null" or raw_text == "{}":
			event_label.text = "Database Connected: No events sent yet.\nUse /starttext or /startrain in Discord!"
			return
			
		var json = JSON.new()
		var error = json.parse(raw_text)
		
		if error == OK:
			var data = json.get_data()
			if data is Dictionary:
				process_game_events(data)
		else:
			print("JSON Parsing Error: ", json.get_error_message())
	else:
		print("Failed to reach Firebase. HTTP Status Code: ", response_code)
		event_label.text = "Connection Error! Code: " + str(response_code)

func process_game_events(data: Dictionary) -> void:
	var display_text: String = "=== DISCORD LIVE EVENTS ===\n\n"
	
	# 1. Parse the /starttext node
	if data.has("abuse"):
		var abuse_data = data["abuse"]
		if abuse_data is Dictionary:
			var text_content = abuse_data.get("text", "No text provided")
			var admin_name = abuse_data.get("admin", "Unknown Admin")
			
			display_text += "📢 TEXT EVENT:\n"
			display_text += "• Admin Abuse Started By: " + str(admin_name) + "\n"
			display_text += "• Message: \"" + str(text_content) + "\"\n\n"
	
	# 2. Parse the /startrain node
	if data.has("rain"):
		var rain_data = data["rain"]
		if rain_data is Dictionary:
			var rain_type = rain_data.get("type", "Normal")
			var triggered_by = rain_data.get("triggered_by", "Unknown")
			
			display_text += "🌧️ WEATHER EVENT:\n"
			display_text += "• Rain Type: " + str(rain_type) + "\n"
			display_text += "• Summoned By: " + str(triggered_by) + "\n\n"
			
			# Example game mechanic trigger
			if rain_type == "Emerald":
				trigger_emerald_rain_effect()

	# Update the actual visual Label on your screen
	event_label.text = display_text

func trigger_emerald_rain_effect() -> void:
	# This function will run repeatedly as long as 'Emerald' is active in Firebase
	print("Game Logic: Executing Emerald Rain particle/item drop updates!")
