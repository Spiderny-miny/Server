extends Node

var server := TCPServer.new()
var port := 8080

func _ready() -> void:
	# Spin up our custom engine server port
	if server.listen(port) == OK:
		print("Godot Admin Server started successfully on port: ", port)
	else:
		print("Failed to start Godot Admin Server. Check if port is occupied.")

func _process(_delta: float) -> void:
	# Continuously monitor if BDFD is trying to connect
	if server.is_connection_available():
		var peer: StreamPeerTCP = server.take_connection()
		handle_discord_request(peer)

func handle_discord_request(peer: StreamPeerTCP) -> void:
	# Brief buffer latency delay for network packet assembly
	OS.delay_msec(60) 
	var available_bytes := peer.get_available_bytes()
	
	if available_bytes > 0:
		var request_string := peer.get_string(available_bytes)
		
		# Locate structural JSON bracket points from the raw HTTP stream
		var json_start := request_string.find("{")
		var json_end := request_string.rfind("}")
		
		if json_start != -1 and json_end != -1:
			var json_body := request_string.substr(json_start, (json_end - json_start) + 1)
			
			var json := JSON.new()
			var parse_result := json.parse(json_body)
			
			if parse_result == OK:
				var data: Dictionary = json.get_data()
				execute_admin_command(data)
				
				# Respond back with HTTP 200 OK status to keep BDFD happy
				var response := "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\"}"
				peer.put_data(response.to_utf8_buffer())
				
	peer.disconnect_from_host()

func execute_admin_command(data: Dictionary) -> void:
	var command_type: String = data.get("commandType", "")
	var sender: String = data.get("sender", "Unknown Admin")
	var text_data: String = data.get("text", "")
	
	match command_type:
		"starttext":
			var final_output := "%s: %s" % [sender, text_data]
			print(final_output) 
			# UI implementation note: hook up your game HUD layout nodes here 
			# to flash final_output to the players!
			
		"startrain":
			print("Admin command received! Spawning sky drop sequence: ", text_data)
			# Event loop note: run your item generation node loop instances here!
