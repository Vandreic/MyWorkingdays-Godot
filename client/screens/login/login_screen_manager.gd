class_name LoginScreenManager
extends BaseScreenTemplateManager
## Manages the login screen UI and server connection.
##
## Displays server status, handles access code input, and verifies credentials
## with the backend.[br]
## Transitions to the name entry screen on successful authentication.

# BUG:
# If the connect button is spammed rapidly, multiple cooldown timers may be started simultaneously.
# This causes the cooldown to stack, requiring the user to wait multiple cooldown periods before trying again.
# When the cooldown timer reaches 00:00, it may immediately restart if multiple timers are active.

# BUG:
# If connect_button is disabled while server is offline, it will keep disabled when server comes back on.
# Reproduce:
# 1. Disable server (don't run python script)
# 2. Reach API calls limit (spam connect button until you see "API Call Limit Reached!" message)
# 3. Before pressing the "reload_button", enable server (run python script)
# 4. Press "reload_button"
# Now the connect_button is still disabled.

# BUG / FIXME (Important):
# API call limit timer will duplicate when user goes to landing screen and back to login screen.
# Reproduce:
# 1. Reach API calls limit (spam connect button until you see "API Call Limit Reached!" message)
# 2. Go to landing screen (press "change_language_button")
# 3. Go back to login screen
# Now the API call limit timer is duplicated.
# TEMP SOLUTION: Button is disabled during API call limit timer.
# API call limit reached and corresponding timer should be set more globally, so they can be checked upon changing back to login-screen.


## Label displaying the welcome title with the app name.
@onready var title_label: Label = %TitleLabel

## Label displaying the server status title.
@onready var server_status_label: Label = %ServerStatusLabel

## Label displaying additional server status details.
@onready var server_status_description: Label = %ServerStatusDescription

## Indicator showing the server connection status color.
## [br][br]
## Retrieves its color from the [member server_status_colors] dictionary.
@onready var server_status_indicator: TextureRect = %ServerStatusIndicator

## Button to retry server connection.
@onready var reconnect_button: TextureButton = %ReconnectButton

## Label describing the access code input field.
@onready var access_code_label: Label = %AccessCodeLabel

## Text input field for the access code.
@onready var access_code_input: LineEdit = %AccessCodeInput

## Button to submit the access code.
@onready var connect_button: Button = %ConnectButton

## Button to switch to the language selection screen.
@onready var change_language_button: TextureButton = %ChangeLanguageButton

## Label displaying the application version.
@onready var app_version_label: Label = %AppVersionLabel


## Server online status flag.
## [br][br]
## If [code]true[/code], the server is online and accessible.
var server_online: bool = true

## Color mapping for different server statuses.
## [br][br]
## Keys correspond to [enum APIManager.ServerHealthStatus] values.[br]
## The [code]default[/code] key is used for the initial state.[br]
## Each color uses the [code]Color(0xRRGGBBAA)[/code] format (See [method Color.hex] for more details).
var server_status_colors: Dictionary = {
	"default": Color(0x9e9e9eFF),
	"healthy": Color(0x4CAF50FF),
	"no_internet": Color(0xF44336FF),
	"server_unreachable": Color(0xF44336FF),
	"timeout": Color(0xFB8C00FF),
	"error": Color(0xF44336FF)
}

## Initializes the login screen and checks server health.
func _ready() -> void:
	_update_ui_with_new_language()
	_set_app_version()
	_connect_signals()
	
	APIManager.check_server_health()


## Sets the application version label from [code]application/config/version[/code] (Project Settings).
func _set_app_version() -> void:
	app_version_label.text = "v%s" % _get_app_version()


## Connects UI components and API signals to their handlers.
func _connect_signals() -> void:

	# Scene Nodes
	access_code_input.text_changed.connect(_on_access_code_input_text_changed)
	reconnect_button.pressed.connect(_on_reconnect_button_pressed)
	connect_button.pressed.connect(_on_connect_button_pressed)
	change_language_button.pressed.connect(_on_change_language_button_pressed)

	# API Manager
	APIManager.check_server_health_completed.connect(_on_check_server_health_completed)
	APIManager.verify_access_code_completed.connect(_on_verify_access_code_completed)


## Transitions to the language selection screen; passes metadata so we return here on continue.
func _on_change_language_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.LANGUAGE_SELECTION_SCREEN, ScreenManager.Screen.LOGIN_SCREEN)


## Refreshes the UI labels with the current language.
func _update_ui_with_new_language() -> void:
	
