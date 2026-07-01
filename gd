extends Control

@onready var http_request = $HTTPRequest
@onready var timer = $Timer

var firebase_url = "https://game-server-4a36c-default-rtdb.firebaseio.com/inputcommands.json"
var last_processed_id = ""

func _ready():
	# Configure the timer to check Firebase every 1.5 seconds
	timer.wait_time = 1.5
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	# Connect the HTTP request completion signal
	http_request.request_completed.connect(_on_request_completed)

func _on_timer_timeout():
	http_request.request(firebase_url)

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		return # Server error or empty database
		
	var json_data = JSON.parse_string(body.get_string_from_utf8())
	
	# Ensure data exists and has a valid unique ID
	if json_data and json_data.has("id"):
		var command_id = json_data["id"]
		
		# Only process if this is a brand new command ID
		if command_id != last_processed_id:
			last_processed_id = command_id
			handle_incoming_command(json_data)

func handle_incoming_command(data: Dictionary):
	var username = data["username"]
	var content = data["content"]
	var command_type = data["type"]
	
	# Handle Text Command
	if command_type == "text":
		# Formats exactly as: (discordusername): text: hello guys from discord
		var formatted_output = "(" + username + "): " + content
		print(formatted_output) 
		# TODO: Pass 'formatted_output' to your in-game UI Chat/Label node
		
	# Handle Rain Command
	elif command_type == "rain":
		print("(" + username + ") triggered rain type: " + content)
		# TODO: Call your rain spawning function here, e.g., spawn_rain(content)
