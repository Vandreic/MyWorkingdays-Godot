class_name LanguageSelectionScreenManager
extends BaseScreenTemplateManager
## Manages the language selection screen UI.
##
## Lets the user choose English or Danish.[br]
## Saves the choice and transitions to the appropriate screen on continue: home
## if accessed from home, login if accessed from login or on first app startup.

## Label displaying the screen title.
@onready var title_label: Label = %TitleLabel
## Button to select English.
@onready var en_language_button: Button = %ENLanguageButton
## Button to select Danish.
@onready var da_language_button: Button = %DALanguageButton
## Container holding the language buttons and indicators.
@onready var languages_container: GridContainer = %LanguagesContainer
## Indicator for the selected English language.
@onready var en_selected_language_indicator: TextureRect = %ENSelectedLanguageIndicator
## Indicator for the selected Danish language.
@onready var da_selected_language_indicator: TextureRect = %DASelectedLanguageIndicator
## Button to confirm language choice and continue.
@onready var continue_button: Button = %ContinueButton
## Label displaying the application version.
@onready var app_version_label: Label = %AppVersionLabel


## Screen to return to when Continue is pressed; -1 means use default (login).
var _return_screen: int = -1

## Color mapping for selected and unselected language indicators.
var selected_language_indicator: Dictionary = {
	"selected": Color(),
	"not_selected": Color(0x00000000) # Transparent color / Invisible,
}


## Called by [ScreenManager] when navigating to this screen with metadata.
## [param metadata] is the [enum ScreenManager.Screen] to return to on continue;
## defaults to [constant ScreenManager.Screen.LOGIN_SCREEN] if null or invalid.
func set_edit_data(metadata: Variant) -> void:
	if metadata != null and metadata is int:
		_return_screen = metadata
	else:
		_return_screen = -1


## Initializes the language selection screen and sets up the UI.
func _ready() -> void:
	_update_ui_with_new_language()
	_connect_signals()
	_set_app_version()
	
	_setup_selected_language_indicator()
	_update_language_indicators()
	
	# If user has not chosen a language, set language to "en" instead of "en_US"
	if TranslationServer.get_locale() == "en_US":
		_on_en_language_button_pressed()
	

## Configures the selected and unselected colors for language indicators.
func _setup_selected_language_indicator() -> void:
	# Get primary theme color from UI_FilledButton theme variation
	var _primary_color: Color = en_language_button.get_theme_stylebox("normal").bg_color

	# Set primary color to "selected state"
	selected_language_indicator["selected"] = _primary_color

	# Set default colors to indicators (English is default)
	en_selected_language_indicator.modulate = selected_language_indicator["selected"]
	da_selected_language_indicator.modulate = selected_language_indicator["not_selected"]
	
	
	if SaveData.save_data_dict["language"] == "en_US": # No language chosen yet (First app startup)
		en_selected_language_indicator.modulate = selected_language_indicator["selected"]
		da_selected_language_indicator.modulate = selected_language_indicator["not_selected"]
	

## Sets the application version label from [code]application/config/version[/code] (Project Settings).
func _set_app_version() -> void:
	app_version_label.text = "v%s" % _get_app_version()


## Connects the language buttons and continue button to their handlers.
func _connect_signals() -> void:
	en_language_button.pressed.connect(_on_en_language_button_pressed)
	da_language_button.pressed.connect(_on_da_language_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)


## Sets the locale to English and refreshes the UI.
func _on_en_language_button_pressed() -> void:
	TranslationServer.set_locale("en")

	_update_language_indicators()
	_update_ui_with_new_language()


## Sets the locale to Danish and refreshes the UI.
func _on_da_language_button_pressed() -> void:
	TranslationServer.set_locale("da")

	_update_language_indicators()
	_update_ui_with_new_language()


## Updates the language indicator visibility based on the current locale.
func _update_language_indicators():
	var current_locale = TranslationServer.get_locale().to_lower() # "en" or "da"

	for node in languages_container.get_children():
		# We only target the TextureRects at the bottom of your tree
		if node is TextureRect and "SelectedLanguageIndicator" in node.name:
			
			# Extract the first two letters of the node name and make them lowercase
			# This turns "ENSelectedLanguageIndicator" into "en"
			var node_prefix = node.name.left(2).to_lower()
			
			if node_prefix == current_locale:
				node.modulate = selected_language_indicator["selected"]
			else:
				node.modulate = selected_language_indicator["not_selected"]
			

## Refreshes the UI labels with the current language.
func _update_ui_with_new_language() -> void:
	title_label.text = tr("CHOOSE_LANGUAGE")
	en_language_button.get_node("ENButtonContainer/ENLanguageLabel").text = tr("LANGUAGE_ENGLISH")
	da_language_button.get_node("DAButtonContainer/DALanguageLabel").text = tr("LANGUAGE_DANISH")
	continue_button.text = tr("CONTINUE_BUTTON")


## Saves the chosen language to the SaveData autoload and transitions to the appropriate screen.
##
## Returns to the screen from which language selection was opened (home or login);
## defaults to login on first app startup.
func _on_continue_button_pressed() -> void:
	# Save chosen language
	SaveData.save_data_dict["language"] = TranslationServer.get_locale()
	SaveData.save_data_to_file()

	if _return_screen >= 0:
		ScreenManager.change_screen(_return_screen)
	else:
		ScreenManager.change_screen(ScreenManager.Screen.LOGIN_SCREEN)
