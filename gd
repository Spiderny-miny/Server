extends Node

@onready var http_request: HTTPRequest = $HTTPRequest

# Configuration constants matching your GitHub account assets
const GIST_ID = "8802dd903e8053cb51aed85dda77253f"
const GITHUB_TOKEN = "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"

# Dynamic URL path construction
const RAW_GIST_URL = "https://gist.githubusercontent.com/raw/" + GIST_ID + "/commands.json"
const API_URL = "https://api.github.com/gists/" + GIST_ID

const CHECK_INTERVAL = 3.5 # Loop timeframe check (in seconds)
var clearing_mailbox = false

func _ready() -> void:
	# Wire up network signals 
	http_request.request_completed.connect(_on_request_completed)
	
	# Launch our looping checker function
	check_mailbox_loop()

func check_mailbox_loop() -> void:
	while true:
		if not clearing_mailbox:
			# Pull down raw plain text script configuration straight from GitHub
			http_request.request(RAW_GIST_URL)
		await get_tree().create_timer(CHECK_INTERVAL).timeout

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if clearing_mailbox:
		# Mailbox network drop successfully initialized, resume main checking cycle
		clearing_mailbox = false
		return
		
	if response_code == 200:
		var json := JSON.new()
		var parse_result := json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var commands = json.get_data()
			if commands is Array and commands.size() > 0:
				# Instantly drop content on GitHub first to prevent running command multiple times
				clear_github_mailbox()
				
				# Iterate and trigger arrays sequentially
				for command_data in commands:
					execute_admin_command(command_data)

func clear_github_mailbox() -> void:
	clearing_mailbox = true
	var custom_headers := [
		"Authorization: token " + GITHUB_TOKEN,
		"User-Agent: GodotEngine",
		"Content-Type: application/json"
	]
	var payload := {
		"files": {
			"commands.json": {
				"content": "[]"
			}
		}
	}
	http_request.request(API_URL, custom_headers, HTTPClient.METHOD_PATCH, JSON.stringify(payload))

func execute_admin_command(data: Dictionary) -> void:
	var command_type: String = data.get("commandType", "")
	var sender: String = data.get("sender", "Unknown Admin")
	var text_data: String = data.get("text", "")
	
	match command_type:
		"starttext":
			var display_msg := "%s: %s" % [sender, text_data]
			print(display_msg)
			# Add UI logic code here to display the string text on players' viewports
			
		"startrain":
			print("Starting admin command sequence drop! Target material: ", text_data)
			# Add event spawn loop execution code here
