extends Node
## Communicates with the backend server through HTTP requests.
##
## Performs server health checks and verifies access codes. Emits
## [signal check_server_health_completed] and [signal verify_access_code_completed]
## to report request results.
## [br][br]
## The server URL combines host (from constants below), [constant PORT], and [constant API_PREFIX].
## Configure endpoints in the [member endpoints] dictionary.
## [br][br]
## [b]Server Connection:[/b][br]
## - [b]IDE:[/b] Uses localhost (client and server on same PC). [br]
## - [b]Exported (e.g. phone):[/b] Uses your PC's IP so the app can reach the server. [br]
## - - [b]Get PC IP:[/b] Windows CMD → [code]ipconfig[/code] → IPv4 under WiFi/Ethernet. [br]
## -[constant PORT] must match [code]server/.env[/code]. Server must use [code]HOST=0.0.0.0[/code] for phone testing.
## [br][br]
## [b]Autoload:[/b] Access this singleton globally via [code]APIManager[/code].


## Represents the server's health status after a connection attempt.
enum ServerHealthStatus {
	## The server responded and operates normally.
	HEALTHY,
	## The client cannot resolve the host (no internet connection).
	NO_INTERNET,
	## The client cannot connect to the server.
	SERVER_UNREACHABLE,
	## The request exceeded the timeout duration.
	TIMEOUT,
	## An unexpected error occurred.
	ERROR,
}

## Emitted when [method check_server_health] finishes.
##
## [param status] contains the [enum ServerHealthStatus] result.
## [param title] provides a short status message.
## [param description] provides additional details about the status.
signal check_server_health_completed(status: ServerHealthStatus, title: String, description: String)

## Emitted when [method verify_access_code] finishes.
##
## If [param access_granted] is [code]true[/code], the access code is valid.
## [param message] contains the server's response message.
## [param response_data] contains the full parsed JSON response.
signal verify_access_code_completed(access_granted: bool, title: String, description: String)


## Host when running from Godot IDE (client and server on same PC).
const HOST_EDITOR: String = "http://localhost"
## Host when running exported app (e.g. on phone). Replace with your PC's IP.
## To get PC IP: Windows: run [code]ipconfig[/code], look for IPv4 under your WiFi/Ethernet.
const HOST_EXPORTED: String = "http://10.0.0.7"

## The server's port number.
const PORT: int = 8000

## The API version path prefix.
const API_PREFIX: String = "/api/v1"

## The timeout duration for HTTP requests in seconds.
const HTTP_REQUEST_TIMEOUT_DURATION: int = 5

## The cooldown duration when API call limit is reached, in seconds.
const API_CALL_COOLDOWN_DURATION: int = 30

## Active host based on run context. Uses [constant HOST_EDITOR] in IDE, [constant HOST_EXPORTED] when exported.
var host: String:
	get:
		return HOST_EDITOR if OS.has_feature("editor") else HOST_EXPORTED

## Complete base URL for all API requests.
## Uses [constant HOST_EDITOR] in IDE, [constant HOST_EXPORTED] when exported.
var url: String:
	get:
		return "%s:%s%s" % [host, PORT, API_PREFIX]

## Maps endpoint names to their URL paths.
## [br][br]
## Contains the following endpoints:[br]
## - [code]"health"[/code]: Server health check endpoint.[br]
## - [code]"verify"[/code]: Access code verification endpoint.
var endpoints: Dictionary = {
	"health": "/system/health",
	"verify": "/auth/verify",
}

## Tracks API call counts and limits for each endpoint.
var api_call_limits: Dictionary = {
	"health_check": {"count": 0, "limit": 5},
	"verify_access_code": {"count": 0, "limit": 5},
}


## Sends a health check request to the server If [param skip_cooldown_check] 
## is [code]true[/code], skips restore check (used when cooldown has just ended). [br][br]
##
## Creates an [HTTPRequest] node, sends a GET request to the health endpoint,
## and emits [signal check_server_health_completed] with the result. Times out
## after [constant HTTP_REQUEST_TIMEOUT_DURATION].
func check_server_health() -> void:
	if _restore_cooldown_if_needed() == true:
		return
	
	# Check if API call limit is reached for this endpoint
	if api_call_limits["health_check"]["count"] >= api_call_limits["health_check"]["limit"]:
		_create_cooldown_timer("health")
		return
	else:
		var request_headers: Array = ["Content-Type: application/json"]
		_make_api_request("health", request_headers, Callable(self, "_on_check_server_health_completed"))
		# Increment the API call count for health_check
		api_call_limits["health_check"]["count"] += 1
	

## Verifies an access code with the server.
##
## Sends [param access_code] to the verification endpoint and emits
## [signal verify_access_code_completed] with the result. Times out
## after [constant HTTP_REQUEST_TIMEOUT_DURATION].
func verify_access_code(access_code: String) -> void:
	if _restore_cooldown_if_needed() == true:
		return
	
	if api_call_limits["verify_access_code"]["count"] >= api_call_limits["verify_access_code"]["limit"]:
		_create_cooldown_timer("verify")
		return
	else:
		var request_headers: Array = [
			"Content-Type: application/json",
			"Access-Key: %s" % access_code,
		]
		_make_api_request("verify", request_headers, Callable(self, "_on_verify_access_code_completed"))
		# Increment the API call count for verify_access_code
		api_call_limits["verify_access_code"]["count"] += 1


