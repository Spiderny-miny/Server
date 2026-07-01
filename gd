extends Node

@onready var label: Label = $Label
@onready var http_request: HTTPRequest = $HTTPRequest

# Firebase endpoints
const FIREBASE_URL = "https://game-server-4a36c-default-rtdb.firebaseio.com/mailbox.json"
const STATUS_URL = "https://game-server-4a36c-default-rtdb.firebaseio.com/status.json"

const CHECK_INTERVAL = 2.0 
var clearing_mailbox = false

# Preload your falling object asset (Ensure this path is correct in your file system)
var emerald_scene = preload("res://Emerald.tscn") 

func _ready() -> void:
	# Connect our network signal handler
	http_request.request_completed.connect(_on_request_completed)
	# Start checking the mailbox
	check_mailbox_loop()

func check_mailbox_loop() -> void:
	while true:
		if not clearing_mailbox:
			# Check Firebase for incoming commands
			http_request.request(FIREBASE_URL)
		await get_tree().create_timer(CHECK_INTERVAL).timeout

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if clearing_mailbox:
		clearing_mailbox = false
		return
		
	if response_code == 200:
		var response_string = body.get_string_from_utf8()
		
		# Skip tracking if the mailbox database layout returns empty or null
		if response_string == "null" or response_string.strip_edges() == "":
			return
			
		var json := JSON.new()
		var parse_result := json.parse(response_string)
		
		if parse_result == OK:
			var data = json.get_data()
			if data is Dictionary:
				# Instantly wipe mailbox so command does not repeat
				clear_mailbox()
				# Execute game logic
				execute_admin_command(data)

func clear_mailbox() -> void:
	clearing_mailbox = true
	http_request.request(FIREBASE_URL, PackedStringArray(), HTTPClient.METHOD_DELETE)

func execute_admin_command(data: Dictionary) -> void:
	var command_type: String = data.get("commandType", "")
	var sender: String = data.get("sender", "Unknown Admin")
	var text_data: String = data.get("text", "")
	
	# Send confirmation receipt back to Firebase so BDFD can view the approval
	send_receipt_to_firebase()
	
	match command_type:
		"starttext":
			# Safely display string text on players' screen layout
			label.text = "%s: %s" % [sender, text_data]
			
			# Optional text cleanup layout loop timer
			await get_tree().create_timer(6.0).timeout
			if label.text == "%s: %s" % [sender, text_data]:
				label.text = ""
			
		"startrain":
			print("Starting item drop event for material: ", text_data)
			spawn_item_rain(text_data)

func send_receipt_to_firebase() -> void:
	var headers = ["Content-Type: application/json"]
	http_request.request(STATUS_URL, headers, HTTPClient.METHOD_PUT, JSON.stringify("SUCCESS"))
	
	# Leave status up for 5 seconds for the bot to fetch, then delete it automatically
	await get_tree().create_timer(5.0).timeout
	http_request.request(STATUS_URL, PackedStringArray(), HTTPClient.METHOD_DELETE)

func spawn_item_rain(item_type: String) -> void:
	# CRITICAL SAFETY CHECK: Prevent crashes if scene file configuration is null
	if emerald_scene == null:
		print("Error: Cannot start rain event. The emerald_scene instance is null!")
		return 
		
	if item_type.to_lower() == "emerald":
		for i in range(10):
			var item = emerald_scene.instantiate()
			get_tree().current_scene.add_child(item)
			
			var random_x = randf_range(-10.0, 10.0)
			var random_y = randf_range(15.0, 20.0) # Elevated height location
			
			if item is Node3D:
				item.global_position = Vector3(random_x, random_y, randf_range(-10.0, 10.0))
			elif item is Node2D:
				item.global_position = Vector2(random_x * 50, random_y * 10)
				
			await get_tree().create_timer(0.1).timeout