# Update UI text elements with the new language
	title_label.text = tr("WELCOME_TO_APP").format({"app_name": tr("APP_NAME")})
	server_status_label.text = tr("SERVER_STATUS_CHECKING")
	access_code_label.text = tr("ACCESS_CODE")
	access_code_input.placeholder_text = tr("ACCESS_CODE_PLACEHOLDER")
	connect_button.text = tr("CONNECT_BUTTON")
	

## Handles text changes in the [member access_code_input] input field.
## [br][br]
## Toggles the [member connect_button] based on input validity.
func _on_access_code_input_text_changed(_new_text: String) -> void:
	var user_input: String = access_code_input.text
	
	if server_online == true:
		if user_input.is_empty() == true or user_input.length() < 3:
			connect_button.disabled = true
		else:
			connect_button.disabled = false


## Applies the server health check result to the UI.
## [br][br]
## Sets the status indicator color, label text, and reconnect button visibility
## based on [param status].
func _on_check_server_health_completed(status: APIManager.ServerHealthStatus, title: String, description: String) -> void:	
	server_status_label.text = title # No translation needed; APIManager outputs the translated version

	# Display description message if any
	if description.is_empty() != true:
		server_status_description.text = description # No translation needed; APIManager outputs the translated version
		server_status_description.visible = true
	else:
		server_status_description.visible = false
	
	# Update server status indicator
	match status:
		APIManager.ServerHealthStatus.HEALTHY:
			server_status_indicator.modulate = server_status_colors["healthy"]
		APIManager.ServerHealthStatus.NO_INTERNET:
			server_status_indicator.modulate = server_status_colors["no_internet"]
		APIManager.ServerHealthStatus.SERVER_UNREACHABLE:
			server_status_indicator.modulate = server_status_colors["server_unreachable"]
		APIManager.ServerHealthStatus.TIMEOUT:
			server_status_indicator.modulate = server_status_colors["timeout"]
		APIManager.ServerHealthStatus.ERROR:
			server_status_indicator.modulate = server_status_colors["error"]
	
	if status == APIManager.ServerHealthStatus.HEALTHY:
		server_online = true
		reconnect_button.visible = false
	else:
		server_online = false
		reconnect_button.visible = true
	
	# Disable reconnect button if API limit is reached
	# Also disabled change_language_button if API limit is reached (temp solution) FIXME
	if title == tr("SERVER_STATUS_API_LIMIT_REACHED"):  # if title == "API Call Limit Reached!" (English)
		reconnect_button.visible = false
		change_language_button.modulate.a8 = 190 # Set opacity to 190 instead of 255
		change_language_button.disabled = true
	else:
		change_language_button.modulate.a8 = 255 # Set opacity back to default (255)
		change_language_button.disabled = false
		change_language_button.visible = true # Restore if hidden by verify cooldown


## Sends the access code to the server for verification.
func _on_connect_button_pressed() -> void:
	connect_button.disabled = true
	var access_code: String = access_code_input.text
	
	APIManager.verify_access_code(access_code)


## Processes the server's access code verification response.
## [br][br]
## Displays the server response in the UI. Transitions to the home screen 
## (managed by [HomeScreenManager]) if [param access_granted] is [code]true[/code].
func _on_verify_access_code_completed(access_granted: bool, title: String, description: String) -> void:
	server_status_description.visible = true

	if access_granted == true:
		server_status_description.text = tr("SERVER_STATUS_ACCESS_GRANTED") # Not needed (Optional)

		# Change to home screen
		ScreenManager.change_screen(ScreenManager.Screen.NAME_ENTRY_SCREEN)
	else:		
		server_status_description.text = description # No translation needed; APIManager outputs the translated version
		connect_button.disabled = false

	# Inform user if API call limit has been reached
	if title == tr("SERVER_STATUS_API_LIMIT_REACHED"):  # if title == "API Call Limit Reached!" (English)
		server_status_indicator.modulate = server_status_colors["error"]
		server_status_label.text = title
		server_status_description.text = description
		connect_button.disabled = true
		change_language_button.modulate.a8 = 190 # Match health-check cooldown styling
		change_language_button.disabled = true
	else:
		change_language_button.disabled = false


## Resets the UI to its initial state and retries the server connection.
func _on_reconnect_button_pressed() -> void:
	server_status_indicator.modulate = server_status_colors["default"]
	server_status_label.text = tr("SERVER_STATUS_CHECKING")
	server_status_description.text = ""
	server_status_description.visible = false
	reconnect_button.visible = false
	
	APIManager.check_server_health()
	
	# Bypass login and skip backend authentication. Remove this line to use real authentication.
	ScreenManager.change_screen(ScreenManager.Screen.NAME_ENTRY_SCREEN)