## Restores an active cooldown from save data if still in effect. [br][br]
##
## Returns [code]true[/code] if a cooldown was restored or is still active.
func _restore_cooldown_if_needed() -> bool:
	if has_node("APICallCooldownTimer") == true:
		return true
	
	var endpoint: String = SaveData.save_data_dict["api_cooldown_endpoint"]
	var cooldown_until: float = SaveData.save_data_dict["api_cooldown_until"]
	var now: float = Time.get_unix_time_from_system()
	
	if cooldown_until <= now or endpoint.is_empty() == true:
		return false
	
	var remaining: float = cooldown_until - now
	_create_cooldown_timer(endpoint, remaining)
	return true


## Create a timer to manage API call cooldowns when limits are reached.
##
## [param endpoint] determines which endpoint cooldown to manage.
## [param remaining_seconds] if positive, uses this instead of [constant API_CALL_COOLDOWN_DURATION] (for restored cooldowns).
func _create_cooldown_timer(endpoint: String, remaining_seconds: float = -1.0) -> void:
	var duration: float = float(API_CALL_COOLDOWN_DURATION) if remaining_seconds < 0 else remaining_seconds
	var cooldown_until: float = Time.get_unix_time_from_system() + duration
	SaveData.save_data_dict["api_cooldown_until"] = cooldown_until
	SaveData.save_data_dict["api_cooldown_endpoint"] = endpoint
	SaveData.save_data_to_file()

	# Create main cooldown timer
	var cooldown_timer: Timer = Timer.new()
	cooldown_timer.name = "APICallCooldownTimer"
	cooldown_timer.wait_time = duration
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	cooldown_timer.start()

	# Create timer for ticking every second
	var tick_timer: Timer = Timer.new()
	tick_timer.name = "CooldownTickTimer"
	tick_timer.wait_time = 1.0
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_cooldown_tick.bind(endpoint, cooldown_timer, tick_timer))
	add_child(tick_timer)
	tick_timer.start()


## Processes each tick of the cooldown timer.
##
## Emits status signals with the remaining time. Resets the API call count
## and triggers a health check when the cooldown ends.
func _on_cooldown_tick(endpoint: String, cooldown_timer: Timer, tick_timer: Timer) -> void:

	# Format remaining time to MM:SS
	var time_left: int = int(round(cooldown_timer.time_left))
	var minutes: int = time_left / 60
	var seconds: int = time_left % 60
	var time_string: String = "%02d:%02d" % [minutes, seconds]

	match endpoint:
				"health":
					check_server_health_completed.emit(
						ServerHealthStatus.ERROR,
						tr("SERVER_STATUS_API_LIMIT_REACHED"), # API Call Limit Reached!
						tr("SERVER_INFO_API_LIMIT_REACHED").format({"time": time_string}) # You have reached the maximum number of allowed API calls. \n\n Try again in {time}.

					)
				"verify":
					verify_access_code_completed.emit(
						false,
						tr("SERVER_STATUS_API_LIMIT_REACHED"), # API Call Limit Reached!
						tr("SERVER_INFO_API_LIMIT_REACHED").format({"time": time_string}) # You have reached the maximum number of allowed API calls. \n\n Try again in {time}.
					)
				#_:
					#push_warning("[API MANAGER] Invalid endpoint: %s" % endpoint)
					#return

	# Check if cooldown has ended
	if cooldown_timer.time_left <= 0:
		# Remove from tree first so has_node returns false before we call check_server_health
		tick_timer.stop()
		remove_child(tick_timer)
		tick_timer.queue_free()
		cooldown_timer.stop()
		remove_child(cooldown_timer)
		cooldown_timer.queue_free()

		# Clear persisted cooldown
		SaveData.save_data_dict["api_cooldown_until"] = 0.0
		SaveData.save_data_dict["api_cooldown_endpoint"] = ""
		SaveData.save_data_to_file()

		# Reset API call count for the endpoint and re-check server health
		match endpoint:
			"health":
				api_call_limits["health_check"]["count"] = 0
			"verify":
				api_call_limits["verify_access_code"]["count"] = 0
		
		check_server_health()


