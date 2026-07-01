extends Control

@onready var http_request = $FirebaseRequest
@onready var timer = $Timer

# The exact same URL used in BDFD!
var firebase_url = "https://game-server-4a36c-default-rtdb.firebaseio.com/admin_event.json"

func _ready():
    # Connect the HTTP node and Timer to our code
    http_request.request_completed.connect(_on_request_completed)
    timer.timeout.connect(check_firebase)
    
    # Do an initial check when the game starts
    check_firebase()

func check_firebase():
    # Ask Firebase for the latest data
    http_request.request(firebase_url)

func _on_request_completed(result, response_code, headers, body):
    if response_code == 200:
        var json = JSON.new()
        var parse_result = json.parse(body.get_string_from_utf8())
        
        if parse_result == OK:
            var data = json.data
            # Check if data exists (it might be null if Firebase is empty)
            if data and data.has("message"):
                print("Admin Abuse started from: ", data["admin"])
                print("Message: ", data["message"])
                
                # TODO: Link this to your RichTextLabel or UI in Godot to show the players!
