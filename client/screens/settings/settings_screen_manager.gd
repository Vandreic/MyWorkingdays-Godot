class_name SettingsScreenManager
extends BaseScreenTemplateManager
## Manages the settings screen for language, theme, and other preferences.
##
## Displays a list of settings entries. Language opens the language selection screen
## and returns here on continue. Receives the return screen via [method set_edit_data] when
## opened from Home, Wages, or Salary.

## Screen to return to when Go back is pressed; defaults to HOME_SCREEN.
var _return_screen: int = ScreenManager.Screen.HOME_SCREEN

## Label showing the screen title.
@onready var title_label: Label = %TitleLabel
## Button to go back to the screen the user came from.
@onready var go_back_button: Button = %GoBackButton
## Button to open the language selection screen.
@onready var language_button: Button = %LanguageButton
## Label for the theme row.
@onready var theme_label: Label = %ThemeLabel
## OptionButton for theme selection (light/dark).
@onready var theme_option_button: OptionButton = %ThemeOptionButton
## Button to navigate to the home screen.
@onready var home_button: Button = %HomeButton
## Button to open the wages screen.
@onready var wages_button: Button = %WagesButton
## Button to open the salary screen.
@onready var salary_button: Button = %SalaryButton


## Called by [ScreenManager] when navigating to this screen with metadata.
## [param metadata] is the [enum ScreenManager.Screen] to return to when Go back is pressed.
func set_edit_data(metadata: Variant) -> void:
	if metadata != null and metadata is int:
		_return_screen = metadata
	else:
		_return_screen = ScreenManager.Screen.HOME_SCREEN


func _ready() -> void:
	super._ready()
	var settings_btn = get_node_or_null("%SettingsButton")
	if settings_btn:
		settings_btn.visible = false
	_update_theme_option_button()
	_update_ui_with_new_language()
	_connect_signals()
	apply_navbar_button_styles([home_button, wages_button, salary_button], null)


## Populates the theme OptionButton and sets the selected index from SaveData. Called from [method _ready].
func _update_theme_option_button() -> void:
	theme_option_button.clear()
	theme_option_button.add_item(tr("SETTINGS_THEME_LIGHT"), 0)
	theme_option_button.add_item(tr("SETTINGS_THEME_DARK"), 1)
	var theme_id: String = SaveData.save_data_dict.get("theme", "light")
	theme_option_button.selected = 0 if theme_id == "light" else 1


## Updates labels with translated strings.
func _update_ui_with_new_language() -> void:
	title_label.text = tr("SETTINGS_TITLE")
	go_back_button.text = tr("GO_BACK")
	home_button.get_node("VBoxContainer/Label").text = tr("NAV_HOME")
	wages_button.get_node("VBoxContainer/Label").text = tr("NAV_WAGES")
	salary_button.get_node("VBoxContainer/Label").text = tr("NAV_SALARY")
	language_button.text = tr("SETTINGS_LANGUAGE")
	theme_label.text = tr("SETTINGS_THEME")


## Connects button signals to handlers.
func _connect_signals() -> void:
	language_button.pressed.connect(_on_language_pressed)
	theme_option_button.item_selected.connect(_on_theme_selected)
	theme_option_button.get_popup().about_to_popup.connect(_on_theme_popup_about_to_show)
	go_back_button.pressed.connect(_on_go_back_pressed)
	home_button.pressed.connect(_on_home_pressed)
	wages_button.pressed.connect(_on_wages_pressed)
	salary_button.pressed.connect(_on_salary_pressed)


## Ensures the theme selection PopupMenu uses the current theme before display (PopupMenu may not inherit from parent when shown).
func _on_theme_popup_about_to_show() -> void:
	theme_option_button.get_popup().theme = ThemeManager.get_current_theme()


## Handles theme selection change. [param index] is 0 for light, 1 for dark.
func _on_theme_selected(index: int) -> void:
	var theme_id: String = "light" if index == 0 else "dark"
	ThemeManager.set_theme(theme_id)
	_update_ui_with_new_language()
	apply_navbar_button_styles([home_button, wages_button, salary_button], null)


## Opens the language selection screen; returns to settings on continue.
func _on_language_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.LANGUAGE_SELECTION_SCREEN, ScreenManager.Screen.SETTINGS_SCREEN)


## Navigates back to the screen the user came from.
func _on_go_back_pressed() -> void:
	ScreenManager.change_screen(_return_screen)


## Navigates to the home screen.
func _on_home_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)


## Navigates to the wages screen.
func _on_wages_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.WAGES_SCREEN)


## Navigates to the salary screen.
func _on_salary_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.SALARY_SCREEN)
