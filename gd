extends Node

var firebase_url = "https://YOUR-PROJECT-ID.firebaseio.com/godot_commands.json"

func _on_Timer_timeout():
    # Ask Firebase for the latest commands every time the timer ticks
    $HTTPRequest.request(firebase_url)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        if json:
            check_commands(json)

func check_commands(data):
    if data.has("starttext"):
        var text_info = data["starttext"]
        print("Admin: ", text_info["admin"], " says: ", text_info["text"])
        # Add your game logic to show the text here!
        
    if data.has("startrain"):
        var rain_info = data["startrain"]
        print("Spawning rain of type: ", rain_info["type"])
        # Add your game logic to spawn the emeralds here!
