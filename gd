extends  Control

@onready var http_request = $FirebaseRequest
@onready var timer = $Timer

# Drag and drop your standard Label and AnimationPlayer from the Scene tree into these slots in the Inspector
@export var event_label: Label
@export var animation_player: AnimationPlayer

# Change this to the exact name of the animation you created in your AnimationPlayer
@export var animation_name: String = "fade_in"

var firebase_url = "https://game-server-4a36c-default-rtdb.firebaseio.com/inputcommands.json"

# Tracks the last processed message ID to prevent repetition loops
var last_message_id: String = ""

func _ready():
	http_request.request_completed.connect(_on_request_completed)
	timer.timeout.connect(check_firebase)
	
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
			
			if data and data.has("message") and data.has("admin") and data.has("id"):
				var current_id = str(data["id"])
				
				# Loop guard: Only run if it's a completely new message
				if current_id != last_message_id:
					last_message_id = current_id 
					
					var admin_name = data["admin"]
					var message_text = data["message"]
					
					# Formats exactly as requested: "mikmik: hello guys"
					var formatted_text = admin_name + ": " + message_text
					
					print("New Event: ", formatted_text)
					
					# Update standard Label text
					if event_label:
						event_label.text = formatted_text
					
					# Play the alert animation safely
					if animation_player and animation_player.has_animation(animation_name):
						# Stop the animation if it was already running, then play it fresh
						animation_player.stop()
						animation_player.play(animation_name)
