extends Node

@onready var label: Label = $Label
@onready var http_request: HTTPRequest = $HTTPRequest

# Your direct Firebase endpoint link
const FIREBASE_URL = "https://game-server-4a36c-default-rtdb.firebaseio.com/mailbox.json"

const CHECK_INTERVAL = 2.5 # Check database every 2.5 seconds
var clearing_mailbox = false

# Preload your rain drop scenes here (adjust the paths to match your project files)
var emerald_scene = preload("res://Emerald.tscn") 

func _ready() -> void:
	# Connect the network request handler
	http_request.request_completed.connect(_on_request_completed)
	# Start monitoring the mailbox
	check_mailbox_loop()

func check_mailbox_loop() -> void:
	while true:
		if not clearing_mailbox:
			# Look into our Firebase URL
			http_request.request(FIREBASE_URL)
		await get_tree().create_timer(CHECK_INTERVAL).timeout

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if clearing_mailbox:
		# Mailbox successfully cleared on the web, resume scanning
		clearing_mailbox = false
		return
		
	if response_code == 200:
		var response_string = body.get_string_from_utf8()
		
		# If database returns "null" or empty, it means there is no new command
		if response_string == "null" or response_string.strip_edges() == "":
			return
			
		var json := JSON.new()
		var parse_result := json.parse(response_string)
		
		if parse_result == OK:
			var data = json.get_data()
			if data is Dictionary:
				# Clear Firebase immediately so this command runs only ONCE
				clear_mailbox()
				# Execute the logic inside Godot
				execute_admin_command(data)

func clear_mailbox() -> void:
	clearing_mailbox = true
	# Sending a DELETE request to Firebase instantly wipes the mailbox clean
	http_request.request(FIREBASE_URL, PackedStringArray(), HTTPClient.METHOD_DELETE)

func execute_admin_command(data: Dictionary) -> void:
	var command_type: String = data.get("commandType", "")
	var sender: String = data.get("sender", "Unknown Admin")
	var text_data: String = data.get("text", "")
	
	match command_type:
		"starttext":
			# Update your UI node property safely
			label.text = "%s: %s" % [sender, text_data]
			
			# Optional: Make the text automatically clear out after 6 seconds
			await get_tree().create_timer(6.0).timeout
			if label.text == "%s: %s" % [sender, text_data]:
				label.text = ""
			
		"startrain":
			print("Admin triggered an item event drop: ", text_data)
			spawn_item_rain(text_data)

func spawn_item_rain(item_type: String) -> void:
	# 1. CRITICAL SAFETY CHECK: Verify if the scene asset is null before proceeding
	if emerald_scene == null:
		print("Error: Cannot start rain event. The emerald_scene instance is null!")
		return # Instantly stops the function so the game doesn't crash
		
	# 2. Proceed only if the typed command matches "emerald"
	if item_type.to_lower() == "emerald":
		print("Spawning 10 emerald items...")
		for i in range(10):
			var item = emerald_scene.instantiate()
			get_tree().current_scene.add_child(item)
			
			# Define random spawn coordinates over your map area
			var random_x = randf_range(-10.0, 10.0)
			var random_y = randf_range(15.0, 20.0) # Sky altitude
			
			if item is Node3D:
				item.global_position = Vector3(random_x, random_y, randf_range(-10.0, 10.0))
			elif item is Node2D:
				item.global_position = Vector2(random_x * 50, random_y * 10)
				
			# Small pause between drops for a realistic "raining" appearance
			await get_tree().create_timer(0.1).timeout
	else:
		print("Unknown item type received: ", item_type)
