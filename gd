extends Control
@onready var http_request = $FirebaseRequest
@onready var timer = $Timer
# Drag and drop your RichTextLabel or Label here in the Inspector
@export var event_label: RichTextLabel 

var firebase_url = "https://game-server-4a36c-default-rtdb.firebaseio.com/inputcommands.json"

# Track the last processed message ID to prevent loops/repeats
var last_message_id: String = ""

func _ready():
	http_request.request_completed.connect(_on_request_completed)
	timer.timeout.connect(check_firebase)
	
	# Start the timer if it isn't set to Autostart
	if timer.is_stopped():
		timer.start()
	
	check_firebase()

func check_firebase():
	http_request.request(firebase_url)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			
			# Ensure data is valid and contains the required keys
			if data and data.has("message") and data.has("admin") and data.has("id"):
				var current_id = str(data["id"])
				
				# ONLY process if this is a brand new message ID
				if current_id != last_message_id:
					last_message_id = current_id # Update the ID tracker
					
					var admin_name = data["admin"]
					var message_text = data["message"]
					
					# Format the string: "mikmik: hello guys"
					var formatted_text = admin_name + ": " + message_text
					
					print("New Message Received: ", formatted_text)
					
					# Update your UI Label
					if event_label:
						# If using RichTextLabel, append_text keeps old history. 
						# Use event_label.text = formatted_text if you only want the latest.
						event_label.append_text(formatted_text + "\n")
