class_name NameEntryScreenManager
extends BaseScreenTemplateManager
## Manages the name entry screen UI.
##
## Prompts the user to enter their name with validation.[br]
## Saves the name and transitions to the home screen on continue.

## Label displaying the screen title.
@onready var title_label: Label = %TitleLabel
## Label prompting the user to enter their name.
@onready var name_prompt_label: Label = %NamePromptLabel
## Text input for the user's name.
@onready var name_input: LineEdit = %NameInput
## Button to submit the name and continue.
@onready var continue_button: Button = %ContinueButton
## Validates name input (letters, spaces, hyphens, apostrophes).
@onready var regex: RegEx = RegEx.new()


## Initializes the name entry screen, connects signals, and validates input.
func _ready() -> void:
	_update_ui_with_new_language()
	_connect_signals()
	
	continue_button.disabled = true
	regex.compile("^[A-Za-z]+(?:[ '-][A-Za-z]+)*$")


## Refreshes the UI labels with the current language.
func _update_ui_with_new_language() -> void:
	title_label.text = tr("NAME_ENTRY_TITLE")
	name_prompt_label.text = tr("NAME_PROMPT_LABEL")
	continue_button.text = tr("CONTINUE_BUTTON")


## Connects the name input and continue button to their handlers.
func _connect_signals() -> void:
	name_input.text_changed.connect(_on_name_input_changed)
	continue_button.pressed.connect(_on_continue_button_pressed)


## Enables or disables the continue button based on regex validation.
func _on_name_input_changed(_new_text: String) -> void:
	if regex.search(_new_text) != null:
		continue_button.disabled = false
	else:
		continue_button.disabled = true


## Saves the name to the SaveData autoload and transitions to the home screen.
func _on_continue_button_pressed() -> void:
	# Save name
	SaveData.save_data_dict["name"] = name_input.text
	SaveData.save_data_to_file()
	
	# Change to home screen
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)