## Sends an API request to the specified endpoint.
##
## Creates an [HTTPRequest] node and connects it to [param callback].
## Frees the node and emits an error signal if the request fails.
func _make_api_request(endpoint: String, headers: Array, callback: Callable, method: int = HTTPClient.METHOD_GET, body: String = "") -> void:
	
	# Create and configure HTTPRequest node
	var http_request: HTTPRequest = HTTPRequest.new()
	http_request.timeout = HTTP_REQUEST_TIMEOUT_DURATION
	http_request.name = "APIRequest_%s" % endpoint
	add_child(http_request)
	http_request.request_completed.connect(callback.bind(http_request))
	
	# Construct full URL and send request
	var request_url: String = url + endpoints[endpoint]
	var error: Error = http_request.request(request_url, headers, method, body)	

	# Handle request error
	if error != OK:
		http_request.queue_free()

		# Get the signal name from the callback
		var signal_name = str(callback).split("_on_", false, 1)[1] # e.g., "check_server_health_completed"

		# Emit appropriate signal based on endpoint
		match endpoint:
			"health":
				# An error occurred. \n Could not connect to the server.
				emit_signal(signal_name, ServerHealthStatus.ERROR, tr("SERVER_STATUS_ERROR"), tr("SERVER_INFO_ERROR_SEND_HEALTH_CHECK"))
			"verify":
				# An error occurred. \n Could not send access code to server.
				emit_signal(signal_name, false, tr("SERVER_STATUS_ERROR"), tr("SERVER_INFO_ERROR_SEND_ACCESS_CODE"))
			_:
					push_warning("[API MANAGER] Invalid endpoint: %s" % endpoint)
					return


## Processes the server health check response.
##
## Parses the HTTP result and emits [signal check_server_health_completed]
## with the appropriate [enum ServerHealthStatus].
func _on_check_server_health_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	http_request.queue_free()
		
	## Check for connection/DNS errors
	if result == HTTPRequest.RESULT_CANT_RESOLVE: # Request failed while resolving
		check_server_health_completed.emit(
			ServerHealthStatus.NO_INTERNET, 
			tr("SERVER_STATUS_NO_INTERNET"), # "No internet connection!"
			tr("SERVER_INFO_NO_INTERNET") # "Please connect to the internet and try again."
		)
		return
	## Check for Connection Errors
	elif result == HTTPRequest.RESULT_CANT_CONNECT: # Request failed while connecting
		check_server_health_completed.emit(
			ServerHealthStatus.SERVER_UNREACHABLE,
			tr("SERVER_STATUS_OFFLINE"), # "Server Status: Offline.",
			tr("SERVER_INFO_OFFLINE") # "Server is temporarily offline. Please try again later.
		)
		return
	## Check for Timeout specifically
	elif result == HTTPRequest.RESULT_TIMEOUT: # Request failed due to a timeout
		check_server_health_completed.emit(
			ServerHealthStatus.TIMEOUT,
			tr("SERVER_STATUS_CONNECTION_TIMEOUT"), # "Connection timed out."
			tr("SERVER_INFO_CHECK_CONNECTION") # 
		)
		return

	# Check the Server Response Code
	if response_code == 200:
		var server_response: Variant = JSON.parse_string(body.get_string_from_utf8())
		if server_response["status"] == "ok": # Check status (optional)
			check_server_health_completed.emit(
				ServerHealthStatus.HEALTHY,
				tr("SERVER_STATUS_ONLINE"), # "Server Status: Online"
				"" # No additional info
			)
			return
	else:
		check_server_health_completed.emit(
			ServerHealthStatus.ERROR,
			tr("SERVER_STATUS_ERROR"), # "An error occurred."
			tr("SERVER_INFO_ERROR").format({"response_code": response_code}) # "Server responded with code: {response_code}"
		)
		return


## Processes the access code verification response.
##
## Parses the HTTP result and emits [signal verify_access_code_completed]
## with the verification status and server message.
func _on_verify_access_code_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	http_request.queue_free()

	# Check for connection/DNS errors
	if result == HTTPRequest.RESULT_CANT_RESOLVE: # Request failed while resolving
		check_server_health_completed.emit(
			ServerHealthStatus.NO_INTERNET, 
			tr("SERVER_STATUS_NO_INTERNET"), # "No internet connection!"
			tr("SERVER_INFO_NO_INTERNET") # "Please connect to the internet and try again."
		)
		return
	# Check for Connection Errors
	elif result == HTTPRequest.RESULT_CANT_CONNECT: # Request failed while connecting
		check_server_health_completed.emit(
			ServerHealthStatus.SERVER_UNREACHABLE,
			tr("SERVER_STATUS_OFFLINE"), # "Server Status: Offline.",
			tr("SERVER_INFO_OFFLINE") # "Server is temporarily offline. Please try again later."
		)
		return
	# Check for Timeout specifically
	elif result == HTTPRequest.RESULT_TIMEOUT: # Request failed due to a timeout
		check_server_health_completed.emit(
			ServerHealthStatus.TIMEOUT,
			tr("SERVER_STATUS_TIMEOUT"), # "Connection timed out.",
			tr("SERVER_INFO_TIMEOUT") # "Please check your connection or try again."
		)
		return

	# Check the Server Response Code
	var server_response: Variant = JSON.parse_string(body.get_string_from_utf8())

	if response_code == 200: # { "status": "ok", "role": "user" }
		# Check status (optional)
		if server_response["status"] == "ok":
			verify_access_code_completed.emit(true, "", tr("SERVER_STATUS_ACCESS_GRANTED")) # "Access Granted! (No additional info; we leave title as is)"
			return
		
	# Access Denied
	elif response_code == 403: # { "detail": "Invalid API key. Access denied." }
		verify_access_code_completed.emit(false, tr("SERVER_STATUS_ACCESS_DENIED"), tr("SERVER_INFO_INVALID_API_KEY"))
		return
